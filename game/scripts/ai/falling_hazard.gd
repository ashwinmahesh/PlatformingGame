class_name FallingHazard
extends Node3D
## Something falls from the sky onto a marked ring (icicle rain, falling rocks): the ring shows
## for `warn` seconds, then anything inside takes ½ heart (Build 4 bosses).

var warn: float = 1.1
var radius: float = 1.6
var look: StringName = &"icicle"
var _t: float = 0.0
var _hit_done: bool = false
var _ring: MeshInstance3D
var _drop: MeshInstance3D


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.85
	tm.outer_radius = radius
	_ring.mesh = tm
	_ring.material_override = Fx.fx_mat(Color(Palette.color(&"roof_red"), 0.85))
	_ring.scale = Vector3(1.0, 0.25, 1.0)
	_ring.position.y = 0.08
	add_child(_ring)
	if look == &"icicle":
		var cone := CylinderMesh.new()
		cone.top_radius = 0.6
		cone.bottom_radius = 0.0
		cone.height = 2.2
		_drop = Kit.mesh_instance(self, cone, Kit.mat(&"water_light", 0.04), Vector3(0.0, 24.0, 0.0))
	else:
		var s := SphereMesh.new()
		s.radius = 0.9
		s.height = 1.8
		_drop = Kit.mesh_instance(self, s, Kit.mat(&"stone_dark", 0.04), Vector3(0.0, 24.0, 0.0))


func _physics_process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / warn, 0.0, 1.0)
	_drop.position.y = lerpf(24.0, 1.1, k * k)
	_ring.scale = Vector3(1.0 + 0.2 * sin(_t * 18.0), 0.25, 1.0 + 0.2 * sin(_t * 18.0))
	if k >= 1.0 and not _hit_done:
		_hit_done = true
		Fx.burst(get_parent(), global_position + Vector3.UP * 0.4, Palette.color(&"water_light" if look == &"icicle" else &"stone_light"), 12, 4.0, 0.14)
		AudioDirector.play(&"coconut_break", -6.0, 1.3)
	if _t > warn + 0.15:
		queue_free()


func damage_to_player(p: Player) -> Dictionary:
	if not _hit_done or _t > warn + 0.1:
		return {}
	var d := p.global_position - global_position
	if Vector2(d.x, d.z).length() > radius or d.y > 1.6:
		return {}
	return {"halves": 1, "from": global_position, "cause": String(look)}
