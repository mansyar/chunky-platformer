class_name Wallet
extends RefCounted
## Session-scoped gem wallet: collected gems accumulate here.
##
## The single source of truth for "how many gems does the child have".
## Balance never goes negative: spend() clamps and returns success bool.
## Save/load arrives in Phase 3; this phase only needs session persistence
## (owned by the game root, carried across area swaps).

## Emitted whenever the balance changes, carrying the new balance.
signal changed(balance: int)

var _balance := 0


## Current balance.
func balance() -> int:
	return _balance


## Add gems. Non-positive amounts are ignored.
func add(amount: int) -> void:
	if amount <= 0:
		return
	_balance += amount
	changed.emit(_balance)


## Spend gems. Returns true and deducts on success; returns false and
## leaves the balance untouched when funds are insufficient. Non-positive
## amounts are rejected without emitting.
func spend(amount: int) -> bool:
	if amount <= 0:
		return false
	if amount > _balance:
		return false
	_balance -= amount
	changed.emit(_balance)
	return true


## Test/debug helper: reset to zero within the session.
func reset() -> void:
	_balance = 0
	changed.emit(_balance)
