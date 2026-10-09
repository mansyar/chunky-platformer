extends GdToolsTest
## Tests for the key counter badge (Phase 2).
##
## The badge sits beside the gem counter and reads "how many of the three keys
## do I have left to find". It must be legible at a glance and must never show
## a number that is not a subset of the keys the child has actually taken.

const COUNTER_SCRIPT := "res://src/ui/key_counter.gd"


func _counter() -> KeyCounter:
	var counter: KeyCounter = load(COUNTER_SCRIPT).new()
	counter.palette = "meadow"
	add_child(counter)
	return counter


func _panel(counter: KeyCounter) -> Control:
	return counter.find_child("Panel", true, false) as Control


func _icon(counter: KeyCounter) -> Sprite2D:
	return counter.find_child("Icon", true, false) as Sprite2D


func _visible_digits(counter: KeyCounter) -> Array[Sprite2D]:
	var digits: Array[Sprite2D] = []
	for child: Node in _panel(counter).get_children():
		if child is Sprite2D and child.name != "Icon" and child.visible:
			digits.append(child as Sprite2D)
	return digits


func _digit_count(counter: KeyCounter) -> int:
	return _visible_digits(counter).size()


func test_counter_starts_empty() -> void:
	var counter := _counter()
	assert_eq(counter.count(), 0, "no keys yet.")
	assert_eq(_digit_count(counter), 0, "and no digits shown.")


func test_counter_shows_the_key_icon() -> void:
	assert_eq(
		_icon(_counter()).texture,
		AssetFactory.get_texture("key", "meadow"),
		"the badge is marked with a key."
	)


func test_counter_counts_up_to_three() -> void:
	var counter := _counter()
	for expected: int in [1, 2, 3]:
		counter.set_count(expected)
		assert_eq(counter.count(), expected, "count %d is shown." % expected)
		assert_eq(_digit_count(counter), 1, "%d is a single digit." % expected)


func test_counter_reuses_digit_textures() -> void:
	var counter := _counter()
	counter.set_count(3)
	var digits := _visible_digits(counter)
	assert_eq(digits[0].texture, AssetFactory.get_texture("digit_3", "meadow"), "the '3' glyph.")


func test_counter_never_counts_down() -> void:
	# Keys are permanent, so the badge is monotonic. A drop would tell a child
	# they had lost something, which is exactly the kind of lie this game must
	# never tell.
	var counter := _counter()
	counter.set_count(3)
	counter.set_count(1)
	assert_eq(counter.count(), 3, "the badge holds at 3.")


func test_counter_never_exceeds_the_area_goal() -> void:
	var counter := _counter()
	counter.set_count(9)
	assert_eq(counter.count(), AreaLayout.KEYS_PER_AREA, "capped at the goal.")


func test_counter_bumps_on_change() -> void:
	var counter := _counter()
	counter.set_count(1)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_ne(
		_panel(counter).scale,
		Vector2.ONE,
		"the badge pulses when a key lands, like the gem counter."
	)


func test_counter_sits_below_the_gem_counter_in_the_corner() -> void:
	var counter := _counter()
	var icon := _icon(counter)
	assert_lt(icon.global_position.x, 200, "in the top-left corner.")
	assert_gt(icon.global_position.y, 60, "below the gem counter badge.")
	assert_lt(icon.global_position.y, 400, "and well clear of the bottom UI.")


func test_counter_and_gem_counter_do_not_overlap() -> void:
	# Two badges stacked in one corner must not collide, and their baselines
	# must line up so the block reads as one tidy panel.
	var gems := GemCounter.new()
	gems.palette = "meadow"
	add_child(gems)
	var keys := _counter()
	gems.set_count(12)
	keys.set_count(3)
	var gem_bottom: float = (gems.find_child("Icon", true, false) as Sprite2D).global_position.y
	var key_bottom: float = _icon(keys).global_position.y
	assert_gt(key_bottom, gem_bottom, "the key badge sits clearly below the gem badge.")
	var gem_height := _icon_size(gems)
	var key_height := _icon_size(keys)
	assert_almost_eq(key_height, gem_height, 0.01, "both badges use the same icon scale.")


func test_counter_tints_itself_to_its_area() -> void:
	var counter := KeyCounter.new()
	counter.palette = "cave"
	add_child(counter)
	assert_eq(
		_icon(counter).texture,
		AssetFactory.get_texture("key", "cave"),
		"a cave badge shows a cave key."
	)


func _icon_size(counter: CanvasLayer) -> float:
	var icon := counter.find_child("Icon", true, false) as Sprite2D
	return icon.texture.get_height() * icon.scale.y
