extends GdToolsTest
## Tests for Robo's horizontal movement logic (Movement Phase 1).
##
## The ramp math is pure (no physics frames needed): move_axis() updates
## velocity.x with a symmetric acceleration/deceleration ramp toward the
## axis-signed target speed. Air control uses the identical code path, so
## steering authority never changes mid-jump.

const ACCEL_STEP := Tuning.WALK_SPEED * (0.05 / Tuning.ACCEL_TIME)  # velocity covered in 0.05s


func _robot() -> Robot:
	return load("res://src/robot/robot.gd").new()


func test_accelerates_toward_target_speed() -> void:
	var robot: Robot = _robot()
	robot.move_axis(1.0, 0.05)
	assert_almost_eq(
		robot.velocity.x, ACCEL_STEP, 0.01, "ramp covers a proportional step, not full speed."
	)


func test_reaches_and_holds_target_speed() -> void:
	var robot: Robot = _robot()
	robot.move_axis(1.0, 0.5)
	assert_almost_eq(
		robot.velocity.x, Tuning.WALK_SPEED, 0.01, "long input reaches steady walk speed."
	)


func test_decelerates_to_stop() -> void:
	var robot: Robot = _robot()
	robot.velocity.x = Tuning.WALK_SPEED
	robot.move_axis(0.0, 0.5)
	assert_almost_eq(robot.velocity.x, 0.0, 0.01, "released input glides to a stop.")


func test_reversal_ramps_through_zero() -> void:
	var robot: Robot = _robot()
	robot.velocity.x = Tuning.WALK_SPEED
	robot.move_axis(-1.0, Tuning.ACCEL_TIME)
	assert_almost_eq(
		robot.velocity.x,
		0.0,
		0.01,
		"one full ramp from full speed reaches zero on the way to reversing."
	)


func test_air_control_matches_ground() -> void:
	var robot: Robot = _robot()
	robot.move_axis(1.0, 0.05)
	assert_almost_eq(
		robot.velocity.x, ACCEL_STEP, 0.01, "air steering uses the same ramp as ground."
	)


func test_facing_tracks_direction() -> void:
	var robot: Robot = _robot()
	robot.move_axis(1.0, 0.05)
	assert_eq(robot.facing, 1, "walking right faces right.")
	robot.move_axis(-1.0, 0.05)
	assert_eq(robot.facing, -1, "walking left faces left.")


func test_facing_holds_when_input_released() -> void:
	var robot: Robot = _robot()
	robot.move_axis(-1.0, 0.05)
	robot.move_axis(0.0, 0.05)
	assert_eq(robot.facing, -1, "neutral input keeps the last facing.")


func test_neutral_input_never_moves() -> void:
	var robot: Robot = _robot()
	robot.move_axis(0.0, 0.5)
	assert_almost_eq(robot.velocity.x, 0.0, 0.01, "no input, no drift.")
