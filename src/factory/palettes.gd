class_name Palettes
## Named color palettes for all generated assets.
##
## Area palettes recolor the world per region (tiles, props, sky); the robot
## palette stays constant across areas so the character reads as the same
## friendly companion everywhere. Colors are bright and high-contrast per the
## product guidelines for young children.

const PALETTE_ROBOT := {
	"body": Color("f25c54"),
	"body_dark": Color("b23e37"),
	"eye": Color("ffffff"),
	"eye_glow": Color("ffe066"),
	"accent": Color("ffd93d"),
}

const AREA_PALETTES := {
	"meadow":
	{
		"sky_top": Color("7ec8e3"),
		"sky_bottom": Color("cdeffd"),
		"ground": Color("8b5a2b"),
		"ground_dark": Color("6b4423"),
		"grass": Color("58c24f"),
		"accent": Color("ffd93d"),
	},
	"cave":
	{
		"sky_top": Color("2b2e4a"),
		"sky_bottom": Color("5c5470"),
		"ground": Color("6e6a8a"),
		"ground_dark": Color("47436b"),
		"grass": Color("9b8bb4"),
		"accent": Color("b983ff"),
		# Cave deco set (area-personality): glowing crystals + stalactites +
		# glow-shrooms on teal moss. Bright cool tones so props glow against
		# the dark cave ground.
		"crystal": Color("7ef0ff"),
		"crystal_dark": Color("3fa8c9"),
		"glow": Color("fff3a3"),
		"moss": Color("5fe8b5"),
	},
	"sunset":
	{
		"sky_top": Color("ff9a76"),
		"sky_bottom": Color("ffd7a8"),
		"ground": Color("a5694a"),
		"ground_dark": Color("7c4a33"),
		"grass": Color("e8875f"),
		"accent": Color("ff5d8f"),
		# Sunset deco set (area-personality): rounded buttes + warm tufts +
		# sunblooms and pale pebbles. Hot terracotta + sunny yellow so props
		# read warm against the orange ground.
		"butte": Color("d96f4e"),
		"butte_dark": Color("8f3f2e"),
		"bloom": Color("ffd93d"),
		"pebble": Color("ffe3c2"),
	},
}
