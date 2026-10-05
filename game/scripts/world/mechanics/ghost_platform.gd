class_name GhostPlatform
extends StaticBody3D
## A see-through platform that turns solid when its switches are solved (Build 4 puzzles).

var size: Vector3 = Vector3(4.0, 0.8, 4.0)
var color_name: StringName = &"portal_teal"
var solid: bool = false
var _shape: CollisionShape3D
var _mi: MeshInstance3D
var _ghost_mat: ShaderMaterial


func _ready() -> void:
	collision_mask = 0
	var b := BoxShape3D.new()
	b.size = size
	_shape = Kit.add_shape(self, b, Vector3(0.0, -size.y * 0.5, 0.0))
	_ghost_mat = Fx.fx_mat(Color(Palette.color(color_name), 0.25))
	_mi = Kit.mesh_instance(self, RoundMesh.box(size, 0.25), _ghost_mat, Vector3(0.0, -size.y * 0.5, 0.0))
	set_solid(solid)


func set_solid(on: bool) -> void:
	solid = on
	collision_layer = Layers.WORLD if on else 0
	_mi.material_override = Kit.mat(color_name, 0.0) if on else _ghost_mat
	if on and is_inside_tree():
		_mi.scale = Vector3(1.0, 0.2, 1.0)
		create_tween().tween_property(_mi, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
