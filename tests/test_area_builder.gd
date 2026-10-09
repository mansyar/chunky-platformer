extends GdToolsTest
## Tests for area layout records and the shared area builder (Phase 1).
##
## A layout is the whole world expressed as data. These tests pin two things:
## that a layout can be checked for nonsense before it ever builds, and that
## the meadow layout reproduces the hand-built playground terrain exactly.

const LAYOUT_SCRIPT := "res://src/levels/area_layout.gd"
const BUILDER_SCRIPT := "res://src/levels/area_builder.gd"


func _meadow() -> AreaLayout:
	return AreaLayout.meadow()


# --- record shape -----------------------------------------------------------


func test_meadow_layout_is_valid() -> void:
	var problems: PackedStringArray = _meadow().validate()
	assert_eq(problems.size(), 0, "the meadow layout has no problems: %s" % [problems])


func test_every_area_validates() -> void:
	# The cave and sunset layouts exist as data from day one so the goal loop's
	# soft-lock invariant is enforced before a child ever reaches them. A layout
	# missing a key tier would strand the player in an unwinnable area.
	for layout: AreaLayout in AreaLayout.all():
		assert_eq(
			layout.validate().size(),
			0,
			"the %s layout is playable: %s" % [layout.area_name, layout.validate()]
		)


func test_the_three_areas_have_distinct_terrain_and_palettes() -> void:
	var names: Array[String] = []
	var palettes: Array[String] = []
	var terrain: Array[String] = []
	for layout: AreaLayout in AreaLayout.all():
		names.append(layout.area_name)
		palettes.append(layout.palette)
		terrain.append(str(layout.spans))
	assert_eq(names, ["meadow", "cave", "sunset"], "the three areas keep their play order.")
	assert_eq(palettes, ["meadow", "cave", "sunset"], "each area has its own palette.")
	assert_ne(terrain[0], terrain[1], "the cave is not the meadow with a recolour.")
	assert_ne(terrain[0], terrain[2], "the sunset is not the meadow with a recolour.")
	assert_ne(terrain[1], terrain[2], "the sunset is not the cave with a recolour.")


func test_layout_validation_catches_a_nameless_layout() -> void:
	var layout := AreaLayout.new()
	layout.area_name = ""
	layout.palette = "meadow"
	assert_true(layout.validate().has("name is empty"), "a layout without a name is rejected.")


func test_layout_validation_catches_an_unknown_palette() -> void:
	var layout := AreaLayout.new()
	layout.area_name = "nowhere"
	layout.palette = "lava"
	assert_true(
		layout.validate().has("unknown palette 'lava'"),
		"a layout asking for a palette that does not exist is rejected."
	)


func test_layout_validation_catches_out_of_bounds_spans() -> void:
	var layout := AreaLayout.new()
	layout.area_name = "wide"
	layout.palette = "meadow"
	layout.cols = 10
	layout.spans = [{"from": 4, "to": 99, "top_row": 28}]
	assert_true(
		layout.validate().has("span 4..99 runs past 10 columns"),
		"a span wider than the level is rejected."
	)


func test_layout_validation_requires_three_keys_one_per_reach_tier() -> void:
	var layout := AreaLayout.new()
	layout.area_name = "meadow"
	layout.palette = "meadow"
	layout.key_spots = [
		{"tier": "walk", "at": Vector2(10, 500)},
		{"tier": "walk", "at": Vector2(20, 500)},
	]
	assert_true(
		layout.validate().has("expected 3 key spots, found 2"), "too few keys is a layout error."
	)
	layout.key_spots.append({"tier": "walk", "at": Vector2(30, 500)})
	assert_true(
		layout.validate().has("expected one key per tier, walk has 3"),
		"three keys at the same reach tier is a layout error."
	)
	layout.key_spots[1] = {"tier": "jump", "at": Vector2(20, 460)}
	layout.key_spots[2] = {"tier": "bounce", "at": Vector2(30, 400)}
	layout.cols = 40
	layout.rows = 34
	layout.ground_row = 32
	assert_eq(
		layout.validate().size(),
		0,
		"one key per reach tier is a valid layout: %s" % [layout.validate()]
	)


# --- the meadow regression guard -------------------------------------------


func test_meadow_terrain_matches_the_hand_built_playground() -> void:
	# The Movement track hand-placed every row of the meadow. These spans are
	# that terrain written down: if the builder reshapes the level, this fails
	# before anything else can notice.
	var expected := [
		{"from": 0, "to": 12, "top_row": 28},  # low hill plateau
		{"from": 12, "to": 14, "top_row": 30},  # its staircase step
		{"from": 24, "to": 26, "top_row": 30},  # tall hill, lowest step
		{"from": 26, "to": 28, "top_row": 28},  # tall hill, middle step
		{"from": 28, "to": 30, "top_row": 26},  # tall hill, top step
		{"from": 30, "to": 40, "top_row": 24},  # tall hill plateau
	]
	assert_eq(_meadow().spans, expected, "the meadow terrain is unchanged.")
	assert_eq(_meadow().ground_row, 32, "the ground floor is still at row 32.")
	assert_eq(_meadow().cols, 40, "the meadow is still 40 columns wide.")


func test_meadow_keeps_its_trampoline_elevator_and_bridge() -> void:
	var layout := _meadow()
	assert_eq(
		layout.trampolines,
		[Vector2(328, 512), Vector2(176, 448)],
		"both trampolines survive the refactor."
	)
	assert_eq(layout.platforms, [{"width": 144.0, "at": Vector2(280, 400)}], "the bridge survives.")
	assert_eq(layout.walls, [-4.0, 644.0], "the level still closes at both ends.")


# --- the builder ------------------------------------------------------------


func _built() -> Node2D:
	var builder: Node = load(BUILDER_SCRIPT).new()
	add_child(builder)
	builder.build(_meadow())
	return builder


func test_builder_creates_a_world_with_the_expected_parts() -> void:
	var level := _built()
	assert_not_null(level.find_child("World", true, false), "the builder makes a World.")
	assert_not_null(level.find_child("Robo", true, false), "the builder places Robo.")
	assert_not_null(level.find_child("FollowCamera", true, false), "the builder frames the camera.")
	assert_not_null(
		level.find_child("GemCounter", true, false), "the builder shows the gem counter."
	)


func test_builder_paints_exactly_the_cells_the_layout_describes() -> void:
	var level := _built()
	var tile_map := _find_first_tile_map(level)
	assert_not_null(tile_map, "the builder paints a TileMapLayer.")
	var layout := _meadow()
	for x: int in layout.cols:
		assert_ne(
			tile_map.get_cell_source_id(Vector2i(x, layout.ground_row)),
			-1,
			"the ground floor spans the full width at col %d." % x
		)
	# The valley between the hills stays open sky: falling off a hill must
	# drop Robo to the floor, never into a wall.
	for y: int in range(20, 31):
		assert_eq(
			tile_map.get_cell_source_id(Vector2i(18, y)),
			-1,
			"the valley shaft at (18,%d) is open." % y
		)
	for span: Dictionary in layout.spans:
		assert_ne(
			tile_map.get_cell_source_id(Vector2i(span["from"], span["top_row"])),
			-1,
			"span %d starts solid at row %d." % [span["from"], span["top_row"]]
		)


func test_builder_places_the_layout_s_interactives() -> void:
	var level := _built()
	assert_eq(level.find_children("*", "Trampoline", true, false).size(), 2, "both trampolines.")
	assert_eq(
		level.find_children("*", "StaticBody2D", true, false).size(),
		3,
		"one bridge plus a wall at each end"
	)


func test_builder_spawns_one_gem_per_layout_spot() -> void:
	var level := _built()
	assert_eq(
		level.find_children("*", "Gem", true, false).size(),
		_meadow().gem_spots.size(),
		"one gem per layout spot."
	)


func test_builder_shows_the_layout_s_props() -> void:
	var level := _built()
	var found := false
	for child: Node in level.find_child("World", true, false).get_children():
		if child is Sprite2D:
			found = true
	assert_true(found, "the layout's props are painted into the world.")


func test_every_layout_fills_one_gem_tier_per_reach_style() -> void:
	# Gems keep their flat handcrafted list; keys carry an explicit tier. This
	# guards the two lists from drifting into the same shape by accident.
	var layout := _meadow()
	assert_gt(layout.gem_spots.size(), 0, "the meadow still has gems.")
	assert_eq(layout.key_spots.size(), 0, "keys arrive in Phase 2.")


func _find_first_tile_map(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node as TileMapLayer
	for child: Node in node.get_children():
		var found := _find_first_tile_map(child)
		if found != null:
			return found
	return null
