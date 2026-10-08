class_name Gem
extends Area2D
## Collectible gem: auto-collects on touch, respawns forever after a delay.
##
## Code-assembled per the Foundation pattern (no hand-authored scenes).
## Collection is pure joy: hide, wait, respawn, repeat — no counters here,
## the HUD owns the count.

signal collected(gem: Gem)
signal respawned(gem: Gem)

## Seconds a collected gem stays hidden. Injectable so tests run fast;
## production uses Tuning.GEM_RESPAWN_TIME.
var respawn_delay := Tuning.GEM_RESPAWN_TIME

var _sprite: Sprite2D
var _bob_time := 0.0
var _is_collected := false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetFactory.get_texture("gem", "meadow")
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)

	var timer := Timer.new()
	timer.name = "RespawnTimer"
	timer.one_shot = true
	timer.wait_time = respawn_delay
	timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(timer)

	body_entered.connect(_on_body_entered)


## Pure bob math: a slow sine around the gem's origin. Static so the HUD,
## tests, or future effects can share the same motion language.
static func bob_offset(time: float) -> float:
	return sin(time * Tuning.GEM_BOB_SPEED) * Tuning.GEM_BOB_AMPLITUDE


func update_bob(delta: float) -> void:
	_bob_time += delta
	_sprite.position.y = bob_offset(_bob_time)


func _process(delta: float) -> void:
	update_bob(delta)


func is_collected() -> bool:
	return _is_collected


## Collect the gem. Idempotent: repeated calls while hidden do nothing.
## Monitoring is disabled with set_deferred because collection can arrive
## from a physics callback (body_entered) where flushing is forbidden.
func collect() -> void:
	if _is_collected:
		return
	_is_collected = true
	_sprite.visible = false
	set_deferred("monitoring", false)
	var timer := get_node("RespawnTimer") as Timer
	timer.start(respawn_delay)
	collected.emit(self)


func _on_respawn_timer_timeout() -> void:
	_is_collected = false
	_sprite.visible = true
	set_deferred("monitoring", true)
	respawned.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collect()
