class_name MachineTag
extends Node2D
## Price sticker floating above the gift machine: one big numeral plus one
## gem pip per gem of price. Numerals + icons only — no words, no Label nodes
## anywhere — so a number-learning 4-year-old reads it at a glance. Purely
## visual: the machine owns the pricing logic, this node only shows it.

const DIGIT_SCALE := 2.0
const PIP_SCALE := 0.5
const PIP_STEP := 10.0
const PIP_ROW_Y := 18.0
const MAX_PIPS := 3

## Area palette, set by the machine before this node enters the tree so the
## pips match the gems they are counting.
var palette := "meadow"

var _price := 1
var _digit: Sprite2D
var _pips: Array[Sprite2D] = []


func _ready() -> void:
	_digit = Sprite2D.new()
	_digit.name = "Numeral"
	_digit.scale = Vector2.ONE * DIGIT_SCALE
	add_child(_digit)
	_render()


## Show a new price. Zero means the set is complete and the bonus is free.
func set_price(value: int) -> void:
	_price = clampi(value, 0, MAX_PIPS)
	if is_node_ready():
		_render()


func price() -> int:
	return _price


## How many gem pips are currently visible (always equals the price).
func pip_count() -> int:
	var shown := 0
	for pip: Sprite2D in _pips:
		if pip.visible:
			shown += 1
	return shown


func _render() -> void:
	if _digit == null:
		return
	_digit.texture = AssetFactory.get_texture("digit_%d" % _price)
	while _pips.size() < MAX_PIPS:
		var pip := Sprite2D.new()
		pip.name = "Pip%d" % _pips.size()
		pip.texture = AssetFactory.get_texture("gem", palette)
		pip.scale = Vector2.ONE * PIP_SCALE
		add_child(pip)
		_pips.append(pip)
	for i: int in range(_pips.size()):
		var pip: Sprite2D = _pips[i]
		pip.visible = i < _price
		pip.position = Vector2((float(i) - float(_price - 1) / 2.0) * PIP_STEP, PIP_ROW_Y)
