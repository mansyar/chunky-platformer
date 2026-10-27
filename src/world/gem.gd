class_name Gem
extends Area2D
## Collectible gem: auto-collects on touch, stays collected (no respawn).
##
## Code-assembled per the Foundation pattern (no hand-authored scenes).
## Each area holds a fixed set of gems (see AreaLayout.GEMS_PER_AREA);
## a collected gem never comes back — not on a timer, not on revisit.
## The per-area taken flags live in the game root; the wallet owns the count.

signal collected(gem: Gem)

## Area palette, set by the level before the gem enters the tree. Gems tint
## themselves to their own area - the cave's purple gems must not be meadow
## yellow.
var palette := "meadow"

## Index into the layout's gem_spots, assigned by the builder so the game
## root can record per-area taken flags.
var gem_id := -1

var _sprite: Sprite2D
var _bob_time := 0.0
var _is_collected := false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetFactory.get_texture("gem", palette)
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = Tuning.GEM_PICKUP_RADIUS
	shape.shape = circle
	add_child(shape)

	if _is_collected:
		_sprite.visible = false

	body_entered.connect(_on_body_entered)


## Pure bob math: a slow sine around the gem's origin. Static so the HUD,
## tests, or future effects can share the same motion language.
static func bob_offset(time: float) -> float:
	return sin(time * Tuning.GEM_BOB_SPEED) * Tuning.GEM_BOB_AMPLITUDE


func update_bob(delta: float) -> void:
	_bob_time += delta
	if _sprite != null:
		_sprite.position.y = bob_offset(_bob_time)


func _process(delta: float) -> void:
	update_bob(delta)


func is_collected() -> bool:
	return _is_collected


## Collect the gem. Idempotent: repeated calls while hidden do nothing.
## There is no respawn — the art stays hidden until the area is rebuilt
## with fresh taken flags (a revisit keeps the taken flags, so zero restore).
func collect() -> void:
	if _is_collected:
		return
	_is_collected = true
	if _sprite != null:
		_sprite.visible = false
	collected.emit(self)


## Mark the gem pre-collected before it enters the tree (revisit path).
## No signal is emitted: nothing was earned, the gem simply stays hidden.
func start_collected() -> void:
	_is_collected = true
	if _sprite != null:
		_sprite.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collect()
