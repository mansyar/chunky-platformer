extends GdToolsTest
## Tests for the session wallet (Phase 1, FR-2).
##
## The wallet is the single source of truth for "how many gems does the
## child have". Balance never goes negative; every change emits `changed`.


func _wallet() -> Wallet:
	return Wallet.new()


func test_fresh_wallet_starts_empty() -> void:
	assert_eq(_wallet().balance(), 0, "a fresh wallet holds nothing.")


func test_add_accumulates() -> void:
	var wallet := _wallet()
	wallet.add(1)
	wallet.add(2)
	assert_eq(wallet.balance(), 3, "gems accumulate.")


func test_add_ignores_non_positive_amounts() -> void:
	var wallet := _wallet()
	wallet.add(3)
	wallet.add(0)
	wallet.add(-2)
	assert_eq(wallet.balance(), 3, "zero and negative adds change nothing.")


func test_spend_deducts_exactly() -> void:
	var wallet := _wallet()
	wallet.add(3)
	assert_true(wallet.spend(3), "spending the full balance succeeds.")
	assert_eq(wallet.balance(), 0, "the price is deducted exactly.")


func test_spend_never_drives_the_balance_negative() -> void:
	var wallet := _wallet()
	wallet.add(2)
	assert_false(wallet.spend(3), "overspending fails.")
	assert_eq(wallet.balance(), 2, "a failed spend leaves the balance untouched.")
	assert_false(wallet.spend(0), "spending zero fails.")
	assert_false(wallet.spend(-1), "spending a negative amount fails.")
	assert_eq(wallet.balance(), 2, "rejected spends change nothing.")


func test_changed_emits_on_add_and_spend() -> void:
	var wallet := _wallet()
	var seen: Array[int] = []
	wallet.changed.connect(func(b: int) -> void: seen.append(b))
	wallet.add(2)
	wallet.spend(1)
	assert_eq(seen, [2, 1], "every balance change is announced.")


func test_changed_does_not_emit_on_rejected_moves() -> void:
	var wallet := _wallet()
	var count := [0]
	wallet.changed.connect(func(_b: int) -> void: count[0] += 1)
	wallet.add(0)
	wallet.spend(5)
	assert_eq(count[0], 0, "rejected moves stay silent.")


func test_reset_empties_within_the_session() -> void:
	var wallet := _wallet()
	wallet.add(4)
	wallet.reset()
	assert_eq(wallet.balance(), 0, "reset returns to zero.")
