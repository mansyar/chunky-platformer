extends GdToolsTest
## Phase-3 wiring tests: every gameplay moment triggers the right sound.
##
## The rule that matters: sounds ride along with existing signals and handlers
## (robot takeoff, trampoline impulse, builder _on_*, game finale) and never
## reroute gameplay. Each test resets the shared voice pool, drives the real
## gameplay call, and proves a voice was claimed (or the ambient loop moved).
## The game root owns the one persistent AudioManager so area swaps crossfade;
## builders borrow it for ducking; robot and trampoline play without ducking
## (they fire too often to hold the loop down, and stay decoupled).

const GAME_SCRIPT := "res://src/levels/game.gd"


func _layout_named(area_name: String) -> AreaLayout:
	for layout: AreaLayout in AreaLayout.all():
		if layout.area_name == area_name:
			return layout
	return null


func _wallet_with(gems: int) -> Wallet:
	var wallet := Wallet.new()
	if gems > 0:
		wallet.add(gems)
	return wallet


func _area(area_name: String, banked: int = 0) -> AreaBuilder:
	var builder := AreaBuilder.new()
	add_child(builder)
	builder.build(_layout_named(area_name), _wallet_with(banked), [], Wardrobe.new())
	return builder


func _area_with_manager(area_name: String, banked: int = 0) -> Array:
	# Mirrors the game root's contract: the persistent manager is handed to
	# the builder after build so one-shots duck the loop.
	var manager := AudioManager.new()
	add_child(manager)
	var builder := _area(area_name, banked)
	builder.audio_manager = manager
	return [builder, manager]


func _game() -> Game:
	SaveGame.clear()
	var game: Game = load(GAME_SCRIPT).new()
	add_child(game)
	return game


func _enter_door(game: Game) -> void:
	for _i: int in AreaLayout.KEYS_PER_AREA:
		game.builder.goal_state.take_key()
	game.builder.door.entered.emit(game.builder.door)


func _step_through(game: Game) -> void:
	game.transition.step(Tuning.TRANSITION_TIME)


# --- movement + bounce -------------------------------------------------------


func test_jump_takeoff_plays_the_jump_sound() -> void:
	AudioFactory.reset_pool()
	var robot := Robot.new()
	robot.position = Vector2(100, 400)
	add_child(robot)
	var before := AudioFactory.active_voice_count()
	robot.update_jump(0.016, true, true)
	assert_eq(AudioFactory.active_voice_count(), before + 1, "takeoff whooshes once.")


func test_no_launch_means_no_jump_sound() -> void:
	AudioFactory.reset_pool()
	var robot := Robot.new()
	robot.position = Vector2(100, 400)
	add_child(robot)
	robot.update_jump(0.016, false, false)
	assert_eq(AudioFactory.active_voice_count(), 0, "standing still stays silent.")


func test_trampoline_bounce_plays_the_bounce_sound() -> void:
	AudioFactory.reset_pool()
	var trampoline := Trampoline.new()
	add_child(trampoline)
	var body := CharacterBody2D.new()
	body.velocity = Vector2(30, 100)
	trampoline.bounce(body)
	assert_eq(body.velocity.y, -Tuning.BOUNCE_IMPULSE, "physics still launches.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the pad boings on impulse.")


func test_rising_body_stays_silent_on_the_pad() -> void:
	AudioFactory.reset_pool()
	var trampoline := Trampoline.new()
	add_child(trampoline)
	var body := CharacterBody2D.new()
	body.velocity = Vector2(0, -100)
	trampoline.bounce(body)
	assert_eq(AudioFactory.active_voice_count(), 0, "a rising body is not bounced.")


func test_bounce_mashing_never_clips() -> void:
	AudioFactory.reset_pool()
	var trampoline := Trampoline.new()
	add_child(trampoline)
	var body := CharacterBody2D.new()
	for _i: int in 20:
		body.velocity = Vector2(0, 100)
		trampoline.bounce(body)
	assert_eq(
		AudioFactory.active_voice_count(),
		Tuning.AUDIO_MAX_VOICES,
		"mashing stays polyphonic: the cap holds."
	)


# --- collect + goal loop -----------------------------------------------------


func test_gem_collect_plays_the_gem_pop() -> void:
	var builder := _area("meadow")
	AudioFactory.reset_pool()
	var gem := builder.find_children("*", "Gem", true, false)[0] as Gem
	gem.collect()
	assert_eq(builder.wallet.balance(), 1, "the wallet still bumps.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the ring pops exactly once.")


func test_key_take_plays_the_key_chime() -> void:
	var builder := _area("meadow")
	AudioFactory.reset_pool()
	var key := builder.find_children("*", "Key", true, false)[0] as Key
	key.take()
	assert_eq(builder.goal_state.keys_taken(), 1, "progress still counts.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the key chimes exactly once.")


func test_door_unlock_plays_the_rising_chime() -> void:
	var builder := _area("meadow")
	AudioFactory.reset_pool()
	builder.door.on_progress(AreaLayout.KEYS_PER_AREA)
	assert_false(builder.door.is_solid(), "the door still opens.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the opening chimes once.")


# --- hint-safe ---------------------------------------------------------------


func test_sounds_never_block_hint_sparkles_or_pointing() -> void:
	# An empty wallet wiggles: the sound, the wiggle, and the hint sparkle
	# must all arrive together.
	var builder := _area("meadow", 0)
	AudioFactory.reset_pool()
	var wiggled := [false]
	var hinted: Array = []
	builder.machine.wiggled.connect(func() -> void: wiggled[0] = true)
	builder.machine.hinted.connect(func(target: Node2D) -> void: hinted.append(target))
	assert_eq(
		builder.machine.use(), GiftMachine.UseResult.WIGGLE, "an empty wallet wiggles kindly."
	)
	assert_true(wiggled[0], "the wiggle still signals.")
	assert_true(hinted.has(builder.machine.nearest_hint_gem()), "the trail still points.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the wiggle sounds once.")
	# And Robo still turns toward whatever a trail points at afterwards.
	builder.robot.point_at(hinted[0])
	assert_true(builder.robot.is_pointing(), "pointing survives the sounds.")


# --- gift machine ------------------------------------------------------------


func test_gift_dispense_plays_the_pop() -> void:
	var builder := _area("meadow", 3)
	AudioFactory.reset_pool()
	assert_eq(builder.machine.use(), GiftMachine.UseResult.DISPENSED, "a banked tap dispenses.")
	assert_eq(builder.machine.wardrobe.owned().size(), 1, "one gift owned.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the dispense pops once.")


func test_gift_bonus_plays_the_bonus_sound() -> void:
	var builder := _area("meadow", 0)
	for gift_id: String in Cosmetics.all_ids():
		builder.machine.wardrobe.own(gift_id)
	builder.machine.refresh_tag()
	AudioFactory.reset_pool()
	assert_eq(builder.machine.use(), GiftMachine.UseResult.BONUS, "a complete tap celebrates free.")
	assert_eq(builder.machine.wallet.balance(), 0, "the bonus stays free.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the bonus rings once.")


# --- ducking + ownership -----------------------------------------------------


func test_collect_ducks_the_area_loop() -> void:
	var wired := _area_with_manager("meadow")
	var builder: AreaBuilder = wired[0]
	var manager: AudioManager = wired[1]
	var gem := builder.find_children("*", "Gem", true, false)[0] as Gem
	gem.collect()
	assert_true(manager.is_ducked(), "the pop dips the loop for a breath.")


func test_game_owns_the_manager_and_lends_it_to_the_builder() -> void:
	var game := _game()
	assert_true(game.audio_manager is AudioManager, "the root owns one manager.")
	assert_eq(game.builder.audio_manager, game.audio_manager, "the live builder ducks through it.")


# --- finale + ambient --------------------------------------------------------


func test_boot_starts_the_meadow_loop() -> void:
	var game := _game()
	assert_eq(game.audio_manager.current_area(), "meadow", "the meadow hums from the first frame.")


func test_area_swap_crossfades_to_the_next_loop() -> void:
	var game := _game()
	game._build_area(1)
	assert_eq(game.audio_manager.target_area(), "cave", "the cave hum is coming.")
	assert_true(game.audio_manager.is_fading(), "the swap crossfades, never cuts.")
	game.audio_manager._process(Tuning.AUDIO_CROSSFADE_TIME + 0.05)
	assert_eq(game.audio_manager.current_area(), "cave", "the cave hum arrives.")
	assert_false(game.audio_manager.is_fading(), "the blend settles afterwards.")


func test_finale_plays_the_celebrate_flourish() -> void:
	var game := _game()
	var last := AreaLayout.all().size() - 1
	for _i: int in last:
		_enter_door(game)
		_step_through(game)
	assert_eq(game.area_index, last, "Robo reached the last area.")
	var fanfare := [0]
	game.celebrated.connect(func() -> void: fanfare[0] += 1)
	# Bank the keys first (their chimes are proven above), then reset the
	# pool so only the finale flourish is counted below.
	for _i: int in AreaLayout.KEYS_PER_AREA:
		game.builder.goal_state.take_key()
	AudioFactory.reset_pool()
	game.builder.door.entered.emit(game.builder.door)
	assert_eq(fanfare[0], 1, "the finale still signals once.")
	assert_eq(AudioFactory.active_voice_count(), 1, "the flourish rings once.")
	assert_true(game.audio_manager.is_ducked(), "the flourish dips the loop.")


func test_loop_home_returns_to_the_meadow_loop() -> void:
	var game := _game()
	for _i: int in AreaLayout.all().size():
		_enter_door(game)
		_step_through(game)
	assert_eq(game.area_index, 0, "the finale loops home.")
	assert_eq(game.audio_manager.current_area(), "meadow", "the meadow hum welcomes Robo back.")
