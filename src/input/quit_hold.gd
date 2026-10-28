class_name QuitHold
extends Control
## Hidden parent gate: a sustained stationary hold in the extreme top-right
## corner flushes the save and quits the app. A 4-year-old never trips it:
## there is no button, no text, and no visual; release or drift resets the
## timer silently. Gameplay input passes through untouched: this node only
## observes, never consumes, and Esc is deliberately inert.
##
## Hold feedback (screen-safe): while the hold counts, a small white ring at
## the touch point fills gradually (constant alphas, no flashing), a soft
## tick sounds each second, and the existing door-chime rings on completion.
## Resets are silent: the ring clears, the tick clock stops, no chime.
##
## Headless-testable: the zone comes from `viewport_size` (synced from the
## live viewport rect, refreshed on resize), the timing from `_process`, and
## every side effect is an injectable Callable (`save_flush`, `quit_call`,
## `tick_call`, `chime_call`) so tests record calls with spies instead of
## quitting the engine or playing audio. Unbound, the gate takes the
## production path: save-flush then `get_tree().quit()`, ticks and chime
## through the existing synth set (`gem` pop, `door` rise — no new assets).

## Default hold sound: the short soft "gem" pop, reused as the tick.
const TICK_SFX := "gem"
## Completion sound: the existing rising door-chime.
const CHIME_SFX := "door"
## Painted above world geometry on the base canvas layer (HUD CanvasLayers
## and the transition veil sit above canvas layers by design; the ring never
## overlaps them — it lives in the empty top-right corner).
const RING_Z_INDEX := 100

## Production defaults live in Tuning (tunable after device testing).
var hold_seconds: float = Tuning.QUIT_HOLD_SECONDS
var zone_radius: float = Tuning.QUIT_ZONE_RADIUS
## Seconds between soft ticks while the hold counts.
var tick_interval: float = Tuning.QUIT_TICK_INTERVAL
## Progress-ring radius in screen pixels (kept fully on screen); the stroke
## width is Tuning.QUIT_RING_WIDTH.
var ring_radius: float = Tuning.QUIT_RING_RADIUS
var ring_width: float = Tuning.QUIT_RING_WIDTH
## Live viewport size in screen pixels; refreshed from the real rect on
## ready and on every resize. Tests drive resize by calling
## set_viewport_size() directly.
var viewport_size: Vector2 = Vector2(1280, 720)
## Save-flush hook: the game binds this to its save routine. Ignored when
## unbound; a false return still quits (never trap the parent).
var save_flush: Callable = Callable()
## Quit hook: bound by tests to a recording spy. Unbound, the gate takes the
## production path and calls get_tree().quit().
var quit_call: Callable = Callable()
## Tick hook: bound by tests to a recording spy. Unbound, the gate plays the
## soft tick through the existing synth set.
var tick_call: Callable = Callable()
## Chime hook: bound by tests to a recording spy. Unbound, the gate plays
## the door-chime through the existing synth set.
var chime_call: Callable = Callable()

var _holding := false
var _elapsed := 0.0
var _press_pos := Vector2.ZERO
var _touch_index := -1
var _using_mouse := false
## Elapsed mark of the next tick; INF while idle so the clock only runs
## mid-hold and a zero/negative interval can never spin the tick loop.
var _next_tick := INF


func _ready() -> void:
	# A full-rect overlay that draws the ring in screen space (immune to the
	# camera zoom) yet never intercepts a thing: gameplay input keeps flowing
	# to the game exactly as before.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Full-rect overlay: anchors AND offsets, so the rect always matches
	# the viewport even though the gate lives under a plain Node parent.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = RING_Z_INDEX
	if is_inside_tree() and get_viewport() != null:
		viewport_size = get_viewport().get_visible_rect().size
		if get_viewport().has_signal("size_changed"):
			get_viewport().size_changed.connect(_on_viewport_size_changed)


## Extreme top-right corner of the live viewport rect.
func zone_center() -> Vector2:
	return Vector2(viewport_size.x, 0.0)


func is_in_zone(pos: Vector2) -> bool:
	return zone_center().distance_to(pos) <= zone_radius


func is_holding() -> bool:
	return _holding


## 0..1 progress of the current hold; 0 when idle.
func progress() -> float:
	if hold_seconds <= 0.0:
		return 0.0
	return clampf(_elapsed / hold_seconds, 0.0, 1.0)


## The ring shows only while a hold is counting; resets clear it fully.
func is_ring_visible() -> bool:
	return _holding


## Arc sweep in radians for the current progress; 0 when idle.
func ring_sweep() -> float:
	return TAU * progress()


## Ring center clamped so the whole ring stays on screen even when the
## press lands on the extreme corner pixel.
func ring_center() -> Vector2:
	var margin := ring_radius + 8.0
	return Vector2(
		clampf(_press_pos.x, margin, maxf(viewport_size.x - margin, margin)),
		clampf(_press_pos.y, margin, maxf(viewport_size.y - margin, margin))
	)


## Live-resize entry point: recompute the zone, and silently drop a hold
## whose press point is now outside it.
func set_viewport_size(size: Vector2) -> void:
	viewport_size = size
	if _holding and not is_in_zone(_press_pos):
		_reset_silent()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index != MOUSE_BUTTON_LEFT:
			return
		if click.pressed:
			_press_at(click.position, -1, true)
		elif _using_mouse:
			_reset_silent()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press_at(touch.position, touch.index, false)
		elif touch.index == _touch_index:
			_reset_silent()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _holding and not _using_mouse and drag.index == _touch_index:
			_move_to(drag.position)
	elif event is InputEventMouseMotion:
		if _holding and _using_mouse:
			_move_to((event as InputEventMouseMotion).position)
	# Anything else (keys incl. Esc, joypad, second fingers while holding)
	# is deliberately ignored: the gate never consumes gameplay input.


func _process(delta: float) -> void:
	if not _holding:
		return
	_elapsed += delta
	while tick_interval > 0.0 and _next_tick < hold_seconds and _elapsed >= _next_tick:
		_play_tick()
		_next_tick += tick_interval
	queue_redraw()
	if _elapsed >= hold_seconds:
		_play_chime()
		_fire()
		_reset_silent()


func _draw() -> void:
	if not _holding:
		return
	# Constant alphas only: a faint track plus the filling arc. Nothing
	# blinks, pulses, or jumps — the sweep grows smoothly with the hold.
	var center := ring_center()
	draw_arc(center, ring_radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.25), ring_width, true)
	var sweep := ring_sweep()
	if sweep > 0.01:
		draw_arc(
			center,
			ring_radius,
			-PI / 2.0,
			-PI / 2.0 + sweep,
			48,
			Color(1.0, 1.0, 1.0, 0.9),
			ring_width,
			true
		)


func _press_at(pos: Vector2, touch_index: int, using_mouse: bool) -> void:
	if _holding:
		return
	if not is_in_zone(pos):
		return
	_holding = true
	_elapsed = 0.0
	_press_pos = pos
	_touch_index = touch_index
	_using_mouse = using_mouse
	_next_tick = tick_interval
	queue_redraw()


func _move_to(pos: Vector2) -> void:
	if not is_in_zone(pos):
		_reset_silent()
	else:
		_press_pos = pos


func _reset_silent() -> void:
	_holding = false
	_elapsed = 0.0
	_touch_index = -1
	_using_mouse = false
	_next_tick = INF
	queue_redraw()


func _fire() -> void:
	if save_flush.is_valid():
		save_flush.call()
	if quit_call.is_valid():
		quit_call.call()
	else:
		_default_quit()


func _play_tick() -> void:
	if tick_call.is_valid():
		tick_call.call()
	else:
		AudioFactory.play(TICK_SFX)


func _play_chime() -> void:
	if chime_call.is_valid():
		chime_call.call()
	else:
		AudioFactory.play(CHIME_SFX)


func _default_quit() -> void:
	var tree := get_tree()
	if tree != null:
		tree.quit()


func _on_viewport_size_changed() -> void:
	if is_inside_tree() and get_viewport() != null:
		set_viewport_size(get_viewport().get_visible_rect().size)
