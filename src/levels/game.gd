class_name Game
extends Node
## The game root: owns the area index and swaps levels behind a palette fade.
##
## The flow a child experiences: collect 3 keys, walk into the door, the screen
## sinks into the sky they are leaving, the next area builds while the screen
## is covered, and the veil lifts out of the new sky. Gems are a lifetime score
## and survive every swap. After the last area the game celebrates first, then
## loops home to the meadow.

## Emitted after the new area is live.
signal area_changed(index: int)

## Emitted when the final door is entered, before the loop home begins.
signal celebrated

var area_index := 0
var builder: AreaBuilder
var transition: AreaTransition

## Session wallet: collected gems accumulate here and survive every swap
## (quitting to title keeps the balance); the balance is loaded from disk at
## boot and rewritten on every change (save_game_20261027 Phase 3).
var wallet: Wallet

## Session wardrobe: gifted looks accumulate here and survive every swap,
## exactly like the wallet (owned by the game root, borrowed by the area).
## Owned/worn looks are loaded from disk at boot and rewritten on change.
var wardrobe: Wardrobe

## Persistent ambient loop owner. The manager lives here (not in the builder)
## so area swaps crossfade instead of cutting: the builder is freed on every
## transition, but this node survives. Builders get a reference for ducking.
var audio_manager: AudioManager

## Hidden parent gate: a 3s stationary hold in the extreme top-right corner
## flushes the save and quits. Owned here so the flush sees the live
## session; the gate never consumes gameplay input and Esc stays inert.
var quit_hold: QuitHold

## Per-area gem-taken flags, keyed by area name. A collected gem stays
## collected on revisit: the rebuilt area pre-collects these indices. Loaded
## from disk at boot, rewritten with the wallet on every save.
var _taken: Dictionary = {}


func _ready() -> void:
	wallet = Wallet.new()
	wardrobe = Wardrobe.new()
	_restore_save()
	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	quit_hold = QuitHold.new()
	quit_hold.name = "QuitHold"
	add_child(quit_hold)
	quit_hold.save_flush = Callable(self, "_save")
	transition = AreaTransition.new()
	transition.name = "Transition"
	add_child(transition)
	transition.faded_out.connect(_swap_area)
	_build_area(area_index)
	wallet.changed.connect(_save)
	wardrobe.changed.connect(_save)


## Load-at-boot: refill the wallet, re-own the wardrobe in save order, pick
## up the gem-taken flags, and resume the saved area (already clamped to a
## valid index by SaveGame). A corrupt save boots fresh (see SaveGame).
func _restore_save() -> void:
	var state := SaveGame.load_game()
	area_index = int(state.get("area_index", 0))
	var balance := int(state.get("wallet", 0))
	if balance > 0:
		wallet.add(balance)
	var owned: Array = state.get("owned", [])
	for gift_id in owned:
		wardrobe.own(str(gift_id))
	var worn := str(state.get("worn", ""))
	if not worn.is_empty():
		wardrobe.wear(worn)
	_taken = (state.get("taken", {}) as Dictionary).duplicate(true)


## Progress autosave (FR-9): every wallet/wardrobe change and every area
## swap rewrites the file. Live gem flags are pulled from the builder first
## so a force-quit keeps the current area's collects too. The committed area
## index rides along so the next boot resumes here; the finale loop home
## rebuilds area 0 first, so it commits the meadow.
func _save(_changed: Variant = null) -> void:
	if wallet == null or wardrobe == null:
		return
	if builder != null:
		_taken[builder.area_name()] = builder.taken_flags()
	SaveGame.save_game(wallet, wardrobe, _taken, SaveGame.SAVE_PATH, area_index)


func _process(delta: float) -> void:
	if transition.is_running():
		transition.step(delta)


func _build_area(index: int) -> void:
	if builder != null:
		_taken[builder.area_name()] = builder.taken_flags()
		builder.queue_free()
		# queue_free() defers release, so drop the child now: the new area
		# must own the "Area" name and the old tree must not linger a frame.
		remove_child(builder)
	area_index = index
	builder = AreaBuilder.new()
	builder.name = "Area"
	add_child(builder)
	var layout := AreaLayout.all()[index]
	var flags: Array[bool] = []
	if _taken.has(layout.area_name):
		flags = _taken[layout.area_name]
	builder.build(layout, wallet, flags, wardrobe)
	builder.audio_manager = audio_manager
	# The loop follows the area: crossfades on every swap, including the
	# finale loop-home (which rebuilds area 0 and lands here too).
	audio_manager.switch_ambient(layout.area_name)
	builder.door.entered.connect(_on_door_entered)
	area_changed.emit(index)
	_save()


func _swap_area() -> void:
	_build_area((_area_count() + area_index + 1) % _area_count())


func _area_count() -> int:
	return AreaLayout.all().size()


func _on_door_entered(_door: Door) -> void:
	# The open door's sensor keeps overlapping Robo for a few frames after the
	# first entry; a second bump during the fade must not queue a second swap.
	if transition.is_running():
		return
	if area_index == _area_count() - 1:
		celebrated.emit()
		builder.robot.celebrate()
		# Sound-only: the finale flourish. Ducking lets it ring over the
		# meadow loop that follows on the loop-home rebuild.
		AudioFactory.play("celebrate")
		audio_manager.notify_sfx_played()
	transition.begin(_sky_of(area_index), _sky_of((_area_count() + area_index + 1) % _area_count()))


func _sky_of(index: int) -> Color:
	return Palettes.AREA_PALETTES[AreaLayout.all()[index].palette]["sky_top"]
