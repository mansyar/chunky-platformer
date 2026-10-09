extends GdToolsTest
## Reachability tests for every area layout (Phase 6).
##
## The meadow was hand-built and playtested; the cave and sunset were drafted
## as data and never checked against the physics they must serve. These tests
## encode the rules a 4-year-old depends on:
##
##   1. Every area is walkable end to end: no column-to-column height change
##      larger than two tiles (32px). A sheer cliff is a frustration trap.
##   2. Every key sits at its declared reach tier: walk = a stroll, jump = one
##      hop (apex 48px), bounce = on a trampoline's vertical arc.
##   3. Every gem falls into a reachable tier, with enough of each kind that
##      no single mechanic is the only way forward.
##   4. Doors, trampolines and the spawn point sit exactly on surfaces - a
##      buried or floating prop is a bug a child sees instantly.
##   5. Trampoline pad art sits in the tile row above the surface it stands on.

const TILE := 16.0
const ROBOT_HALF_HEIGHT := 14.0
const DOOR_HALF_HEIGHT := 24.0
const STEP_MAX := 32.0  # two tiles; what step-assist can climb hands-free
const JUMP_APEX := Tuning.JUMP_IMPULSE * Tuning.JUMP_IMPULSE / (2.0 * Tuning.GRAVITY)
const BOUNCE_APEX := Tuning.BOUNCE_IMPULSE * Tuning.BOUNCE_IMPULSE / (2.0 * Tuning.GRAVITY)

# --- geometry helpers -------------------------------------------------------


func _profile(layout: AreaLayout) -> PackedFloat64Array:
	## Surface height per column from spans plus the ground floor. One-way
	## platforms are deliberately excluded: they are optional routes, not the
	## walkable floor a child can always rely on.
	var p := PackedFloat64Array()
	p.resize(layout.cols)
	for c: int in layout.cols:
		p[c] = float(layout.ground_row) * TILE
		for span: Dictionary in layout.spans:
			if c >= int(span["from"]) and c < int(span["to"]):
				p[c] = minf(p[c], float(span["top_row"]) * TILE)
	return p


func _surface_below(layout: AreaLayout, x: float, y: float) -> float:
	## The topmost walkable surface at x that sits at or below y.
	var best := float(layout.ground_row) * TILE
	for span: Dictionary in layout.spans:
		var top := float(span["top_row"]) * TILE
		if x >= float(int(span["from"])) * TILE and x < float(int(span["to"])) * TILE:
			if top >= y:
				best = minf(best, top)
	for platform: Dictionary in layout.platforms:
		var at: Vector2 = platform["at"]
		var half: float = platform["width"] / 2.0
		if x >= at.x - half and x <= at.x + half and at.y >= y:
			best = minf(best, at.y)
	return best


func _is_buried(layout: AreaLayout, x: float, y: float) -> bool:
	if y > float(layout.ground_row) * TILE:
		return true
	for span: Dictionary in layout.spans:
		if x >= float(int(span["from"])) * TILE and x < float(int(span["to"])) * TILE:
			if y > float(span["top_row"]) * TILE:
				return true
	return false


func _classify_tier(layout: AreaLayout, pos: Vector2) -> String:
	## Which reach tier genuinely reaches this spot. Walk wins ties; a trampoline
	## arc only counts if the item is on it AND clear of the pad itself.
	assert_false(
		_is_buried(layout, pos.x, pos.y), "%s: %s is inside solid ground." % [layout.area_name, pos]
	)
	var surface := _surface_below(layout, pos.x, pos.y)
	var height_above := surface - pos.y
	if height_above >= 8.0 and height_above <= 20.0:
		return "walk"
	if height_above > 20.0 and height_above <= JUMP_APEX + 8.0:
		return "jump"
	for trampoline: Vector2 in layout.trampolines:
		var base := _surface_below(layout, trampoline.x, trampoline.y)
		var apex := base - BOUNCE_APEX
		if absf(pos.x - trampoline.x) <= 24.0 and pos.y >= apex + 8.0 and pos.y <= base - 24.0:
			return "bounce"
	return "none"


# --- the tests --------------------------------------------------------------


func test_every_area_is_walkable_end_to_end() -> void:
	# From spawn column to door column, no step may exceed two tiles. This is
	# the test that would have caught the meadow's original blocking hill.
	for layout: AreaLayout in AreaLayout.all():
		var p := _profile(layout)
		for c: int in layout.cols - 1:
			assert_lte(
				absf(p[c + 1] - p[c]),
				STEP_MAX,
				(
					"%s: cols %d->%d step %.0fpx - a child cannot climb that."
					% [layout.area_name, c, c + 1, absf(p[c + 1] - p[c])]
				)
			)


func test_every_key_sits_at_its_declared_tier() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var seen := {}
		for spot: Dictionary in layout.key_spots:
			var at: Vector2 = spot["at"]
			var tier: String = spot["tier"]
			assert_eq(
				_classify_tier(layout, at),
				tier,
				(
					"%s: the %s key at %s is not actually %s-reachable."
					% [layout.area_name, tier, at, tier]
				)
			)
			seen[tier] = true
		for tier: String in AreaLayout.KEY_TIERS:
			assert_true(seen.has(tier), "%s needs a %s key." % [layout.area_name, tier])


func test_every_gem_falls_into_a_reachable_tier() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var counts := {"walk": 0, "jump": 0, "bounce": 0}
		for spot: Vector2 in layout.gem_spots:
			var tier := _classify_tier(layout, spot)
			assert_true(
				counts.has(tier) and tier != "none",
				"%s: gem at %s is unreachable (%s)." % [layout.area_name, spot, tier]
			)
			if counts.has(tier):
				counts[tier] += 1
		assert_gte(counts["walk"], 6, "%s needs a walk-tier gem majority." % layout.area_name)
		assert_gte(counts["jump"], 2, "%s needs jump-tier gems." % layout.area_name)
		assert_gte(counts["bounce"], 2, "%s needs bounce-tier gems." % layout.area_name)


func test_every_door_is_seated_on_its_surface() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var surface := _surface_below(layout, layout.door_at.x, layout.door_at.y)
		assert_almost_eq(
			layout.door_at.y + DOOR_HALF_HEIGHT,
			surface,
			2.0,
			"%s: the door at %s floats or is buried." % [layout.area_name, layout.door_at]
		)


func test_every_trampoline_sits_on_a_surface() -> void:
	for layout: AreaLayout in AreaLayout.all():
		for trampoline: Vector2 in layout.trampolines:
			var surface := _surface_below(layout, trampoline.x, trampoline.y)
			assert_almost_eq(
				trampoline.y,
				surface,
				2.0,
				"%s: trampoline at %s floats or is buried." % [layout.area_name, trampoline]
			)


func test_every_trampolines_pad_art_matches_its_foot() -> void:
	for layout: AreaLayout in AreaLayout.all():
		assert_eq(
			layout.pad_cells.size(),
			layout.trampolines.size(),
			"%s: every trampoline needs painted pad art." % layout.area_name
		)
		for i: int in layout.pad_cells.size():
			var trampoline: Vector2 = layout.trampolines[i]
			var pad: Vector2i = layout.pad_cells[i]
			assert_eq(
				float(pad.x) * TILE + 8.0,
				trampoline.x,
				"%s: pad art column must sit under the trampoline." % layout.area_name
			)
			var surface := _surface_below(layout, trampoline.x, trampoline.y)
			assert_eq(
				pad.y,
				int(surface / TILE) - 1,
				"%s: pad art must sit in the tile row above the surface." % layout.area_name
			)


func test_the_spawn_point_stands_on_the_ground() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var surface := _surface_below(layout, layout.robot_spawn.x, layout.robot_spawn.y)
		assert_almost_eq(
			layout.robot_spawn.y + ROBOT_HALF_HEIGHT,
			surface,
			2.0,
			"%s: Robo does not spawn standing on the ground." % layout.area_name
		)


func test_every_area_seals_its_edges_the_same_way() -> void:
	# The 8px wall is centred on the wall x, so it only covers the level edge
	# when placed at -4. The meadow learned this in review; all areas follow.
	for layout: AreaLayout in AreaLayout.all():
		assert_lte(layout.walls[0], -4.0, "%s: left wall leaves a gap." % layout.area_name)
		assert_gte(layout.walls[1], 644.0, "%s: right wall leaves a gap." % layout.area_name)
