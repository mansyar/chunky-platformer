class_name AssetSpec
## The single source of truth for every generated visual asset.
##
## Each entry is a plain Dictionary describing one output the AssetFactory
## must produce. Generators and the factory both read from this spec, and
## tests assert the factory can produce every entry — spec-first per the
## tech stack.
##
## Entry fields:
##   name    String  unique snake_case identifier
##   kind    String  "tile" | "deco" | "background" | "frame" | "prop"
##   size    Vector2i  pixel dimensions of the generated image
##   palette String  "area" (recolors per area palette) or "robot"
##
## Tiles are 16x16 and rendered with nearest-neighbor filtering, so they
## scale crisply at any zoom. The robot is 32x32 for chunky readability.

const TILE_SIZE := Vector2i(16, 16)
const ROBOT_FRAME_SIZE := Vector2i(32, 32)

const SPEC: Array = [
	# --- world tiles (8) ---
	{"name": "tile_solid", "kind": "tile", "size": TILE_SIZE, "palette": "area"},
	{"name": "tile_grass_top", "kind": "tile", "size": TILE_SIZE, "palette": "area"},
	{"name": "tile_platform", "kind": "tile", "size": TILE_SIZE, "palette": "area"},
	{"name": "tile_trampoline", "kind": "tile", "size": TILE_SIZE, "palette": "area"},
	{"name": "deco_grass_tuft", "kind": "deco", "size": TILE_SIZE, "palette": "area"},
	{"name": "deco_rock", "kind": "deco", "size": TILE_SIZE, "palette": "area"},
	{"name": "deco_flower", "kind": "deco", "size": TILE_SIZE, "palette": "area"},
	# Screen-resolution vertical gradient: rendered 1:1 behind the scaled
	# world, so gradient steps are one screen pixel and invisible.
	{"name": "sky_strip", "kind": "background", "size": Vector2i(16, 720), "palette": "area"},
	# --- robot animation frames (8): idle x2, walk x4, jump, land-squash ---
	{"name": "robot_idle_0", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_idle_1", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_walk_0", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_walk_1", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_walk_2", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_walk_3", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_jump", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	{"name": "robot_land", "kind": "frame", "size": ROBOT_FRAME_SIZE, "palette": "robot"},
	# --- interactive props ---
	{"name": "gem", "kind": "prop", "size": TILE_SIZE, "palette": "area"},
	{"name": "key", "kind": "prop", "size": TILE_SIZE, "palette": "area"},
	{"name": "door_locked", "kind": "prop", "size": Vector2i(32, 48), "palette": "area"},
	{"name": "door_open", "kind": "prop", "size": Vector2i(32, 48), "palette": "area"},
	{"name": "touch_left", "kind": "ui", "size": Vector2i(24, 24), "palette": "robot"},
	{"name": "touch_right", "kind": "ui", "size": Vector2i(24, 24), "palette": "robot"},
	{"name": "touch_jump", "kind": "ui", "size": Vector2i(24, 24), "palette": "robot"},
	{"name": "digit_0", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_1", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_2", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_3", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_4", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_5", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_6", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_7", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_8", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
	{"name": "digit_9", "kind": "ui", "size": Vector2i(8, 12), "palette": "robot"},
]
