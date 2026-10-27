extends GdToolsTest
## Collect-flow, now in wallet terms: gathering gems feeds the session
## wallet, and WalletHud (the sole top-left badge) shows the balance.

const LEVEL_SCENE := "res://src/levels/playground.tscn"
const WALK_FRAMES := 240


func _open_level() -> Node2D:
	var level: Node2D = load(LEVEL_SCENE).instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().process_frame
	return level


func _hud(level: Node2D) -> WalletHud:
	var found := level.find_child("WalletHud", true, false)
	assert_not_null(found, "the playground shows the wallet HUD")
	return found as WalletHud


func _gems(level: Node2D) -> Array:
	return level.find_children("*", "Gem", true, false)


func test_collecting_a_gem_raises_the_wallet_balance() -> void:
	var level := await _open_level()
	var hud := _hud(level)
	assert_eq(hud.balance(), 0, "the wallet starts empty")
	level.wallet.add(3)
	assert_eq(hud.balance(), 3, "collecting 3 gems shows 3 on the HUD")


func test_hud_follows_the_wallet_through_collect_and_spend() -> void:
	var level := await _open_level()
	var hud := _hud(level)
	level.wallet.add(3)
	level.wallet.add(2)
	assert_eq(hud.balance(), 5, "the HUD tracks wallet adds")
	assert_true(level.wallet.spend(1), "the machine can spend a banked gem")
	assert_eq(hud.balance(), 4, "the HUD drops after the spend")


func test_collecting_walk_picks_up_gems() -> void:
	var level := await _open_level()
	var hud := _hud(level)
	var gems := _gems(level)
	assert_gt(gems.size(), 0, "the meadow hides some gems")
	level.robot.global_position = (gems[0] as Node2D).global_position
	for i in WALK_FRAMES:
		var frame_target := _nearest_gem(level)
		if frame_target == null:
			break
		level.robot.global_position = frame_target.global_position
		await get_tree().physics_frame
	assert_gt(hud.balance(), 0, "the stroll banks at least one gem")


func test_post_spend_hud_matches_wallet_and_stays_single() -> void:
	var level := await _open_level()
	var hud := _hud(level)
	var wallet: Wallet = level.wallet
	var cost: int = level.machine.price_for_next()
	assert_gt(cost, 0, "the first gift has a price")
	wallet.add(cost + 2)
	assert_eq(hud.balance(), cost + 2, "banking before the tap shows on the HUD")
	assert_eq(level.machine.use(), GiftMachine.UseResult.DISPENSED, "the tap dispenses")
	assert_eq(hud.balance(), 2, "the HUD matches the wallet after the spend")
	assert_eq(wallet.balance(), 2, "the wallet holds the remainder")
	assert_null(level.find_child("GemCounter", true, false), "no legacy counter badge remains")
	assert_not_null(level.find_child("WalletHud", true, false), "the wallet HUD is the badge")
	var badges := 0
	for child in level.get_children():
		if child is WalletHud:
			badges += 1
	assert_eq(badges, 1, "exactly one top-left badge remains")


func _nearest_gem(level: Node2D) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for node in _gems(level):
		var gem := node as Gem
		if gem == null or gem.is_collected():
			continue
		var d: float = level.robot.global_position.distance_squared_to(
			(node as Node2D).global_position
		)
		if d < best_d:
			best_d = d
			best = node
	return best
