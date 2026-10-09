extends GdToolsTest
## Tests for the goal state and the door (Phase 3).
##
## This is the part of the game a 4-year-old can get stuck on forever, so it is
## written as a safety property rather than as a feature: there is no path that
## locks the door with keys still unclaimed, and no path that opens it early.

const DOOR_SCRIPT := "res://src/world/door.gd"


func _state() -> GoalState:
	var state := GoalState.new()
	add_child(state)
	return state


func _door() -> Door:
	var door: Door = load(DOOR_SCRIPT).new()
	door.palette = "meadow"
	add_child(door)
	return door


func _body_at(position: Vector2) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.position = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	return body


# --- goal state ------------------------------------------------------------


func test_a_fresh_area_is_locked_at_zero_keys() -> void:
	var state := _state()
	assert_eq(state.keys_taken(), 0, "no keys yet.")
	assert_false(state.is_complete(), "so the area cannot be finished.")
	assert_true(state.is_locked(), "and the door is shut until the keys are found.")


func test_taking_a_key_counts_once_and_announces_progress() -> void:
	var state := _state()
	var announced := [0]
	state.progress.connect(func(_n: int) -> void: announced[0] += 1)
	state.take_key()
	assert_eq(state.keys_taken(), 1, "one key banked.")
	assert_eq(announced[0], 1, "the HUD and hint timer hear about it once.")


func test_goal_completes_only_at_three_keys() -> void:
	var state := _state()
	for taken: int in [1, 2]:
		state.take_key()
		assert_false(state.is_complete(), "%d of 3 is not enough." % taken)
	state.take_key()
	assert_true(state.is_complete(), "3 of 3 finishes the area.")
	assert_false(state.is_locked(), "and the door is free.")


func test_goal_state_never_exceeds_the_key_count() -> void:
	# Double-collecting a key (or a duplicated signal) must not bank a fourth
	# key and hand out an unearned win.
	var state := _state()
	for _i: int in 5:
		state.take_key()
	assert_eq(state.keys_taken(), AreaLayout.KEYS_PER_AREA, "capped at the goal.")
	assert_eq(state.keys_remaining(), 0, "nothing left, and not a negative remainder.")


func test_reset_returns_the_area_to_locked() -> void:
	var state := _state()
	for _i: int in AreaLayout.KEYS_PER_AREA:
		state.take_key()
	state.reset()
	assert_eq(state.keys_taken(), 0, "a fresh area starts empty.")
	assert_true(state.is_locked(), "and locked again.")


# --- the door --------------------------------------------------------------


func test_door_starts_solid_and_locked() -> void:
	var door := _door()
	assert_true(door.is_solid(), "a locked door stops a child walking through it.")
	assert_eq(
		door.find_child("Sprite", true, false).texture, _texture("door_locked"), "locked art."
	)


func test_door_opens_at_three_keys_and_swaps_its_art() -> void:
	var door := _door()
	var state := _state()
	state.progress.connect(door.on_progress)
	for _i: int in AreaLayout.KEYS_PER_AREA:
		state.take_key()
	assert_false(door.is_solid(), "an open door stops blocking the way.")
	assert_eq(door.find_child("Sprite", true, false).texture, _texture("door_open"), "open art.")


func test_door_stays_solid_until_the_last_key() -> void:
	var door := _door()
	var state := _state()
	state.progress.connect(door.on_progress)
	for _i: int in AreaLayout.KEYS_PER_AREA - 1:
		state.take_key()
		assert_true(door.is_solid(), "still locked at %d keys." % _i)


func test_door_announces_its_opening() -> void:
	var door := _door()
	var state := _state()
	state.progress.connect(door.on_progress)
	var unlocks := [0]
	door.unlocked.connect(func(_d: Door) -> void: unlocks[0] += 1)
	state.take_key()
	state.take_key()
	state.take_key()
	assert_eq(unlocks[0], 1, "the transition listens for this exactly once.")


func test_walking_into_an_open_door_starts_the_transition() -> void:
	var door := _door()
	var state := _state()
	state.progress.connect(door.on_progress)
	for _i: int in AreaLayout.KEYS_PER_AREA:
		state.take_key()
	var exits := [0]
	door.entered.connect(func(_d: Door) -> void: exits[0] += 1)
	var body := _body_at(door.position)
	for _frame: int in 6:
		await get_tree().physics_frame
	assert_eq(exits[0], 1, "an open door leads onward.")


func test_walking_into_a_locked_door_does_nothing() -> void:
	# No bounce, no buzz, no signal: a locked door is simply a wall.
	var door := _door()
	var exits := [0]
	door.entered.connect(func(_d: Door) -> void: exits[0] += 1)
	var body := _body_at(door.position)
	for _frame: int in 6:
		await get_tree().physics_frame
	assert_eq(exits[0], 0, "a locked door never sends a child onward.")


func test_door_tints_itself_to_its_area() -> void:
	var door := Door.new()
	door.palette = "sunset"
	add_child(door)
	assert_eq(
		door.find_child("Sprite", true, false).texture,
		AssetFactory.get_texture("door_locked", "sunset"),
		"a sunset door looks like a sunset door."
	)


func _texture(asset: String) -> Texture2D:
	return AssetFactory.get_texture(asset, "meadow")
