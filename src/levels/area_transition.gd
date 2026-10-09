class_name AreaTransition
extends CanvasLayer
## A full-screen palette fade between areas.
##
## The veil sinks into the sky colour the child is leaving, the world swaps
## while the screen is covered, then the veil lifts out of the sky they are
## entering. Two areas with different palettes therefore fade *through* colour
## rather than through black - the world never disappears into nothing.
##
## step(delta) is explicit rather than driven by timers so the whole sequence
## is deterministic and unit-testable.

## Emitted exactly once, at the midpoint, when the screen is fully covered.
## This is the signal the game root swaps areas on.
signal faded_out

## Emitted when the veil has fully cleared.
signal finished

const VEIL_LAYER := 10  # above the world and both HUDs

var from_color := Color.WHITE
var to_color := Color.WHITE

## Negative means idle. Otherwise 0..1 across the whole fade.
var _progress := -1.0
var _swapped := false
var _veil: ColorRect


func _ready() -> void:
	layer = VEIL_LAYER
	_veil = ColorRect.new()
	_veil.name = "Veil"
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.visible = false
	add_child(_veil)


func is_running() -> bool:
	return _progress >= 0.0


func is_veil_visible() -> bool:
	return _veil.visible


func begin(from: Color, to: Color) -> void:
	from_color = from
	to_color = to
	_progress = 0.0
	_swapped = false
	_veil.visible = true
	_veil.color = Color(from, 0.0)


func step(delta: float) -> void:
	if not is_running():
		return
	_progress = minf(_progress + delta / Tuning.TRANSITION_TIME, 1.0)
	if _progress < 0.5:
		_veil.color = Color(from_color, _progress * 2.0)
	else:
		if not _swapped:
			_swapped = true
			faded_out.emit()
		var t := (_progress - 0.5) * 2.0
		_veil.color = Color(to_color, 1.0 - t)
	if _progress >= 1.0:
		_progress = -1.0
		_veil.visible = false
		finished.emit()
