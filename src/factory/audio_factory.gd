extends Node
## AudioFactory — synthesized SFX + ambient loops (Audio track P1+P2).
##
## Registered as the `AudioFactory` autoload. All 9 one-shot SFX are
## pre-generated once at startup as 8-bit mono AudioStreamWAV buffers (see
## Tuning.AUDIO_SFX) and cached in memory; repeat calls reuse the cache and
## never regenerate. play() is polyphonic with a voice cap: at most
## Tuning.AUDIO_MAX_VOICES one-shots overlap and the oldest voice is stolen
## first, so a mashing 4-year-old can never clip or drop the ambient.
## Unknown or empty SFX names are safe no-ops. The three per-area ambient
## loops (see Tuning.AUDIO_AMBIENT) pre-generate the same way and are served
## by get_ambient(), sharing rendering with AudioManager so both surfaces
## stay byte-identical; unknown or empty areas fall back to meadow.

var _sfx_cache := {}
var _ambient_cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _voice_seq: Array[int] = []
var _play_counter := 0


func _ready() -> void:
	warm_sfx()
	warm_ambient()
	_ensure_pool()


## Pre-generates every SFX buffer once; repeat calls reuse the cache.
func warm_sfx() -> void:
	for sfx_name in Tuning.AUDIO_SFX_NAMES:
		if not _sfx_cache.has(sfx_name):
			_sfx_cache[sfx_name] = _synthesize(sfx_name)


## True when a buffer is cached for this logical SFX name.
func has_sfx(sfx_name: String) -> bool:
	return _sfx_cache.has(sfx_name)


## Returns the cached stream, or null for unknown names (safe fallback).
func get_sfx(sfx_name: String) -> AudioStreamWAV:
	return _sfx_cache.get(sfx_name) as AudioStreamWAV


## Logical names of all cached SFX buffers, in tuning order.
func sfx_names() -> Array[String]:
	var names: Array[String] = []
	for sfx_name in Tuning.AUDIO_SFX_NAMES:
		if _sfx_cache.has(sfx_name):
			names.append(sfx_name)
	return names


## How many SFX buffers are cached (9 once warmed; ambient loops are counted
## separately by ambient_cache_size()).
func cache_size() -> int:
	return _sfx_cache.size()


## Deterministic snapshot summary of one buffer for assert_snapshot pins:
## byte length, checksum, leading bytes, and peak deviation from silence.
## Returns an empty Dictionary for unknown names.
func sfx_signature(sfx_name: String) -> Dictionary:
	if not _sfx_cache.has(sfx_name):
		return {}
	var stream: AudioStreamWAV = _sfx_cache.get(sfx_name) as AudioStreamWAV
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
		"name": sfx_name,
		"bytes": bytes.size(),
		"checksum": checksum,
		"head": head,
		"peak": peak,
	}


## Voice pool size (Tuning.AUDIO_MAX_VOICES once ready in the tree).
func pool_size() -> int:
	return _pool.size()


## How many voices currently hold a stream. Counts assigned players rather
## than is_playing() so the cap holds deterministically on every audio
## driver, including headless / dummy drivers that never report playback.
func active_voice_count() -> int:
	var count := 0
	for player in _pool:
		if player.stream != null:
			count += 1
	return count


## Stops every voice and releases its stream so the pool is fully free.
func reset_pool() -> void:
	for player in _pool:
		player.stop()
		player.stream = null
	_voice_seq.fill(-1)


## Plays a one-shot sound effect by logical name (e.g. "jump", "gem").
## Polyphonic up to the voice cap with oldest-steal; unknown or empty
## names, and calls outside the scene tree, are safe no-ops.
func play(sfx_name: String) -> void:
	if sfx_name.is_empty() or not _sfx_cache.has(sfx_name):
		return
	if not is_inside_tree():
		return
	_ensure_pool()
	if _pool.is_empty():
		return
	var player := _free_player()
	if player == null:
		player = _steal_oldest()
	_play_counter += 1
	_voice_seq[_pool.find(player)] = _play_counter
	player.stream = _sfx_cache.get(sfx_name) as AudioStreamWAV
	player.volume_db = linear_to_db(float(Tuning.AUDIO_SFX[sfx_name]["volume"]))
	player.play()


## Pre-generates every ambient loop once; repeat calls reuse the cache.
## Rendering is shared with AudioManager.synthesize_ambient (no duplicated
## synthesis), so factory and manager loops are byte-identical.
func warm_ambient() -> void:
	for area_name in Tuning.AUDIO_AMBIENT_NAMES:
		if not _ambient_cache.has(area_name):
			_ambient_cache[area_name] = AudioManager.synthesize_ambient(area_name)


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


## Unknown or empty areas read as the meadow loop (shared rule).
func _resolve_area(area_name: String) -> String:
	return AudioManager.canonical_area(area_name)


func _ensure_pool() -> void:
	if not _pool.is_empty():
		return
	if not is_inside_tree():
		return
	for i in Tuning.AUDIO_MAX_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		player.bus = &"Master"
		add_child(player)
		_pool.append(player)
		_voice_seq.append(-1)


## First idle voice (never used or finished), or null when all are busy.
func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if player.stream == null or not player.is_playing():
			return player
	return null


## Busiest-pool fallback: the voice that started longest ago.
func _steal_oldest() -> AudioStreamPlayer:
	var oldest := 0
	for i in _pool.size():
		if _voice_seq[i] < _voice_seq[oldest]:
			oldest = i
	return _pool[oldest]


## Synthesizes one soft SFX buffer: a sine sweep from freq_start to
## freq_end with an optional gentle vibrato, shaped by a short linear
## attack and a cosine release so the buffer starts and ends in silence.
func _synthesize(sfx_name: String) -> AudioStreamWAV:
	var spec: Dictionary = Tuning.AUDIO_SFX[sfx_name]
	var duration: float = spec["duration"]
	var freq_start: float = spec["freq_start"]
	var freq_end: float = spec["freq_end"]
	var volume: float = spec["volume"]
	var wobble_rate: float = spec["wobble_rate"]
	var wobble_depth: float = spec["wobble_depth"]
	var rate := Tuning.AUDIO_SAMPLE_RATE
	var frames := int(duration * float(rate))
	var attack_frames := maxi(1, int(Tuning.AUDIO_ATTACK_TIME * float(rate)))
	var release_frames := maxi(1, int(duration * Tuning.AUDIO_RELEASE_FRACTION * float(rate)))
	var bytes := PackedByteArray()
	bytes.resize(frames)
	var phase := 0.0
	for i in frames:
		var t := float(i) / float(maxi(frames, 1))
		var freq := lerpf(freq_start, freq_end, t)
		if wobble_rate > 0.0:
			freq += wobble_depth * sin(TAU * wobble_rate * float(i) / float(rate))
		phase += TAU * freq / float(rate)
		var env := 1.0
		if i < attack_frames:
			env = float(i) / float(attack_frames)
		var tail := frames - i
		if tail < release_frames:
			var release := (
				0.5 + 0.5 * cos(PI * float(release_frames - tail) / float(release_frames))
			)
			env = minf(env, release)
		bytes[i] = clampi(128 + int(127.0 * volume * env * sin(phase)), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
