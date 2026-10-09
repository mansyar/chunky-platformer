extends GdToolsTest
## The goal loop as a child experiences it in a real level (Phase 3).
##
## Entity tests prove the pieces work. This proves they are actually wired
## together in a built area - the failure mode that matters is a door that
## never opens because nobody connected it to the key tally.

const PLAYGROUND_SCENE := "res://src/levels/playground.tscn"


func _open_level() -> Node:
	var level: Node = load(PLAYGROUND_SCENE).instantiate()
	add_child(level)
	return level


func _state(level: Node) -> GoalState:
	return level.find_child("GoalState", true, false) as GoalState


func _door(level: Node) -> Door:
	return level.find_child("Door", true, false) as Door


func _keys(level: Node) -> Array[Node]:
	return level.find_children("*", "Key", true, false)


func test_the_meadow_ships_a_working_goal_loop() -> void:
	var level := _open_level()
	assert_not_null(_state(level), "the area tracks its own goal.")
	assert_not_null(_door(level), "and has a door.")
	assert_eq(_keys(level).size(), AreaLayout.KEYS_PER_AREA, "with three keys to find.")
	assert_not_null(level.find_child("KeyCounter", true, false), "and a badge counting them.")


func test_collecting_keys_unlocks_the_door_and_fills_the_badge() -> void:
	var level := _open_level()
	var state := _state(level)
	var door := _door(level)
	var badge := level.find_child("KeyCounter", true, false) as KeyCounter
	assert_true(door.is_solid(), "the door starts shut.")
	for _i: int in AreaLayout.KEYS_PER_AREA - 1:
		_take_a_key(level, _i)
		assert_true(door.is_solid(), "still shut at %d keys." % (_i + 1))
	_take_a_key(level, AreaLayout.KEYS_PER_AREA - 1)
	assert_false(door.is_solid(), "the last key opens it.")
	assert_eq(badge.count(), AreaLayout.KEYS_PER_AREA, "and the badge agrees.")
	assert_true(state.is_complete(), "and the area knows it is finished.")


func test_taking_a_real_key_drives_the_whole_chain() -> void:
	# The end-to-end path: walk into an actual Key node in the world and check
	# that the tally, the badge and the door all react - no manual wiring.
	var level := _open_level()
	var key := _keys(level)[0] as Key
	var badge := level.find_child("KeyCounter", true, false) as KeyCounter
	key.take()
	await get_tree().process_frame
	assert_eq(badge.count(), 1, "the badge moved.")
	assert_eq(_state(level).keys_taken(), 1, "so did the goal tally.")
	assert_true(_door(level).is_solid(), "one key is not three.")


func test_the_door_is_where_the_layout_puts_it() -> void:
	var level := _open_level()
	assert_eq(
		_door(level).position,
		AreaLayout.meadow().door_at,
		"the door stands where the layout says, not on a placeholder."
	)


func test_robo_always_draws_in_front_of_the_level() -> void:
	# A door is 32x48 and Robo is 32x32, so walking into the doorway makes them
	# overlap. Siblings paint in tree order, and the door is built after the
	# robot, so without an explicit z-index the door would cover Robo at the
	# exact moment the player is most interested in him.
	var level := _open_level()
	var robot := level.find_child("Robo", true, false) as Node2D
	for other: Node2D in [
		_door(level), _keys(level)[0] as Node2D, level.find_child("World", true, false)
	]:
		assert_gt(
			robot.z_index,
			other.z_index,
			"Robo must paint above the door, the keys and the terrain."
		)


func _take_a_key(level: Node, index: int) -> void:
	var key := _keys(level)[index] as Key
	key.take()
	await get_tree().process_frame
