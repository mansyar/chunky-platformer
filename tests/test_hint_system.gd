extends GdToolsTest
## Tests for the hint system (Phase 4).
##
## A 4-year-old will wander, get distracted, or lose track of what they were
## doing. After HINT_DELAY seconds with no key progress the game shows a trail
## of sparkles from Robo to the next key, and Robo turns and points at it.
##
## The rule that matters: the hint never appears early, never points at a key
## that has already been taken, and never fires while the child is mid-play.


func _hint() -> HintSystem:
	var hint := HintSystem.new()
	hint.hint_delay = Tuning.HINT_DELAY
	add_child(hint)
	return hint


func _goal() -> GoalState:
	var goal := GoalState.new()
	add_child(goal)
	return goal


func _robot() -> Robot:
	var robot := Robot.new()
	robot.position = Vector2(100, 400)
	add_child(robot)
	return robot


func _key() -> Key:
	var key := Key.new()
	add_child(key)
	return key


# --- timing ----------------------------------------------------------------


func test_the_hint_is_armed_immediately() -> void:
	assert_false(_hint().is_showing(), "nothing is drawn at the start.")


func test_the_hint_fires_after_the_delay_with_no_progress() -> void:
	var hint := _hint()
	hint.hint_delay = 0.2
	var key := Key.new()
	add_child(key)
	hint.begin(_goal(), _robot(), [key])
	await _wait(0.25)
	assert_true(hint.is_showing(), "no progress for HINT_DELAY means a hint.")


func test_the_hint_does_not_fire_early() -> void:
	var hint := _hint()
	hint.hint_delay = 0.5
	await _wait(0.3)
	assert_false(hint.is_showing(), "a child exploring is not stuck yet.")


func test_collecting_a_key_re_arms_the_timer() -> void:
	# The whole point: progress buys silence. Without this the trail would keep
	# nagging a child who is doing exactly the right thing.
	var hint := _hint()
	hint.hint_delay = 0.2
	hint.begin(_goal(), _robot(), [_key()])
	await _wait(0.25)
	assert_true(hint.is_showing(), "the hint is up before the progress.")
	hint.goal_state.take_key()
	hint.progressed()
	assert_false(hint.is_showing(), "progress makes it vanish at once.")
	await _wait(0.1)
	# The timer was already past the deadline when the key was taken. If it had
	# kept running it would fire again instantly, so staying quiet proves it
	# really did restart from zero.
	assert_false(hint.is_showing(), "and the timer restarts from zero.")


func test_the_hint_is_hidden_when_the_goal_is_complete() -> void:
	var hint := _hint()
	hint.hint_delay = 0.2
	hint.begin(_goal(), _robot(), [])
	for _key: int in 3:
		hint.goal_state.take_key()
		hint.progressed()
	await _wait(0.25)
	assert_false(hint.is_showing(), "with no keys left there is nothing to point at.")


# --- the trail -------------------------------------------------------------


func test_the_trail_runs_from_robo_to_the_nearest_key() -> void:
	var hint := _hint()
	var key := Key.new()
	key.position = Vector2(300, 400)
	add_child(key)
	var robot := _robot()
	hint.begin(_goal(), robot, [key])
	assert_eq(hint.target().position, key.position, "the trail aims at the key.")
	assert_eq(hint.origin(), robot.position, "and starts where Robo is.")


func test_the_trail_aims_at_the_nearest_of_several_keys() -> void:
	var hint := _hint()
	var far := Key.new()
	far.position = Vector2(600, 400)
	add_child(far)
	var near := Key.new()
	near.position = Vector2(160, 400)
	add_child(near)
	hint.begin(_goal(), _robot(), [far, near])
	assert_eq(hint.target().position, near.position, "nearest, not first in the list.")


func test_the_trail_aims_at_the_door_once_every_key_is_found() -> void:
	# The last hint must not point at a key that is already in the child's
	# pocket. When the goal is met, the answer is the door.
	var hint := _hint()
	var key := Key.new()
	key.position = Vector2(160, 400)
	add_child(key)
	var robot := _robot()
	hint.begin(_goal(), robot, [key])
	for _key: int in 3:
		hint.goal_state.take_key()
		hint.progressed()
	hint.door = Door.new()
	hint.door.position = Vector2(560, 400)
	add_child(hint.door)
	hint.progressed()
	hint.hint_delay = 0.0
	await _wait(0.05)
	assert_eq(hint.target(), hint.door, "with 3/3 the trail points home.")


func test_a_taken_key_is_never_the_target() -> void:
	var hint := _hint()
	var key := Key.new()
	key.position = Vector2(160, 400)
	add_child(key)
	var robot := _robot()
	hint.begin(_goal(), robot, [key])
	key.take()
	hint.progressed()
	assert_ne(hint.target(), key, "a key in the pocket is not a beacon.")


func test_the_trail_has_dots_between_the_two_points() -> void:
	var hint := _hint()
	hint.trail_points = 5
	assert_eq(
		hint.trail_points_for(Vector2.ZERO, Vector2(100, 0)).size(),
		5,
		"the trail is made of points, not a drawn line."
	)


func test_the_trail_is_deterministic() -> void:
	# The same start and end always produce the same trail, so a child sees a
	# stable path rather than a shimmering scribble.
	var hint := _hint()
	hint.trail_points = 6
	var a := hint.trail_points_for(Vector2(10, 20), Vector2(90, 140))
	var b := hint.trail_points_for(Vector2(10, 20), Vector2(90, 140))
	assert_eq(a, b, "the same line gives the same dots.")


func test_the_trail_fades_out_on_its_own() -> void:
	# A hint that never disappears becomes wallpaper. It is a temporary nudge.
	var hint := _hint()
	hint.hint_delay = 0.05
	hint.show_time = 0.15
	await _wait(0.35)
	assert_false(hint.is_showing(), "the trail has a life of its own.")


func test_after_fading_the_hint_waits_a_full_delay_before_returning() -> void:
	# Playtest finding: the trail faded after its show time and then blinked
	# straight back, because the stall timer had kept running past the deadline.
	# A fade must re-arm the clock, so a child who ignored the first nudge gets
	# a full quiet period before the second one.
	var hint := _hint()
	hint.hint_delay = 0.3
	hint.show_time = 0.5
	hint.begin(_goal(), _robot(), [_key()])
	# Show window [0.3, 0.8], quiet [0.8, 1.3], show again [1.3, 1.8]. Samples
	# sit well inside each window so frame jitter cannot flip an assertion.
	await _wait(0.4)
	assert_true(hint.is_showing(), "shown within the first delay.")
	await _wait(0.5)
	assert_false(hint.is_showing(), "then faded, and stays quiet...")
	await _wait(0.5)
	assert_true(hint.is_showing(), "...until a full delay has passed again.")


# --- robo pointing ---------------------------------------------------------


func test_robo_points_at_the_hint_target() -> void:
	var robot := _robot()
	var target := Node2D.new()
	target.position = Vector2(400, 400)
	add_child(target)
	robot.point_at(target)
	assert_ne(robot.facing, 0, "Robo turns toward it.")
	assert_true(robot.is_pointing(), "and holds the pose.")
	assert_gt(robot.point_hold_left, 0.0, "for a while.")


func test_robo_points_left_when_the_target_is_behind_him() -> void:
	var robot := _robot()
	var target := Node2D.new()
	target.position = Vector2(-300, 400)
	add_child(target)
	robot.point_at(target)
	assert_eq(robot.facing, -1, "he turns the other way.")


func test_pointing_never_moves_robo() -> void:
	# A hint must not interfere with play. Robo still falls, walks and jumps
	# exactly as he would without the hint, so the test compares him against a
	# control Robo that is never pointed at anything.
	var target := Node2D.new()
	target.position = Vector2(400, 400)
	add_child(target)
	var pointed := _robot()
	var control := _robot()
	for _frame: int in 10:
		await get_tree().physics_frame
		pointed.point_at(target)
	assert_eq(pointed.position, control.position, "same path, same speed.")
	assert_eq(pointed.velocity, control.velocity, "and identical velocity.")


func test_robo_stops_pointing_when_the_hint_goes_away() -> void:
	var robot := _robot()
	var target := Node2D.new()
	target.position = Vector2(400, 400)
	add_child(target)
	robot.point_at(target)
	assert_true(robot.is_pointing(), "pointing.")
	robot.stop_pointing()
	assert_false(robot.is_pointing(), "then he goes back to walking.")


func test_walking_cancels_the_point() -> void:
	# A child who starts walking again has understood the hint; keeping the
	# pose would fight their input.
	var robot := _robot()
	var target := Node2D.new()
	target.position = Vector2(400, 400)
	add_child(target)
	robot.point_at(target)
	robot.update_animation(0.016, true, true)
	assert_false(robot.is_pointing(), "walking takes over.")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
