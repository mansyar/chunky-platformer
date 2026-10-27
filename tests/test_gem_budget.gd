extends GdToolsTest
## Tests for the fixed gem budget (Phase 1, FR-1 / AC-1 / AC-2).
##
## Every area holds exactly AreaLayout.GEMS_PER_AREA hand-placed gems with no
## respawn; collected gems stay collected on revisit within the session, and
## the wallet HUD mirrors the wallet balance as big numerals + gem icon.

const BUILDER_SCRIPT := "res://src/levels/area_builder.gd"
const GAME_SCRIPT := "res://src/levels/game.gd"


func _built(layout: AreaLayout, wallet: Wallet, taken: Array[bool] = []) -> AreaBuilder:
	var builder: AreaBuilder = load(BUILDER_SCRIPT).new()
	add_child(builder)
	builder.build(layout, wallet, taken)
	return builder


func _visible_digits(hud: WalletHud) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var icon := hud.find_child("Icon", true, false)
	for node: Node in hud.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite != icon and sprite.visible:
			out.append(sprite)
	return out


# --- fixed budget ------------------------------------------------------------


func test_every_area_holds_exactly_the_budget() -> void:
	for layout: AreaLayout in AreaLayout.all():
		assert_eq(
			layout.gem_spots.size(),
			AreaLayout.GEMS_PER_AREA,
			"the %s area holds the full budget." % layout.area_name
		)


func test_every_area_budget_validates() -> void:
	for layout: AreaLayout in AreaLayout.all():
		assert_eq(layout.validate().size(), 0, "the %s layout is playable." % layout.area_name)


func test_builder_spawns_one_gem_per_budget_spot() -> void:
	for layout: AreaLayout in AreaLayout.all():
		var builder := _built(layout, Wallet.new())
		assert_eq(
			builder.find_children("*", "Gem", true, false).size(),
			AreaLayout.GEMS_PER_AREA,
			"one gem per budget spot in %s." % layout.area_name
		)


func test_wallet_hud_is_bound_and_top_left() -> void:
	var wallet := Wallet.new()
	var builder := _built(AreaLayout.meadow(), wallet)
	var hud := builder.wallet_hud
	assert_not_null(hud, "the builder shows the wallet badge.")
	assert_eq(hud.balance(), 0, "a fresh wallet shows zero.")
	wallet.add(3)
	assert_eq(hud.balance(), 3, "the badge mirrors the wallet.")
	var icon := hud.find_child("Icon", true, false) as Sprite2D
	assert_not_null(icon, "the badge shows the gem icon.")
	assert_lt(icon.global_position.x, 200.0, "icon sits near the left edge.")
	assert_lt(icon.global_position.y, 140.0, "icon sits near the top edge.")
	wallet.add(9)
	assert_eq(_visible_digits(hud).size(), 2, "12 is two digits.")


# --- no respawn, stays collected ---------------------------------------------


func test_collected_gem_never_respawns() -> void:
	var wallet := Wallet.new()
	var builder := _built(AreaLayout.meadow(), wallet)
	var gem := builder.find_children("*", "Gem", true, false)[0] as Gem
	gem.collect()
	assert_true(gem.is_collected(), "the gem is collected.")
	await get_tree().create_timer(0.3).timeout
	assert_true(gem.is_collected(), "the gem stays hidden: no timed respawn.")
	assert_eq(wallet.balance(), 1, "exactly one gem reached the wallet.")


func test_collecting_three_shows_three() -> void:
	# AC-2: collecting 3 gems shows numeral "3" with the gem icon.
	var wallet := Wallet.new()
	var builder := _built(AreaLayout.meadow(), wallet)
	var gems := builder.find_children("*", "Gem", true, false)
	for i: int in range(3):
		(gems[i] as Gem).collect()
	assert_eq(wallet.balance(), 3, "the wallet holds three gems.")
	assert_eq(builder.counter.count(), 3, "the legacy counter agrees.")
	assert_eq(builder.wallet_hud.balance(), 3, "the badge reads 3 with the gem icon.")


func test_leaving_and_returning_restores_zero_gems() -> void:
	# AC-1: collect everything, leave, return -> zero restored.
	# Phase 3 persists to disk: a Game boot must start from a clean slate.
	SaveGame.clear()
	var game: Game = load(GAME_SCRIPT).new()
	add_child(game)
	var first := game.builder
	var gems := first.find_children("*", "Gem", true, false)
	for gem: Node in gems:
		(gem as Gem).collect()
	assert_eq(game.wallet.balance(), AreaLayout.GEMS_PER_AREA, "every gem banked.")
	var budget := AreaLayout.GEMS_PER_AREA
	# Walk through the door to the next area and back to the meadow.
	for _i: int in range(AreaLayout.all().size()):
		for _k: int in AreaLayout.KEYS_PER_AREA:
			game.builder.goal_state.take_key()
		game.builder.door.entered.emit(game.builder.door)
		game.transition.step(Tuning.TRANSITION_TIME)
	assert_eq(game.area_index, 0, "back home in the meadow.")
	var home := game.builder.find_children("*", "Gem", true, false)
	var restored := 0
	for gem: Node in home:
		if not (gem as Gem).is_collected():
			restored += 1
	assert_eq(restored, 0, "zero gems restored on revisit.")
	assert_eq(game.wallet.balance(), budget, "the wallet kept the session total (%d)." % budget)


func test_balance_survives_rebuilds_within_the_session() -> void:
	# AC-2: quitting to title (same session) keeps the balance — modelled as
	# a rebuild carrying the same wallet.
	var wallet := Wallet.new()
	wallet.add(3)
	var again := _built(AreaLayout.meadow(), wallet, [])
	assert_eq(again.wallet_hud.balance(), 3, "the rebuilt badge still reads 3.")
