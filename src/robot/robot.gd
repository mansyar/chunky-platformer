class_name Robot
extends CharacterBody2D
## Robo, the toddler-safe explorer. Code-assembled per the Foundation
## pattern (no hand-authored scenes). Phase 1 delivers horizontal movement
## and facing state; jump/gravity arrive in Phase 2, the sprite in Phase 3.
##
## move_axis() is the pure ramp math (unit-tested without physics frames);
## _physics_process only wires input to it and applies collisions.

var facing := 1


func _ready() -> void:
	_build_collision()


func _build_collision() -> void:
	# A slim box leaves the 32px art forgiving: Robo brushes past ledges
	# instead of catching pixel-perfect edges.
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 28)
	shape.shape = rect
	add_child(shape)


func move_axis(axis: float, delta: float) -> void:
	var step := Tuning.WALK_SPEED * delta / Tuning.ACCEL_TIME
	velocity.x = move_toward(velocity.x, axis * Tuning.WALK_SPEED, step)
	if axis != 0.0:
		facing = 1 if axis > 0.0 else -1


func _physics_process(delta: float) -> void:
	# The Input Map is configured declaratively in the Input Layer phase;
	# guard until then so headless tests never touch missing actions.
	if not InputMap.has_action("move_left") or not InputMap.has_action("move_right"):
		return
	move_axis(Input.get_axis("move_left", "move_right"), delta)
	move_and_slide()
