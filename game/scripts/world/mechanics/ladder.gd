class_name Ladder
extends Node3D
## Build 6 (Ashwin: "add ladders as a way to increase vertical accessibility"). A wooden ladder
## standing against a wall; its climbing side faces local +Z. Walk into it to grab on, climb with
## forward/back, jump to let go; climbing past the top steps you off onto the ledge.

var height: float = 6.0
var width: float = 1.3
var color_name: StringName = &"wood_plank"


func _ready() -> void:
	add_to_group(&"ladder")
	var rail_mat := Kit.mat(&"bark_mid", 0.03)
	for side: float in [-1.0, 1.0]:
		Kit.mesh_instance(self, RoundMesh.box(Vector3(0.14, height + 0.6, 0.14), 0.04), rail_mat, Vector3(side * width * 0.5, (height + 0.6) * 0.5, 0.12))
	var rung_mat := Kit.mat(color_name, 0.02)
	var n := int(height / 0.5)
	for i in n:
		Kit.mesh_instance(self, RoundMesh.box(Vector3(width, 0.08, 0.1), 0.03), rung_mat, Vector3(0.0, 0.35 + i * 0.5, 0.12))
	var area := Area3D.new()
	area.collision_layer = Layers.HAZARD
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta(&"ladder", self)
	var box := BoxShape3D.new()
	box.size = Vector3(width + 0.4, height + 0.4, 1.4)
	Kit.add_shape(area, box, Vector3(0.0, height * 0.5, 0.7))
	add_child(area)


func top_y() -> float:
	return global_position.y + height


## The side you climb from (flat, unit).
func out_dir() -> Vector3:
	var z := global_basis.z
	z.y = 0.0
	return z.normalized()
