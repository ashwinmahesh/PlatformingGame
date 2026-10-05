class_name ErrandItem
extends Area3D
## Something a villager has lost (Build 6 side tasks): touch it to pick it up (sets a flag), then
## talk to the villager for the reward.

var flag: StringName
var label_text: String = "Lost item"
var color_name: StringName = &"candy_pink"
var _visual: Node3D
var _t: float = 0.0


func _ready() -> void:
	if Progress.has_flag(flag):
		queue_free()
		return
	collision_layer = Layers.INTERACT
	collision_mask = Layers.PLAYER_BODY
	var s := SphereShape3D.new()
	s.radius = 1.0
	Kit.add_shape(self, s, Vector3(0.0, 0.8, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	var gift := RoundMesh.box(Vector3(0.8, 0.7, 0.8), 0.15)
	Kit.mesh_instance(_visual, gift, Kit.mat(color_name, 0.03), Vector3(0.0, 0.8, 0.0))
	var ribbon := RoundMesh.box(Vector3(0.85, 0.12, 0.25), 0.04)
	Kit.mesh_instance(_visual, ribbon, Kit.mat(&"gold"), Vector3(0.0, 1.16, 0.0))
	Kit.label(self, Vector3(0.0, 2.0, 0.0), label_text, 28)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	if _visual != null:
		_visual.rotation.y += delta * 1.5
		_visual.position.y = sin(_t * 2.5) * 0.15


func _on_body(b: Node3D) -> void:
	if b is Player and not Progress.has_flag(flag):
		Progress.set_flag(flag)
		AudioDirector.play(&"heart")
		var hud := get_tree().get_first_node_in_group(&"hud") as Hud
		if hud != null:
			hud.show_banner("Found: %s!" % label_text, 1.8)
		queue_free()
