class_name ChompoRex
extends BossBase
## Dinodew Jungle's boss (World 9): Chomposaurus Rex, a grumpy giant red tyrant lizard with a
## crown of ember crystals along the base of his tail. Every attack ends with him puffed out and
## the crest glowing open: PLUNGE it (or slash it). 4 hits win.
##   Stomp Leap   tell: crouches, glows orange, a shadow marks where he'll land;
##                then a leap onto the shadow, a quake ring and falling rocks. He lands winded.
##   Chomp Charge tell: scrapes a foot, head down, a magenta line on the ground;
##                then a run along the line and a snap at the end. He skids, dizzy.
##   Tail Spin    (2 hp or less) tell: tail glows and he crouches low;
##                then one full turn with his tail sweeping wide: jump it. He's dizzy after.
##   Roar         (2 hp or less) tell: rears back; rocks rain where you stand. No opening.
## Hitboxes are capsules on his own bones (head, neck, torso, tail, legs), so what hurts is
## exactly what you see. The model faces -Z of the boss node, like every boss.

enum S { INTRO, CHOOSE, STOMP_WINDUP, LEAP, WINDED, CHARGE_WINDUP, CHARGE, CHOMP, DIZZY, SPIN_WINDUP, SPIN, ROAR, RECOVER }

const SCALE := 0.55
## The ember crest, on his back at the base of the tail (in the _body frame).
const WEAK_AT := Vector3(0.0, 5.7, 2.4)
const LEAP_HEIGHT := 7.0
const CHARGE_SPEED := 15.0
const OPEN_TICKS := 210

var dino: Dino
var _body: Node3D
var _crest: Node3D
var _crest_mats: Array[ShaderMaterial] = []
var _marker: MeshInstance3D
var _aim: MeshInstance3D
var _stars: Node3D
var _hop_from: Vector3
var _hop_to: Vector3
var _dir: Vector3 = Vector3.FORWARD
var _last_pattern: int = -1
var _spin_from: float = 0.0
## Capsules [a, b, radius] in world space, rebuilt every tick from the bones.
var _caps: Array[Array] = []


func _init() -> void:
	boss_name = "Chomposaurus Rex"
	max_hp = 4
	body_rx = 2.4
	body_ry = 3.0
	body_cy = 4.0


func state_name() -> String:
	return S.keys()[state]


func visual_root() -> Node3D:
	return _body


func build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	dino = Dino.new()
	dino.species = &"rex"
	dino.model_scale = SCALE
	dino.outline = 0.04
	dino.colours = {"Green": &"roof_red", "LightGreen": &"sunset_orange", "LightYellow": &"thatch", "Red": &"gloop_pink", "Black": &"ink_navy"}
	dino.clip = &"Idle"
	dino.rotation.y = PI
	_body.add_child(dino)
	for n in dino.model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m != null:
				m = m.duplicate() as ShaderMaterial
				mi.set_surface_override_material(i, m)
				_flash_mats.append(m)
	# The ember crest: a fan of crystals at the base of his tail.
	_crest = Node3D.new()
	_crest.position = WEAK_AT + Vector3(0.0, -0.5, 0.0)
	_body.add_child(_crest)
	for i in 5:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.55, 1.5 - absf(i - 2) * 0.25, 0.55)
		var m := Kit.unique_mat(&"sunset_orange", 0.04)
		_crest_mats.append(m)
		var c := Kit.mesh_instance(_crest, prism, m, Vector3((i - 2) * 0.45, 0.6, absf(i - 2) * -0.1))
		c.rotation.z = (i - 2) * -0.22
	var b := CapsuleShape3D.new()
	b.radius = 2.0
	b.height = 7.0
	_body_area = area(Layers.ENEMY_HURTBOX, b, Vector3.ZERO)
	var w := SphereShape3D.new()
	w.radius = 1.9
	_weak_area = area(Layers.ENEMY_HURTBOX, w, WEAK_AT)
	_stars = Node3D.new()
	_stars.visible = false
	add_child(_stars)
	for i in 4:
		var star := Kit.mesh_instance(_stars, GoalStar.star_mesh(0.35, 0.15, 0.1), Kit.mat(&"gold"), Vector3(cos(i * PI * 0.5) * 1.2, 0.0, sin(i * PI * 0.5) * 1.2))
		star.rotation.y = i
	_marker = _flat_mark(CylinderMesh.new(), Color(Palette.INK, 0.45))
	(_marker.mesh as CylinderMesh).top_radius = 3.4
	(_marker.mesh as CylinderMesh).bottom_radius = 3.4
	(_marker.mesh as CylinderMesh).height = 0.05
	_aim = _flat_mark(BoxMesh.new(), Color(Palette.color(&"portal_magenta"), 0.6))
	(_aim.mesh as BoxMesh).size = Vector3(1.2, 0.05, 1.0)


func _flat_mark(mesh: Mesh, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Fx.fx_mat(c)
	mi.top_level = true
	mi.visible = false
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mi


func max_ticks_for(s: int) -> int:
	match s:
		S.INTRO:
			return 140
		S.CHOOSE:
			return 40
		S.STOMP_WINDUP, S.CHARGE_WINDUP, S.SPIN_WINDUP:
			return 80
		S.LEAP:
			return 90
		S.CHARGE:
			return 160
		S.CHOMP:
			return 80
		S.SPIN:
			return 80
		S.WINDED, S.DIZZY:
			return OPEN_TICKS + 30
		S.ROAR:
			return 130
		S.RECOVER:
			return 100
	return 600


func on_watchdog() -> void:
	close_weak_spot()
	_stars.visible = false
	set_state(S.RECOVER)


func harmful() -> bool:
	return super.harmful() and state in [S.STOMP_WINDUP, S.CHARGE_WINDUP, S.CHARGE, S.CHOMP, S.SPIN_WINDUP, S.SPIN, S.ROAR, S.CHOOSE] or (super.harmful() and state == S.LEAP and state_ticks >= 50)


func contact_halves() -> int:
	return 2 if state in [S.CHARGE, S.SPIN, S.LEAP] else 1


func on_wake() -> void:
	set_state(S.INTRO)


func on_weak_hit() -> void:
	_stars.visible = false
	set_state(S.RECOVER)


## Where the crest is right now (tests and hints).
func crest_position() -> Vector3:
	return global_transform * (_body.transform * WEAK_AT)


## Hitboxes: capsules along his bones, so what hurts is what you see.
func damage_to_player(p: Player) -> Dictionary:
	if not harmful():
		return {}
	var chest := p.global_position + Vector3.UP * 0.6
	for c in _caps:
		var a := c[0] as Vector3
		var b := c[1] as Vector3
		var r := float(c[2]) + 0.35
		var ab := b - a
		var t := clampf((chest - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if chest.distance_to(a + ab * t) < r:
			return {"halves": contact_halves(), "from": global_position, "heavy": contact_halves() > 1, "cause": boss_name}
	return {}


func _update_hitboxes() -> void:
	_caps.clear()
	var pt := func(bone: String) -> Vector3: return dino.bone_point(bone)
	var head: Vector3 = pt.call("Head")
	var head_fwd := (dino.global_transform.basis * (dino.bone_local("Head").basis.y)).normalized()
	var s := SCALE / 0.55
	_caps.append([pt.call("Hips"), pt.call("Shoulders"), 2.1 * s])
	_caps.append([pt.call("Shoulders"), head, 1.3 * s])
	_caps.append([head, head + head_fwd * 2.4 * s, 1.15 * s])
	_caps.append([pt.call("Tail1"), pt.call("Tail3"), 1.1 * s])
	_caps.append([pt.call("Tail3"), pt.call("Tail5"), 0.7 * s])
	for side: String in ["R", "L"]:
		_caps.append([pt.call("BackUpLeg." + side), pt.call("BackFoot." + side), 0.8 * s])
	# The sword's hurt area hugs the torso.
	var hips: Vector3 = pt.call("Hips")
	var sh: Vector3 = pt.call("Shoulders")
	var cs := _body_area.get_child(0) as CollisionShape3D
	var mid := (hips + sh) * 0.5
	var up := (sh - hips).normalized()
	cs.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, up)), mid)


func _ember_rain(center: Vector3, count: int, spread: float) -> void:
	for i in count:
		var h := FallingHazard.new()
		h.look = &"rock"
		h.warn = 1.1 + i * 0.12
		h.radius = 1.6
		get_parent().add_child(h)
		var off := Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-spread, spread)) if i > 0 else Vector3.ZERO
		h.global_position = clamp_to_arena(center + off, 1.5)


func _quake_ring(at: Vector3) -> void:
	var r := Shockwave.new()
	r.ground_y = ground_y
	r.color_name = &"sunset_orange"
	r.max_radius = arena_radius + 2.0
	get_parent().add_child(r)
	r.global_position = Vector3(at.x, ground_y, at.z)


func tick_state() -> void:
	var p := player_ref()
	_marker.visible = state in [S.STOMP_WINDUP, S.LEAP]
	_aim.visible = state == S.CHARGE_WINDUP
	match state:
		S.INTRO:
			if state_ticks == 1:
				dino.play(&"Attack", 0.2)
			if state_ticks == 30:
				shake(0.4)
			if state_ticks == 70:
				dino.play(&"Idle", 0.3)
			if state_ticks >= 120:
				set_state(S.CHOOSE)
		S.CHOOSE:
			face_player(0.1)
			_settle()
			if state_ticks >= 24:
				var options: Array[int] = [S.STOMP_WINDUP, S.CHARGE_WINDUP]
				if hp <= 2:
					options.append(S.SPIN_WINDUP)
					if _last_pattern != S.ROAR:
						options.append(S.ROAR)
				var choices := options.filter(func(o: int) -> bool: return o != _last_pattern)
				var pick: int = choices[rng.randi() % choices.size()]
				_last_pattern = pick
				set_state(pick)
		S.STOMP_WINDUP:
			face_player(0.12)
			if state_ticks == 1:
				dino.play(&"Idle", 0.2, 0.5)
				AudioDirector.play(&"boss_roar", -4.0, 0.8)
			_body.scale = Vector3.ONE.lerp(Vector3(1.08, 0.88, 1.08), clampf(state_ticks / 50.0, 0.0, 1.0))
			flash(Color(1.0, 0.55, 0.1), 0.15 + 0.25 * absf(sin(state_ticks * 0.5)))
			if p != null:
				_hop_to = clamp_to_arena(p.global_position, 4.0)
			_marker.global_position = _hop_to + Vector3.UP * 0.06
			if state_ticks >= 54:
				flash(Color.WHITE, 0.0)
				_hop_from = global_position
				_body.scale = Vector3(0.94, 1.1, 0.94)
				dino.play(&"Jump", 0.1, 1.0)
				AudioDirector.play(&"slime_hop", 0.0, 0.35)
				set_state(S.LEAP)
		S.LEAP:
			var t := clampf(state_ticks / 62.0, 0.0, 1.0)
			var flat := _hop_from.lerp(_hop_to, t)
			global_position = Vector3(flat.x, ground_y + LEAP_HEIGHT * 4.0 * t * (1.0 - t), flat.z)
			_body.scale = _body.scale.lerp(Vector3.ONE, 0.1)
			if t >= 1.0:
				global_position = _hop_to
				_body.scale = Vector3(1.12, 0.85, 1.12)
				AudioDirector.play(&"boss_slam")
				shake(0.8)
				_quake_ring(global_position)
				Fx.burst(get_parent(), global_position + Vector3.UP * 0.4, Palette.color(&"sunset_orange"), 24, 7.0, 0.2, -10.0, 0.7)
				_ember_rain(p.global_position if p != null else arena_center, 4, 7.0)
				_open(S.WINDED)
		S.WINDED, S.DIZZY:
			_body.scale = _body.scale.lerp(Vector3.ONE, 0.1)
			_body.rotation.x = lerpf(_body.rotation.x, -0.12, 0.08)
			_body.position.y = lerpf(_body.position.y, -0.25, 0.08)
			if state == S.DIZZY:
				_stars.visible = true
				_stars.global_position = dino.bone_point("Head") + Vector3.UP * 1.6
				_stars.rotation.y += 0.12
				_body.rotation.z = sin(state_ticks * 0.15) * 0.06
			if not weak_open or state_ticks >= OPEN_TICKS:
				_stars.visible = false
				close_weak_spot()
				set_state(S.RECOVER)
		S.CHARGE_WINDUP:
			face_player(0.15)
			if state_ticks == 1:
				dino.play(&"Idle", 0.2, 1.6)
			_body.rotation.x = lerpf(_body.rotation.x, -0.1, 0.1)
			if p != null:
				var to := p.global_position - global_position
				to.y = 0.0
				if to.length() > 0.5:
					_dir = to.normalized()
			_aim.global_position = global_position + _dir * 10.0 + Vector3.UP * 0.06
			_aim.basis = Basis.looking_at(_dir, Vector3.UP).scaled(Vector3(1.0, 1.0, 20.0))
			if state_ticks % 16 == 0:
				Fx.burst(get_parent(), global_position + Vector3.UP * 0.2, Palette.color(&"sand_light"), 6, 2.5, 0.15, -6.0, 0.4)
			if state_ticks >= 52:
				dino.play(&"Run", 0.15, 1.2)
				AudioDirector.play(&"boss_roll", 0.0, 0.7)
				set_state(S.CHARGE)
		S.CHARGE:
			rotation.y = lerp_angle(rotation.y, atan2(-_dir.x, -_dir.z), 0.3)
			global_position += _dir * CHARGE_SPEED / 60.0
			if state_ticks % 10 == 0:
				shake(0.15)
				Fx.burst(get_parent(), global_position + Vector3.UP * 0.3, Palette.color(&"sand_light"), 4, 2.0, 0.15, -3.0, 0.4)
			var from_c := Vector2(global_position.x - arena_center.x, global_position.z - arena_center.z).length()
			if from_c > arena_radius - 6.0 or state_ticks >= 120:
				global_position = clamp_to_arena(global_position, 6.0)
				dino.play(&"Attack", 0.1, 1.2)
				AudioDirector.play(&"boss_bonk", 0.0, 0.8)
				shake(0.5)
				set_state(S.CHOMP)
		S.CHOMP:
			if state_ticks >= 48:
				dino.play(&"Idle", 0.3, 0.6)
				_open(S.DIZZY)
		S.SPIN_WINDUP:
			face_player(0.08)
			if state_ticks == 1:
				dino.play(&"Idle", 0.2, 0.5)
				AudioDirector.play(&"spin", -2.0, 0.6)
			_body.position.y = lerpf(_body.position.y, -0.35, 0.1)
			flash(Color(1.0, 0.85, 0.3), 0.15 + 0.2 * absf(sin(state_ticks * 0.6)))
			if state_ticks >= 50:
				flash(Color.WHITE, 0.0)
				_spin_from = rotation.y
				set_state(S.SPIN)
		S.SPIN:
			var k := clampf(state_ticks / 54.0, 0.0, 1.0)
			rotation.y = _spin_from + TAU * (k * k * (3.0 - 2.0 * k))
			if state_ticks % 9 == 0:
				Fx.burst(get_parent(), dino.bone_point("Tail5"), Palette.color(&"sunset_orange"), 4, 2.0, 0.15, -4.0, 0.4)
			if k >= 1.0:
				_open(S.DIZZY)
		S.ROAR:
			face_player(0.1)
			if state_ticks == 1:
				dino.play(&"Attack", 0.2, 0.7)
			if state_ticks == 12:
				AudioDirector.play(&"boss_roar", 0.0, 0.9)
				shake(0.5)
			if state_ticks in [24, 54, 84] and p != null:
				_ember_rain(p.global_position, 3, 4.0)
			if state_ticks >= 104:
				dino.play(&"Idle", 0.3)
				set_state(S.CHOOSE)
		S.RECOVER:
			_settle()
			if state_ticks == 1:
				dino.play(&"Idle", 0.3, 1.0)
			if state_ticks >= 70:
				set_state(S.CHOOSE)
	var glow := 1.0 if weak_open else 0.0
	for m in _crest_mats:
		m.set_shader_parameter(&"flash", glow * (0.6 + 0.4 * sin(state_ticks * 0.3)))
		m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	_weak_area.position = _body.transform * WEAK_AT


func _open(s: int) -> void:
	AudioDirector.play(&"boss_bonk", -4.0, 0.7)
	open_weak_spot()
	set_state(s)


func _settle() -> void:
	_body.rotation = _body.rotation.lerp(Vector3.ZERO, 0.12)
	_body.position = _body.position.lerp(Vector3.ZERO, 0.12)
	_body.scale = _body.scale.lerp(Vector3.ONE, 0.12)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dino != null and not gone:
		_update_hitboxes()
