class_name HintSystem
extends Node2D
## Shows a child where to go next, but only when they have genuinely stalled.
##
## A 4-year-old will wander, get distracted, or simply forget what they were
## doing. After hint_delay seconds with no key progress, a trail of sparkles
## appears from Robo to the next key and Robo turns and points at it. Progress
## buys silence immediately.
##
## Two rules make this a safety net rather than a nag:
##   1. It never fires while the child is making progress.
##   2. It fades away on its own, so it is a nudge, not wallpaper.
##
## The trail is pure, deterministic maths over two points - the same start and
## end always give the same dots, so the path does not shimmer.

## Emitted when the hint appears and when it goes away. Phase 5's transition
## listens so it can clear a trail across an area change.
signal shown(target: Node2D)
signal dismissed

const DEFAULT_TRAIL_POINTS := 8
const DOT_RADIUS := 2.0

## Seconds of no key progress before the hint appears. Overridable per test.
var hint_delay := Tuning.HINT_DELAY

## Seconds the trail stays up before fading. Short by design.
var show_time := Tuning.HINT_SHOW_TIME

## Dots along the line from Robo to the target.
var trail_points := DEFAULT_TRAIL_POINTS

## Property rather than a bare field so appearing and disappearing both fire
## their signal exactly once, and so _process can set it without a setter loop.
var showing := false:
	set(value):
		if value == showing:
			return
		showing = value
		_age = 0.0
		if showing:
			shown.emit(_target)
		else:
			dismissed.emit()
			if _robot != null:
				_robot.stop_pointing()

var door: Door
var goal_state: GoalState

var _robot: Robot
var _keys: Array[Key] = []
var _target: Node2D
var _timer := 0.0
var _age := 0.0


## Wire the hint to an area. `keys` is the area's live key list, not a copy:
## a child taking a key must change what the hint points at immediately.
func begin(state: GoalState, robot: Robot, keys: Array[Key]) -> void:
	goal_state = state
	_robot = robot
	_keys = keys
	_timer = 0.0
	showing = false
	# Resolve the target immediately: a caller may ask what the hint would point
	# at on the same frame it wired the area up.
	recount()


## Called whenever a key is taken. Resets the silence timer and clears the
## trail - a child who is doing the right thing is never nagged.
func progressed() -> void:
	_timer = 0.0
	showing = false
	recount()


func is_showing() -> bool:
	return showing


## Where the trail currently starts: Robo's feet, so the dots read as coming
## from him rather than floating at his middle.
func origin() -> Vector2:
	return _robot.position if _robot != null else Vector2.ZERO


## What the trail points at: the door once the goal is met, otherwise the
## nearest key still to be found. Null only if there is genuinely nothing left.
func target() -> Node2D:
	return _target


func _process(delta: float) -> void:
	_timer += delta
	if not showing and _timer >= hint_delay:
		recount()
		showing = _target != null
	if showing:
		_age += delta
		queue_redraw()
		if _age >= show_time:
			showing = false
			# Re-arm the clock. Without this, the timer - still past the
			# deadline - would re-show the trail on the very next frame and the
			# hint would blink forever instead of resting between nudges.
			_timer = 0.0


func _exit_tree() -> void:
	if showing:
		showing = false


## Re-pick the target. A test may take a key and immediately ask what the hint
## would point at, without waiting a frame for _process.
func recount() -> void:
	if goal_state != null and goal_state.is_complete():
		_target = door
		return
	var nearest: Key = null
	var best := INF
	for key: Key in _keys:
		if key.is_taken():
			continue
		var distance := origin().distance_squared_to(key.position)
		if distance < best:
			best = distance
			nearest = key
	_target = nearest


## Pure and deterministic: `count` evenly spaced points from `from` to `to`.
## Testable without a scene, which is why the trail is not a drawn polyline.
static func trail_positions(from: Vector2, to: Vector2, count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if count <= 0:
		return points
	for step: int in count:
		points.append(from.lerp(to, float(step) / float(count)))
	return points


func trail_points_for(from: Vector2, to: Vector2) -> Array[Vector2]:
	return trail_positions(from, to, trail_points)


func _draw() -> void:
	if not showing or _target == null:
		return
	# Fade the whole trail together so it dissolves rather than blinking off.
	var fade := clampf(1.0 - _age / show_time, 0.0, 1.0)
	var color := _sparkle_color()
	color.a = fade
	for point: Vector2 in trail_points_for(origin(), _target.position):
		draw_circle(point, DOT_RADIUS, color)


func _sparkle_color() -> Color:
	# Warm gold either way: gold for a key, near-white for the door, so the
	# child learns "shiny dots mean go there" without reading anything.
	return Tuning.HINT_SPARKLE if _target is Key else Color(1.0, 0.95, 0.7)
