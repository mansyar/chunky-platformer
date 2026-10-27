extends GdToolsTest
## Tests for the gift machine (gem_shop_20261027 Phase 2).
##
## One machine per area dispenses tiered surprise cosmetics cheapest-first,
## wiggles kindly + hints at gems on an empty wallet, and celebrates free
## after the set is complete. Robo-facing behavior (wear, tap-to-cycle) is
## covered here too, since the machine owns the dispense moment.


func _wallet_with(gems: int) -> Wallet:
	var wallet := Wallet.new()
	if gems > 0:
		wallet.add(gems)
	return wallet


func _machine(banked: int, area: String = "meadow") -> GiftMachine:
	var machine := GiftMachine.new()
	machine.palette = area
	machine.wallet = _wallet_with(banked)
	machine.wardrobe = Wardrobe.new()
	add_child(machine)
	return machine


func _gem_at(pos: Vector2, collected: bool = false) -> Gem:
	var gem := Gem.new()
	gem.position = pos
	if collected:
		gem.start_collected()
	add_child(gem)
	return gem


func _layout_named(area_name: String) -> AreaLayout:
	for layout: AreaLayout in AreaLayout.all():
		if layout.area_name == area_name:
			return layout
	return null


func _area(area_name: String, banked: int = 0) -> AreaBuilder:
	var layout := _layout_named(area_name)
	var builder := AreaBuilder.new()
	add_child(builder)
	builder.build(layout, _wallet_with(banked), [], Wardrobe.new())
	return builder


func _pop_count(parent: Node) -> int:
	var found := 0
	for child: Node in parent.get_children():
		if child is PopEffect:
			found += 1
	return found


func _has_words(node: Node) -> bool:
	if node is Label or node is Label3D or node is RichTextLabel:
		return true
	for child: Node in node.get_children():
		if _has_words(child):
			return true
	return false


func _machine_count(builder: AreaBuilder) -> int:
	var found := 0
	var stack: Array[Node] = [builder]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is GiftMachine:
			found += 1
		stack.append_array(node.get_children())
	return found


func _rest(machine: GiftMachine) -> void:
	machine._process(Tuning.MACHINE_DISPENSE_TIME + 0.05)


func test_machine_builds_sprite_sensor_and_price_tag() -> void:
	var machine := _machine(5)
	var sprite := machine.find_child("Sprite", true, false) as Sprite2D
	assert_not_null(sprite, "the machine builds a sprite.")
	assert_eq(
		sprite.texture, AssetFactory.get_texture("gift_machine", "meadow"), "it wears machine art."
	)
	var sensor := machine.find_child("TapZone", true, false) as CollisionShape2D
	assert_not_null(sensor, "the machine builds a tap zone.")
	assert_eq(
		(sensor.shape as CircleShape2D).radius,
		Tuning.MACHINE_TAP_RADIUS,
		"the tap zone is tuned in one place."
	)
	var tag := machine.find_child("PriceTag", true, false) as MachineTag
	assert_not_null(tag, "the machine builds a price sticker.")
	assert_eq(tag.price(), 1, "an empty wardrobe stickers the tier-1 price.")


func test_tap_zones_clear_the_touch_minimum() -> void:
	var machine := _machine(0)
	var sensor := machine.find_child("TapZone", true, false) as CollisionShape2D
	var radius := (sensor.shape as CircleShape2D).radius
	var screen_px := 2.0 * radius * AreaBuilder.CAMERA_ZOOM
	assert_true(
		screen_px >= Tuning.MACHINE_TOUCH_MIN,
		"machine tap target is %.0f screen px (>= 64)." % screen_px
	)
	var builder := _area("meadow")
	var robo_shape := builder.robot.find_child("Shape", true, false)
	# Robo's own collider is the tap-Robo target; both ways must clear 64px.
	if robo_shape == null:
		for child: Node in builder.robot.get_children():
			if child is CollisionShape2D:
				robo_shape = child
	var rect := (robo_shape as CollisionShape2D).shape as RectangleShape2D
	var robo_px := minf(rect.size.x, rect.size.y) * AreaBuilder.CAMERA_ZOOM
	assert_true(robo_px >= Tuning.MACHINE_TOUCH_MIN, "Robo tap target clears 64px.")


func test_machine_uses_no_words() -> void:
	var machine := _machine(3)
	assert_false(_has_words(machine), "numerals + pips only: no text nodes anywhere.")


func test_each_area_gets_one_wired_machine() -> void:
	for area_name: String in ["meadow", "cave", "sunset"]:
		var builder := _area(area_name)
		assert_eq(_machine_count(builder), 1, "%s builds exactly one machine." % area_name)
		var machine := builder.machine
		assert_not_null(machine, "%s exposes its machine." % area_name)
		var layout := _layout_named(area_name)
		assert_eq(machine.position, layout.machine_at, "machine sits on its layout spot.")
		assert_eq(machine.palette, area_name, "machine wears its area palette.")
		assert_eq(machine.wallet, builder.wallet, "machine shares the session wallet.")
		assert_eq(machine.wardrobe, builder.wardrobe, "machine shares the session wardrobe.")
		assert_eq(
			machine.hint_targets.size(),
			AreaLayout.GEMS_PER_AREA,
			"the hint sparkle knows every gem in the area."
		)


func test_dispense_deducts_wears_and_pops_confetti() -> void:
	var machine := _machine(5)
	var gifted: Array = []
	machine.dispensed.connect(func(gift_id: String) -> void: gifted.append(gift_id))
	var before := _pop_count(machine.get_parent())
	assert_eq(machine.use(), GiftMachine.UseResult.DISPENSED, "a banked tap dispenses.")
	assert_eq(machine.wallet.balance(), 4, "exactly the tier-1 price leaves the wallet.")
	assert_eq(gifted, [Cosmetics.HAT_SPROUT], "the cheapest gift dispenses first.")
	assert_true(machine.wardrobe.is_owned(Cosmetics.HAT_SPROUT), "the gift is owned at once.")
	assert_eq(machine.wardrobe.worn(), Cosmetics.HAT_SPROUT, "the gift is worn at once.")
	assert_true(machine.is_busy(), "the pop serializes rapid taps.")
	assert_true(_pop_count(machine.get_parent()) > before, "the dispense pops confetti.")


func test_surprise_order_is_cheapest_first() -> void:
	var machine := _machine(12)
	var expected := [
		Cosmetics.HAT_SPROUT,
		Cosmetics.HAT_STAR,
		Cosmetics.HAT_CROWN,
		Cosmetics.TRAIL_BUBBLES,
		Cosmetics.TRAIL_SPARKLE,
		Cosmetics.COLOR_SUNNY,
	]
	var expected_prices := [1, 1, 2, 2, 3, 3]
	var paid := 0
	for i: int in range(expected.size()):
		assert_eq(machine.next_gift_id(), expected[i], "gift %d is '%s'." % [i, expected[i]])
		var want_price: int = expected_prices[i]
		assert_eq(machine.price_for_next(), want_price, "gift %d costs %d." % [i, want_price])
		assert_eq(machine.use(), GiftMachine.UseResult.DISPENSED, "gift %d dispenses." % i)
		paid += expected_prices[i]
		_rest(machine)
	assert_eq(machine.wallet.balance(), 12 - paid, "every tier deducted exactly once.")
	assert_eq(machine.wallet.balance(), 0, "the full set costs all 12 gems.")
	assert_eq(machine.wardrobe.owned().size(), 6, "no duplicates until the set is complete.")
	assert_true(machine.is_complete(), "six gifts complete the set.")
	assert_eq(machine.price_for_next(), 0, "the sticker reads 0 once the bonus is free.")


func test_price_three_deducts_exactly_three() -> void:
	var machine := _machine(3)
	for gift_id: String in Cosmetics.all_ids().slice(0, 5):
		assert_true(machine.wardrobe.own(gift_id), "'%s' pre-owned." % gift_id)
	machine.refresh_tag()
	assert_eq(machine.price_for_next(), 3, "only the tier-3 gift is left.")
	assert_eq(machine.use(), GiftMachine.UseResult.DISPENSED, "the last gift dispenses.")
	assert_eq(machine.wallet.balance(), 0, "exactly 3 gems left the wallet.")


func test_complete_set_means_free_bonus() -> void:
	var machine := _machine(5)
	for gift_id: String in Cosmetics.all_ids():
		machine.wardrobe.own(gift_id)
	machine.refresh_tag()
	var tag := machine.find_child("PriceTag", true, false) as MachineTag
	assert_eq(tag.price(), 0, "the sticker reads 0 once the set is complete.")
	assert_eq(tag.pip_count(), 0, "no pips once the bonus is free.")
	var celebrated := [false]
	machine.bonus.connect(func() -> void: celebrated[0] = true)
	var before := _pop_count(machine.get_parent())
	assert_eq(machine.use(), GiftMachine.UseResult.BONUS, "a complete tap celebrates.")
	assert_true(celebrated[0], "the bonus signals.")
	assert_eq(machine.wallet.balance(), 5, "the bonus is free: the wallet is untouched.")
	assert_eq(machine.wardrobe.owned().size(), 6, "the bonus grants no duplicate.")
	assert_true(_pop_count(machine.get_parent()) > before, "the bonus pops confetti.")
	assert_eq(machine.use(), GiftMachine.UseResult.BUSY, "celebrations serialize too.")


func test_empty_wallet_wiggles_and_hints_nearest_gem() -> void:
	var machine := _machine(0)
	var near := _gem_at(Vector2(100, 0))
	_gem_at(Vector2(40, 0), true)  # collected: the hint must skip it
	var far := _gem_at(Vector2(200, 0))
	var targets: Array[Node2D] = [near, far]
	machine.hint_targets = targets
	var wiggled := [false]
	var hinted: Array = []
	machine.wiggled.connect(func() -> void: wiggled[0] = true)
	machine.hinted.connect(func(target: Node2D) -> void: hinted.append(target))
	var before := _pop_count(machine.get_parent())
	assert_eq(machine.use(), GiftMachine.UseResult.WIGGLE, "an empty tap wiggles.")
	assert_true(wiggled[0], "the wiggle signals.")
	assert_true(machine.is_wiggling(), "the wiggle anim plays.")
	assert_eq(machine.wallet.balance(), 0, "a wiggle spends nothing.")
	assert_eq(hinted, [near], "the hint sparkles toward the nearest uncollected gem.")
	assert_true(_pop_count(machine.get_parent()) > before, "the hint sparkles.")
	machine._process(Tuning.MACHINE_WIGGLE_TIME)
	assert_false(machine.is_wiggling(), "the wiggle ends on its own.")
	var sprite := machine.find_child("Sprite", true, false) as Sprite2D
	assert_almost_eq(sprite.rotation, 0.0, 0.001, "Robo's friend stands straight again.")


func test_no_hint_when_nothing_is_left_to_collect() -> void:
	var machine := _machine(0)
	var spent: Array[Node2D] = [_gem_at(Vector2(60, 0), true), _gem_at(Vector2(-60, 0), true)]
	machine.hint_targets = spent
	var hinted := [false]
	machine.hinted.connect(func(_target: Node2D) -> void: hinted[0] = true)
	assert_eq(machine.use(), GiftMachine.UseResult.WIGGLE, "an empty tap still wiggles.")
	assert_false(hinted[0], "with no gems left there is nothing to hint at.")


func test_short_of_price_wiggles_without_spending() -> void:
	var machine := _machine(1)
	machine.wardrobe.own(Cosmetics.HAT_SPROUT)
	machine.wardrobe.own(Cosmetics.HAT_STAR)
	assert_eq(machine.price_for_next(), 2, "the next gift costs 2.")
	assert_eq(machine.use(), GiftMachine.UseResult.WIGGLE, "1 gem cannot buy a 2-gem gift.")
	assert_eq(machine.wallet.balance(), 1, "the wallet keeps its gem.")
	assert_false(machine.wardrobe.is_owned(Cosmetics.HAT_CROWN), "nothing dispenses on a wiggle.")


func test_rapid_taps_serialize_one_gift() -> void:
	var machine := _machine(5)
	assert_eq(machine.use(), GiftMachine.UseResult.DISPENSED, "first tap dispenses.")
	assert_eq(machine.use(), GiftMachine.UseResult.BUSY, "second tap waits its turn.")
	assert_eq(machine.wallet.balance(), 4, "only one gift was charged.")
	_rest(machine)
	assert_eq(machine.use(), GiftMachine.UseResult.DISPENSED, "the next gift follows the pop.")
	assert_eq(machine.wallet.balance(), 3, "each gift charges exactly once.")


func test_tap_inputs_use_the_machine() -> void:
	var clicked := _machine(5)
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	clicked._on_input_event(null, click, 0)
	assert_eq(clicked.wallet.balance(), 4, "a click dispenses.")
	var touched := _machine(5)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touched._on_input_event(null, touch, 0)
	assert_eq(touched.wallet.balance(), 4, "a touch dispenses.")


func test_price_tag_tracks_the_next_gift() -> void:
	var machine := _machine(12)
	var tag := machine.find_child("PriceTag", true, false) as MachineTag
	var seen: Array = []
	for i: int in range(6):
		seen.append(tag.price())
		machine.use()
		_rest(machine)
	assert_eq(seen, [1, 1, 2, 2, 3, 3], "the sticker follows the tiers down.")
	assert_eq(tag.price(), 0, "the sticker reads 0 once the set is complete.")
	var numeral := tag.find_child("Numeral", true, false) as Sprite2D
	assert_eq(
		numeral.texture, AssetFactory.get_texture("digit_0"), "the sticker shows a 0 numeral."
	)


func test_tap_robo_cycles_owned_looks() -> void:
	var builder := _area("meadow")
	var robo := builder.robot
	assert_eq(robo.tap(), "", "with no looks there is nothing to cycle.")
	builder.wardrobe.own(Cosmetics.HAT_SPROUT)
	assert_eq(robo.tap(), Cosmetics.HAT_SPROUT, "one look stays put.")
	builder.wardrobe.own(Cosmetics.HAT_STAR)
	assert_eq(robo.tap(), Cosmetics.HAT_SPROUT, "a tap cycles back to the first look.")
	assert_eq(robo.tap(), Cosmetics.HAT_STAR, "the next tap wears the second look.")
	assert_eq(builder.wardrobe.worn(), Cosmetics.HAT_STAR, "taps move the worn look.")


func test_robo_tap_input_cycles_looks() -> void:
	var builder := _area("meadow")
	builder.wardrobe.own(Cosmetics.HAT_SPROUT)
	builder.wardrobe.own(Cosmetics.HAT_STAR)
	var robo := builder.robot
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	robo._on_input_event(null, click, 0)
	assert_eq(robo.wardrobe.worn(), Cosmetics.HAT_SPROUT, "a tap on Robo cycles the look.")


func test_worn_looks_dress_robo() -> void:
	var builder := _area("meadow")
	var robo := builder.robot
	var hat := robo.find_child("Hat", true, false) as Sprite2D
	assert_not_null(hat, "Robo builds a hat slot.")
	assert_false(hat.visible, "no hat shows before the first gift.")
	builder.wardrobe.own(Cosmetics.HAT_CROWN)
	assert_true(hat.visible, "a hat gift shows its topper.")
	assert_eq(
		hat.texture, AssetFactory.get_texture(Cosmetics.HAT_CROWN), "the topper matches the gift."
	)
	builder.wardrobe.own(Cosmetics.TRAIL_BUBBLES)
	assert_false(hat.visible, "a trail look hides the topper.")
	assert_eq(robo._trail_id, Cosmetics.TRAIL_BUBBLES, "a trail look draws behind Robo.")
	builder.wardrobe.own(Cosmetics.COLOR_SUNNY)
	assert_eq(robo.modulate, Tuning.ROBO_SUNNY_TINT, "a color look tints Robo.")
	builder.wardrobe.wear(Cosmetics.HAT_CROWN)
	assert_true(hat.visible, "re-wearing a hat shows it again.")
	assert_eq(robo.modulate, Color.WHITE, "leaving the color look clears the tint.")


func test_machine_art_reads_as_a_present() -> void:
	var img := AssetFactory.get_texture("gift_machine", "meadow").get_image()
	assert_eq(img.get_pixel(0, 0).a, 0.0, "corners stay transparent.")
	var lid := img.get_pixel(16, 14)
	var body := img.get_pixel(16, 32)
	assert_true(lid.a > 0.5 and body.a > 0.5, "lid stripe and body are painted.")
	assert_false(lid.is_equal_approx(body), "the lid stripe contrasts the body.")
	for gift_id: String in Cosmetics.all_ids():
		if Cosmetics.kind_of(gift_id) != Cosmetics.KIND_HAT:
			continue
		var hat_img := AssetFactory.get_texture(gift_id).get_image()
		assert_eq(hat_img.get_pixel(0, 0).a, 0.0, "'%s' corners stay transparent." % gift_id)
		assert_true(hat_img.get_pixel(8, 8).a > 0.5, "'%s' paints its middle." % gift_id)


func test_game_carries_wardrobe_across_areas() -> void:
	var game: Node = load("res://src/levels/game.gd").new()
	add_child(game)
	assert_not_null(game.wardrobe, "the game owns the session wardrobe.")
	assert_eq(game.builder.wardrobe, game.wardrobe, "area 0 borrows the session wardrobe.")
	assert_not_null(game.builder.machine, "area 0 builds a machine.")
	game.wallet.add(5)
	assert_eq(game.builder.machine.use(), GiftMachine.UseResult.DISPENSED, "a gift dispenses.")
	assert_eq(game.wardrobe.worn(), Cosmetics.HAT_SPROUT, "the gift is worn.")
	game._build_area(1)
	assert_eq(game.builder.wardrobe, game.wardrobe, "area 1 borrows the same wardrobe.")
	assert_true(game.wardrobe.is_owned(Cosmetics.HAT_SPROUT), "gifts survive the area swap.")
	assert_eq(game.builder.machine.wardrobe, game.wardrobe, "area 1's machine is wired up.")
