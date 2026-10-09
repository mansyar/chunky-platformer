extends GdToolsTest
## Tests for the Key entity and the key counter badge (Phase 2).
##
## A key is permanent: once a child has it, it is theirs. That is the whole
## difference from a gem, and it is what makes the goal loop trustworthy - the
## counter can never go backwards and the door can never strand them.

const KEY_SCRIPT := "res://src/world/key.gd"


func _key() -> Key:
	var key: Key = load(KEY_SCRIPT).new()
	key.palette = "meadow"
	add_child(key)
	return key


func _body_at(position: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.position = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	return body


# --- construction -----------------------------------------------------------


func test_key_builds_a_sprite_and_a_sensor() -> void:
	var key := _key()
	assert_not_null(key.find_child("Sprite", true, false), "the key paints art.")
	assert_not_null(key.find_child("Shape", true, false), "the key can be touched.")
	assert_eq(key.find_child("Sprite", true, false).texture, _key_texture(), "it uses the key art.")


func test_key_tints_itself_to_its_area() -> void:
	var key := Key.new()
	key.palette = "cave"
	add_child(key)
	assert_eq(
		key.find_child("Sprite", true, false).texture,
		AssetFactory.get_texture("key", "cave"),
		"a key in the cave looks like a cave key."
	)


func test_key_starts_un_taken() -> void:
	assert_false(_key().is_taken(), "a fresh key has not been collected.")


# --- the bob ---------------------------------------------------------------


func test_key_bob_is_a_bounded_sine() -> void:
	# Same contract as Gem.bob_offset: pure, deterministic, and never leaves
	# its amplitude, so a key can never drift out of its own layout cell.
	assert_eq(Key.bob_offset(0.0), 0.0, "the bob starts at rest.")
	var peak := Key.bob_offset(PI / (2.0 * Tuning.KEY_BOB_SPEED))
	assert_almost_eq(peak, Tuning.KEY_BOB_AMPLITUDE, 0.01, "the bob reaches exactly its amplitude")
	assert_almost_eq(
		Key.bob_offset(PI / Tuning.KEY_BOB_SPEED), 0.0, 0.01, "the bob returns to rest"
	)
	for step: int in 20:
		var offset := Key.bob_offset(float(step) * 0.31)
		assert_lte(absf(offset), Tuning.KEY_BOB_AMPLITUDE, "the bob stays in range")


func test_key_bob_moves_only_the_art() -> void:
	var key := _key()
	var start := key.position
	key.update_bob(0.5)
	assert_eq(key.position, start, "bobbing must never move the collision sensor.")
	assert_ne(key.find_child("Sprite", true, false).position.y, 0.0, "the art is what bobs.")


# --- collection ------------------------------------------------------------


func test_key_collects_on_touch_and_is_permanent() -> void:
	var key := _key()
	var body := _body_at(key.position)
	for _frame: int in 6:
		await get_tree().physics_frame
	assert_true(key.is_taken(), "walking into a key takes it.")
	assert_false(key.find_child("Sprite", true, false).visible, "a taken key shows no art.")


func test_key_never_respawns() -> void:
	# The difference from a gem, stated structurally: a Key has no respawn
	# timer at all, so there is no code path that could bring it back.
	var key := _key()
	assert_null(
		key.find_child("RespawnTimer", true, false),
		"a key carries no timer - there is nothing that could return it."
	)
	var body := _body_at(key.position)
	for _frame: int in 6:
		await get_tree().physics_frame
	assert_true(key.is_taken(), "collected.")
	await get_tree().create_timer(0.3).timeout
	assert_true(key.is_taken(), "still taken after time passes - a key never comes back.")


func test_key_emits_once_when_taken() -> void:
	var key := _key()
	# GDScript lambdas capture locals by value, so the tally lives in a
	# one-element array the closure mutates.
	var tally := [0]
	key.taken.connect(func(_k: Key) -> void: tally[0] += 1)
	var body := _body_at(key.position)
	for _frame: int in 10:
		await get_tree().physics_frame
	assert_eq(tally[0], 1, "one key, one signal - walking past again is harmless.")


func test_key_ignores_bodies_that_are_not_characters() -> void:
	# Area2D overlap is not enough: a world object brushing a key must never
	# swallow it.
	var key := _key()
	var prop := StaticBody2D.new()
	prop.position = key.position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	prop.add_child(shape)
	add_child(prop)
	for _frame: int in 6:
		await get_tree().physics_frame
	assert_false(key.is_taken(), "a static body cannot collect a key.")


func _key_texture() -> Texture2D:
	return AssetFactory.get_texture("key", "meadow")
