extends GdToolsTest
## Tests for the Gem entity and its collect/respawn state machine (Phase 2).
##
## The gem is a code-assembled Area2D: overlap collects it, a timer respawns
## it forever. The bob is pure sine math tested without frames; collection
## and respawn are tested with real physics/tree where overlap is involved.

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


func test_gem_waits_for_the_body_to_leave_before_respawning() -> void:
	# A gem must not pop back under the body that just took it.
	var gem := _gem()
	gem.respawn_delay = 0.05
	var body := _body_at(Vector2.ZERO)
	gem.collect()
	await get_tree().create_timer(0.2).timeout
	assert_true(gem.is_collected(), "gem stays hidden while Robo stands on the spot.")
	body.queue_free()
	await get_tree().create_timer(0.3).timeout
	assert_false(gem.is_collected(), "gem returns once the spot is clear.")


func test_gem_respawns_after_its_delay() -> void:
	var gem := _gem()
	gem.respawn_delay = 0.1
	var fired := [false]
	gem.respawned.connect(func(_g: Area2D) -> void: fired[0] = true)
	gem.collect()
	assert_false(fired[0], "respawn does not fire immediately.")
	await get_tree().create_timer(0.3).timeout
	assert_true(fired[0], "gem respawns after its delay.")
	assert_false(gem.is_collected(), "respawned gem is collectable again.")
	var sprite := gem.find_child("Sprite", true, false) as Sprite2D
	assert_true(sprite.visible, "respawned gem shows its art again.")


func test_collect_respawn_cycle_repeats() -> void:
	var gem := _gem()
	gem.respawn_delay = 0.05
	var count := [0]
	gem.collected.connect(func(_g: Area2D) -> void: count[0] += 1)
	for cycle: int in range(3):
		gem.collect()
		assert_eq(count[0], cycle + 1, "cycle %d collected." % (cycle + 1))
		await get_tree().create_timer(0.15).timeout
		assert_false(gem.is_collected(), "cycle %d respawned." % (cycle + 1))
	assert_eq(count[0], 3, "three full cycles collected three times.")


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
