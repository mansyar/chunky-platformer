class_name Trampoline
extends Area2D
## Auto-bounce pad: launches any body that falls onto it from above.
## Side and bottom contacts do nothing; horizontal momentum is preserved,
## and every landing bounces again (endless fun, zero frustration).


func _ready() -> void:
	# Default pad: one tile wide, a shallow strip along its top so Robo
	# triggers the bounce by touching the surface, not the sides.
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)  # top strip at the body's origin
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var character := body as CharacterBody2D
	if character == null:
		return
	bounce(character)


func bounce(character: CharacterBody2D) -> void:
	# Only rising bodies are ignored: entering while moving up (e.g. jumping
	# past the pad) must not steal Robo's jump. Falling, landing, and simply
	# standing on the pad all bounce — standing on a trampoline should feel
	# like standing on a trampoline.
	if character.velocity.y < 0.0:
		return
	character.velocity.y = -Tuning.BOUNCE_IMPULSE
	# Sound-only: a soft boing on the auto-impulse. The factory voice cap
	# keeps mashing polyphonic without clipping; physics above is untouched.
	AudioFactory.play("bounce")
