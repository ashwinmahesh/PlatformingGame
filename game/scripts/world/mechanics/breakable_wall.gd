class_name BreakableWall
extends StaticBody3D
## Cracked rock or an ice block: three sword hits or one Plunge breaks it (Build 4).

var size: Vector3 = Vector3(4.0, 4.0, 1.5)
var color_name: StringName = &"water_light"
var hp: int = 3
var _last_id: int = -1
var _mi: MeshInstance3D
var _mat: ShaderMaterial


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	collision_mask = 0
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, size.y * 0.5, 0.0))
	_mat = Kit.unique_mat(color_name, 0.0)
	_mi = Kit.mesh_instance(self, RoundMesh.box(size, 0.3), _mat, Vector3(0.0, size.y * 0.5, 0.0))
	for i in 3:
		var crack := BoxMesh.new()
		crack.size = Vector3(0.08, size.y * 0.5, 0.05)
		var c := Kit.mesh_instance(self, crack, Kit.mat(&"bark_dark"), Vector3(-0.8 + i * 0.8, size.y * (0.4 + 0.1 * i), size.z * 0.5 + 0.01))
		c.rotation.z = 0.4 - i * 0.35
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var hb := BoxShape3D.new()
	hb.size = size + Vector3.ONE * 0.4
	Kit.add_shape(area, hb, Vector3(0.0, size.y * 0.5, 0.0))
	add_child(area)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	hp -= 3 if plunge else 1
	_mat.set_shader_parameter(&"flash", 0.8)
	create_tween().tween_method(func(v: float) -> void: _mat.set_shader_parameter(&"flash", v), 0.8, 0.0, 0.2)
	if hp <= 0:
		AudioDirector.play(&"coconut_break")
		Fx.burst(get_parent(), global_position + Vector3.UP * size.y * 0.5, Palette.color(color_name), 24, 6.0, 0.2, -10.0, 0.8)
		queue_free()
	else:
		AudioDirector.play(&"hit", -2.0, 0.8)
	return {"hit": true, "bounce": float(atk.get("bounce", 2.2)) if plunge else 0.0}
