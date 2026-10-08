extends GdToolsTest
## Empirical integration tests inside the REAL playground scene:
## the jump apex Robo actually reaches, and hands-free stair climbing.

const PLAYGROUND_SCENE := "res://src/levels/playground.tscn"


func _open_level() -> Node2D:
	var level: Node2D = (load(PLAYGROUND_SCENE) as PackedScene).instantiate()
	add_child(level)
	return level


func _robo(level: Node2D) -> Robot:
	return level.find_child("Robo", true, false) as Robot


func _ensure_actions() -> void:
	for action_name: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


func test_real_jump_apex_matches_tuning() -> void:
	_ensure_actions()
	var level: Node2D = _open_level()
	var robo: Robot = _robo(level)
	await get_tree().physics_frame
	var ground_feet: float = robo.position.y + 14.0
	var apex: float = ground_feet
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	for _i: int in 60:
		await get_tree().physics_frame
		apex = minf(apex, robo.position.y + 14.0)
	var rise: float = ground_feet - apex
	assert_almost_eq(
		rise,
		Tuning.JUMP_IMPULSE * Tuning.JUMP_IMPULSE / (2.0 * Tuning.GRAVITY),
		3.0,
		"real jump apex matches the analytic height (%.1fpx rise)." % rise
	)
	level.free()


func test_holding_direction_climbs_the_stairs_hands_free() -> void:
	_ensure_actions()
	var level: Node2D = _open_level()
	var robo: Robot = _robo(level)
	await get_tree().physics_frame
	var rested_on_step := false
	Input.action_press("move_left")
	for _i: int in 210:  # 3.5s: walk to the low-hill step and auto-hop up
		await get_tree().physics_frame
		if not robo.is_on_floor():
			continue
		var feet_y: float = robo.position.y + 14.0
		if absf(feet_y - 480.0) < 2.0 or absf(feet_y - 448.0) < 2.0:
			rested_on_step = true
	Input.action_release("move_left")
	assert_true(
		rested_on_step,
		"holding left climbs the staircase hands-free (rested on a stair or plateau)."
	)
	level.free()
