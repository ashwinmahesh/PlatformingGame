class_name Hud
extends CanvasLayer
## Hearts, seeds, boss bar, notices, interaction prompt, dialogue box and pause menu.

var player: Player
var world_id: StringName = &""

var _hearts: HeartsDisplay
var _breath: BreathDisplay
var _seeds: Label
var _notice: Label
var _prompt: Label
var _boss_box: Control
var _boss_bar: ColorRect
var _boss_fill: ColorRect
var _timer_label: Label
var _banner: Label
var _dialogue: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_lines: Array = []
var _dlg_index: int = 0
var _dlg_chars: float = 0.0
var _dlg_player: Player
var _dlg_ignore_frames: int = 0
var _pause: Control
var _notice_tween: Tween
var _theme: Theme
var _boss_name: Label
## Build 5 magic: the ability bar (bottom right) and the "new magic" card.
var _ability_bar: HBoxContainer
var _ability_slots: Dictionary[StringName, Control] = {}
var _learn_card: PanelContainer
var _learn_title: Label
var _learn_body: Label


func _ready() -> void:
	add_to_group(&"hud")
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _make_theme()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme
	add_child(root)
	_hearts = HeartsDisplay.new()
	_hearts.position = Vector2(40, 32)
	root.add_child(_hearts)
	_breath = BreathDisplay.new()
	_breath.position = Vector2(44, 100)
	root.add_child(_breath)
	_seeds = _label(root, "", 34, HORIZONTAL_ALIGNMENT_RIGHT)
	_seeds.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_seeds.offset_left = -360
	_seeds.offset_right = -40
	_seeds.offset_top = 32
	_notice = _label(root, "", 44, HORIZONTAL_ALIGNMENT_CENTER)
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notice.offset_left = -600
	_notice.offset_right = 600
	_notice.offset_top = 120
	_notice.modulate.a = 0.0
	_banner = _label(root, "", 80, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.offset_left = -800
	_banner.offset_right = 800
	_banner.offset_top = -220
	_banner.offset_bottom = -100
	_banner.modulate.a = 0.0
	_banner.add_theme_color_override(&"font_color", Palette.color(&"gold"))
	_prompt = _label(root, "", 32, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -400
	_prompt.offset_right = 400
	_prompt.offset_top = -150
	_prompt.offset_bottom = -100
	_timer_label = _label(root, "", 40, HORIZONTAL_ALIGNMENT_CENTER)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_left = -300
	_timer_label.offset_right = 300
	_timer_label.offset_top = 40
	_build_boss_bar(root)
	_build_abilities(root)
	_build_dialogue(root)
	_build_pause(root)
	Events.notice.connect(show_notice)
	Events.seed_collected.connect(func(_id: StringName) -> void: _refresh_seeds())
	Events.shard_collected.connect(func(_id: StringName) -> void: _refresh_seeds())
	_refresh_seeds()


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 32
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(Palette.color(&"cloth_cream"), 0.96)
	panel.border_color = Palette.INK
	panel.set_border_width_all(5)
	panel.set_corner_radius_all(22)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 22
	panel.content_margin_bottom = 22
	t.set_stylebox(&"panel", &"PanelContainer", panel)
	var btn := StyleBoxFlat.new()
	btn.bg_color = Palette.color(&"wood_plank")
	btn.border_color = Palette.INK
	btn.set_border_width_all(4)
	btn.set_corner_radius_all(16)
	btn.content_margin_left = 24
	btn.content_margin_right = 24
	btn.content_margin_top = 10
	btn.content_margin_bottom = 10
	var btn_hover := btn.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Palette.color(&"thatch")
	t.set_stylebox(&"normal", &"Button", btn)
	t.set_stylebox(&"hover", &"Button", btn_hover)
	t.set_stylebox(&"focus", &"Button", btn_hover)
	t.set_stylebox(&"pressed", &"Button", btn_hover)
	t.set_color(&"font_color", &"Button", Palette.INK)
	t.set_color(&"font_hover_color", &"Button", Palette.INK)
	t.set_color(&"font_focus_color", &"Button", Palette.INK)
	t.set_color(&"font_color", &"Label", Palette.color(&"cloth_cream"))
	t.set_color(&"font_outline_color", &"Label", Palette.INK)
	t.set_constant(&"outline_size", &"Label", 12)
	return t


func _label(parent: Control, text: String, size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override(&"font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func bind_player(p: Player) -> void:
	player = p
	p.hp_changed.connect(func(h: int, m: int) -> void: _hearts.set_hp(h, m))
	_hearts.set_hp(p.hp, p.max_hp)


func _refresh_seeds() -> void:
	var w := Progress.world_def(world_id)
	if w == null:
		_seeds.text = "Glimmer Seeds  %d / %d" % [Progress.seed_count(), Progress.all_seed_ids().size()]
		return
	var text := "Glimmer Seeds  %d / %d" % [Progress.world_seed_count(world_id), w.seed_ids.size()]
	if not w.shard_ids.is_empty():
		text += "\nStar Shards  %d / %d" % [Progress.world_shard_count(world_id), w.shards_required]
	_seeds.text = text


func show_notice(text: String) -> void:
	_notice.text = text
	if _notice_tween != null:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_property(_notice, "modulate:a", 1.0, 0.15)
	_notice_tween.tween_interval(1.8)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.5)


func show_banner(text: String, hold: float = 2.5) -> void:
	_banner.text = text
	_banner.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.25)
	t.tween_interval(hold)
	t.tween_property(_banner, "modulate:a", 0.0, 0.6)


func set_timer_text(text: String) -> void:
	_timer_label.text = text


# --- Boss bar ---------------------------------------------------------------------------------

func _build_boss_bar(root: Control) -> void:
	_boss_box = Control.new()
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.offset_left = -500
	_boss_box.offset_right = 500
	_boss_box.offset_top = -95
	_boss_box.offset_bottom = -40
	_boss_box.visible = false
	root.add_child(_boss_box)
	var name_label := _label(_boss_box, "Mother Gloop", 30, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name = name_label
	name_label.position = Vector2(0, -44)
	name_label.size = Vector2(1000, 40)
	_boss_bar = ColorRect.new()
	_boss_bar.color = Palette.INK
	_boss_bar.size = Vector2(1000, 34)
	_boss_box.add_child(_boss_bar)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Palette.color(&"gloop_pink")
	_boss_fill.position = Vector2(5, 5)
	_boss_fill.size = Vector2(990, 24)
	_boss_box.add_child(_boss_fill)


func set_boss_name(text: String) -> void:
	_boss_name.text = text


func set_boss(hp: int, max_hp: int, shown: bool) -> void:
	_boss_box.visible = shown
	_boss_fill.size.x = 990.0 * float(hp) / float(max_hp)


# --- Magic (Build 5) ---------------------------------------------------------------------------

func _build_abilities(root: Control) -> void:
	_ability_bar = HBoxContainer.new()
	_ability_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_ability_bar.offset_left = -560
	_ability_bar.offset_top = -150
	_ability_bar.offset_right = -40
	_ability_bar.offset_bottom = -40
	_ability_bar.alignment = BoxContainer.ALIGNMENT_END
	_ability_bar.add_theme_constant_override(&"separation", 14)
	root.add_child(_ability_bar)
	for id in Abilities.ORDER:
		var info: Array = Abilities.INFO[id]
		var slot := VBoxContainer.new()
		slot.custom_minimum_size = Vector2(110, 110)
		var orb := PanelContainer.new()
		orb.custom_minimum_size = Vector2(76, 76)
		orb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.color(info[4] as StringName)
		sb.set_corner_radius_all(38)
		sb.border_color = Palette.INK
		sb.set_border_width_all(4)
		orb.add_theme_stylebox_override(&"panel", sb)
		var initial := _label(orb, str(info[0]).substr(0, 1), 40, HORIZONTAL_ALIGNMENT_CENTER)
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(orb)
		var key := _label(slot, str(info[1]), 22, HORIZONTAL_ALIGNMENT_CENTER)
		key.name = "Key"
		slot.visible = false
		_ability_bar.add_child(slot)
		_ability_slots[id] = slot
	_learn_card = PanelContainer.new()
	_learn_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_learn_card.offset_left = -520
	_learn_card.offset_right = 520
	_learn_card.offset_top = -170
	_learn_card.offset_bottom = 120
	_learn_card.modulate.a = 0.0
	_learn_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_learn_card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_learn_card.add_child(box)
	_label(box, "New magic!", 30, HORIZONTAL_ALIGNMENT_CENTER)
	_learn_title = _label(box, "", 64, HORIZONTAL_ALIGNMENT_CENTER)
	_learn_body = _label(box, "", 30, HORIZONTAL_ALIGNMENT_CENTER)
	_learn_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Events.ability_learned.connect(show_ability_learned)


func show_ability_learned(id: StringName) -> void:
	var info: Array = Abilities.INFO.get(id, [])
	if info.is_empty():
		return
	_learn_title.text = str(info[0])
	_learn_title.add_theme_color_override(&"font_color", Palette.color(info[4] as StringName))
	_learn_body.text = "%s\n%s" % [info[2], info[3]]
	AudioDirector.play(&"ability")
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(_learn_card, "modulate:a", 1.0, 0.35)
	t.tween_interval(5.0)
	t.tween_property(_learn_card, "modulate:a", 0.0, 0.6)


func _update_abilities() -> void:
	if player == null:
		return
	for id in _ability_slots:
		var slot := _ability_slots[id]
		slot.visible = player.has_ability(id)
		if not slot.visible:
			continue
		var ready := true
		match id:
			&"fireball":
				ready = player.fireball_cooldown <= 0
			&"thunderclap":
				ready = player.clap_cooldown <= 0
			&"dash":
				ready = player.dash_cooldown <= 0 and (player.is_grounded() or not player.air_dash_used)
			&"glide":
				ready = not player.gliding
		slot.modulate = Color(1.0, 1.0, 1.0, 1.0 if ready else 0.4)


# --- Dialogue (plan §8.7) ---------------------------------------------------------------------

func _build_dialogue(root: Control) -> void:
	_dialogue = PanelContainer.new()
	_dialogue.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_dialogue.offset_left = -720
	_dialogue.offset_right = 720
	_dialogue.offset_top = -330
	_dialogue.offset_bottom = -60
	_dialogue.visible = false
	root.add_child(_dialogue)
	var vb := VBoxContainer.new()
	_dialogue.add_child(vb)
	_dlg_name = Label.new()
	_dlg_name.add_theme_font_size_override(&"font_size", 34)
	_dlg_name.add_theme_color_override(&"font_color", Palette.color(&"roof_red"))
	_dlg_name.add_theme_constant_override(&"outline_size", 0)
	vb.add_child(_dlg_name)
	_dlg_text = Label.new()
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(1300, 150)
	_dlg_text.add_theme_font_size_override(&"font_size", 36)
	_dlg_text.add_theme_color_override(&"font_color", Palette.INK)
	_dlg_text.add_theme_constant_override(&"outline_size", 0)
	vb.add_child(_dlg_text)
	var hint := Label.new()
	hint.text = "E / Space  >"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override(&"font_size", 22)
	hint.add_theme_color_override(&"font_color", Palette.color(&"stone_dark"))
	hint.add_theme_constant_override(&"outline_size", 0)
	vb.add_child(hint)


func is_dialogue_open() -> bool:
	return _dialogue.visible


func open_dialogue(lines: Array, p: Player) -> void:
	if lines.is_empty() or _dialogue.visible:
		return
	_dlg_lines = lines
	_dlg_index = 0
	_dlg_player = p
	p.set_talking(true)
	_dialogue.visible = true
	_dlg_ignore_frames = 2
	AudioDirector.set_ducked(true)
	_show_line()


func _show_line() -> void:
	var line := _dlg_lines[_dlg_index] as Dictionary
	_dlg_name.text = str(line.get("speaker", ""))
	_dlg_text.text = str(line.get("text", ""))
	_dlg_text.visible_characters = 0
	_dlg_chars = 0.0
	var flag := str(line.get("set", ""))
	if flag != "":
		Progress.set_flag(StringName(flag))
	AudioDirector.play(&"ui_blip", -8.0)


## Closing always gives control back (plan §8.6).
func close_dialogue() -> void:
	_dialogue.visible = false
	AudioDirector.set_ducked(false)
	if _dlg_player != null and is_instance_valid(_dlg_player):
		_dlg_player.set_talking(false)
		_dlg_player.buffer_age = -1


func _process(delta: float) -> void:
	if _dialogue.visible and not get_tree().paused:
		_dlg_chars += delta * 45.0
		_dlg_text.visible_characters = int(_dlg_chars)
		_dlg_ignore_frames -= 1
		if _dlg_ignore_frames < 0 and (Input.is_action_just_pressed(&"ui_accept_game") or Input.is_action_just_pressed(&"attack")):
			if _dlg_text.visible_characters < _dlg_text.text.length():
				_dlg_chars = _dlg_text.text.length()
			else:
				_dlg_index += 1
				if _dlg_index >= _dlg_lines.size():
					close_dialogue()
				else:
					_show_line()
	if Input.is_action_just_pressed(&"pause") and not Router.busy:
		set_paused(not get_tree().paused)
	_update_prompt()
	if player != null and is_instance_valid(player):
		_breath.set_breath(player.breath / Player.BREATH_MAX, player.head_underwater() or player.breath < Player.BREATH_MAX - 0.05)
		_update_abilities()


func _update_prompt() -> void:
	_prompt.text = ""
	if player == null or not is_instance_valid(player) or _dialogue.visible or player.state != Player.State.NORMAL:
		return
	for n in get_tree().get_nodes_in_group(&"interactable"):
		var t := n as Node3D
		if t != null and t.global_position.distance_to(player.global_position) < Player.INTERACT_RANGE:
			_prompt.text = ("Y" if Settings.last_device_gamepad else "E") + "  Talk"
			return


# --- Pause menu -------------------------------------------------------------------------------

func _build_pause(root: Control) -> void:
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.visible = false
	root.add_child(_pause)
	var dim := ColorRect.new()
	dim.color = Color(Palette.INK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -450
	panel.offset_bottom = 450
	_pause.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 14)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 52)
	vb.add_child(title)
	_button(vb, "Resume", func() -> void: set_paused(false))
	_slider(vb, "Camera distance  (- / = keys)", Settings.CAMERA_DISTANCE_MIN, Settings.CAMERA_DISTANCE_MAX, Settings.camera_distance, func(v: float) -> void: Settings.camera_distance = v)
	_slider(vb, "Camera turn speed", 0.8, 5.0, Settings.stick_sensitivity, func(v: float) -> void: Settings.stick_sensitivity = v)
	_slider(vb, "Music volume", 0.0, 1.0, Settings.music_volume, func(v: float) -> void:
		Settings.music_volume = v
		AudioDirector.apply_volumes())
	_slider(vb, "Sound volume", 0.0, 1.0, Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = v
		AudioDirector.apply_volumes())
	_slider(vb, "Screen shake", 0.0, 1.0, Settings.screen_shake, func(v: float) -> void: Settings.screen_shake = v)
	var inv := CheckBox.new()
	inv.text = "Invert camera Y"
	inv.button_pressed = Settings.invert_y
	inv.add_theme_color_override(&"font_color", Palette.INK)
	inv.toggled.connect(func(on: bool) -> void: Settings.invert_y = on)
	vb.add_child(inv)
	_button(vb, "Return to Mossbrook", func() -> void:
		set_paused(false)
		Progress.set_resume(Progress.HUB_SCENE, &"hub_rootway_exit")
		Router.go_to(Progress.HUB_SCENE, &"hub_rootway_exit"))
	_button(vb, "Quit to title", func() -> void:
		set_paused(false)
		Router.go_to_path("res://scenes/ui/title.tscn"))


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _slider(parent: Control, text: String, lo: float, hi: float, value: float, cb: Callable) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", 24)
	l.add_theme_color_override(&"font_color", Palette.INK)
	l.add_theme_constant_override(&"outline_size", 0)
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = value
	s.value_changed.connect(cb)
	parent.add_child(s)


func set_paused(on: bool) -> void:
	get_tree().paused = on
	_pause.visible = on
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		(_pause.get_child(1).get_child(0).get_child(1) as Button).grab_focus()
	else:
		Settings.save_settings()
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
