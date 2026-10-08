extends GdToolsTest
## Tests for Robo's animation state selection (Movement Phase 3).
##
## update_animation(delta, on_floor, moving) is frame-steppable pure logic:
## it chooses the animation and flips the sprite. The AnimatedSprite2D and
## its SpriteFrames are code-built from AssetFactory robot textures.


func _robot() -> Robot:
	# Added to the tree so _ready() runs and builds the sprite from AssetFactory.
	var robot: Robot = load("res://src/robot/robot.gd").new()
	add_child(robot)
	return robot


func _sprite(robot: Robot) -> AnimatedSprite2D:
	for child: Node in robot.get_children():
		if child is AnimatedSprite2D:
			return child
	return null


# --- SpriteFrames content ---


func test_frames_use_all_eight_robot_frames() -> void:
	var robot: Robot = _robot()
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_eq(sprite.sprite_frames.get_frame_count("idle"), 2, "idle bobs on two frames.")
	assert_eq(sprite.sprite_frames.get_frame_count("walk"), 4, "walk cycles four frames.")
	assert_eq(sprite.sprite_frames.get_frame_count("jump"), 1, "jump is a single frame.")
	assert_eq(sprite.sprite_frames.get_frame_count("land"), 1, "land-squash is a single frame.")


func test_walk_animation_is_looped_jump_is_not() -> void:
	var robot: Robot = _robot()
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_true(sprite.sprite_frames.get_animation_loop("walk"), "walk cycles.")
	assert_false(sprite.sprite_frames.get_animation_loop("jump"), "jump holds its pose.")


# --- state selection ---


func test_idle_when_still_on_floor() -> void:
	var robot: Robot = _robot()
	robot.update_animation(0.016, true, false)
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_eq(sprite.animation, "idle", "standing still bobs idly.")


func test_walk_while_moving_on_floor() -> void:
	var robot: Robot = _robot()
	robot.update_animation(0.016, true, true)
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_eq(sprite.animation, "walk", "moving on the floor walks.")


func test_jump_while_airborne() -> void:
	var robot: Robot = _robot()
	robot.update_animation(0.016, false, true)
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_eq(sprite.animation, "jump", "airborne Robo holds the jump pose.")


func test_landing_plays_squash_then_returns_to_idle() -> void:
	var robot: Robot = _robot()
	robot.update_animation(0.016, false, false)  # airborne
	robot.update_animation(0.016, true, false)  # just landed
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_eq(sprite.animation, "land", "landing squashes first.")
	robot.update_animation(Tuning.LAND_SQUASH_TIME, true, false)
	assert_eq(sprite.animation, "idle", "after the squash window Robo idles.")


# --- frame advancement ---


func test_walk_cycles_at_configured_speed() -> void:
	var robot: Robot = _robot()
	var sprite: AnimatedSprite2D = _sprite(robot)
	sprite.play("walk")
	assert_eq(
		sprite.sprite_frames.get_animation_speed("walk"),
		Tuning.WALK_ANIM_FPS,
		"walk beats at the tuned frame rate."
	)
	assert_true(sprite.is_playing(), "walk is actively playing.")
	assert_true(sprite.sprite_frames.get_animation_loop("walk"), "walk loops continuously.")


# --- facing flip ---


func test_sprite_flips_with_facing() -> void:
	var robot: Robot = _robot()
	robot.move_axis(-1.0, 0.016)
	robot.update_animation(0.016, true, true)
	var sprite: AnimatedSprite2D = _sprite(robot)
	assert_true(sprite.flip_h, "facing left mirrors the sprite.")
	robot.move_axis(1.0, 0.016)
	robot.update_animation(0.016, true, true)
	assert_false(sprite.flip_h, "facing right restores the sprite.")
