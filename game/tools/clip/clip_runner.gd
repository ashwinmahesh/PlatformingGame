extends Node
## Clip scenarios for `make clip NAME=...` (plan §7.3): scripted input on the real game, recorded
## with Movie Maker mode. Scenarios: triple_jump, plunge_springcap, slash_combo.

var _level: Level
var _inp: ScriptedInput
var _t: int = 0
var _scenario: String = "triple_jump"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			_scenario = a.get_slice("=", 1)
	Router.pending_spawn = &"w1_entrance"
	var scene := "res://scenes/levels/w1/glimmerbrook.tscn"
	if _scenario == "hub_portal":
		Router.pending_spawn = &"hub_rootway_exit"
		scene = "res://scenes/hub/mossbrook.tscn"
	_level = (load(scene) as PackedScene).instantiate() as Level
	add_child(_level)
	# Scene changes (portals) free this node, so the safety quit lives on the tree.
	get_tree().create_timer(14.0).timeout.connect(func() -> void:
		AudioDirector.quit_game())
	_inp = ScriptedInput.new()
	_level.player.input_source = _inp
	if _scenario == "plunge_springcap":
		_level.player.respawn_at(Vector3(0.0, 5.05, -62.0))
	if _scenario == "magic":
		_level.player.abilities_override = [&"fireball", &"glide", &"thunderclap", &"dash"]


func _physics_process(_delta: float) -> void:
	_t += 1
	match _scenario:
		"triple_jump":
			_inp.move = Vector2(0.0, 1.0) if _t > 20 else Vector2.ZERO
			if _t in [40, 62, 84]:
				_inp.tap(&"jump")
		"plunge_springcap":
			_inp.move = Vector2(0.0, 0.6) if (_t > 10 and _t < 26) or _t > 80 else Vector2.ZERO
			if _t == 10:
				_inp.tap(&"jump")
			if _t == 30:
				_inp.tap(&"plunge")
		"hub_portal":
			# Turn around and walk into the Rootway arch; the world should load behind the wipe.
			_inp.move = Vector2(0.0, -1.0) if _t > 30 else Vector2.ZERO
		"slash_combo":
			if _t in [20, 32, 46]:
				_inp.tap(&"attack")
		"magic":
			# Fireball, Thunderclap, then a jump held into a Glide and an Air Dash.
			if _t in [20, 48]:
				_inp.tap(&"fireball")
			if _t == 80:
				_inp.tap(&"thunderclap")
			_inp.move = Vector2(0.0, 1.0) if _t > 120 else Vector2.ZERO
			if _t == 130:
				_inp.press(&"jump")
			if _t == 150:
				_inp.release(&"jump")
			if _t == 156:
				_inp.press(&"jump")
			if _t == 176:
				_inp.release(&"jump")
			if _t == 182:
				_inp.press(&"jump")
			if _t == 260:
				_inp.tap(&"dash")
	if _t > (360 if _scenario in ["hub_portal", "magic"] else 200):
		AudioDirector.quit_game()
