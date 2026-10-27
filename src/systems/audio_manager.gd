class_name AudioManager
extends Node
## Ambient loop playback helper (Audio track P2).
##
## NOT an autoload: game code instantiates one manager and adds it to the
## tree, and _process then ticks crossfades once per frame. Three gentle
## per-area loops (see Tuning.AUDIO_AMBIENT) pre-generate once as
## loop-enabled 8-bit mono AudioStreamWAV buffers and stay cached, so repeat
## switches never regenerate. Area changes crossfade over
## Tuning.AUDIO_CROSSFADE_TIME through two reused players (never more, never
## leaked); a mid-fade switch supersedes cleanly from current volumes with no
## hard cut. One-shots duck the loop by Tuning.AUDIO_DUCK_DB through
## duck_ambient() (sticky) or notify_sfx_played() (auto-restores after
## Tuning.AUDIO_DUCK_TIME). Unknown or empty area names fall back to the
## meadow loop; calls outside the scene tree update logical state but play
## nothing, so headless / dummy drivers never crash.

const _SILENCE_DB := -80.0

var _ambient_cache := {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current_area := ""
var _target_area := ""
var _fading := false
var _fade_t := 0.0
var _fade_start_out := -80.0
var _ducked := false
var _duck_time_left := 0.0


func _ready() -> void:
	warm_ambient()
	_ensure_players()


## Pre-generates every ambient loop once; repeat calls reuse the cache.
func warm_ambient() -> void:
	for area_name in Tuning.AUDIO_AMBIENT_NAMES:
		if not _ambient_cache.has(area_name):
			_ambient_cache[area_name] = _synthesize_ambient(area_name)


## True when a loop is cached for this area (unknown names read false).
func has_ambient(area_name: String) -> bool:
	return _ambient_cache.has(area_name)


## Returns the cached loop for an area; unknown or empty names fall back to
## the meadow loop. Warms on demand, so it never returns null afterwards.
func get_ambient(area_name: String) -> AudioStreamWAV:
	if _ambient_cache.is_empty():
		warm_ambient()
	return _ambient_cache.get(_resolve_area(area_name)) as AudioStreamWAV


## Logical names of all cached loops, in tuning order.
func ambient_names() -> Array[String]:
	var names: Array[String] = []
	for area_name in Tuning.AUDIO_AMBIENT_NAMES:
		if _ambient_cache.has(area_name):
			names.append(area_name)
	return names


## How many loops are cached (3 once warmed).
func ambient_cache_size() -> int:
	return _ambient_cache.size()


## Deterministic snapshot summary of one loop for assert_snapshot pins:
## byte length, checksum, leading bytes, peak deviation from silence, and
## the loop points. Returns an empty Dictionary for unknown names.
func ambient_signature(area_name: String) -> Dictionary:
	if not _ambient_cache.has(area_name):
		return {}
	var stream: AudioStreamWAV = _ambient_cache.get(area_name) as AudioStreamWAV
	var bytes := stream.data
	var checksum := 0
	var peak := 0
	for b in bytes:
		checksum = (checksum + b) % 1000003
		peak = maxi(peak, absi(b - 128))
	var head: Array[int] = []
	for i in mini(8, bytes.size()):
		head.append(bytes[i])
	return {
		"name": area_name,
		"bytes": bytes.size(),
		"checksum": checksum,
		"head": head,
		"peak": peak,
		"loop_mode": stream.loop_mode,
		"loop_end": stream.loop_end,
	}


## Area currently playing; "" before the first switch.
func current_area() -> String:
	return _current_area


## Area the in-flight crossfade is heading to ("" when idle).
func target_area() -> String:
	return _target_area


## True while a crossfade is still blending.
func is_fading() -> bool:
	return _fading


## True while the loop is ducked under SFX.
func is_ducked() -> bool:
	return _ducked


## How many ambient players exist (2 once ready in the tree).
func player_count() -> int:
	return _players.size()


## The stream on the active player (null before the first switch).
func active_stream() -> AudioStreamWAV:
	if _players.is_empty():
		return null
	return _players[_active].stream as AudioStreamWAV


## Volume of the active player in dB (silence floor before players exist).
func active_volume_db() -> float:
	if _players.is_empty():
		return _SILENCE_DB
	return _players[_active].volume_db


## Volume of one loop player by index (silence floor for bad indexes).
func player_volume(index: int) -> float:
	if index < 0 or index >= _players.size():
		return _SILENCE_DB
	return _players[index].volume_db


## The mix target the loop rests at (duck-aware), in dB.
func target_volume_db() -> float:
	return _target_db()


## Crossfades to an area's loop (unknown names read as meadow). The first
## switch starts directly at target volume; later switches overlap outgoing
## + incoming for AUDIO_CROSSFADE_TIME. A mid-fade call supersedes from the
## current volumes — the same two players are reused, never leaked. Outside
## the scene tree only the logical area updates (safe no-play).
func switch_ambient(area_name: String) -> void:
	if _ambient_cache.is_empty():
		warm_ambient()
	var area := _resolve_area(area_name)
	if area == _current_area and not _fading:
		return
	if area == _target_area and _fading:
		return
	_target_area = area
	_ensure_players()
	if _players.is_empty():
		_current_area = area
		_fading = false
		return
	var incoming: AudioStreamPlayer = _players[1 - _active]
	var outgoing: AudioStreamPlayer = _players[_active]
	incoming.stop()
	incoming.stream = _ambient_cache.get(area) as AudioStreamWAV
	if outgoing.stream == null:
		_active = 1 - _active
		incoming.volume_db = _target_db()
		incoming.play()
		_current_area = area
		_fading = false
		return
	_fade_start_out = outgoing.volume_db
	_fade_t = 0.0
	_fading = true
	incoming.volume_db = _SILENCE_DB
	incoming.play()


## Steps the loop back by AUDIO_DUCK_DB until restore_ambient().
func duck_ambient() -> void:
	_ducked = true
	_duck_time_left = 0.0
	_apply_rest_volume()


## Restores the loop to its full mix volume.
func restore_ambient() -> void:
	_ducked = false
	_duck_time_left = 0.0
	_apply_rest_volume()


## Ducks for one SFX hit, then auto-restores after AUDIO_DUCK_TIME.
func notify_sfx_played() -> void:
	_ducked = true
	_duck_time_left = Tuning.AUDIO_DUCK_TIME
	_apply_rest_volume()


func _process(delta: float) -> void:
	if _duck_time_left > 0.0:
		_duck_time_left -= delta
		if _duck_time_left <= 0.0:
			_duck_time_left = 0.0
			_ducked = false
			_apply_rest_volume()
	if not _fading:
		return
	if _players.size() < 2:
		_fading = false
		return
	_fade_t += delta / maxf(Tuning.AUDIO_CROSSFADE_TIME, 0.01)
	var t := clampf(_fade_t, 0.0, 1.0)
	var smooth := t * t * (3.0 - 2.0 * t)
	var target := _target_db()
	var outgoing: AudioStreamPlayer = _players[_active]
	var incoming: AudioStreamPlayer = _players[1 - _active]
	outgoing.volume_db = lerpf(_fade_start_out, _SILENCE_DB, smooth)
	incoming.volume_db = lerpf(_SILENCE_DB, target, smooth)
	if t >= 1.0:
		outgoing.stop()
		incoming.volume_db = target
		_active = 1 - _active
		_current_area = _target_area
		_fading = false


## The steady-state mix volume (duck-aware), in dB.
func _target_db() -> float:
	var base := linear_to_db(maxf(Tuning.AUDIO_AMBIENT_VOLUME, 0.001))
	if _ducked:
		return base - Tuning.AUDIO_DUCK_DB
	return base


## Rests the active player at the mix target. A fade tick owns both volumes
## while blending, so duck / restore only touch the steady state.
func _apply_rest_volume() -> void:
	if _fading:
		return
	if _players.is_empty():
		return
	_players[_active].volume_db = _target_db()


func _ensure_players() -> void:
	if not _players.is_empty():
		return
	if not is_inside_tree():
		return
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Ambient%d" % i
		player.bus = &"Master"
		add_child(player)
		_players.append(player)


## Canonical area name shared with AudioFactory: known areas pass through,
## anything else reads as the meadow loop (first tuned area). Side-effect
## free so both surfaces resolve identically.
static func canonical_area(area_name: String) -> String:
	if Tuning.AUDIO_AMBIENT_NAMES.has(area_name):
		return area_name
	return Tuning.AUDIO_AMBIENT_NAMES[0]


## Unknown or empty areas read as the meadow loop (shared rule).
func _resolve_area(area_name: String) -> String:
	return canonical_area(area_name)


## Renders one gentle loop: a three-tone chord breathing under a slow
## tremolo. Every chord frequency and the tremolo rate complete whole cycles
## inside the duration, so the loop wraps without a click; frequencies and
## rate are hoisted out of the frame loop to keep startup sub-second. Shared
## by the manager cache and AudioFactory.warm_ambient so both surfaces serve
## byte-identical streams.
static func synthesize_ambient(area_name: String) -> AudioStreamWAV:
	var spec: Dictionary = Tuning.AUDIO_AMBIENT[canonical_area(area_name)]
	var freqs: Array = spec["freqs"]
	var f0: float = freqs[0]
	var f1: float = freqs[1]
	var f2: float = freqs[2]
	var lfo_rate: float = spec["lfo_rate"]
	var lfo_depth: float = spec["lfo_depth"]
	var rate := Tuning.AUDIO_SAMPLE_RATE
	var frames := int(Tuning.AUDIO_AMBIENT_DURATION * float(rate))
	var volume := float(Tuning.AUDIO_AMBIENT_VOLUME)
	var bytes := PackedByteArray()
	bytes.resize(frames)
	var step0 := TAU * f0 / float(rate)
	var step1 := TAU * f1 / float(rate)
	var step2 := TAU * f2 / float(rate)
	var lfo_step := TAU * lfo_rate / float(rate)
	var voice0 := 0.0
	var voice1 := 0.0
	var voice2 := 0.0
	for i in frames:
		var chord := (sin(voice0) + sin(voice1) + sin(voice2)) / 3.0
		var breath := 1.0 - lfo_depth * (0.5 + 0.5 * sin(lfo_step * float(i)))
		bytes[i] = clampi(128 + int(127.0 * volume * breath * chord), 0, 255)
		voice0 += step0
		voice1 += step1
		voice2 += step2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = bytes
	return stream


## Instance wrapper kept so warm_ambient reads unchanged.
func _synthesize_ambient(area_name: String) -> AudioStreamWAV:
	return synthesize_ambient(area_name)
