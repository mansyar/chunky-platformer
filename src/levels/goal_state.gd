class_name GoalState
extends Node
## How far through an area's three keys a child is.
##
## The single source of truth for "can this area be finished". The door, the
## counter and the hint timer all read from here rather than from each other,
## so there is exactly one place where the goal can be wrong - and it is
## capped at the key count, because a duplicate signal must never hand out an
## unearned win.

## Emitted whenever the key tally rises, carrying the new total. The HUD, the
## door and the hint timer all listen here.
signal progress(keys_taken: int)

const KEYS_PER_AREA := AreaLayout.KEYS_PER_AREA

var _keys_taken := 0


func keys_taken() -> int:
	return _keys_taken


func keys_remaining() -> int:
	return maxi(KEYS_PER_AREA - _keys_taken, 0)


func is_complete() -> bool:
	return _keys_taken >= KEYS_PER_AREA


## The door is "locked" until the goal is met. Named from the door's point of
## view because that is how the rest of the game asks the question.
func is_locked() -> bool:
	return not is_complete()


func take_key() -> void:
	if _keys_taken >= KEYS_PER_AREA:
		return
	_keys_taken += 1
	progress.emit(_keys_taken)


## Used when a child loops back to an area they have already finished.
func reset() -> void:
	_keys_taken = 0
