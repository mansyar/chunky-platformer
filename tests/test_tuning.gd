extends GdToolsTest
## Tests for the game tuning constants file (Movement Phase 1).
##
## All gameplay numbers live in ONE file (Tuning). These tests lock the
## values the spec promises and the relationships that make them safe:
## bounce stronger than jump, gravity gentler than Godot's default, and
## grace timers in a toddler-friendly range.

const GODOT_DEFAULT_GRAVITY := 980.0


func test_walk_speed_matches_spec() -> void:
	# 2.5 tiles/s at the 16px tile size = 40 px/s.
	assert_eq(Tuning.WALK_SPEED, AssetSpec.TILE_SIZE.x * 2.5, "walk speed is 2.5 tiles/s.")


func test_accel_ramp_is_tiny() -> void:
	assert_gt(Tuning.ACCEL_TIME, 0.05, "acceleration ramp is not instant.")
	assert_lt(Tuning.ACCEL_TIME, 0.2, "acceleration ramp stays tiny.")


func test_gravity_is_gentler_than_default() -> void:
	assert_lt(Tuning.GRAVITY, GODOT_DEFAULT_GRAVITY, "gravity below Godot default for floaty arcs.")
	assert_gt(Tuning.GRAVITY, 0.0, "gravity still pulls down.")


func test_fall_speed_is_capped() -> void:
	assert_gt(Tuning.FALL_SPEED_CAP, 0.0, "terminal fall cap exists.")


func test_bounce_is_stronger_than_jump() -> void:
	assert_gt(
		Tuning.BOUNCE_IMPULSE, Tuning.JUMP_IMPULSE, "trampoline throws higher than a normal jump."
	)


func test_grace_timers_match_spec() -> void:
	assert_almost_eq(Tuning.COYOTE_TIME, 0.1, 0.01, "coyote time ~0.1s.")
	assert_almost_eq(Tuning.JUMP_BUFFER, 0.1, 0.01, "jump buffer ~0.1s.")


func test_camera_smoothing_is_positive() -> void:
	assert_gt(Tuning.CAMERA_SMOOTHING, 0.0, "camera follow smoothing configured.")
