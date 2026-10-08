extends GdToolsTest
## Tests for the toddler step assist (Movement Phase 7 playtest feedback):
## walking into a low ledge while holding a direction hops Robo onto it
## automatically, so staircases need zero jump precision.


func _robot() -> Robot:
	var robot: Robot = load("res://src/robot/robot.gd").new()
	add_child(robot)
	return robot


func _ensure_actions() -> void:
	for action_name: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


func _box(size: Vector2, center: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = center
	body.add_child(shape)
	add_child(body)
	return body


func test_step_assist_climbs_low_ledge_automatically() -> void:
	_ensure_actions()
	_box(Vector2(400, 16), Vector2(0, 44))  # floor, top at y=36
	_box(Vector2(64, 32), Vector2(80, 20))  # 2-tile step, top at y=4
	var robot: Robot = _robot()
	robot.position = Vector2(0, 22)  # feet on the floor
	Input.action_press("move_right")
	for _i: int in 150:
		await get_tree().physics_frame
	Input.action_release("move_right")
	var feet_y: float = robot.position.y + 14.0
	assert_true(robot.is_on_floor(), "Robo ended up standing.")
	assert_almost_eq(feet_y, 4.0, 2.0, "Robo climbed the step without jumping.")
	assert_gt(robot.position.x, 48.0, "Robo is on top of the step, not stuck at its face.")
	robot.free()


func test_step_assist_ignores_tall_walls() -> void:
	_ensure_actions()
	_box(Vector2(400, 16), Vector2(0, 44))  # floor, top at y=36
	_box(Vector2(16, 200), Vector2(80, -64))  # tall wall, face at x=72
	var robot: Robot = _robot()
	robot.position = Vector2(0, 22)
	Input.action_press("move_right")
	for _i: int in 150:
		await get_tree().physics_frame
	Input.action_release("move_right")
	var feet_y: float = robot.position.y + 14.0
	assert_almost_eq(feet_y, 36.0, 1.0, "Robo stays on the floor at a tall wall.")
	assert_true(robot.position.x < 72.0, "Robo is stopped by the wall, not inside it.")
	robot.free()


func test_step_assist_needs_horizontal_input() -> void:
	_ensure_actions()
	_box(Vector2(400, 16), Vector2(0, 44))
	_box(Vector2(64, 32), Vector2(80, 20))
	var robot: Robot = _robot()
	robot.position = Vector2(20, 22)
	for _i: int in 60:
		await get_tree().physics_frame
	var feet_y: float = robot.position.y + 14.0
	assert_almost_eq(feet_y, 36.0, 1.0, "standing still next to a ledge does not hop.")
	robot.free()
