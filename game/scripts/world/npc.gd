class_name Npc
extends Node3D
## Villager (plan §8.6): idle, face the player within 4 m, show a speech bubble within 2 m,
## talk on interact. All three share one body and differ by parts, scale and colour.

var npc_id: String = "elder_fern"
var display_name: String = ""
var tunic: StringName = &"roof_teal"
var hat: StringName = &"thatch"
var skin: StringName = &"skin_mid"
var body_scale: float = 1.0
## Build 6 side task: once `errand_flag` is set (an ErrandItem was found), talking hands over
## `reward_seed` (a Glimmer Seed of this world).
var errand_flag: StringName = &""
var reward_seed: StringName = &""
## Build 5 (Bubbleton Reef): a glass diving bubble round the head.
var bubble_helmet: bool = false
## Villagers share one rig (KayKit Adventurers, CC0) and differ by outfit and scale (plan §11.4).
const MODELS: Dictionary[String, Array] = {
	"elder_fern": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.6, ["Spellbook", "Spellbook_open", "1H_Wand"]],
	"pip": ["res://assets/models/kaykit_adventurers/Knight.glb", 0.48, ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "1H_Sword", "2H_Sword"]],
	"old_bramble": ["res://assets/models/kaykit_adventurers/Barbarian.glb", 0.62, ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe"]],
	# Build 4: travellers in the new worlds and more villagers in Mossbrook.
	"sandy": ["res://assets/models/kaykit_adventurers/Rogue_Hooded.glb", 0.58, ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]],
	"cobble": ["res://assets/models/kaykit_adventurers/Knight.glb", 0.6, ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "1H_Sword", "2H_Sword"]],
	"lumen": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.55, ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]],
	"tundra": ["res://assets/models/kaykit_adventurers/Barbarian.glb", 0.66, ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe"]],
	"marlo": ["res://assets/models/kaykit_adventurers/Rogue.glb", 0.6, ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]],
	"bea": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.58, ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]],
	"barnacle": ["res://assets/models/kaykit_adventurers/Barbarian.glb", 0.64, ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe"]],
	"coralie": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.56, ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]],
	"skye": ["res://assets/models/kaykit_adventurers/Rogue_Hooded.glb", 0.55, ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]],
	"quill": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.58, ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]],
	"dusty": ["res://assets/models/kaykit_adventurers/Barbarian.glb", 0.6, ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe"]],
	"puffle": ["res://assets/models/kaykit_adventurers/Mage.glb", 0.6, ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]],
	"finn": ["res://assets/models/kaykit_adventurers/Rogue_Hooded.glb", 0.5, ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]],
	"kip": ["res://assets/models/kaykit_adventurers/Knight.glb", 0.44, ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "1H_Sword", "2H_Sword"]],
}

## Room for future services (plan §8.8); empty in Release 1.
var services: Array[StringName] = []
var _visual: Node3D
var _model: CharacterModel
var _talk_left: float = 0.0
var _bubble: Label3D
var _hop: float = 0.0


func _ready() -> void:
	add_to_group(&"interactable")
	_visual = Node3D.new()
	add_child(_visual)
	var spec: Array = MODELS.get(npc_id, MODELS["elder_fern"])
	var hidden: Array[String] = []
	hidden.assign(spec[2] as Array)
	_model = CharacterModel.create(str(spec[0]), float(spec[1]) * body_scale, hidden, 0.035)
	_visual.add_child(_model)
	_model.play(&"Idle")
	if bubble_helmet:
		var glass := SphereMesh.new()
		glass.radius = 0.62 * body_scale
		glass.height = 1.24 * body_scale
		Kit.mesh_instance(_visual, glass, Fx.fx_mat(Color(Palette.color(&"bubble"), 0.28)), Vector3(0.0, 1.55 * body_scale, 0.0))
		var rim := TorusMesh.new()
		rim.inner_radius = 0.45 * body_scale
		rim.outer_radius = 0.58 * body_scale
		Kit.mesh_instance(_visual, rim, Kit.mat(&"gold"), Vector3(0.0, 1.05 * body_scale, 0.0))
	_bubble = Kit.label(self, Vector3(0.0, 2.3 * body_scale, 0.0), "...", 64)
	_bubble.visible = false
	Kit.label(self, Vector3(0.0, 2.75 * body_scale, 0.0), display_name, 28)
	# Solid so you can't walk through villagers.
	var body := Kit.static_body(self, Vector3.ZERO, Layers.WORLD)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45 * body_scale
	cap.height = 1.6 * body_scale
	Kit.add_shape(body, cap, Vector3(0.0, 0.8 * body_scale, 0.0))


func _process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	var to := p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	if d < 4.0 and d > 0.1:
		var want := Basis.looking_at(to.normalized(), Vector3.UP)
		_visual.basis = _visual.basis.orthonormalized().slerp(want, 1.0 - exp(-6.0 * delta))
	_bubble.visible = d < 2.2 and p.state != Player.State.TALK
	_hop = maxf(_hop - delta * 3.0, 0.0)
	_talk_left = maxf(_talk_left - delta, 0.0)
	if _hop > 0.0:
		_model.play(&"Cheer", 0.15)
	elif _talk_left > 0.0 or p.state == Player.State.TALK and d < 3.0:
		_model.play(&"Interact", 0.2)
	else:
		_model.play(&"Idle", 0.3)


func interact(p: Player) -> void:
	if errand_flag != &"" and reward_seed != &"" and Progress.has_flag(errand_flag) and not Progress.has_seed(reward_seed):
		Progress.collect_seed(reward_seed)
		AudioDirector.play(&"seed")
		emote_joy()
		var h := get_tree().get_first_node_in_group(&"hud") as Hud
		if h != null:
			h.open_dialogue([{"speaker": display_name, "text": "You found it! Thank you! Here, take this Glimmer Seed."}], p)
		return
	var data := DialogueData.load_npc(npc_id)
	var lines := DialogueData.pick_lines(data)
	if lines.is_empty():
		return
	_talk_left = 1.2
	var hud := get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null:
		hud.open_dialogue(lines, p)


func emote_joy() -> void:
	_hop = 2.5
