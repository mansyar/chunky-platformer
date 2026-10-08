extends GdToolsTest
## Tests for the pixel-drawing DSL primitives (Foundation Phase 2).
##
## The DSL draws into Image buffers using deterministic, clipped operations.
## Every test asserts exact pixel colors on tiny (4x4) buffers so failures
## point at the precise primitive that misbehaves.

const RED := Color(1.0, 0.0, 0.0, 1.0)
const BLUE := Color(0.0, 0.0, 1.0, 1.0)
const HALF_ALPHA_GREEN := Color(0.0, 1.0, 0.0, 0.5)
const TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)


func _new_img(size: int = 4) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(TRANSPARENT)
	return img


# --- rect -------------------------------------------------------------------


func test_rect_fills_requested_region() -> void:
	var img := _new_img()
	PixelDsl.rect(img, Rect2i(1, 1, 2, 2), RED)
	assert_eq(img.get_pixel(1, 1), RED, "rect fills its interior (top-left).")
	assert_eq(img.get_pixel(2, 2), RED, "rect fills its interior (bottom-right).")
	assert_eq(img.get_pixel(0, 0), TRANSPARENT, "rect does not touch pixels outside the region.")
	assert_eq(img.get_pixel(3, 3), TRANSPARENT, "rect does not touch pixels outside the region.")


func test_rect_clips_out_of_bounds() -> void:
	var img := _new_img()
	# Region extends past all four edges; must not crash, must clip.
	PixelDsl.rect(img, Rect2i(-1, -1, 6, 6), RED)
	for x in range(4):
		for y in range(4):
			assert_eq(
				img.get_pixel(x, y), RED, "clipped rect covers whole image at (%d, %d)." % [x, y]
			)


func test_rect_with_zero_size_is_a_noop() -> void:
	var img := _new_img()
	PixelDsl.rect(img, Rect2i(1, 1, 0, 0), RED)
	assert_eq(img.get_pixel(1, 1), TRANSPARENT, "zero-size rect changes nothing.")


# --- disc -------------------------------------------------------------------


func test_disc_fills_pixels_within_radius() -> void:
	var img := _new_img()
	# Radius 1 disc centered at (1, 1): covers center + 4 neighbors,
	# corners (distance sqrt(2) > 1) stay transparent.
	PixelDsl.disc(img, Vector2i(1, 1), 1, BLUE)
	assert_eq(img.get_pixel(1, 1), BLUE, "disc fills its center.")
	assert_eq(img.get_pixel(0, 1), BLUE, "disc fills left neighbor.")
	assert_eq(img.get_pixel(2, 1), BLUE, "disc fills right neighbor.")
	assert_eq(img.get_pixel(1, 0), BLUE, "disc fills top neighbor.")
	assert_eq(img.get_pixel(1, 2), BLUE, "disc fills bottom neighbor.")
	assert_eq(img.get_pixel(0, 0), TRANSPARENT, "disc leaves corners outside radius transparent.")


func test_disc_clips_out_of_bounds() -> void:
	var img := _new_img()
	# Disc partially off the left/top edge; must not crash, must clip.
	PixelDsl.disc(img, Vector2i(0, 0), 2, BLUE)
	assert_eq(img.get_pixel(0, 0), BLUE, "clipped disc still paints in-bounds pixels.")
	assert_eq(img.get_pixel(1, 1), BLUE, "clipped disc still paints in-bounds pixels.")
	assert_eq(img.get_pixel(3, 3), TRANSPARENT, "clipped disc does not paint beyond its radius.")


# --- outline ----------------------------------------------------------------


func test_outline_draws_only_perimeter() -> void:
	var img := _new_img()
	PixelDsl.outline(img, Rect2i(0, 0, 3, 3), RED)
	assert_eq(img.get_pixel(0, 0), RED, "outline paints the corner.")
	assert_eq(img.get_pixel(1, 0), RED, "outline paints the top edge.")
	assert_eq(img.get_pixel(2, 2), RED, "outline paints the opposite corner.")
	assert_eq(img.get_pixel(1, 1), TRANSPARENT, "outline leaves the interior untouched.")


func test_outline_clips_out_of_bounds() -> void:
	var img := _new_img()
	# Outline starting off-canvas; only the visible part is drawn.
	PixelDsl.outline(img, Rect2i(-2, -2, 6, 6), RED)
	assert_eq(img.get_pixel(3, 0), RED, "clipped outline paints the visible right edge.")
	assert_eq(img.get_pixel(3, 3), RED, "clipped outline paints the visible bottom-right corner.")
	assert_eq(img.get_pixel(0, 0), TRANSPARENT, "clipped outline does not paint interior pixels.")


# --- shade ------------------------------------------------------------------


func test_shade_blends_instead_of_replacing() -> void:
	var img := _new_img()
	PixelDsl.rect(img, Rect2i(0, 0, 2, 2), BLUE)
	PixelDsl.shade(img, Rect2i(0, 0, 2, 2), HALF_ALPHA_GREEN)
	var blended := img.get_pixel(0, 0)
	assert_almost_eq(blended.r, 0.0, 0.01, "shade blends channels rather than replacing (red).")
	assert_almost_eq(blended.g, 0.5, 0.01, "shade blends channels rather than replacing (green).")
	assert_almost_eq(blended.b, 0.5, 0.01, "shade blends channels rather than replacing (blue).")
	assert_almost_eq(blended.a, 1.0, 0.01, "shade over an opaque base stays opaque.")


func test_shade_on_transparent_pixels() -> void:
	var img := _new_img()
	PixelDsl.shade(img, Rect2i(0, 0, 2, 2), HALF_ALPHA_GREEN)
	var pixel := img.get_pixel(0, 0)
	assert_eq(pixel.r, 0.0, "shade over transparent keeps overlay color (red).")
	assert_almost_eq(
		pixel.g,
		1.0,
		0.01,
		"straight-alpha blend over transparent keeps full overlay color (green)."
	)
	assert_almost_eq(pixel.a, 0.5, 0.01, "shade over transparent yields overlay alpha.")


func test_shade_clips_out_of_bounds() -> void:
	var img := _new_img()
	# Must not crash when the region leaves the image.
	PixelDsl.shade(img, Rect2i(-2, -2, 8, 8), HALF_ALPHA_GREEN)
	var pixel := img.get_pixel(2, 2)
	assert_almost_eq(pixel.a, 0.5, 0.01, "clipped shade covers in-bounds pixels.")
