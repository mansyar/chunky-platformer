class_name AreaBuilder
extends Node2D
## Builds a complete playable area from an AreaLayout.
##
## One builder, three areas. Everything that used to be hardcoded per level -
## sky, terrain, stairs, trampolines, gems, props, Robo, camera, HUD - is read
## off the layout here, so a new area is a data file rather than a new script.
##
## The world is built 1:1 (16px tiles) and the CAMERA zooms 4x for the chunky
## look. Never scale a parent of physics bodies: move_and_slide motion would be
## divided by the parent scale, silently quartering every speed and jump.

const CAMERA_ZOOM := 4.0
const TILE := 16
const ROBOT_HALF_HEIGHT := 14.0  # collider half-height (slim 28px box)
const SCREEN := Vector2(1280, 720)

## Handles to the parts a caller needs to wire up (gems, transitions, hints).
var robot: Robot
var counter: GemCounter

var _layout: AreaLayout


## Build the given layout under this node. Returns the level's bounds so a
## caller can clamp a camera or check that the level is the expected size.
func build(layout: AreaLayout) -> Rect2:
	_layout = layout
	_build_sky()
	var world := Node2D.new()
	world.name = "World"
	add_child(world)
	_build_tiles(world)
	_build_interactives(world)
	_build_props(world)
	robot = _build_robot(world)
	_build_camera(world)
	_build_gems(world)
	counter = GemCounter.new()
	counter.name = "GemCounter"
	counter.palette = layout.palette
	add_child(counter)
	add_child(TouchControls.new())
	return bounds()


## The world's walkable extent in pixels, derived from the layout rather than
## guessed. Every height change the layout describes is 2 tiles (32px), so a
## child can always hop it.
func bounds() -> Rect2:
	return Rect2(0, 0, _layout.cols * TILE, (_layout.rows - 1) * TILE)


func _build_sky() -> void:
	# Screen-space sky: a CanvasLayer ignores the camera zoom, so the gradient
	# keeps one texel per screen row (no banding) at any zoom.
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var sky := Sprite2D.new()
	sky.texture = AssetFactory.get_texture("sky_strip", _layout.palette)
	sky.centered = false
	sky.region_enabled = true
	sky.region_rect = Rect2(0, 0, SCREEN.x, SCREEN.y)
	sky.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	layer.add_child(sky)


func _build_tiles(world: Node2D) -> void:
	var tile_map := TileMapLayer.new()
	tile_map.tile_set = _build_tile_set()
	world.add_child(tile_map)
	_fill_ground(tile_map)
	# Spans run left to right and fill down to the ground, so a staircase is
	# just a run of spans with descending top rows. No sheer walls anywhere: a
	# toddler walking along the ground can always hop up.
	for span: Dictionary in _layout.spans:
		for x: int in range(span["from"], span["to"]):
			tile_map.set_cell(Vector2i(x, span["top_row"]), 0, _coords("tile_grass_top"))
			for y: int in range(span["top_row"] + 1, _layout.ground_row):
				tile_map.set_cell(Vector2i(x, y), 0, _coords("tile_solid"))
	for asset_name: String in _layout.deco:
		for cell: Vector2i in _layout.deco[asset_name]:
			tile_map.set_cell(cell, 0, _coords(asset_name))
	# Visible pads under each trampoline area (the Area2D itself is invisible).
	for cell: Vector2i in _layout.pad_cells:
		tile_map.set_cell(cell, 0, _coords("tile_trampoline"))


func _fill_ground(tile_map: TileMapLayer) -> void:
	for x: int in _layout.cols:
		tile_map.set_cell(Vector2i(x, _layout.ground_row), 0, _coords("tile_grass_top"))
		tile_map.set_cell(Vector2i(x, _layout.ground_row + 1), 0, _coords("tile_solid"))


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()  # terrain tiles collide on the default layer
	var source := TileSetAtlasSource.new()
	source.texture = AssetFactory.get_tile_atlas(_layout.palette)
	source.texture_region_size = Vector2i(TILE, TILE)
	for entry: Dictionary in AssetSpec.SPEC:
		var kind: String = entry.get("kind", "")
		if kind == "tile" or kind == "deco":
			source.create_tile(_coords(entry["name"]))
	# Attach before touching TileData: collision layers only sync once the
	# source belongs to the TileSet.
	tile_set.add_source(source, 0)
	# Terrain tiles get a full-square collision polygon; deco stays walk-through.
	for terrain: String in ["tile_solid", "tile_grass_top"]:
		var data: TileData = source.get_tile_data(_coords(terrain), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(
			0,
			0,
			PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
		)
	return tile_set


func _coords(asset_name: String) -> Vector2i:
	return AssetFactory.get_tile_atlas_coords(asset_name, _layout.palette)


func _build_interactives(world: Node2D) -> void:
	for at: Vector2 in _layout.trampolines:
		var trampoline := Trampoline.new()
		trampoline.position = at
		world.add_child(trampoline)
	for platform: Dictionary in _layout.platforms:
		var bridge: StaticBody2D = LevelParts.one_way_platform(platform["width"])
		bridge.position = platform["at"]
		world.add_child(bridge)
	# Invisible walls close the level ends; the camera clamps to the same
	# bounds, so the viewport edge never leaves the world.
	var half_height := bounds().size.y
	for x: float in _layout.walls:
		var wall: StaticBody2D = LevelParts.edge_wall(half_height)
		wall.position = Vector2(x, half_height / 2.0)
		world.add_child(wall)


func _build_props(world: Node2D) -> void:
	for prop: Dictionary in _layout.props:
		var sprite := Sprite2D.new()
		sprite.texture = AssetFactory.get_texture(prop["asset"], _layout.palette)
		sprite.position = prop["at"]
		world.add_child(sprite)


func _build_gems(world: Node2D) -> void:
	for spot: Vector2 in _layout.gem_spots:
		var gem := Gem.new()
		gem.position = spot
		gem.palette = _layout.palette
		gem.collected.connect(_on_gem_collected)
		gem.respawned.connect(_on_gem_respawned)
		world.add_child(gem)


func _on_gem_collected(gem: Gem) -> void:
	# Juice must never interrupt play: the ring pops, the counter bumps, Robo
	# squashes - and his velocity is untouched.
	PopEffect.spawn(gem.get_parent(), gem.global_position, _accent())
	counter.increment()
	robot.celebrate()


func _on_gem_respawned(gem: Gem) -> void:
	# The returning gem announces itself with the same sparkle burst.
	PopEffect.spawn(gem.get_parent(), gem.global_position, _accent())


func _accent() -> Color:
	return Palettes.AREA_PALETTES[_layout.palette]["accent"]


func _build_robot(world: Node2D) -> Robot:
	var robo := Robot.new()
	robo.name = "Robo"
	robo.position = _layout.robot_spawn
	world.add_child(robo)
	return robo


func _build_camera(world: Node2D) -> void:
	var half := SCREEN / (2.0 * CAMERA_ZOOM)
	var camera := FollowCamera.new()
	camera.name = "FollowCamera"
	camera.view_half = half
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	camera.set_bounds(bounds())
	camera.target = robot
	world.add_child(camera)
	camera.make_current()
