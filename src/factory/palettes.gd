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
	},
	"sunset":
	{
		"sky_top": Color("ff9a76"),
		"sky_bottom": Color("ffd7a8"),
		"ground": Color("a5694a"),
		"ground_dark": Color("7c4a33"),
		"grass": Color("e8875f"),
		"accent": Color("ff5d8f"),
	},
}
