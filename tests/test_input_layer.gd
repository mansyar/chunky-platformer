extends GdToolsTest
## Tests for the input layer (Movement Phase 6): Input Map wiring and the
## touch-controls layer with last-device detection.


func test_input_map_defines_all_actions() -> void:
	for action_name: String in ["move_left", "move_right", "jump"]:
		assert_true(InputMap.has_action(action_name), "Input Map defines '%s'." % action_name)


func test_jump_has_keyboard_and_gamepad_events() -> void:
	var events: Array = InputMap.action_get_events("jump")
	assert_gt(events.size(), 1, "jump has multiple bindings.")
	var has_key := false
	var has_pad := false
	for event: InputEvent in events:
		if event is InputEventKey:
			has_key = true
		if event is InputEventJoypadButton:
			has_pad = true
	assert_true(has_key, "jump is bound to a key.")
	assert_true(has_pad, "jump is bound to a gamepad button.")


func test_move_actions_have_gamepad_stick_bindings() -> void:
	var events: Array = InputMap.action_get_events("move_right")
	var has_axis := false
	for event: InputEvent in events:
		if event is InputEventJoypadMotion:
			has_axis = true
	assert_true(has_axis, "move_right is bound to the left stick / dpad axis.")


func _controls() -> CanvasLayer:
	var controls: CanvasLayer = load("res://src/input/touch_controls.gd").new()
	add_child(controls)
	return controls


func test_touch_controls_build_three_buttons() -> void:
	var controls: CanvasLayer = _controls()
	var actions := {}
	for child: Node in controls.get_children():
		var button := child as TouchScreenButton
		if button != null:
			actions[button.action] = button
	for required: String in ["move_left", "move_right", "jump"]:
		assert_has(actions, required, "'%s' has a touch button." % required)
		var button: TouchScreenButton = actions[required]
		assert_true(button.texture_normal != null, "%s button has generated art." % required)
	controls.free()


func test_touch_controls_hide_on_keyboard() -> void:
	var controls: CanvasLayer = _controls()
	assert_true(controls.visible, "touch controls start visible (touch-first).")
	var key := InputEventKey.new()
	key.keycode = KEY_A
	controls._input(key)
	assert_false(controls.visible, "keyboard activity hides the touch buttons.")
	controls.free()


func test_touch_controls_reappear_on_touch() -> void:
	var controls: CanvasLayer = _controls()
	var key := InputEventKey.new()
	key.keycode = KEY_A
	controls._input(key)
	controls._input(InputEventScreenTouch.new())
	assert_true(controls.visible, "touch activity brings the buttons back.")
	controls.free()


func test_touch_controls_hide_on_gamepad() -> void:
	var controls: CanvasLayer = _controls()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	controls._input(pad)
	assert_false(controls.visible, "gamepad activity hides the touch buttons.")
	controls.free()
