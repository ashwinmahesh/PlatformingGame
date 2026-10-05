class_name Gloplet
extends CharacterBody3D
## Small slime (plan §8.3). A state machine with tick timers from EnemyDef; procedural animation.
## The blue Bouncer is the same code with is_bouncer: its flattened top is a bounce surface.

signal defeated(enemy: Gloplet)

enum S { IDLE, WANDER, NOTICE, APPROACH, WINDUP, LUNGE, RECOVER, RETURN_HOME, HURT, DEFEATED, DORMANT }

const GRAVITY := 30.0
const BODY_RADIUS := 0.5
## Build 2: Gloplets are 20% bigger. Body, hurtbox and contact all scale together.
const SIZE := 1.2

var def: EnemyDef = preload("res://data/enemies/gloplet.tres")
var director: AttackDirector
var home: Vector3
var active: bool = true
var state: S = S.IDLE
var state_ticks: int = 0
var hp: int = 2
var hitstop_ticks: int = 0
var lunge_target: Vector3
var watchdog_trips: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _player: Player
var _airborne: bool = false
var _air_gravity: float = GRAVITY
var _next_hop_tick: int = 0
var _last_hit_id: int = -1
var _lost_sight_ticks: int = 0
var _visual: Node3D
var _mat: ShaderMaterial
var _squash: Vector3 = Vector3.ONE
var _bang: Label3D
var _debug: Label3D
var _hurtbox: Area3D
var _bounce_area: Area3D
var _puddle: MeshInstance3D
var _facing: Vector3 = Vector3.FORWARD


func setup(enemy_def: EnemyDef, at: Vector3, attack_director: AttackDirector, seed_value: int) -> void:
	def = enemy_def
	home = at
	position = at
	director = attack_director
	rng.seed = seed_value
	hp = def.hp


func _ready() -> void:
	add_to_group(&"enemy")
	add_to_group(&"lockable")
	add_to_group(&"enemy_attacker")
	collision_layer = Layers.ENEMY_BODY
	collision_mask = Layers.WORLD | Layers.ENEMY_BODY
	floor_snap_length = 0.2
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.42 * SIZE
	cs.shape = shape
	cs.position.y = 0.42 * SIZE
	add_child(cs)
	_hurtbox = _area(Layers.ENEMY_HURTBOX, 0.55 * SIZE, 0.45 * SIZE)
	_bounce_area = _area(Layers.BOUNCE, 0.7 * SIZE, 0.4 * SIZE)
	_bounce_area.monitorable = false
	_build_visual()
	hp = def.hp
	if director == null:
		director = AttackDirector.new()
	_next_hop_tick = rng.randi_range(10, def.idle_ticks)


func _area(layer: int, radius: float, y: float) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = layer
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = radius
	var cs := CollisionShape3D.new()
	cs.shape = s
	cs.position.y = y
	a.add_child(cs)
	add_child(a)
	return a


func is_lockable() -> bool:
	return state not in [S.DEFEATED, S.DORMANT] and visible


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


func _player_ref() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func _set_state(s: S) -> void:
	if state in [S.WINDUP, S.LUNGE] and s not in [S.WINDUP, S.LUNGE]:
		director.mark_finished(self)
	state = s
	state_ticks = 0


## Maximum ticks for each state; exceeding one is a bug (plan §8.1 watchdog).
func _max_ticks(s: S) -> int:
	match s:
		S.IDLE:
			return def.idle_ticks * 3 + 60
		S.NOTICE:
			return def.notice_ticks + 5
		S.WINDUP:
			return def.windup_ticks + 120
		S.LUNGE, S.WANDER:
			return 180
		S.RECOVER:
			return def.recover_ticks + 5
		S.HURT:
			return def.hurt_ticks + 5
		S.DORMANT:
			return def.respawn_ticks + 5
	return def.max_state_ticks


func _physics_process(delta: float) -> void:
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	if not active and state not in [S.DEFEATED, S.DORMANT]:
		return
	state_ticks += 1
	if state_ticks > _max_ticks(state) and state not in [S.DEFEATED]:
		watchdog_trips += 1
		push_error("Gloplet watchdog: state %s exceeded %d ticks" % [S.keys()[state], _max_ticks(state)])
		director.release(self)
		_set_state(S.IDLE)
	_brain()
	_move(delta)
	_animate(delta)


func _brain() -> void:
	var p := _player_ref()
	var sees := p != null and _can_see(p)
	match state:
		S.IDLE:
			if sees:
				_notice()
			elif state_ticks >= _next_hop_tick:
				var off := Vector3(rng.randf_range(-2.5, 2.5), 0.0, rng.randf_range(-2.5, 2.5))
				if _try_hop(home + off - global_position, def.hop_air_ticks, def.hop_height):
					_set_state(S.WANDER)
				else:
					state_ticks = 0
		S.WANDER:
			if sees:
				_notice()
			elif not _airborne and state_ticks > 2:
				_next_hop_tick = rng.randi_range(def.idle_ticks / 2, def.idle_ticks)
				_set_state(S.IDLE)
		S.NOTICE:
			_face(p.global_position - global_position)
			if state_ticks >= def.notice_ticks:
				_set_state(S.APPROACH)
				_next_hop_tick = 0
		S.APPROACH:
			_lost_sight_ticks = 0 if sees else _lost_sight_ticks + 1
			var to := p.global_position - global_position
			to.y = 0.0
			if global_position.distance_to(home) > def.leash_radius or _lost_sight_ticks > def.lost_sight_ticks:
				director.release(self)
				_set_state(S.RETURN_HOME)
				return
			_face(to)
			if not _airborne and to.length() <= def.lunge_range and p.state != Player.State.DEAD and director.request(self):
				_set_state(S.WINDUP)
				return
			if not _airborne and state_ticks >= _next_hop_tick:
				_next_hop_tick = state_ticks + def.hop_interval_ticks
				if to.length() > 1.6:
					_try_hop(to.normalized() * minf(def.hop_distance, to.length() - 1.2), def.hop_air_ticks, def.hop_height)
		S.WINDUP:
			_face(p.global_position - global_position)
			if director.boss_lock or not director.holds(self):
				director.release(self)
				_set_state(S.APPROACH)
				return
			if state_ticks >= def.windup_ticks and director.can_start(self):
				# Target locked at the end of the wind-up.
				var to := p.global_position - global_position
				to.y = 0.0
				if to.length() > def.lunge_range + 1.0:
					to = to.normalized() * (def.lunge_range + 1.0)
				director.mark_started(self)
				if _try_hop(to, def.lunge_air_ticks, def.lunge_height):
					lunge_target = global_position + to
					_set_state(S.LUNGE)
					AudioDirector.play(&"slime_hop", -2.0, 0.8)
				else:
					director.release(self)
					_set_state(S.APPROACH)
		S.LUNGE:
			if not _airborne and state_ticks > 2:
				director.release(self)
				_set_state(S.RECOVER)
				_squash = Vector3(1.5, 0.45, 1.5)
				AudioDirector.play(&"slime_land", -4.0)
		S.RECOVER:
			if state_ticks >= def.recover_ticks:
				_set_state(S.APPROACH)
		S.RETURN_HOME:
			var to_home := home - global_position
			to_home.y = 0.0
			if to_home.length() < 0.8:
				_set_state(S.IDLE)
			elif not _airborne and state_ticks % def.hop_interval_ticks == 0:
				_try_hop(to_home.normalized() * minf(def.hop_distance * 1.3, to_home.length()), def.hop_air_ticks, def.hop_height)
		S.HURT:
			if state_ticks >= def.hurt_ticks:
				_set_state(S.APPROACH)
		S.DEFEATED:
			if state_ticks >= 2:
				if def.is_bouncer:
					_set_state(S.DORMANT)
				else:
					queue_free()
		S.DORMANT:
			if state_ticks >= def.respawn_ticks:
				respawn()


func _notice() -> void:
	_set_state(S.NOTICE)
	_bang.visible = true
	_bang.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_bang, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(_bang):
			_bang.visible = false)
	AudioDirector.play(&"notice", -6.0)


func _can_see(p: Player) -> bool:
	if p.state == Player.State.DEAD:
		return false
	var to := p.global_position - global_position
	var d := to.length()
	if d > def.sight_radius:
		return false
	if d > def.hearing_radius:
		var flat := Vector3(to.x, 0.0, to.z).normalized()
		if rad_to_deg(_facing.angle_to(flat)) > def.fov_deg * 0.5:
			return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, p.global_position + Vector3.UP * 0.8, Layers.WORLD)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## HopMover: ballistic hops; every target is checked by a downward ray so the slime never hops
## off a ledge or into water. Returns false if the hop (and its 50% fallback) is unsafe.
func _try_hop(offset: Vector3, air_ticks: int, height: float) -> bool:
	offset.y = 0.0
	for scale: float in [1.0, 0.5]:
		var o := offset * scale
		if is_hop_target_safe(global_position + o):
			var t := air_ticks / 60.0
			_air_gravity = 8.0 * height / (t * t)
			velocity = Vector3(o.x / t, 4.0 * height / t, o.z / t)
			_airborne = true
			_squash = Vector3(0.75, 1.3, 0.75)
			_face(o)
			return true
	return false


func is_hop_target_safe(target: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	for p: Vector3 in [target, (global_position + target) * 0.5]:
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 1.5, Layers.WORLD)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return false
		var hp_pos: Vector3 = hit["position"]
		if absf(hp_pos.y - global_position.y) > 0.9 or (hit["normal"] as Vector3).y < 0.7:
			return false
		var pq := PhysicsPointQueryParameters3D.new()
		pq.position = hp_pos + Vector3.DOWN * 0.15
		pq.collide_with_areas = true
		pq.collide_with_bodies = false
		pq.collision_mask = Layers.HAZARD
		if not space.intersect_point(pq, 1).is_empty():
			return false
	return true


func _move(delta: float) -> void:
	if state in [S.DEFEATED, S.DORMANT]:
		return
	if _airborne:
		velocity.y -= _air_gravity * delta
	elif is_on_floor():
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), 25.0 * delta)
		velocity.y = -1.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if _airborne and is_on_floor() and velocity.y <= 0.0:
		_airborne = false
		velocity = Vector3.ZERO
		_squash = Vector3(1.3, 0.7, 1.3)
	if global_position.y < home.y - 15.0:
		_defeat(false)


func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		_facing = dir.normalized()


# --- Combat -----------------------------------------------------------------------------------

func receive_player_attack(atk: Dictionary, area: Area3D) -> Dictionary:
	if state in [S.DEFEATED, S.DORMANT]:
		return {}
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	var bounce_h := 0.0
	if plunge:
		bounce_h = def.bounce_height if (def.is_bouncer and state == S.RECOVER) else float(atk.get("bounce", 2.2))
	elif area == _bounce_area:
		return {}
	var id := int(atk.get("id", -1))
	if id == _last_hit_id:
		return {"bounce": bounce_h}
	_last_hit_id = id
	hp -= int(atk.get("damage", 1))
	_mat.set_shader_parameter(&"flash", 1.0)
	create_tween().tween_method(func(v: float) -> void: _mat.set_shader_parameter(&"flash", v), 1.0, 0.0, 0.2)
	_squash = Vector3(1.4, 0.6, 1.4)
	director.release(self)
	if hp <= 0:
		_defeat(true)
		return {"hit": true, "killed": true, "bounce": bounce_h}
	var away := global_position - (atk.get("from", global_position) as Vector3)
	away.y = 0.0
	if not plunge and away.length() > 0.01:
		velocity = away.normalized() * 4.0 * float(atk.get("knockback", 1.0)) + Vector3.UP * 3.0
		_airborne = true
		_air_gravity = GRAVITY
	_set_state(S.HURT)
	AudioDirector.play(&"slime_hurt", -3.0)
	return {"hit": true, "killed": false, "bounce": bounce_h}


## A flattened Bouncer's top launches you 4 m and counts as a Plunge refund.
func on_player_land(_p: Player) -> float:
	if def.is_bouncer and state == S.RECOVER:
		_squash = Vector3(1.6, 0.4, 1.6)
		return def.bounce_height
	return 0.0


func damage_to_player(p: Player) -> Dictionary:
	if state in [S.DEFEATED, S.DORMANT, S.RECOVER] or not visible:
		return {}
	# Contact uses the drawn body (an ellipsoid that squashes) grown by the hero's capsule.
	var sq := _visual.basis.get_scale()
	var rx := BODY_RADIUS * sq.x + 0.33
	var ry := 0.425 * sq.y + 0.6
	var d := p.global_position + Vector3.UP * 0.6 - (global_position + Vector3.UP * 0.42 * sq.y)
	if (d.x * d.x + d.z * d.z) / (rx * rx) + (d.y * d.y) / (ry * ry) >= 1.0:
		return {}
	var lunge := state == S.LUNGE
	return {"halves": def.lunge_damage if lunge else def.contact_damage, "from": global_position, "cause": "gloplet_lunge" if lunge else "gloplet_contact"}


func _defeat(drop: bool) -> void:
	director.release(self)
	_set_state(S.DEFEATED)
	_hurtbox.set_deferred(&"monitorable", false)
	_bounce_area.set_deferred(&"monitorable", false)
	visible = def.is_bouncer
	_visual.visible = false
	if def.is_bouncer:
		_puddle.visible = true
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.4, Palette.color(def.color), 18, 5.0, 0.13, -9.0, 0.6)
	AudioDirector.play(&"slime_pop")
	Telemetry.log_event("enemy_defeated", {"id": String(def.id), "pos": global_position})
	if drop and rng.randf() < def.heart_drop_chance:
		Pickup.spawn_heart(get_parent(), global_position + Vector3.UP * 0.5)
	defeated.emit(self)


## Bouncers come back from their goo puddle (and zone resets restore everyone).
func respawn() -> void:
	position = home
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	hp = def.hp
	visible = true
	_visual.visible = true
	_puddle.visible = false
	_hurtbox.monitorable = true
	_airborne = false
	_last_hit_id = -1
	_set_state(S.IDLE)
	_squash = Vector3(0.3, 1.6, 0.3)


# --- Visuals (procedural, no rig) -------------------------------------------------------------

## Build 6 asset swap: the Quaternius blob model (green, or pink tinted to this slime's colour)
## replaces the built body. Its material takes over the flash, so hits still read.
func _use_model() -> void:
	for n in _visual.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).visible = false
	var green := def.color == &"slime_green"
	var path := Models.Q_MONSTERS + ("GreenBlob" if green else "PinkBlob") + ".gltf"
	var h := 1.05 if not def.is_bouncer else 1.25
	var model := Models.spawn(_visual, path, Vector3.ZERO, PI, h / maxf(Models.model_bounds(path).size.y, 0.01), 0.03)
	Models.play(model, [&"Idle"])
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m == null:
				continue
			m = m.duplicate() as ShaderMaterial
			if not green and def.color != &"gloop_pink":
				m.set_shader_parameter(&"albedo_color", Palette.color(def.color).lerp(Color.WHITE, 0.25))
			mi.set_surface_override_material(i, m)
			_mat = m


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_mat = Kit.slime_mat(def.color, 0.03)
	var body := SphereMesh.new()
	body.radius = 0.5
	body.height = 0.85
	body.radial_segments = 16
	body.rings = 8
	Kit.mesh_instance(_visual, body, _mat, Vector3(0.0, 0.42, 0.0))
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.075
		eye.height = 0.15
		Kit.mesh_instance(_visual, eye, Kit.mat(&"bark_dark"), Vector3(0.15 * side, 0.5, -0.43))
		var glint := SphereMesh.new()
		glint.radius = 0.025
		glint.height = 0.05
		Kit.mesh_instance(_visual, glint, Kit.mat(&"foam"), Vector3(0.15 * side + 0.025, 0.53, -0.49))
		var leaf := SphereMesh.new()
		leaf.radius = 0.13
		leaf.height = 0.08
		var lm := Kit.mesh_instance(_visual, leaf, Kit.mat(&"leaf_dark" if def.color != &"slime_green" else &"leaf_teal", 0.012), Vector3(0.09 * side, 0.9, 0.0))
		lm.rotation.z = -0.7 * side
	var stem := CylinderMesh.new()
	stem.top_radius = 0.02
	stem.bottom_radius = 0.035
	stem.height = 0.14
	Kit.mesh_instance(_visual, stem, Kit.mat(&"leaf_dark"), Vector3(0.0, 0.84, 0.0))
	_use_model()
	_bang = Kit.label(self, Vector3(0.0, 1.5, 0.0), "!", 96)
	_bang.modulate = Palette.color(&"gold")
	_bang.visible = false
	_debug = Kit.label(self, Vector3(0.0, 1.9, 0.0), "", 32)
	_debug.visible = false
	var pm := CylinderMesh.new()
	pm.top_radius = 0.55
	pm.bottom_radius = 0.65
	pm.height = 0.08
	_puddle = Kit.mesh_instance(self, pm, Kit.slime_mat(def.color, 0.0), Vector3(0.0, 0.04, 0.0))
	_puddle.visible = false


func _animate(delta: float) -> void:
	_squash = _squash.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	var s := _squash
	match state:
		S.IDLE, S.NOTICE, S.APPROACH, S.RETURN_HOME:
			var breathe := sin(Time.get_ticks_msec() * 0.004 + home.x) * 0.04
			s *= Vector3(1.0 - breathe, 1.0 + breathe, 1.0 - breathe)
		S.WINDUP:
			var k := clampf(float(state_ticks) / def.windup_ticks, 0.0, 1.0)
			s = Vector3(lerpf(1.0, 1.2, k), lerpf(1.0, 0.7, k), lerpf(1.0, 1.2, k))
			# Warning flash: white to orange.
			_mat.set_shader_parameter(&"flash_color", Color.WHITE.lerp(Color(1.0, 0.55, 0.1), k))
			_mat.set_shader_parameter(&"flash", 0.25 + 0.35 * absf(sin(state_ticks * 0.5)))
		S.RECOVER:
			s = Vector3(1.35, 0.5, 1.35) * (1.0 + sin(state_ticks * 0.6) * 0.05)
	if _airborne:
		s = s * Vector3(0.88, 1.2, 0.88)
	if state != S.WINDUP and _mat.get_shader_parameter(&"flash_color") != Color.WHITE:
		_mat.set_shader_parameter(&"flash_color", Color.WHITE)
		_mat.set_shader_parameter(&"flash", 0.0)
	_visual.basis = Basis.looking_at(_facing, Vector3.UP).scaled(s * SIZE)
	_hurtbox.position.y = 0.45 * SIZE * s.y
	_bounce_area.monitorable = def.is_bouncer and state == S.RECOVER
	_debug.visible = DevTools.ai_debug
	if _debug.visible:
		_debug.text = "%s %d hp%d" % [S.keys()[state], state_ticks, hp]
