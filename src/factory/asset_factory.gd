extends Node
## AssetFactory — generates every visual asset defined in AssetSpec.
##
## Registered as the `AssetFactory` autoload. Generation happens eagerly at
## startup (warm_all in _ready) per the tech stack: all visuals are pure
## code (PixelDsl op lists plus a few procedural draws), deterministic, and
## cached per (asset, palette). Area assets are generated once per area
## palette; robot frames use the fixed robot palette regardless of area.
##
## The tile atlas packs all tile/deco/background entries into a 4-column
## grid image so a TileSet can consume a single texture.

const ATLAS_COLUMNS := 4

## Robot frame geometry: "frames as data". Each entry positions the shared
## body parts for one animation frame; _draw_robot_frame renders them.
const ROBOT_FRAMES := {
	"robot_idle_0":
	{
		"body": Rect2i(8, 8, 16, 14),
		"face": Rect2i(10, 10, 12, 8),
		"arm_l": Rect2i(5, 14, 3, 6),
		"arm_r": Rect2i(24, 14, 3, 6),
		"leg_l": Rect2i(11, 22, 3, 7),
		"leg_r": Rect2i(18, 22, 3, 7),
		"foot_l": Rect2i(10, 28, 5, 3),
		"foot_r": Rect2i(17, 28, 5, 3),
		"antenna": Rect2i(15, 4, 2, 4),
	},
	"robot_idle_1":
	{
		"body": Rect2i(8, 9, 16, 14),
		"face": Rect2i(10, 11, 12, 8),
		"arm_l": Rect2i(5, 15, 3, 6),
		"arm_r": Rect2i(24, 15, 3, 6),
		"leg_l": Rect2i(11, 23, 3, 6),
		"leg_r": Rect2i(18, 23, 3, 6),
		"foot_l": Rect2i(10, 28, 5, 3),
		"foot_r": Rect2i(17, 28, 5, 3),
		"antenna": Rect2i(15, 5, 2, 4),
	},
	"robot_walk_0":
	{
		"body": Rect2i(8, 8, 16, 14),
		"face": Rect2i(10, 10, 12, 8),
		"arm_l": Rect2i(4, 13, 3, 6),
		"arm_r": Rect2i(25, 15, 3, 6),
		"leg_l": Rect2i(9, 23, 3, 6),
		"leg_r": Rect2i(21, 22, 3, 7),
		"foot_l": Rect2i(8, 29, 5, 3),
		"foot_r": Rect2i(21, 28, 5, 3),
		"antenna": Rect2i(15, 4, 2, 4),
	},
	"robot_walk_1":
	{
		"body": Rect2i(8, 9, 16, 14),
		"face": Rect2i(10, 11, 12, 8),
		"arm_l": Rect2i(5, 15, 3, 6),
		"arm_r": Rect2i(24, 15, 3, 6),
		"leg_l": Rect2i(12, 22, 3, 7),
		"leg_r": Rect2i(17, 22, 3, 7),
		"foot_l": Rect2i(11, 28, 5, 3),
		"foot_r": Rect2i(16, 28, 5, 3),
		"antenna": Rect2i(15, 5, 2, 4),
	},
	"robot_walk_2":
	{
		"body": Rect2i(8, 8, 16, 14),
		"face": Rect2i(10, 10, 12, 8),
		"arm_l": Rect2i(25, 15, 3, 6),
		"arm_r": Rect2i(4, 13, 3, 6),
		"leg_l": Rect2i(21, 22, 3, 7),
		"leg_r": Rect2i(9, 23, 3, 6),
		"foot_l": Rect2i(21, 28, 5, 3),
		"foot_r": Rect2i(8, 29, 5, 3),
		"antenna": Rect2i(15, 4, 2, 4),
	},
	"robot_walk_3":
	{
		"body": Rect2i(8, 8, 16, 14),
		"face": Rect2i(10, 10, 12, 8),
		"arm_l": Rect2i(5, 14, 3, 6),
		"arm_r": Rect2i(24, 14, 3, 6),
		"leg_l": Rect2i(12, 22, 3, 7),
		"leg_r": Rect2i(17, 22, 3, 7),
		"foot_l": Rect2i(11, 28, 5, 3),
		"foot_r": Rect2i(16, 28, 5, 3),
		"antenna": Rect2i(15, 4, 2, 4),
	},
	"robot_jump":
	{
		"body": Rect2i(8, 6, 16, 14),
		"face": Rect2i(10, 8, 12, 8),
		"arm_l": Rect2i(5, 8, 3, 6),
		"arm_r": Rect2i(24, 8, 3, 6),
		"leg_l": Rect2i(11, 22, 3, 5),
		"leg_r": Rect2i(18, 22, 3, 5),
		"foot_l": Rect2i(10, 26, 5, 3),
		"foot_r": Rect2i(17, 26, 5, 3),
		"antenna": Rect2i(15, 2, 2, 4),
	},
	"robot_land":
	{
		"body": Rect2i(6, 14, 20, 10),
		"face": Rect2i(8, 16, 16, 7),
		"arm_l": Rect2i(3, 16, 3, 6),
		"arm_r": Rect2i(26, 16, 3, 6),
		"leg_l": Rect2i(11, 24, 3, 5),
		"leg_r": Rect2i(18, 24, 3, 5),
		"foot_l": Rect2i(9, 29, 6, 3),
		"foot_r": Rect2i(17, 29, 6, 3),
		"antenna": Rect2i(14, 10, 2, 4),
	},
}

var _spec_by_name := {}
var _images := {}
var _textures := {}
var _atlas_coords := {}


func _init() -> void:
	for entry: Dictionary in AssetSpec.SPEC:
		_spec_by_name[entry["name"]] = entry


func _ready() -> void:
	warm_all()


## Generates every spec'd asset up front (called at startup).
func warm_all() -> void:
	for entry: Dictionary in AssetSpec.SPEC:
		if entry["palette"] == "robot":
			get_texture(entry["name"])
	for palette_name: String in Palettes.AREA_PALETTES:
		for entry: Dictionary in AssetSpec.SPEC:
			if entry["palette"] == "area":
				get_texture(entry["name"], palette_name)
		get_tile_atlas(palette_name)


func get_image(asset_name: String, palette_name: String = "meadow") -> Image:
	var resolved := _resolve_palette(asset_name, palette_name)
	if resolved.is_empty():
		return null
	var key := "%s|%s" % [asset_name, resolved]
	if not _images.has(key):
		var palette: Dictionary = (
			Palettes.PALETTE_ROBOT if resolved == "robot" else Palettes.AREA_PALETTES[resolved]
		)
		_images[key] = _generate_image(_spec_by_name[asset_name], palette)
	return _images[key]


func get_texture(asset_name: String, palette_name: String = "meadow") -> Texture2D:
	var resolved := _resolve_palette(asset_name, palette_name)
	if resolved.is_empty():
		return null
	var key := "%s|%s" % [asset_name, resolved]
	if not _textures.has(key):
		_textures[key] = ImageTexture.create_from_image(get_image(asset_name, palette_name))
	return _textures[key]


## Resolves the palette actually used for an asset: robot frames always use
## the fixed robot palette regardless of the area palette argument. Returns
## an empty string for unknown assets (after warning), which callers treat
## as a null result.
func _resolve_palette(asset_name: String, palette_name: String) -> String:
	var entry: Dictionary = _spec_by_name.get(asset_name, {})
	if entry.is_empty():
		push_warning("AssetFactory: unknown asset '%s'." % asset_name)
		return ""
	return "robot" if entry["palette"] == "robot" else palette_name


## Returns the packed atlas texture for all world tiles in one palette.
func get_tile_atlas(palette_name: String = "meadow") -> Texture2D:
	var key := "atlas|%s" % palette_name
	if not _textures.has(key):
		var entries := _atlas_entries()
		var rows := ceili(entries.size() / float(ATLAS_COLUMNS))
		var tile: Vector2i = AssetSpec.TILE_SIZE
		var img := Image.create(ATLAS_COLUMNS * tile.x, rows * tile.y, false, Image.FORMAT_RGBA8)
		for i in entries.size():
			var src: Image = get_image(entries[i]["name"], palette_name)
			@warning_ignore("integer_division")
			var coords := Vector2i(i % ATLAS_COLUMNS, i / ATLAS_COLUMNS)
			img.blit_rect(src, Rect2i(Vector2i.ZERO, tile), coords * tile)
			_atlas_coords["%s|%s" % [entries[i]["name"], palette_name]] = coords
		_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]


## Returns the atlas grid cell (in tile units) for one world tile.
func get_tile_atlas_coords(asset_name: String, palette_name: String = "meadow") -> Vector2i:
	get_tile_atlas(palette_name)
	return _atlas_coords.get("%s|%s" % [asset_name, palette_name], Vector2i(-1, -1))


func _atlas_entries() -> Array:
	# Only tileable world art is packed into the atlas; background assets
	# (the full-height sky strip) are consumed as standalone textures.
	var out := []
	for entry: Dictionary in AssetSpec.SPEC:
		if entry["kind"] in ["tile", "deco"]:
			out.append(entry)
	return out


func _generate_image(entry: Dictionary, palette: Dictionary) -> Image:
	var size: Vector2i = entry["size"]
	var asset_name: String = entry["name"]
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	if asset_name == "sky_strip":
		_draw_sky_strip(img, palette)
	elif ROBOT_FRAMES.has(asset_name):
		_draw_robot_frame(img, asset_name, palette)
	else:
		PixelDsl.apply(img, _ops_for(asset_name, palette))
	return img


# --- op-list builders --------------------------------------------------------


static func _rect(r: Rect2i, c: Color) -> Dictionary:
	return {"op": "rect", "region": r, "color": c}


static func _disc(center: Vector2i, radius: int, c: Color) -> Dictionary:
	return {"op": "disc", "center": center, "radius": radius, "color": c}


static func _outline(r: Rect2i, c: Color) -> Dictionary:
	return {"op": "outline", "region": r, "color": c}


static func _shade(r: Rect2i, c: Color) -> Dictionary:
	return {"op": "shade", "region": r, "color": c}


static func _clear(r: Rect2i) -> Dictionary:
	return {"op": "clear", "region": r}


func _ops_for(asset_name: String, p: Dictionary) -> Array:
	# Aliases are optional: robot-palette assets (ui buttons) only carry
	# body/eye/accent keys, so world-color lookups fall back gracefully.
	var g: Color = p.get("ground", p.get("body", Color.BLACK))
	var gd: Color = p.get("ground_dark", p.get("body_dark", Color.BLACK))
	var gr: Color = p.get("grass", p.get("accent", Color.BLACK))
	var ac: Color = p.get("accent", Color.BLACK)
	var ink: Color = p.get("body_dark", Color.BLACK)
	var ops: Array = []
	match asset_name:
		"tile_solid":
			ops = [
				_rect(Rect2i(0, 0, 16, 16), g),
				_rect(Rect2i(0, 13, 16, 3), gd),
				_outline(Rect2i(0, 0, 16, 16), gd),
			]
		"tile_grass_top":
			ops = [
				_rect(Rect2i(0, 0, 16, 16), g),
				_rect(Rect2i(0, 13, 16, 3), gd),
				_rect(Rect2i(0, 0, 16, 4), gr),
				_rect(Rect2i(3, 0, 2, 2), g),
				_rect(Rect2i(9, 0, 2, 2), g),
			]
		"tile_platform":
			ops = [
				_rect(Rect2i(0, 4, 16, 8), g),
				_rect(Rect2i(0, 4, 16, 3), gr),
				_outline(Rect2i(0, 4, 16, 8), gd),
			]
		"tile_trampoline":
			ops = [
				_rect(Rect2i(3, 8, 2, 6), gd),
				_rect(Rect2i(11, 8, 2, 6), gd),
				_rect(Rect2i(1, 12, 14, 4), gd),
				_rect(Rect2i(0, 3, 16, 5), ac),
				_shade(Rect2i(0, 6, 16, 2), Color(gd, 0.5)),
			]
		"deco_grass_tuft":
			ops = [
				_rect(Rect2i(7, 7, 2, 9), gr),
				_rect(Rect2i(4, 10, 2, 6), gr),
				_rect(Rect2i(10, 10, 2, 6), gr),
			]
		"deco_rock":
			ops = [
				_rect(Rect2i(5, 5, 6, 4), g),
				_rect(Rect2i(3, 7, 10, 9), g),
				_shade(Rect2i(3, 12, 10, 4), Color(gd, 0.5)),
			]
		"deco_flower":
			ops = [
				_rect(Rect2i(7, 9, 2, 7), gr),
				_disc(Vector2i(8, 6), 3, ac),
				_disc(Vector2i(8, 6), 1, gd),
			]
		"gem":
			ops = [
				_rect(Rect2i(6, 3, 4, 2), ac),
				_rect(Rect2i(4, 5, 8, 4), ac),
				_rect(Rect2i(2, 7, 12, 4), ac),
				_rect(Rect2i(4, 11, 8, 2), ac),
				_rect(Rect2i(6, 13, 4, 2), ac),
				_shade(Rect2i(5, 5, 3, 3), Color(1.0, 1.0, 1.0, 0.5)),
			]
		"key":
			ops = [
				_disc(Vector2i(5, 5), 4, ac),
				_clear(Rect2i(3, 3, 5, 5)),
				_rect(Rect2i(9, 6, 6, 2), ac),
				_rect(Rect2i(12, 8, 2, 3), ac),
			]
		"door_locked":
			ops = [
				_rect(Rect2i(3, 3, 26, 44), g),
				_shade(Rect2i(8, 3, 2, 44), Color(gd, 0.4)),
				_shade(Rect2i(16, 3, 2, 44), Color(gd, 0.4)),
				_shade(Rect2i(24, 3, 2, 44), Color(gd, 0.4)),
				_outline(Rect2i(1, 1, 30, 46), gd),
				_disc(Vector2i(16, 24), 4, ac),
				_disc(Vector2i(16, 24), 2, gd),
			]
		"door_open":
			ops = [
				_rect(Rect2i(3, 3, 26, 44), p["sky_bottom"]),
				_shade(Rect2i(3, 3, 26, 44), Color(ac, 0.25)),
				_outline(Rect2i(1, 1, 30, 46), gd),
			]
		"touch_left":
			ops = [_disc(Vector2i(12, 12), 11, ac)]
			for i: int in range(4):
				ops.append(
					_rect(Rect2i(6 + i * 2, 11 - i, 2, 3 + i * 2), p.get("eye", Color.WHITE))
				)
		"touch_right":
			ops = [_disc(Vector2i(12, 12), 11, ac)]
			for i: int in range(4):
				ops.append(
					_rect(Rect2i(15 - i * 2, 11 - i, 2, 3 + i * 2), p.get("eye", Color.WHITE))
				)
		"touch_jump":
			ops = [_disc(Vector2i(12, 12), 11, ac)]
			for i: int in range(4):
				ops.append(
					_rect(Rect2i(11 - i, 8 + i * 2, 2 + i * 2, 2), p.get("eye", Color.WHITE))
				)
		"digit_0":
			ops = [
				_outline(Rect2i(0, 0, 8, 12), ink),
				_outline(Rect2i(1, 1, 6, 10), ink),
			]
		"digit_1":
			ops = [_rect(Rect2i(5, 0, 3, 12), ink)]
		"digit_2":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(6, 2, 2, 4), ink),
				_rect(Rect2i(0, 6, 8, 2), ink),
				_rect(Rect2i(0, 8, 2, 2), ink),
				_rect(Rect2i(0, 10, 8, 2), ink),
			]
		"digit_3":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(6, 2, 2, 8), ink),
				_rect(Rect2i(0, 6, 6, 2), ink),
				_rect(Rect2i(0, 10, 8, 2), ink),
			]
		"digit_4":
			ops = [
				_rect(Rect2i(0, 0, 2, 6), ink),
				_rect(Rect2i(0, 4, 8, 2), ink),
				_rect(Rect2i(6, 0, 2, 12), ink),
			]
		"digit_5":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(0, 2, 2, 4), ink),
				_rect(Rect2i(0, 6, 8, 2), ink),
				_rect(Rect2i(6, 8, 2, 2), ink),
				_rect(Rect2i(0, 10, 8, 2), ink),
			]
		"digit_6":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(0, 2, 2, 8), ink),
				_rect(Rect2i(0, 6, 8, 2), ink),
				_rect(Rect2i(6, 8, 2, 2), ink),
				_rect(Rect2i(0, 10, 8, 2), ink),
			]
		"digit_7":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(6, 2, 2, 10), ink),
			]
		"digit_8":
			ops = [
				_outline(Rect2i(0, 0, 8, 12), ink),
				_outline(Rect2i(1, 1, 6, 10), ink),
				_rect(Rect2i(0, 5, 8, 2), ink),
			]
		"digit_9":
			ops = [
				_rect(Rect2i(0, 0, 8, 2), ink),
				_rect(Rect2i(0, 2, 2, 4), ink),
				_rect(Rect2i(0, 6, 8, 2), ink),
				_rect(Rect2i(6, 2, 2, 10), ink),
				_rect(Rect2i(0, 10, 8, 2), ink),
			]
		_:
			push_warning("AssetFactory: no generator for asset '%s'." % asset_name)
	return ops


# --- procedural draws (beyond rect/disc ops) ---------------------------------


func _draw_sky_strip(img: Image, p: Dictionary) -> void:
	var top: Color = p["sky_top"]
	var bottom: Color = p["sky_bottom"]
	var height := img.get_height()
	for y in height:
		var t := float(y) / float(maxi(height - 1, 1))
		var row_color := top.lerp(bottom, t)
		for x in img.get_width():
			img.set_pixel(x, y, row_color)


func _draw_robot_frame(img: Image, frame_name: String, p: Dictionary) -> void:
	var parts: Dictionary = ROBOT_FRAMES[frame_name]
	var body: Color = p["body"]
	var body_dark: Color = p["body_dark"]
	var eye: Color = p["eye"]
	var eye_glow: Color = p["eye_glow"]
	var accent: Color = p["accent"]
	var face: Rect2i = parts["face"]
	var eye_y := face.position.y + 3
	var eye_l := Vector2i(face.position.x + 3, eye_y)
	var eye_r := Vector2i(face.end.x - 4, eye_y)
	var antenna: Rect2i = parts["antenna"]
	var ball := Vector2i(antenna.position.x + 1, antenna.position.y - 1)
	# Back-to-front: antenna, ball, limbs, then body/face on top.
	PixelDsl.rect(img, antenna, body_dark)
	PixelDsl.disc(img, ball, 2, accent)
	PixelDsl.rect(img, parts["arm_l"], body)
	PixelDsl.rect(img, parts["arm_r"], body)
	PixelDsl.rect(img, parts["leg_l"], body_dark)
	PixelDsl.rect(img, parts["leg_r"], body_dark)
	PixelDsl.rect(img, parts["foot_l"], body_dark)
	PixelDsl.rect(img, parts["foot_r"], body_dark)
	PixelDsl.rect(img, parts["body"], body)
	PixelDsl.outline(img, parts["body"], body_dark)
	PixelDsl.rect(img, face, body_dark)
	PixelDsl.disc(img, eye_l, 2, eye)
	PixelDsl.disc(img, eye_r, 2, eye)
	PixelDsl.disc(img, eye_l, 1, eye_glow)
	PixelDsl.disc(img, eye_r, 1, eye_glow)
