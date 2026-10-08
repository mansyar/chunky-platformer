extends GdToolsTest
## Tests for the audio-generation stub interface (Foundation Phase 4).
##
## The stub pins the API the game will call so gameplay code can be written
## against it now; Phase 6 (Audio) replaces the no-op internals with
## pre-generated AudioStreamWAV synthesis.


func test_play_accepts_any_sfx_name_as_noop() -> void:
	AudioFactory.play("jump")
	AudioFactory.play("gem")
	assert_true(true, "play() completes without error for known-style names.")


func test_get_ambient_returns_null_until_implemented() -> void:
	assert_true(
		AudioFactory.get_ambient("meadow") == null,
		"get_ambient returns null in the stub implementation."
	)
