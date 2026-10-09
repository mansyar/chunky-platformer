class_name Door
extends Area2D
## The way out of an area. Locked until all three keys are found, then open.
##
## A locked door is not an obstacle to overcome - it is a wall with a picture
## on it. It never buzzes, bounces or scolds a child who bumps into it. Once
## the goal is met it stops being solid and simply lets a child walk through,
## which is the only interaction it has.
##
## This entity owns no art of its own: the Foundation track already generated
## door_locked and door_open.

## Emitted once, when the last key unlocks it. The area transition listens.
signal unlocked(door: Door)

## Emitted when a child walks into an OPEN door. A locked door never emits it.
signal entered(door: Door)

## Area palette, set by the level before the door enters the tree.
var palette := "meadow"

var _sensor: CollisionShape2D
var _sprite: Sprite2D
var _solid: StaticBody2D
var _open := false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetFactory.get_texture("door_locked", palette)
	add_child(_sprite)

	# The blocking part is a StaticBody2D rather than a collision shape on this
	# Area2D, so "is the door solid" is literally "does this body exist" - and
	# opening the door is removing it, with no half-enabled state in between.
	_solid = StaticBody2D.new()
	_solid.name = "Solid"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 44)
	shape.shape = rect
	_solid.add_child(shape)
	add_child(_solid)

	_sensor = CollisionShape2D.new()
	_sensor.name = "Sensor"
	var sensor_shape := CircleShape2D.new()
	sensor_shape.radius = Tuning.KEY_PICKUP_RADIUS + 4.0
	_sensor.shape = sensor_shape
	add_child(_sensor)
	body_entered.connect(_on_body_entered)


func is_solid() -> bool:
	return not _open


## Called by the area whenever the key tally rises. Idempotent, so a repeated
## progress signal can never re-open or re-announce an open door.
func on_progress(keys_taken: int) -> void:
	if _open or keys_taken < AreaLayout.KEYS_PER_AREA:
		return
	_open = true
	_solid.queue_free()
	_solid = null
	_sprite.texture = AssetFactory.get_texture("door_open", palette)
	unlocked.emit(self)


func _on_body_entered(body: Node2D) -> void:
	# Overlap is not enough, and neither is "the door is open": a child has to
	# actually be a character who walked in.
	if _open and body is CharacterBody2D:
		entered.emit(self)
