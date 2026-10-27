class_name Cosmetics
extends RefCounted
## Catalog of the 6-item surprise gift set (gem_shop_20261027 Phase 2).
##
## The set is fixed by the spec: 3 hats, 2 trails, 1 robot color, priced
## 1, 1, 2, 2, 3, 3 for a 12-gem complete set. The order below IS the dispense
## order within a tier — cheapest-unowned-first, ties broken by position — so
## the kindest math (cheapest first) needs no extra sorting. Prices reuse the
## Tuning gift tiers so designers tune in exactly one place.

const HAT_SPROUT := "hat_sprout"
const HAT_STAR := "hat_star"
const HAT_CROWN := "hat_crown"
const TRAIL_BUBBLES := "trail_bubbles"
const TRAIL_SPARKLE := "trail_sparkle"
const COLOR_SUNNY := "color_sunny"

const KIND_HAT := "hat"
const KIND_TRAIL := "trail"
const KIND_COLOR := "color"


## Every gift as plain data, cheapest tier first.
static func catalog() -> Array[Dictionary]:
	return [
		{"id": HAT_SPROUT, "kind": KIND_HAT, "price": Tuning.GIFT_TIER_1},
		{"id": HAT_STAR, "kind": KIND_HAT, "price": Tuning.GIFT_TIER_1},
		{"id": HAT_CROWN, "kind": KIND_HAT, "price": Tuning.GIFT_TIER_2},
		{"id": TRAIL_BUBBLES, "kind": KIND_TRAIL, "price": Tuning.GIFT_TIER_2},
		{"id": TRAIL_SPARKLE, "kind": KIND_TRAIL, "price": Tuning.GIFT_TIER_3},
		{"id": COLOR_SUNNY, "kind": KIND_COLOR, "price": Tuning.GIFT_TIER_3},
	]


## Every gift id in dispense order.
static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in catalog():
		ids.append(str(entry["id"]))
	return ids


## True for one of the six set ids.
static func is_valid(cosmetic_id: String) -> bool:
	return all_ids().has(cosmetic_id)


## The gem price of a gift, or -1 for an unknown id.
static func price_of(cosmetic_id: String) -> int:
	for entry: Dictionary in catalog():
		if str(entry["id"]) == cosmetic_id:
			return int(entry["price"])
	return -1


## The kind of a gift ("hat", "trail", or "color"), or "" for unknown ids.
static func kind_of(cosmetic_id: String) -> String:
	for entry: Dictionary in catalog():
		if str(entry["id"]) == cosmetic_id:
			return str(entry["kind"])
	return ""


## How many gifts of one kind the set holds (pins the 3/2/1 mix).
static func count_of_kind(kind: String) -> int:
	var found := 0
	for entry: Dictionary in catalog():
		if str(entry["kind"]) == kind:
			found += 1
	return found


## The full-set price: every gift owned exactly once.
static func total_cost() -> int:
	var total := 0
	for entry: Dictionary in catalog():
		total += int(entry["price"])
	return total
