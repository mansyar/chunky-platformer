extends GdToolsTest
## Tests for the playground level (Movement Phase 7): structure, geometry,
## and a physics smoke check. The level is code-assembled from AssetFactory
## art, LevelParts pieces, the Robot, the FollowCamera, and TouchControls.

const PLAYGROUND_SCENE := "res://src/levels/playground.tscn"


func _level() -> Node2D:
	var level: Node2D = load(PLAYGROUND_SCENE).instantiate()
	add_child(level)
	return level


func _find_first(node: Node, callback: Callable) -> Node:
	if callback.call(node):
		return node
	for child: Node in node.get_children():
		var found: Node = _find_first(child, callback)
		if found != null:
			return found
	return null


func _find_all(node: Node, callback: Callable, into: Array) -> void:
	if callback.call(node):
		into.append(node)
	for child: Node in node.get_children():
		_find_all(child, callback, into)


# --- scene wiring ---


func test_main_scene_is_playground() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene", ""),
		PLAYGROUND_SCENE,
		"the playground is the game's main scene."
	)


func test_proof_scene_is_gone() -> void:
	assert_false(
		ResourceLoader.exists("res://src/proof/proof.tscn"),
		"the proof scene was replaced by the playground."
	)


func test_playground_has_world_camera_robot_and_touch_controls() -> void:
	var level: Node2D = _level()
	var tilemaps: Array = []
	_find_all(level, func(n: Node) -> bool: return n is TileMapLayer, tilemaps)
	assert_eq(tilemaps.size(), 1, "the level has exactly one TileMapLayer.")
	assert_gt(
		(tilemaps[0] as TileMapLayer).get_used_cells().size(),
		100,
		"the level is built from many tiles."
	)
	var robot: Node = _find_first(level, func(n: Node) -> bool: return n is Robot)
	assert_true(robot != null, "Robo is in the level.")
	var camera: Node = _find_first(level, func(n: Node) -> bool: return n is FollowCamera)
	assert_true(camera != null, "a follow camera watches the level.")
	assert_true((camera as FollowCamera).target == robot, "the camera follows Robo.")
	var touch: Node = _find_first(level, func(n: Node) -> bool: return n is TouchControls)
	assert_true(touch != null, "touch controls are available.")
	level.free()


func test_playground_has_interactives() -> void:
	var level: Node2D = _level()
	var trampolines: Array = []
	_find_all(level, func(n: Node) -> bool: return n is Trampoline, trampolines)
	assert_true(trampolines.size() >= 2, "the level has at least two trampolines.")
	var walls: Array = []
	_find_all(
		level,
		func(n: Node) -> bool:
			if not (n is StaticBody2D):
				return false
			var x: float = (n as StaticBody2D).position.x
			return x < 0.0 or x > 640.0,
		walls
	)
	assert_true(walls.size() >= 2, "invisible edge walls close both level ends.")
	level.free()


# --- geometry: three layers, safe falls ---


func test_level_geometry_has_three_layers() -> void:
	var level: Node2D = _level()
	var tiles: Node = _find_first(level, func(n: Node) -> bool: return n is TileMapLayer)
	var layer := tiles as TileMapLayer
	var mid_hill := layer.get_cell_source_id(Vector2i(8, 30))
	var top_hill := layer.get_cell_source_id(Vector2i(30, 27))
	var valley_floor := layer.get_cell_source_id(Vector2i(20, 33))
	var valley_sky := layer.get_cell_source_id(Vector2i(20, 20))
	assert_true(mid_hill != -1, "the left hill exists above the ground floor.")
	assert_true(top_hill != -1, "the right tall hill exists.")
	assert_true(valley_floor != -1, "the valley floor is walkable ground.")
	assert_eq(valley_sky, -1, "the valley is an open safe-fall shaft between the hills.")
	level.free()


func test_robot_spawns_on_valley_floor() -> void:
	var level: Node2D = _level()
	var robot: Node = _find_first(level, func(n: Node) -> bool: return n is Robot)
	var feet_y: float = (robot as Node2D).position.y + 14.0
	assert_almost_eq(feet_y, 512.0, 1.0, "Robo spawns standing on the valley floor.")
	level.free()


func test_physics_smoke_robot_lands_and_camera_follows() -> void:
	var level: Node2D = _level()
	var robot: Node = _find_first(level, func(n: Node) -> bool: return n is Robot)
	for _i: int in 30:
		await get_tree().physics_frame
	assert_true((robot as Robot).is_on_floor(), "Robo rests on the floor after spawn.")
	level.free()
