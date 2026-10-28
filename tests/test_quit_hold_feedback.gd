extends GdToolsTest
## Tests for the parent-gate hold feedback (parent_gate_20261028 Phase 2).
##
## The hidden 3s corner hold from Phase 1 gains a filling progress ring at
## the touch point (screen-safe: constant white, no flashes), soft ticks
## while it counts, and the existing door-chime on completion. Ticks and the
## chime ride injectable doubles so no test ever plays audio; the production
## path reuses the synth set (tick = "gem" pop, chime = "door" rise).
## Resets stay silent: ring cleared, ticks stopped, no chime.


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


func _corner(gate: QuitHold) -> Vector2:
	return gate.zone_center()


func _hold_for(gate: QuitHold, seconds: float) -> void:
	gate._process(seconds)


func _hold_steps(gate: QuitHold, seconds: float, step: float = 0.25) -> void:
	var left := seconds
	while left > 0.0:
		var chunk := minf(step, left)
		gate._process(chunk)
		left -= chunk


func _spies() -> Dictionary:
	return {
		"ticks": [] as Array,
		"chimes": [] as Array,
		"quits": [] as Array,
		"saves": [] as Array,
	}


func _bind(gate: QuitHold, spies: Dictionary) -> void:
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	var saves: Array = spies["saves"]
	gate.tick_call = func() -> void: ticks.append("tick")
	gate.chime_call = func() -> void: chimes.append("chime")
	gate.quit_call = func() -> void: quits.append("quit")
	gate.save_flush = func() -> bool:
		saves.append("save")
		return true
	gate.set_viewport_size(Vector2(1280, 720))


# --- tuning defaults ----------------------------------------------------------


func test_feedback_defaults_come_from_tuning() -> void:
	var gate := QuitHold.new()
	assert_almost_eq(gate.tick_interval, Tuning.QUIT_TICK_INTERVAL, 0.001, "tick every second.")
	assert_almost_eq(gate.ring_radius, Tuning.QUIT_RING_RADIUS, 0.01, "ring radius is tuned.")
	assert_almost_eq(Tuning.QUIT_TICK_INTERVAL, 1.0, 0.001, "one soft tick per second.")
	assert_almost_eq(Tuning.QUIT_RING_RADIUS, 28.0, 0.01, "small ring at the touch point.")


func test_gate_is_a_non_consuming_screen_overlay() -> void:
	var gate := _gate()
	assert_true(gate is Control, "a CanvasItem so it can draw the ring itself.")
	assert_eq(gate.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never eats GUI input.")


# --- progress ring ------------------------------------------------------------


func test_ring_hidden_until_hold_starts() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	assert_false(gate.is_ring_visible(), "idle: no ring.")
	assert_almost_eq(gate.ring_sweep(), 0.0, 0.001, "idle: no sweep.")
	gate._input(_touch(true, _corner(gate)))
	assert_true(gate.is_ring_visible(), "press in-zone shows the ring.")
	assert_almost_eq(gate.ring_sweep(), 0.0, 0.001, "but no time has passed yet.")


func test_ring_sweep_grows_with_progress() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.5)
	assert_true(gate.is_ring_visible(), "ring stays up mid-hold.")
	assert_almost_eq(gate.progress(), 0.5, 0.01, "halfway through the hold.")
	assert_almost_eq(gate.ring_sweep(), PI, 0.05, "half the hold fills half the ring.")


func test_ring_center_stays_fully_on_screen() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	var center := gate.ring_center()
	var margin := gate.ring_radius + 8.0
	assert_gte(center.x, margin, "ring never clips off the right edge.")
	assert_gte(center.y, margin, "ring never clips off the top edge.")
	assert_lte(center.x, 1280.0 - margin, "ring stays inside the viewport.")
	assert_lte(center.y, 720.0 - margin, "ring stays inside the viewport.")


func test_ring_clears_on_early_release() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.0)
	assert_true(gate.is_ring_visible(), "ring was up.")
	gate._input(_touch(false, _corner(gate)))
	assert_false(gate.is_ring_visible(), "release clears the ring.")
	assert_almost_eq(gate.ring_sweep(), 0.0, 0.001, "no residue.")


func test_ring_clears_on_drift() -> void:
	var gate := _gate()
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 1.0)
	gate._input(_drag(Vector2(400, 400)))
	assert_false(gate.is_ring_visible(), "drift clears the ring too.")


# --- ticks + chime ------------------------------------------------------------


func test_ticks_fire_each_interval_and_chime_completes() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	var saves: Array = spies["saves"]
	gate._input(_touch(true, _corner(gate)))
	_hold_steps(gate, 0.5)
	assert_true(ticks.is_empty(), "half a second is too early for a tick.")
	_hold_steps(gate, 0.5)
	assert_eq(ticks.size(), 1, "one soft tick after the first second.")
	_hold_steps(gate, 1.0)
	assert_eq(ticks.size(), 2, "a second tick after the second second.")
	assert_true(chimes.is_empty(), "the chime waits for the full hold.")
	_hold_steps(gate, 1.0)
	assert_eq(ticks.size(), 2, "no third tick: the hold completes instead.")
	assert_eq(chimes, ["chime"], "the door-chime rings exactly once.")
	assert_eq(saves, ["save"], "completion flushes the save first.")
	assert_eq(quits, ["quit"], "then quits exactly once.")
	assert_false(gate.is_ring_visible(), "completion clears the ring.")


func test_single_big_step_ticks_the_same() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 3.0)
	assert_eq(ticks.size(), 2, "frame rate never changes the tick count.")
	assert_eq(chimes, ["chime"], "completion still chimes once.")
	assert_eq(quits, ["quit"], "and quits exactly once.")


func test_custom_tick_interval_reschedules() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	gate.tick_interval = 0.5
	var ticks: Array = spies["ticks"]
	var quits: Array = spies["quits"]
	gate._input(_touch(true, _corner(gate)))
	_hold_for(gate, 3.0)
	assert_eq(ticks.size(), 5, "ticks at 0.5..2.5, then the chime.")
	assert_eq(quits, ["quit"], "the faster clock still quits once.")


func test_release_stops_ticks_and_skips_chime() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	gate._input(_touch(true, _corner(gate)))
	_hold_steps(gate, 1.5)
	assert_eq(ticks.size(), 1, "one tick before the release.")
	gate._input(_touch(false, _corner(gate)))
	_hold_for(gate, 5.0)
	assert_eq(ticks.size(), 1, "reset stops the tick clock.")
	assert_true(chimes.is_empty(), "reset never chimes.")
	assert_true(quits.is_empty(), "reset never quits.")


# --- resize + second finger (Phase 1 edges, now with feedback) ----------------


func test_resize_staying_inside_keeps_hold_and_feedback() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	gate.set_viewport_size(Vector2(800, 600))
	gate._input(_touch(true, Vector2(790, 10)))
	assert_true(gate.is_holding(), "the hold starts in-zone.")
	_hold_steps(gate, 1.0)
	assert_eq(ticks.size(), 1, "one tick before the resize.")
	gate.set_viewport_size(Vector2(810, 600))
	assert_true(gate.is_holding(), "the holder is still inside: the hold continues.")
	assert_true(gate.is_ring_visible(), "the ring survives the resize.")
	assert_almost_eq(gate.progress(), 1.0 / 3.0, 0.05, "progress is preserved.")
	_hold_steps(gate, 2.0)
	assert_eq(ticks.size(), 2, "ticks resume on the same clock.")
	assert_eq(chimes, ["chime"], "the hold still completes.")
	assert_eq(quits, ["quit"], "exactly once.")


func test_resize_pushing_outside_resets_silently() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	gate.set_viewport_size(Vector2(1280, 720))
	gate._input(_touch(true, Vector2(1260, 10)))
	_hold_steps(gate, 1.0)
	assert_eq(ticks.size(), 1, "one tick before the resize.")
	gate.set_viewport_size(Vector2(800, 600))
	assert_false(gate.is_holding(), "the holder is outside after resize.")
	assert_false(gate.is_ring_visible(), "the ring clears with the reset.")
	_hold_for(gate, 5.0)
	assert_eq(ticks.size(), 1, "no more ticks after the reset.")
	assert_true(chimes.is_empty(), "a resized-away hold never chimes.")
	assert_true(quits.is_empty(), "and never quits.")


func test_second_finger_neither_resets_nor_disturbs_feedback() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	gate._input(_touch(true, _corner(gate), 0))
	gate._input(_touch(true, Vector2(120, 600), 1))
	gate._input(_drag(Vector2(160, 600), 1))
	gate._input(_touch(false, Vector2(160, 600), 1))
	_hold_steps(gate, 1.0)
	assert_true(gate.is_holding(), "gameplay neither resets the hold.")
	assert_true(gate.is_ring_visible(), "nor hides the ring.")
	assert_eq(ticks.size(), 1, "nor disturbs the tick clock.")
	assert_true(chimes.is_empty(), "nor fires early.")
	_hold_steps(gate, 2.0)
	assert_eq(ticks.size(), 2, "the hold ticks on.")
	assert_eq(chimes, ["chime"], "and completes exactly once.")
	assert_eq(quits, ["quit"], "quitting exactly once.")


func test_mouse_hold_shows_ring_ticks_and_chimes() -> void:
	var gate := _gate()
	var spies := _spies()
	_bind(gate, spies)
	var ticks: Array = spies["ticks"]
	var chimes: Array = spies["chimes"]
	var quits: Array = spies["quits"]
	var saves: Array = spies["saves"]
	gate._input(_click(true, _corner(gate)))
	assert_true(gate.is_ring_visible(), "a mouse press shows the ring too.")
	_hold_for(gate, 3.0)
	assert_eq(ticks.size(), 2, "the mouse hold ticks.")
	assert_eq(chimes, ["chime"], "and chimes on completion.")
	assert_eq(saves, ["save"], "flushing the save first.")
	assert_eq(quits, ["quit"], "then quitting once.")
