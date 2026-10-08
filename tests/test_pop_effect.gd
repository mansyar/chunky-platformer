extends GdToolsTest
## Tests for collection juice (Phase 3): the pop effect and Robo's
## visual-only celebration.

const POP_SCRIPT := "res://src/fx/pop_effect.gd"
const ROBOT_SCRIPT := "res://src/robot/robot.gd"


func _effect() -> Node2D:
	var effect: Node2D = load(POP_SCRIPT).new()
	add_child(effect)
	return effect


func test_pop_effect_is_pure_visual() -> void:
	var effect := _effect()
	assert_eq(effect.get_class(), "Node2D", "PopEffect draws, it does not do physics.")


func test_ring_grows_over_the_lifetime() -> void:
	assert_almost_eq(
		PopEffect.ring_radius(0.0), Tuning.POP_START_RADIUS, 0.01, "ring starts small."
	)
	assert_almost_eq(PopEffect.ring_radius(1.0), Tuning.POP_END_RADIUS, 0.01, "ring ends wide.")
	assert_almost_eq(
		PopEffect.ring_radius(0.5),
		(Tuning.POP_START_RADIUS + Tuning.POP_END_RADIUS) / 2.0,
		0.01,
		"ring grows linearly."
	)


func test_sparkles_are_deterministic() -> void:
	var a := PopEffect.sparkle_offsets(0.5)
	var b := PopEffect.sparkle_offsets(0.5)
	assert_eq(a.size(), Tuning.SPARKLE_COUNT, "a fixed sparkle count.")
	assert_true(a == b, "same progress gives the same sparkles (no randomness).")


func test_effect_advances_and_self_frees() -> void:
	var effect := _effect()
	assert_false(effect.is_done(), "a fresh effect is still alive.")
	effect.update_effect(Tuning.POP_LIFETIME + 0.01)
	assert_true(effect.is_done(), "effect finishes after its lifetime.")
	assert_true(effect.is_queued_for_deletion(), "finished effects clean themselves up.")


func test_spawn_places_the_effect_in_the_tree() -> void:
	var parent := Node2D.new()
	add_child(parent)
	var effect := PopEffect.spawn(parent, Vector2(64, 32), Color.RED)
	assert_not_null(effect, "spawn returns the effect.")
	assert_eq(effect.get_parent(), parent, "spawn attaches to the given parent.")
	assert_eq(effect.global_position, Vector2(64, 32), "spawn places the effect.")


func test_celebrate_does_not_touch_velocity() -> void:
	# celebrate() itself must never write velocity — checked immediately,
	# before physics frames get a chance to apply gravity or friction.
	var robot: CharacterBody2D = load(ROBOT_SCRIPT).new()
	add_child(robot)
	robot.velocity = Vector2(40, 30)
	robot.celebrate()
	assert_eq(robot.velocity, Vector2(40, 30), "celebration never touches velocity.")


func test_celebrate_squashes_only_the_sprite() -> void:
	var robot: CharacterBody2D = load(ROBOT_SCRIPT).new()
	add_child(robot)
	robot.celebrate()
	var sprite := robot.find_children("*", "AnimatedSprite2D", true, false)[0] as AnimatedSprite2D
	for i: int in range(4):
		await get_tree().physics_frame
	assert_ne(sprite.scale, Vector2.ONE, "the sprite squashes.")
	await get_tree().create_timer(Tuning.CELEBRATE_TIME + 0.2).timeout
	assert_eq(sprite.scale, Vector2.ONE, "the sprite settles back to normal.")


func test_celebrate_retrigger_is_safe() -> void:
	var robot: CharacterBody2D = load(ROBOT_SCRIPT).new()
	add_child(robot)
	robot.celebrate()
	robot.celebrate()
	await get_tree().create_timer(Tuning.CELEBRATE_TIME + 0.2).timeout
	var sprite := robot.find_children("*", "AnimatedSprite2D", true, false)[0] as AnimatedSprite2D
	assert_eq(sprite.scale, Vector2.ONE, "back-to-back celebrations settle cleanly.")
