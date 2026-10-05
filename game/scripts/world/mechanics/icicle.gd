class_name Icicle
extends Node3D
## Hangs over a path; when the hero walks underneath, it trembles, a ring marks the impact spot,
## then it drops (½ heart) and grows back (Build 4, Frostfang Peak).

enum S { HANGING, SHAKING, FALLING, REGROW }

var ground_y: float = 0.0
var state: S = S.HANGING
var _t: float = 0.0
var _home: Vector3
var _spike: MeshInstance3D
var _ring: MeshInstance3D


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	_home = position
	var cone := CylinderMesh.new()
	cone.top_radius = 0.45
	cone.bottom_radius = 0.0
	cone.height = 1.8
	_spike = Kit.mesh_instance(self, cone, Kit.mat(&"water_light", 0.03), Vector3(0.0, -0.9, 0.0))
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.8
	tm.outer_radius = 1.0
	_ring.mesh = tm
	_ring.material_override = Fx.fx_mat(Color(Palette.color(&"roof_red"), 0.85))
	_ring.top_level = true
	_ring.visible = false
	_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_ring)


func _physics_process(delta: float) -> void:
	_t += delta
	match state:
		S.HANGING:
			var p := get_tree().get_first_node_in_group(&"player") as Player
			if p != null and Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < 2.6 and p.global_position.y < global_position.y:
				state = S.SHAKING
				_t = 0.0
				_ring.visible = true
				_ring.global_position = Vector3(global_position.x, ground_y + 0.08, global_position.z)
				_ring.scale = Vector3(1.0, 0.3, 1.0)
		S.SHAKING:
			_spike.position.x = sin(_t * 70.0) * 0.06
			if _t >= 0.7:
				state = S.FALLING
				_t = 0.0
		S.FALLING:
			position.y -= (8.0 + _t * 40.0) * delta
			if global_position.y - 1.8 <= ground_y:
				Fx.burst(get_parent(), Vector3(global_position.x, ground_y + 0.3, global_position.z), Palette.color(&"water_light"), 14, 4.0, 0.12)
				AudioDirector.play(&"coconut_break", -6.0, 1.4)
				state = S.REGROW
				_t = 0.0
				visible = false
				_ring.visible = false
		S.REGROW:
			if _t >= 4.0:
				position = _home
				visible = true
				_spike.scale = Vector3.ONE * 0.1
				create_tween().tween_property(_spike, "scale", Vector3.ONE, 0.6)
				state = S.HANGING


func damage_to_player(p: Player) -> Dictionary:
	if state != S.FALLING:
		return {}
	var tip := global_position + Vector3.DOWN * 1.6
	var d := p.global_position + Vector3.UP * 0.6 - tip
	if Vector2(d.x, d.z).length() > 0.8 or absf(d.y) > 1.0:
		return {}
	return {"halves": 1, "from": tip, "cause": "icicle"}
