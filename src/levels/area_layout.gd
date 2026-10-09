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
	l.trampolines = [Vector2(328, 512), Vector2(176, 448)]
	l.platforms = [{"width": 144.0, "at": Vector2(280, 400)}]
	l.walls = [-4.0, 644.0]
	l.gem_spots = [
		# walk tier - plain walking pickups
		Vector2(60, 436),
		Vector2(140, 436),
		Vector2(240, 500),
		Vector2(380, 500),
		Vector2(440, 500),
		Vector2(416, 436),
		Vector2(520, 372),
		Vector2(600, 372),
		# jump tier - one clean jump apex (48px) above a surface
		Vector2(270, 464),
		Vector2(560, 336),
		# bounce tier - only the trampoline arcs (~133px) reach this high
		Vector2(328, 392),
		Vector2(176, 328),
	]
	l.door_at = Vector2(520, 360)
	l.props = [
		{"asset": "key", "at": Vector2(600, 352)},
		{"asset": "door_locked", "at": Vector2(520, 360)},
	]
	l.robot_spawn = Vector2(300, 498)
	return l


## The cave: layered and tight. The tall hill's steps collapse into a sheer
## cliff whose only route is the bridge, so the bounce key is compulsory rather
## than optional and the walk key sits deep in the left alcove.
static func cave() -> AreaLayout:
	var l := AreaLayout.new()
	l.area_name = "cave"
	l.palette = "cave"
	l.cols = 40
	l.rows = 34
	l.ground_row = 32
	l.spans = [
		{"from": 0, "to": 8, "top_row": 24},  # high left ceiling
		{"from": 8, "to": 14, "top_row": 28},  # step down into the alcove
		{"from": 26, "to": 30, "top_row": 26},  # right ledge, one hop up
		{"from": 30, "to": 40, "top_row": 30},  # low right shelf by the door
	]
	l.deco = {
		"deco_rock": [Vector2i(3, 23), Vector2i(11, 27), Vector2i(28, 25), Vector2i(36, 29)],
		"deco_grass_tuft": [Vector2i(6, 23)],
	}
	l.pad_cells = [Vector2i(20, 31), Vector2i(33, 29)]
	l.trampolines = [Vector2(328, 512), Vector2(536, 496)]
	l.platforms = [
		{"width": 96.0, "at": Vector2(272, 416)},  # the cave bridge
		{"width": 64.0, "at": Vector2(112, 352)},  # alcove ledge
	]
	l.walls = [0.0, 644.0]
	l.gem_spots = [
		Vector2(120, 340),
		Vector2(288, 404),
		Vector2(360, 484),
		Vector2(496, 484),
		Vector2(560, 284),
	]
	l.key_spots = [
		{"tier": "walk", "at": Vector2(96, 268)},
		{"tier": "jump", "at": Vector2(208, 444)},
		{"tier": "bounce", "at": Vector2(328, 300)},
	]
	l.door_at = Vector2(596, 464)
	l.props = []
	l.robot_spawn = Vector2(200, 498)
	return l


## The sunset hills: tall and trampoline-driven. Three stacked plateaus mean
## two of the three keys are bounce-tier; the low ground is the fast route to
## the door, but it is long.
static func sunset() -> AreaLayout:
	var l := AreaLayout.new()
	l.area_name = "sunset"
	l.palette = "sunset"
	l.cols = 40
	l.rows = 34
	l.ground_row = 32
	l.spans = [
		{"from": 0, "to": 10, "top_row": 30},  # low left shoulder
		{"from": 10, "to": 20, "top_row": 20},  # tallest plateau
		{"from": 20, "to": 24, "top_row": 26},  # long descent to the valley
		{"from": 34, "to": 40, "top_row": 26},  # right shoulder by the door
	]
	l.deco = {
		"deco_flower": [Vector2i(4, 29), Vector2i(14, 19), Vector2i(37, 25)],
		"deco_grass_tuft": [Vector2i(8, 29), Vector2i(18, 19), Vector2i(35, 25)],
		"deco_rock": [Vector2i(22, 25)],
	}
	l.pad_cells = [Vector2i(16, 31), Vector2i(28, 31)]
	l.trampolines = [Vector2(264, 512), Vector2(456, 512)]
	l.platforms = [
		{"width": 80.0, "at": Vector2(232, 384)},  # mid-air catch above the valley
		{"width": 80.0, "at": Vector2(432, 384)},
	]
	l.walls = [0.0, 644.0]
	l.gem_spots = [
		Vector2(120, 188),
		Vector2(200, 188),
		Vector2(296, 300),
		Vector2(360, 484),
		Vector2(424, 484),
		Vector2(560, 244),
	]
	l.key_spots = [
		{"tier": "walk", "at": Vector2(56, 288)},
		{"tier": "jump", "at": Vector2(296, 188)},
		{"tier": "bounce", "at": Vector2(160, 76)},
	]
	l.door_at = Vector2(600, 408)
	l.props = []
	l.robot_spawn = Vector2(300, 498)
	return l


## Every area, in play order.
static func all() -> Array[AreaLayout]:
	return [meadow(), cave(), sunset()]
