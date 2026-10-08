class_name Robot
extends CharacterBody2D
## Robo, the toddler-safe explorer. Code-assembled per the Foundation
## pattern (no hand-authored scenes). Phase 1 delivers horizontal movement
## and facing state; jump/gravity arrive in Phase 2, the sprite in Phase 3.
##
## move_axis() is the pure ramp math (unit-tested without physics frames);
## _physics_process only wires input to it and applies collisions.

var facing := 1
var _coyote_left := 0.0
var _buffer_left := 0.0


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


func update_jump(delta: float, on_floor: bool, jump_just_pressed: bool) -> void:
	# Grace timers: coyote forgives walking off an edge, the buffer forgives
	# pressing a hair early. A launch consumes both so only one jump happens.
	_coyote_left = Tuning.COYOTE_TIME if on_floor else maxf(_coyote_left - delta, 0.0)
	_buffer_left = Tuning.JUMP_BUFFER if jump_just_pressed else maxf(_buffer_left - delta, 0.0)
	if _buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = -Tuning.JUMP_IMPULSE
		_coyote_left = 0.0
		_buffer_left = 0.0


func update_gravity(delta: float, on_floor: bool) -> void:
	# Gentler-than-default gravity with a terminal cap: long falls stay
	# floaty and never feel scary (toddler anti-frustration rule).
	if on_floor:
		velocity.y = 0.0
		return
	velocity.y = minf(velocity.y + Tuning.GRAVITY * delta, Tuning.FALL_SPEED_CAP)


func _physics_process(delta: float) -> void:
	# The Input Map is configured declaratively in the Input Layer phase;
	# guard until then so headless tests never touch missing actions.
	if not InputMap.has_action("move_left") or not InputMap.has_action("move_right"):
		return
	var on_floor := is_on_floor()
	var jump_pressed := InputMap.has_action("jump") and Input.is_action_just_pressed("jump")
	update_gravity(delta, on_floor)
	update_jump(delta, on_floor, jump_pressed)
	move_axis(Input.get_axis("move_left", "move_right"), delta)
	move_and_slide()
