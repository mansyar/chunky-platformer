extends GdToolsTest
## Tests for the asset-spec completeness contract (Foundation Phase 3).
##
## The asset spec is the single source of truth for every generated visual.
## These tests lock the data contract: unique names, valid kinds and sizes,
## palette references that resolve, and the exact asset set promised by the
## track spec (16 tiles, 8 robot frames, gem, key, door locked/open).

const TILE_KINDS := ["tile", "deco", "background"]
const FRAME_KIND := "frame"
const PROP_KIND := "prop"


func test_spec_is_not_empty() -> void:
	assert_gt(AssetSpec.SPEC.size(), 0, "asset spec defines at least one asset.")


func test_every_entry_has_required_fields() -> void:
	for entry: Dictionary in AssetSpec.SPEC:
		var name: String = entry.get("name", "")
		assert_gt(name.length(), 0, "entry has a name.")
		assert_has(
			["tile", "deco", "background", "frame", "prop", "ui"],
			entry.get("kind", ""),
			"%s has a valid kind." % name
		)
		var size: Vector2i = entry.get("size", Vector2i.ZERO)
		assert_gt(size.x, 0, "%s has positive width." % name)
		assert_gt(size.y, 0, "%s has positive height." % name)
		assert_has(
			["robot", "area"],
			entry.get("palette", ""),
			"%s references a known palette slot." % name
		)


func test_every_entry_has_unique_name() -> void:
	var names := {}
	for entry: Dictionary in AssetSpec.SPEC:
		var name: String = entry.get("name", "")
		assert_false(names.has(name), "asset name '%s' is unique." % name)
		names[name] = true


func test_area_palettes_define_required_colors() -> void:
	for palette_name: String in ["meadow", "cave", "sunset"]:
		var palette: Dictionary = Palettes.AREA_PALETTES[palette_name]
		for key: String in ["sky_top", "sky_bottom", "ground", "ground_dark", "grass", "accent"]:
			assert_has(palette, key, "%s palette defines '%s'." % [palette_name, key])


func test_robot_palette_defines_required_colors() -> void:
	for key: String in ["body", "body_dark", "eye", "eye_glow", "accent"]:
		assert_has(Palettes.PALETTE_ROBOT, key, "robot palette defines '%s'." % key)


func test_spec_defines_sixteen_tiles() -> void:
	var tile_names := []
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") in TILE_KINDS:
			tile_names.append(entry.get("name", ""))
	assert_eq(
		tile_names.size(),
		16,
		"spec defines exactly 16 world tiles/decorations (8 base + 8 area-personality)."
	)


func test_spec_defines_area_personality_deco_sets() -> void:
	# Rich set = 4+ prop types per area. Cave: crystals + stalactites +
	# glow-shrooms + moss. Sunset: buttes + tufts + sunblooms + pebbles.
	var deco := {}
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") == "deco":
			deco[entry.get("name", "")] = entry
	for required: String in [
		"deco_crystal",
		"deco_stalactite",
		"deco_glowshroom",
		"deco_moss",
		"deco_butte",
		"deco_sunset_tuft",
		"deco_sunbloom",
		"deco_pebble",
	]:
		assert_has(deco, required, "spec defines the '%s' personality deco." % required)
		assert_eq(
			deco[required].get("size", Vector2i.ZERO),
			Vector2i(16, 16),
			"'%s' is a 16px tile." % required
		)
		assert_eq(
			deco[required].get("palette", ""), "area", "'%s' recolors per area palette." % required
		)


func test_personality_palette_keys() -> void:
	var cave: Dictionary = Palettes.AREA_PALETTES["cave"]
	for key: String in ["crystal", "crystal_dark", "glow", "moss"]:
		assert_has(cave, key, "cave palette defines '%s'." % key)
	var sunset: Dictionary = Palettes.AREA_PALETTES["sunset"]
	for key: String in ["butte", "butte_dark", "bloom", "pebble"]:
		assert_has(sunset, key, "sunset palette defines '%s'." % key)


func test_meadow_palette_is_untouched() -> void:
	# The meadow is the byte-identical baseline: its palette keeps exactly
	# the 6 base colors, no personality keys.
	var meadow: Dictionary = Palettes.AREA_PALETTES["meadow"]
	assert_eq(meadow.keys().size(), 6, "meadow palette keeps exactly its 6 base colors.")


func test_spec_defines_eight_robot_frames() -> void:
	var frame_names := []
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") == FRAME_KIND:
			frame_names.append(entry.get("name", ""))
	assert_eq(frame_names.size(), 8, "spec defines exactly 8 robot frames.")


func test_robot_frame_set_matches_animation_plan() -> void:
	var expected := [
		"robot_idle_0",
		"robot_idle_1",
		"robot_walk_0",
		"robot_walk_1",
		"robot_walk_2",
		"robot_walk_3",
		"robot_jump",
		"robot_land",
	]
	var frame_names := []
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") == FRAME_KIND:
			frame_names.append(entry.get("name", ""))
	frame_names.sort()
	var expected_sorted := expected.duplicate()
	expected_sorted.sort()
	assert_eq(
		frame_names, expected_sorted, "robot frames cover idle x2, walk x4, jump, land-squash."
	)


func test_spec_defines_props() -> void:
	var prop_names := {}
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") == PROP_KIND:
			prop_names[entry.get("name", "")] = true
	for required: String in ["gem", "key", "door_locked", "door_open"]:
		assert_has(prop_names, required, "spec defines the '%s' prop." % required)


func test_spec_defines_three_touch_buttons() -> void:
	var ui_assets := {}
	for entry: Dictionary in AssetSpec.SPEC:
		if entry.get("kind", "") == "ui":
			ui_assets[entry.get("name", "")] = entry
	for required: String in ["touch_left", "touch_right", "touch_jump"]:
		assert_has(ui_assets, required, "spec defines the '%s' touch button." % required)
		assert_eq(
			ui_assets[required].get("size", Vector2i.ZERO),
			Vector2i(24, 24),
			"%s is a chunky 24px button." % required
		)


func test_spec_defines_ten_digit_glyphs() -> void:
	for i: int in range(10):
		var name := "digit_%d" % i
		var found: Dictionary = {}
		for entry: Dictionary in AssetSpec.SPEC:
			if entry.get("name", "") == name:
				found = entry
				break
		assert_eq(
			found.get("kind", ""), "ui", "%s is a ui asset (code-generated pixel digit)." % name
		)
		assert_eq(found.get("size", Vector2i.ZERO), Vector2i(8, 12), "%s is an 8x12 glyph." % name)
		assert_eq(found.get("palette", ""), "robot", "%s uses the robot palette." % name)
