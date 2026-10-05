class_name MotherGloop
extends Node3D
## World 1 boss (plan §8.5, retuned in Build 2). 5 HP, shrinks from scale 1.0 to 0.6 as she takes
## damage. Only a Plunge on her open core hurts her: one Plunge per opening, and the core closes
## the moment it's hit, so the fight takes exactly 5 clean Plunges. Thresholds at 3 and 1 HP
## start phases 2 and 3. Every state has a bounded
## exit and a watchdog. All timings are physics ticks.

signal hp_changed(hp: int)
signal defeated_once

enum S { SLEEP, INTRO, WAIT, CHOOSE, HOP_WARN, HOP_AIR, BARRAGE_WARN, BARRAGE_AIR, ROLL_WARN, ROLL, UNROLL, CORE_WINDOW, PHASE_CHANGE, SPLIT, RECOVER, DEFEAT, GONE }
enum Pattern { NONE, HOP_SLAM, BOUNCE_BARRAGE, ROLLING_CHARGE }

const MAX_HP := 5
const WINDOW_CAP := 1
const THRESHOLDS: Array[int] = [3, 1]
const RADIUS := 2.2
const INTRO_TICKS := 100
const CHOOSE_TICKS := 24
const HOP_WARN := 48
const HOP_AIR := 50
const HOP_HEIGHT := 7.0
const BARRAGE_WARN := 30
const BARRAGE_AIR := 36
const BARRAGE_HEIGHT := 4.0
const BARRAGE_HOPS := 3
const RING_GAP := 24
const ROLL_WARN := 48
const ROLL_MAX_TICKS := 180
const ROLL_MAX_DIST := 25.0
const ROLL_SPEED := 12.0
const UNROLL_TICKS := 90
const RECOVER_TICKS := 90
const WINDOW_FIRST := 240
const WINDOW_NORMAL := 150
const WINDOW_STUMP := 180
const WINDOW_HINT_AT := 120
const BODY_EXTEND := 18
const BODY_EXTEND_MAX := 54
const CORE_INVULN := 18
const PHASE_TICKS := 36
const MIN_WARN := 21
const DEFEAT_TICKS := 110
const MAX_MINIONS := 3
const WEIGHTS := {Pattern.HOP_SLAM: 1.0, Pattern.BOUNCE_BARRAGE: 1.2, Pattern.ROLLING_CHARGE: 1.2}

var hp: int = MAX_HP
var state: S = S.SLEEP
var state_ticks: int = 0
var phase: int = 1
var last_pattern: Pattern = Pattern.NONE
var forced_pattern: Pattern = Pattern.NONE
var window_damage: int = 0
var window_len: int = 0
var window_extend: int = 0
var windows_opened: int = 0
var core_invuln: int = 0
var plunged_ever: bool = false
var defeated_count: int = 0
var watchdog_trips: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var director: AttackDirector = AttackDirector.new()
var arena_center: Vector3 = Vector3.ZERO
var arena_radius: float = 15.0
var stumps: Array[Vector3] = []
var stump_radius: float = 1.0
var minion_parent: Node3D
var hitstop_ticks: int = 0
## Tests that force the watchdog set this so the expected trip is a warning, not an error.
var expect_watchdog: bool = false

var _ground_y: float = 0.0
var _hop_from: Vector3
var _hop_to: Vector3
var _hop_air: int = 0
var _hop_height: float = 0.0
var _hops_left: int = 0
var _roll_dir: Vector3
var _roll_dist: float = 0.0
var _goo_ticks: int = 0
var _pending_ring_tick: int = -1
var _last_core_id: int = -1
var _last_body_id: int = -1
var _slam_tick: bool = false
var _squash: Vector3 = Vector3.ONE
var _player: Player

var _visual: Node3D
var _body_mat: ShaderMaterial
var _hat: Node3D
var _core: MeshInstance3D
var _body_area: Area3D
var _core_area: Area3D
var _marker: MeshInstance3D
var _aim: MeshInstance3D
var _hint: Label3D
var _debug: Label3D


func _ready() -> void:
	add_to_group(&"boss")
	add_to_group(&"lockable")
	add_to_group(&"enemy_attacker")
	_ground_y = global_position.y
	_build()
	if minion_parent == null:
		minion_parent = get_parent() as Node3D


# --- Pure logic (unit tested) -----------------------------------------------------------------

func phase_for(h: int) -> int:
	if h > THRESHOLDS[0]:
		return 1
	if h > THRESHOLDS[1]:
		return 2
	return 3


func eligible_patterns() -> Array[Pattern]:
	var out: Array[Pattern] = [Pattern.HOP_SLAM]
	if phase >= 2:
		out.append(Pattern.BOUNCE_BARRAGE)
	if phase >= 3:
		out.append(Pattern.ROLLING_CHARGE)
	return out


## There's always a legal choice: forced first pattern on a new phase, else weighted random
## excluding the previous pattern when more than one is eligible.
func choose_pattern() -> Pattern:
	if forced_pattern != Pattern.NONE:
		var f := forced_pattern
		forced_pattern = Pattern.NONE
		last_pattern = f
		return f
	var eligible := eligible_patterns()
	if eligible.size() == 1:
		last_pattern = eligible[0]
		return eligible[0]
	var candidates: Array[Pattern] = eligible.filter(func(p: Pattern) -> bool: return p != last_pattern)
	var total := 0.0
	for p in candidates:
		total += float(WEIGHTS[p])
	var roll := rng.randf() * total
	for p in candidates:
		roll -= float(WEIGHTS[p])
		if roll <= 0.0:
			last_pattern = p
			return p
	last_pattern = candidates[-1]
	return candidates[-1]


func open_window(length: int) -> void:
	windows_opened += 1
	window_len = WINDOW_FIRST if windows_opened == 1 else length
	window_extend = 0
	window_damage = 0
	core_invuln = 0
	_set_state(S.CORE_WINDOW)


func window_ticks_left() -> int:
	return window_len + window_extend - state_ticks


## Body hits extend an open window by 0.3 s, at most 0.9 s in total.
func extend_window() -> void:
	window_extend = mini(window_extend + BODY_EXTEND, BODY_EXTEND_MAX)


## Applies core damage with the per-window cap and threshold clamp. Returns damage dealt.
func apply_core_damage(raw: int) -> int:
	if state != S.CORE_WINDOW or core_invuln > 0 or hp <= 0:
		return 0
	var floor_hp := 0
	for t in THRESHOLDS:
		if hp > t:
			floor_hp = t
			break
	var dmg := mini(raw, WINDOW_CAP - window_damage)
	dmg = mini(dmg, hp - floor_hp)
	if dmg <= 0:
		return 0
	hp -= dmg
	window_damage += dmg
	core_invuln = CORE_INVULN
	hp_changed.emit(hp)
	if hp <= 0:
		_begin_defeat()
	elif hp == floor_hp:
		_set_state(S.PHASE_CHANGE)
	elif window_damage >= WINDOW_CAP:
		_set_state(S.CHOOSE)
	return dmg


func _begin_defeat() -> void:
	_set_state(S.DEFEAT)
	director.boss_lock = false
	if defeated_count == 0:
		defeated_count = 1
		defeated_once.emit()
		Events.boss_defeated.emit(&"world_01")


func _max_ticks(s: S) -> int:
	match s:
		S.SLEEP, S.GONE:
			return 1 << 30
		S.INTRO:
			return INTRO_TICKS + 5
		S.WAIT:
			return 240
		S.CHOOSE:
			return CHOOSE_TICKS + 5
		S.HOP_WARN, S.BARRAGE_WARN, S.ROLL_WARN:
			return HOP_WARN + 5
		S.HOP_AIR, S.BARRAGE_AIR:
			return HOP_AIR + 5
		S.ROLL:
			return ROLL_MAX_TICKS + 5
		S.UNROLL:
			return UNROLL_TICKS + 5
		S.CORE_WINDOW:
			return WINDOW_FIRST + BODY_EXTEND_MAX + 5
		S.PHASE_CHANGE, S.SPLIT:
			return PHASE_TICKS + 5
		S.RECOVER:
			return RECOVER_TICKS + 5
		S.DEFEAT:
			return DEFEAT_TICKS + 5
	return 600


func _set_state(s: S) -> void:
	state = s
	state_ticks = 0
	director.boss_lock = s in [S.HOP_WARN, S.BARRAGE_WARN, S.ROLL_WARN, S.CORE_WINDOW]


## Faster as she shrinks; warnings never drop under 0.35 s.
func _timing(base: int, is_warning: bool = false) -> int:
	var k := lerpf(0.75, 1.0, float(hp) / MAX_HP)
	return maxi(int(round(base * k)), MIN_WARN if is_warning else 1)


func body_scale() -> float:
	return 0.6 + 0.4 * float(hp) / MAX_HP


# --- Tick -------------------------------------------------------------------------------------

func start_fight() -> void:
	if state == S.SLEEP:
		_set_state(S.INTRO)
		AudioDirector.play(&"boss_roar")


func _player_ref() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


func is_lockable() -> bool:
	return state not in [S.SLEEP, S.DEFEAT, S.GONE]


func _physics_process(_delta: float) -> void:
	director.advance()
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	state_ticks += 1
	if core_invuln > 0:
		core_invuln -= 1
	if state_ticks > _max_ticks(state):
		watchdog_trips += 1
		var msg := "MotherGloop watchdog: state %s exceeded %d ticks" % [S.keys()[state], _max_ticks(state)]
		if expect_watchdog:
			push_warning(msg)
		else:
			push_error(msg)
		_set_state(S.RECOVER)
	_tick_state()
	_tick_rings()
	_update_visual()


func _tick_state() -> void:
	var p := _player_ref()
	_slam_tick = false
	match state:
		S.INTRO:
			_squash = Vector3(1.0 + sin(state_ticks * 0.3) * 0.1, 1.0 - sin(state_ticks * 0.3) * 0.1, 1.0 + sin(state_ticks * 0.3) * 0.1)
			if state_ticks >= INTRO_TICKS:
				_set_state(S.CHOOSE)
		S.CHOOSE, S.RECOVER:
			if state_ticks >= (CHOOSE_TICKS if state == S.CHOOSE else RECOVER_TICKS):
				_set_state(S.WAIT)
		S.WAIT:
			# The boss waits for any minion attack already in progress before winding up.
			if not director.any_active_attack():
				_start_pattern(choose_pattern())
		S.HOP_WARN:
			_squash = Vector3(1.0, 1.0, 1.0).lerp(Vector3(1.25, 0.7, 1.25), clampf(float(state_ticks) / _timing(HOP_WARN, true), 0.0, 1.0))
			if p != null:
				_hop_to = _clamp_to_arena(p.global_position)
			if state_ticks >= _timing(HOP_WARN, true):
				_begin_hop(_hop_to, _timing(HOP_AIR), HOP_HEIGHT, S.HOP_AIR)
		S.HOP_AIR, S.BARRAGE_AIR:
			var t := float(state_ticks) / _hop_air
			var flat := _hop_from.lerp(_hop_to, clampf(t, 0.0, 1.0))
			global_position = Vector3(flat.x, _ground_y + _hop_height * 4.0 * t * (1.0 - t), flat.z)
			_squash = Vector3(0.85, 1.2, 0.85)
			if state_ticks >= _hop_air:
				_land()
		S.BARRAGE_WARN:
			_squash = Vector3(1.2, 0.75, 1.2)
			if p != null:
				_hop_to = _clamp_to_arena(p.global_position)
			if state_ticks >= _timing(BARRAGE_WARN, true):
				_begin_hop(_hop_to, _timing(BARRAGE_AIR), BARRAGE_HEIGHT, S.BARRAGE_AIR)
		S.ROLL_WARN:
			_squash = Vector3(1.1, 0.9, 1.1) * (1.0 + sin(state_ticks * 0.9) * 0.04)
			if p != null:
				var to := p.global_position - global_position
				to.y = 0.0
				if to.length() > 0.1:
					_roll_dir = to.normalized()
			if state_ticks >= _timing(ROLL_WARN, true):
				_roll_dist = 0.0
				_goo_ticks = 0
				_set_state(S.ROLL)
				AudioDirector.play(&"boss_roll")
		S.ROLL:
			var speed := ROLL_SPEED / lerpf(0.75, 1.0, float(hp) / MAX_HP) / 60.0
			global_position += _roll_dir * speed
			_roll_dist += speed
			_goo_ticks += 1
			if _goo_ticks % 20 == 0:
				var goo := GooPuddle.new()
				minion_parent.add_child(goo)
				goo.global_position = Vector3(global_position.x, _ground_y, global_position.z)
			var r := RADIUS * body_scale()
			for s in stumps:
				if Vector2(global_position.x - s.x, global_position.z - s.z).length() < r + stump_radius:
					AudioDirector.play(&"boss_bonk")
					_shake(0.6)
					open_window(WINDOW_STUMP)
					return
			var from_center := Vector2(global_position.x - arena_center.x, global_position.z - arena_center.z).length()
			if from_center > arena_radius - r or state_ticks >= ROLL_MAX_TICKS or _roll_dist >= ROLL_MAX_DIST:
				_set_state(S.UNROLL)
		S.UNROLL:
			_squash = Vector3(1.15, 0.85, 1.15)
			if state_ticks >= UNROLL_TICKS:
				_set_state(S.CHOOSE)
		S.CORE_WINDOW:
			_squash = Vector3(1.3, 0.55, 1.3) * (1.0 + sin(state_ticks * 0.4) * 0.03)
			if state_ticks >= window_len + window_extend:
				_set_state(S.CHOOSE)
		S.PHASE_CHANGE:
			_squash = Vector3.ONE * (1.0 + float(state_ticks) / PHASE_TICKS * 0.25)
			if state_ticks >= PHASE_TICKS:
				phase = phase_for(hp)
				if phase == 2:
					forced_pattern = Pattern.BOUNCE_BARRAGE
					_set_state(S.SPLIT)
				else:
					forced_pattern = Pattern.ROLLING_CHARGE
					AudioDirector.play(&"boss_roar")
					_set_state(S.CHOOSE)
		S.SPLIT:
			_squash = Vector3(1.2, 1.2, 1.2) * (1.0 - float(state_ticks) / PHASE_TICKS * 0.2)
			if state_ticks >= PHASE_TICKS:
				_spit_minions()
				_set_state(S.CHOOSE)
		S.DEFEAT:
			_squash = Vector3.ONE * (1.0 + float(state_ticks) / DEFEAT_TICKS * 0.5) + Vector3(sin(state_ticks * 0.8), -sin(state_ticks * 0.8), sin(state_ticks * 0.8)) * 0.08
			if state_ticks >= DEFEAT_TICKS:
				Fx.confetti(get_parent(), global_position + Vector3.UP * 2.0)
				AudioDirector.play(&"boss_pop")
				_shake(0.8)
				_set_state(S.GONE)
				visible = false
				_body_area.monitorable = false
				_core_area.monitorable = false


func _start_pattern(p: Pattern) -> void:
	match p:
		Pattern.HOP_SLAM:
			_set_state(S.HOP_WARN)
		Pattern.BOUNCE_BARRAGE:
			_hops_left = BARRAGE_HOPS
			_set_state(S.BARRAGE_WARN)
		Pattern.ROLLING_CHARGE:
			_set_state(S.ROLL_WARN)
	Telemetry.log_event("boss_pattern", {"pattern": Pattern.keys()[p], "hp": hp})


func _begin_hop(to: Vector3, air: int, height: float, s: S) -> void:
	_hop_from = global_position
	_hop_to = Vector3(to.x, _ground_y, to.z)
	_hop_air = air
	_hop_height = height
	_set_state(s)
	director.boss_lock = false
	AudioDirector.play(&"slime_hop", 0.0, 0.5)


func _land() -> void:
	global_position = _hop_to
	_squash = Vector3(1.4, 0.6, 1.4)
	_slam_tick = true
	_shake(0.5)
	AudioDirector.play(&"boss_slam")
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.3, Palette.color(&"gloop_pink"), 16, 6.0, 0.18, -10.0, 0.6)
	if state == S.HOP_AIR:
		_spawn_ring()
		open_window(WINDOW_NORMAL)
	else:
		_hops_left -= 1
		if _hops_left <= 0:
			_spawn_ring()
			_pending_ring_tick = RING_GAP
			open_window(WINDOW_NORMAL)
		else:
			_set_state(S.BARRAGE_WARN)


func _tick_rings() -> void:
	if _pending_ring_tick > 0:
		_pending_ring_tick -= 1
		if _pending_ring_tick == 0:
			_spawn_ring()


func _spawn_ring() -> void:
	var ring := Shockwave.new()
	ring.ground_y = _ground_y
	ring.max_radius = arena_radius + 2.0
	minion_parent.add_child(ring)
	ring.global_position = Vector3(global_position.x, _ground_y, global_position.z)


func _spit_minions() -> void:
	var alive := 0
	for c in minion_parent.get_children():
		if c is Gloplet and (c as Gloplet).state != Gloplet.S.DEFEATED:
			alive += 1
	for i in mini(3, MAX_MINIONS - alive):
		var g := Gloplet.new()
		var a := rng.randf() * TAU
		var at := _clamp_to_arena(global_position + Vector3(cos(a), 0.0, sin(a)) * 4.0)
		g.setup(preload("res://data/enemies/gloplet.tres"), at, director, rng.randi())
		g.add_to_group(&"boss_minion")
		minion_parent.add_child(g)
		Fx.burst(minion_parent, at + Vector3.UP * 0.5, Palette.color(&"slime_green"), 10, 3.0)
	AudioDirector.play(&"slime_pop", 0.0, 0.7)


func _clamp_to_arena(p: Vector3) -> Vector3:
	var flat := Vector2(p.x - arena_center.x, p.z - arena_center.z)
	var max_r := arena_radius - RADIUS * body_scale() - 0.5
	if flat.length() > max_r:
		flat = flat.normalized() * max_r
	return Vector3(arena_center.x + flat.x, _ground_y, arena_center.z + flat.y)


func _shake(amount: float) -> void:
	var p := _player_ref()
	if p != null and p.camera_rig != null and p.camera_rig.has_method(&"add_trauma"):
		p.camera_rig.call(&"add_trauma", amount)


# --- Combat -----------------------------------------------------------------------------------

func receive_player_attack(atk: Dictionary, area: Area3D) -> Dictionary:
	if state in [S.SLEEP, S.DEFEAT, S.GONE]:
		return {}
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	var bounce_h := float(atk.get("bounce", 2.2)) if plunge else 0.0
	var id := int(atk.get("id", -1))
	var is_core := area == _core_area
	if id == (_last_core_id if is_core else _last_body_id):
		return {"bounce": bounce_h}
	if is_core:
		_last_core_id = id
	else:
		_last_body_id = id
	if is_core and state == S.CORE_WINDOW and plunge:
		plunged_ever = true
		var dealt := apply_core_damage(1)
		if dealt > 0:
			_body_mat.set_shader_parameter(&"flash", 1.0)
			create_tween().tween_method(func(v: float) -> void: _body_mat.set_shader_parameter(&"flash", v), 1.0, 0.0, 0.25)
			AudioDirector.play(&"boss_hurt")
		return {"hit": true, "bounce": bounce_h}
	if state == S.CORE_WINDOW:
		extend_window()
	return {"hit": true, "bounce": bounce_h}


## Contact uses the same ellipsoid the body is drawn with, grown by the hero's radius.
func touches(p: Player, margin: float = 0.35) -> bool:
	var sc := body_scale()
	var rx := RADIUS * _squash.x * sc + margin
	var ry := 0.95 * RADIUS * _squash.y * sc + margin + 0.3
	var center := global_position + Vector3(0.0, 0.95 * RADIUS * _squash.y * sc, 0.0)
	var d := p.global_position + Vector3.UP * 0.6 - center
	return (d.x * d.x + d.z * d.z) / (rx * rx) + (d.y * d.y) / (ry * ry) < 1.0


func damage_to_player(p: Player) -> Dictionary:
	if state in [S.SLEEP, S.INTRO, S.CORE_WINDOW, S.DEFEAT, S.GONE, S.PHASE_CHANGE, S.SPLIT]:
		return {}
	if state in [S.HOP_AIR, S.BARRAGE_AIR] and not _slam_tick:
		return {}
	if not touches(p):
		return {}
	if _slam_tick:
		return {"halves": 2, "from": global_position, "heavy": true, "cause": "boss_slam"}
	if state == S.ROLL:
		return {"halves": 2, "from": global_position, "heavy": true, "cause": "boss_roll"}
	return {"halves": 1, "from": global_position, "cause": "boss_contact"}


# --- Visuals ----------------------------------------------------------------------------------

func _build() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_body_mat = Kit.slime_mat(&"gloop_pink", 0.05)
	_body_mat.set_shader_parameter(&"wobble", 0.06)
	var body := SphereMesh.new()
	body.radius = RADIUS
	body.height = RADIUS * 1.9
	body.radial_segments = 24
	body.rings = 12
	Kit.mesh_instance(_visual, body, _body_mat, Vector3(0.0, RADIUS * 0.95, 0.0))
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.32
		eye.height = 0.5
		Kit.mesh_instance(_visual, eye, Kit.mat(&"bark_dark", 0.02), Vector3(0.7 * side, RADIUS * 1.15, -RADIUS * 0.86))
		var glint := SphereMesh.new()
		glint.radius = 0.1
		glint.height = 0.2
		Kit.mesh_instance(_visual, glint, Kit.mat(&"foam"), Vector3(0.7 * side + 0.1, RADIUS * 1.25, -RADIUS * 0.96))
	var mouth := TorusMesh.new()
	mouth.inner_radius = 0.25
	mouth.outer_radius = 0.36
	var m := Kit.mesh_instance(_visual, mouth, Kit.mat(&"bark_dark"), Vector3(0.0, RADIUS * 0.75, -RADIUS * 0.92))
	m.rotation.x = PI * 0.5
	m.scale = Vector3(1.0, 1.0, 0.4)
	_core = Kit.mesh_instance(_visual, _sphere(0.6), Fx.fx_mat(Palette.color(&"gold")), Vector3(0.0, RADIUS * 1.85, 0.0))
	_hat = Node3D.new()
	_hat.position = Vector3(0.0, RADIUS * 1.88, 0.0)
	_visual.add_child(_hat)
	var pad := CylinderMesh.new()
	pad.top_radius = 1.7
	pad.bottom_radius = 1.6
	pad.height = 0.14
	pad.radial_segments = 20
	Kit.mesh_instance(_hat, pad, Kit.mat(&"grass_light", 0.03), Vector3.ZERO)
	Kit.mesh_instance(_hat, _sphere(0.32), Kit.mat(&"gloop_pink", 0.02), Vector3(0.6, 0.25, 0.3))
	Kit.mesh_instance(_hat, _sphere(0.14), Kit.mat(&"gold"), Vector3(0.6, 0.45, 0.3))
	_body_area = _area(Layers.ENEMY_HURTBOX, RADIUS)
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = RADIUS * 1.9
	(_body_area.get_child(0) as CollisionShape3D).shape = cyl
	_core_area = _area(Layers.ENEMY_HURTBOX | Layers.BOUNCE, 1.1)
	_marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.05
	_marker.mesh = disc
	_marker.material_override = Fx.fx_mat(Color(Palette.INK, 0.45))
	_marker.top_level = true
	_marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_marker)
	_aim = MeshInstance3D.new()
	var line := BoxMesh.new()
	line.size = Vector3(0.6, 0.05, 1.0)
	_aim.mesh = line
	_aim.material_override = Fx.fx_mat(Color(Palette.color(&"portal_magenta"), 0.6))
	_aim.top_level = true
	_aim.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_aim)
	_hint = Kit.label(self, Vector3(0.0, RADIUS * 2.0 + 2.2, 0.0), "Plunge!", 72)
	_hint.modulate = Palette.color(&"gold")
	_hint.visible = false
	_debug = Kit.label(self, Vector3(0.0, RADIUS * 2.0 + 3.2, 0.0), "", 36)


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _area(layer: int, r: float) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = layer
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	cs.shape = s
	a.add_child(cs)
	add_child(a)
	return a


func _update_visual() -> void:
	var sc := body_scale()
	_visual.scale = _squash * sc
	if state == S.ROLL:
		_visual.rotation.x -= 0.25
	else:
		_visual.rotation.x = lerpf(_visual.rotation.x, 0.0, 0.2)
		var p := _player_ref()
		if p != null and state not in [S.DEFEAT, S.GONE]:
			var to := p.global_position - global_position
			to.y = 0.0
			if to.length() > 0.5:
				_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-to.x, -to.z), 0.08)
	# Hurtboxes follow the drawn body: a cylinder inside the squashed ellipsoid, the core on top.
	var height := 1.9 * RADIUS * sc * _squash.y
	var body_shape := (_body_area.get_child(0) as CollisionShape3D).shape as CylinderShape3D
	body_shape.radius = RADIUS * sc * _squash.x * 0.92
	body_shape.height = height * 0.9
	_body_area.position = Vector3(0.0, height * 0.5, 0.0)
	_core_area.position = Vector3(0.0, height - 0.15, 0.0)
	((_core_area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = 1.1 * sc
	var open := state == S.CORE_WINDOW
	_hat.rotation.z = lerpf(_hat.rotation.z, 1.1 if open else 0.0, 0.2)
	_hat.position.x = lerpf(_hat.position.x, 1.2 if open else 0.0, 0.2)
	_core.visible = open
	_core.scale = Vector3.ONE * (1.0 + sin(state_ticks * 0.3) * 0.12)
	_hint.visible = open and windows_opened == 1 and state_ticks > WINDOW_HINT_AT and not plunged_ever
	_hint.position.y = height + 2.0
	# Landing shadow (always visible during hops) and Rolling Charge aim line.
	_marker.visible = state in [S.HOP_WARN, S.HOP_AIR, S.BARRAGE_WARN, S.BARRAGE_AIR]
	if _marker.visible:
		_marker.global_position = Vector3(_hop_to.x, _ground_y + 0.06, _hop_to.z)
		_marker.scale = Vector3.ONE * RADIUS * sc
	_aim.visible = state == S.ROLL_WARN
	if _aim.visible and _roll_dir.length() > 0.1:
		var length := 14.0
		_aim.global_position = global_position + _roll_dir * (length * 0.5) + Vector3.UP * 0.06
		_aim.basis = Basis.looking_at(_roll_dir, Vector3.UP).scaled(Vector3(1.0, 1.0, length))
	_debug.visible = DevTools.ai_debug
	if _debug.visible:
		_debug.text = "%s t%d hp%d ph%d win%d" % [S.keys()[state], state_ticks, hp, phase, window_damage]
