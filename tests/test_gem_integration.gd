extends GdToolsTest
## End-to-end tests for gems in the playground level (Phase 5).
##
## Reach tiers are verified geometrically against the level's real surfaces
## (world y of the walkable tops) instead of trusting a hand-written label:
##   - walk  = gem hovering 12px above a surface
##   - jump  = gem exactly one jump apex (48px) above a surface
##   - bounce= gem high above a trampoline, only the arc reaches it

const PLAYGROUND_SCENE := "res://src/levels/playground.tscn"
const SURFACES: Array[float] = [384.0, 416.0, 448.0, 480.0, 512.0]
const TRAMPOLINE_X: Array[float] = [328.0, 176.0]
const HOVER_ABOVE_SURFACE := 12.0
const JUMP_APEX := 48.0
const WALK_FRAMES := 200


func _open_level() -> Node2D:
	var level: Node2D = load(PLAYGROUND_SCENE).instantiate()
	add_child(level)
	return level


func _gems(level: Node2D) -> Array[Node]:
	return level.find_children("*", "Gem", true, false)


func _counter(level: Node2D) -> GemCounter:
	for child: Node in level.get_children():
		if child is GemCounter:
			return child
	return null


func _robot(level: Node2D) -> Robot:
	return level.find_child("Robo", true, false) as Robot


func _ensure_actions() -> void:
	for action: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _walk_until_collected(level: Node2D, direction: String) -> bool:
	_ensure_actions()
	Input.action_press(direction)
	for i: int in range(WALK_FRAMES):
		await get_tree().physics_frame
		if _counter(level).count() > 0:
			Input.action_release(direction)
			return true
	Input.action_release(direction)
	return false


func test_level_spawns_twelve_gems() -> void:
	var level := _open_level()
	assert_eq(_gems(level).size(), 12, "the playground holds twelve collectible gems.")


func test_gems_are_grouped_into_reachable_tiers() -> void:
	var level := _open_level()
	var walk := 0
	var jump := 0
	var bounce := 0
	for gem: Node in _gems(level):
		var pos: Vector2 = gem.position
		var matched := false
		for surface: float in SURFACES:
			if absf(pos.y - (surface - HOVER_ABOVE_SURFACE)) < 1.0:
				walk += 1
				matched = true
				break
			if absf(pos.y - (surface - JUMP_APEX)) < 1.0:
				jump += 1
				matched = true
				break
		if not matched:
			for tramp_x: float in TRAMPOLINE_X:
				if absf(pos.x - tramp_x) <= 16.0 and pos.y <= 512.0 - 100.0:
					bounce += 1
					break
	assert_gte(walk, 6, "most gems are plain walking pickups.")
	assert_gte(jump, 2, "at least two gems need a jump.")
	assert_gte(bounce, 2, "at least two gems need the trampoline arc.")


func test_level_has_a_counter_starting_at_zero() -> void:
	var level := _open_level()
	assert_not_null(_counter(level), "the level owns a HUD counter.")
	assert_eq(_counter(level).count(), 0, "the counter starts empty.")


func test_no_static_gem_sprite_remains() -> void:
	# The old placeholder gem prop was a plain Sprite2D child of the world;
	# real gems are Gem (Area2D) entities instead.
	var level := _open_level()
	var world := level.get_node("World")
	var gem_texture: Texture2D = AssetFactory.get_texture("gem", "meadow")
	var leftover := 0
	for child: Node in world.get_children():
		if child is Sprite2D and (child as Sprite2D).texture == gem_texture:
			leftover += 1
	assert_eq(leftover, 0, "no plain gem sprites linger (gems are Gem nodes).")


func test_walking_right_collects_a_gem_and_counts_it() -> void:
	var level := _open_level()
	assert_true(await _walk_until_collected(level, "move_right"), "Robo collected a gem.")
	assert_eq(_counter(level).count(), 1, "the counter shows one gem.")
	var hidden := 0
	for gem: Node in _gems(level):
		if (gem as Gem).is_collected():
			hidden += 1
	assert_eq(hidden, 1, "exactly the walked-into gem is hidden.")


func test_collect_spawns_juice_and_celebrates() -> void:
	var level := _open_level()
	assert_true(await _walk_until_collected(level, "move_right"), "Robo collected a gem.")
	var pops := level.find_children("*", "PopEffect", true, false)
	assert_gt(pops.size(), 0, "collecting pops an effect.")
	var sprite := _robot(level).find_children("*", "AnimatedSprite2D", true, false)[0]
	# The celebration tween needs a frame to move the sprite.
	for i: int in range(3):
		await get_tree().process_frame
	assert_ne((sprite as AnimatedSprite2D).scale, Vector2.ONE, "Robo celebrates.")


func test_gem_respawns_after_its_delay() -> void:
	var level := _open_level()
	for gem: Node in _gems(level):
		(gem as Gem).respawn_delay = 0.1
	assert_true(await _walk_until_collected(level, "move_right"), "Robo collected a gem.")
	var collected: Array[Node] = []
	for gem: Node in _gems(level):
		if (gem as Gem).is_collected():
			collected.append(gem)
	assert_eq(collected.size(), 1, "one gem was taken.")
	var count_after: int = _counter(level).count()
	# Put Robo somewhere far away (the gem waits for him to leave — a gem that
	# pops back under him would be a free gem and look broken).
	_robot(level).position = Vector2(100, 434)
	for i: int in range(5):
		await get_tree().physics_frame
	await get_tree().create_timer(0.6).timeout
	var gem := collected[0] as Gem
	assert_false(gem.is_collected(), "the gem came back.")
	var art := gem.find_child("Sprite", true, false) as Sprite2D
	assert_true(art.visible, "the returned gem shows its art again.")
	assert_eq(
		_counter(level).count(),
		count_after,
		(
			"the counter keeps the collected total (count=%d, was %d)"
			% [_counter(level).count(), count_after]
		)
	)


func test_robot_keeps_moving_while_collecting() -> void:
	# Anti-frustration rule: collecting must never interrupt movement.
	var level := _open_level()
	_ensure_actions()
	var robot := _robot(level)
	Input.action_press("move_right")
	for i: int in range(120):
		await get_tree().physics_frame
		if _counter(level).count() > 0:
			break
	var collected_at := robot.position.x
	for i: int in range(30):
		await get_tree().physics_frame
	Input.action_release("move_right")
	assert_gt(robot.position.x, collected_at + 10.0, "Robo kept walking after collecting.")
