class_name BossBase
extends Node3D
## Shared base for the Build 4 bosses (Rumble Golem, Avalanche Ape). Same rules as Mother Gloop:
## the boss has a weak spot that only opens after an attack, only a Plunge on it hurts, one hit
## per opening, and every state has a watchdog. Subclasses write tick_state() and the body.

signal hp_changed(hp: int)
signal defeated_once

const DEFEAT_TICKS := 110

var world_id: StringName
var boss_name: String = "Boss"
var max_hp: int = 4
var hp: int = 4
var state: int = 0
var state_ticks: int = 0
var weak_open: bool = false
var weak_invuln: int = 0
var defeated_count: int = 0
var watchdog_trips: int = 0
var hitstop_ticks: int = 0
var arena_center: Vector3
var arena_radius: float = 18.0
var ground_y: float = 0.0
var awake: bool = false
var gone: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Contact ellipsoid (horizontal radius, half height, centre height).
var body_rx: float = 2.0
var body_ry: float = 2.0
var body_cy: float = 2.0

var _player: Player
var _weak_area: Area3D
var _body_area: Area3D
var _flash_mats: Array[ShaderMaterial] = []
var _hint: Label3D
var _debug: Label3D
var _last_weak_id: int = -1
var _last_body_id: int = -1
var _defeat_ticks: int = -1


func _ready() -> void:
	add_to_group(&"boss")
	add_to_group(&"lockable")
	add_to_group(&"enemy_attacker")
	ground_y = global_position.y
	hp = max_hp
	build_body()
	_hint = Kit.label(self, Vector3(0.0, body_cy + body_ry + 2.5, 0.0), "Plunge!", 72)
	_hint.modulate = Palette.color(&"gold")
	_hint.visible = false
	_debug = Kit.label(self, Vector3(0.0, body_cy + body_ry + 3.5, 0.0), "", 34)


# --- Overridables -----------------------------------------------------------------------------

func build_body() -> void:
	pass


## The node holding the boss's meshes (scaled for squash and the defeat wobble).
func visual_root() -> Node3D:
	return self


func tick_state() -> void:
	pass


func max_ticks_for(_s: int) -> int:
	return 600


func on_watchdog() -> void:
	pass


func state_name() -> String:
	return str(state)


## Damage only when the boss can hurt you (not stunned, not asleep).
func harmful() -> bool:
	return awake and not weak_open and not gone


func contact_halves() -> int:
	return 1


# --- Helpers ----------------------------------------------------------------------------------

func player_ref() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func set_state(s: int) -> void:
	state = s
	state_ticks = 0


func flashy(color: StringName, outline: float = 0.05) -> ShaderMaterial:
	var m := Kit.unique_mat(color, outline)
	_flash_mats.append(m)
	return m


func flash(c: Color, amount: float) -> void:
	for m in _flash_mats:
		m.set_shader_parameter(&"flash_color", c)
		m.set_shader_parameter(&"flash", amount)


func area(layer: int, shape: Shape3D, offset: Vector3) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = layer
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	Kit.add_shape(a, shape, offset)
	add_child(a)
	return a


func shake(amount: float) -> void:
	var p := player_ref()
	if p != null and p.camera_rig != null and p.camera_rig.has_method(&"add_trauma"):
		p.camera_rig.call(&"add_trauma", amount)


func ring(at: Vector3, max_r: float = -1.0) -> void:
	var r := Shockwave.new()
	r.ground_y = ground_y
	r.max_radius = arena_radius + 2.0 if max_r < 0.0 else max_r
	get_parent().add_child(r)
	r.global_position = Vector3(at.x, ground_y, at.z)


func clamp_to_arena(p: Vector3, margin: float = 3.0) -> Vector3:
	var flat := Vector2(p.x - arena_center.x, p.z - arena_center.z)
	var max_r := arena_radius - margin
	if flat.length() > max_r:
		flat = flat.normalized() * max_r
	return Vector3(arena_center.x + flat.x, ground_y, arena_center.z + flat.y)


func face_player(rate: float = 0.08) -> void:
	var p := player_ref()
	if p == null:
		return
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), rate)


## Opens the weak spot (one Plunge hit closes it again).
func open_weak_spot() -> void:
	weak_open = true
	weak_invuln = 0
	_last_weak_id = -1


func close_weak_spot() -> void:
	weak_open = false


func start_fight() -> void:
	if not awake:
		awake = true
		AudioDirector.play(&"boss_roar")
		on_wake()


func on_wake() -> void:
	pass


# --- Engine -----------------------------------------------------------------------------------

func is_lockable() -> bool:
	return awake and not gone


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


func _physics_process(_delta: float) -> void:
	if gone:
		return
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	if _defeat_ticks >= 0:
		_defeat_ticks += 1
		# Wobble the drawn body only: Jolt can't scale the hit areas non-uniformly.
		visual_root().scale = Vector3.ONE * (1.0 + float(_defeat_ticks) / DEFEAT_TICKS * 0.4) + Vector3(sin(_defeat_ticks * 0.8), -sin(_defeat_ticks * 0.8), sin(_defeat_ticks * 0.8)) * 0.06
		if _defeat_ticks >= DEFEAT_TICKS:
			Fx.confetti(get_parent(), global_position + Vector3.UP * body_cy)
			AudioDirector.play(&"boss_pop")
			shake(0.8)
			gone = true
			visible = false
			_weak_area.monitorable = false
			_body_area.monitorable = false
		return
	if not awake:
		return
	state_ticks += 1
	if weak_invuln > 0:
		weak_invuln -= 1
	if state_ticks > max_ticks_for(state):
		watchdog_trips += 1
		push_error("%s watchdog: state %s exceeded %d ticks" % [boss_name, state_name(), max_ticks_for(state)])
		on_watchdog()
	tick_state()
	_hint.visible = weak_open and state_ticks > 90
	_debug.visible = DevTools.ai_debug
	if _debug.visible:
		_debug.text = "%s t%d hp%d%s" % [state_name(), state_ticks, hp, " OPEN" if weak_open else ""]


## Any hit on the open weak spot hurts (Plunge, sword or magic); one hit closes it.
func apply_weak_hit() -> int:
	if not weak_open or weak_invuln > 0 or hp <= 0:
		return 0
	hp -= 1
	weak_invuln = 18
	hp_changed.emit(hp)
	close_weak_spot()
	flash(Color.WHITE, 1.0)
	create_tween().tween_method(func(v: float) -> void: flash(Color.WHITE, v), 1.0, 0.0, 0.25)
	AudioDirector.play(&"boss_hurt")
	shake(0.5)
	if hp <= 0:
		_begin_defeat()
	else:
		on_weak_hit()
	return 1


func on_weak_hit() -> void:
	pass


func _begin_defeat() -> void:
	_defeat_ticks = 0
	if defeated_count == 0:
		defeated_count = 1
		defeated_once.emit()
		Events.boss_defeated.emit(world_id)


func receive_player_attack(atk: Dictionary, a: Area3D) -> Dictionary:
	if not awake or gone or _defeat_ticks >= 0:
		return {}
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	# Build 7 fix: a small, controlled hop off a boss, never a launch into the sky.
	var bounce_h := minf(float(atk.get("bounce", 2.2)), 2.0) if plunge else 0.0
	var id := int(atk.get("id", -1))
	var is_weak := a == _weak_area
	if id == (_last_weak_id if is_weak else _last_body_id):
		return {"bounce": bounce_h}
	if is_weak:
		_last_weak_id = id
	else:
		_last_body_id = id
	# Build 7 fix: the open weak spot takes the Plunge, the sword and magic alike.
	if is_weak:
		apply_weak_hit()
	else:
		AudioDirector.play(&"hit", -2.0, 0.7)
	return {"hit": true, "bounce": bounce_h}


func damage_to_player(p: Player) -> Dictionary:
	if not harmful():
		return {}
	var c := global_position + Vector3.UP * body_cy
	var d := p.global_position + Vector3.UP * 0.6 - c
	var rx := body_rx + 0.35
	var ry := body_ry + 0.6
	if (d.x * d.x + d.z * d.z) / (rx * rx) + (d.y * d.y) / (ry * ry) >= 1.0:
		return {}
	return {"halves": contact_halves(), "from": global_position, "heavy": contact_halves() > 1, "cause": boss_name}
