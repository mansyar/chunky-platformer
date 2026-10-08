extends GdToolsTest
## Tests for the screen-space gem counter (Phase 4).

const COUNTER_SCRIPT := "res://src/ui/gem_counter.gd"


func _counter() -> CanvasLayer:
	var counter: CanvasLayer = load(COUNTER_SCRIPT).new()
	add_child(counter)
	return counter


func _panel(counter: CanvasLayer) -> Control:
	return counter.find_child("Panel", true, false) as Control


func _icon(counter: CanvasLayer) -> Sprite2D:
	return counter.find_child("Icon", true, false) as Sprite2D


func _visible_digits(counter: CanvasLayer) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	for sprite: Node in counter.find_children("*", "Sprite2D", true, false):
		var digit := sprite as Sprite2D
		if digit != _icon(counter) and digit.visible:
			out.append(digit)
	return out


func test_counter_is_screen_space() -> void:
	var counter := _counter()
	assert_eq(counter.get_class(), "CanvasLayer", "counter lives on a CanvasLayer.")
	var panel := _panel(counter)
	assert_not_null(panel, "counter has a Control panel to anchor against.")
	assert_true(panel.anchor_right >= 1.0, "panel spans the full screen width.")
	assert_true(panel.anchor_bottom >= 1.0, "panel spans the full screen height.")


func test_fresh_counter_shows_no_digits() -> void:
	var counter := _counter()
	assert_eq(counter.count(), 0, "a fresh counter starts at zero.")
	assert_eq(_visible_digits(counter).size(), 0, "zero shows no digit sprites.")


func test_counter_uses_generated_art() -> void:
	var counter := _counter()
	assert_eq(
		_icon(counter).texture, AssetFactory.get_texture("gem", "meadow"), "icon is the gem art."
	)
	counter.set_count(3)
	var digits := _visible_digits(counter)
	assert_eq(digits.size(), 1, "one digit for a single-digit count.")
	assert_eq(
		digits[0].texture, AssetFactory.get_texture("digit_3"), "digit art matches the value."
	)


func test_increment_bump_scales_the_panel() -> void:
	var counter := _counter()
	var panel := _panel(counter)
	counter.increment()
	await get_tree().process_frame
	assert_ne(panel.scale, Vector2.ONE, "increment bumps the counter.")
	await get_tree().create_timer(Tuning.COUNTER_BUMP_TIME + 0.2).timeout
	assert_eq(panel.scale, Vector2.ONE, "the bump settles back.")


func test_one_digit_sprite_per_digit_of_the_count() -> void:
	var counter := _counter()
	counter.set_count(7)
	assert_eq(_visible_digits(counter).size(), 1, "7 is one digit.")
	counter.set_count(12)
	assert_eq(_visible_digits(counter).size(), 2, "12 is two digits.")
	counter.set_count(123)
	assert_eq(_visible_digits(counter).size(), 3, "123 is three digits.")


func test_digits_match_the_count_value() -> void:
	var counter := _counter()
	counter.set_count(24)
	var expected := ["digit_2", "digit_4"]
	var digits := _visible_digits(counter)
	for i: int in range(digits.size()):
		assert_eq(digits[i].texture, AssetFactory.get_texture(expected[i]), "digit %d matches." % i)


func test_count_only_grows() -> void:
	var counter := _counter()
	counter.set_count(9)
	counter.set_count(4)
	assert_eq(counter.count(), 9, "the counter never goes backwards.")


func test_counter_sits_in_the_top_left_corner() -> void:
	var counter := _counter()
	counter.set_count(12)
	var icon := _icon(counter)
	var digits := _visible_digits(counter)
	assert_lt(icon.global_position.x, 200.0, "icon sits near the left edge.")
	assert_lt(icon.global_position.y, 140.0, "icon sits near the top edge.")
	assert_gt(digits[0].global_position.x, icon.global_position.x, "digits follow the icon.")


func test_bump_retrigger_is_safe() -> void:
	var counter := _counter()
	counter.increment()
	counter.increment()
	counter.increment()
	await get_tree().create_timer(Tuning.COUNTER_BUMP_TIME + 0.2).timeout
	assert_eq(_panel(counter).scale, Vector2.ONE, "back-to-back bumps settle cleanly.")
