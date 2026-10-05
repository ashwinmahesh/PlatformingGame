class_name TrainingDummy
extends Node3D
## Straw dummy in the training yard: a safe place to try the sword. It wobbles and never dies.

var _visual: Node3D
var _wobble: float = 0.0
var _last_id: int = -1
var _dir: float = 1.0


func _ready() -> void:
	add_to_group(&"lockable")
	_visual = Node3D.new()
	add_child(_visual)
	var post := CylinderMesh.new()
	post.top_radius = 0.08
	post.bottom_radius = 0.1
	post.height = 1.8
	Kit.mesh_instance(_visual, post, Kit.mat(&"bark_mid"), Vector3(0.0, 0.9, 0.0))
	var straw := CapsuleMesh.new()
	straw.radius = 0.35
	straw.height = 1.0
	Kit.mesh_instance(_visual, straw, Kit.mat(&"thatch", 0.025), Vector3(0.0, 1.1, 0.0))
	var head := SphereMesh.new()
	head.radius = 0.25
	head.height = 0.5
	Kit.mesh_instance(_visual, head, Kit.mat(&"cloth_cream", 0.025), Vector3(0.0, 1.8, 0.0))
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	Kit.add_shape(area, cap, Vector3(0.0, 1.0, 0.0))
	add_child(area)
	var body := Kit.static_body(self, Vector3.ZERO, Layers.WORLD)
	var bs := CylinderShape3D.new()
	bs.radius = 0.3
	bs.height = 1.6
	Kit.add_shape(body, bs, Vector3(0.0, 0.8, 0.0))


func is_lockable() -> bool:
	return true


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	if id == _last_id:
		return {"bounce": float(atk.get("bounce", 2.2)) if plunge else 0.0}
	_last_id = id
	_wobble = 1.0
	var from := atk.get("from", global_position) as Vector3
	_dir = signf(global_position.x - from.x + 0.001)
	return {"hit": true, "bounce": float(atk.get("bounce", 2.2)) if plunge else 0.0}


func _process(delta: float) -> void:
	_wobble = maxf(_wobble - delta * 1.5, 0.0)
	_visual.rotation.z = sin(_wobble * 18.0) * _wobble * 0.35 * _dir
