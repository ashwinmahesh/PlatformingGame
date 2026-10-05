class_name VineGate
extends StaticBody3D
## Vine gate that closes behind you at the boss arena (plan §8.5).

var width: float = 6.0
var _closed: bool = false
var _shape: CollisionShape3D
var _visual: Node3D


func _ready() -> void:
	collision_layer = 0
	var b := BoxShape3D.new()
	b.size = Vector3(width, 4.0, 0.6)
	_shape = Kit.add_shape(self, b, Vector3(0.0, 2.0, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	for i in int(width / 0.6):
		var vine := CylinderMesh.new()
		vine.top_radius = 0.12
		vine.bottom_radius = 0.16
		vine.height = 4.0
		var v := Kit.mesh_instance(_visual, vine, Kit.mat(&"leaf_dark", 0.02), Vector3(-width * 0.5 + 0.3 + i * 0.6, 2.0, sin(i * 1.7) * 0.15))
		v.rotation.z = sin(i * 2.3) * 0.12
		Kit.blob(_visual, Vector3(-width * 0.5 + 0.3 + i * 0.6, 1.0 + fmod(i * 1.37, 2.5), 0.15), 0.18, &"gloop_pink" if i % 3 == 0 else &"leaf_teal")
	set_closed(false)


func set_closed(closed: bool) -> void:
	_closed = closed
	collision_layer = Layers.WORLD if closed else 0
	var t := create_tween()
	t.tween_property(_visual, "position:y", 0.0 if closed else -4.2, 0.6).set_trans(Tween.TRANS_BACK)
	if closed:
		AudioDirector.play(&"gate")
