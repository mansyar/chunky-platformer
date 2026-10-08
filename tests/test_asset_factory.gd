extends GdToolsTest
## Tests for AssetFactory logic (Foundation Phase 4).
##
## Contract under test: every AssetSpec entry generates a correctly sized,
## non-empty image; results are cached per (asset, palette); area assets
## recolor per palette while robot frames do not; the tile atlas is a
## deterministic grid with stable coordinates.


func _factory() -> Node:
	return get_node("/root/AssetFactory")


func test_factory_generates_every_spec_asset() -> void:
	for entry: Dictionary in AssetSpec.SPEC:
		var img: Image = _factory().get_image(entry["name"], "meadow")
		assert_true(img is Image, "%s produces an Image." % entry["name"])
		if img == null:
			continue
		assert_eq(img.get_width(), entry["size"].x, "%s width matches spec." % entry["name"])
		assert_eq(img.get_height(), entry["size"].y, "%s height matches spec." % entry["name"])
		var has_pixels := false
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.0:
					has_pixels = true
		assert_true(has_pixels, "%s is not fully transparent." % entry["name"])


func test_repeated_calls_return_cached_objects() -> void:
	var a: Image = _factory().get_image("gem", "meadow")
	var b: Image = _factory().get_image("gem", "meadow")
	assert_true(a == b, "repeated get_image returns the cached Image instance.")
	var ta: Texture2D = _factory().get_texture("gem", "meadow")
	var tb: Texture2D = _factory().get_texture("gem", "meadow")
	assert_true(ta == tb, "repeated get_texture returns the cached texture instance.")


func test_area_assets_vary_by_palette() -> void:
	var meadow: Image = _factory().get_image("tile_solid", "meadow")
	var cave: Image = _factory().get_image("tile_solid", "cave")
	assert_false(meadow == cave, "area assets are distinct objects per palette.")
	assert_true(meadow.get_pixel(8, 8) != cave.get_pixel(8, 8), "area assets recolor per palette.")


func test_robot_frames_share_one_generation() -> void:
	var meadow: Image = _factory().get_image("robot_idle_0", "meadow")
	var cave: Image = _factory().get_image("robot_idle_0", "cave")
	assert_true(meadow == cave, "robot frames ignore the area palette argument.")


func test_tile_atlas_geometry() -> void:
	var atlas: Image = _factory().get_tile_atlas("meadow").get_image()
	assert_eq(atlas.get_width(), 64, "atlas is 4 tiles wide.")
	assert_eq(atlas.get_height(), 32, "atlas is 2 tiles tall for 8 entries.")
	assert_eq(
		_factory().get_tile_atlas_coords("tile_solid", "meadow"),
		Vector2i(0, 0),
		"first atlas entry maps to the origin."
	)
	assert_eq(
		_factory().get_tile_atlas_coords("sky_strip", "meadow"),
		Vector2i(3, 1),
		"last atlas entry maps to the second row."
	)


func test_unknown_asset_returns_null() -> void:
	assert_true(
		_factory().get_image("does_not_exist") == null, "unknown assets warn and return null."
	)
