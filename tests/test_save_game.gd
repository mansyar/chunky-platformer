extends GdToolsTest
## Tests for the minimal save/load (gem_shop_20261027 Phase 3, FR-8/FR-9).
##
## The wallet, the wardrobe, and the per-area gem-taken flags survive an app
## restart inside a versioned user:// JSON file; a missing, corrupt, or
## future-version save boots fresh with no crash and no on-screen text; and
## every gem collect, gift dispense, and area transition rewrites the file.
## Pure SaveGame cases use a throwaway path; Game trigger cases drive the
## real save path from a clean slate and clean up after themselves.

const GAME_SCRIPT := "res://src/levels/game.gd"
const TEMP_PATH := "user://test_save_game_tmp.json"


func _wallet_with(gems: int) -> Wallet:
	var wallet := Wallet.new()
	if gems > 0:
		wallet.add(gems)
	return wallet


func _wardrobe_wearing(own_first: Array, wear_id: String) -> Wardrobe:
	var wardrobe := Wardrobe.new()
	for gift_id in own_first:
		wardrobe.own(str(gift_id))
	if not wear_id.is_empty():
		wardrobe.wear(wear_id)
	return wardrobe


func _taken_flags(first_n_taken: int) -> Dictionary:
	var flags: Array[bool] = []
	for i: int in range(AreaLayout.GEMS_PER_AREA):
		flags.append(i < first_n_taken)
	return {"meadow": flags}


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _boot_game() -> Game:
	var game: Game = load(GAME_SCRIPT).new()
	add_child(game)
	return game


func _fresh_game() -> Game:
	# Phase 3 persists to disk, so a Game boot must start from a clean slate.
	SaveGame.clear()
	return _boot_game()


## Collect the live gems whose gem_id is listed (the builder owns the gems,
## so tests reach them the same way the gem-budget suite does).
func _collect_gems(game: Game, ids: Array) -> void:
	for node in game.builder.find_children("*", "Gem", true, false):
		var gem := node as Gem
		if gem != null and ids.has(gem.gem_id):
			gem.collect()


func _is_collected(game: Game, gem_id: int) -> bool:
	for node in game.builder.find_children("*", "Gem", true, false):
		var gem := node as Gem
		if gem != null and gem.gem_id == gem_id:
			return gem.is_collected()
	return false


# --- round-trips (P3.T1.1) ----------------------------------------------------


func test_round_trip_preserves_wallet_wardrobe_and_taken() -> void:
	SaveGame.clear(TEMP_PATH)
	var wallet := _wallet_with(5)
	var wardrobe := _wardrobe_wearing(
		[Cosmetics.HAT_SPROUT, Cosmetics.TRAIL_SPARKLE], Cosmetics.HAT_SPROUT
	)
	var taken := _taken_flags(3)
	assert_true(SaveGame.save_game(wallet, wardrobe, taken, TEMP_PATH), "saving succeeds.")
	var state := SaveGame.load_game(TEMP_PATH)
	assert_eq(state["wallet"], 5, "the balance survives the restart.")
	assert_eq(
		state["owned"],
		[Cosmetics.HAT_SPROUT, Cosmetics.TRAIL_SPARKLE],
		"owned gifts survive in own order."
	)
	assert_eq(state["worn"], Cosmetics.HAT_SPROUT, "the worn look survives.")
	assert_eq((state["taken"] as Dictionary)["meadow"], taken["meadow"], "gem-taken flags survive.")
	SaveGame.clear(TEMP_PATH)


func test_save_file_is_versioned_json() -> void:
	SaveGame.clear(TEMP_PATH)
	SaveGame.save_game(_wallet_with(0), Wardrobe.new(), {}, TEMP_PATH)
	var raw: Variant = _read_json(TEMP_PATH)
	assert_eq(raw["version"], SaveGame.VERSION, "the file carries a version field.")
	assert_true(raw.has("wallet"), "the wallet is stored.")
	assert_true(raw.has("owned"), "owned gifts are stored.")
	assert_true(raw.has("worn"), "the worn look is stored.")
	assert_true(raw.has("taken"), "gem-taken flags are stored.")
	assert_true(raw.has("area_index"), "the area index is stored.")
	SaveGame.clear(TEMP_PATH)


func test_empty_session_round_trips_to_fresh() -> void:
	SaveGame.clear(TEMP_PATH)
	SaveGame.save_game(_wallet_with(0), Wardrobe.new(), {}, TEMP_PATH)
	assert_eq(
		SaveGame.load_game(TEMP_PATH), SaveGame.fresh_state(), "a fresh session reloads as fresh."
	)
	SaveGame.clear(TEMP_PATH)


func test_full_collection_round_trips() -> void:
	SaveGame.clear(TEMP_PATH)
	var all: Array = [
		Cosmetics.HAT_SPROUT,
		Cosmetics.HAT_STAR,
		Cosmetics.HAT_CROWN,
		Cosmetics.TRAIL_BUBBLES,
		Cosmetics.TRAIL_SPARKLE,
		Cosmetics.COLOR_SUNNY,
	]
	var wardrobe := _wardrobe_wearing(all, Cosmetics.COLOR_SUNNY)
	SaveGame.save_game(_wallet_with(12), wardrobe, _taken_flags(10), TEMP_PATH)
	var state := SaveGame.load_game(TEMP_PATH)
	assert_eq(state["wallet"], 12, "a full wallet survives.")
	assert_eq(state["owned"], all, "all six gifts survive in own order.")
	assert_eq(state["worn"], Cosmetics.COLOR_SUNNY, "the last-worn look survives.")
	SaveGame.clear(TEMP_PATH)


func test_to_dict_ignores_junk_taken_keys() -> void:
	var taken := {"meadow": [true, false], "junk": "nope", 7: [true]}
	var payload := SaveGame.to_dict(_wallet_with(1), Wardrobe.new(), taken)
	var clean: Dictionary = payload["taken"]
	assert_eq(clean["meadow"], [true, false], "real flags pass through.")
	assert_eq(clean["junk"], [], "junk values read as uncollected.")
	assert_false(clean.has(7), "non-area keys are dropped.")


func test_save_reports_write_failure() -> void:
	assert_false(
		SaveGame.save_game(_wallet_with(1), Wardrobe.new(), {}, "user://no_such_dir_xyz/save.json"),
		"an unwritable path returns false instead of crashing."
	)


# --- corrupt / missing / future saves (P3.T1.2) --------------------------------


func test_missing_file_boots_fresh() -> void:
	SaveGame.clear(TEMP_PATH)
	assert_eq(
		SaveGame.load_game(TEMP_PATH), SaveGame.fresh_state(), "a first boot with no save is fresh."
	)


func test_garbage_file_boots_fresh() -> void:
	_write_text(TEMP_PATH, "not json{{{")
	assert_eq(
		SaveGame.load_game(TEMP_PATH),
		SaveGame.fresh_state(),
		"garbage boots fresh instead of crashing."
	)
	SaveGame.clear(TEMP_PATH)


func test_empty_file_boots_fresh() -> void:
	_write_text(TEMP_PATH, "")
	assert_eq(
		SaveGame.load_game(TEMP_PATH),
		SaveGame.fresh_state(),
		"an empty file boots fresh instead of crashing."
	)
	SaveGame.clear(TEMP_PATH)


func test_json_array_boots_fresh() -> void:
	_write_text(TEMP_PATH, "[1, 2, 3]")
	assert_eq(
		SaveGame.load_game(TEMP_PATH),
		SaveGame.fresh_state(),
		"a save that is not an object boots fresh."
	)
	SaveGame.clear(TEMP_PATH)


func test_future_version_boots_fresh() -> void:
	_write_text(
		TEMP_PATH,
		JSON.stringify({"version": 999, "wallet": 50, "owned": [], "worn": "", "taken": {}})
	)
	assert_eq(
		SaveGame.load_game(TEMP_PATH),
		SaveGame.fresh_state(),
		"a save from the future boots fresh instead of crashing."
	)
	SaveGame.clear(TEMP_PATH)


func test_missing_or_wrong_shaped_version_boots_fresh() -> void:
	_write_text(TEMP_PATH, JSON.stringify({"wallet": 50}))
	assert_eq(
		SaveGame.load_game(TEMP_PATH), SaveGame.fresh_state(), "a save with no version boots fresh."
	)
	_write_text(TEMP_PATH, JSON.stringify({"version": "1", "wallet": 50}))
	assert_eq(
		SaveGame.load_game(TEMP_PATH),
		SaveGame.fresh_state(),
		"a save with a non-numeric version boots fresh."
	)
	SaveGame.clear(TEMP_PATH)


func test_shabby_fields_repair_instead_of_wiping() -> void:
	_write_text(
		TEMP_PATH,
		(
			JSON
			. stringify(
				{
					"version": 1,
					"wallet": "lots",
					"owned": [Cosmetics.HAT_SPROUT, "nope", Cosmetics.HAT_SPROUT, 7],
					"worn": "nope",
					"taken": {"meadow": [true, 1, "x", false], "cave": "junk", "5": [true]},
				}
			)
		)
	)
	var state := SaveGame.load_game(TEMP_PATH)
	assert_eq(state["wallet"], 0, "a bad wallet reads as empty.")
	assert_eq(state["owned"], [Cosmetics.HAT_SPROUT], "unknown gifts are dropped.")
	assert_eq(
		state["worn"],
		Cosmetics.HAT_SPROUT,
		"a worn look nobody owns falls back to the newest gift."
	)
	assert_eq(
		(state["taken"] as Dictionary)["meadow"],
		[true, false, false, false],
		"junk flags read as uncollected."
	)
	assert_eq((state["taken"] as Dictionary)["cave"], [], "a junk area reads as unvisited.")
	SaveGame.clear(TEMP_PATH)


func test_game_boots_fresh_with_garbage_save() -> void:
	_write_text(SaveGame.SAVE_PATH, "garbage{{{")
	var game := _boot_game()
	assert_eq(game.wallet.balance(), 0, "the wallet starts empty.")
	assert_true(game.wardrobe.owned().is_empty(), "nothing is owned.")
	assert_eq(game.area_index, 0, "the meadow still builds: no crash, no error text.")
	SaveGame.clear()


func test_relaunch_restores_wallet_wardrobe_and_taken() -> void:
	var game := _fresh_game()
	_collect_gems(game, [0, 1, 2])
	assert_eq(game.builder.machine.use(), GiftMachine.UseResult.DISPENSED, "a gift is dispensed.")
	remove_child(game)
	game.queue_free()
	var again := _boot_game()
	assert_eq(again.wallet.balance(), 2, "the balance survives the relaunch.")
	assert_eq(
		again.wardrobe.owned(), [Cosmetics.HAT_SPROUT], "the gifted look survives the relaunch."
	)
	assert_eq(again.wardrobe.worn(), Cosmetics.HAT_SPROUT, "the worn look survives too.")
	for i: int in range(3):
		assert_true(_is_collected(again, i), "collected gem %d stays collected after relaunch." % i)
	assert_false(_is_collected(again, 3), "uncollected gems stay put after relaunch.")
	SaveGame.clear()


# --- autosave triggers (P3.T2.1) -----------------------------------------------


func test_collect_rewrites_the_save() -> void:
	var game := _fresh_game()
	var before: Variant = _read_json(SaveGame.SAVE_PATH)
	assert_eq(before["wallet"], 0, "boot writes a fresh save.")
	_collect_gems(game, [0])
	var after: Variant = _read_json(SaveGame.SAVE_PATH)
	assert_eq(after["wallet"], 1, "collecting a gem rewrites the save.")
	assert_eq(
		((after["taken"] as Dictionary)["meadow"] as Array)[0],
		true,
		"the collect is on disk, not just in memory."
	)
	SaveGame.clear()


func test_dispense_rewrites_the_save() -> void:
	var game := _fresh_game()
	game.wallet.add(3)
	assert_eq(game.builder.machine.use(), GiftMachine.UseResult.DISPENSED, "a gift is dispensed.")
	var saved: Variant = _read_json(SaveGame.SAVE_PATH)
	assert_eq(saved["wallet"], 2, "the dispense price is on disk.")
	assert_eq(saved["owned"], [Cosmetics.HAT_SPROUT], "the gift is on disk.")
	assert_eq(saved["worn"], Cosmetics.HAT_SPROUT, "the new look is on disk.")
	SaveGame.clear()


func test_area_transition_rewrites_the_save() -> void:
	var game := _fresh_game()
	_collect_gems(game, [0])
	for _i: int in AreaLayout.KEYS_PER_AREA:
		game.builder.goal_state.take_key()
	game.builder.door.entered.emit(game.builder.door)
	game.transition.step(Tuning.TRANSITION_TIME)
	assert_eq(game.area_index, 1, "the swap happened.")
	var saved: Variant = _read_json(SaveGame.SAVE_PATH)
	assert_eq(
		((saved["taken"] as Dictionary)["meadow"] as Array)[0],
		true,
		"the meadow collect survived the swap on disk."
	)
	SaveGame.clear()

# V2 area_index persist/clamp and V1 migration live in test_save_game_v2.gd:
# this suite is at the lint cap of 20 public methods.
