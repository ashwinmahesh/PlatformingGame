class_name QueenBloomzilla
extends BossBase
## World 7's boss (Build 7): a towering alien flower. She curls her petals and spits homing spore
## orbs, or rears her vine-roots and slams out a ring. After each slam she wilts forward and her
## glowing core droops within reach: hit it (Plunge, sword or magic). Phase 2 spits more.

enum S { INTRO, CHOOSE, SPIT_WINDUP, SPIT, SLAM_WINDUP, SLAM, WILT, RECOVER }

const CORE_AT := Vector3(0.0, 8.4, 0.0)

var _body: Node3D
var _petals: Array[Node3D] = []
var _core: MeshInstance3D


func _init() -> void:
	boss_name = "Queen Bloomzilla"
	max_hp = 4
	body_rx = 3.0
	body_ry = 4.4
	body_cy = 4.4


func state_name() -> String:
	return S.keys()[state]


func visual_root() -> Node3D:
	return _body


func build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.9
	stem.bottom_radius = 1.5
	stem.height = 7.6
	Kit.mesh_instance(_body, stem, flashy(&"leaf_teal"), Vector3(0.0, 3.8, 0.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var leaf := SphereMesh.new()
		leaf.radius = 2.0
		leaf.height = 0.5
		var mi := Kit.mesh_instance(_body, leaf, flashy(&"lime_pop"), Vector3(cos(a) * 2.6, 0.4, sin(a) * 2.6))
		mi.scale = Vector3(1.4, 1.0, 0.8)
		mi.rotation.y = -a
	for i in 6:
		var holder := Node3D.new()
		holder.position = CORE_AT
		holder.rotation.y = float(i) / 6.0 * TAU
		_body.add_child(holder)
		var petal := SphereMesh.new()
		petal.radius = 2.3
		petal.height = 0.5
		var pm := Kit.mesh_instance(holder, petal, flashy(&"candy_pink" if i % 2 == 0 else &"crystal_violet"), Vector3(2.5, 0.0, 0.0))
		pm.scale = Vector3(1.2, 1.0, 0.7)
		_petals.append(holder)
	var core := SphereMesh.new()
	core.radius = 1.3
	core.height = 2.6
	_core = Kit.mesh_instance(_body, core, Kit.unique_mat(&"gold", 0.04), CORE_AT)
	# Two big sleepy eyes on the heart, looking the way she faces (-Z).
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.32
		eye.height = 0.64
		Kit.mesh_instance(_body, eye, Kit.mat(&"ink_navy"), CORE_AT + Vector3(0.5 * side, 0.25, -1.12))
		var shine := SphereMesh.new()
		shine.radius = 0.1
		shine.height = 0.2
		Kit.mesh_instance(_body, shine, Kit.mat(&"cloth_cream"), CORE_AT + Vector3(0.5 * side + 0.1, 0.38, -1.4))
	var b := CylinderShape3D.new()
	b.radius = 2.4
	b.height = 8.2
	_body_area = area(Layers.ENEMY_HURTBOX, b, Vector3(0.0, 4.1, 0.0))
	var w := SphereShape3D.new()
	w.radius = 2.2
	_weak_area = area(Layers.ENEMY_HURTBOX, w, CORE_AT)


func max_ticks_for(s: int) -> int:
	match s:
		S.INTRO:
			return 110
		S.CHOOSE:
			return 40
		S.SPIT_WINDUP, S.SLAM_WINDUP:
			return 70
		S.SPIT, S.SLAM:
			return 60
		S.WILT:
			return 260
		S.RECOVER:
			return 90
	return 600


func on_watchdog() -> void:
	close_weak_spot()
	set_state(S.RECOVER)


func harmful() -> bool:
	return super.harmful() and state not in [S.WILT, S.RECOVER]


func on_wake() -> void:
	set_state(S.INTRO)


func on_weak_hit() -> void:
	set_state(S.RECOVER)


## Where the core is right now (tests and hints).
func core_position() -> Vector3:
	return _body.global_transform * CORE_AT


func tick_state() -> void:
	var phase2 := hp <= 2
	match state:
		S.INTRO:
			_body.rotation.y += 0.02
			if state_ticks >= 100:
				set_state(S.CHOOSE)
		S.CHOOSE:
			face_player(0.05)
			if state_ticks >= 24:
				set_state(S.SPIT_WINDUP if rng.randf() < (0.6 if phase2 else 0.4) else S.SLAM_WINDUP)
		S.SPIT_WINDUP:
			face_player(0.05)
			for pt in _petals:
				pt.rotation.z = lerpf(pt.rotation.z, 1.1, 0.1)
			flash(Color(0.7, 1.0, 0.3), 0.2 + 0.3 * absf(sin(state_ticks * 0.4)))
			if state_ticks >= 50:
				flash(Color.WHITE, 0.0)
				var n := 5 if phase2 else 3
				for k in n:
					var shot := EnemyShot.new()
					shot.kind = EnemyShot.Kind.HEX
					shot.color_name = &"lime_pop"
					get_parent().add_child(shot)
					var dir := (-global_basis.z).rotated(Vector3.UP, deg_to_rad(-40.0 + 80.0 * k / maxf(n - 1, 1)))
					shot.home_in(global_position + CORE_AT, dir + Vector3.UP * 0.4)
				AudioDirector.play(&"poof", 0.0, 0.7)
				set_state(S.SPIT)
		S.SPIT:
			for pt in _petals:
				pt.rotation.z = lerpf(pt.rotation.z, 0.0, 0.1)
			if state_ticks >= 50:
				set_state(S.CHOOSE if rng.randf() < 0.5 else S.SLAM_WINDUP)
		S.SLAM_WINDUP:
			_body.position.y = lerpf(0.0, 1.5, clampf(state_ticks / 54.0, 0.0, 1.0))
			flash(Color(1.0, 0.55, 0.1), 0.2 + 0.3 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 54:
				flash(Color.WHITE, 0.0)
				set_state(S.SLAM)
		S.SLAM:
			_body.position.y = lerpf(1.5, 0.0, clampf(state_ticks / 6.0, 0.0, 1.0))
			if state_ticks == 6:
				AudioDirector.play(&"boss_slam")
				shake(0.6)
				ring(global_position + Vector3.UP * 0.05, arena_radius)
			if state_ticks >= 20:
				open_weak_spot()
				set_state(S.WILT)
		S.WILT:
			# Wilts forward, core drooping within reach of a jump or a Plunge.
			_body.rotation.x = lerpf(_body.rotation.x, -1.15, 0.08)
			for pt in _petals:
				pt.rotation.z = lerpf(pt.rotation.z, -0.6, 0.1)
			if not weak_open or state_ticks >= 240:
				close_weak_spot()
				set_state(S.RECOVER)
		S.RECOVER:
			_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.12)
			_body.position.y = lerpf(_body.position.y, 0.0, 0.12)
			if state_ticks >= 60:
				set_state(S.CHOOSE)
	var glow := 1.0 if weak_open else 0.2
	(_core.material_override as ShaderMaterial).set_shader_parameter(&"flash", glow * (0.6 + 0.4 * sin(state_ticks * 0.3)))
	(_core.material_override as ShaderMaterial).set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	# The heart's hit zone rides the body (its shape sits at CORE_AT inside the area).
	var turn := _body.transform.basis.orthonormalized()
	_weak_area.transform = Transform3D(turn, _body.transform * CORE_AT - turn * CORE_AT)
