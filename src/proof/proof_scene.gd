extends Node2D
## Proof scene (Foundation Phase 5) — the entire world is assembled in code
## from AssetFactory output: tiled sky strip, a TileMapLayer built from the
## generated tile atlas, sprite props, and Robo standing on the ground.
##
## The world is authored in 16 px tile units and scaled 4x so the 1280x720
## viewport shows a 320x180 chunk of world with chunky, toddler-sized art.

const TILE: Vector2i = Vector2i(16, 16)
const VIEW: Vector2i = Vector2i(320, 192)
const WORLD_SCALE := 4.0
const GROUND_ROW := 10
const ROBOT_GROUND_Y := 160.0


func _ready() -> void:
	# Sky renders at screen resolution (scale 1) for a smooth gradient;
	# the scaled world draws on top of it.
	_build_sky()
	var world := Node2D.new()
	world.name = "World"
	world.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	add_child(world)
	_build_tiles(world)
	_build_props(world)
	_build_robot(world)


func _build_sky() -> void:
	var sky := Sprite2D.new()
	sky.name = "Sky"
	sky.texture = AssetFactory.get_texture("sky_strip", "meadow")
	sky.centered = false
	sky.region_enabled = true
	sky.region_rect = Rect2(Vector2.ZERO, Vector2(1280, 720))
	sky.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(sky)


func _build_tiles(world: Node2D) -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE
	var source := TileSetAtlasSource.new()
	source.texture = AssetFactory.get_tile_atlas("meadow")
	source.texture_region_size = TILE
	for entry: Dictionary in AssetSpec.SPEC:
		if entry["kind"] in ["tile", "deco", "background"]:
			source.create_tile(AssetFactory.get_tile_atlas_coords(entry["name"], "meadow"))
	tile_set.add_source(source, 0)
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = tile_set
	world.add_child(layer)
	# Ground: grass-top row with solid soil beneath, spanning the view.
	for x in VIEW.x / TILE.x:
		layer.set_cell(
			Vector2i(x, GROUND_ROW),
			0,
			AssetFactory.get_tile_atlas_coords("tile_grass_top", "meadow")
		)
		layer.set_cell(
			Vector2i(x, GROUND_ROW + 1),
			0,
			AssetFactory.get_tile_atlas_coords("tile_solid", "meadow")
		)
	# Floating platform.
	for x in range(10, 14):
		layer.set_cell(
			Vector2i(x, 6), 0, AssetFactory.get_tile_atlas_coords("tile_platform", "meadow")
		)
	# Trampoline resting on the ground.
	layer.set_cell(
		Vector2i(5, GROUND_ROW - 1),
		0,
		AssetFactory.get_tile_atlas_coords("tile_trampoline", "meadow")
	)
	# Decorations on the ground line.
	layer.set_cell(
		Vector2i(2, GROUND_ROW - 1),
		0,
		AssetFactory.get_tile_atlas_coords("deco_grass_tuft", "meadow")
	)
	layer.set_cell(
		Vector2i(8, GROUND_ROW - 1), 0, AssetFactory.get_tile_atlas_coords("deco_rock", "meadow")
	)
	layer.set_cell(
		Vector2i(15, GROUND_ROW - 1), 0, AssetFactory.get_tile_atlas_coords("deco_flower", "meadow")
	)


func _build_props(world: Node2D) -> void:
	_add_prop(world, "gem", Vector2(16 * 16 + 8, 7 * 16 + 8))
	_add_prop(world, "key", Vector2(11 * 16 + 8, 6 * 16 - 8))
	_add_prop(world, "door_locked", Vector2(280.0, ROBOT_GROUND_Y - 24.0))


func _add_prop(world: Node2D, asset_name: String, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = asset_name.to_pascal_case()
	sprite.texture = AssetFactory.get_texture(asset_name, "meadow")
	sprite.position = pos
	world.add_child(sprite)


func _build_robot(world: Node2D) -> void:
	var robot := Sprite2D.new()
	robot.name = "Robo"
	robot.texture = AssetFactory.get_texture("robot_idle_0")
	# Sprite is 32x32 with feet at the bottom edge; center it so the feet
	# rest exactly on the ground surface.
	robot.position = Vector2(72.0, ROBOT_GROUND_Y - 16.0)
	world.add_child(robot)
