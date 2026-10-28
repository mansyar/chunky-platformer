extends GdToolsTest
## Snapshot tests pinning the area-personality deco outputs (Phase 1).
##
## Cave (crystal/stalactite/glow set) and sunset (butte/tuft/warm set) prop
## art is locked at fixed pixels so regressions fail loudly, plus a
## determinism check across both area palettes. Split from
## test_asset_snapshots.gd so no scope exceeds the method limit.


func _fresh_factory() -> Node:
	return load("res://src/factory/asset_factory.gd").new()


func test_deco_crystal_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_crystal", "cave")
	var p: Dictionary = Palettes.AREA_PALETTES["cave"]
	assert_eq(img.get_pixel(7, 5), p["crystal"], "crystal tip reads as crystal color.")
	assert_eq(img.get_pixel(6, 7), p["glow"], "crystal face carries a warm highlight.")
	assert_eq(img.get_pixel(8, 12), p["crystal_dark"], "crystal base reads as crystal-dark.")
	assert_eq(img.get_pixel(0, 0).a, 0.0, "crystal keeps a transparent backdrop.")


func test_deco_stalactite_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_stalactite", "cave")
	var p: Dictionary = Palettes.AREA_PALETTES["cave"]
	assert_eq(img.get_pixel(8, 1), p["crystal_dark"], "stalactite bar reads as crystal-dark.")
	assert_eq(img.get_pixel(6, 9), p["crystal"], "long tooth ends rounded in crystal.")
	assert_eq(img.get_pixel(11, 7), p["crystal"], "short tooth ends rounded in crystal.")
	assert_eq(img.get_pixel(0, 15).a, 0.0, "stalactite hangs in transparency.")


func test_deco_glowshroom_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_glowshroom", "cave")
	var p: Dictionary = Palettes.AREA_PALETTES["cave"]
	assert_eq(img.get_pixel(8, 7), p["crystal"], "glowshroom cap reads as crystal color.")
	assert_eq(img.get_pixel(6, 6), p["glow"], "cap spots glow warm.")
	assert_eq(img.get_pixel(7, 14), p["moss"], "glowshroom sits in a mossy base.")


func test_deco_moss_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_moss", "cave")
	var p: Dictionary = Palettes.AREA_PALETTES["cave"]
	assert_eq(img.get_pixel(5, 13), p["moss"], "moss body reads as moss color.")
	assert_eq(img.get_pixel(5, 10), p["glow"], "moss carries glow specks.")
	assert_eq(img.get_pixel(0, 0).a, 0.0, "moss keeps a transparent backdrop.")


func test_deco_butte_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_butte", "sunset")
	var p: Dictionary = Palettes.AREA_PALETTES["sunset"]
	assert_eq(img.get_pixel(8, 5), p["butte"], "butte dome reads as butte color.")
	assert_eq(img.get_pixel(6, 7), p["bloom"], "butte carries a warm sun spot.")
	assert_eq(img.get_pixel(8, 14), p["butte_dark"], "butte base reads as butte-dark.")


func test_deco_sunset_tuft_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_sunset_tuft", "sunset")
	var p: Dictionary = Palettes.AREA_PALETTES["sunset"]
	assert_eq(img.get_pixel(7, 12), p["grass"], "tuft blades read as grass color.")
	assert_eq(img.get_pixel(5, 7), p["bloom"], "left seed head reads warm bloom.")
	assert_eq(img.get_pixel(10, 7), p["bloom"], "right seed head reads warm bloom.")


func test_deco_sunbloom_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_sunbloom", "sunset")
	var p: Dictionary = Palettes.AREA_PALETTES["sunset"]
	assert_eq(img.get_pixel(8, 6), p["accent"], "sunbloom center reads as accent.")
	assert_eq(img.get_pixel(5, 6), p["bloom"], "sunbloom petals read as bloom color.")
	assert_eq(img.get_pixel(7, 14), p["grass"], "sunbloom stem reads as grass color.")


func test_deco_pebble_structure() -> void:
	var img: Image = get_node("/root/AssetFactory").get_image("deco_pebble", "sunset")
	var p: Dictionary = Palettes.AREA_PALETTES["sunset"]
	var glow: Color = p.get("glow", Color(1, 1, 1))
	assert_eq(img.get_pixel(5, 12), p["pebble"], "left stone reads as pebble color.")
	assert_eq(img.get_pixel(11, 13), p["pebble"], "right stone reads as pebble color.")
	assert_eq(img.get_pixel(10, 11), glow, "pebbles carry a warm glint.")


func test_personality_deco_is_deterministic() -> void:
	var a := _fresh_factory()
	var b := _fresh_factory()
	for asset_name: String in [
		"deco_crystal",
		"deco_stalactite",
		"deco_glowshroom",
		"deco_moss",
		"deco_butte",
		"deco_sunset_tuft",
		"deco_sunbloom",
		"deco_pebble",
	]:
		for palette_name: String in ["cave", "sunset"]:
			var img_a: Image = a.get_image(asset_name, palette_name)
			var img_b: Image = b.get_image(asset_name, palette_name)
			assert_true(
				img_a.get_data() == img_b.get_data(),
				(
					"%s (%s) generates byte-identical output across instances."
					% [asset_name, palette_name]
				)
			)
	a.free()
	b.free()
