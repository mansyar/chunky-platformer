extends GdToolsTest
## Tests for the session wardrobe (gem_shop_20261027 Phase 2).
##
## Owning auto-wears, duplicates are refused until the set is complete, and
## tap-Robo cycles owned looks with wraparound. Pure state, no tree needed.


func _wardrobe() -> Wardrobe:
	return Wardrobe.new()


func test_wardrobe_starts_empty_and_unworn() -> void:
	var wardrobe := _wardrobe()
	assert_true(wardrobe.owned().is_empty(), "nothing owned at first.")
	assert_eq(wardrobe.worn(), "", "nothing worn at first.")
	assert_false(wardrobe.is_complete(), "the set is not complete.")
	assert_eq(wardrobe.next_unowned(), Cosmetics.HAT_SPROUT, "cheapest gift is next.")
	assert_eq(wardrobe.next_price(), Tuning.GIFT_TIER_1, "next price is tier 1.")


func test_owning_auto_wears_and_signals() -> void:
	var wardrobe := _wardrobe()
	var worn_ids: Array = []
	wardrobe.changed.connect(func(worn_id: String) -> void: worn_ids.append(worn_id))
	assert_true(wardrobe.own(Cosmetics.HAT_SPROUT), "owning the sprout works.")
	assert_true(wardrobe.is_owned(Cosmetics.HAT_SPROUT), "the sprout is owned.")
	assert_eq(wardrobe.worn(), Cosmetics.HAT_SPROUT, "owning auto-wears the gift.")
	assert_eq(worn_ids, [Cosmetics.HAT_SPROUT], "one change, carrying the worn id.")


func test_owning_rejects_unknown_ids_and_duplicates() -> void:
	var wardrobe := _wardrobe()
	var changes := [0]
	wardrobe.changed.connect(func(_worn_id: String) -> void: changes[0] += 1)
	assert_false(wardrobe.own("hat_nope"), "unknown ids are refused.")
	assert_true(wardrobe.own(Cosmetics.HAT_STAR), "owning the star works.")
	assert_false(wardrobe.own(Cosmetics.HAT_STAR), "duplicates are refused.")
	assert_eq(wardrobe.owned().size(), 1, "only the first own sticks.")
	assert_eq(changes[0], 1, "refusals emit nothing.")


func test_next_unowned_is_always_cheapest_remaining() -> void:
	var wardrobe := _wardrobe()
	# Own out of order: the next gift is still the cheapest one left.
	assert_true(wardrobe.own(Cosmetics.COLOR_SUNNY), "own the priciest gift first.")
	assert_eq(wardrobe.next_unowned(), Cosmetics.HAT_SPROUT, "cheapest gift is still next.")
	assert_eq(wardrobe.next_price(), Tuning.GIFT_TIER_1, "next price is still tier 1.")
	assert_true(wardrobe.own(Cosmetics.HAT_SPROUT), "own the cheapest.")
	assert_eq(wardrobe.next_unowned(), Cosmetics.HAT_STAR, "tier-1 twin is next.")
	assert_true(wardrobe.own(Cosmetics.HAT_STAR), "own the twin.")
	assert_eq(wardrobe.next_unowned(), Cosmetics.HAT_CROWN, "tier 2 opens next.")
	assert_eq(wardrobe.next_price(), Tuning.GIFT_TIER_2, "next price is tier 2.")


func test_full_set_completes_and_frees_the_bonus() -> void:
	var wardrobe := _wardrobe()
	for gift_id: String in Cosmetics.all_ids():
		assert_true(wardrobe.own(gift_id), "'%s' is owned." % gift_id)
	assert_true(wardrobe.is_complete(), "six gifts complete the set.")
	assert_eq(wardrobe.next_unowned(), "", "nothing is next after completion.")
	assert_eq(wardrobe.next_price(), -1, "no price after completion: bonus is free.")


func test_wear_needs_ownership() -> void:
	var wardrobe := _wardrobe()
	assert_false(wardrobe.wear(Cosmetics.HAT_CROWN), "unowned looks cannot be worn.")
	assert_eq(wardrobe.worn(), "", "refused wear changes nothing.")
	wardrobe.own(Cosmetics.HAT_CROWN)
	wardrobe.own(Cosmetics.HAT_SPROUT)
	assert_true(wardrobe.wear(Cosmetics.HAT_CROWN), "owned looks wear fine.")
	assert_eq(wardrobe.worn(), Cosmetics.HAT_CROWN, "the crown is worn.")


func test_cycle_walks_owned_looks_and_wraps() -> void:
	var wardrobe := _wardrobe()
	assert_eq(wardrobe.cycle_next(), "", "empty wardrobe cycles to nothing.")
	wardrobe.own(Cosmetics.HAT_SPROUT)
	assert_eq(wardrobe.cycle_next(), Cosmetics.HAT_SPROUT, "one look stays put.")
	wardrobe.own(Cosmetics.TRAIL_BUBBLES)
	var changes: Array = []
	wardrobe.changed.connect(func(worn_id: String) -> void: changes.append(worn_id))
	assert_eq(wardrobe.cycle_next(), Cosmetics.HAT_SPROUT, "cycle wraps to the first look.")
	assert_eq(wardrobe.cycle_next(), Cosmetics.TRAIL_BUBBLES, "then steps to the second.")
	assert_eq(wardrobe.cycle_next(), Cosmetics.HAT_SPROUT, "then wraps again.")
	assert_eq(
		changes,
		[Cosmetics.HAT_SPROUT, Cosmetics.TRAIL_BUBBLES, Cosmetics.HAT_SPROUT],
		"every cycle step signals the new look."
	)


func test_reset_empties_the_session() -> void:
	var wardrobe := _wardrobe()
	wardrobe.own(Cosmetics.HAT_SPROUT)
	wardrobe.reset()
	assert_true(wardrobe.owned().is_empty(), "reset clears ownership.")
	assert_eq(wardrobe.worn(), "", "reset clears the worn look.")
	assert_false(wardrobe.is_complete(), "reset un-completes the set.")
