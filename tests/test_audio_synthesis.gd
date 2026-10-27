extends GdToolsTest
## SFX synthesis suites (audio_synthesis_20261027 Phase 1).
##
## Pins the Phase 1 contract: all 9 SFX pre-generate as cached 8-bit mono
## AudioStreamWAV buffers at startup, play() is polyphonic-safe with a
## voice cap and oldest-steal, and the toddler-safe mix (soft envelopes,
## conservative volumes, no harsh transients) holds per buffer. Snapshot
## signatures pin determinism; a fresh factory instance must reproduce the
## autoload's bytes exactly.

const EXPECTED_SFX: Array[String] = [
	"jump",
	"bounce",
	"gem",
	"key",
	"door",
	"celebrate",
	"gift_pop",
	"gift_wiggle",
	"gift_bonus",
]

const FactoryScript := preload("res://src/factory/audio_factory.gd")


func _fresh_factory() -> Node:
	var fresh: Node = FactoryScript.new()
	fresh.warm_sfx()
	return fresh


func test_tuning_sample_format_matches_spec() -> void:
	assert_eq(Tuning.AUDIO_SAMPLE_RATE, 22050, "SFX render at 22050 Hz.")
	assert_eq(Tuning.AUDIO_FORMAT_BITS, 8, "SFX buffers are 8-bit.")
	assert_eq(Tuning.AUDIO_CHANNELS, 1, "SFX buffers are mono.")


func test_tuning_voice_cap_matches_spec() -> void:
	assert_eq(Tuning.AUDIO_MAX_VOICES, 8, "at most 8 one-shots overlap.")


func test_tuning_sfx_table_covers_all_nine() -> void:
	assert_eq(Tuning.AUDIO_SFX_NAMES.size(), 9, "tuning lists 9 SFX.")
	for sfx_name in EXPECTED_SFX:
		assert_true(Tuning.AUDIO_SFX.has(sfx_name), "%s has a tuning voice." % sfx_name)
		var spec: Dictionary = Tuning.AUDIO_SFX[sfx_name]
		assert_gt(float(spec["duration"]), 0.0, "%s has a positive duration." % sfx_name)
		assert_true(float(spec["duration"]) < 1.0, "%s stays a short one-shot." % sfx_name)
		assert_gt(float(spec["freq_end"]), 0.0, "%s has a positive pitch." % sfx_name)


func test_tuning_volumes_are_conservative() -> void:
	for sfx_name in Tuning.AUDIO_SFX_NAMES:
		var spec: Dictionary = Tuning.AUDIO_SFX[sfx_name]
		assert_gt(float(spec["volume"]), 0.0, "%s is audible." % sfx_name)
		assert_true(float(spec["volume"]) <= 0.4, "%s volume is conservative." % sfx_name)
	assert_gt(Tuning.AUDIO_ATTACK_TIME, 0.0, "soft attack is configured.")
	assert_gt(Tuning.AUDIO_RELEASE_FRACTION, 0.0, "soft release is configured.")


func test_all_nine_sfx_are_cached_streams() -> void:
	assert_eq(AudioFactory.cache_size(), 9, "startup pre-generates all 9 SFX.")
	assert_eq(AudioFactory.sfx_names().size(), 9, "name list covers all 9 SFX.")
	for sfx_name in EXPECTED_SFX:
		assert_true(AudioFactory.has_sfx(sfx_name), "%s is cached." % sfx_name)
		assert_true(AudioFactory.sfx_names().has(sfx_name), "%s is listed." % sfx_name)


func test_sfx_buffers_have_the_spec_format() -> void:
	for sfx_name in EXPECTED_SFX:
		var stream: AudioStreamWAV = AudioFactory.get_sfx(sfx_name)
		assert_true(stream != null, "%s buffer exists." % sfx_name)
		assert_eq(stream.mix_rate, Tuning.AUDIO_SAMPLE_RATE, "%s rate is 22050 Hz." % sfx_name)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_8_BITS, "%s is 8-bit." % sfx_name)
		assert_false(stream.stereo, "%s is mono." % sfx_name)
		var spec: Dictionary = Tuning.AUDIO_SFX[sfx_name]
		var expected := int(float(spec["duration"]) * float(Tuning.AUDIO_SAMPLE_RATE))
		assert_eq(stream.data.size(), expected, "%s length matches its duration." % sfx_name)


func test_sfx_buffers_are_non_silent_and_conservative() -> void:
	for sfx_name in EXPECTED_SFX:
		var sig: Dictionary = AudioFactory.sfx_signature(sfx_name)
		assert_gt(int(sig["peak"]), 8, "%s is non-silent." % sfx_name)
		assert_true(int(sig["peak"]) < 64, "%s stays conservative (no clipping)." % sfx_name)


func test_sfx_envelopes_start_and_end_in_silence() -> void:
	for sfx_name in EXPECTED_SFX:
		var bytes := AudioFactory.get_sfx(sfx_name).data
		assert_true(absi(bytes[0] - 128) < 3, "%s starts in silence." % sfx_name)
		assert_true(absi(bytes[bytes.size() - 1] - 128) < 3, "%s ends in silence." % sfx_name)


func test_sfx_have_no_harsh_transients() -> void:
	for sfx_name in EXPECTED_SFX:
		var bytes := AudioFactory.get_sfx(sfx_name).data
		var worst := 0
		for i in range(1, bytes.size()):
			worst = maxi(worst, absi(bytes[i] - bytes[i - 1]))
		assert_true(worst < 48, "%s has no harsh sample jumps." % sfx_name)


func test_each_sfx_has_a_distinct_buffer() -> void:
	for a in range(EXPECTED_SFX.size()):
		for b in range(a + 1, EXPECTED_SFX.size()):
			var first := AudioFactory.get_sfx(EXPECTED_SFX[a]).data
			var second := AudioFactory.get_sfx(EXPECTED_SFX[b]).data
			assert_true(
				first != second, "%s and %s sound different." % [EXPECTED_SFX[a], EXPECTED_SFX[b]]
			)


func test_sfx_snapshot_signatures() -> void:
	for sfx_name in EXPECTED_SFX:
		assert_snapshot(AudioFactory.sfx_signature(sfx_name), "sfx_" + sfx_name)


func test_synthesis_is_deterministic_across_instances() -> void:
	var fresh := _fresh_factory()
	for sfx_name in EXPECTED_SFX:
		assert_eq(
			fresh.sfx_signature(sfx_name),
			AudioFactory.sfx_signature(sfx_name),
			"%s regenerates identically." % sfx_name
		)
		assert_true(
			fresh.get_sfx(sfx_name).data == AudioFactory.get_sfx(sfx_name).data,
			"%s bytes match exactly." % sfx_name
		)
	fresh.free()


func test_cache_reuses_streams_without_regeneration() -> void:
	var first: AudioStreamWAV = AudioFactory.get_sfx("gem")
	AudioFactory.warm_sfx()
	var second: AudioStreamWAV = AudioFactory.get_sfx("gem")
	assert_is(first, second, "repeat warm-up reuses the cached stream.")
	assert_eq(AudioFactory.cache_size(), 9, "cache size stays fixed.")


func test_unknown_sfx_lookups_fall_back_safely() -> void:
	assert_false(AudioFactory.has_sfx("nope"), "unknown names report uncached.")
	assert_true(AudioFactory.get_sfx("nope") == null, "unknown names return null.")
	assert_true(AudioFactory.sfx_signature("nope").is_empty(), "unknown names have no signature.")


func test_pregeneration_at_startup_is_fast() -> void:
	var fresh: Node = FactoryScript.new()
	var start := Time.get_ticks_msec()
	fresh.warm_sfx()
	var elapsed := Time.get_ticks_msec() - start
	assert_eq(fresh.cache_size(), 9, "cold warm-up produces all 9 SFX.")
	assert_true(elapsed < 1000, "pre-generation stays sub-second.")
	fresh.free()


func test_play_emits_a_one_shot_per_valid_name() -> void:
	AudioFactory.reset_pool()
	assert_eq(AudioFactory.pool_size(), Tuning.AUDIO_MAX_VOICES, "pool holds 8 voices.")
	for sfx_name in EXPECTED_SFX:
		AudioFactory.play(sfx_name)
	assert_eq(
		AudioFactory.active_voice_count(),
		Tuning.AUDIO_MAX_VOICES,
		"every valid name emits; the pool caps at 8 voices."
	)
	AudioFactory.reset_pool()


func test_rapid_mash_stays_polyphonic_with_cap() -> void:
	AudioFactory.reset_pool()
	for i in 10:
		AudioFactory.play("gem")
	assert_eq(
		AudioFactory.active_voice_count(),
		Tuning.AUDIO_MAX_VOICES,
		"a 10-play mash saturates exactly at the cap (oldest-steal, no growth)."
	)
	assert_eq(
		AudioFactory.pool_size(), Tuning.AUDIO_MAX_VOICES, "the pool never grows past the cap."
	)
	AudioFactory.reset_pool()
	assert_eq(AudioFactory.active_voice_count(), 0, "reset frees every voice.")


func test_play_ignores_unknown_and_empty_names() -> void:
	AudioFactory.reset_pool()
	AudioFactory.play("nope")
	AudioFactory.play("")
	assert_eq(AudioFactory.active_voice_count(), 0, "unknown names never claim a voice.")
	AudioFactory.play("jump")
	assert_eq(AudioFactory.active_voice_count(), 1, "valid names still play afterwards.")
	AudioFactory.reset_pool()


func test_play_outside_the_tree_is_a_safe_noop() -> void:
	var fresh := _fresh_factory()
	fresh.play("jump")
	fresh.play("nope")
	assert_eq(fresh.cache_size(), 9, "headless instances still synthesize without error.")
	fresh.free()
