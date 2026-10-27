class_name WalletHud
extends CanvasLayer
## Screen-space wallet badge: gem icon + big pixel-digit balance, top-left.
##
## Numerals + icons only (no words). Digits reuse the generated pixel glyph
## art (no font files). The badge mirrors the wallet balance and updates via
## the wallet's changed signal, so collecting or spending is instantly visible.

## Generated glyph canvas, mirroring the digit_* asset spec (8x12).
const DIGIT_SIZE := Vector2(8.0, 12.0)
const DIGIT_GAP := 8.0

## Area palette, set by the level before the badge enters the tree so the
## HUD icon matches the gems it is counting.
var palette := "meadow"

var _wallet: Wallet
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
	_icon.texture = AssetFactory.get_texture("gem", palette)
	_icon.scale = Vector2.ONE * Tuning.COUNTER_SCALE
	_icon.position = Vector2(
		Tuning.COUNTER_MARGIN.x + _icon_size().x / 2.0,
		Tuning.COUNTER_MARGIN.y + _baseline() - _icon_size().y / 2.0
	)
	_panel.add_child(_icon)
	if _wallet != null:
		_render_digits()


## Bind a wallet. The badge shows its balance now and on every change.
func bind(wallet: Wallet) -> void:
	if _wallet != null and _wallet.changed.is_connected(_on_wallet_changed):
		_wallet.changed.disconnect(_on_wallet_changed)
	_wallet = wallet
	if _wallet != null:
		_wallet.changed.connect(_on_wallet_changed)
		if is_node_ready():
			_render_digits()


func balance() -> int:
	if _wallet == null:
		return 0
	return _wallet.balance()


func _on_wallet_changed(_new_balance: int) -> void:
	_render_digits()
	_bump()


func _bump() -> void:
	if not is_node_ready():
		return
	if _bump_tween != null and _bump_tween.is_valid():
		_bump_tween.kill()
	_panel.scale = Vector2.ONE
	_bump_tween = create_tween()
	_bump_tween.tween_property(_panel, "scale", Vector2(1.3, 0.7), Tuning.COUNTER_BUMP_TIME * 0.4)
	_bump_tween.tween_property(_panel, "scale", Vector2.ONE, Tuning.COUNTER_BUMP_TIME * 0.6)


## Shared bottom edge for the icon and the digits: the tallest element (the
## 16px gem) defines it, so the shorter 12px digits sit on the same line.
func _baseline() -> float:
	return maxf(_icon_size().y, DIGIT_SIZE.y * Tuning.COUNTER_SCALE)


func _icon_size() -> Vector2:
	var texture := AssetFactory.get_texture("gem", palette)
	return Vector2(texture.get_width(), texture.get_height()) * Tuning.COUNTER_SCALE


## Lay out one pooled sprite per digit of the current balance, hiding the rest.
## Sprite2D positions are centers, so each slot shifts by half its own size.
func _render_digits() -> void:
	if _panel == null or _icon == null:
		return
	var digits := str(balance())
	var icon_w := _icon_size().x
	var digit_w := DIGIT_SIZE.x * Tuning.COUNTER_SCALE
	var digit_h := DIGIT_SIZE.y * Tuning.COUNTER_SCALE
	for i: int in range(digits.length()):
		var sprite := _digit_sprite(i)
		sprite.texture = AssetFactory.get_texture("digit_%s" % digits[i])
		sprite.visible = true
		sprite.position = Vector2(
			Tuning.COUNTER_MARGIN.x + icon_w + DIGIT_GAP + i * digit_w + digit_w / 2.0,
			Tuning.COUNTER_MARGIN.y + _baseline() - digit_h / 2.0
		)
	for j: int in range(digits.length(), _digit_pool.size()):
		_digit_pool[j].visible = false


func _digit_sprite(index: int) -> Sprite2D:
	while _digit_pool.size() <= index:
		var sprite := Sprite2D.new()
		sprite.name = "Digit%d" % _digit_pool.size()
		sprite.scale = Vector2.ONE * Tuning.COUNTER_SCALE
		_panel.add_child(sprite)
		_digit_pool.append(sprite)
	return _digit_pool[index]
