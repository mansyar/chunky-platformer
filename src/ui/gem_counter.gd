class_name GemCounter
extends CanvasLayer
## Screen-space gem counter: gem icon + growing pixel-digit count, top-left.
##
## Digits are generated pixel glyphs (no fonts allowed), so the number stays
## perfectly on-theme at any resolution. The count only ever grows — there is
## no total and nothing to read beyond "more is better" (toddler rule).

var _count := 0
var _panel: Control
var _icon: Sprite2D
var _digit_pool: Array[Sprite2D] = []
var _bump_tween: Tween


func _ready() -> void:
	_panel = Control.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_icon = Sprite2D.new()
	_icon.name = "Icon"
	_icon.texture = AssetFactory.get_texture("gem", "meadow")
	_icon.scale = Vector2.ONE * Tuning.COUNTER_SCALE
	_icon.position = Tuning.COUNTER_MARGIN
	_panel.add_child(_icon)


func count() -> int:
	return _count


## Set the count. Monotonic by design: a smaller value is ignored so the
## number can never appear to shrink under a toddler's thumbs.
func set_count(value: int) -> void:
	if value <= _count:
		return
	_count = value
	_render_digits()


func increment() -> void:
	set_count(_count + 1)
	_bump()


func _bump() -> void:
	if _bump_tween:
		_bump_tween.kill()
	_panel.scale = Vector2.ONE
	_bump_tween = create_tween()
	_bump_tween.tween_property(_panel, "scale", Vector2(1.3, 0.7), Tuning.COUNTER_BUMP_TIME * 0.4)
	_bump_tween.tween_property(_panel, "scale", Vector2.ONE, Tuning.COUNTER_BUMP_TIME * 0.6)


## Lay out one pooled sprite per digit of the current count, hiding the rest.
## Sprite2D positions are centers, so each slot shifts by half its own size.
func _render_digits() -> void:
	var digits := str(_count)
	var icon_w := _icon.texture.get_width() * Tuning.COUNTER_SCALE
	var digit_w := 8.0 * Tuning.COUNTER_SCALE
	var digit_h := 12.0 * Tuning.COUNTER_SCALE
	for i: int in range(digits.length()):
		var sprite := _digit_sprite(i)
		sprite.texture = AssetFactory.get_texture("digit_%s" % digits[i])
		sprite.visible = true
		sprite.position = Vector2(
			Tuning.COUNTER_MARGIN.x + icon_w + 8.0 + i * digit_w + digit_w / 2.0,
			Tuning.COUNTER_MARGIN.y + digit_h / 2.0
		)
	for i: int in range(digits.length(), _digit_pool.size()):
		_digit_pool[i].visible = false


func _digit_sprite(index: int) -> Sprite2D:
	while _digit_pool.size() <= index:
		var sprite := Sprite2D.new()
		sprite.name = "Digit%d" % _digit_pool.size()
		sprite.scale = Vector2.ONE * Tuning.COUNTER_SCALE
		_panel.add_child(sprite)
		_digit_pool.append(sprite)
	return _digit_pool[index]
