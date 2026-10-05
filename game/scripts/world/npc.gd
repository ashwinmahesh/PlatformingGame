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
## Room for future services (plan §8.8); empty in Release 1.
var services: Array[StringName] = []
var _visual: Node3D
var _bubble: Label3D
var _hop: float = 0.0


func _ready() -> void:
	add_to_group(&"interactable")
	_visual = Node3D.new()
	_visual.scale = Vector3.ONE * body_scale
	add_child(_visual)
	var torso := CapsuleMesh.new()
	torso.radius = 0.32
	torso.height = 0.85
	Kit.mesh_instance(_visual, torso, Kit.mat(tunic, 0.025), Vector3(0.0, 0.45, 0.0))
	var head := SphereMesh.new()
	head.radius = 0.34
	head.height = 0.64
	Kit.mesh_instance(_visual, head, Kit.mat(skin, 0.025), Vector3(0.0, 1.05, 0.0))
	var h := CylinderMesh.new()
	h.top_radius = 0.1
	h.bottom_radius = 0.45
	h.height = 0.28
	Kit.mesh_instance(_visual, h, Kit.mat(hat, 0.025), Vector3(0.0, 1.35, 0.0))
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.05
		eye.height = 0.1
		Kit.mesh_instance(_visual, eye, Kit.mat(&"bark_dark"), Vector3(0.12 * side, 1.07, -0.3))
	_bubble = Kit.label(self, Vector3(0.0, 2.1 * body_scale, 0.0), "...", 64)
	_bubble.visible = false
	Kit.label(self, Vector3(0.0, 2.45 * body_scale, 0.0), display_name, 28)
	# Solid so you can't walk through villagers.
	var body := Kit.static_body(self, Vector3.ZERO, Layers.WORLD)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35 * body_scale
	cap.height = 1.5 * body_scale
	Kit.add_shape(body, cap, Vector3(0.0, 0.75 * body_scale, 0.0))


func _process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	var to := p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	if d < 4.0 and d > 0.1:
		var want := Basis.looking_at(to.normalized(), Vector3.UP)
		_visual.basis = _visual.basis.orthonormalized().slerp(want, 1.0 - exp(-6.0 * delta)).scaled(Vector3.ONE * body_scale)
	_bubble.visible = d < 2.2 and p.state != Player.State.TALK
	_hop = maxf(_hop - delta * 3.0, 0.0)
	_visual.position.y = sin(_hop * PI) * 0.3 + sin(Time.get_ticks_msec() * 0.003) * 0.02


func interact(p: Player) -> void:
	var data := DialogueData.load_npc(npc_id)
	var lines := DialogueData.pick_lines(data)
	if lines.is_empty():
		return
	_hop = 1.0
	var hud := get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null:
		hud.open_dialogue(lines, p)


func emote_joy() -> void:
	_hop = 1.0
