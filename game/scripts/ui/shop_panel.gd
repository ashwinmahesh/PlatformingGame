class_name ShopPanel
extends CanvasLayer
## Build 7 Glimmer Seed shop window: up/down to pick, jump/attack/E to buy, Esc or interact on
## "Leave" to close. The hero stands still (talking) while it's open.

var player: Player
var _list: VBoxContainer
var _wallet: Label
var _detail: Label
var _rows: Array[Label] = []
var _index: int = 0
var _ignore: int = 2


static func open(p: Player) -> ShopPanel:
	var panel := ShopPanel.new()
	panel.player = p
	p.get_tree().root.add_child(panel)
	return panel


func _ready() -> void:
	layer = 20
	player.set_talking(true)
	AudioDirector.set_ducked(true)
	var box := PanelContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -520
	box.offset_right = 520
	box.offset_top = -330
	box.offset_bottom = 330
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.2, 0.94)
	sb.border_color = Palette.color(&"gold")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	box.add_theme_stylebox_override(&"panel", sb)
	add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	_add_label(v, "Bramble & Bloom: the Glimmer Seed shop", 34)
	_wallet = _add_label(v, "", 26)
	_wallet.add_theme_color_override(&"font_color", Palette.color(&"gold"))
	_list = VBoxContainer.new()
	v.add_child(_list)
	for id in ShopItems.ORDER:
		_rows.append(_add_label(_list, "", 24))
	_rows.append(_add_label(_list, "", 24))
	_detail = _add_label(v, "", 22)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(960, 60)
	_add_label(v, "Up/Down: choose    Space/E: buy    Esc: leave", 18)
	_refresh()


func _add_label(parent: Control, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	parent.add_child(l)
	return l


func _refresh() -> void:
	_wallet.text = "Glimmer Seeds to spend: %d" % Progress.seeds_to_spend()
	for i in ShopItems.ORDER.size():
		var id := ShopItems.ORDER[i]
		var info: Array = ShopItems.ITEMS[id]
		var tag := ""
		if Progress.has_upgrade(id):
			tag = "  (owned)"
		elif ShopItems.needs(id) != &"" and not Progress.has_upgrade(ShopItems.needs(id)):
			tag = "  (needs %s)" % str((ShopItems.ITEMS[ShopItems.needs(id)] as Array)[0])
		_rows[i].text = "%s %-22s %3d seeds%s" % [">" if i == _index else " ", str(info[0]), int(info[1]), tag]
		_rows[i].modulate = Color.WHITE if Progress.can_buy(id) or i == _index else Color(1, 1, 1, 0.55)
	var leave := _rows[_rows.size() - 1]
	leave.text = "%s Leave" % (">" if _index == ShopItems.ORDER.size() else " ")
	_detail.text = str((ShopItems.ITEMS[ShopItems.ORDER[_index]] as Array)[2]) if _index < ShopItems.ORDER.size() else "Come back with more seeds!"


func _process(_delta: float) -> void:
	_ignore -= 1
	if _ignore > 0:
		return
	if Input.is_action_just_pressed(&"move_back") or Input.is_action_just_pressed(&"ui_down"):
		_index = (_index + 1) % _rows.size()
		AudioDirector.play(&"ui_blip", -10.0)
		_refresh()
	elif Input.is_action_just_pressed(&"move_forward") or Input.is_action_just_pressed(&"ui_up"):
		_index = (_index - 1 + _rows.size()) % _rows.size()
		AudioDirector.play(&"ui_blip", -10.0)
		_refresh()
	elif Input.is_action_just_pressed(&"pause") or Input.is_action_just_pressed(&"ui_cancel"):
		close()
	elif Input.is_action_just_pressed(&"ui_accept_game") or Input.is_action_just_pressed(&"attack"):
		if _index >= ShopItems.ORDER.size():
			close()
		elif Progress.buy(ShopItems.ORDER[_index]):
			AudioDirector.play(&"seed")
			player.apply_upgrades()
			_refresh()
		else:
			AudioDirector.play(&"hit", -6.0, 0.6)


func close() -> void:
	AudioDirector.set_ducked(false)
	if is_instance_valid(player):
		player.set_talking(false)
		player.buffer_age = -1
	queue_free()
