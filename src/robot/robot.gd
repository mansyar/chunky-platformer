class_name Robot
extends CharacterBody2D
## Robo, the toddler-safe explorer. Code-assembled per the Foundation
## pattern (no hand-authored scenes).
##
## move_axis()/update_jump()/update_gravity() are pure ramp math (unit-tested
## without physics frames); _physics_process only wires input to them and
## applies collisions. The step-assist hop makes low ledges climbable
## hands-free (toddler anti-frustration rule).

var facing := 1
var _coyote_left := 0.0
var _buffer_left := 0.0
var _sprite: AnimatedSprite2D
var _was_on_floor := true  # Robo spawns standing; a real jump still squashes on landing
var _land_left := 0.0


func _ready() -> void:
	_build_collision()
	_build_sprite()


func _build_collision() -> void:
	# A slim box leaves the 32px art forgiving: Robo brushes past ledges
	# instead of catching pixel-perfect edges.
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 28)
	shape.shape = rect
	add_child(shape)


func _build_sprite() -> void:
	var frames := SpriteFrames.new()
	_add_anim(frames, "idle", ["robot_idle_0", "robot_idle_1"], Tuning.IDLE_ANIM_FPS, true)
	_add_anim(
		frames,
		"walk",
		["robot_walk_0", "robot_walk_1", "robot_walk_2", "robot_walk_3"],
		Tuning.WALK_ANIM_FPS,
		true
	)
	_add_anim(frames, "jump", ["robot_jump"], 1.0, false)
	_add_anim(frames, "land", ["robot_land"], 1.0, false)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	# Feet of the 32px art must meet the 28px collider bottom.
	_sprite.offset = Vector2(0, -2)
	_sprite.play("idle")
	add_child(_sprite)


func _add_anim(
	frames: SpriteFrames, anim: String, texture_names: Array[String], fps: float, loops: bool
) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loops)
	for texture_name: String in texture_names:
		frames.add_frame(anim, AssetFactory.get_texture(texture_name))


func update_animation(delta: float, on_floor: bool, moving: bool) -> void:
	# State machine: airborne jump pose, a short squash right after landing,
	# then walk or idle. Facing mirrors the sprite every frame.
	if on_floor and not _was_on_floor:
		_land_left = Tuning.LAND_SQUASH_TIME
	_land_left = maxf(_land_left - delta, 0.0)
	_was_on_floor = on_floor
	var anim := "jump"
	if on_floor:
		if _land_left > 0.0:
			anim = "land"
		elif moving:
			anim = "walk"
		else:
			anim = "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	_sprite.flip_h = facing < 0


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
	# A negative velocity.y (step-assist hop) must survive the floor zeroing
	# on its launch frame, so only resting/falling bodies are zeroed.
	if on_floor and velocity.y >= 0.0:
		velocity.y = 0.0
		return
	velocity.y = minf(velocity.y + Tuning.GRAVITY * delta, Tuning.FALL_SPEED_CAP)


func _try_step_assist(direction: float) -> void:
	# Walking into a low ledge (up to ~2 tiles) while holding a direction
	# hops Robo onto it automatically: staircases need zero jump precision.
	if direction == 0.0 or not is_on_floor():
		return
	var hit_wall := false
	for i: int in get_slide_collision_count():
		if absf(get_slide_collision(i).get_normal().x) > 0.7:
			hit_wall = true
			break
	if not hit_wall:
		return
	# Probe the space a ledge-height above Robo: if that spot is free and
	# moving forward there is unobstructed, the ledge is low enough to hop.
	var lifted := global_transform.translated(Vector2(0, -Tuning.STEP_UP_MAX_LEDGE))
	if test_move(lifted, Vector2(0, -2.0)):
		return  # no headroom above
	if test_move(lifted, Vector2(direction * 6.0, 0.0)):
		return  # the ledge is too tall
	velocity.y = -Tuning.STEP_UP_BOOST


func _physics_process(delta: float) -> void:
	# The Input Map is configured declaratively in the Input Layer phase;
	# guard until then so headless tests never touch missing actions.
	if not InputMap.has_action("move_left") or not InputMap.has_action("move_right"):
		return
	var axis := Input.get_axis("move_left", "move_right")
	# Step assist probes LAST frame's slide collisions and may launch a hop;
	# it must run before gravity so the boost is not zeroed on the floor.
	_try_step_assist(axis)
	var on_floor := is_on_floor()
	var jump_pressed := InputMap.has_action("jump") and Input.is_action_just_pressed("jump")
	update_gravity(delta, on_floor)
	update_jump(delta, on_floor, jump_pressed)
	move_axis(axis, delta)
	update_animation(delta, on_floor, absf(velocity.x) > 1.0)
	move_and_slide()
