extends GdToolsTest
## Tests for the gift-set catalog (gem_shop_20261027 Phase 2).
##
## The catalog is the spec's 6-item surprise set made queryable: 3 hats,
## 2 trails, 1 robot color, priced 1, 1, 2, 2, 3, 3 for a 12-gem complete
## set. Pure data, so every test runs without frames or the tree.


func test_catalog_holds_six_unique_gifts() -> void:
	var ids := Cosmetics.all_ids()
	assert_eq(ids.size(), 6, "the surprise set is exactly six gifts.")
	var seen := {}
	for gift_id: String in ids:
		assert_false(seen.has(gift_id), "gift id '%s' appears once." % gift_id)
		seen[gift_id] = true
		assert_true(Cosmetics.is_valid(gift_id), "'%s' validates." % gift_id)
	assert_false(Cosmetics.is_valid(""), "empty id is not a gift.")
	assert_false(Cosmetics.is_valid("hat_nope"), "unknown id is not a gift.")


func test_catalog_mixes_three_hats_two_trails_one_color() -> void:
	assert_eq(Cosmetics.count_of_kind(Cosmetics.KIND_HAT), 3, "three hats.")
	assert_eq(Cosmetics.count_of_kind(Cosmetics.KIND_TRAIL), 2, "two trails.")
	assert_eq(Cosmetics.count_of_kind(Cosmetics.KIND_COLOR), 1, "one color.")


func test_catalog_prices_are_tiered_one_one_two_two_three_three() -> void:
	var prices: Array[int] = []
	for gift_id: String in Cosmetics.all_ids():
		prices.append(Cosmetics.price_of(gift_id))
	assert_eq(prices, [1, 1, 2, 2, 3, 3], "tiers run 1, 1, 2, 2, 3, 3.")
	for tier: int in [Tuning.GIFT_TIER_1, Tuning.GIFT_TIER_2, Tuning.GIFT_TIER_3]:
		assert_true(prices.has(tier), "tier %d is used." % tier)
	assert_eq(Cosmetics.price_of("hat_nope"), -1, "unknown gifts cost -1.")
	assert_eq(Cosmetics.kind_of("hat_nope"), "", "unknown gifts have no kind.")


func test_catalog_costs_twelve_gems_for_the_full_set() -> void:
	assert_eq(Cosmetics.total_cost(), 12, "owning every gift once costs 12 gems.")
	assert_eq(
		Cosmetics.total_cost(), Tuning.COSMETIC_SET_TOTAL, "total matches the tuning constant."
	)


func test_catalog_lists_cheapest_first() -> void:
	var last_price := 0
	for gift_id: String in Cosmetics.all_ids():
		var gift_price := Cosmetics.price_of(gift_id)
		assert_true(
			gift_price >= last_price, "'%s' never costs less than an earlier gift." % gift_id
		)
		last_price = gift_price


func test_every_hat_has_generated_art() -> void:
	for gift_id: String in Cosmetics.all_ids():
		if Cosmetics.kind_of(gift_id) != Cosmetics.KIND_HAT:
			continue
		var texture := AssetFactory.get_texture(gift_id)
		assert_not_null(texture, "'%s' has generated art." % gift_id)
		assert_eq(texture.get_width(), 16, "'%s' is 16 wide." % gift_id)
		assert_eq(texture.get_height(), 12, "'%s' is 12 tall." % gift_id)
