extends GdToolsTest
## Snapshot tests pinning key generated outputs (Foundation Phase 4).
##
## These lock the visual structure of signature assets at fixed pixels so
## accidental regressions in generators fail loudly. They also lock
## determinism: two fresh factory instances must produce byte-identical
## images.


func _fresh_factory() -> Node:
	return load("res://src/factory/asset_factory.gd").new()


func test_tile_grass_top_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("tile_grass_top", "meadow")
	var p: Dictionary = Palettes.AREA_PALETTES["meadow"]
	assert_eq(img.get_pixel(0, 0), p["grass"], "grass strip covers the top edge.")
	assert_eq(img.get_pixel(8, 8), p["ground"], "tile body is ground color.")
	assert_eq(img.get_pixel(8, 15), p["ground_dark"], "bottom edge is the dark soil band.")


func test_tile_solid_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("tile_solid", "meadow")
	var p: Dictionary = Palettes.AREA_PALETTES["meadow"]
	assert_eq(img.get_pixel(8, 8), p["ground"], "solid tile center is ground color.")
	assert_eq(img.get_pixel(8, 15), p["ground_dark"], "solid tile bottom is dark soil.")


func test_gem_center_is_accent() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("gem", "meadow")
	var p: Dictionary = Palettes.AREA_PALETTES["meadow"]
	assert_eq(img.get_pixel(8, 8), p["accent"], "gem body reads as the area accent color.")


func test_key_has_ring_hole_and_shaft() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("key", "meadow")
	var p: Dictionary = Palettes.AREA_PALETTES["meadow"]
	assert_eq(img.get_pixel(5, 5).a, 0.0, "key ring has a transparent hole.")
	assert_eq(img.get_pixel(5, 1), p["accent"], "key ring top is accent color.")
	assert_eq(img.get_pixel(11, 6), p["accent"], "key shaft is accent color.")


func test_doors_differ_and_share_size() -> void:
	var locked: Image = get_node("/root/AssetFactory").get_image("door_locked", "meadow")
	var open: Image = get_node("/root/AssetFactory").get_image("door_open", "meadow")
	assert_eq(
		Vector2i(locked.get_width(), locked.get_height()), Vector2i(32, 48), "doors are 32x48."
	)
	assert_true(
		locked.get_data() != open.get_data(), "locked and open doors are visually distinct."
	)


func test_robot_idle_body_and_eyes() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("robot_idle_0")
	var p: Dictionary = Palettes.PALETTE_ROBOT
	assert_eq(img.get_pixel(9, 9), p["body"], "robot body reads as body color.")
	assert_eq(img.get_pixel(13, 13), p["eye_glow"], "robot pupil reads as eye glow color.")
	assert_eq(img.get_pixel(14, 12), p["eye"], "robot sclera reads as eye color.")


func test_robot_land_is_squashed_wider_than_idle() -> void:
	var land: Image = get_node("/root/AssetFactory").get_image("robot_land")
	var idle: Image = get_node("/root/AssetFactory").get_image("robot_idle_0")
	var p: Dictionary = Palettes.PALETTE_ROBOT
	assert_eq(land.get_pixel(7, 22), p["body"], "land frame body extends wider than idle.")
	assert_eq(idle.get_pixel(6, 22).a, 0.0, "idle frame is transparent at the same pixel.")


func test_land_frame_feet_reach_the_ground() -> void:
	# Landing must look planted: the land frame's feet must reach the canvas
	# bottom line like idle does, or Robo visibly hovers during the squash.
	var factory: Node = get_node("/root/AssetFactory")
	var land: Image = factory.get_image("robot_land")
	var idle: Image = factory.get_image("robot_idle_0")
	var feet_color: Color = Palettes.PALETTE_ROBOT["body_dark"]
	assert_eq(idle.get_pixel(10, 30), feet_color, "idle baseline: feet touch the bottom row.")
	assert_eq(land.get_pixel(11, 30), feet_color, "land feet touch the bottom row (no hover).")


func test_generation_is_deterministic() -> void:
	var a := _fresh_factory()
	var b := _fresh_factory()
	for asset_name: String in ["robot_idle_0", "tile_grass_top", "gem", "door_locked"]:
		var img_a: Image = a.get_image(asset_name, "meadow")
		var img_b: Image = b.get_image(asset_name, "meadow")
		assert_true(
			img_a.get_data() == img_b.get_data(),
			"%s generates byte-identical output across instances." % asset_name
		)
	a.free()
	b.free()


func test_touch_left_button_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("touch_left", "meadow")
	var p: Dictionary = Palettes.PALETTE_ROBOT
	assert_eq(img.get_size(), Vector2i(24, 24), "button is 24px.")
	assert_eq(img.get_pixel(3, 12), p["accent"], "button face is the accent disc.")
	assert_eq(img.get_pixel(7, 12), p["eye"], "left arrow points left in eye white.")


func test_touch_jump_button_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("touch_jump", "meadow")
	var p: Dictionary = Palettes.PALETTE_ROBOT
	assert_eq(img.get_pixel(3, 12), p["accent"], "button face is the accent disc.")
	assert_eq(img.get_pixel(12, 8), p["eye"], "jump arrow points up in eye white.")


func test_walk_stride_leads_right() -> void:
	# The native walk art strides to the RIGHT (flip_h handles left): in each
	# stride frame the extended leg sits on the right half of the canvas,
	# even though its leg_l/leg_r label alternates between stride phases.
	var frames: Dictionary = AssetFactory.ROBOT_FRAMES
	for frame_name: String in ["robot_walk_0", "robot_walk_2"]:
		var frame: Dictionary = frames[frame_name]
		var left: Rect2i = frame["leg_l"]
		var right: Rect2i = frame["leg_r"]
		var extended: Rect2i = left if left.size.y > right.size.y else right
		assert_gt(
			extended.position.x,
			16,
			"%s strides right natively (extended leg on the right half)." % frame_name
		)
