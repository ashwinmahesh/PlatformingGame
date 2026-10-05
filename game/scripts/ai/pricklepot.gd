class_name Pricklepot
extends Critter
## A round cactus in a clay pot (inspired by Dragon Quest's cactus monsters, our own design). It
## hides in the sand with only its flower showing, pops up when you come close and spins at you
## with its spikes out: sword hits bounce off. Build 6: as it pops it fires a fan of needles
## (slash them, or glide over). When the spin ends it's dizzy, and open to hits.

enum S { HIDDEN, POP, SPIN, DIZZY, SINK }

const NOTICE := 7.0
const SPIN_SPEED := 3.4

var _body: Node3D
var _spikes: Array[Node3D] = []
var _spin: float = 0.0


func _init() -> void:
	model_spec = ["Cactoro", 1.8, PI]
	max_hp = 2
	body_radius = 0.7
	body_half_height = 0.75
	body_center = 0.8
	color_name = &"leaf_teal"
	drop_heart_chance = 0.35


func build_body() -> void:
	_body = Node3D.new()
	_visual.add_child(_body)
	var pot := CylinderMesh.new()
	pot.top_radius = 0.62
	pot.bottom_radius = 0.45
	pot.height = 0.6
	Kit.mesh_instance(_body, pot, flashy(&"roof_red", 0.03), Vector3(0.0, 0.3, 0.0))
	var rim := TorusMesh.new()
	rim.inner_radius = 0.5
	rim.outer_radius = 0.7
	Kit.mesh_instance(_body, rim, flashy(&"wood_warm", 0.02), Vector3(0.0, 0.6, 0.0))
	var cactus := ball(_body, 0.62, &"leaf_teal", Vector3(0.0, 1.05, 0.0))
	cactus.scale = Vector3(1.0, 1.1, 1.0)
	for side: float in [-1.0, 1.0]:
		ball(_body, 0.09, &"bark_dark", Vector3(0.2 * side, 1.15, -0.55), 0.0)
		var arm := ball(_body, 0.24, &"leaf_teal", Vector3(0.7 * side, 1.05, 0.0))
		arm.scale = Vector3(0.8, 1.3, 0.8)
	ball(_body, 0.06, &"gloop_pink", Vector3(0.0, 0.92, -0.58), 0.0)
	for i in 5:
		var petal := ball(_body, 0.14, &"gloop_pink" if i % 2 == 0 else &"roof_red", Vector3(cos(i * TAU / 5.0) * 0.14, 1.78, sin(i * TAU / 5.0) * 0.14), 0.0)
		petal.scale = Vector3(1.0, 0.5, 1.0)
	ball(_body, 0.08, &"gold", Vector3(0.0, 1.82, 0.0), 0.0)
	for i in 10:
		var a := float(i) / 10.0 * TAU
		var root := Node3D.new()
		root.position = Vector3(cos(a) * 0.62, 1.0 + (0.15 if i % 2 == 0 else -0.15), sin(a) * 0.62)
		root.rotation.y = -a
		_body.add_child(root)
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.07
		spike.height = 0.4
		var sm := Kit.mesh_instance(root, spike, Kit.mat(&"cloth_cream", 0.01), Vector3(0.15, 0.0, 0.0))
		sm.rotation.z = -PI * 0.5
		root.scale = Vector3.ONE * 0.3
		_spikes.append(root)
	_body.position.y = -1.3


func model_parent() -> Node3D:
	return _body


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state in [S.POP, S.SPIN]


func is_lockable() -> bool:
	return super.is_lockable() and state != S.HIDDEN


func on_hit(atk: Dictionary) -> Dictionary:
	if state == S.HIDDEN:
		return {}
	if state in [S.POP, S.SPIN] and StringName(str(atk.get("kind", ""))) == &"thunder":
		set_state(S.DIZZY)
	elif state in [S.POP, S.SPIN]:
		AudioDirector.play(&"hit", 0.0, 1.9)
		Fx.burst(get_parent(), global_position + Vector3.UP * 1.0, Palette.color(&"cloth_cream"), 6, 3.0, 0.07)
		return {"hit": true, "blocked": true}
	take(int(atk.get("damage", 1)) + (1 if StringName(str(atk.get("kind", ""))) == &"plunge" else 0), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.HIDDEN:
			velocity = Vector3(0.0, velocity.y, 0.0)
			if p != null and to.length() < NOTICE and state_ticks > 40 and p.state != Player.State.DEAD:
				AudioDirector.play(&"notice", -6.0, 1.6)
				set_state(S.POP)
		S.POP:
			# Build 6 roster: spikes bristle (the tell), then a fan of five needles, then the spin.
			face(to)
			flash(Color(1.0, 0.55, 0.1), 0.3 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 30:
				flash(Color.WHITE, 0.0)
				_needle_fan()
				set_state(S.SPIN)
		S.SPIN:
			var dir := to.normalized() if to.length() > 0.3 else facing
			velocity.x = dir.x * SPIN_SPEED
			velocity.z = dir.z * SPIN_SPEED
			if state_ticks >= 150 or (to.length() > NOTICE * 2.0):
				AudioDirector.play(&"boss_bonk", -8.0, 1.8)
				set_state(S.DIZZY)
		S.DIZZY:
			velocity.x = move_toward(velocity.x, 0.0, 0.5)
			velocity.z = move_toward(velocity.z, 0.0, 0.5)
			if state_ticks >= 120:
				set_state(S.SINK)
		S.SINK:
			velocity = Vector3(0.0, velocity.y, 0.0)
			if state_ticks >= 30:
				set_state(S.HIDDEN)


func _needle_fan() -> void:
	AudioDirector.play(&"slash", -6.0, 1.7)
	for i in 5:
		var shot := EnemyShot.new()
		shot.kind = EnemyShot.Kind.NEEDLE
		shot.color_name = &"cloth_cream"
		get_parent().add_child(shot)
		shot.shoot(global_position + Vector3.UP * 1.0, facing.rotated(Vector3.UP, deg_to_rad(-40.0 + i * 20.0)), 11.0)


func animate(delta: float) -> void:
	var target_y := -1.3
	match state:
		S.POP, S.SPIN, S.DIZZY:
			target_y = 0.0
	_body.position.y = lerpf(_body.position.y, target_y, 1.0 - exp(-(14.0 if state == S.POP else 5.0) * delta))
	var spiky := state in [S.POP, S.SPIN]
	for s in _spikes:
		s.scale = s.scale.lerp(Vector3.ONE * (1.0 if spiky else 0.3), 1.0 - exp(-12.0 * delta))
	_spin += delta * (18.0 if state == S.SPIN else 0.0)
	_body.rotation.y = _spin
	_body.rotation.z = sin(state_ticks * 0.25) * 0.25 if state == S.DIZZY else 0.0
