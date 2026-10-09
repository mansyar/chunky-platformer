class_name Game
extends Node
## The game root: owns the area index and swaps levels behind a palette fade.
##
## The flow a child experiences: collect 3 keys, walk into the door, the screen
## sinks into the sky they are leaving, the next area builds while the screen
## is covered, and the veil lifts out of the new sky. Gems are a lifetime score
## and survive every swap. After the last area the game celebrates first, then
## loops home to the meadow.

## Emitted after the new area is live.
signal area_changed(index: int)

## Emitted when the final door is entered, before the loop home begins.
signal celebrated

var area_index := 0
var builder: AreaBuilder
var transition: AreaTransition

## Lifetime gem total, carried across every swap.
var _gem_total := 0


func _ready() -> void:
	transition = AreaTransition.new()
	transition.name = "Transition"
	add_child(transition)
	transition.faded_out.connect(_swap_area)
	_build_area(0)


func _process(delta: float) -> void:
	if transition.is_running():
		transition.step(delta)


func _build_area(index: int) -> void:
	if builder != null:
		_gem_total = builder.counter.count()
		builder.queue_free()
	area_index = index
	builder = AreaBuilder.new()
	builder.name = "Area"
	add_child(builder)
	builder.build(AreaLayout.all()[index])
	builder.door.entered.connect(_on_door_entered)
	# A fresh counter starts at zero, so the lifetime total slots straight in.
	builder.counter.set_count(_gem_total)
	area_changed.emit(index)


func _swap_area() -> void:
	_build_area((_area_count() + area_index + 1) % _area_count())


func _area_count() -> int:
	return AreaLayout.all().size()


func _on_door_entered(_door: Door) -> void:
	# The open door's sensor keeps overlapping Robo for a few frames after the
	# first entry; a second bump during the fade must not queue a second swap.
	if transition.is_running():
		return
	if area_index == _area_count() - 1:
		celebrated.emit()
		builder.robot.celebrate()
	transition.begin(_sky_of(area_index), _sky_of((_area_count() + area_index + 1) % _area_count()))


func _sky_of(index: int) -> Color:
	return Palettes.AREA_PALETTES[AreaLayout.all()[index].palette]["sky_top"]
