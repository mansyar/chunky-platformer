extends GdToolsTest
## Area-personality placement guards (Phase 2).
##
## Cave + sunset dress richly with hand-placed bg props while the meadow stays
## byte-identical. These tests pin the data contract: rich distinct sets,
## validated seating/bounds/determinism, bg-layer wiring with zero collision,
## and readable gameplay (no occlusion of gems/keys/door/machine/spawn).

const TILE := 16.0
const PROP_HALF := 8.0
const CLEAR_GEM_KEY := 24.0
const CAVE_SET := ["deco_crystal", "deco_stalactite", "deco_glowshroom", "deco_moss"]
const SUNSET_SET := ["deco_butte", "deco_sunset_tuft", "deco_sunbloom", "deco_pebble"]


func _surface(layout: AreaLayout, x: float) -> float:
	# Terrain surface only (spans + ground floor): platforms are optional
	# routes, never the seat a prop relies on.
	var best := float(layout.ground_row) * TILE
	for span: Dictionary in layout.spans:
		if x >= float(int(span["from"])) * TILE and x < float(int(span["to"])) * TILE:
			best = minf(best, float(span["top_row"]) * TILE)
	return best


func _seated(layout: AreaLayout, pos: Vector2) -> bool:
	# Standing props rest their base on terrain; hanging stalactites hook
	# their top under the cave bridge instead of floating mid-air.
	var bottom := pos.y + PROP_HALF
	if absf(bottom - _surface(layout, pos.x)) <= 2.0:
		return true
	for platform: Dictionary in layout.platforms:
		var at: Vector2 = platform["at"]
		var half: float = float(platform["width"]) / 2.0
		if pos.x >= at.x - half and pos.x <= at.x + half:
			if absf(pos.y - PROP_HALF - at.y) <= 2.0:
				return true
	return false


func _types(layout: AreaLayout) -> Array[String]:
	var seen: Array[String] = []
	for prop: Dictionary in layout.props:
		var asset: String = prop["asset"]
		if not seen.has(asset):
			seen.append(asset)
	return seen


func test_cave_props_are_rich_and_cave_only() -> void:
	var layout := AreaLayout.cave()
	assert_gte(layout.props.size(), 5, "the cave dresses richly, not with one token prop.")
	assert_lte(layout.props.size(), 8, "the cave stays readable, not cluttered.")
	assert_gte(_types(layout).size(), 4, "the cave shows 4+ prop types.")
	for prop: Dictionary in layout.props:
		assert_true(
			CAVE_SET.has(prop["asset"]),
			"cave prop '%s' belongs to the cave vocabulary." % prop["asset"]
		)


func test_sunset_props_are_rich_and_sunset_only() -> void:
	var layout := AreaLayout.sunset()
	assert_gte(layout.props.size(), 5, "the sunset dresses richly.")
	assert_lte(layout.props.size(), 8, "the sunset stays readable.")
	assert_gte(_types(layout).size(), 4, "the sunset shows 4+ prop types.")
	for prop: Dictionary in layout.props:
		assert_true(
			SUNSET_SET.has(prop["asset"]),
			"sunset prop '%s' belongs to the sunset vocabulary." % prop["asset"]
		)


func test_meadow_props_stay_empty() -> void:
	assert_eq(AreaLayout.meadow().props, [], "the meadow keeps its baseline: no props.")


func test_every_area_validates_with_props() -> void:
	for layout: AreaLayout in AreaLayout.all():
		assert_eq(
			layout.validate().size(),
			0,
			"the %s layout (with props) has no problems: %s" % [layout.area_name, layout.validate()]
		)


func test_props_are_deterministic() -> void:
	# Layouts are hand-placed data: rebuilding must give the same list back,
	# never a reshuffled room.
	for area in ["cave", "sunset"]:
		var first: AreaLayout = AreaLayout.all()[1] if area == "cave" else AreaLayout.all()[2]
		var second: AreaLayout = AreaLayout.cave() if area == "cave" else AreaLayout.sunset()
		assert_eq(first.props, second.props, "the %s props are deterministic." % area)


func test_props_stay_inside_bounds() -> void:
	for layout: AreaLayout in AreaLayout.all():
		for prop: Dictionary in layout.props:
			var at: Vector2 = prop["at"]
			assert_gte(
				at.x - PROP_HALF, 0.0, "%s prop %s leaves the left edge." % [layout.area_name, at]
			)
			assert_lte(
				at.x + PROP_HALF,
				float(layout.cols) * TILE,
				"%s prop %s leaves the right edge." % [layout.area_name, at]
			)
			assert_gte(at.y - PROP_HALF, 0.0, "%s prop %s leaves the sky." % [layout.area_name, at])
			assert_lte(
				at.y + PROP_HALF,
				float(layout.rows - 1) * TILE,
				"%s prop %s sinks past the world." % [layout.area_name, at]
			)


func test_props_are_seated() -> void:
	for layout: AreaLayout in AreaLayout.all():
		for prop: Dictionary in layout.props:
			assert_true(
				_seated(layout, prop["at"]),
				(
					"%s prop '%s' at %s floats: base must touch terrain or hook the bridge."
					% [layout.area_name, prop["asset"], prop["at"]]
				)
			)


func test_props_keep_gameplay_readable() -> void:
	# Small gems/keys need a clear halo; big door/machine bodies must not
	# overlap a prop rect; pads and deco tiles keep their own cells.
	for layout: AreaLayout in AreaLayout.all():
		for prop: Dictionary in layout.props:
			var at: Vector2 = prop["at"]
			for spot: Vector2 in layout.gem_spots:
				assert_gte(
					at.distance_to(spot),
					CLEAR_GEM_KEY,
					"%s prop at %s crowds a gem at %s." % [layout.area_name, at, spot]
				)
			for spot: Dictionary in layout.key_spots:
				assert_gte(
					at.distance_to(spot["at"]),
					CLEAR_GEM_KEY,
					"%s prop at %s crowds the %s key." % [layout.area_name, at, spot["tier"]]
				)
			for spot: Vector2 in layout.trampolines:
				assert_gte(
					at.distance_to(spot),
					CLEAR_GEM_KEY,
					"%s prop at %s crowds a trampoline." % [layout.area_name, at]
				)
			assert_gte(
				at.distance_to(layout.robot_spawn),
				CLEAR_GEM_KEY,
				"%s prop at %s crowds Robo's spawn." % [layout.area_name, at]
			)
			# Door and machine are 32x48 bodies: rect non-overlap, not a halo.
			for body: Vector2 in [layout.door_at, layout.machine_at]:
				var overlaps := absf(at.x - body.x) < 24.0 and absf(at.y - body.y) < 32.0
				assert_false(
					overlaps,
					"%s prop at %s overlaps a 32x48 body at %s." % [layout.area_name, at, body]
				)
			for cell: Vector2i in layout.pad_cells:
				var center := Vector2(float(cell.x) * TILE + 8.0, float(cell.y) * TILE + 8.0)
				assert_gte(
					at.distance_to(center),
					PROP_HALF + PROP_HALF,
					"%s prop at %s paints over pad art." % [layout.area_name, at]
				)
			for asset_name: String in layout.deco:
				for cell: Vector2i in layout.deco[asset_name]:
					var center := Vector2(float(cell.x) * TILE + 8.0, float(cell.y) * TILE + 8.0)
					assert_gte(
						at.distance_to(center),
						PROP_HALF + PROP_HALF,
						"%s prop at %s paints over deco '%s'." % [layout.area_name, at, asset_name]
					)


func test_builder_paints_props_behind_gameplay() -> void:
	# Props are plain sprites on the bg layer: visible, behind everything
	# interactive, and adding zero physics bodies.
	for layout: AreaLayout in AreaLayout.all():
		var builder := AreaBuilder.new()
		add_child(builder)
		builder.build(layout)
		var world := builder.find_child("World", true, false)
		var sprites := 0
		for child: Node in world.get_children():
			if child is Sprite2D:
				sprites += 1
				assert_lt(
					(child as Sprite2D).z_index,
					0,
					"the %s props paint behind gameplay." % layout.area_name
				)
		assert_eq(sprites, layout.props.size(), "one sprite per %s prop." % layout.area_name)
		assert_eq(
			builder.find_children("*", "StaticBody2D", true, false).size(),
			4,
			"the %s props add no collision (bridge/platform + 2 walls + door)." % layout.area_name
		)
