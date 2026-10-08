extends GdToolsTest
## Tests for Robo's jump, gravity, and grace timers (Movement Phase 2).
##
## update_jump() and update_gravity() are frame-steppable pure logic: they
## take (delta, on_floor, jump_just_pressed) so grace windows can be tested
## deterministically without simulating whole physics scenes.


func _robot() -> Robot:
	return load("res://src/robot/robot.gd").new()


# --- jump impulse ---


func test_jump_sets_upward_impulse() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.016, true, true)
	assert_eq(
		robot.velocity.y, -Tuning.JUMP_IMPULSE, "a fresh press on the floor launches Robo upward."
	)


func test_no_jump_without_floor_or_coyote() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.016, false, true)
	assert_eq(robot.velocity.y, 0.0, "mid-air with expired coyote, a press does nothing.")


# --- coyote time ---


func test_coyote_window_allows_jump_after_leaving_edge() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.05, true, false)  # standing fills the coyote window
	robot.update_jump(0.05, false, true)  # walked off, still inside 0.1s
	assert_eq(
		robot.velocity.y, -Tuning.JUMP_IMPULSE, "jumping just after leaving an edge still works."
	)


func test_coyote_expires() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.05, true, false)
	robot.update_jump(0.11, false, true)  # longer than the 0.1s window
	assert_eq(robot.velocity.y, 0.0, "a late press after the coyote window does nothing.")


# --- jump buffer ---


func test_buffer_fires_on_landing() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.016, false, true)  # pressed while airborne
	robot.update_jump(0.016, true, false)  # lands a moment later
	assert_eq(
		robot.velocity.y, -Tuning.JUMP_IMPULSE, "a press just before landing jumps on landing."
	)


func test_buffer_expires() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.016, false, true)  # press stored
	robot.update_jump(0.11, false, false)  # no floor arrives within 0.1s
	robot.update_jump(0.016, true, false)  # lands much later
	assert_eq(robot.velocity.y, 0.0, "a stale buffered press is forgotten.")


# --- single jump ---


func test_no_double_jump_mid_air() -> void:
	var robot: Robot = _robot()
	robot.update_jump(0.016, true, true)
	var launched: float = robot.velocity.y
	robot.update_jump(0.016, false, true)
	assert_eq(robot.velocity.y, launched, "a second mid-air press cannot re-launch.")


# --- gravity ---


func test_gravity_pulls_down_gently() -> void:
	var robot: Robot = _robot()
	robot.update_gravity(0.1, false)
	assert_almost_eq(robot.velocity.y, Tuning.GRAVITY * 0.1, 0.01, "gravity accelerates the fall.")


func test_fall_speed_is_capped() -> void:
	var robot: Robot = _robot()
	robot.update_gravity(10.0, false)
	assert_eq(robot.velocity.y, Tuning.FALL_SPEED_CAP, "long falls never exceed the terminal cap.")


func test_gravity_rests_on_floor() -> void:
	var robot: Robot = _robot()
	robot.velocity.y = Tuning.FALL_SPEED_CAP
	robot.update_gravity(0.016, true)
	assert_eq(robot.velocity.y, 0.0, "landing zeroes vertical velocity.")


# --- derived jump height ---


func test_jump_reaches_three_tiles() -> void:
	# h = v^2 / (2g) — the analytic apex promised by Tuning's comment.
	var height := Tuning.JUMP_IMPULSE * Tuning.JUMP_IMPULSE / (2.0 * Tuning.GRAVITY)
	assert_almost_eq(height, 3.0 * AssetSpec.TILE_SIZE.y, 0.5, "jump apex is about 3 tiles high.")


# --- physics integration (real floor) ---


func test_real_jump_leaves_the_floor() -> void:
	for action_name: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
	var robot: Robot = _robot()
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(200, 16)
	floor_shape.shape = rect
	floor_shape.position = Vector2(0, 44)  # top surface just under Robo's feet
	floor_body.add_child(floor_shape)
	var start_y := 0.0
	# Spawn Robo resting on the floor: collider half-height 14, floor top at
	# y = 44 - 8 = 36, so feet exactly touch the surface.
	robot.position = Vector2(0, 22)
	add_child(floor_body)
	add_child(robot)
	start_y = robot.position.y
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	assert_lt(robot.position.y, start_y, "Robo physically leaves the floor when jump is pressed.")
	robot.queue_free()
	floor_body.queue_free()
