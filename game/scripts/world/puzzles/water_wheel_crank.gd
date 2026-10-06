class_name WaterWheelCrank
extends Node3D
## A sluice wheel: hit it to turn the water to the next level.

signal turned

var _wheel: Node3D
var _last_id: int = -1


func _ready() -> void:
	Kit.pillar(self, Vector3(0.0, 1.2, 0.0), 0.3, 1.2, &"bark_dark", &"")
	_wheel = Node3D.new()
	_wheel.position = Vector3(0.0, 1.6, 0.0)
	add_child(_wheel)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.55
	rim.outer_radius = 0.75
	var r := Kit.mesh_instance(_wheel, rim, Kit.mat(&"roof_red", 0.03))
	r.rotation.x = PI * 0.5
	for i in 4:
		var spoke := Kit.mesh_instance(_wheel, RoundMesh.box(Vector3(0.12, 1.3, 0.12), 0.04), Kit.mat(&"bark_mid"))
		spoke.rotation.z = i * PI * 0.25
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 1.0
	Kit.add_shape(a, s, Vector3(0.0, 1.6, 0.0))
	add_child(a)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	create_tween().tween_property(_wheel, "rotation:z", _wheel.rotation.z + PI * 0.5, 0.4)
	turned.emit()
	return {"hit": true}
