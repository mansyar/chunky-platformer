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
const ROBOT_Z_INDEX := 10  # the player always paints above level geometry
const SCREEN := Vector2(1280, 720)

## Handles to the parts a caller needs to wire up (gems, transitions, hints).
var robot: Robot
var wallet_hud: WalletHud
var goal_state: GoalState
var door: Door
var key_counter: KeyCounter
var hint: HintSystem

## Session wallet fed by gem collects (null until build with one).
var wallet: Wallet

## Session wardrobe fed by the gift machine (null until build with one).
## Like the wallet it is owned by the caller and carried across area swaps.
var wardrobe: Wardrobe

## The area's gift machine (null until built).
var machine: GiftMachine

## Ambient loop owner, set by the game root after build (null in bare-builder
## tests). One-shot handlers duck the loop through it; play() alone still
## sounds when it is absent, so headless and unit tests stay safe.
var audio_manager: AudioManager

## Per-gem taken flags for this build, indexed by gem_id.
var _taken: Array[bool] = []

## The area's live keys, kept so the hint can re-resolve its target the moment
## one is taken rather than holding a stale reference.
var _keys: Array[Key] = []

var _layout: AreaLayout


## Which area this builder built - used by the game root and tests.
func area_name() -> String:
	return _layout.area_name


## Build the given layout under this node. Returns the level's bounds so a
## caller can clamp a camera or check that the level is the expected size.
## The optional wallet receives one gem per collect; the optional taken
## flags pre-collect gems (revisit path: nothing is restored). The optional
## wardrobe receives the machine's gifts (a fresh one is made when omitted).
func build(
	layout: AreaLayout,
	p_wallet: Wallet = null,
	taken: Array[bool] = [],
	p_wardrobe: Wardrobe = null
) -> Rect2:
	_layout = layout
	_keys.clear()  # a rebuild must not inherit the previous area's keys
	if p_wallet == null:
		wallet = Wallet.new()
	else:
		wallet = p_wallet
	if p_wardrobe == null:
		wardrobe = Wardrobe.new()
	else:
		wardrobe = p_wardrobe
	_taken.clear()
	for i: int in range(layout.gem_spots.size()):
		_taken.append(i < taken.size() and taken[i])
	_build_sky()
	var world := Node2D.new()
	world.name = "World"
	add_child(world)
	_build_tiles(world)
	_build_interactives(world)
	_build_props(world)
	robot = _build_robot(world)
	# Tap-Robo cycles owned looks: the wardrobe lives here (session state from
	# the game root) and Robo only borrows it for taps + wear.
	robot.wardrobe = wardrobe
	wardrobe.changed.connect(robot.refresh_look)
	robot.refresh_look()
	_build_goal(world)
	_build_camera(world)
	_build_gems(world)
	_build_machine(world)
	wallet_hud = WalletHud.new()
	wallet_hud.name = "WalletHud"
	wallet_hud.palette = layout.palette
	add_child(wallet_hud)
	wallet_hud.bind(wallet)
	add_child(TouchControls.new())
	return bounds()


## Per-gem taken flags for this area (a copy; index = gem_id).
func taken_flags() -> Array[bool]:
	return _taken.duplicate()


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
	# Personality on the wall behind the play: plain sprites, no collision,
	# no gameplay reads. The bg layer (z_index -10) keeps gems, keys, the
	# door, hint sparkles, and Robo above the decoration.
	for prop: Dictionary in _layout.props:
		var sprite := Sprite2D.new()
		sprite.texture = AssetFactory.get_texture(prop["asset"], _layout.palette)
		sprite.position = prop["at"]
		sprite.z_index = -10
		world.add_child(sprite)


## The goal loop: three keys, a door, and the badge counting them. The keys and
## the door replace the static prop sprites the Movement track used as
## placeholders, so the picture a child has already seen now means something.
func _build_goal(world: Node2D) -> void:
	goal_state = GoalState.new()
	goal_state.name = "GoalState"
	add_child(goal_state)

	door = Door.new()
	door.name = "Door"
	door.palette = _layout.palette
	door.position = _layout.door_at
	goal_state.progress.connect(door.on_progress)
	door.unlocked.connect(_on_door_unlocked)
	world.add_child(door)

	for spot: Dictionary in _layout.key_spots:
		var key := Key.new()
		key.position = spot["at"]
		key.palette = _layout.palette
		key.taken.connect(_on_key_taken)
		world.add_child(key)
		_keys.append(key)

	key_counter = KeyCounter.new()
	key_counter.name = "KeyCounter"
	key_counter.palette = _layout.palette
	add_child(key_counter)
	_build_hint()


func _on_key_taken(_key: Key) -> void:
	goal_state.take_key()
	key_counter.set_count(goal_state.keys_taken())
	# Progress buys silence: the trail is gone the instant a key is banked.
	hint.progressed()
	_play_sfx("key")


func _build_hint() -> void:
	hint = HintSystem.new()
	hint.name = "Hint"
	hint.door = door
	add_child(hint)
	hint.shown.connect(_on_hint_shown)
	hint.begin(goal_state, robot, _keys)


func _on_hint_shown(target: Node2D) -> void:
	# Robo turns toward whatever the trail points at. The trail can run off the
	# side of the screen for a far key, so pointing at the key itself (not at a
	# screen-space position) keeps him facing the right way.
	robot.point_at(target)


func _on_door_unlocked(_door: Door) -> void:
	# The door opening is the moment the child has been working toward, so it
	# gets the same celebration a gem would.
	PopEffect.spawn(_layout_world(), door.global_position, _accent())
	robot.celebrate()
	_play_sfx("door")


func _layout_world() -> Node:
	return find_child("World", true, false)


func _build_gems(world: Node2D) -> void:
	for i: int in range(_layout.gem_spots.size()):
		var gem := Gem.new()
		gem.position = _layout.gem_spots[i]
		gem.palette = _layout.palette
		gem.gem_id = i
		if i < _taken.size() and _taken[i]:
			gem.start_collected()
		gem.collected.connect(_on_gem_collected)
		world.add_child(gem)


func _on_gem_collected(gem: Gem) -> void:
	# Juice must never interrupt play: the ring pops, the wallet bumps the
	# HUD via changed, Robo squashes - and his velocity is untouched.
	if gem.gem_id >= 0 and gem.gem_id < _taken.size():
		_taken[gem.gem_id] = true
	PopEffect.spawn(gem.get_parent(), gem.global_position, _accent())
	if wallet != null:
		wallet.add(1)
	robot.celebrate()
	_play_sfx("gem")


func _accent() -> Color:
	return Palettes.AREA_PALETTES[_layout.palette]["accent"]


## One friendly gift machine per area, seated on its layout spot and fed by
## the session wallet + wardrobe. Its hint sparkle points at this area's
## live gems, and every dispense earns Robo's celebration.
func _build_machine(world: Node2D) -> void:
	machine = GiftMachine.new()
	machine.name = "GiftMachine"
	machine.position = _layout.machine_at
	machine.palette = _layout.palette
	machine.wallet = wallet
	machine.wardrobe = wardrobe
	world.add_child(machine)
	var gems: Array[Node2D] = []
	for child: Node in world.get_children():
		if child is Gem:
			gems.append(child)
	machine.hint_targets = gems
	machine.dispensed.connect(_on_machine_dispensed)
	machine.bonus.connect(_on_machine_bonus)
	machine.wiggled.connect(_on_machine_wiggled)


func _on_machine_dispensed(_cosmetic_id: String) -> void:
	PopEffect.spawn(_layout_world(), machine.global_position + Vector2(0.0, -32.0), _accent())
	robot.celebrate()
	_play_sfx("gift_pop")


func _on_machine_bonus() -> void:
	PopEffect.spawn(_layout_world(), machine.global_position + Vector2(0.0, -32.0), _accent())
	robot.celebrate()
	_play_sfx("gift_bonus")


func _on_machine_wiggled() -> void:
	# Sound-only: a kind wiggle when the wallet is empty. The hint sparkle
	# (machine.hinted) fires independently, so the trail is never blocked.
	_play_sfx("gift_wiggle")


## Sound-only: plays a one-shot and ducks the area loop while it rings.
## Never touches gameplay state, so hints, progress, and physics are
## unaffected (hint-safe by construction).
func _play_sfx(sfx_name: String) -> void:
	AudioFactory.play(sfx_name)
	if audio_manager != null:
		audio_manager.notify_sfx_played()


func _build_robot(world: Node2D) -> Robot:
	var robo := Robot.new()
	robo.name = "Robo"
	robo.position = _layout.robot_spawn
	# Siblings paint in tree order, and the door and keys are built after the
	# robot - so without an explicit z-index the door would cover Robo at the
	# exact moment a child walks into the doorway. z_index rather than
	# move_child(): the player should be on top of the level wherever it sits
	# in the tree, not only because it happens to be added last.
	robo.z_index = ROBOT_Z_INDEX
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
