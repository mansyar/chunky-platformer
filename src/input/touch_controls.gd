class_name TouchControls
extends CanvasLayer
## Big on-screen buttons for tiny thumbs. Drives the same Input Map actions
## the robot reads, so gameplay code never knows which device is in use.
## Auto-hides on keyboard/mouse/gamepad activity and reappears on touch.

const BUTTON_ART := {
	"move_left": "touch_left",
	"move_right": "touch_right",
	"jump": "touch_jump",
}
const BUTTON_SCALE := 4.0  # 24px art -> 96px on-screen


func _ready() -> void:
	_build_buttons()


func _build_buttons() -> void:
	var view := Vector2(1280, 720)
	var pad := 48.0
	var size := 24.0 * BUTTON_SCALE
	_spawn("move_left", Vector2(pad, view.y - size - pad))
	_spawn("move_right", Vector2(pad * 2.0 + size, view.y - size - pad))
	_spawn("jump", Vector2(view.x - size - pad, view.y - size - pad))


func _spawn(action: String, at: Vector2) -> void:
	var button := TouchScreenButton.new()
	button.texture_normal = AssetFactory.get_texture(BUTTON_ART[action])
	button.action = action
	button.scale = Vector2.ONE * BUTTON_SCALE
	button.position = at
	add_child(button)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		visible = true
	elif (
		event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventJoypadButton
		or event is InputEventJoypadMotion
	):
		visible = false
