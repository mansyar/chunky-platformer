extends Node
## AudioFactory — stub audio interface (Foundation Phase 4).
##
## Registered as the `AudioFactory` autoload. Gameplay code calls play()
## for one-shot SFX and get_ambient() for per-area ambient loops. Both are
## no-ops for now; Phase 6 (Audio) fills in pre-generated AudioStreamWAV
## synthesis behind this same interface.


## Plays a one-shot sound effect by logical name (e.g. "jump", "gem").
func play(_sfx_name: String) -> void:
	pass


## Returns the ambient loop stream for an area, or null while unimplemented.
func get_ambient(_area_name: String) -> AudioStream:
	return null
