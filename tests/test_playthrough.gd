extends GdToolsTest
## Full-loop playthrough (Phase 6): meadow -> cave -> sunset -> meadow.
##
## Keys are collected with real physics - Robo is teleported onto each key's
## sensor and the Area2D does the rest - so every grab proves the placement
## the reachability suite promises is actually collectable in engine.

const GAME_SCENE := "res://src/levels/game.tscn"
const SETTLE_FRAMES := 4


func _ensure_actions() -> void:
	for action: String in ["move_left", "move_right", "jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func _open_game() -> Node:
	# A Game boot resumes the save on disk: start from a clean slate so the
	# playthrough always opens in the meadow.
	SaveGame.clear()
	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(game)
	_ensure_actions()
	return game


func _robo(area: Node) -> CharacterBody2D:
	return area.find_child("Robo", true, false)


func _keys(area: Node) -> Array:
	return area.find_children("*", "Key", true, false)


func _grab(key: Node, robo: CharacterBody2D) -> void:
	robo.position = key.position
	for i: int in SETTLE_FRAMES:
		await get_tree().physics_frame


func _finish_area(game: Node) -> void:
	## Take all three keys and walk into the door. The caller rides the fade
	## separately so it can capture per-area state before the swap.
	var area: Node = game.builder
	var robo := _robo(area)
	for key: Node in _keys(area):
		await _grab(key, robo)
	assert_true(area.goal_state.is_complete(), "three grabs complete the area.")
	await get_tree().process_frame  # let the door free its solid body
	robo.position = area.door.position
	for i: int in SETTLE_FRAMES:
		await get_tree().physics_frame


func _ride_fade(game: Node) -> void:
	game.transition.step(Tuning.TRANSITION_TIME)


# --- the tests --------------------------------------------------------------


func test_the_main_scene_is_the_game_root() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene", ""),
		GAME_SCENE,
		"launching the game starts the three-area loop, not a lone meadow."
	)


func test_a_full_playthrough_loops_home_after_sunset() -> void:
	var game := _open_game()
	assert_eq(game.area_index, 0, "the game opens in the meadow.")
	for expected: int in [1, 2]:
		await _finish_area(game)
		_ride_fade(game)
		assert_eq(game.area_index, expected, "the door carries Robo into area %d." % expected)
		assert_eq(_keys(game.builder).size(), 3, "the new area has its three keys.")
		assert_false(game.builder.goal_state.is_complete(), "the new area starts locked.")
	var celebrated := [0]
	game.celebrated.connect(func() -> void: celebrated[0] += 1)
	await _finish_area(game)
	assert_eq(celebrated[0], 1, "finishing sunset celebrates once.")
	_ride_fade(game)
	assert_eq(game.area_index, 0, "area 3 loops home to the meadow.")
	assert_eq(_keys(game.builder).size(), 3, "the looped meadow has fresh keys.")
	assert_false(game.builder.goal_state.is_complete(), "the looped meadow is locked again.")
	for i: int in 30:
		await get_tree().physics_frame
	var robo := _robo(game.builder)
	var landed := false
	var trace := "area=%s" % game.builder.area_name()
	for i: int in 90:
		await get_tree().physics_frame
		if robo.is_on_floor():
			landed = true
			break
		if i % 15 == 0:
			trace += (
				" f%d=(%.0f,%.0f)v(%.0f,%.0f)"
				% [
					i,
					robo.position.x,
					robo.position.y,
					robo.velocity.x,
					robo.velocity.y,
				]
			)
	assert_true(
		landed,
		(
			"the looped meadow is playable - Robo lands (a graze on the spawn-adjacent"
			+ " trampoline is fine, a fall into the void is not). (%s)" % trace
		)
	)


func test_the_wallet_balance_persists_across_areas() -> void:
	var game := _open_game()
	# The wallet is the source of truth; the HUD mirrors it.
	game.wallet.add(7)
	await _finish_area(game)
	# Grabbing keys can incidentally collect gems on the way, so the score to
	# carry is whatever the wallet holds just before the fade, not 7.
	var carried: int = game.wallet.balance()
	_ride_fade(game)
	assert_eq(game.wallet.balance(), carried, "the gem score rides the transition.")
	assert_eq(game.builder.wallet_hud.balance(), carried, "the HUD rides the transition.")
	assert_eq(game.builder.key_counter.count(), 0, "keys reset for the new area.")


func test_hints_are_live_in_every_area() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var builder := AreaBuilder.new()
		add_child(builder)
		builder.build(layout)
		assert_true(
			builder.hint != null and builder.hint.goal_state == builder.goal_state,
			"%s: the hint system watches this area's goal." % layout.area_name
		)
