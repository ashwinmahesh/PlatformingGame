class_name InputSetup
extends RefCounted
## Registers the input map from code (plan §9.6) so it is reproducible and remappable.
## Build 2: WASD moves, arrow keys turn the camera (swappable in Settings), Space jumps, F (or J)
## attacks. No mouse.

const DEADZONE := 0.2


static func register() -> void:
	# Settings.arrows_move swaps the two key sets (the sticks never change).
	var swap := Settings.arrows_move
	var left := KEY_LEFT if swap else KEY_A
	var right := KEY_RIGHT if swap else KEY_D
	var up := KEY_UP if swap else KEY_W
	var down := KEY_DOWN if swap else KEY_S
	_action(&"move_left", [_key(left), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action(&"move_right", [_key(right), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action(&"move_forward", [_key(up), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action(&"move_back", [_key(down), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action(&"cam_left", [_key(KEY_A if swap else KEY_LEFT), _axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action(&"cam_right", [_key(KEY_D if swap else KEY_RIGHT), _axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action(&"cam_up", [_key(KEY_W if swap else KEY_UP), _axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action(&"cam_down", [_key(KEY_S if swap else KEY_DOWN), _axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action(&"jump", [_key(KEY_SPACE), _joy(JOY_BUTTON_A)])
	_action(&"attack", [_key(KEY_F), _key(KEY_J), _joy(JOY_BUTTON_X)])
	_action(&"plunge", [_key(KEY_SHIFT), _key(KEY_K), _joy(JOY_BUTTON_B)])
	_action(&"interact", [_key(KEY_E), _joy(JOY_BUTTON_Y)])
	_action(&"lock_on", [_key(KEY_Q), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action(&"switch_target", [_key(KEY_TAB), _joy(JOY_BUTTON_RIGHT_STICK)])
	_action(&"pause", [_key(KEY_ESCAPE), _joy(JOY_BUTTON_START)])
	_action(&"cam_zoom_in", [_key(KEY_EQUAL), _key(KEY_KP_ADD), _joy(JOY_BUTTON_DPAD_UP)])
	_action(&"cam_zoom_out", [_key(KEY_MINUS), _key(KEY_KP_SUBTRACT), _joy(JOY_BUTTON_DPAD_DOWN)])
	# Build 5 magic: R Fireball, C Thunderclap, V Air Dash; Glide is holding Space while falling.
	_action(&"fireball", [_key(KEY_R), _key(KEY_L), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action(&"thunderclap", [_key(KEY_C), _joy(JOY_BUTTON_LEFT_SHOULDER)])
	_action(&"dash", [_key(KEY_V), _joy(JOY_BUTTON_RIGHT_SHOULDER)])
	_action(&"dev_feel_lab", [_key(KEY_F1)])
	_action(&"dev_ai_debug", [_key(KEY_F2)])
	_action(&"dev_all_abilities", [_key(KEY_F3)])
	_action(&"ui_accept_game", [_key(KEY_ENTER), _key(KEY_E), _key(KEY_SPACE), _joy(JOY_BUTTON_A)])


static func _action(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, DEADZONE)
	for e in events:
		InputMap.action_add_event(action, e)


static func _key(code: Key) -> InputEvent:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _joy(button: JoyButton) -> InputEvent:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


static func _axis(axis: JoyAxis, value: float) -> InputEvent:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
