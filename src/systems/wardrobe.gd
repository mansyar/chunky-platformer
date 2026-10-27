class_name Wardrobe
extends RefCounted
## Owned + worn looks for Robo (gem_shop_20261027 Phase 2).
##
## The gift machine owns gifts here cheapest-unowned-first, never granting a
## duplicate until the 6-item set is complete; tapping Robo cycles the worn
## look with wraparound. Owning auto-wears immediately, so the surprise is
## visible within a second of the dispense. Save/load arrives in Phase 3 —
## this phase only needs session state, owned by the game root and carried
## across area swaps exactly like the wallet.

## Emitted whenever the worn look changes, carrying the new worn id.
signal changed(worn_id: String)

var _owned: Array[String] = []
var _worn := ""


## Every owned gift id, in the order they were owned.
func owned() -> Array[String]:
	return _owned.duplicate()


func is_owned(cosmetic_id: String) -> bool:
	return _owned.has(cosmetic_id)


func is_complete() -> bool:
	return _owned.size() >= Cosmetics.all_ids().size()


## The currently worn gift id, or "" when nothing is worn yet.
func worn() -> String:
	return _worn


## Take ownership of a gift. Rejects unknown ids and duplicates; owning
## auto-wears the new look. Returns true when something was owned.
func own(cosmetic_id: String) -> bool:
	if not Cosmetics.is_valid(cosmetic_id):
		return false
	if _owned.has(cosmetic_id):
		return false
	_owned.append(cosmetic_id)
	_worn = cosmetic_id
	changed.emit(_worn)
	return true


## Wear an owned look. Returns false (changing nothing) for unowned ids;
## re-wearing the current look succeeds silently.
func wear(cosmetic_id: String) -> bool:
	if not _owned.has(cosmetic_id):
		return false
	if _worn == cosmetic_id:
		return true
	_worn = cosmetic_id
	changed.emit(_worn)
	return true


## Cheapest unowned gift (catalog order breaks tier ties); "" when complete.
func next_unowned() -> String:
	for entry: Dictionary in Cosmetics.catalog():
		var gift_id := str(entry["id"])
		if not _owned.has(gift_id):
			return gift_id
	return ""


## Price of the next gift; -1 when the set is complete (the bonus is free).
func next_price() -> int:
	var gift_id := next_unowned()
	if gift_id.is_empty():
		return -1
	return Cosmetics.price_of(gift_id)


## Wear the next owned look, wrapping to the first after the last. With fewer
## than two owned looks there is nothing to cycle between, so the worn look
## stays put.
func cycle_next() -> String:
	if _owned.size() < 2:
		return _worn
	var at := _owned.find(_worn)
	var next_id: String = _owned[(at + 1) % _owned.size()]
	_worn = next_id
	changed.emit(_worn)
	return _worn


## Test/debug helper: empty the wardrobe within the session.
func reset() -> void:
	_owned.clear()
	_worn = ""
	changed.emit(_worn)
