class_name SaveGame
extends RefCounted
## Minimal save/load for the gem economy (gem_shop_20261027 Phase 3).
##
## One tiny JSON file in user:// holds the wallet balance, the owned/worn
## cosmetic ids, the per-area gem-taken flags, and the last visited area
## index, stamped with a version field reserved for migration. The game loads
## once at boot and rewrites on every wallet/wardrobe change plus every area
## swap.
##
## Recovery is two-tiered: an unreadable file or a version mismatch boots
## fully fresh (a warning is logged for diagnostics, never shown to the
## child); a readable file with shabby inner fields is repaired field by
## field (bad wallet reads as 0, unknown or duplicate gifts are dropped, a
## worn look that is not owned falls back to the newest owned gift, junk
## taken flags read as uncollected, a missing or out-of-range area reads as
## the meadow) so one bad field never wipes progress. V1 files (no area key)
## migrate forward, keeping every collection and defaulting the area to 0.

## Where the save lives, and the only versions this build reads (current plus
## the previous one, which migrates forward).
const SAVE_PATH := "user://save_game.json"
const VERSION := 2
const PREVIOUS_VERSION := 1


## A fresh session: empty wallet, empty wardrobe, no area visited, meadow.
static func fresh_state() -> Dictionary:
	return {"version": VERSION, "wallet": 0, "owned": [], "worn": "", "taken": {}, "area_index": 0}


## Pack live session objects into a save-ready Dictionary. The area defaults
## to the meadow so older callers keep writing valid V2 saves.
static func to_dict(
	wallet: Wallet, wardrobe: Wardrobe, taken: Dictionary, area_index: int = 0
) -> Dictionary:
	var taken_clean := {}
	for area in taken.keys():
		if not (area is String):
			continue
		var flags: Array[bool] = []
		if taken[area] is Array:
			for entry in taken[area] as Array:
				flags.append(entry is bool and entry)
		taken_clean[area] = flags
	return {
		"version": VERSION,
		"wallet": maxi(wallet.balance(), 0),
		"owned": wardrobe.owned(),
		"worn": wardrobe.worn(),
		"taken": taken_clean,
		"area_index": maxi(area_index, 0),
	}


## Repair a parsed JSON value into a valid state Dictionary. Anything that
## is not an object, or carries an unknown version (including saves from the
## future), becomes a fresh state with a warning; V1 files migrate forward
## with their collections intact and the area defaulting to the meadow; inner
## fields repair themselves so surviving progress is kept.
static func sanitize(data: Variant) -> Dictionary:
	if not (data is Dictionary):
		push_warning("SaveGame: save is not an object; booting fresh.")
		return fresh_state()
	var version_ok := false
	var raw_version: Variant = (data as Dictionary).get("version", null)
	if raw_version is int or raw_version is float:
		var version := int(raw_version)
		version_ok = version == VERSION or version == PREVIOUS_VERSION
	if not version_ok:
		push_warning("SaveGame: unsupported save version; booting fresh.")
		return fresh_state()
	var wallet := 0
	var raw_wallet: Variant = (data as Dictionary).get("wallet", 0)
	if raw_wallet is int or raw_wallet is float:
		wallet = maxi(int(raw_wallet), 0)
	var owned: Array[String] = []
	var raw_owned: Variant = (data as Dictionary).get("owned", [])
	if raw_owned is Array:
		for entry in raw_owned as Array:
			if entry is String and Cosmetics.is_valid(entry) and not owned.has(entry):
				owned.append(entry)
	var worn := ""
	var raw_worn: Variant = (data as Dictionary).get("worn", "")
	if raw_worn is String and owned.has(raw_worn):
		worn = raw_worn
	elif not owned.is_empty():
		worn = owned.back()
	var taken := {}
	var raw_taken: Variant = (data as Dictionary).get("taken", {})
	if raw_taken is Dictionary:
		for area in (raw_taken as Dictionary).keys():
			var flags: Array[bool] = []
			if (raw_taken as Dictionary)[area] is Array:
				for entry in (raw_taken as Dictionary)[area] as Array:
					flags.append(entry is bool and entry)
			taken[area] = flags
	# The area is the only ranged field: anything missing, non-numeric, or
	# outside the built areas reads as the meadow. The count comes from the
	# area list itself so adding an area never strands a valid save here.
	var area_index := 0
	var raw_area: Variant = (data as Dictionary).get("area_index", 0)
	if raw_area is int or raw_area is float:
		var candidate := int(raw_area)
		if candidate >= 0 and candidate < AreaLayout.all().size():
			area_index = candidate
	return {
		"version": VERSION,
		"wallet": wallet,
		"owned": owned,
		"worn": worn,
		"taken": taken,
		"area_index": area_index,
	}


## Write the session to disk. Returns false (with a warning) when the file
## cannot be written; the session itself is unaffected.
static func save_game(
	wallet: Wallet,
	wardrobe: Wardrobe,
	taken: Dictionary,
	path: String = SAVE_PATH,
	area_index: int = 0
) -> bool:
	var payload := to_dict(wallet, wardrobe, taken, area_index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot write '%s'." % path)
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true


## Read the save, repaired and ready to apply. A missing, unreadable, or
## future-version file boots fresh with a warning; never null, never throws.
static func load_game(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fresh_state()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SaveGame: cannot read '%s'; booting fresh." % path)
		return fresh_state()
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		push_warning("SaveGame: save is empty; booting fresh.")
		return fresh_state()
	# The instance parser reports failure as a return value; the static
	# parse_string would log an engine ERROR on corrupt text and fail the run.
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("SaveGame: save is not valid JSON; booting fresh.")
		return fresh_state()
	return sanitize(json.get_data())


## Delete the save file (fresh-boot helper for tests).
static func clear(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			push_warning("SaveGame: cannot delete '%s'." % path)
