extends GdToolsTest
## Tests for the area transition and the celebration (Phase 5).
##
## The game root owns the area index. Walking into an open door fades the
## screen through the outgoing area's sky colour, swaps to the next area at the
## midpoint, and fades back in through the incoming sky. The gem counter is a
## lifetime score and survives every swap. Finishing the last area celebrates
## first, then loops home to the meadow.
##
## The transition is driven by an explicit step(delta) so tests are
## deterministic: one big step jumps straight to the end, a fractional step
## stops after the midpoint swap.

const GAME_SCRIPT := "res://src/levels/game.gd"


func _game() -> Game:
	# Phase 3 persists to disk: a Game boot must start from a clean slate.
	SaveGame.clear()
	var game: Game = load(GAME_SCRIPT).new()
	add_child(game)
	return game


func _area(game: Game) -> AreaBuilder:
	return game.builder


func _enter_door(game: Game) -> void:
	# GoalState and Door's own suites prove that keys open the door and that
	# only a real walk-in emits `entered`, so the game-level wiring is tested
	# by emitting the signal the engine would emit.
	for _i: int in AreaLayout.KEYS_PER_AREA:
		_area(game).goal_state.take_key()
	_area(game).door.entered.emit(_area(game).door)


func _step_through(game: Game) -> void:
	game.transition.step(Tuning.TRANSITION_TIME)


# --- where the world begins -------------------------------------------------


func test_the_game_opens_in_the_meadow() -> void:
	var game := _game()
	assert_eq(game.area_index, 0, "a new launch always starts at the meadow.")
	assert_eq(_area(game).area_name(), "meadow", "the first area is live.")


# --- entering the door ------------------------------------------------------


func test_entering_the_door_fades_through_the_outgoing_palette() -> void:
	var game := _game()
	_enter_door(game)
	assert_true(game.transition.is_running(), "the fade has begun.")
	assert_eq(
		game.transition.from_color,
		Palettes.AREA_PALETTES["meadow"]["sky_top"],
		"the screen sinks into the sky the child is leaving."
	)
	assert_eq(
		game.transition.to_color,
		Palettes.AREA_PALETTES["cave"]["sky_top"],
		"and rises out of the sky they are entering."
	)


func test_the_swap_rebuilds_the_next_area_with_a_fresh_goal() -> void:
	var game := _game()
	var old := _area(game)
	_enter_door(game)
	game.transition.step(Tuning.TRANSITION_TIME * 0.6)
	assert_eq(game.area_index, 1, "the second area is live by the midpoint.")
	assert_eq(_area(game).area_name(), "cave", "the cave is the next area.")
	assert_ne(_area(game), old, "a new world was built.")
	assert_true(old.is_queued_for_deletion(), "the old area is released.")
	assert_eq(_area(game).goal_state.keys_taken(), 0, "a fresh chase begins.")
	assert_eq(_area(game).key_counter.count(), 0, "and the badge starts empty.")


func test_the_fade_finishes_and_the_veil_clears() -> void:
	var game := _game()
	_enter_door(game)
	_step_through(game)
	assert_false(game.transition.is_running(), "the fade ends.")
	assert_false(game.transition.is_veil_visible(), "and the veil is gone.")


func test_a_second_door_bump_during_the_fade_is_ignored() -> void:
	# The open door's sensor keeps overlapping Robo for a few frames after the
	# first entry. Without a guard the game would queue two swaps.
	var game := _game()
	_enter_door(game)
	_area(game).door.entered.emit(_area(game).door)
	_step_through(game)
	assert_eq(game.area_index, 1, "exactly one swap happened.")


# --- what survives the swap -------------------------------------------------


func test_the_gem_counter_persists_across_areas() -> void:
	# Gems are a lifetime delight counter, not a per-area score. A child who
	# collected eight gems must still see eight after the door.
	var game := _game()
	game.wallet.add(7)
	_area(game).counter.set_count(game.wallet.balance())
	_enter_door(game)
	_step_through(game)
	assert_eq(_area(game).counter.count(), 7, "the gem total rides along.")
	assert_eq(game.wallet.balance(), 7, "the session wallet rides along.")


# --- the full loop ----------------------------------------------------------


func test_finishing_the_last_area_celebrates_and_loops_home() -> void:
	var game := _game()
	var marks := [0]
	game.celebrated.connect(func() -> void: marks[0] += 1)
	_enter_door(game)
	_step_through(game)
	assert_eq(game.area_index, 1, "meadow leads to the cave.")
	assert_eq(marks[0], 0, "no celebration for an ordinary door.")
	_enter_door(game)
	_step_through(game)
	assert_eq(game.area_index, 2, "the cave leads to the sunset hills.")
	_enter_door(game)
	assert_eq(marks[0], 1, "the last door triggers the celebration first.")
	_step_through(game)
	assert_eq(game.area_index, 0, "and the world loops home to the meadow.")
	assert_eq(marks[0], 1, "celebrated exactly once.")


func test_the_loop_celebration_points_robo_nowhere_and_stays_playable() -> void:
	# After the loop the fresh meadow must be a normal area: fresh keys, fresh
	# door, Robo standing on the ground ready to go.
	var game := _game()
	_enter_door(game)
	_step_through(game)
	_enter_door(game)
	_step_through(game)
	_enter_door(game)
	_step_through(game)
	var area := _area(game)
	assert_eq(area.goal_state.keys_taken(), 0, "the looped meadow wants keys again.")
	assert_eq(area.door.is_solid(), true, "its door is shut.")
	assert_gt(area.robot.position.y, 0.0, "Robo is in the world, not in the void.")
