extends CanvasLayer
## Debug overlay, Feel Lab (F1) and AI debug view (F2). Disabled in release builds (plan §7.3).
## "Save preset" writes user://feel_lab/preset.tres, which the next launch loads, so your tuning
## reaches agents as a readable diff.

const PRESET_PATH := "user://feel_lab/preset.tres"

var enabled: bool = OS.is_debug_build()
var ai_debug: bool = false
var feel_lab_open: bool = false
var _overlay: Label
var _panel: PanelContainer
var _settings: MovementSettings


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = Label.new()
	_overlay.position = Vector2(40, 120)
	_overlay.add_theme_font_size_override(&"font_size", 22)
	_overlay.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_overlay.add_theme_constant_override(&"outline_size", 8)
	_overlay.visible = false
	add_child(_overlay)


## The settings the hero should use: a saved Feel Lab preset in debug builds, else the data file.
func movement_settings() -> MovementSettings:
	if _settings != null:
		return _settings
	var base := preload("res://data/movement/hero_movement.tres") as MovementSettings
	_settings = base.duplicate() as MovementSettings
	if enabled and FileAccess.file_exists(PRESET_PATH):
		var preset := ResourceLoader.load(PRESET_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as MovementSettings
		if preset != null:
			_settings = preset
	return _settings


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed(&"dev_feel_lab"):
		feel_lab_open = not feel_lab_open
		_overlay.visible = feel_lab_open
		if feel_lab_open:
			_build_panel()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif _panel != null:
			_panel.queue_free()
			_panel = null
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif event.is_action_pressed(&"dev_ai_debug"):
		ai_debug = not ai_debug
	elif event.is_action_pressed(&"dev_all_abilities"):
		Progress.dev_all_abilities = not Progress.dev_all_abilities
		Events.notice.emit("Dev: all abilities %s" % ("ON" if Progress.dev_all_abilities else "off"))


func _process(_delta: float) -> void:
	if not _overlay.visible:
		return
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		_overlay.text = "(no player)"
		return
	var h := Vector2(p.velocity.x, p.velocity.z).length()
	_overlay.text = "speed %.2f  vy %.2f\nstate %s  grounded %s\njumps_used %d  air_slash %s\nbuffer_age %d  coyote %.3f\nhp %d/%d  fps %d" % [
		h, p.velocity.y, Player.State.keys()[p.state], p.is_grounded(), p.jumps_used, p.air_slash_ready,
		p.buffer_age, maxf(p.coyote_left, 0.0), p.hp, p.max_hp, Engine.get_frames_per_second()]


func _build_panel() -> void:
	var s := movement_settings()
	_panel = PanelContainer.new()
	_panel.position = Vector2(1400, 80)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.14, 0.88)
	bg.set_content_margin_all(16)
	bg.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override(&"panel", bg)
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(440, 0)
	_panel.add_child(vb)
	var title := Label.new()
	title.text = "Feel Lab (F1 to close)"
	vb.add_child(title)
	_slider(vb, s, "run_speed", 3.0, 12.0)
	_slider(vb, s, "accel_time", 0.02, 0.4)
	_slider(vb, s, "air_control", 0.1, 1.0)
	_slider(vb, s, "gravity_up", 10.0, 50.0)
	_slider(vb, s, "gravity_down", 15.0, 80.0)
	_slider(vb, s, "apex_gravity_scale", 0.2, 1.0)
	_slider(vb, s, "coyote_time", 0.0, 0.3)
	_slider(vb, s, "jump_buffer", 0.0, 0.3)
	_slider(vb, s, "wall_slide_speed", 0.5, 8.0)
	_slider(vb, s, "wall_jump_height", 1.0, 5.0)
	_slider(vb, s, "wall_jump_push", 3.0, 14.0)
	_slider(vb, s, "wall_lockout", 0.0, 0.6)
	_slider(vb, s, "ladder_speed", 2.0, 8.0)
	for i in 3:
		var l := Label.new()
		vb.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.5
		sl.max_value = 4.0
		sl.step = 0.05
		sl.value = s.jump_heights[i]
		l.text = "J%d height %.2f" % [i + 1, sl.value]
		var idx := i
		sl.value_changed.connect(func(v: float) -> void:
			s.jump_heights[idx] = v
			l.text = "J%d height %.2f" % [idx + 1, v])
		vb.add_child(sl)
	_toggle(vb, s, "mario_chain_mode")
	_toggle(vb, s, "prefer_ground_jump")
	var save := Button.new()
	save.text = "Save preset"
	save.pressed.connect(func() -> void:
		DirAccess.make_dir_recursive_absolute("user://feel_lab")
		var err := ResourceSaver.save(s, PRESET_PATH)
		Events.notice.emit("Preset saved" if err == OK else "Preset save failed"))
	vb.add_child(save)
	var reset := Button.new()
	reset.text = "Reset to defaults (next launch)"
	reset.pressed.connect(func() -> void:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PRESET_PATH))
		Events.notice.emit("Preset removed"))
	vb.add_child(reset)


func _slider(parent: Control, s: MovementSettings, prop: String, lo: float, hi: float) -> void:
	var l := Label.new()
	parent.add_child(l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = (hi - lo) / 200.0
	sl.value = float(s.get(prop))
	l.text = "%s %.3f" % [prop, sl.value]
	sl.value_changed.connect(func(v: float) -> void:
		s.set(prop, v)
		l.text = "%s %.3f" % [prop, v])
	parent.add_child(sl)


func _toggle(parent: Control, s: MovementSettings, prop: String) -> void:
	var c := CheckBox.new()
	c.text = prop
	c.button_pressed = bool(s.get(prop))
	c.toggled.connect(func(on: bool) -> void: s.set(prop, on))
	parent.add_child(c)
