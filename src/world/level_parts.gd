class_name LevelParts
## Static builders for level construction pieces. The playground level and
## the test suites share one implementation so layout helpers stay honest.


## A floor-only platform: bodies rise through from below and always land on
## top. No drop-through input exists — falls only happen by walking off.
static func one_way_platform(width: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 8)
	shape.shape = rect
	shape.position = Vector2(0, 4)  # top surface sits at the body's origin
	shape.one_way_collision = true
	# Empirical 4.7 semantics: the direction points at the blocked side, so
	# the default (0, 1) = solid from above. Explicit for clarity: Robo lands
	# on top and jumps through from below.
	shape.one_way_collision_direction = Vector2(0, 1)
	body.add_child(shape)
	return body


## An invisible boundary wall. The camera clamps to the same bounds, so
## Robo can never see beyond the world edge.
static func edge_wall(height: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, height)
	shape.shape = rect
	body.add_child(shape)
	return body
