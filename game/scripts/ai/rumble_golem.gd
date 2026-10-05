class_name RumbleGolem
extends BossBase
## Sunscorch Canyon's boss (Build 4): a big friendly-looking stone golem with a glowing gem on its
## back. Ground Slam sends out a ring and leaves its fists stuck: it kneels and the gem opens.
## In phase 2 it also lobs boulders; slash one back to knock it down. 4 clean Plunges win.

enum S { INTRO, CHOOSE, WALK, SLAM_WINDUP, SLAM, STUCK, THROW_WINDUP, THROW, RECOVER, KNOCKED }

const WALK_SPEED := 3.2

var _arms: Array[Node3D] = []
var _gem: MeshInstance3D
var _body: Node3D
var _throws_left: int = 0


func _init() -> void:
	boss_name = "Rumble Golem"
	max_hp = 4
	body_rx = 2.4
	body_ry = 2.6
	body_cy = 2.7


func state_name() -> String:
	return S.keys()[state]


func visual_root() -> Node3D:
	return _body


func build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	Kit.mesh_instance(_body, RoundMesh.box(Vector3(4.4, 3.6, 3.2), 0.9), flashy(&"stone_light"), Vector3(0.0, 2.9, 0.0))
	Kit.mesh_instance(_body, RoundMesh.box(Vector3(3.6, 1.2, 2.6), 0.5), flashy(&"stone_dark"), Vector3(0.0, 0.9, 0.0))
	Kit.mesh_instance(_body, RoundMesh.box(Vector3(2.2, 1.8, 2.0), 0.7), flashy(&"stone_light"), Vector3(0.0, 5.3, -0.3))
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.22
		eye.height = 0.44
		Kit.mesh_instance(_body, eye, Fx.fx_mat(Palette.color(&"portal_teal")), Vector3(0.45 * side, 5.45, -1.3))
		var arm := Node3D.new()
		arm.position = Vector3(2.7 * side, 3.8, 0.0)
		_body.add_child(arm)
		Kit.mesh_instance(arm, RoundMesh.box(Vector3(1.2, 2.6, 1.2), 0.5), flashy(&"stone_light"), Vector3(0.0, -1.2, 0.0))
		Kit.mesh_instance(arm, RoundMesh.box(Vector3(1.7, 1.5, 1.7), 0.6), flashy(&"stone_dark"), Vector3(0.0, -2.9, 0.0))
		_arms.append(arm)
		Kit.mesh_instance(_body, RoundMesh.box(Vector3(1.3, 1.6, 1.4), 0.5), flashy(&"stone_dark"), Vector3(1.0 * side, 0.4, 0.0))
	for i in 5:
		var tuft := SphereMesh.new()
		tuft.radius = 0.4
		tuft.height = 0.4
		Kit.mesh_instance(_body, tuft, Kit.mat(&"moss", 0.02), Vector3(-1.4 + i * 0.7, 4.7, 0.4 * sin(i)))
	var gem := PrismMesh.new()
	gem.size = Vector3(1.2, 1.4, 1.0)
	_gem = Kit.mesh_instance(_body, gem, Kit.unique_mat(&"gold", 0.04), Vector3(0.0, 4.8, 1.4))
	_gem.rotation.x = 0.6
	var b := CylinderShape3D.new()
	b.radius = 2.3
	b.height = 5.0
	_body_area = area(Layers.ENEMY_HURTBOX, b, Vector3(0.0, 2.6, 0.0))
	var w := SphereShape3D.new()
	w.radius = 1.6
	_weak_area = area(Layers.ENEMY_HURTBOX | Layers.BOUNCE, w, Vector3(0.0, 5.2, 1.0))


func max_ticks_for(s: int) -> int:
	match s:
		S.INTRO:
			return 110
		S.CHOOSE:
			return 40
		S.WALK:
			return 220
		S.SLAM_WINDUP, S.THROW_WINDUP:
			return 70
		S.SLAM, S.THROW:
			return 40
		S.STUCK, S.KNOCKED:
			return 300
		S.RECOVER:
			return 90
	return 600


func on_watchdog() -> void:
	close_weak_spot()
	set_state(S.RECOVER)


func harmful() -> bool:
	return super.harmful() and state in [S.WALK, S.SLAM_WINDUP, S.SLAM, S.THROW_WINDUP, S.THROW]


func contact_halves() -> int:
	return 2 if state == S.SLAM else 1


func on_wake() -> void:
	set_state(S.INTRO)


func on_weak_hit() -> void:
	set_state(S.RECOVER)


## A reflected boulder knocks it onto its knees: the gem opens.
func hit_by_boulder() -> void:
	if gone or _defeat_ticks >= 0:
		return
	AudioDirector.play(&"boss_bonk")
	shake(0.6)
	open_weak_spot()
	set_state(S.KNOCKED)


func tick_state() -> void:
	var p := player_ref()
	var phase2 := hp <= 2
	match state:
		S.INTRO:
			_body.position.y = sin(state_ticks * 0.3) * 0.15
			if state_ticks >= 100:
				set_state(S.CHOOSE)
		S.CHOOSE:
			if state_ticks >= 24:
				if phase2 and rng.randf() < 0.45:
					_throws_left = 2
					set_state(S.THROW_WINDUP)
				else:
					set_state(S.WALK)
		S.WALK:
			face_player(0.06)
			var fwd := -global_basis.z
			fwd.y = 0.0
			global_position = clamp_to_arena(global_position + fwd.normalized() * WALK_SPEED / 60.0, 3.5)
			_body.position.y = absf(sin(state_ticks * 0.15)) * 0.25
			if state_ticks % 40 == 20:
				AudioDirector.play(&"boss_slam", -10.0, 1.4)
				shake(0.15)
			if p != null and (Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < 7.0 or state_ticks >= 180):
				set_state(S.SLAM_WINDUP)
		S.SLAM_WINDUP:
			face_player(0.05)
			var k := clampf(state_ticks / 54.0, 0.0, 1.0)
			for arm in _arms:
				arm.rotation.x = lerpf(0.0, -2.6, k)
			flash(Color(1.0, 0.55, 0.1), 0.2 + 0.3 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 54:
				flash(Color.WHITE, 0.0)
				set_state(S.SLAM)
		S.SLAM:
			for arm in _arms:
				arm.rotation.x = lerpf(-2.6, 0.9, clampf(state_ticks / 6.0, 0.0, 1.0))
			if state_ticks == 6:
				AudioDirector.play(&"boss_slam")
				shake(0.7)
				ring(global_position + (-global_basis.z) * 3.0)
				if phase2:
					ring(global_position)
				Fx.burst(get_parent(), global_position + (-global_basis.z) * 3.0, Palette.color(&"thatch"), 20, 6.0, 0.2, -10.0, 0.6)
			if state_ticks >= 14:
				# Fists stuck in the ground: it kneels and the gem on its back opens.
				open_weak_spot()
				set_state(S.STUCK)
		S.STUCK, S.KNOCKED:
			_body.rotation.x = lerpf(_body.rotation.x, 0.45, 0.1)
			_body.position.y = lerpf(_body.position.y, -0.6, 0.1)
			var open_ticks := 230 if state == S.KNOCKED else 200
			if not weak_open or state_ticks >= open_ticks:
				close_weak_spot()
				set_state(S.RECOVER)
		S.THROW_WINDUP:
			face_player(0.1)
			_arms[1].rotation.x = lerpf(_arms[1].rotation.x, -2.8, 0.15)
			if state_ticks >= 40:
				var nut := Boulder.new()
				nut.thrower = self
				get_parent().add_child(nut)
				var target := clamp_to_arena(p.global_position, 1.0) if p != null else arena_center
				nut.launch(global_position + Vector3.UP * 6.0, target, 1.15, 5.0)
				AudioDirector.play(&"spin", -2.0, 0.6)
				set_state(S.THROW)
		S.THROW:
			_arms[1].rotation.x = lerpf(-2.8, 0.6, clampf(state_ticks / 8.0, 0.0, 1.0))
			if state_ticks >= 30:
				_throws_left -= 1
				set_state(S.THROW_WINDUP if _throws_left > 0 else S.RECOVER)
		S.RECOVER:
			_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.12)
			_body.position.y = lerpf(_body.position.y, 0.0, 0.12)
			for arm in _arms:
				arm.rotation.x = lerpf(arm.rotation.x, 0.0, 0.12)
			if state_ticks >= 60:
				set_state(S.CHOOSE)
	var glow := 1.0 if weak_open else 0.0
	(_gem.material_override as ShaderMaterial).set_shader_parameter(&"flash", glow * (0.6 + 0.4 * sin(state_ticks * 0.3)))
	(_gem.material_override as ShaderMaterial).set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	_weak_area.position = Vector3(0.0, 5.2 + _body.position.y, 1.0)
