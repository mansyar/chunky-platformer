class_name AreaLayout
extends RefCounted
## One area's world expressed as data instead of code.
##
## The meadow used to be 200 hand-placed lines in playground.gd; the cave and
## the sunset would have doubled and tripled that. A layout is the same
## information in a form you can validate, diff, and read at a glance.
##
## Spans are the terrain primitive: `{"from": col, "to": col_exclusive,
## "top_row": row}` fills solid tiles from that row down to the ground. A
## staircase is a run of spans with descending top rows.

## The reach tiers a key can sit at, from the ground up. The hint system and
## the layout validation both read these names, so a key's difficulty is data
## rather than an accident of its coordinates.
const KEY_TIERS := ["walk", "jump", "bounce"]

## Every layout must hide exactly one key per reach tier: three tiers, three
## keys. A missing bounce key would leave the trampoline pointless; a missing
## walk key would gate progress behind a jump.
const KEYS_PER_AREA := 3  # one per KEY_TIERS entry

## Fixed gem budget: every area holds exactly this many hand-placed gems.
## Collected gems stay collected on revisit (no respawn); the per-area counts
## below are the budget. Reachability pins the mix: >=6 walk, >=2 jump,
## >=2 bounce (see test_every_gem_falls_into_a_reachable_tier).
const GEMS_PER_AREA := 10

var area_name := ""
var palette := ""
var cols := 0
var rows := 0
var ground_row := 0

## Terrain runs, left to right. `to` is exclusive.
var spans: Array[Dictionary] = []

## Decorative tile names mapped to the cells they occupy.
var deco := {}

## Trampoline pad tiles and the Area2D bounce pads that sit on them.
var pad_cells: Array[Vector2i] = []
var trampolines: Array[Vector2] = []

## One-way platforms: `{"width": px, "at": Vector2}`.
var platforms: Array[Dictionary] = []

## World x of the invisible walls closing each end of the level.
var walls: Array[float] = []

## Gems are a flat handcrafted list; keys carry an explicit tier (see
## KEY_TIERS) because the goal loop needs to reason about reach.
var gem_spots: Array[Vector2] = []
var key_spots: Array[Dictionary] = []

## Where the goal door stands, once Phase 3 builds it.
var door_at := Vector2.ZERO

## Prop art to paint as plain sprites: `{"asset": name, "at": Vector2}`.
var props: Array[Dictionary] = []

var robot_spawn := Vector2.ZERO

## Friendly gift machine spot (gem_shop_20261027 Phase 2): seated on a
## walkable surface near the spawn, clear of gems, keys, pads, and the door.
var machine_at := Vector2.ZERO


## Collect every reason this layout is unusable, so a caller can report all
## the problems at once instead of one per run.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if area_name.is_empty():
		problems.append("name is empty")
	if palette.is_empty() or not Palettes.AREA_PALETTES.has(palette):
		problems.append("unknown palette '%s'" % palette)
	if cols <= 0 or rows <= 0:
		problems.append("level needs a positive size")
	for span: Dictionary in spans:
		if span["from"] >= span["to"]:
			problems.append("span %d..%d runs backwards" % [span["from"], span["to"]])
		if span["to"] > cols:
			problems.append("span %d..%d runs past %d columns" % [span["from"], span["to"], cols])
		if span["top_row"] >= ground_row:
			problems.append(
				(
					"span at row %d starts at or below the ground row %d"
					% [span["top_row"], ground_row]
				)
			)
	# Key spots are checked whenever a layout declares any: zero keys means the
	# area simply carries no goal yet, but one or two would soft-lock the child,
	# so a partial set is an error.
	if not key_spots.is_empty():
		if key_spots.size() != KEYS_PER_AREA:
			problems.append("expected %d key spots, found %d" % [KEYS_PER_AREA, key_spots.size()])
		for tier: String in KEY_TIERS:
			var at_tier := 0
			for spot: Dictionary in key_spots:
				if spot.get("tier", "") == tier:
					at_tier += 1
			if at_tier != 1:
				problems.append("expected one key per tier, %s has %d" % [tier, at_tier])
	if not gem_spots.is_empty() and gem_spots.size() != GEMS_PER_AREA:
		problems.append("expected %d gem spots, found %d" % [GEMS_PER_AREA, gem_spots.size()])
	return problems


## The meadow: the Movement track's playground, written down rather than coded.
## This is the regression reference - every other area is free to differ, but
## this one must never change under a child's feet.
static func meadow() -> AreaLayout:
	var l := AreaLayout.new()
	l.area_name = "meadow"
	l.palette = "meadow"
	l.cols = 40
	l.rows = 34
	l.ground_row = 32
	l.spans = [
		{"from": 0, "to": 12, "top_row": 28},  # low hill plateau
		{"from": 12, "to": 14, "top_row": 30},  # its single staircase step
		{"from": 24, "to": 26, "top_row": 30},  # tall hill, lowest step
		{"from": 26, "to": 28, "top_row": 28},  # tall hill, middle step
		{"from": 28, "to": 30, "top_row": 26},  # tall hill, top step
		{"from": 30, "to": 40, "top_row": 24},  # tall hill plateau
	]
	l.deco = {
		"deco_grass_tuft": [Vector2i(3, 27), Vector2i(32, 23), Vector2i(17, 31)],
		"deco_flower": [Vector2i(8, 27), Vector2i(35, 23), Vector2i(20, 31)],
		"deco_rock": [Vector2i(10, 27), Vector2i(37, 23), Vector2i(22, 31)],
	}
	l.pad_cells = [Vector2i(20, 31), Vector2i(11, 27)]
	l.trampolines = [Vector2(328, 512), Vector2(184, 448)]  # x must match its pad cell
	l.platforms = [{"width": 144.0, "at": Vector2(280, 400)}]
	l.walls = [-4.0, 644.0]
	l.gem_spots = [
		# Fixed budget: 10 gems (6 walk + 2 jump + 2 bounce).
		# walk tier - plain walking pickups
		Vector2(60, 436),
		Vector2(140, 436),
		Vector2(240, 500),
		Vector2(380, 500),
		Vector2(416, 436),
		Vector2(520, 372),
		# jump tier - one clean jump apex (48px) above a surface
		Vector2(270, 464),
		Vector2(560, 336),
		# bounce tier - only the trampoline arcs (~133px) reach this high
		Vector2(328, 448),
		Vector2(176, 328),
	]
	l.key_spots = [
		# One key per reach tier, so every way of climbing the meadow leads
		# somewhere new and no tier is a wasted walk.
		{"tier": "walk", "at": Vector2(340, 500)},  # plain walk across the valley floor
		{"tier": "jump", "at": Vector2(432, 412)},  # a hop up the tall hill's middle step
		{"tier": "bounce", "at": Vector2(176, 330)},  # trampolined up to the low plateau
	]
	l.door_at = Vector2(520, 360)
	l.props = []
	l.robot_spawn = Vector2(300, 498)
	l.machine_at = Vector2(88, 424)  # low hill plateau, left of the walk gems
	return l


## The cave: layered and tight. Twin staircase massifs squeeze a deep valley
## in the middle; the bridge crosses it high up and the left trampoline is the
## fun route to the bounce key. Every route stays walkable end to end.
static func cave() -> AreaLayout:
	var l := AreaLayout.new()
	l.area_name = "cave"
	l.palette = "cave"
	l.cols = 40
	l.rows = 34
	l.ground_row = 32
	l.spans = [
		{"from": 0, "to": 10, "top_row": 26},  # left plateau
		{"from": 10, "to": 12, "top_row": 28},  # staircase down
		{"from": 12, "to": 14, "top_row": 30},  # staircase down
		{"from": 26, "to": 28, "top_row": 30},  # staircase up
		{"from": 28, "to": 30, "top_row": 28},  # staircase up
		{"from": 30, "to": 40, "top_row": 26},  # right shelf by the door
	]
	l.deco = {
		"deco_rock": [Vector2i(3, 25), Vector2i(36, 25), Vector2i(28, 27)],
		"deco_grass_tuft": [Vector2i(7, 25), Vector2i(31, 25)],
	}
	l.pad_cells = [Vector2i(5, 25), Vector2i(20, 31)]
	l.trampolines = [Vector2(88, 416), Vector2(328, 512)]
	l.platforms = [
		{"width": 128.0, "at": Vector2(288, 400)},  # the cave bridge
	]
	l.walls = [-4.0, 644.0]
	l.gem_spots = [
		# Fixed budget: 10 gems (6 walk + 2 jump + 2 bounce).
		# walk tier - plain walking pickups
		Vector2(88, 404),
		Vector2(176, 436),
		Vector2(296, 500),
		Vector2(376, 500),
		Vector2(288, 388),  # on the bridge, reached via the elevator
		Vector2(440, 468),
		# jump tier - one clean jump apex (48px) above a surface
		Vector2(120, 368),
		Vector2(536, 368),
		# bounce tier - only the trampoline arcs (~133px) reach this high
		Vector2(88, 336),
		Vector2(328, 440),
	]
	l.key_spots = [
		# One key per reach tier, so every way of climbing the cave leads
		# somewhere new and no tier is a wasted walk.
		{"tier": "walk", "at": Vector2(232, 500)},  # plain walk across the valley floor
		{"tier": "jump", "at": Vector2(464, 400)},  # a hop up the right staircase
		{"tier": "bounce", "at": Vector2(88, 304)},  # trampolined above the left plateau
	]
	l.door_at = Vector2(596, 392)
	l.props = []
	l.robot_spawn = Vector2(240, 498)
	l.machine_at = Vector2(40, 392)  # left plateau, clear of pad + bounce arc
	return l


## The sunset hills: tall and trampoline-driven. A tall central plateau is
## ringed by two-tile steps on both sides, a catch platform floats over the
## valley trampoline, and the door waits on the right shoulder.
static func sunset() -> AreaLayout:
	var l := AreaLayout.new()
	l.area_name = "sunset"
	l.palette = "sunset"
	l.cols = 40
	l.rows = 34
	l.ground_row = 32
	l.spans = [
		{"from": 0, "to": 9, "top_row": 30},  # low left shoulder
		{"from": 9, "to": 11, "top_row": 28},  # staircase up
		{"from": 11, "to": 13, "top_row": 26},  # staircase up
		{"from": 13, "to": 23, "top_row": 24},  # tallest plateau
		{"from": 23, "to": 25, "top_row": 26},  # staircase down
		{"from": 25, "to": 27, "top_row": 28},  # staircase down
		{"from": 27, "to": 29, "top_row": 30},  # staircase down
		{"from": 35, "to": 36, "top_row": 30},  # right approach step
		{"from": 36, "to": 40, "top_row": 28},  # right shoulder by the door
	]
	l.deco = {
		"deco_flower": [Vector2i(5, 29), Vector2i(18, 23), Vector2i(38, 27)],
		"deco_grass_tuft": [Vector2i(2, 29), Vector2i(20, 23)],
		"deco_rock": [Vector2i(24, 25)],
	}
	l.pad_cells = [Vector2i(14, 23), Vector2i(31, 31)]
	l.trampolines = [Vector2(232, 384), Vector2(504, 512)]
	l.platforms = [
		{"width": 80.0, "at": Vector2(504, 384)},  # mid-air catch above the valley
	]
	l.walls = [-4.0, 644.0]
	l.gem_spots = [
		# Fixed budget: 10 gems (6 walk + 2 jump + 2 bounce).
		# walk tier - plain walking pickups
		Vector2(40, 468),
		Vector2(160, 436),
		Vector2(192, 404),
		Vector2(280, 372),
		Vector2(328, 372),
		Vector2(576, 436),
		# jump tier - one clean jump apex (48px) above a surface
		Vector2(344, 336),
		Vector2(616, 400),
		# bounce tier - only the trampoline arcs (~133px) reach this high
		Vector2(232, 300),
		Vector2(504, 440),
	]
	l.key_spots = [
		# One key per reach tier, so every way of climbing the sunset leads
		# somewhere new and no tier is a wasted walk.
		{"tier": "walk", "at": Vector2(72, 468)},  # plain walk along the left shoulder
		{"tier": "jump", "at": Vector2(296, 336)},  # a hop on the tallest plateau
		{"tier": "bounce", "at": Vector2(504, 396)},  # trampolined up the valley arc
	]
	l.door_at = Vector2(600, 424)
	l.props = []
	l.robot_spawn = Vector2(80, 466)
	l.machine_at = Vector2(120, 456)  # left shoulder, right of spawn + walk key
	return l


## Every area, in play order.
static func all() -> Array[AreaLayout]:
	return [meadow(), cave(), sunset()]
