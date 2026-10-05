extends TestCase
## Ashwin's control-swap setting: arrow keys can move the hero with WASD turning the camera.


func _keys(action: StringName) -> Array[Key]:
	var out: Array[Key] = []
	for e in InputMap.action_get_events(action):
		var k := e as InputEventKey
		if k != null:
			out.append(k.physical_keycode)
	return out


func test_wasd_and_arrows_swap() -> void:
	var was := Settings.arrows_move
	Settings.arrows_move = false
	InputSetup.register()
	check(KEY_W in _keys(&"move_forward") and KEY_UP in _keys(&"cam_up"), "default: WASD moves, arrows turn the camera")
	Settings.arrows_move = true
	InputSetup.register()
	check(KEY_UP in _keys(&"move_forward") and not KEY_W in _keys(&"move_forward"), "swapped: the up arrow moves forward")
	check(KEY_LEFT in _keys(&"move_left") and KEY_RIGHT in _keys(&"move_right") and KEY_DOWN in _keys(&"move_back"), "swapped: all four arrows move")
	check(KEY_W in _keys(&"cam_up") and KEY_A in _keys(&"cam_left") and KEY_D in _keys(&"cam_right") and KEY_S in _keys(&"cam_down"), "swapped: WASD turns the camera")
	check(Settings.controls_hint().begins_with("Arrow keys move"), "the help text follows the setting")
	Settings.arrows_move = was
	InputSetup.register()
