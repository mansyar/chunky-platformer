extends GdToolsTest
## V2 save tests (resume-mid-adventure Phase 1, P1.T1): area_index persists on
## save and out-of-range values clamp to the meadow on load. Split from
## test_save_game.gd, which sits at the lint cap of 20 public methods.

const TEMP_PATH := "user://test_save_game_v2_tmp.json"


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


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


# --- V2 area_index persist + clamp (P1.T1: FR-1, FR-4; AC-3 save side) --------


func test_to_dict_defaults_area_to_meadow() -> void:
	var payload := SaveGame.to_dict(_wallet_with(0), Wardrobe.new(), {})
	assert_eq(payload["version"], 2, "new saves stamp schema V2.")
	assert_eq(payload["area_index"], 0, "an omitted area saves as the meadow.")


func test_to_dict_persists_area_index() -> void:
	var payload := SaveGame.to_dict(_wallet_with(1), Wardrobe.new(), {}, 2)
	assert_eq(payload["area_index"], 2, "the sunset index survives packing.")
	var negative := SaveGame.to_dict(_wallet_with(1), Wardrobe.new(), {}, -1)
	assert_eq(negative["area_index"], 0, "a negative index packs as the meadow.")


func test_round_trip_preserves_area_index() -> void:
	SaveGame.clear(TEMP_PATH)
	var wardrobe := _wardrobe_wearing([Cosmetics.HAT_SPROUT], Cosmetics.HAT_SPROUT)
	assert_true(
		SaveGame.save_game(_wallet_with(5), wardrobe, _taken_flags(3), TEMP_PATH, 2),
		"saving mid-sunset succeeds."
	)
	var state := SaveGame.load_game(TEMP_PATH)
	assert_eq(state["area_index"], 2, "the area survives the restart.")
	assert_eq(state["wallet"], 5, "the wallet survives alongside the area.")
	SaveGame.clear(TEMP_PATH)


func test_out_of_range_area_clamps_to_meadow() -> void:
	for bad: int in [99, -1, 3]:
		_write_text(
			TEMP_PATH,
			(
				JSON
				. stringify(
					{
						"version": 2,
						"wallet": 0,
						"owned": [],
						"worn": "",
						"taken": {},
						"area_index": bad,
					}
				)
			)
		)
		assert_eq(
			SaveGame.load_game(TEMP_PATH)["area_index"],
			0,
			"area %d boots the meadow instead of crashing." % bad
		)
	_write_text(
		TEMP_PATH,
		(
			JSON
			. stringify(
				{
					"version": 2,
					"wallet": 0,
					"owned": [],
					"worn": "",
					"taken": {},
					"area_index": "cave",
				}
			)
		)
	)
	assert_eq(
		SaveGame.load_game(TEMP_PATH)["area_index"], 0, "a non-numeric area boots the meadow."
	)
	SaveGame.clear(TEMP_PATH)
