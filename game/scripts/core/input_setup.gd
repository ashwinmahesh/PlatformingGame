class_name InputSetup
extends RefCounted
## Registers the input map from code (plan §9.6) so it is reproducible and remappable.
## Build 2: WASD moves, arrow keys turn the camera, Space jumps, F (or J) attacks. No mouse.

const DEADZONE := 0.2


static func register() -> void:
	_action(&"move_left", [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action(&"move_right", [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action(&"move_forward", [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action(&"move_back", [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action(&"cam_left", [_key(KEY_LEFT), _axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action(&"cam_right", [_key(KEY_RIGHT), _axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action(&"cam_up", [_key(KEY_UP), _axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action(&"cam_down", [_key(KEY_DOWN), _axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action(&"jump", [_key(KEY_SPACE), _joy(JOY_BUTTON_A)])
	_action(&"attack", [_key(KEY_F), _key(KEY_J), _joy(JOY_BUTTON_X)])
	_action(&"plunge", [_key(KEY_SHIFT), _key(KEY_K), _joy(JOY_BUTTON_B)])
	_action(&"interact", [_key(KEY_E), _joy(JOY_BUTTON_Y)])
	_action(&"lock_on", [_key(KEY_Q), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action(&"switch_target", [_key(KEY_TAB), _joy(JOY_BUTTON_RIGHT_STICK)])
	_action(&"pause", [_key(KEY_ESCAPE), _joy(JOY_BUTTON_START)])
	_action(&"dev_feel_lab", [_key(KEY_F1)])
	_action(&"dev_ai_debug", [_key(KEY_F2)])
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
