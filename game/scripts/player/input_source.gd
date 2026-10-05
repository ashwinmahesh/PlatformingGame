class_name InputSource
extends RefCounted
## Where the player's input comes from. DeviceInput in play, ScriptedInput in tests.


func sample() -> PlayerInput:
	return PlayerInput.new()
