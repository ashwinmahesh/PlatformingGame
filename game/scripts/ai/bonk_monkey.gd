class_name BonkMonkey
extends Node3D
## Bonk monkey (plan §8.4): throws coconuts from tree perches. A ring marks where each coconut
## will land. Slashing a coconut sends it home to the thrower; a hit (reflected coconut, slash or
## Plunge) knocks the monkey off its perch, stunned on the ground for 2.5 s, where a combo
## finishes it. 3 HP. Built from simple shapes (plan's "rough blockout" for P4).

signal defeated(monkey: BonkMonkey)

enum S { PERCHED, AIM, THROW, COOLDOWN, RELOCATE, STUNNED, CLIMB, DEFEATED }

const MAX_HP := 3
const SIGHT := 24.0
const AIM_TICKS := 42
const THROW_TICKS := 10
const COOLDOWN_TICKS := 72
const RELOCATE_AFTER := 2
const HOP_TICKS := 60
const STUN_TICKS := 150
const CLIMB_TICKS := 60
const COCONUT_FLIGHT := 0.9

var perches: Array[Vector3] = []
var perch_index: int = 0
var director: AttackDirector
var state: S = S.PERCHED
var state_ticks: int = 0
var hp: int = MAX_HP
var hitstop_ticks: int = 0
var watchdog_trips: int = 0
var throws_since_move: int = 0
var aim_point: Vector3 = Vector3.ZERO
var last_coconut: Coconut

var _player: Player
var _hop_from: Vector3
var _hop_to: Vector3
var _hop_height: float = 2.0
var _last_hit_id: int = -1
var _visual: Node3D
var _body_mat: ShaderMaterial
var _arm: Node3D
var _held_nut: MeshInstance3D
var _tail: Node3D
var _hurtbox: Area3D
var _debug: Label3D
var _bob: float = 0.0


func _ready() -> void:
	add_to_group(&"enemy")
	add_to_group(&"lockable")
	if director == null:
		director = AttackDirector.new()
	if not perches.is_empty():
		global_position = perches[perch_index]
	_build()


func is_lockable() -> bool:
	return state != S.DEFEATED


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


func _player_ref() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func _set_state(s: S) -> void:
	if state in [S.AIM, S.THROW] and s not in [S.AIM, S.THROW]:
		director.mark_finished(self)
	state = s
	state_ticks = 0


func _max_ticks(s: S) -> int:
	match s:
		S.AIM:
			return AIM_TICKS + 5
		S.THROW:
			return THROW_TICKS + 5
		S.COOLDOWN:
			return COOLDOWN_TICKS + 5
		S.RELOCATE, S.CLIMB:
			return HOP_TICKS + 10
		S.STUNNED:
			return STUN_TICKS + 5
	return 1 << 30


func _physics_process(_delta: float) -> void:
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	state_ticks += 1
	if state_ticks > _max_ticks(state):
		watchdog_trips += 1
		push_error("BonkMonkey watchdog: state %s exceeded %d ticks" % [S.keys()[state], _max_ticks(state)])
		director.release(self)
		_set_state(S.PERCHED)
	var p := _player_ref()
	match state:
		S.PERCHED:
			if p != null and _can_see(p) and director.request(self, true):
				_set_state(S.AIM)
				AudioDirector.play(&"notice", -8.0, 1.4)
		S.AIM:
			_face(p.global_position if p != null else global_position)
			if p == null or not _can_see(p):
				director.release(self)
				_set_state(S.PERCHED)
			elif state_ticks >= AIM_TICKS and director.can_start(self):
				# Target locked when the aim ends; the ring shows where it will land.
				aim_point = _ground_below(p.global_position + Vector3.UP * 0.5)
				director.mark_started(self)
				_throw()
				_set_state(S.THROW)
		S.THROW:
			if state_ticks >= THROW_TICKS:
				director.release(self)
				throws_since_move += 1
				_set_state(S.COOLDOWN)
		S.COOLDOWN:
			if state_ticks >= COOLDOWN_TICKS:
				if throws_since_move >= RELOCATE_AFTER and perches.size() > 1:
					throws_since_move = 0
					perch_index = (perch_index + 1) % perches.size()
					_begin_hop(perches[perch_index], 3.0, S.RELOCATE)
				else:
					_set_state(S.PERCHED)
		S.RELOCATE, S.CLIMB:
			var t := clampf(float(state_ticks) / HOP_TICKS, 0.0, 1.0)
			var flat := _hop_from.lerp(_hop_to, t)
			flat.y = lerpf(_hop_from.y, _hop_to.y, t) + _hop_height * 4.0 * t * (1.0 - t)
			global_position = flat
			if t >= 1.0:
				_set_state(S.PERCHED)
		S.STUNNED:
			if state_ticks >= STUN_TICKS:
				_begin_hop(perches[perch_index] if not perches.is_empty() else global_position, 4.0, S.CLIMB)
	_animate()


func _begin_hop(to: Vector3, height: float, s: S) -> void:
	_hop_from = global_position
	_hop_to = to
	_hop_height = height
	_set_state(s)


func _can_see(p: Player) -> bool:
	if p.state in [Player.State.DEAD, Player.State.FROZEN]:
		return false
	var to := p.global_position - global_position
	if to.length() > SIGHT:
		return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.0, p.global_position + Vector3.UP * 0.8, Layers.WORLD)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _ground_below(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 60.0, Layers.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else p


func _face(target: Vector3) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() > 0.1:
		_visual.basis = Basis.looking_at(to.normalized(), Vector3.UP)


func _throw() -> void:
	var nut := Coconut.new()
	nut.thrower = self
	get_parent().add_child(nut)
	nut.launch(global_position + Vector3.UP * 1.6, aim_point, COCONUT_FLIGHT)
	last_coconut = nut
	AudioDirector.play(&"slash", -8.0, 0.7)


# --- Combat -----------------------------------------------------------------------------------

func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if state == S.DEFEATED:
		return {}
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	var bounce_h := float(atk.get("bounce", 2.2)) if plunge else 0.0
	var id := int(atk.get("id", -1))
	if id == _last_hit_id:
		return {"bounce": bounce_h}
	_last_hit_id = id
	if state == S.STUNNED:
		_take(int(atk.get("damage", 1)))
	else:
		_knock_off()
	return {"hit": true, "bounce": bounce_h}


## A reflected coconut came home.
func hit_by_coconut() -> void:
	if state == S.DEFEATED:
		return
	if state == S.STUNNED:
		_take(1)
	else:
		_knock_off()


func _knock_off() -> void:
	director.release(self)
	AudioDirector.play(&"coconut_break")
	_flash()
	# Knocked forward, off the perch, toward whoever hit it.
	var fwd := -_visual.basis.z.normalized()
	var ground := _ground_below(global_position + Vector3.UP * 0.2 + fwd * 3.0)
	_hop_from = global_position
	_hop_to = ground
	_hop_height = 1.0
	global_position = ground
	_set_state(S.STUNNED)
	Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"gold"), 10, 4.0, 0.1)


func _take(dmg: int) -> void:
	hp -= dmg
	_flash()
	AudioDirector.play(&"hit", -2.0)
	if hp <= 0:
		_set_state(S.DEFEATED)
		_hurtbox.set_deferred(&"monitorable", false)
		Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"bark_light"), 18, 5.0, 0.15)
		AudioDirector.play(&"poof")
		Telemetry.log_event("enemy_defeated", {"id": "bonk_monkey", "pos": global_position})
		defeated.emit(self)
		if randf() < 0.4:
			Pickup.spawn_heart(get_parent(), global_position + Vector3.UP * 0.5)
		queue_free()


func _flash() -> void:
	_body_mat.set_shader_parameter(&"flash", 1.0)
	create_tween().tween_method(func(v: float) -> void: _body_mat.set_shader_parameter(&"flash", v), 1.0, 0.0, 0.2)


# --- Visuals (procedural rough blockout) ------------------------------------------------------

func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_body_mat = Kit.unique_mat(&"bark_light", 0.04)
	var body := SphereMesh.new()
	body.radius = 0.5
	body.height = 1.1
	Kit.mesh_instance(_visual, body, _body_mat, Vector3(0.0, 0.7, 0.0))
	var belly := SphereMesh.new()
	belly.radius = 0.36
	belly.height = 0.7
	Kit.mesh_instance(_visual, belly, Kit.mat(&"skin_light"), Vector3(0.0, 0.65, -0.2))
	var head := SphereMesh.new()
	head.radius = 0.45
	head.height = 0.85
	Kit.mesh_instance(_visual, head, _body_mat, Vector3(0.0, 1.5, 0.0))
	var face := SphereMesh.new()
	face.radius = 0.33
	face.height = 0.5
	Kit.mesh_instance(_visual, face, Kit.mat(&"skin_light", 0.02), Vector3(0.0, 1.45, -0.22))
	for side: float in [-1.0, 1.0]:
		var ear := SphereMesh.new()
		ear.radius = 0.18
		ear.height = 0.12
		var e := Kit.mesh_instance(_visual, ear, Kit.mat(&"skin_mid", 0.02), Vector3(0.45 * side, 1.6, 0.0))
		e.rotation.z = PI * 0.5
		var eye := SphereMesh.new()
		eye.radius = 0.07
		eye.height = 0.14
		Kit.mesh_instance(_visual, eye, Kit.mat(&"bark_dark"), Vector3(0.13 * side, 1.55, -0.48))
		var foot := SphereMesh.new()
		foot.radius = 0.16
		foot.height = 0.2
		Kit.mesh_instance(_visual, foot, _body_mat, Vector3(0.2 * side, 0.12, -0.1))
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 0.5, 0.45)
	_visual.add_child(_tail)
	for i in 4:
		var seg := SphereMesh.new()
		seg.radius = 0.09
		seg.height = 0.18
		Kit.mesh_instance(_tail, seg, _body_mat, Vector3(0.0, i * 0.17, i * 0.08))
	_arm = Node3D.new()
	_arm.position = Vector3(0.45, 1.0, 0.0)
	_visual.add_child(_arm)
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.1
	arm_mesh.height = 0.6
	Kit.mesh_instance(_arm, arm_mesh, _body_mat, Vector3(0.0, 0.25, 0.0))
	var nut := SphereMesh.new()
	nut.radius = 0.25
	nut.height = 0.5
	_held_nut = Kit.mesh_instance(_arm, nut, Kit.mat(&"bark_mid", 0.03), Vector3(0.0, 0.6, 0.0))
	_hurtbox = Area3D.new()
	_hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.set_meta(&"actor", self)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.6
	cap.height = 2.0
	Kit.add_shape(_hurtbox, cap, Vector3(0.0, 1.0, 0.0))
	add_child(_hurtbox)
	_debug = Kit.label(self, Vector3(0.0, 2.6, 0.0), "", 32)


func _animate() -> void:
	_bob += 0.12
	var t := float(state_ticks)
	_visual.position.y = sin(_bob) * 0.04
	_tail.rotation.z = sin(_bob * 0.7) * 0.4
	_held_nut.visible = state in [S.PERCHED, S.AIM]
	match state:
		S.AIM:
			_arm.rotation.x = lerpf(0.0, 2.4, clampf(t / AIM_TICKS, 0.0, 1.0))
			_visual.scale = Vector3(1.05, 0.95, 1.05)
		S.THROW:
			_arm.rotation.x = lerpf(2.4, -1.2, clampf(t / THROW_TICKS, 0.0, 1.0))
			_visual.scale = Vector3.ONE
		S.STUNNED:
			_visual.rotation.z = sin(t * 0.3) * 0.25
			_arm.rotation.x = -0.6
		_:
			_arm.rotation.x = lerpf(_arm.rotation.x, 0.0, 0.2)
			_visual.rotation.z = 0.0
			_visual.scale = Vector3.ONE
	_debug.visible = DevTools.ai_debug
	if _debug.visible:
		_debug.text = "%s %d hp%d" % [S.keys()[state], state_ticks, hp]
