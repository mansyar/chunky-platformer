class_name PopEffect
extends Node2D
## Expanding ring + sparkle burst for collect/respawn moments.
##
## Pure visual: a Node2D that draws and self-frees. It owns no physics
## bodies, so juice can never push Robo around (toddler-safety rule).
## Sparkle placement is fully deterministic — same progress, same picture.

var _age := 0.0
var _color := Color.WHITE


## Spawn a one-shot pop effect at a world position. Returns the effect so
## callers (gem, HUD, tests) can inspect it if they want.
static func spawn(parent: Node, pos: Vector2, color: Color) -> PopEffect:
	var effect := PopEffect.new()
	effect.position = pos
	effect._color = color
	parent.add_child(effect)
	return effect


## Pure ring math: radius grows linearly over the effect's lifetime.
static func ring_radius(progress: float) -> float:
	return lerpf(Tuning.POP_START_RADIUS, Tuning.POP_END_RADIUS, progress)


## Pure sparkle math: a fixed ring of dots flying outward. Deterministic
## by design — no randomness anywhere in the juice.
static func sparkle_offsets(progress: float) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var dist := lerpf(2.0, Tuning.POP_END_RADIUS + 4.0, progress)
	for i: int in range(Tuning.SPARKLE_COUNT):
		var angle := TAU * float(i) / float(Tuning.SPARKLE_COUNT)
		offsets.append(Vector2.from_angle(angle) * dist)
	return offsets


func is_done() -> bool:
	return _age >= Tuning.POP_LIFETIME


## Advance the effect by hand (tests) or per frame (_process). A finished
## effect queues itself for deletion — juice must never linger.
func update_effect(delta: float) -> void:
	_age += delta
	if is_done():
		queue_free()
	else:
		queue_redraw()


func _process(delta: float) -> void:
	update_effect(delta)


func _draw() -> void:
	var progress := clampf(_age / Tuning.POP_LIFETIME, 0.0, 1.0)
	var alpha := 1.0 - progress
	draw_arc(Vector2.ZERO, ring_radius(progress), 0.0, TAU, 32, Color(_color, alpha), 3.0)
	for offset: Vector2 in sparkle_offsets(progress):
		draw_circle(offset, 3.0, Color(_color, alpha))
