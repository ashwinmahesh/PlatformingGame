class_name DeviceInput
extends InputSource
## Reads the keyboard and gamepad through the input map.

var enabled: bool = true


func sample() -> PlayerInput:
	var i := PlayerInput.new()
	if not enabled:
		return i
	i.move = Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	i.jump_pressed = Input.is_action_just_pressed(&"jump")
	i.jump_held = Input.is_action_pressed(&"jump")
	i.jump_released = Input.is_action_just_released(&"jump")
	i.attack_pressed = Input.is_action_just_pressed(&"attack")
	i.plunge_pressed = Input.is_action_just_pressed(&"plunge")
	i.plunge_held = Input.is_action_pressed(&"plunge")
	i.interact_pressed = Input.is_action_just_pressed(&"interact")
	i.lock_pressed = Input.is_action_just_pressed(&"lock_on")
	i.lock_held = Input.is_action_pressed(&"lock_on")
	i.lock_released = Input.is_action_just_released(&"lock_on")
	i.switch_target_pressed = Input.is_action_just_pressed(&"switch_target")
	i.fireball_pressed = Input.is_action_just_pressed(&"fireball")
	i.clap_pressed = Input.is_action_just_pressed(&"thunderclap")
	i.dash_pressed = Input.is_action_just_pressed(&"dash")
	i.vine_pressed = Input.is_action_just_pressed(&"vine")
	for k in 9:
		if Input.is_action_just_pressed(StringName("ability_%d" % (k + 1))):
			i.cast_slot = k
	i.cast_selected_pressed = Input.is_action_just_pressed(&"cast_selected")
	i.select_step = (1 if Input.is_action_just_pressed(&"ability_next") else 0) - (1 if Input.is_action_just_pressed(&"ability_prev") else 0)
	return i
