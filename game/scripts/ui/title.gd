extends Control
## Title screen: Continue (when a save exists), New Game, Quit.

var _continue: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	var had_save := Progress.has_save()
	var loaded := Progress.load_save()
	AudioDirector.play_music(&"mossbrook")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var grad := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec3 top_col : source_color = vec3(0.431, 0.776, 1.0);
uniform vec3 bottom_col : source_color = vec3(0.365, 0.702, 0.231);
void fragment() {
	float hills = 0.72 + sin(UV.x * 9.0) * 0.03 + sin(UV.x * 23.0 + 1.0) * 0.015;
	vec3 sky = mix(top_col, vec3(0.749, 0.902, 1.0), UV.y);
	COLOR = vec4(UV.y > hills ? bottom_col : sky, 1.0);
}"""
	grad.shader = sh
	bg.material = grad
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vb.offset_left = -360
	vb.offset_right = 360
	vb.offset_top = -330
	vb.offset_bottom = 330
	vb.add_theme_constant_override(&"separation", 22)
	add_child(vb)
	var title := Label.new()
	title.text = "Sproutblade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 120)
	title.add_theme_color_override(&"font_color", Palette.color(&"gold"))
	title.add_theme_color_override(&"font_outline_color", Palette.INK)
	title.add_theme_constant_override(&"outline_size", 28)
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "A tiny hero, a springy triple jump, and a lot of slime"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override(&"font_size", 30)
	sub.add_theme_color_override(&"font_outline_color", Palette.INK)
	sub.add_theme_constant_override(&"outline_size", 10)
	vb.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vb.add_child(spacer)
	var theme_holder := Hud.new()
	vb.theme = theme_holder._make_theme()
	theme_holder.free()
	_continue = _button(vb, "Continue", _on_continue)
	_continue.visible = loaded or had_save
	_button(vb, "New Game", _on_new_game)
	_button(vb, "Quit", func() -> void: AudioDirector.quit_game())
	(_continue if _continue.visible else vb.get_child(4) as Button).grab_focus()
	var help := Label.new()
	help.text = "WASD move  ·  Arrow keys camera  ·  Space jump (x3)  ·  F attack\nShift Plunge  ·  E talk  ·  Q lock-on  ·  Esc pause  ·  F1 Feel Lab"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override(&"font_size", 24)
	help.add_theme_color_override(&"font_outline_color", Palette.INK)
	help.add_theme_constant_override(&"outline_size", 8)
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_left = -900
	help.offset_right = 900
	help.offset_top = -120
	help.offset_bottom = -30
	add_child(help)


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override(&"font_size", 40)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _on_continue() -> void:
	var target := Progress.resume_target()
	Router.go_to(target[0], target[1])


func _on_new_game() -> void:
	Progress.new_game()
	Router.go_to(Progress.HUB_SCENE, &"hub_arrival")
