extends GdToolsTest
## Ambient loop + playback suites (audio_synthesis_20261027 Phase 2).
##
## Pins the Phase 2 contract: three gentle loop-enabled AudioStreamWAV loops
## (meadow / cave / sunset) pre-generate once and stay cached, and the
## AudioManager helper (a plain Node, NOT an autoload) crossfades areas over
## ~0.8s through two reused players and ducks the loop a full 6 dB under
## SFX. Snapshot signatures pin determinism; a fresh manager must reproduce
## the live manager's bytes exactly. AudioFactory (the autoload playback
## surface) serves the same loops from its own cache through get_ambient(),
## sharing rendering with the manager so both stay byte-identical.

const EXPECTED_AMBIENT: Array[String] = ["meadow", "cave", "sunset"]

const FactoryScript := preload("res://src/factory/audio_factory.gd")


func _fresh_manager() -> AudioManager:
	var fresh := AudioManager.new()
	fresh.warm_ambient()
	return fresh


func _live_manager() -> AudioManager:
	var live := AudioManager.new()
	add_child(live)
	return live


func _settle(manager: AudioManager) -> void:
	manager._process(Tuning.AUDIO_CROSSFADE_TIME + 0.05)


func test_tuning_ambient_table_covers_three_areas() -> void:
	assert_eq(Tuning.AUDIO_AMBIENT_NAMES, EXPECTED_AMBIENT, "one loop per area.")
	for area_name in EXPECTED_AMBIENT:
		assert_true(Tuning.AUDIO_AMBIENT.has(area_name), "%s has a tuning voice." % area_name)
		var spec: Dictionary = Tuning.AUDIO_AMBIENT[area_name]
		var freqs: Array = spec["freqs"]
		assert_eq(freqs.size(), 3, "%s layers three tones." % area_name)
		for freq in freqs:
			assert_gt(float(freq), 0.0, "%s layers a positive pitch." % area_name)


func test_tuning_ambient_mix_is_conservative() -> void:
	assert_gt(Tuning.AUDIO_AMBIENT_DURATION, 0.0, "loops have a positive length.")
	assert_gt(float(Tuning.AUDIO_AMBIENT_VOLUME), 0.0, "loops are audible.")
	assert_true(float(Tuning.AUDIO_AMBIENT_VOLUME) <= 0.4, "loops stay conservative.")
	assert_almost_eq(Tuning.AUDIO_CROSSFADE_TIME, 0.8, 0.001, "area changes blend over ~0.8s.")
	assert_almost_eq(Tuning.AUDIO_DUCK_DB, 6.0, 0.001, "one-shots duck the loop by 6 dB.")
	assert_gt(Tuning.AUDIO_DUCK_TIME, 0.0, "timed ducks hold a positive window.")


func test_ambient_cache_prebuilds_and_reuses_streams() -> void:
	var manager := _live_manager()
	assert_eq(manager.ambient_cache_size(), 3, "warm-up pre-generates all 3 loops.")
	assert_eq(manager.ambient_names(), EXPECTED_AMBIENT, "the name list covers every area.")
	for area_name in EXPECTED_AMBIENT:
		assert_true(manager.has_ambient(area_name), "%s is cached." % area_name)
	var first := manager.get_ambient("sunset")
	manager.warm_ambient()
	manager.switch_ambient("sunset")
	_settle(manager)
	assert_is(manager.get_ambient("sunset"), first, "repeat warm-up reuses the cached loop.")
	assert_is(manager.active_stream(), first, "playback serves the same cached loop.")
	assert_eq(manager.ambient_cache_size(), 3, "cache size stays fixed.")


func test_ambient_buffers_have_the_spec_format() -> void:
	var manager := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		var stream: AudioStreamWAV = manager.get_ambient(area_name)
		assert_not_null(stream, "%s buffer exists." % area_name)
		assert_eq(stream.mix_rate, Tuning.AUDIO_SAMPLE_RATE, "%s rate is 22050 Hz." % area_name)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_8_BITS, "%s is 8-bit." % area_name)
		assert_false(stream.stereo, "%s is mono." % area_name)
		var frames := int(Tuning.AUDIO_AMBIENT_DURATION * float(Tuning.AUDIO_SAMPLE_RATE))
		assert_eq(stream.data.size(), frames, "%s length matches its duration." % area_name)
	manager.free()


func test_ambient_loops_are_loop_enabled() -> void:
	var manager := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		var stream := manager.get_ambient(area_name)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s loops forward." % area_name)
		assert_eq(stream.loop_begin, 0, "%s loops from the first frame." % area_name)
		assert_eq(stream.loop_end, stream.data.size(), "%s loops the whole buffer." % area_name)
	manager.free()


func test_ambient_buffers_are_non_silent_and_conservative() -> void:
	var manager := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		var sig: Dictionary = manager.ambient_signature(area_name)
		assert_gt(int(sig["peak"]), 8, "%s is non-silent." % area_name)
		assert_true(int(sig["peak"]) < 64, "%s stays conservative (no clipping)." % area_name)
	manager.free()


func test_ambient_loops_are_gentle_and_click_free() -> void:
	var manager := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		var bytes := manager.get_ambient(area_name).data
		var worst := 0
		for i in range(1, bytes.size()):
			worst = maxi(worst, absi(bytes[i] - bytes[i - 1]))
		assert_true(worst < 24, "%s has no harsh sample jumps." % area_name)
		var seam := absi(bytes[0] - bytes[bytes.size() - 1])
		assert_true(seam < 16, "%s wraps without a click." % area_name)
	manager.free()


func test_each_ambient_has_a_distinct_buffer() -> void:
	var manager := _fresh_manager()
	for a in range(EXPECTED_AMBIENT.size()):
		for b in range(a + 1, EXPECTED_AMBIENT.size()):
			var first := manager.get_ambient(EXPECTED_AMBIENT[a]).data
			var second := manager.get_ambient(EXPECTED_AMBIENT[b]).data
			assert_true(
				first != second,
				"%s and %s sound different." % [EXPECTED_AMBIENT[a], EXPECTED_AMBIENT[b]]
			)
	manager.free()


func test_ambient_snapshot_signatures() -> void:
	var manager := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		assert_snapshot(manager.ambient_signature(area_name), "ambient_" + area_name)
	manager.free()


func test_ambient_synthesis_is_deterministic_across_instances() -> void:
	var live := _live_manager()
	var fresh := _fresh_manager()
	for area_name in EXPECTED_AMBIENT:
		assert_eq(
			fresh.ambient_signature(area_name),
			live.ambient_signature(area_name),
			"%s regenerates identically." % area_name
		)
		assert_true(
			fresh.get_ambient(area_name).data == live.get_ambient(area_name).data,
			"%s bytes match exactly." % area_name
		)
	fresh.free()


func test_unknown_areas_fall_back_to_meadow() -> void:
	var manager := _fresh_manager()
	var home := manager.get_ambient("meadow")
	assert_is(manager.get_ambient("nope"), home, "unknown areas borrow meadow.")
	assert_is(manager.get_ambient(""), home, "empty names borrow meadow.")
	assert_true(manager.ambient_signature("nope").is_empty(), "unknown names have no signature.")
	manager.switch_ambient("nope")
	assert_eq(manager.current_area(), "meadow", "fallback switches still resolve.")
	manager.free()


func test_sfx_plus_ambient_startup_stays_sub_second() -> void:
	var factory: Node = FactoryScript.new()
	var fresh := AudioManager.new()
	var start := Time.get_ticks_msec()
	factory.warm_sfx()
	fresh.warm_ambient()
	var elapsed := Time.get_ticks_msec() - start
	assert_eq(factory.cache_size(), 9, "cold start makes all 9 SFX.")
	assert_eq(fresh.ambient_cache_size(), 3, "cold start makes all 3 loops.")
	# Why: native coverage instruments every GDScript line in-process
	# (GdToolsNativeCoverage._active), which slows the synthesis loops past
	# the budget; the 1 s budget pins real-hardware startup, not instrumented time.
	if not GdToolsNativeCoverage._active:
		assert_true(elapsed < 1000, "SFX + loops stay sub-second together.")
	factory.free()
	fresh.free()


func test_switch_ambient_plays_the_matching_loop() -> void:
	var manager := _live_manager()
	assert_eq(manager.player_count(), 2, "the manager keeps two loop players.")
	manager.switch_ambient("cave")
	assert_eq(manager.current_area(), "cave", "the first switch starts at once.")
	assert_false(manager.is_fading(), "the first switch needs no blend.")
	assert_is(manager.active_stream(), manager.get_ambient("cave"), "cave plays its own loop.")
	assert_almost_eq(
		manager.active_volume_db(), manager.target_volume_db(), 0.5, "it starts at full mix."
	)
	var stream := manager.active_stream()
	manager.switch_ambient("cave")
	assert_false(manager.is_fading(), "re-selecting the area never re-blends.")
	assert_is(manager.active_stream(), stream, "the cached loop keeps playing.")


func test_crossfade_overlaps_without_a_hard_cut() -> void:
	var manager := _live_manager()
	manager.switch_ambient("meadow")
	manager.switch_ambient("cave")
	assert_true(manager.is_fading(), "the second switch blends.")
	manager._process(Tuning.AUDIO_CROSSFADE_TIME * 0.5)
	assert_true(manager.is_fading(), "the blend is still going halfway.")
	var target := manager.target_volume_db()
	for index in 2:
		var level := manager.player_volume(index)
		assert_true(level > -80.0, "player %d already entered the blend." % index)
		assert_true(level < target, "player %d never jumps straight to full." % index)
	_settle(manager)
	assert_false(manager.is_fading(), "the blend finishes.")
	assert_eq(manager.current_area(), "cave", "the new area is playing.")
	assert_is(manager.active_stream(), manager.get_ambient("cave"), "cave plays its own loop.")
	assert_almost_eq(manager.active_volume_db(), target, 0.5, "the loop rests at full mix.")
	assert_eq(manager.player_count(), 2, "the blend never grows players.")


func test_mid_fade_switch_supersedes_cleanly() -> void:
	var manager := _live_manager()
	manager.switch_ambient("meadow")
	manager.switch_ambient("cave")
	manager._process(Tuning.AUDIO_CROSSFADE_TIME * 0.5)
	manager.switch_ambient("sunset")
	assert_true(manager.is_fading(), "the newest switch takes over.")
	_settle(manager)
	assert_eq(manager.current_area(), "sunset", "the newest area wins.")
	assert_false(manager.is_fading(), "the superseding blend finishes.")
	assert_is(manager.active_stream(), manager.get_ambient("sunset"), "sunset plays its loop.")
	assert_eq(manager.player_count(), 2, "superseding never grows players.")
	assert_eq(manager.get_child_count(), 2, "no player leaks as children.")


func test_ducking_steps_back_and_restores_cleanly() -> void:
	var manager := _live_manager()
	manager.switch_ambient("meadow")
	var full := manager.target_volume_db()
	manager.duck_ambient()
	assert_true(manager.is_ducked(), "ducking latches.")
	assert_almost_eq(
		manager.active_volume_db(), full - Tuning.AUDIO_DUCK_DB, 0.5, "the loop steps back 6 dB."
	)
	manager.restore_ambient()
	assert_false(manager.is_ducked(), "restore unlatches.")
	assert_almost_eq(manager.active_volume_db(), full, 0.5, "the loop returns to full mix.")


func test_notify_sfx_ducks_then_auto_restores() -> void:
	var manager := _live_manager()
	manager.switch_ambient("sunset")
	var full := manager.target_volume_db()
	manager.notify_sfx_played()
	assert_true(manager.is_ducked(), "a one-shot ducks the loop.")
	assert_almost_eq(
		manager.active_volume_db(), full - Tuning.AUDIO_DUCK_DB, 0.5, "the duck is a full 6 dB."
	)
	manager._process(Tuning.AUDIO_DUCK_TIME + 0.1)
	assert_false(manager.is_ducked(), "the duck releases on its own.")
	assert_almost_eq(manager.active_volume_db(), full, 0.5, "the mix restores cleanly.")


func test_many_switches_never_leak_players() -> void:
	var manager := _live_manager()
	for area_name: String in EXPECTED_AMBIENT + EXPECTED_AMBIENT:
		manager.switch_ambient(area_name)
		_settle(manager)
		assert_eq(manager.player_count(), 2, "still two players after '%s'." % area_name)
	assert_eq(manager.get_child_count(), 2, "the manager owns exactly its two players.")
	assert_eq(manager.current_area(), "sunset", "the last area is playing.")


func test_manager_outside_the_tree_is_headless_safe() -> void:
	var fresh := AudioManager.new()
	fresh.warm_ambient()
	fresh.switch_ambient("cave")
	fresh.duck_ambient()
	fresh.notify_sfx_played()
	fresh._process(0.5)
	fresh.restore_ambient()
	assert_eq(fresh.ambient_cache_size(), 3, "headless instances still synthesize without error.")
	assert_eq(fresh.current_area(), "cave", "logical area tracks without playback.")
	assert_eq(fresh.player_count(), 0, "no players exist outside the tree.")
	fresh.free()


func _fresh_factory() -> Node:
	var fresh: Node = FactoryScript.new()
	fresh.warm_sfx()
	fresh.warm_ambient()
	return fresh


func test_factory_serves_the_same_cached_loops_as_the_manager() -> void:
	var factory := _fresh_factory()
	var manager := _fresh_manager()
	assert_eq(factory.cache_size(), 9, "the SFX cache stays SFX-only.")
	assert_eq(factory.ambient_cache_size(), 3, "warm-up pre-generates all 3 loops.")
	assert_eq(factory.ambient_names(), EXPECTED_AMBIENT, "the name list covers every area.")
	for area_name in EXPECTED_AMBIENT:
		assert_true(factory.has_ambient(area_name), "%s is cached." % area_name)
		var stream: AudioStreamWAV = factory.get_ambient(area_name)
		assert_not_null(stream, "%s loop exists on the autoload surface." % area_name)
		assert_eq(stream.mix_rate, Tuning.AUDIO_SAMPLE_RATE, "%s rate is 22050 Hz." % area_name)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s loops." % area_name)
		assert_eq(
			factory.ambient_signature(area_name),
			manager.ambient_signature(area_name),
			"%s signature matches across surfaces." % area_name
		)
		assert_true(
			stream.data == manager.get_ambient(area_name).data,
			"%s bytes match exactly." % area_name
		)
	var first: AudioStreamWAV = factory.get_ambient("cave")
	factory.warm_ambient()
	assert_is(factory.get_ambient("cave"), first, "repeat warm-up reuses the cached loop.")
	assert_eq(factory.ambient_cache_size(), 3, "cache size stays fixed.")
	var home: AudioStreamWAV = factory.get_ambient("meadow")
	assert_is(factory.get_ambient("nope"), home, "unknown areas borrow meadow.")
	assert_is(factory.get_ambient(""), home, "empty names borrow meadow.")
	assert_false(factory.has_ambient("nope"), "unknown names report uncached.")
	assert_true(factory.ambient_signature("nope").is_empty(), "unknowns have no signature.")
	assert_not_null(AudioFactory.get_ambient("sunset"), "the autoload serves loops too.")
	assert_is(
		AudioFactory.get_ambient("nope"),
		AudioFactory.get_ambient("meadow"),
		"the autoload falls back too."
	)
	factory.free()
	manager.free()
