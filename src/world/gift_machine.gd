class_name GiftMachine
extends Area2D
## The friendly gift machine: one per area, tap to turn banked gems into a
## surprise cosmetic. Code-assembled per the Foundation pattern.
##
## - Gems banked: deduct exactly the cheapest-unowned price, dispense with a
##   pop + confetti, and auto-wear immediately. Own-then-wear is a single
##   atomic step, so an area change mid-celebration can never lose the gift.
## - Empty wallet (or short of the next price): a kind wiggle plus a hint
##   sparkle toward the nearest uncollected gem. Never scolds, never locks,
##   never shows words.
## - Set complete: a free bonus celebration instead of an item — the machine
##   stays friendly forever, never a dead end.
## - Rapid taps serialize one dispense at a time; the wallet never negatives.

## Emitted after a gift is owned + worn, carrying the cosmetic id.
signal dispensed(cosmetic_id: String)
## Emitted when the complete set earns its free bonus celebration.
signal bonus
## Emitted on an empty-wallet tap once the wiggle starts.
signal wiggled
## Emitted with the gem the hint sparkle points at (only when one is left).
signal hinted(target: Node2D)

enum UseResult { DISPENSED, BONUS, WIGGLE, BUSY }

## Area palette, set by the level before the machine enters the tree.
var palette := "meadow"
## Session wallet, shared with the builder (never owned here).
var wallet: Wallet
## Session wardrobe, shared with the builder (never owned here).
var wardrobe: Wardrobe

## Live world nodes the empty-wallet hint may point at (the area gems).
var hint_targets: Array[Node2D] = []

var _busy_left := 0.0
var _wiggle_left := 0.0
var _sprite: Sprite2D
var _tag: MachineTag


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetFactory.get_texture("gift_machine", palette)
	add_child(_sprite)

	var sensor := CollisionShape2D.new()
	sensor.name = "TapZone"
	var circle := CircleShape2D.new()
	circle.radius = Tuning.MACHINE_TAP_RADIUS
	sensor.shape = circle
	add_child(sensor)

	_tag = MachineTag.new()
	_tag.name = "PriceTag"
	_tag.palette = palette
	_tag.position = Vector2(0.0, -44.0)
	add_child(_tag)
	refresh_tag()

	input_event.connect(_on_input_event)


## The sticker price: cheapest-unowned gift, or 0 once the set is complete
## (the bonus celebration is free).
func price_for_next() -> int:
	if wardrobe == null:
		return Tuning.GIFT_TIER_1
	var gift_price := wardrobe.next_price()
	return gift_price if gift_price >= 0 else 0


## The gift the next paid use would dispense ("" when the set is complete).
func next_gift_id() -> String:
	if wardrobe == null:
		return ""
	return wardrobe.next_unowned()


func is_complete() -> bool:
	return wardrobe != null and wardrobe.is_complete()


func is_busy() -> bool:
	return _busy_left > 0.0


func is_wiggling() -> bool:
	return _wiggle_left > 0.0


## Re-read the sticker after the wardrobe changes.
func refresh_tag() -> void:
	if _tag != null:
		_tag.set_price(price_for_next())


## Tap the machine: dispense, celebrate the free bonus, wiggle kindly, or
## stay busy while the last pop is still playing.
func use() -> int:
	if _busy_left > 0.0:
		return UseResult.BUSY
	if wardrobe == null or wardrobe.is_complete():
		_do_bonus()
		return UseResult.BONUS
	var gift_id := wardrobe.next_unowned()
	var cost := wardrobe.next_price()
	if wallet == null or wallet.balance() < cost:
		_do_wiggle()
		return UseResult.WIGGLE
	if not wallet.spend(cost):
		_do_wiggle()
		return UseResult.WIGGLE
	wardrobe.own(gift_id)
	_busy_left = Tuning.MACHINE_DISPENSE_TIME
	if is_inside_tree():
		PopEffect.spawn(get_parent(), global_position + Vector2(0.0, -32.0), _accent())
	dispensed.emit(gift_id)
	refresh_tag()
	return UseResult.DISPENSED


func _process(delta: float) -> void:
	if _busy_left > 0.0:
		_busy_left = maxf(_busy_left - delta, 0.0)
		_tick_pop()
	elif _sprite != null:
		_sprite.scale = Vector2.ONE
	if _wiggle_left > 0.0:
		_wiggle_left = maxf(_wiggle_left - delta, 0.0)
		if _sprite != null:
			var k := _wiggle_left / Tuning.MACHINE_WIGGLE_TIME
			_sprite.rotation = sin(_wiggle_left * 30.0) * Tuning.MACHINE_WIGGLE_TILT * k
			if _wiggle_left <= 0.0:
				_sprite.rotation = 0.0


## Dispense squash-and-return on the sprite while the pop is live.
func _tick_pop() -> void:
	if _sprite == null:
		return
	var progress := 1.0 - _busy_left / Tuning.MACHINE_DISPENSE_TIME
	_sprite.scale = Vector2.ONE * (1.0 + 0.25 * sin(PI * clampf(progress, 0.0, 1.0)))


func _do_bonus() -> void:
	_busy_left = Tuning.MACHINE_DISPENSE_TIME
	if is_inside_tree():
		PopEffect.spawn(get_parent(), global_position + Vector2(0.0, -32.0), _accent())
		PopEffect.spawn(get_parent(), global_position + Vector2(0.0, -16.0), Color.WHITE)
	bonus.emit()


func _do_wiggle() -> void:
	_wiggle_left = Tuning.MACHINE_WIGGLE_TIME
	wiggled.emit()
	var target := nearest_hint_gem()
	if target != null and is_inside_tree():
		# World parents sit at the origin, so global == local there; a
		# non-Node2D test parent just takes the global position as-is.
		var sparkle_at := target.global_position
		var home := get_parent() as Node2D
		if home != null:
			sparkle_at = home.to_local(target.global_position)
		PopEffect.spawn(get_parent(), sparkle_at, _accent())
		hinted.emit(target)


## Nearest uncollected gem, or null when nothing is left to point at.
func nearest_hint_gem() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for target: Node2D in hint_targets:
		if target == null or not is_instance_valid(target):
			continue
		var gem := target as Gem
		if gem != null and gem.is_collected():
			continue
		var d := global_position.distance_squared_to(target.global_position)
		if d < best_d:
			best_d = d
			best = target
	return best


func _accent() -> Color:
	return Palettes.AREA_PALETTES[palette]["accent"]


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var press := event as InputEventMouseButton
		if press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
			use()
	elif event is InputEventScreenTouch:
		if (event as InputEventScreenTouch).pressed:
			use()
