class_name FollowCamera
extends Camera2D
## Smooth two-axis follow camera clamped to the level bounds. Lives inside
## the scaled world node, so its coordinates are world pixels and the view
## covers view_half * 2 of them. The clamp uses the same bounds as the
## invisible edge walls: the viewport edge never leaves the world.

var target: Node2D
var view_half := Vector2(160, 90)
var _bounds := Rect2()


func set_bounds(rect: Rect2) -> void:
	# An empty rect disables clamping (unbounded levels / tests).
	_bounds = rect


func follow(delta: float) -> void:
	if target == null:
		return
	# Frame-rate-independent exponential smoothing.
	var weight := 1.0 - exp(-Tuning.CAMERA_SMOOTHING * delta)
	position = position.lerp(target.position, weight)
	if _bounds.size != Vector2.ZERO:
		position.x = clampf(
			position.x, _bounds.position.x + view_half.x, _bounds.end.x - view_half.x
		)
		position.y = clampf(
			position.y, _bounds.position.y + view_half.y, _bounds.end.y - view_half.y
		)


func _physics_process(delta: float) -> void:
	follow(delta)
