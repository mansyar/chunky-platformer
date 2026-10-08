class_name PixelDsl
## Static drawing primitives that paint deterministically into Image buffers.
##
## All operations clip to the image bounds: out-of-range coordinates are
## ignored rather than raising errors, so asset generators can draw freely
## without bounds math. Operations replace pixels; `shade` blends instead.


static func rect(img: Image, region: Rect2i, color: Color) -> void:
	var clipped := region.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for x in range(clipped.position.x, clipped.end.x):
		for y in range(clipped.position.y, clipped.end.y):
			img.set_pixel(x, y, color)


static func disc(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var min_corner := center - Vector2i(radius, radius)
	var max_corner := center + Vector2i(radius, radius)
	var radius_sq := radius * radius
	for x in range(maxi(min_corner.x, 0), mini(max_corner.x + 1, img.get_width())):
		for y in range(maxi(min_corner.y, 0), mini(max_corner.y + 1, img.get_height())):
			var offset := Vector2i(x, y) - center
			if offset.length_squared() <= radius_sq:
				img.set_pixel(x, y, color)


static func outline(img: Image, region: Rect2i, color: Color) -> void:
	if region.size.x <= 0 or region.size.y <= 0:
		return
	# Top and bottom edges span the full width.
	rect(img, Rect2i(region.position, Vector2i(region.size.x, 1)), color)
	rect(
		img,
		Rect2i(
			Vector2i(region.position.x, region.end.y - 1),
			Vector2i(region.size.x, 1),
		),
		color
	)
	# Side edges span the interior rows only (avoids double-painting corners).
	if region.size.y >= 2:
		rect(
			img,
			Rect2i(
				Vector2i(region.position.x, region.position.y + 1),
				Vector2i(1, region.size.y - 2),
			),
			color
		)
		rect(
			img,
			Rect2i(
				Vector2i(region.end.x - 1, region.position.y + 1),
				Vector2i(1, region.size.y - 2),
			),
			color
		)


static func shade(img: Image, region: Rect2i, color: Color) -> void:
	var clipped := region.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for x in range(clipped.position.x, clipped.end.x):
		for y in range(clipped.position.y, clipped.end.y):
			img.set_pixel(x, y, img.get_pixel(x, y).blend(color))
