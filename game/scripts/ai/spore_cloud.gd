class_name SporeCloud
extends Node3D
## A Shroomlet's puff of spores: stings (½ heart) and slows while you stand in it.

var radius: float = 2.4
var life: float = 2.6
var _t: float = 0.0
var _hit_cool: float = 0.0
var _mi: MeshInstance3D
var _mat: ShaderMaterial


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 1.4
	_mat = Fx.fx_mat(Color(Palette.color(&"portal_magenta"), 0.35))
	_mi = Kit.mesh_instance(self, s, _mat, Vector3(0.0, radius * 0.5, 0.0))
	_mi.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_mi, "scale", Vector3.ONE, 0.35)
	Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"portal_magenta"), 16, 3.0, 0.14, -1.0, 1.2)


func _physics_process(delta: float) -> void:
	_t += delta
	_hit_cool -= delta
	if _t > life - 0.5:
		_mat.set_shader_parameter(&"tint", Color(Palette.color(&"portal_magenta"), 0.35 * (life - _t) / 0.5))
	if _t >= life:
		queue_free()


func damage_to_player(p: Player) -> Dictionary:
	if _hit_cool > 0.0:
		return {}
	var d := p.global_position + Vector3.UP * 0.6 - (global_position + Vector3.UP * radius * 0.5)
	if d.length() > radius:
		return {}
	p.apply_slow(1.0)
	_hit_cool = 1.0
	return {"halves": 1, "from": global_position, "cause": "spores"}
