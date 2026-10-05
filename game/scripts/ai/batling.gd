class_name Batling
extends Critter
## A little bat (inspired by Dragon Quest's Dracky, our own design): hovers, then swoops at the
## spot where you stood when its wings flashed. One hit pops it; a Plunge bounces you off it.

enum S { HOVER, WINDUP, SWOOP, RETURN }

const SIGHT := 13.0
var _target: Vector3
var _wings: Array[Node3D] = []
var _flap: float = 0.0


func _init() -> void:
	max_hp = 1
	body_radius = 0.5
	body_half_height = 0.45
	body_center = 0.5
	uses_gravity = false
	color_name = &"roof_blue"
	drop_heart_chance = 0.2


func build_body() -> void:
	ball(_visual, 0.5, &"roof_blue", Vector3(0.0, 0.5, 0.0))
	ball(_visual, 0.3, &"skin_light", Vector3(0.0, 0.42, -0.3), 0.0)
	for side: float in [-1.0, 1.0]:
		ball(_visual, 0.08, &"bark_dark", Vector3(0.16 * side, 0.62, -0.44), 0.0)
		var ear := CylinderMesh.new()
		ear.top_radius = 0.0
		ear.bottom_radius = 0.16
		ear.height = 0.4
		Kit.mesh_instance(_visual, ear, flashy(&"roof_blue", 0.02), Vector3(0.25 * side, 1.0, 0.0))
		var fang := CylinderMesh.new()
		fang.top_radius = 0.04
		fang.bottom_radius = 0.0
		fang.height = 0.14
		Kit.mesh_instance(_visual, fang, Kit.mat(&"foam"), Vector3(0.08 * side, 0.3, -0.48))
		var wing := Node3D.new()
		wing.position = Vector3(0.45 * side, 0.6, 0.0)
		_visual.add_child(wing)
		var w := PrismMesh.new()
		w.size = Vector3(0.9, 0.5, 0.06)
		var wm := Kit.mesh_instance(wing, w, flashy(&"portal_magenta", 0.02), Vector3(0.45 * side, 0.0, 0.0))
		wm.rotation.z = -PI * 0.5 * side
		_wings.append(wing)


func state_name() -> String:
	return S.keys()[state]


func think(delta: float) -> void:
	var p := player_ref()
	match state:
		S.HOVER:
			var bob := Vector3(sin(state_ticks * 0.03) * 1.5, sin(state_ticks * 0.07) * 0.5, cos(state_ticks * 0.025) * 1.5)
			velocity = ((home + bob) - global_position) * 2.0
			if p != null and can_see(p, SIGHT) and state_ticks > 40:
				set_state(S.WINDUP)
		S.WINDUP:
			velocity = velocity.lerp(Vector3.ZERO, 0.2)
			face(flat_to(p.global_position))
			flash(Color(1.0, 0.55, 0.1), 0.3 + 0.3 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 36:
				flash(Color.WHITE, 0.0)
				_target = p.global_position + Vector3.UP * 0.6
				AudioDirector.play(&"slash", -8.0, 1.4)
				set_state(S.SWOOP)
		S.SWOOP:
			var to := _target - global_position
			velocity = to.normalized() * 14.0
			if to.length() < 0.6 or state_ticks > 70 or get_slide_collision_count() > 0:
				set_state(S.RETURN)
		S.RETURN:
			var back := home - global_position
			velocity = back.normalized() * minf(7.0, back.length() * 3.0)
			if back.length() < 0.5:
				set_state(S.HOVER)
	_flap += delta * (30.0 if state == S.WINDUP else 16.0)


func animate(_delta: float) -> void:
	for i in _wings.size():
		_wings[i].rotation.z = sin(_flap) * 0.7 * (1.0 if i == 0 else -1.0)
	if state != S.WINDUP:
		var v := velocity
		v.y = 0.0
		if v.length() > 0.5:
			face(v)
