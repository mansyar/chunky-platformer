extends GdToolsTest
## Tests for the follow camera (Movement Phase 5).
##
## follow(delta) is frame-steppable: it eases the camera toward its target
## with exponential smoothing and clamps the result inside the level bounds
## (minus the half-view), so the viewport edge never leaves the world.

const VIEW_HALF := Vector2(160, 90)  # world-space half-view at 4x scale
const BOUNDS := Rect2(0, 0, 640, 360)  # ~2 screens wide, 2 screens tall


func _camera() -> Camera2D:
	var camera: Camera2D = load("res://src/world/follow_camera.gd").new()
	camera.view_half = VIEW_HALF
	camera.set_bounds(BOUNDS)
	return camera


func _targeted(camera: Camera2D, at: Vector2) -> Node2D:
	var target: Node2D = Node2D.new()
	target.position = at
	camera.target = target
	return target


# --- follow behavior ---


func test_camera_eases_toward_target() -> void:
	var camera: Camera2D = _camera()
	var target: Node2D = _targeted(camera, Vector2(320, 180))
	camera.follow(0.016)
	var dist_after := camera.position.distance_to(target.position)
	assert_lt(dist_after, Vector2(320, 180).length(), "the camera moved toward the target.")
	assert_gt(dist_after, 0.0, "the camera eases rather than snapping.")


func test_camera_converges_on_target() -> void:
	var camera: Camera2D = _camera()
	var target: Node2D = _targeted(camera, Vector2(320, 180))
	for _i: int in 200:
		camera.follow(1.0 / 60.0)
	assert_almost_eq(camera.position.x, 320.0, 1.0, "camera settles on the target x.")
	assert_almost_eq(camera.position.y, 180.0, 1.0, "camera settles on the target y.")


func test_camera_follows_both_axes() -> void:
	var camera: Camera2D = _camera()
	var target: Node2D = _targeted(camera, Vector2(200, 260))
	for _i: int in 200:
		camera.follow(1.0 / 60.0)
	assert_almost_eq(camera.position.x, 200.0, 1.0, "x follows.")
	assert_almost_eq(camera.position.y, 260.0, 1.0, "y follows.")


# --- bounds clamping ---


func test_camera_clamps_at_level_edges() -> void:
	var camera: Camera2D = _camera()
	var target: Node2D = _targeted(camera, Vector2(5000, 5000))
	for _i: int in 400:
		camera.follow(1.0 / 60.0)
	# With a 640x360 world and a 320x180 view, the center can never pass
	# (480, 270) — the viewport edge stays inside the world.
	assert_almost_eq(camera.position.x, 480.0, 0.5, "camera clamps at the right edge.")
	assert_almost_eq(camera.position.y, 270.0, 0.5, "camera clamps at the bottom edge.")


func test_camera_clamps_when_target_at_corner() -> void:
	var camera: Camera2D = _camera()
	var target: Node2D = _targeted(camera, Vector2(0, 0))
	for _i: int in 400:
		camera.follow(1.0 / 60.0)
	assert_almost_eq(camera.position.x, 160.0, 0.5, "camera clamps at the left edge.")
	assert_almost_eq(camera.position.y, 90.0, 0.5, "camera clamps at the top edge.")


func test_camera_without_bounds_never_clamps() -> void:
	var camera: Camera2D = _camera()
	camera.set_bounds(Rect2())
	var target: Node2D = _targeted(camera, Vector2(5000, 5000))
	for _i: int in 400:
		camera.follow(1.0 / 60.0)
	assert_almost_eq(camera.position.x, 5000.0, 1.0, "unbounded levels let the camera roam.")
