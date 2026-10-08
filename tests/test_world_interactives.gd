extends GdToolsTest
## Tests for world interactives (Movement Phase 4): one-way platforms,
## trampolines, and edge walls.
##
## Trampoline bounce conditions are tested directly on the bounce() handler
## (falling-only, momentum-preserving, repeatable); one-way platforms and
## walls are verified through real physics simulation.


func _robot() -> Robot:
	var robot: Robot = load("res://src/robot/robot.gd").new()
	add_child(robot)
	return robot


func _floor(top_y: float, width := 400.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 16)
	shape.shape = rect
	shape.position = Vector2(0, top_y + 8)
	body.add_child(shape)
	add_child(body)
	return body


func _ensure_actions() -> void:
	for action_name: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


# --- one-way platforms ---


func test_one_way_catches_falling_robot() -> void:
	_ensure_actions()
	var platform: StaticBody2D = LevelParts.one_way_platform(64.0)
	platform.position = Vector2(0, 40)
	add_child(platform)
	var robot: Robot = _robot()
	robot.position = Vector2(0, 0)
	for _i: int in 30:
		await get_tree().physics_frame
		if robot.is_on_floor():
			break
	assert_true(robot.is_on_floor(), "a falling robot lands on the one-way platform.")
	robot.free()
	platform.free()


func test_one_way_lets_rising_robot_pass() -> void:
	_ensure_actions()
	var platform: StaticBody2D = LevelParts.one_way_platform(64.0)
	platform.position = Vector2(0, 0)
	add_child(platform)
	var robot: Robot = _robot()
	robot.position = Vector2(0, 30)  # below the platform
	robot.velocity.y = -300.0
	for _i: int in 12:
		await get_tree().physics_frame
	assert_lt(robot.position.y, -14.0, "a rising robot passes through and ends above the platform.")
	assert_false(robot.is_on_floor(), "the platform did not catch the rising robot.")
	robot.free()
	platform.free()


# --- trampoline ---


func test_trampoline_bounces_falling_body() -> void:
	var trampoline: Area2D = Trampoline.new()
	var robot: Robot = _robot()
	robot.velocity.y = 150.0
	trampoline.bounce(robot)
	assert_eq(robot.velocity.y, -Tuning.BOUNCE_IMPULSE, "a falling body is launched back up.")
	robot.free()


func test_trampoline_ignores_rising_body() -> void:
	var trampoline: Area2D = Trampoline.new()
	var robot: Robot = _robot()
	robot.velocity.y = -150.0
	trampoline.bounce(robot)
	assert_eq(robot.velocity.y, -150.0, "a rising body is not bounced.")
	robot.free()


func test_bounce_preserves_horizontal_momentum() -> void:
	var trampoline: Area2D = Trampoline.new()
	var robot: Robot = _robot()
	robot.velocity.x = 30.0
	robot.velocity.y = 150.0
	trampoline.bounce(robot)
	assert_eq(robot.velocity.x, 30.0, "horizontal momentum is untouched by the bounce.")
	robot.free()


func test_bounce_repeats_on_every_landing() -> void:
	var trampoline: Area2D = Trampoline.new()
	var robot: Robot = _robot()
	robot.velocity.y = 150.0
	trampoline.bounce(robot)
	robot.velocity.y = 150.0  # fell back down again
	trampoline.bounce(robot)
	assert_eq(
		robot.velocity.y, -Tuning.BOUNCE_IMPULSE, "bounces keep working, landing after landing."
	)
	robot.free()


func test_trampoline_launches_robot_in_real_physics() -> void:
	var trampoline: Area2D = Trampoline.new()
	trampoline.position = Vector2(0, 30)
	add_child(trampoline)
	var robot: Robot = _robot()
	robot.position = Vector2(0, 10)  # just above the trampoline
	robot.velocity.y = 100.0
	var bounced := false
	for _i: int in 20:
		await get_tree().physics_frame
		if robot.velocity.y == -Tuning.BOUNCE_IMPULSE:
			bounced = true
			break
	assert_true(bounced, "physics detects the fall and the trampoline launches Robo.")
	robot.free()
	trampoline.free()


# --- edge walls ---


func test_edge_wall_blocks_walking_robot() -> void:
	_ensure_actions()
	var floor_body: StaticBody2D = _floor(36.0)
	var wall: StaticBody2D = LevelParts.edge_wall(120.0)
	wall.position = Vector2(0, 0)  # right edge at x=0 (spans -4..4)
	add_child(wall)
	var robot: Robot = _robot()
	robot.position = Vector2(-20, 22)
	Input.action_press("move_right")
	for _i: int in 60:  # a full second: unblocked Robo would travel ~38px
		await get_tree().physics_frame
	Input.action_release("move_right")
	assert_lt(robot.position.x, -8.0, "the invisible wall stops Robo at the boundary.")
	robot.free()
	wall.free()
	floor_body.free()
