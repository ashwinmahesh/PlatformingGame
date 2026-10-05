class_name ScriptedInput
extends InputSource
## Test input: set `move`, call press()/release() before a tick. Edges last exactly one tick.

var move: Vector2 = Vector2.ZERO
var _held: Dictionary[StringName, bool] = {}
var _pressed: Array[StringName] = []
var _released: Array[StringName] = []


func press(action: StringName) -> void:
	_held[action] = true
	_pressed.append(action)


func release(action: StringName) -> void:
	_held[action] = false
	_released.append(action)


## Press and release on consecutive ticks is the common case; this presses now and auto-releases.
func tap(action: StringName) -> void:
	_pressed.append(action)


func sample() -> PlayerInput:
	var i := PlayerInput.new()
	i.move = move
	i.jump_pressed = &"jump" in _pressed
	i.jump_held = _held.get(&"jump", false) or i.jump_pressed
	i.jump_released = &"jump" in _released
	i.attack_pressed = &"attack" in _pressed
	i.plunge_pressed = &"plunge" in _pressed
	i.plunge_held = _held.get(&"plunge", false) or i.plunge_pressed
	i.interact_pressed = &"interact" in _pressed
	i.lock_pressed = &"lock_on" in _pressed
	i.lock_held = _held.get(&"lock_on", false)
	i.lock_released = &"lock_on" in _released
	i.switch_target_pressed = &"switch_target" in _pressed
	_pressed.clear()
	_released.clear()
	return i
