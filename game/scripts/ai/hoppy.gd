class_name Hoppy
extends Critter
## A horned hare (inspired by Dragon Quest's Bunicorn, our own design): stamps, then charges in a
## straight line. Dodge sideways and it skids past; hit a wall and it's dizzy, wide open.

enum S { IDLE, WINDUP, CHARGE, REST, DIZZY }

const SIGHT := 12.0
const CHARGE_SPEED := 11.0
var _dir: Vector3 = Vector3.FORWARD
var _ears: Array[Node3D] = []
var _hop: float = 0.0


func _init() -> void:
	max_hp = 2
	body_radius = 0.55
	body_half_height = 0.5
	body_center = 0.55
	color_name = &"cloth_cream"


func build_body() -> void:
	ball(_visual, 0.55, &"cloth_cream", Vector3(0.0, 0.55, 0.0))
	ball(_visual, 0.18, &"foam", Vector3(0.0, 0.6, 0.55), 0.0)
	for side: float in [-1.0, 1.0]:
		ball(_visual, 0.08, &"bark_dark", Vector3(0.2 * side, 0.75, -0.48), 0.0)
		var ear_root := Node3D.new()
		ear_root.position = Vector3(0.18 * side, 1.0, 0.05)
		_visual.add_child(ear_root)
		var ear := CapsuleMesh.new()
		ear.radius = 0.11
		ear.height = 0.7
		Kit.mesh_instance(ear_root, ear, flashy(&"cloth_cream", 0.02), Vector3(0.0, 0.3, 0.0))
		var inner := CapsuleMesh.new()
		inner.radius = 0.06
		inner.height = 0.5
		Kit.mesh_instance(ear_root, inner, Kit.mat(&"gloop_pink"), Vector3(0.0, 0.3, -0.07))
		_ears.append(ear_root)
		ball(_visual, 0.14, &"cloth_cream", Vector3(0.22 * side, 0.08, -0.25), 0.02)
	var horn := CylinderMesh.new()
	horn.top_radius = 0.0
	horn.bottom_radius = 0.1
	horn.height = 0.45
	var h := Kit.mesh_instance(_visual, horn, Kit.mat(&"gold", 0.02), Vector3(0.0, 1.02, -0.38))
	h.rotation.x = -0.6


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state != S.DIZZY


func think(_delta: float) -> void:
	var p := player_ref()
	match state:
		S.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if is_on_floor() and state_ticks % 70 == 0:
				var wander := flat_to(home + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0)))
				face(wander)
				velocity = wander.limit_length(2.5) + Vector3.UP * 4.0
			if p != null and can_see(p, SIGHT) and state_ticks > 30:
				set_state(S.WINDUP)
				AudioDirector.play(&"notice", -6.0, 1.3)
		S.WINDUP:
			face(flat_to(p.global_position))
			velocity.x = 0.0
			velocity.z = 0.0
			flash(Color(1.0, 0.55, 0.1), 0.3 + 0.3 * absf(sin(state_ticks * 0.6)))
			if state_ticks >= 40:
				flash(Color.WHITE, 0.0)
				_dir = facing
				set_state(S.CHARGE)
		S.CHARGE:
			velocity.x = _dir.x * CHARGE_SPEED
			velocity.z = _dir.z * CHARGE_SPEED
			if is_on_wall():
				AudioDirector.play(&"boss_bonk", -4.0, 1.5)
				Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"gold"), 8, 3.0, 0.1)
				set_state(S.DIZZY)
			elif state_ticks >= 66 or not _ground_ahead():
				set_state(S.REST)
		S.REST:
			velocity.x = move_toward(velocity.x, 0.0, 0.8)
			velocity.z = move_toward(velocity.z, 0.0, 0.8)
			if state_ticks >= 60:
				set_state(S.IDLE)
		S.DIZZY:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 100:
				set_state(S.IDLE)


func _ground_ahead() -> bool:
	var p := global_position + _dir * 1.2 + Vector3.UP
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 2.5, Layers.WORLD)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func animate(delta: float) -> void:
	_hop += delta * (14.0 if state == S.CHARGE else 4.0)
	_visual.position.y = absf(sin(_hop)) * (0.25 if state == S.CHARGE else 0.05)
	for e in _ears:
		e.rotation.x = 0.7 if state == S.CHARGE else (sin(_hop) * 0.1 - (0.6 if state == S.DIZZY else 0.0))
	_visual.rotation.z = sin(state_ticks * 0.3) * 0.3 if state == S.DIZZY else 0.0
