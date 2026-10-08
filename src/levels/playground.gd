extends Node2D
## The playground level (Movement track): a safe three-layer meadow.
##
## Topology (world pixels, tiles are 16px):
##   - Ground floor spans the full width (top at y=512).
##   - A low hill on the left (top at y=448, cols 0-15).
##   - A tall hill on the right (top at y=384, cols 24-39).
##   - A valley shaft between them (cols 16-23): falling off either hill
##     lands safely on the ground floor.
##   - A one-way bridge (y=400) floats over the valley. A trampoline under
##     the bridge is an elevator: bouncing passes up through the one-way
##     platform and Robo lands on top of it. From the bridge a single jump
##     reaches the tall hill. A second trampoline on the low hill bounces
##     Robo up to the bridge the same way.
##
## Layer steps are 64px and the bounce arc is ~85px, so every hop has a
## comfortable margin. No hazards anywhere; walls close both ends and the
## camera clamps to the same bounds.

const LEVEL_COLS := 40
const LEVEL_ROWS := 34
const LEVEL_SIZE := Rect2(0, 0, 640, 544)
const WORLD_SCALE := 4.0
const TILE := 16
const ROBOT_HALF_HEIGHT := 14.0  # collider half-height (slim 28px box)

# Key surfaces (world y of the walkable tops).
const GROUND_TOP := 512.0
const LOW_HILL_TOP := 448.0
const TALL_HILL_TOP := 384.0
const BRIDGE_Y := 400.0


func _ready() -> void:
	_build_sky()
	var world := Node2D.new()
	world.name = "World"
	world.scale = Vector2.ONE * WORLD_SCALE
	add_child(world)
	_build_tiles(world)
	_build_interactives(world)
	_build_props(world)
	var robot: Robot = _build_robot(world)
	_build_camera(world, robot)
	add_child(TouchControls.new())


func _build_sky() -> void:
	var sky := Sprite2D.new()
	sky.texture = AssetFactory.get_texture("sky_strip", "meadow")
	sky.centered = false
	sky.region_enabled = true
	sky.region_rect = Rect2(0, 0, 1280, 720)
	sky.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(sky)  # added before the world, so it renders behind it


func _build_tiles(world: Node2D) -> void:
	var tile_map := TileMapLayer.new()
	tile_map.tile_set = _build_tile_set()
	world.add_child(tile_map)
	_fill_ground(tile_map)
	# Low hill with a jumpable staircase face: plateau cols 0-11 (top row 28),
	# step cols 12-13 (top row 30). No sheer walls anywhere: a toddler walking
	# along the ground can always hop up.
	for x: int in range(0, 12):
		tile_map.set_cell(Vector2i(x, 28), 0, _coords("tile_grass_top"))
		for y: int in range(29, 32):
			tile_map.set_cell(Vector2i(x, y), 0, _coords("tile_solid"))
	for x: int in range(12, 14):
		tile_map.set_cell(Vector2i(x, 30), 0, _coords("tile_grass_top"))
		tile_map.set_cell(Vector2i(x, 31), 0, _coords("tile_solid"))
	# Tall hill with a 2-tile staircase: plateau cols 30-39 (top row 24),
	# steps at cols 28-29 (row 26), 26-27 (row 28), 24-25 (row 30).
	for x: int in range(30, LEVEL_COLS):
		tile_map.set_cell(Vector2i(x, 24), 0, _coords("tile_grass_top"))
		for y: int in range(25, 32):
			tile_map.set_cell(Vector2i(x, y), 0, _coords("tile_solid"))
	for x: int in range(28, 30):
		tile_map.set_cell(Vector2i(x, 26), 0, _coords("tile_grass_top"))
		for y: int in range(27, 32):
			tile_map.set_cell(Vector2i(x, y), 0, _coords("tile_solid"))
	for x: int in range(26, 28):
		tile_map.set_cell(Vector2i(x, 28), 0, _coords("tile_grass_top"))
		for y: int in range(29, 32):
			tile_map.set_cell(Vector2i(x, y), 0, _coords("tile_solid"))
	for x: int in range(24, 26):
		tile_map.set_cell(Vector2i(x, 30), 0, _coords("tile_grass_top"))
		tile_map.set_cell(Vector2i(x, 31), 0, _coords("tile_solid"))
	_place_deco(tile_map)
	# Visible pads under each trampoline area (the Area2D itself is invisible).
	tile_map.set_cell(Vector2i(20, 31), 0, _coords("tile_trampoline"))
	tile_map.set_cell(Vector2i(11, 27), 0, _coords("tile_trampoline"))


func _fill_ground(tile_map: TileMapLayer) -> void:
	for x: int in LEVEL_COLS:
		tile_map.set_cell(Vector2i(x, 32), 0, _coords("tile_grass_top"))
		tile_map.set_cell(Vector2i(x, 33), 0, _coords("tile_solid"))


func _place_deco(tile_map: TileMapLayer) -> void:
	var deco := {
		"deco_grass_tuft": [Vector2i(3, 27), Vector2i(32, 23), Vector2i(17, 31)],
		"deco_flower": [Vector2i(8, 27), Vector2i(35, 23), Vector2i(20, 31)],
		"deco_rock": [Vector2i(10, 27), Vector2i(37, 23), Vector2i(22, 31)],
	}
	for asset_name: String in deco:
		for cell: Vector2i in deco[asset_name]:
			tile_map.set_cell(cell, 0, _coords(asset_name))


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()  # terrain tiles collide on the default layer
	var source := TileSetAtlasSource.new()
	source.texture = AssetFactory.get_tile_atlas("meadow")
	source.texture_region_size = Vector2i(TILE, TILE)
	for entry: Dictionary in AssetSpec.SPEC:
		var kind: String = entry.get("kind", "")
		if kind == "tile" or kind == "deco":
			source.create_tile(AssetFactory.get_tile_atlas_coords(entry["name"], "meadow"))
	# Attach before touching TileData: collision layers only sync once
	# the source belongs to the TileSet.
	tile_set.add_source(source, 0)
	# Terrain tiles get a full-square collision polygon; deco stays walk-through.
	for terrain: String in ["tile_solid", "tile_grass_top"]:
		var data: TileData = source.get_tile_data(_coords(terrain), 0)
		data.add_collision_polygon(0)
		(
			data
			. set_collision_polygon_points(
				0,
				0,
				PackedVector2Array(
					[
						Vector2(-8, -8),
						Vector2(8, -8),
						Vector2(8, 8),
						Vector2(-8, 8),
					]
				)
			)
		)
	return tile_set


func _coords(asset_name: String) -> Vector2i:
	return AssetFactory.get_tile_atlas_coords(asset_name, "meadow")


func _build_interactives(world: Node2D) -> void:
	# Elevator trampoline under the bridge + a bouncy pad on the low hill.
	_spawn_trampoline(Vector2(328, GROUND_TOP), world)
	_spawn_trampoline(Vector2(176, LOW_HILL_TOP), world)
	# One-way bridge over the valley (the elevator pops Robo through it).
	var bridge: StaticBody2D = LevelParts.one_way_platform(144.0)
	bridge.position = Vector2(280, BRIDGE_Y)
	world.add_child(bridge)
	# Invisible walls close the level ends; the camera clamps to the same
	# bounds, so the viewport edge never leaves the world.
	var left_wall: StaticBody2D = LevelParts.edge_wall(560.0)
	left_wall.position = Vector2(-4, 272)
	world.add_child(left_wall)
	var right_wall: StaticBody2D = LevelParts.edge_wall(560.0)
	right_wall.position = Vector2(644, 272)
	world.add_child(right_wall)


func _spawn_trampoline(at: Vector2, world: Node2D) -> void:
	var trampoline := Trampoline.new()
	trampoline.position = at
	world.add_child(trampoline)


func _build_props(world: Node2D) -> void:
	_spawn_prop("gem", Vector2(88, 424), world)
	_spawn_prop("key", Vector2(600, 352), world)
	_spawn_prop("door_locked", Vector2(520, 360), world)


func _spawn_prop(asset_name: String, at: Vector2, world: Node2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = AssetFactory.get_texture(asset_name, "meadow")
	sprite.position = at
	world.add_child(sprite)


func _build_robot(world: Node2D) -> Robot:
	var robot := Robot.new()
	robot.name = "Robo"
	robot.position = Vector2(300, GROUND_TOP - ROBOT_HALF_HEIGHT)
	world.add_child(robot)
	return robot


func _build_camera(world: Node2D, robot: Robot) -> void:
	var camera := FollowCamera.new()
	camera.view_half = Vector2(160, 90)
	camera.set_bounds(LEVEL_SIZE)
	camera.target = robot
	world.add_child(camera)
	camera.make_current()
