class_name Key
extends Area2D
## A collectable that never comes back.
##
## Like a Gem (fixed budget since gem_shop_20261027), a key is permanent. That
## single rule is what makes the goal loop trustworthy - the door can never
## strand a child on an unwinnable area because the key they already carried
## is still in their pocket.
##
## Keys bob so a child can spot them across a room, and are picked up on
## touch because a 4-year-old has no patience for a button prompt.

signal taken(key: Key)

## Area palette, set by the level before the key enters the tree.
var palette := "meadow"

var _sprite: Sprite2D
var _taken := false
var _time := 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetFactory.get_texture("key", palette)
	add_child(_sprite)
	var sensor := CollisionShape2D.new()
	sensor.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = Tuning.KEY_PICKUP_RADIUS
	sensor.shape = circle
	add_child(sensor)
	body_entered.connect(_on_body_entered)


## Pure, deterministic and bounded, so a key can never drift out of the cell
## its layout gave it. Same contract as Gem.bob_offset.
static func bob_offset(time: float) -> float:
	return sin(time * Tuning.KEY_BOB_SPEED) * Tuning.KEY_BOB_AMPLITUDE


## The bob plus a soft glow: a key is the one thing in an area that MUST be
## noticed, so it breathes as well as bobs.
func update_bob(time: float) -> void:
	_sprite.position.y = bob_offset(time)
	_sprite.modulate = Color(1, 1, 1).lerp(Tuning.KEY_GLOW_TINT, Tuning.KEY_GLOW_DEPTH)


func _process(delta: float) -> void:
	_time += delta
	if not _taken:
		update_bob(_time)


func is_taken() -> bool:
	return _taken


## Idempotent: a child standing on a key cannot bank it twice.
func take() -> void:
	if _taken:
		return
	_taken = true
	_sprite.visible = false
	taken.emit(self)


func _on_body_entered(body: Node2D) -> void:
	# Overlap is not enough - a world object brushing a key must not swallow it.
	if body is CharacterBody2D:
		take()
