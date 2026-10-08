extends GdToolsTest
## Tests for the proof scene (Foundation Phase 5).
##
## The proof scene assembles its world in code from AssetFactory output.
## These tests lock the structure: one tile layer populated from the atlas,
## the robot idle sprite standing on the ground, and the project's main
## scene pointing at the proof scene.

const PROOF_SCENE := "res://src/proof/proof.tscn"


func test_proof_scene_is_project_main_scene() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene", ""),
		"res://src/proof/proof.tscn",
		"the proof scene is the project main scene."
	)


func test_proof_scene_builds_generated_world() -> void:
	var proof: Node = load(PROOF_SCENE).instantiate()
	add_child(proof)
	var layers := proof.find_children("*", "TileMapLayer", true, false)
	assert_eq(layers.size(), 1, "proof scene has exactly one tile layer.")
	if layers.size() == 1:
		var layer: TileMapLayer = layers[0]
		assert_gt(layer.get_used_cells().size(), 20, "ground and decor cells are populated.")
	var robot_found := false
	var sprites := proof.find_children("*", "Sprite2D", true, false)
	assert_gt(sprites.size(), 0, "proof scene places sprite props.")
	for sprite: Sprite2D in sprites:
		if sprite.texture == AssetFactory.get_texture("robot_idle_0"):
			robot_found = true
	assert_true(robot_found, "robot idle sprite is present.")
	proof.queue_free()


func test_robot_stands_on_ground_row() -> void:
	var proof: Node = load(PROOF_SCENE).instantiate()
	add_child(proof)
	var ground_y := 160.0
	var robot: Sprite2D = null
	for sprite: Sprite2D in proof.find_children("*", "Sprite2D", true, false):
		if sprite.texture == AssetFactory.get_texture("robot_idle_0"):
			robot = sprite
	assert_true(robot != null, "robot sprite found.")
	if robot != null:
		var bottom := robot.position.y + robot.texture.get_height() * 0.5
		assert_eq(bottom, ground_y, "robot feet rest exactly on the ground surface.")
	proof.queue_free()
