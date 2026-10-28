extends GdToolsTest
## Tests for the hidden parent gate (parent_gate_20261028 Phase 1).
##
## A grown-up holds the extreme top-right corner for 3 stationary seconds to
## flush the save and quit; a child playing normally never trips it. This
## suite pins the logic headlessly: the viewport-relative zone, the hold
## state machine, the injectable save-flush + quit double, the inert Esc key,
## and the guarantee that walk/jump traffic passes through untouched.
## No test ever calls get_tree().quit(): the quit path is always a spy.

const GAME_SCRIPT := "res://src/levels/game.gd"


func _gate() -> QuitHold:
	var gate := QuitHold.new()
	add_child(gate)
	return gate


func _touch(pressed: bool, pos: Vector2, index: int = 0) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.pressed = pressed
	touch.position = pos
	touch.index = index
	return touch


func _drag(pos: Vector2, index: int = 0) -> InputEventScreenDrag:
	var drag := InputEventScreenDrag.new()
	drag.position = pos
	drag.index = index
	return drag


func _click(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = pos
	return click


func _motion(pos: Vector2) -> InputEventMouseMotion:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	return motion


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	return event


func _corner(gate: QuitHold) -> Vector2:
	return gate.zone_center()


func _hold_for(gate: QuitHold, seconds: float) -> void:
	gate._process(seconds)


# --- zone (P1.T1) -------------------------------------------------------------


func test_zone_defaults_come_from_tuning() -> void:
	var gate := _gate()
	assert_eq(gate.zone_radius, Tuning.QUIT_ZONE_RADIUS, "radius is a tuning constant.")
	assert_eq(gate.hold_seconds, Tuning.QUIT_HOLD_SECONDS, "hold time is a tuning constant.")
	assert_almost_eq(gate.zone_radius, 64.0, 0.01, "default radius ~64px.")
	assert_almost_eq(gate.hold_seconds, 3.0, 0.01, "default hold ~3s.")


func test_zone_is_top_right_corner_of_live_viewport() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	assert_eq(_corner(gate), Vector2(1280, 0), "zone sits on the extreme corner.")
	assert_true(gate.is_in_zone(Vector2(1280, 0)), "the corner pixel itself counts.")
	assert_true(gate.is_in_zone(Vector2(1230, 20)), "a press just inside the radius counts.")
	assert_false(gate.is_in_zone(Vector2(1100, 0)), "gameplay far from the corner is outside.")


func test_zone_tracks_resize_including_non_16_9() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(720, 1280))
	assert_eq(_corner(gate), Vector2(720, 0), "portrait moves the corner, not the size.")
	assert_true(gate.is_in_zone(Vector2(700, 10)), "in-zone near the portrait corner.")
	assert_false(gate.is_in_zone(Vector2(1280, 0)), "the old landscape corner is outside.")
	gate.set_viewport_size(Vector2(2560, 1080))
	assert_eq(_corner(gate), Vector2(2560, 0), "ultrawide corner tracked too.")


# --- state machine (P1.T2) ----------------------------------------------------


func test_press_in_zone_starts_hold() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	assert_true(gate.is_holding(), "an in-zone press starts the hold.")
	assert_almost_eq(gate.progress(), 0.0, 0.01, "no time has passed yet.")


func test_press_outside_zone_ignores() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, Vector2(200, 600)))
	assert_false(gate.is_holding(), "gameplay-area touches never arm the gate.")


func test_release_before_hold_resets_silently() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.0)
	assert_gt(gate.progress(), 0.0, "the hold was counting.")
	assert_lt(gate.progress(), 1.0, "but 1s is not a full hold.")
	gate._input(_touch(false, _corner(gate)))
	_hold_for(gate, 5.0)
	assert_true(calls.is_empty(), "an early release never quits.")
	assert_false(gate.is_holding(), "the gate is idle again.")
	assert_almost_eq(gate.progress(), 0.0, 0.001, "no residue left behind.")


func test_drift_outside_zone_resets() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.0)
	gate._input(_drag(Vector2(400, 400)))
	assert_false(gate.is_holding(), "leaving the zone drops the hold.")
	assert_almost_eq(gate.progress(), 0.0, 0.001, "the timer resets, silently.")
	_hold_for(gate, 5.0)
	assert_true(calls.is_empty(), "a drifted hold never fires later.")


func test_full_hold_fires_flush_then_quit_exactly_once() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> void: calls.append("flush")
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.0)
	assert_true(calls.is_empty(), "1s is not enough.")
	_hold_for(gate, 2.0)
	assert_eq(calls, ["flush", "quit"], "a full hold flushes first, then quits.")
	_hold_for(gate, 5.0)
	assert_eq(calls, ["flush", "quit"], "it fires once, never repeats.")


func test_flush_failure_still_quits() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> bool:
		calls.append("flush")
		return false
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, gate.hold_seconds)
	assert_eq(calls, ["flush", "quit"], "a failed flush never traps the parent.")


# --- app wiring + Esc (P1.T3) -------------------------------------------------


func test_game_wires_quit_hold_with_save_flush() -> void:
	SaveGame.clear()
	var game: Game = load(GAME_SCRIPT).new()
	add_child(game)
	assert_true(game.quit_hold != null, "the game owns a quit gate.")
	assert_true(game.quit_hold.is_inside_tree(), "the gate lives in the scene tree.")
	assert_true(game.quit_hold.save_flush.is_valid(), "the gate flushes through the game save.")
	assert_false(
		game.quit_hold.quit_call.is_valid(),
		"no test double in production: the default path calls get_tree().quit()."
	)
	remove_child(game)
	game.queue_free()
	SaveGame.clear()


func test_esc_is_inert() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> void: calls.append("flush")
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_key(KEY_ESCAPE))
	assert_false(gate.is_holding(), "Esc alone never arms the gate.")
	assert_true(calls.is_empty(), "Esc alone never quits.")
	gate._input(_touch(true, _corner(gate)))
	gate._input(_key(KEY_ESCAPE))
	_hold_for(gate, 1.0)
	assert_true(gate.is_holding(), "Esc mid-hold disturbs nothing.")
	_hold_for(gate, 2.0)
	assert_eq(calls, ["flush", "quit"], "the hold still completes after an Esc.")


# --- input non-interference (P1.T4) -------------------------------------------


func test_gameplay_only_traffic_never_starts_or_fires() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> void: calls.append("flush")
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	# A walk-hold bottom-left, jump taps, and keyboard play: the child's world.
	gate._input(_touch(true, Vector2(120, 600), 1))
	gate._input(_key(KEY_A))
	gate._input(_key(KEY_SPACE))
	gate._input(_touch(true, Vector2(1150, 620), 2))
	gate._input(_touch(false, Vector2(1150, 620), 2))
	gate._input(_drag(Vector2(140, 600), 1))
	_hold_for(gate, 5.0)
	gate._input(_touch(false, Vector2(140, 600), 1))
	assert_false(gate.is_holding(), "gameplay traffic never arms the gate.")
	assert_true(calls.is_empty(), "and never fires it.")


func test_gameplay_traffic_during_hold_neither_resets_nor_fires() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> void: calls.append("flush")
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate), 0))
	# A second finger walks and jumps elsewhere while the parent holds.
	gate._input(_touch(true, Vector2(120, 600), 1))
	gate._input(_key(KEY_SPACE))
	gate._input(_drag(Vector2(160, 600), 1))
	gate._input(_touch(false, Vector2(160, 600), 1))
	_hold_for(gate, 1.0)
	assert_true(gate.is_holding(), "gameplay neither resets the parent's hold.")
	assert_true(calls.is_empty(), "nor fires it early.")
	_hold_for(gate, 2.0)
	assert_eq(calls, ["flush", "quit"], "the hold still completes exactly once.")


func test_resize_mid_hold_resets_when_holder_leaves_zone() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, Vector2(1260, 10), 0))
	assert_true(gate.is_holding(), "the hold starts in-zone.")
	gate.set_viewport_size(Vector2(800, 600))
	assert_false(gate.is_holding(), "the holder is outside after resize: silent reset.")
	assert_almost_eq(gate.progress(), 0.0, 0.001, "no residue.")
	_hold_for(gate, 5.0)
	assert_true(calls.is_empty(), "a resized-away hold never fires.")


func test_mouse_hold_quits_and_cursor_drift_resets() -> void:
	var gate := _gate()
	var calls: Array[String] = []
	gate.save_flush = func() -> void: calls.append("flush")
	gate.quit_call = func() -> void: calls.append("quit")
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_click(true, _corner(gate)))
	assert_true(gate.is_holding(), "a mouse press arms the gate too.")
	gate._input(_motion(Vector2(400, 400)))
	assert_false(gate.is_holding(), "cursor drift out of the zone resets.")
	gate._input(_click(false, Vector2(400, 400)))
	gate._input(_click(true, _corner(gate)))
	_hold_for(gate, gate.hold_seconds)
	assert_eq(calls, ["flush", "quit"], "a steady mouse hold quits like a touch.")
