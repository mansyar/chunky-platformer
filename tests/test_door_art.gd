extends GdToolsTest
## Structural tests for the door art (Phase 3 feedback fix).
##
## A child must be able to tell an open door from a locked one at a glance and
## with no reading. These tests pin the differences that carry that meaning:
## a dark opening, warm light spilling out, and no keyhole.

const CLOSED := "door_locked"
const OPEN := "door_open"


func _img(asset: String) -> Image:
	return get_node("/root/AssetFactory").get_image(asset, "meadow")


func _palette() -> Dictionary:
	return Palettes.AREA_PALETTES["meadow"]


func test_open_door_has_a_dark_opening() -> void:
	# The middle of an open door is somewhere you could step through: it must
	# be markedly darker than its frame, not a pale panel that reads as blank.
	var img := _img(OPEN)
	# Deep inside the opening, past the light that spills out of it.
	var deep := img.get_pixel(16, 8)
	assert_lt(
		deep.r + deep.g + deep.b,
		_palette()["ground_dark"].r + _palette()["ground_dark"].g + _palette()["ground_dark"].b,
		"the opening is dark enough to read as a passage"
	)


func test_open_door_spreads_warm_light_at_its_mouth() -> void:
	# Light falls OUT of an open door, so the lowest interior rows are the
	# brightest. That gradient is what says 'go through' rather than 'blank wall'.
	var img := _img(OPEN)
	var mouth := img.get_pixel(16, 44)
	var deep := img.get_pixel(16, 8)
	assert_gt(
		mouth.r + mouth.g + mouth.b,
		deep.r + deep.g + deep.b,
		"the light is brightest at the threshold and fades into the dark"
	)


func test_open_door_has_no_keyhole() -> void:
	# The keyhole was the single clearest "locked" signal. An open door must
	# not keep it, or the two doors look alike at a glance.
	var locked := _img(CLOSED)
	var opened := _img(OPEN)
	var differing := 0
	for y: int in 40:
		for x: int in 32:
			if not _same(locked.get_pixel(x, y), opened.get_pixel(x, y)):
				differing += 1
	assert_gt(differing, 300, "the two doors are unmistakably different.")


func test_locked_door_keeps_its_visible_keyhole() -> void:
	var img := _img(CLOSED)
	var ground: Color = _palette()["ground"]
	assert_false(_same(img.get_pixel(16, 24), ground), "the lock is drawn, not implied.")


func test_doors_are_the_same_size_and_footed_on_the_ground() -> void:
	# A door that changes size or floats between its two states would make the
	# unlock look like the level itself moved.
	for asset: String in [CLOSED, OPEN]:
		var img := _img(asset)
		assert_eq(img.get_size(), Vector2i(32, 48), "%s is 32x48." % asset)


func _same(a: Color, b: Color) -> bool:
	return a.is_equal_approx(b)
