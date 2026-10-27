extends GdToolsTest
## Tests for the Gem entity and its collect state machine (Phase 2, updated
## by gem_shop_20261027 Phase 1: fixed budget, no respawn).
##
## The gem is a code-assembled Area2D: overlap collects it and it stays
## collected. The bob is pure sine math tested without frames; collection
## is tested with real physics/tree where overlap is involved.

const GEM_SCRIPT := "res://src/world/gem.gd"


func _gem() -> Area2D:
	var gem: Area2D = load(GEM_SCRIPT).new()
	add_child(gem)
	return gem


func _body_at(pos: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	body.add_child(shape)
	body.position = pos
	add_child(body)
	return body


func test_gem_builds_sprite_and_sensor() -> void:
	var gem := _gem()
	var sprite := gem.find_child("Sprite", true, false) as Sprite2D
	assert_not_null(sprite, "gem builds a sprite.")
	assert_eq(sprite.texture, AssetFactory.get_texture("gem", "meadow"), "sprite uses the gem art.")
	var shape := gem.find_child("Shape", true, false) as CollisionShape2D
	assert_not_null(shape, "gem builds a collision shape.")
	assert_true(gem.monitoring, "gem watches for bodies.")


func test_gem_tints_itself_to_its_area() -> void:
	# product.md promises three areas with distinct palettes; a cave gem must
	# not be meadow yellow.
	var gem: Area2D = load(GEM_SCRIPT).new()
	gem.palette = "cave"
	add_child(gem)
	var sprite := gem.find_child("Sprite", true, false) as Sprite2D
	assert_eq(
		sprite.texture,
		AssetFactory.get_texture("gem", "cave"),
		"the gem uses the palette its area asked for."
	)


func test_gem_pickup_radius_comes_from_tuning() -> void:
	var gem := _gem()
	var circle := (gem.find_child("Shape", true, false) as CollisionShape2D).shape as CircleShape2D
	assert_eq(
		circle.radius,
		Tuning.GEM_PICKUP_RADIUS,
		"pickup size is tuned in one place, not hardcoded in the entity."
	)


func test_bob_math_is_a_bounded_sine() -> void:
	assert_almost_eq(Gem.bob_offset(0.0), 0.0, 0.001, "bob starts at rest.")
	var amp: float = Tuning.GEM_BOB_AMPLITUDE
	assert_almost_eq(
		Gem.bob_offset(PI / (2.0 * Tuning.GEM_BOB_SPEED)), amp, 0.01, "bob rises to its amplitude."
	)
	for i: int in range(20):
		var t := float(i) * 0.37
		assert_true(
			absf(Gem.bob_offset(t)) <= amp + 0.001, "bob never exceeds its amplitude (t=%.2f)." % t
		)


func test_bob_moves_the_sprite_over_time() -> void:
	var gem := _gem()
	var sprite := gem.find_child("Sprite", true, false) as Sprite2D
	var start_y := sprite.position.y
	gem.update_bob(0.25)
	var moved := sprite.position.y - start_y
	assert_true(absf(moved) > 0.0, "bobbing moves the sprite.")


func test_walking_into_a_gem_collects_it() -> void:
	var gem := _gem()
	var body := _body_at(Vector2(0, -40))
	var fired := [false]
	gem.collected.connect(func(_g: Area2D) -> void: fired[0] = true)
	body.position = Vector2.ZERO
	for i: int in range(6):
		await get_tree().physics_frame
	assert_true(fired[0], "overlap with a body collects the gem.")
	assert_true(gem.is_collected(), "gem reports collected state.")


func test_collected_gem_hides_its_art() -> void:
	var gem := _gem()
	var sprite := gem.find_child("Sprite", true, false) as Sprite2D
	gem.collect()
	assert_true(gem.is_collected(), "gem is collected.")
	assert_false(sprite.visible, "collected gem hides its art.")


func test_collected_gem_stays_collected_forever() -> void:
	# Fixed budget (gem_shop_20261027): no timed respawn. A collected gem
	# stays hidden until the area is rebuilt with fresh taken flags.
	var gem := _gem()
	gem.collect()
	await get_tree().create_timer(0.3).timeout
	assert_true(gem.is_collected(), "the gem stays hidden: no timed respawn.")


func test_start_collected_hides_without_a_signal() -> void:
	# Revisit path: the builder pre-collects taken gems silently.
	var pre: Area2D = load(GEM_SCRIPT).new()
	(pre as Gem).start_collected()
	var count := [0]
	(pre as Gem).collected.connect(func(_g: Area2D) -> void: count[0] += 1)
	add_child(pre)
	assert_true((pre as Gem).is_collected(), "the gem starts hidden.")
	assert_eq(count[0], 0, "pre-collecting emits nothing.")


func test_collect_signal_carries_the_gem() -> void:
	var gem := _gem()
	var who := [null]
	gem.collected.connect(func(g: Area2D) -> void: who[0] = g)
	gem.collect()
	assert_eq(who[0], gem, "collected signal carries the gem itself.")


func test_no_double_collect_while_hidden() -> void:
	var gem := _gem()
	var count := [0]
	gem.collected.connect(func(_g: Area2D) -> void: count[0] += 1)
	gem.collect()
	gem.collect()
	gem.collect()
	assert_eq(count[0], 1, "collecting a collected gem does nothing.")
