class_name QuitHold
extends Node
## Hidden parent gate: a sustained stationary hold in the extreme top-right
## corner flushes the save and quits the app. A 4-year-old never trips it:
## there is no button, no text, and no visual; release or drift resets the
## timer silently. Gameplay input passes through untouched: this node only
## observes, never consumes, and Esc is deliberately inert.
##
## Headless-testable: the zone comes from `viewport_size` (synced from the
## live viewport rect, refreshed on resize), the timing from `_process`, and
## both side effects are injectable Callables (`save_flush`, `quit_call`) so
## tests record calls with spies instead of quitting the engine.

## Production defaults live in Tuning (tunable after device testing).
var hold_seconds: float = Tuning.QUIT_HOLD_SECONDS
var zone_radius: float = Tuning.QUIT_ZONE_RADIUS
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

var _holding := false
var _elapsed := 0.0
var _press_pos := Vector2.ZERO
var _touch_index := -1
var _using_mouse := false


func _ready() -> void:
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
	if _elapsed >= hold_seconds:
		_fire()
		_reset_silent()


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


func _fire() -> void:
	if save_flush.is_valid():
		save_flush.call()
	if quit_call.is_valid():
		quit_call.call()
	else:
		_default_quit()


func _default_quit() -> void:
	var tree := get_tree()
	if tree != null:
		tree.quit()


func _on_viewport_size_changed() -> void:
	if is_inside_tree() and get_viewport() != null:
		set_viewport_size(get_viewport().get_visible_rect().size)
