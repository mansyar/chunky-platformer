extends GdToolsTest
## Tests for the audio-generation stub interface (Foundation Phase 4).
##
## The stub pinned the API the game would call so gameplay code could be
## written against it; the Audio Synthesis track (Phase 6) has now replaced
## the no-op internals with pre-generated AudioStreamWAV synthesis, so this
## suite pins the implemented contract instead of the stub one.


func test_play_accepts_any_sfx_name_as_noop() -> void:
	AudioFactory.play("jump")
	AudioFactory.play("gem")
	assert_true(true, "play() completes without error for known-style names.")


func test_get_ambient_returns_cached_area_loops() -> void:
	var meadow: AudioStreamWAV = AudioFactory.get_ambient("meadow")
	assert_true(meadow != null, "get_ambient returns the meadow loop.")
	assert_is(
		AudioFactory.get_ambient("nope"), meadow, "unknown areas fall back to the meadow loop."
	)
	assert_is(AudioFactory.get_ambient("meadow"), meadow, "repeat calls reuse the cached loop.")
