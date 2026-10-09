class_name KeyCounter
extends CanvasLayer
## The key badge: "how many of the three keys do I have".
##
## Deliberately not a fraction. A 4-year-old cannot yet hold "2 of 3" in their
## head, and the badge is not telling them how many are left - the sparkle
## trail does that. This only answers "am I getting closer?", which is a
## number they can already understand.

const DIGIT_SIZE := Vector2(8, 12)  # the generated glyph canvas
const DIGIT_GAP := 8.0

## Area palette, set by the level before the counter enters the tree so the
## badge matches the area it is counting keys in.
var palette := "meadow"

var _icon: Sprite2D
var _count := 0
var _digit_pool: Array[Sprite2D] = []
var _bump_tween: Tween


func _ready() -> void:
	var panel := Control.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	_icon = Sprite2D.new()
	_icon.name = "Icon"
	_icon.texture = AssetFactory.get_texture("key", palette)
	_icon.scale = Vector2.ONE * Tuning.COUNTER_SCALE
	panel.add_child(_icon)
	_layout()


func count() -> int:
	return _count


## Monotonic and capped: keys are permanent, so this badge must never count
## down (which would imply loss) and never show more than the goal.
func set_count(value: int) -> void:
	var clamped := clampi(value, 0, AreaLayout.KEYS_PER_AREA)
	if clamped <= _count:
		return
	_count = clamped
	_layout()
	_bump()


func increment() -> void:
	set_count(_count + 1)


## Sprite2D is centred on its position, so the icon and the digits are both
## centred on one shared baseline. Getting this wrong is what once left the
## gem icon floating above its own number.
func _baseline() -> float:
	return Tuning.KEY_COUNTER_MARGIN.y + maxf(_icon_size(), _digit_size()) / 2.0


func _icon_size() -> float:
	return _icon.texture.get_height() * Tuning.COUNTER_SCALE


func _digit_size() -> float:
	return DIGIT_SIZE.y * Tuning.COUNTER_SCALE


func _layout() -> void:
	_icon.position = Vector2(
		Tuning.KEY_COUNTER_MARGIN.x + _icon_size() / 2.0, _baseline() - _icon_size() / 2.0
	)
	var x := Tuning.KEY_COUNTER_MARGIN.x + _icon_size() + DIGIT_GAP
	# Nothing collected yet means no number at all - just the key icon. A "0"
	# would read as a score the child had to keep up with.
	# The badge shows a NUMBER, not a tally: "2 keys" is one glyph reading 2,
	# never two glyphs reading 01.
	for index: int in 0 if _count == 0 else str(_count).length():
		var digit := _digit_sprite(index)
		digit.visible = true
		digit.texture = AssetFactory.get_texture("digit_%s" % str(_count)[index], palette)
		var width := digit.texture.get_width() * Tuning.COUNTER_SCALE
		digit.position = Vector2(x + width / 2.0, _baseline() - _digit_size() / 2.0)
		x += width + DIGIT_GAP
	# The pool only grows: the goal is 3, so no digit ever needs hiding again.


func _digit_sprite(index: int) -> Sprite2D:
	while _digit_pool.size() <= index:
		var digit := Sprite2D.new()
		digit.name = "Digit%d" % _digit_pool.size()
		digit.scale = Vector2.ONE * Tuning.COUNTER_SCALE
		(_panel() as Control).add_child(digit)
		_digit_pool.append(digit)
	return _digit_pool[index]


func _panel() -> Control:
	return find_child("Panel", true, false) as Control


## A squash-pulse on every new key, matching the gem counter's rhythm so the
## two badges feel like one panel rather than two competing widgets.
func _bump() -> void:
	if _bump_tween != null and _bump_tween.is_valid():
		_bump_tween.kill()
	var panel := _panel()
	panel.scale = Vector2(1.3, 0.7)
	_bump_tween = create_tween()
	_bump_tween.tween_property(panel, "scale", Vector2.ONE, Tuning.KEY_BUMP_TIME)
