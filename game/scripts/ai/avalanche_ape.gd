class_name AvalancheApe
extends BossBase
## Frostfang Peak's boss (Build 4): a big fluffy snow ape. It leaps at you (a shadow marks the
## landing, then a ring and icicle rain), and belly-slides across the ice. Slide it into one of
## the frozen pillars and it's dizzy: Plunge onto its head. 5 clean Plunges win.

enum S { INTRO, CHOOSE, LEAP_WINDUP, LEAP, LANDED, SLIDE_WINDUP, SLIDE, DIZZY, RECOVER, ROAR }

const LEAP_HEIGHT := 8.0
const SLIDE_SPEED := 16.0

var pillars: Array[Vector3] = []
var pillar_radius: float = 1.6
var _body: Node3D
var _arms: Array[Node3D] = []
var _stars: Node3D
var _hop_from: Vector3
var _hop_to: Vector3
var _slide_dir: Vector3 = Vector3.FORWARD
var _marker: MeshInstance3D
var _aim: MeshInstance3D
var _last_pattern: int = -1


func _init() -> void:
	boss_name = "Avalanche Ape"
	max_hp = 5
	body_rx = 2.2
	body_ry = 2.4
	body_cy = 2.5


func state_name() -> String:
	return S.keys()[state]


func visual_root() -> Node3D:
	return _body


func _fur(parent: Node3D, r: float, pos: Vector3, color: StringName = &"foam") -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return Kit.mesh_instance(parent, s, flashy(color, 0.05), pos)


func build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	_fur(_body, 2.2, Vector3(0.0, 2.4, 0.0))
	_fur(_body, 1.4, Vector3(0.0, 2.2, -1.2), &"cloth_cream")
	var head := _fur(_body, 1.25, Vector3(0.0, 4.6, -0.6))
	head.scale = Vector3(1.0, 0.95, 1.0)
	_fur(_body, 0.8, Vector3(0.0, 4.4, -1.55), &"skin_light")
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.16
		eye.height = 0.32
		Kit.mesh_instance(_body, eye, Kit.mat(&"bark_dark"), Vector3(0.35 * side, 4.75, -1.9))
		var brow := BoxMesh.new()
		brow.size = Vector3(0.5, 0.12, 0.2)
		var b := Kit.mesh_instance(_body, brow, Kit.mat(&"stone_light"), Vector3(0.38 * side, 5.05, -1.85))
		b.rotation.z = -0.3 * side
		var arm := Node3D.new()
		arm.position = Vector3(2.0 * side, 3.4, -0.2)
		_body.add_child(arm)
		var a := CapsuleMesh.new()
		a.radius = 0.6
		a.height = 3.2
		Kit.mesh_instance(arm, a, flashy(&"foam", 0.05), Vector3(0.0, -1.3, 0.0))
		_fur(arm, 0.8, Vector3(0.0, -2.9, 0.0), &"cloth_cream")
		_arms.append(arm)
		_fur(_body, 0.9, Vector3(1.0 * side, 0.5, -0.2), &"cloth_cream")
	for i in 4:
		var crystal := PrismMesh.new()
		crystal.size = Vector3(0.5, 1.2, 0.5)
		var c := Kit.mesh_instance(_body, crystal, Kit.mat(&"water_light", 0.03), Vector3(-0.9 + i * 0.6, 4.2 + absf(i - 1.5) * -0.3, 1.5))
		c.rotation.x = 0.5
	_stars = Node3D.new()
	_stars.position = Vector3(0.0, 6.4, -0.6)
	_stars.visible = false
	_body.add_child(_stars)
	for i in 4:
		var star := Kit.mesh_instance(_stars, GoalStar.star_mesh(0.35, 0.15, 0.1), Kit.mat(&"gold"), Vector3(cos(i * PI * 0.5) * 1.1, 0.0, sin(i * PI * 0.5) * 1.1))
		star.rotation.y = i
	var b := CylinderShape3D.new()
	b.radius = 2.1
	b.height = 4.4
	_body_area = area(Layers.ENEMY_HURTBOX, b, Vector3(0.0, 2.4, 0.0))
	var w := SphereShape3D.new()
	w.radius = 1.9
	_weak_area = area(Layers.ENEMY_HURTBOX, w, Vector3(0.0, 5.2, -0.6))
	_marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 2.2
	disc.bottom_radius = 2.2
	disc.height = 0.05
	_marker.mesh = disc
	_marker.material_override = Fx.fx_mat(Color(Palette.INK, 0.45))
	_marker.top_level = true
	_marker.visible = false
	_marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_marker)
	_aim = MeshInstance3D.new()
	var line := BoxMesh.new()
	line.size = Vector3(0.8, 0.05, 1.0)
	_aim.mesh = line
	_aim.material_override = Fx.fx_mat(Color(Palette.color(&"portal_magenta"), 0.6))
	_aim.top_level = true
	_aim.visible = false
	_aim.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_aim)


## Build 6 asset swap: the Quaternius model replaces the built body (hit areas unchanged).
	_use_model()

func _use_model() -> void:
	for n in _body.find_children("*", "MeshInstance3D", true, false):
		if ((n as MeshInstance3D).mesh is PrismMesh and n.get_parent() == _body) or _stars.is_ancestor_of(n):
			continue
		(n as MeshInstance3D).visible = false
	var path := Models.Q_MONSTERS + "Yeti.gltf"
	var model := Models.spawn(_body, path, Vector3.ZERO, PI, 6.0 / maxf(Models.model_bounds(path).size.y, 0.01), 0.04)
	Models.play(model, [&"Idle", &"Flying_Idle"])
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m != null:
				m = m.duplicate() as ShaderMaterial
				mi.set_surface_override_material(i, m)
				_flash_mats.append(m)


func max_ticks_for(s: int) -> int:
	match s:
		S.INTRO:
			return 110
		S.CHOOSE:
			return 40
		S.LEAP_WINDUP, S.SLIDE_WINDUP:
			return 70
		S.LEAP:
			return 80
		S.LANDED, S.RECOVER:
			return 100
		S.SLIDE:
			return 200
		S.DIZZY:
			return 300
		S.ROAR:
			return 120
	return 600


func on_watchdog() -> void:
	close_weak_spot()
	set_state(S.RECOVER)


func harmful() -> bool:
	return super.harmful() and (state in [S.LEAP_WINDUP, S.LANDED, S.SLIDE_WINDUP, S.SLIDE, S.ROAR] or (state == S.LEAP and state_ticks >= 58))


func contact_halves() -> int:
	return 2 if state in [S.SLIDE, S.LEAP] else 1


func on_wake() -> void:
	set_state(S.INTRO)


func on_weak_hit() -> void:
	_stars.visible = false
	set_state(S.RECOVER)


func _icicle_rain(center: Vector3, count: int, spread: float) -> void:
	for i in count:
		var h := FallingHazard.new()
		h.look = &"icicle"
		h.warn = 1.1 + i * 0.12
		h.radius = 1.6
		get_parent().add_child(h)
		var off := Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-spread, spread)) if i > 0 else Vector3.ZERO
		h.global_position = clamp_to_arena(center + off, 1.5)


func tick_state() -> void:
	var p := player_ref()
	_marker.visible = state in [S.LEAP_WINDUP, S.LEAP]
	_aim.visible = state == S.SLIDE_WINDUP
	match state:
		S.INTRO:
			for arm in _arms:
				arm.rotation.x = -2.6 + sin(state_ticks * 0.4) * 0.3
			if state_ticks >= 100:
				set_state(S.CHOOSE)
		S.CHOOSE:
			for arm in _arms:
				arm.rotation.x = lerpf(arm.rotation.x, 0.0, 0.15)
			if state_ticks >= 24:
				var options: Array[int] = [S.LEAP_WINDUP, S.SLIDE_WINDUP]
				if hp <= 2:
					options.append(S.ROAR)
				var choices := options.filter(func(o: int) -> bool: return o != _last_pattern)
				var pick: int = choices[rng.randi() % choices.size()]
				_last_pattern = pick
				set_state(pick)
		S.LEAP_WINDUP:
			face_player(0.12)
			_body.scale = Vector3.ONE.lerp(Vector3(1.2, 0.75, 1.2), clampf(state_ticks / 48.0, 0.0, 1.0))
			if p != null:
				_hop_to = clamp_to_arena(p.global_position, 2.5)
			_marker.global_position = _hop_to + Vector3.UP * 0.06
			if state_ticks >= 48:
				_hop_from = global_position
				_body.scale = Vector3(0.85, 1.2, 0.85)
				AudioDirector.play(&"slime_hop", 0.0, 0.4)
				set_state(S.LEAP)
		S.LEAP:
			var t := clampf(state_ticks / 60.0, 0.0, 1.0)
			var flat := _hop_from.lerp(_hop_to, t)
			global_position = Vector3(flat.x, ground_y + LEAP_HEIGHT * 4.0 * t * (1.0 - t), flat.z)
			if t >= 1.0:
				global_position = _hop_to
				_body.scale = Vector3(1.35, 0.7, 1.35)
				AudioDirector.play(&"boss_slam")
				shake(0.7)
				ring(global_position)
				_icicle_rain(p.global_position if p != null else arena_center, 4, 7.0)
				set_state(S.LANDED)
		S.LANDED:
			_body.scale = _body.scale.lerp(Vector3.ONE, 0.1)
			if state_ticks >= 60:
				set_state(S.CHOOSE)
		S.SLIDE_WINDUP:
			face_player(0.15)
			_body.rotation.x = lerpf(_body.rotation.x, 1.2, 0.1)
			if p != null:
				var to := p.global_position - global_position
				to.y = 0.0
				if to.length() > 0.5:
					_slide_dir = to.normalized()
			_aim.global_position = global_position + _slide_dir * 9.0 + Vector3.UP * 0.06
			_aim.basis = Basis.looking_at(_slide_dir, Vector3.UP).scaled(Vector3(1.0, 1.0, 18.0))
			if state_ticks >= 50:
				AudioDirector.play(&"boss_roll")
				set_state(S.SLIDE)
		S.SLIDE:
			global_position += _slide_dir * SLIDE_SPEED / 60.0
			if state_ticks % 6 == 0:
				Fx.burst(get_parent(), global_position + Vector3.UP * 0.3, Palette.color(&"foam"), 4, 2.0, 0.15, -3.0, 0.4)
			for pil in pillars:
				if Vector2(global_position.x - pil.x, global_position.z - pil.z).length() < body_rx + pillar_radius:
					# Bonk: dizzy, head exposed.
					AudioDirector.play(&"boss_bonk")
					shake(0.7)
					global_position -= _slide_dir * 1.0
					_stars.visible = true
					open_weak_spot()
					set_state(S.DIZZY)
					return
			var from_c := Vector2(global_position.x - arena_center.x, global_position.z - arena_center.z).length()
			if from_c > arena_radius - body_rx or state_ticks >= 150:
				global_position = clamp_to_arena(global_position, body_rx + 0.5)
				set_state(S.RECOVER)
		S.DIZZY:
			_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.1)
			_stars.rotation.y += 0.12
			_body.rotation.z = sin(state_ticks * 0.15) * 0.15
			if not weak_open or state_ticks >= 240:
				_stars.visible = false
				close_weak_spot()
				set_state(S.RECOVER)
		S.ROAR:
			face_player(0.1)
			for arm in _arms:
				arm.rotation.x = -2.8 + sin(state_ticks * 0.6) * 0.3
			if state_ticks in [20, 50, 80] and p != null:
				_icicle_rain(p.global_position, 3, 4.0)
				shake(0.3)
			if state_ticks == 10:
				AudioDirector.play(&"boss_roar", 0.0, 1.2)
			if state_ticks >= 100:
				set_state(S.CHOOSE)
		S.RECOVER:
			_body.rotation = _body.rotation.lerp(Vector3.ZERO, 0.12)
			_body.scale = _body.scale.lerp(Vector3.ONE, 0.12)
			if state_ticks >= 70:
				set_state(S.CHOOSE)
	_weak_area.position = _body.transform * Vector3(0.0, 5.2, -0.6)
