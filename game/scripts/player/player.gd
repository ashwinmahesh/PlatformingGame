class_name Player
extends CharacterBody3D
## The hero. Movement follows the tick order in plan §3.3; combat follows the contract in §4.1.
## The 60 Hz physics tick is the only gameplay clock. Visuals are cosmetic and read state only.

signal jumped(index: int)
signal landed
signal hp_changed(hp: int, max_hp: int)
signal died
signal bounced(height: float)

enum State { NORMAL, ATTACK, PLUNGE, PLUNGE_LAND, HURT, TALK, FROZEN, DEAD }

const ATTACK_SLASH_1 := preload("res://data/attacks/slash_1.tres")
const ATTACK_AIR := preload("res://data/attacks/air_slash.tres")
const ATTACK_PLUNGE := preload("res://data/attacks/plunge.tres")
const STORED_PRESS_TICKS := 12
const SAFE_GROUND_INTERVAL := 15
const LOCK_RANGE := 15.0
const LOCK_CONE_DEG := 70.0
const INTERACT_RANGE := 2.2
const HERO_PATH := "res://assets/models/kaykit_adventurers/Rogue.glb"
const SWORD_PATH := "res://assets/models/kaykit_adventurers/sword_1handed.gltf"
const HERO_SCALE := 0.62
const SWORD_LENGTH_SCALE := 1.45
const ATTACK_CLIPS: Dictionary[StringName, StringName] = {
	&"slash_1": &"1H_Melee_Attack_Slice_Diagonal",
	&"slash_2": &"1H_Melee_Attack_Slice_Horizontal",
	&"spin_finisher": &"2H_Melee_Attack_Spin",
	&"air_slash": &"1H_Melee_Attack_Chop",
}
const STEP_PROBE := 0.45
const STEP_HOLD_TICKS := 8

@export var settings: MovementSettings = preload("res://data/movement/hero_movement.tres")

## Tests turn this off so a saved Feel Lab preset never changes their numbers.
var use_dev_settings: bool = true
var input_source: InputSource = DeviceInput.new()
var last_input: PlayerInput = PlayerInput.new()
var state: State = State.NORMAL
var camera_yaw: float = 0.0
var camera_rig: Node3D
var facing: Vector3 = Vector3.FORWARD

# Movement (plan §3.3)
var jumps_used: int = 0
var coyote_left: float = 0.0
## Ticks since the buffered jump press; -1 when empty. A press stays valid for jump_buffer s.
var buffer_age: int = -1
var was_grounded: bool = false
var air_slash_ready: bool = false
var last_jump_index: int = 0
var tick: int = 0
var _short_hop_ok: bool = false
var _left_ground_by_launch: bool = false
var _ignore_floor_ticks: int = 0
var _last_platform_velocity: Vector3 = Vector3.ZERO
var _air_speed_cap: float = 7.0
var _landed_at_tick: int = -1000
var _speed_at_landing: float = 0.0
var _skidding: bool = false
var _step_hold: int = 0

# Combat (plan §4.1)
var attack: AttackDef
var attack_tick: int = 0
var attack_id: int = 0
var stored_attack_tick: int = -1
var plunge_tick: int = 0
var plunge_land_left: int = 0
var hurt_left: int = 0
var hitstop_ticks: int = 0
var lock_target: Node3D
var _attack_press_pending: bool = false
var _plunge_press_pending: bool = false
var _knock_velocity: Vector3 = Vector3.ZERO
var _knock_left: int = 0
var _knock_guarded: bool = false
var _slow_left: float = 0.0

# Health
var max_hp: int = 6
var hp: int = 6
var invuln_left: float = 0.0
var safe_position: Vector3 = Vector3.ZERO
var _respawn_left: float = 0.0
var _dead_left: float = 0.0

# Nodes (built in _ready)
var visual: Node3D
var body_pivot: Node3D
var hurtbox: Area3D
var sword_shape: SphereShape3D
var plunge_shape: SphereShape3D
var hurt_shape: CapsuleShape3D
var shadow: Decal
var landing_marker: Decal
var _plunge_streaks: CPUParticles3D
var _sword_rest: Transform3D
var _step_timer: float = 0.0
var hero: CharacterModel
var sword: Node3D
var _sword_trail: SwordTrail
var _land_anim_left: float = 0.0
var _cheer_left: float = 0.0
var _lock_marker: MeshInstance3D
var _squash: Vector3 = Vector3.ONE
var _flip_angle: float = 0.0
var _flip_speed: float = 0.0
var _run_phase: float = 0.0


func _ready() -> void:
	add_to_group(&"player")
	if use_dev_settings:
		settings = DevTools.movement_settings()
	collision_layer = Layers.PLAYER_BODY
	collision_mask = Layers.WORLD
	floor_max_angle = deg_to_rad(settings.max_floor_angle_deg)
	floor_snap_length = settings.step_height + 0.05
	floor_constant_speed = true
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	safe_margin = 0.02
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.2
	cs.shape = cap
	cs.position.y = 0.6
	add_child(cs)
	_build_hurtbox()
	_build_visual()
	_build_shadow()
	_build_landing_marker()
	_build_plunge_streaks()
	max_hp = Progress.max_halves()
	hp = max_hp
	safe_position = global_position


# --- Public API -------------------------------------------------------------------------------

func has_buffered_jump() -> bool:
	return buffer_age >= 0 and buffer_age <= int(settings.jump_buffer * 60.0 + 0.001)


func is_grounded() -> bool:
	return is_on_floor() and _ignore_floor_ticks <= 0


func is_plunge_active() -> bool:
	return state == State.PLUNGE and plunge_tick > settings.plunge_hang_ticks


func is_sword_active() -> bool:
	return state == State.ATTACK and attack != null and attack.phase_at(attack_tick) == AttackDef.Phase.ACTIVE


func attack_phase() -> AttackDef.Phase:
	if state != State.ATTACK or attack == null:
		return AttackDef.Phase.DONE
	return attack.phase_at(attack_tick)


## Hitbox transforms for the resolver (queried directly, never through animation).
func sword_transform() -> Transform3D:
	var reach := attack.reach if attack != null else 0.9
	return Transform3D(Basis(), global_position + Vector3.UP * 0.65 + facing * reach)


func plunge_transform() -> Transform3D:
	return Transform3D(Basis(), global_position + Vector3.UP * 0.15)


func hurt_transform() -> Transform3D:
	return Transform3D(Basis(), global_position + Vector3.UP * 0.6)


func current_attack_dict() -> Dictionary:
	if is_plunge_active():
		return {"id": attack_id, "damage": ATTACK_PLUNGE.damage, "kind": &"plunge", "from": global_position, "hitstop": ATTACK_PLUNGE.hitstop, "knockback": ATTACK_PLUNGE.knockback, "bounce": settings.plunge_bounce_height}
	if attack == null:
		return {}
	return {"id": attack_id, "damage": attack.damage, "kind": attack.id, "from": global_position, "hitstop": attack.hitstop, "knockback": attack.knockback}


## Plunge bounce off a hurtbox or bounce surface (plan §3.3 rule 8, §4.1).
func bounce(height: float, from_plunge: bool = true) -> void:
	state = State.NORMAL
	attack = null
	velocity.y = settings.launch_velocity(height)
	if from_plunge:
		velocity.x = 0.0
		velocity.z = 0.0
	jumps_used = mini(jumps_used, 2)
	coyote_left = 0.0
	air_slash_ready = true
	_short_hop_ok = false
	_left_ground_by_launch = true
	_ignore_floor_ticks = 2
	_air_speed_cap = settings.run_speed
	_squash = Vector3(0.75, 1.3, 0.75)
	_flip_speed = TAU * 2.0
	bounced.emit(height)
	AudioDirector.play(&"springcap" if height > 3.5 else &"bounce")
	Telemetry.log_event("bounce", {"h": height, "pos": global_position})


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


## Returns true when damage was taken.
func take_damage(halves: int, source_pos: Vector3, heavy: bool = false, cause: String = "hit") -> bool:
	if invuln_left > 0.0 or state in [State.DEAD, State.FROZEN] or halves <= 0:
		return false
	hp = maxi(hp - halves, 0)
	hp_changed.emit(hp, max_hp)
	invuln_left = settings.invuln_time
	attack = null
	buffer_age = -1
	stored_attack_tick = -1
	_attack_press_pending = false
	_plunge_press_pending = false
	state = State.HURT
	hurt_left = settings.heavy_hurt_ticks if heavy else settings.hurt_ticks
	var away := global_position - source_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	var grounded := is_grounded()
	var dist := settings.ground_knockback if grounded else settings.air_knockback
	_knock_left = settings.knockback_ticks
	_knock_velocity = away * dist / (settings.knockback_ticks / 60.0)
	_knock_guarded = grounded
	if not grounded:
		velocity.y = maxf(velocity.y, 2.0)
	AudioDirector.play(&"hurt")
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.7, Palette.color(&"roof_red"), 8, 4.0, 0.1)
	if camera_rig != null and camera_rig.has_method(&"add_trauma"):
		camera_rig.call(&"add_trauma", 0.45)
	Telemetry.log_event("hurt", {"cause": cause, "halves": halves, "hp": hp, "pos": global_position})
	if hp <= 0:
		_die(cause)
	return true


func heal(halves: int) -> void:
	hp = mini(hp + halves, max_hp)
	hp_changed.emit(hp, max_hp)


func refill() -> void:
	max_hp = Progress.max_halves()
	hp = max_hp
	hp_changed.emit(hp, max_hp)


## Fell into water or out of the world: lose ½ heart and return to safe ground (plan §9.8).
func on_hazard(kind: StringName = &"water") -> void:
	if state in [State.DEAD, State.FROZEN]:
		return
	if kind == &"water":
		AudioDirector.play(&"splash")
		Fx.burst(get_parent(), global_position, Palette.color(&"foam"), 16, 5.0, 0.15)
	else:
		AudioDirector.play(&"poof")
		Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"leaf_dark"), 16, 5.0, 0.15)
	Telemetry.log_event("fall", {"pos": global_position, "kind": String(kind)})
	hp = maxi(hp - 1, 0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_die("fall")
		return
	state = State.FROZEN
	visual.visible = false
	velocity = Vector3.ZERO
	_respawn_left = 0.55


func respawn_at(pos: Vector3, look: Vector3 = Vector3.FORWARD) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	jumps_used = 0
	buffer_age = -1
	coyote_left = 0.0
	was_grounded = false
	air_slash_ready = false
	attack = null
	hitstop_ticks = 0
	state = State.NORMAL
	visual.visible = true
	_ignore_floor_ticks = 0
	_left_ground_by_launch = false
	_slow_left = 0.0
	look.y = 0.0
	if look.length() > 0.01:
		facing = look.normalized()
	safe_position = pos
	# Refresh contact flags at the new position so a teleport never reads the old floor.
	if is_inside_tree():
		move_and_slide()
		velocity = Vector3.ZERO
		was_grounded = is_on_floor()
	if camera_rig != null and camera_rig.has_method(&"snap"):
		camera_rig.call(&"snap")


func apply_slow(seconds: float) -> void:
	_slow_left = maxf(_slow_left, seconds)


func set_talking(talking: bool) -> void:
	if talking:
		state = State.TALK
		attack = null
		buffer_age = -1
	elif state == State.TALK:
		state = State.NORMAL


# --- Tick -------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var inp := input_source.sample()
	last_input = inp
	tick += 1
	if state == State.DEAD:
		_dead_left -= delta
		velocity = Vector3.ZERO
		if _dead_left <= 0.0:
			_dead_left = 999.0
			died.emit()
		return
	if state == State.FROZEN:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			respawn_at(safe_position, facing)
			invuln_left = settings.invuln_time
			AudioDirector.play(&"poof")
			Fx.burst(get_parent(), global_position + Vector3.UP * 0.5, Palette.color(&"cloth_cream"), 10, 2.5, 0.14)
		return
	_update_lock(inp)
	# 1. Sample input. Presses during Plunge, hurt stun, dialogue and transitions are discarded.
	# The buffer ages before a new press is stored, and pauses in active ticks and hit-stop.
	if buffer_age >= 0 and hitstop_ticks <= 0 and not _buffer_paused():
		buffer_age += 1
	if inp.jump_pressed and _accepts_jump_press():
		buffer_age = 0
	if inp.attack_pressed and state in [State.NORMAL, State.ATTACK]:
		_attack_press_pending = true
		if state == State.ATTACK and attack.phase_at(attack_tick) != AttackDef.Phase.STARTUP:
			stored_attack_tick = tick
	if inp.plunge_pressed and state in [State.NORMAL, State.ATTACK]:
		_plunge_press_pending = true
	if inp.interact_pressed and state == State.NORMAL and is_grounded():
		_try_interact()
	# Local hit-stop: position, animation and timers pause; buffers pause rather than drain.
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	if state == State.TALK:
		velocity = Vector3(0.0, velocity.y - settings.gravity_down * delta, 0.0)
		move_and_slide()
		_update_visual(delta)
		return
	_movement_tick(delta, inp)
	_update_visual(delta)


func _movement_tick(delta: float, inp: PlayerInput) -> void:
	# 2. Read contact from last tick's move.
	if _ignore_floor_ticks > 0:
		_ignore_floor_ticks -= 1
	var grounded := is_grounded() or _step_hold > 0
	if grounded and not was_grounded:
		_on_landed()
	if not grounded and was_grounded and not _left_ground_by_launch:
		# Walked off: add the platform's horizontal push; this counts as a launch for the air slash.
		velocity += Vector3(_last_platform_velocity.x, 0.0, _last_platform_velocity.z)
		air_slash_ready = true
		_air_speed_cap = settings.run_speed
	if grounded:
		coyote_left = settings.coyote_time
		_last_platform_velocity = get_platform_velocity()
	# 3. Timers.
	if not grounded:
		coyote_left -= delta
	if invuln_left > 0.0:
		invuln_left -= delta
	if _slow_left > 0.0:
		_slow_left -= delta
	# 4. Airborne normalisation: never airborne without a usable jump.
	if not grounded and coyote_left <= 0.0 and jumps_used == 0:
		jumps_used = 1
	# Action states.
	_tick_actions(grounded)
	# 5. Resolve a buffered jump press.
	_resolve_jump(grounded)
	if inp.jump_released and _short_hop_ok and velocity.y > 0.0:
		velocity.y *= settings.short_hop_factor
		_short_hop_ok = false
	# 6. Gravity and horizontal movement, then move.
	_apply_gravity(delta, inp.jump_held)
	_apply_horizontal(delta, inp.move, is_grounded() or _step_hold > 0)
	if _step_hold > 0 or (is_grounded() and state in [State.NORMAL, State.ATTACK] and _try_step_up(delta)):
		_step_move()
	else:
		move_and_slide()
	# 7. Ceiling bonk: the jump stays spent and the buffer clears.
	if is_on_ceiling() and velocity.y > 0.0:
		velocity.y = 0.0
		buffer_age = -1
	was_grounded = grounded
	if grounded and tick % SAFE_GROUND_INTERVAL == 0:
		_sample_safe_ground()


func _accepts_jump_press() -> bool:
	return state in [State.NORMAL, State.ATTACK]


func _buffer_paused() -> bool:
	return state == State.ATTACK and attack.phase_at(attack_tick) == AttackDef.Phase.ACTIVE


func _allows_jump_now() -> bool:
	if state == State.NORMAL:
		return true
	if state == State.ATTACK:
		return attack.phase_at(attack_tick) != AttackDef.Phase.ACTIVE
	return false


func _on_landed() -> void:
	jumps_used = 0
	air_slash_ready = false
	_left_ground_by_launch = false
	_landed_at_tick = tick
	_speed_at_landing = Vector2(velocity.x, velocity.z).length()
	_flip_speed = 0.0
	_flip_angle = 0.0
	_squash = Vector3(1.3, 0.7, 1.3)
	_land_anim_left = 0.18
	if state == State.PLUNGE:
		state = State.PLUNGE_LAND
		plunge_land_left = settings.plunge_land_ticks
		Fx.ring(get_parent(), global_position + Vector3.UP * 0.1, Palette.color(&"cloth_cream"), 1.6)
		AudioDirector.play(&"plunge_land")
		if camera_rig != null and camera_rig.has_method(&"add_trauma"):
			camera_rig.call(&"add_trauma", 0.3)
	else:
		AudioDirector.play(&"land", -6.0)
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.05, Palette.color(&"stone_light"), 6, 1.6, 0.1, -2.0, 0.35)
	landed.emit()
	Telemetry.log_event("land", {"pos": global_position})


func _tick_actions(grounded: bool) -> void:
	match state:
		State.HURT:
			hurt_left -= 1
			if hurt_left <= 0:
				state = State.NORMAL
		State.PLUNGE_LAND:
			plunge_land_left -= 1
			if plunge_land_left <= 0:
				state = State.NORMAL
		State.PLUNGE:
			plunge_tick += 1
		State.ATTACK:
			_tick_attack(grounded)
	# New actions from pending presses.
	if _plunge_press_pending:
		_plunge_press_pending = false
		if not grounded and state in [State.NORMAL, State.ATTACK]:
			_start_plunge()
	if _attack_press_pending:
		_attack_press_pending = false
		if state == State.NORMAL:
			if grounded:
				_start_attack(ATTACK_SLASH_1)
			elif air_slash_ready:
				air_slash_ready = false
				_start_attack(ATTACK_AIR)


func _tick_attack(grounded: bool) -> void:
	attack_tick += 1
	var phase := attack.phase_at(attack_tick)
	if stored_attack_tick >= 0 and tick - stored_attack_tick > STORED_PRESS_TICKS:
		stored_attack_tick = -1
	if phase == AttackDef.Phase.RECOVERY and attack.next != null and stored_attack_tick >= 0 and grounded:
		var recovery_tick := attack_tick - attack.startup - attack.active
		if recovery_tick >= attack.combo_open:
			_start_attack(attack.next)
			return
	if phase == AttackDef.Phase.DONE:
		attack = null
		stored_attack_tick = -1
		state = State.NORMAL


func _start_attack(def: AttackDef) -> void:
	attack = def
	attack_tick = 0
	attack_id += 1
	stored_attack_tick = -1
	state = State.ATTACK
	# Slashes auto-turn up to 60° toward the lock target.
	if lock_target != null and is_instance_valid(lock_target):
		var to := lock_target.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			var ang := facing.signed_angle_to(to.normalized(), Vector3.UP)
			facing = facing.rotated(Vector3.UP, clampf(ang, -PI / 3.0, PI / 3.0))
	AudioDirector.play(def.sfx, -2.0)
	Telemetry.log_event("attack", {"kind": String(def.id)})


func _start_plunge() -> void:
	attack = null
	state = State.PLUNGE
	plunge_tick = 0
	attack_id += 1
	velocity = Vector3.ZERO
	buffer_age = -1
	AudioDirector.play(&"plunge")
	Telemetry.log_event("plunge", {"pos": global_position})


func _resolve_jump(grounded: bool) -> void:
	if not has_buffered_jump() or not _allows_jump_now():
		return
	if settings.mario_chain_mode:
		if jumps_used == 0 and (grounded or coyote_left > 0.0):
			var chained := tick - _landed_at_tick <= int(settings.chain_window * 60.0) and _speed_at_landing >= settings.chain_min_speed * settings.run_speed
			var index := (last_jump_index % 3) if chained else 0
			_start_jump(index, grounded)
			jumps_used = 3
		return
	if jumps_used == 0 and (grounded or coyote_left > 0.0):
		_start_jump(0, grounded)
	elif jumps_used >= 1 and jumps_used < 3 and not _prefer_ground_jump_holds():
		_start_jump(jumps_used, false)


## "Prefer ground jump" (Feel Lab): hold the press if the next 0.08 s of motion would touch floor.
func _prefer_ground_jump_holds() -> bool:
	if not settings.prefer_ground_jump or velocity.y > 0.0:
		return false
	var motion := velocity * settings.prefer_ground_lookahead
	motion.y -= 0.5 * settings.gravity_down * settings.prefer_ground_lookahead * settings.prefer_ground_lookahead
	var col := KinematicCollision3D.new()
	return test_move(global_transform, motion, col) and col.get_normal().y > cos(floor_max_angle)


func _start_jump(index: int, from_floor: bool) -> void:
	if state == State.ATTACK:
		attack = null
		state = State.NORMAL
		stored_attack_tick = -1
	if from_floor:
		var pv := get_platform_velocity()
		velocity += Vector3(pv.x, 0.0, pv.z)
	jumps_used = index + 1
	last_jump_index = index + 1
	buffer_age = -1
	coyote_left = 0.0
	velocity.y = settings.jump_velocity(index)
	air_slash_ready = true
	_short_hop_ok = index <= 1
	_left_ground_by_launch = true
	_ignore_floor_ticks = 1
	var h := Vector2(velocity.x, velocity.z)
	_air_speed_cap = maxf(settings.run_speed, h.length())
	if index == 2:
		var boost := facing * settings.j3_forward_boost
		velocity.x += boost.x
		velocity.z += boost.z
		_air_speed_cap = maxf(_air_speed_cap, settings.run_speed + settings.j3_forward_boost)
		_flip_speed = TAU / 0.42
		Fx.burst(get_parent(), global_position + Vector3.UP * 0.6, Palette.color(&"gold"), 14, 3.5, 0.09, -2.0, 0.5)
		if camera_rig != null and camera_rig.has_method(&"add_trauma"):
			camera_rig.call(&"add_trauma", 0.12)
	elif index == 1:
		Fx.ring(get_parent(), global_position + Vector3.UP * 0.2, Palette.color(&"portal_teal"), 1.3)
	else:
		Fx.burst(get_parent(), global_position + Vector3.UP * 0.05, Palette.color(&"stone_light"), 5, 1.4, 0.08, -2.0, 0.3)
	_squash = Vector3(0.78, 1.28, 0.78)
	AudioDirector.play(StringName("jump%d" % (index + 1)), -3.0)
	jumped.emit(index + 1)
	Telemetry.log_event("jump", {"n": index + 1, "pos": global_position})


func _apply_gravity(delta: float, jump_held: bool) -> void:
	if state == State.PLUNGE:
		if plunge_tick <= settings.plunge_hang_ticks:
			velocity = Vector3.ZERO
		elif plunge_tick == settings.plunge_hang_ticks + 1:
			velocity = Vector3(0.0, -settings.plunge_start_speed, 0.0)
		else:
			# Straight down, accelerating hard (Build 2 feedback).
			velocity = Vector3(0.0, maxf(velocity.y - settings.plunge_accel * delta, -settings.plunge_speed), 0.0)
		return
	if is_grounded() and velocity.y <= 0.0:
		velocity.y = -0.5
		return
	var g := settings.gravity_up if velocity.y > 0.0 else settings.gravity_down
	if absf(velocity.y) < settings.apex_threshold and jump_held:
		g *= settings.apex_gravity_scale
	velocity.y = maxf(velocity.y - g * delta, -settings.terminal_fall)
	# Air slash: vertical speed held at >= -1 m/s during the swing.
	if state == State.ATTACK and attack.is_air and attack.phase_at(attack_tick) != AttackDef.Phase.RECOVERY:
		velocity.y = maxf(velocity.y, -1.0)


func _move_basis() -> Basis:
	return Basis(Vector3.UP, camera_yaw)


func _apply_horizontal(delta: float, move: Vector2, grounded: bool) -> void:
	var h := Vector3(velocity.x, 0.0, velocity.z)
	if state == State.PLUNGE:
		return
	if state == State.HURT:
		if _knock_left > 0:
			_knock_left -= 1
			var step := _knock_velocity * delta
			if _knock_guarded and not _ledge_safe(global_position + step):
				_knock_velocity = Vector3.ZERO
			h = _knock_velocity
		else:
			h = h.move_toward(Vector3.ZERO, settings.run_speed / settings.decel_time * delta)
		velocity.x = h.x
		velocity.z = h.z
		return
	if state == State.PLUNGE_LAND:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var b := _move_basis()
	var dir := (b * Vector3(move.x, 0.0, -move.y))
	var tilt := clampf(move.length(), 0.0, 1.0)
	var top := settings.run_speed
	if _slow_left > 0.0:
		top *= 0.5
	var attacking := state == State.ATTACK
	if attacking and grounded:
		top *= settings.attack_move_scale
	var accel := settings.run_speed / settings.accel_time
	var decel := settings.run_speed / settings.decel_time
	if not grounded:
		accel *= settings.air_control
		decel *= settings.air_control
		top = maxf(top, _air_speed_cap) if tilt > 0.9 else top
	# Analog stick: under 50% tilt walks.
	var target := Vector3.ZERO
	if tilt > 0.05:
		target = dir.normalized() * (top if tilt >= settings.walk_tilt else top * settings.walk_speed_scale)
	var rate := accel if target.length() > 0.01 else decel
	if not grounded and target.length() <= 0.01:
		rate = accel * settings.air_drag
	# Skid when reversing hard at speed.
	_skidding = false
	if grounded and target.length() > 0.01 and h.length() > 0.7 * settings.run_speed:
		if rad_to_deg(h.angle_to(target)) > settings.skid_angle_deg:
			_skidding = true
			rate = decel
	h = h.move_toward(target, rate * delta)
	# Ground slash lunge during startup.
	if attacking and grounded and attack.lunge > 0.0 and attack.phase_at(attack_tick) == AttackDef.Phase.STARTUP:
		h = facing * (attack.lunge / (attack.startup / 60.0))
	velocity.x = h.x
	velocity.z = h.z
	# Facing turns toward input at the turn rate; locked on, it faces the target.
	var want := target
	if lock_target != null and is_instance_valid(lock_target) and not attacking:
		want = lock_target.global_position - global_position
		want.y = 0.0
	if want.length() > 0.01 and not attacking:
		var ang := facing.signed_angle_to(want.normalized(), Vector3.UP)
		var max_turn := deg_to_rad(settings.turn_rate_deg) * delta
		facing = facing.rotated(Vector3.UP, clampf(ang, -max_turn, max_turn)).normalized()


## Step-up (plan §3.3 rule 12): test up, then forward, then down. On success the body rises
## onto the step height and glides forward (no gravity, no snap) until it is over the step.
func _try_step_up(delta: float) -> bool:
	var h := Vector3(velocity.x, 0.0, velocity.z) * delta
	if h.length() < 0.0005:
		return false
	var col := KinematicCollision3D.new()
	if not test_move(global_transform, h, col):
		return false
	if col.get_normal().y > cos(floor_max_angle):
		return false
	var up := Vector3(0.0, settings.step_height + 0.02, 0.0)
	if test_move(global_transform, up):
		return false
	var raised := global_transform.translated(up)
	var fwd := h.normalized() * (STEP_PROBE + h.length())
	if test_move(raised, fwd):
		return false
	var down := KinematicCollision3D.new()
	if not test_move(raised.translated(fwd), Vector3(0.0, -settings.step_height - 0.05, 0.0), down):
		return false
	if down.get_normal().y < cos(floor_max_angle):
		return false
	var rise := settings.step_height + 0.02 - down.get_travel().length()
	if rise <= 0.01:
		return false
	global_position.y += rise + 0.02
	_step_hold = STEP_HOLD_TICKS
	return true


func _step_move() -> void:
	_step_hold -= 1
	velocity.y = 0.0
	var snap := floor_snap_length
	floor_snap_length = 0.0
	move_and_slide()
	floor_snap_length = snap
	var below := KinematicCollision3D.new()
	if test_move(global_transform, Vector3(0.0, -0.08, 0.0), below) and below.get_normal().y > cos(floor_max_angle):
		_step_hold = 0
		apply_floor_snap()


## Knockback ledge guard: a downward probe at the next position must find safe floor.
func _ledge_safe(next_pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(next_pos + Vector3.UP * 0.5, next_pos + Vector3.DOWN * 1.0, Layers.WORLD)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return false
	return not _point_in_hazard((hit["position"] as Vector3) + Vector3.DOWN * 0.2)


func _point_in_hazard(p: Vector3) -> bool:
	var pq := PhysicsPointQueryParameters3D.new()
	pq.position = p
	pq.collide_with_areas = true
	pq.collide_with_bodies = false
	pq.collision_mask = Layers.HAZARD
	return not get_world_3d().direct_space_state.intersect_point(pq, 1).is_empty()


## SafeGround recorder: still floor, at least 0.6 m of floor in every direction, no hazard.
func _sample_safe_ground() -> void:
	if get_platform_velocity().length() > 0.01 or state != State.NORMAL:
		return
	var floor_body := get_last_slide_collision()
	if floor_body != null and not floor_body.get_collider() is StaticBody3D:
		return
	var space := get_world_3d().direct_space_state
	for off: Vector3 in [Vector3(0.6, 0, 0), Vector3(-0.6, 0, 0), Vector3(0, 0, 0.6), Vector3(0, 0, -0.6)]:
		var from := global_position + off + Vector3.UP * 0.3
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 0.8, Layers.WORLD)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not hit["collider"] is StaticBody3D:
			return
	if _point_in_hazard(global_position + Vector3.DOWN * 0.3):
		return
	safe_position = global_position


func _die(cause: String) -> void:
	state = State.DEAD
	attack = null
	velocity = Vector3.ZERO
	_dead_left = 1.2
	AudioDirector.play(&"defeat")
	Telemetry.log_event("death", {"cause": cause, "pos": global_position})


# --- Lock-on and interaction ------------------------------------------------------------------

func _update_lock(inp: PlayerInput) -> void:
	if lock_target != null and (not is_instance_valid(lock_target) or not _lockable(lock_target)):
		lock_target = _best_target(null) if inp.lock_held else null
	if inp.lock_pressed:
		lock_target = _best_target(null)
		if lock_target == null and camera_rig != null and camera_rig.has_method(&"recenter"):
			camera_rig.call(&"recenter")
	elif inp.switch_target_pressed and lock_target != null:
		var next := _best_target(lock_target)
		if next != null:
			lock_target = next
	if not inp.lock_held:
		lock_target = null


func _lockable(n: Node3D) -> bool:
	return n.has_method(&"is_lockable") and bool(n.call(&"is_lockable"))


func _best_target(exclude: Node3D) -> Node3D:
	var view_fwd := _move_basis() * Vector3.FORWARD
	var best: Node3D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group(&"lockable"):
		var t := n as Node3D
		if t == null or t == exclude or not _lockable(t):
			continue
		var to := t.global_position - global_position
		var d := to.length()
		if d > LOCK_RANGE or d < 0.01:
			continue
		var flat := Vector3(to.x, 0.0, to.z).normalized()
		var ang := rad_to_deg(view_fwd.angle_to(flat))
		if ang > LOCK_CONE_DEG:
			continue
		var score := ang * 0.15 + d
		if score < best_score:
			best_score = score
			best = t
	return best


func _try_interact() -> void:
	var best: Node3D = null
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group(&"interactable"):
		var t := n as Node3D
		if t == null:
			continue
		var d := t.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = t
	if best != null and best.has_method(&"interact"):
		best.call(&"interact", self)


# --- Visuals (cosmetic only) ------------------------------------------------------------------

func _build_hurtbox() -> void:
	hurtbox = Area3D.new()
	hurtbox.collision_layer = Layers.PLAYER_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurt_shape = CapsuleShape3D.new()
	hurt_shape.radius = 0.38
	hurt_shape.height = 1.2
	var cs := CollisionShape3D.new()
	cs.shape = hurt_shape
	cs.position.y = 0.6
	hurtbox.add_child(cs)
	add_child(hurtbox)
	sword_shape = SphereShape3D.new()
	sword_shape.radius = 0.95
	plunge_shape = SphereShape3D.new()
	plunge_shape.radius = ATTACK_PLUNGE.radius


func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	body_pivot = Node3D.new()
	body_pivot.position.y = 0.6
	visual.add_child(body_pivot)
	# Hero: KayKit Rogue (CC0), restyled with a sprout, a longer sword and the toon look.
	hero = CharacterModel.create(HERO_PATH, HERO_SCALE, ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"], 0.035)
	hero.position.y = -0.6
	body_pivot.add_child(hero)
	var knife := hero.find_part("Knife")
	if knife != null:
		sword = (load(SWORD_PATH) as PackedScene).instantiate() as Node3D
		Toon.apply(sword, 0.03)
		sword.transform = knife.transform
		sword.scale = Vector3(1.0, SWORD_LENGTH_SCALE, 1.0)
		knife.get_parent().add_child(sword)
		_sword_rest = sword.transform
	var crown := hero.attach_on_top("head", "Rogue_Head")
	if crown != null:
		var leaf := SphereMesh.new()
		leaf.radius = 0.32
		leaf.height = 0.16
		var l1 := Kit.mesh_instance(crown, leaf, Kit.mat(&"grass_mid", 0.05), Vector3(0.12, 0.1, 0.0))
		l1.rotation.z = -0.7
		var l2 := Kit.mesh_instance(crown, leaf, Kit.mat(&"leaf_teal", 0.05), Vector3(-0.12, 0.08, 0.0))
		l2.rotation.z = 0.7
		var stem := CylinderMesh.new()
		stem.top_radius = 0.03
		stem.bottom_radius = 0.05
		stem.height = 0.25
		Kit.mesh_instance(crown, stem, Kit.mat(&"leaf_dark"), Vector3(0.0, -0.02, 0.0))
	hero.play(&"Idle")
	_sword_trail = SwordTrail.new()
	_sword_trail.blade = sword
	_sword_trail.base_local = Vector3(0.0, 0.25, 0.0)
	_sword_trail.tip_local = Vector3(0.0, 1.38, 0.0)
	_sword_trail.color = Color(Palette.color(&"foam"), 0.85)
	add_child(_sword_trail)
	# Lock-on marker (top level).
	var diamond := PrismMesh.new()
	diamond.size = Vector3(0.35, 0.4, 0.1)
	_lock_marker = MeshInstance3D.new()
	_lock_marker.mesh = diamond
	_lock_marker.material_override = Fx.fx_mat(Palette.color(&"gold"))
	_lock_marker.top_level = true
	_lock_marker.rotation.z = PI
	_lock_marker.visible = false
	_lock_marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_lock_marker)


func _build_plunge_streaks() -> void:
	_plunge_streaks = CPUParticles3D.new()
	_plunge_streaks.amount = 24
	_plunge_streaks.lifetime = 0.25
	_plunge_streaks.local_coords = false
	_plunge_streaks.emitting = false
	_plunge_streaks.direction = Vector3.UP
	_plunge_streaks.spread = 4.0
	_plunge_streaks.initial_velocity_min = 2.0
	_plunge_streaks.initial_velocity_max = 4.0
	_plunge_streaks.gravity = Vector3.ZERO
	_plunge_streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_plunge_streaks.emission_sphere_radius = 0.6
	var streak := BoxMesh.new()
	streak.size = Vector3(0.05, 0.9, 0.05)
	_plunge_streaks.mesh = streak
	_plunge_streaks.material_override = Fx.fx_mat(Color(Palette.color(&"foam"), 0.8))
	_plunge_streaks.position.y = 1.4
	add_child(_plunge_streaks)


## Plays a celebration (victory).
func cheer() -> void:
	_cheer_left = 2.4


func _build_landing_marker() -> void:
	landing_marker = Decal.new()
	landing_marker.top_level = true
	landing_marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.62, 0.72, 0.86, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	landing_marker.texture_albedo = tex
	landing_marker.modulate = Palette.color(&"gold")
	landing_marker.albedo_mix = 1.0
	landing_marker.emission_energy = 1.0
	landing_marker.size = Vector3(1.6, 2.0, 1.6)
	landing_marker.normal_fade = 0.5
	landing_marker.cull_mask = 1
	landing_marker.visible = false
	add_child(landing_marker)


## Where the hero will land if nothing changes: steps the current arc and raycasts each step.
func predict_landing() -> Variant:
	var pos := global_position + Vector3.UP * 0.1
	var vel := velocity
	var space := get_world_3d().direct_space_state
	var dt := 1.0 / 30.0
	for i in 120:
		if state == State.PLUNGE:
			vel = Vector3(0.0, minf(vel.y, -settings.plunge_start_speed), 0.0)
		else:
			var g := settings.gravity_up if vel.y > 0.0 else settings.gravity_down
			vel.y = maxf(vel.y - g * dt, -settings.terminal_fall)
		var next := pos + vel * dt
		var q := PhysicsRayQueryParameters3D.create(pos, next, Layers.WORLD)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and (hit["normal"] as Vector3).y > 0.5:
			return hit["position"]
		pos = next
	return null


func _build_shadow() -> void:
	shadow = Decal.new()
	shadow.top_level = true
	shadow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var g := Gradient.new()
	g.set_color(0, Color(Palette.INK, 0.6))
	g.set_color(1, Color(Palette.INK, 0.0))
	g.set_offset(0, 0.55)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	shadow.texture_albedo = tex
	shadow.size = Vector3(0.9, 1.6, 0.9)
	shadow.cull_mask = 1
	shadow.normal_fade = 0.5
	add_child(shadow)


func _process(delta: float) -> void:
	# Ground shadow: placed under the hero every frame, outside the squashing visual.
	var origin := get_global_transform_interpolated().origin
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.2, origin + Vector3.DOWN * 40.0, Layers.WORLD)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		shadow.visible = false
	else:
		shadow.visible = true
		var p: Vector3 = hit["position"]
		var height := origin.y - p.y
		var s := lerpf(0.95, 0.45, clampf(height / 8.0, 0.0, 1.0))
		shadow.global_position = p + Vector3.UP * 0.3
		shadow.size = Vector3(s, 1.6, s)
	# Landing marker: shows where the current arc meets the ground (Build 2 depth-perception aid).
	var airborne := not is_on_floor() and state not in [State.DEAD, State.FROZEN]
	landing_marker.visible = false
	if airborne:
		var land: Variant = predict_landing()
		if land != null:
			var lp := land as Vector3
			if origin.y - lp.y > 0.6:
				landing_marker.visible = true
				landing_marker.global_position = lp + Vector3.UP * 0.4
				var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.06
				landing_marker.size = Vector3(1.5 * pulse, 2.0, 1.5 * pulse)
	_plunge_streaks.emitting = state == State.PLUNGE and plunge_tick > settings.plunge_hang_ticks
	if lock_target != null and is_instance_valid(lock_target):
		_lock_marker.visible = true
		_lock_marker.global_position = lock_target.global_position + Vector3.UP * (2.2 + sin(Time.get_ticks_msec() * 0.008) * 0.12)
		_lock_marker.rotation.y += delta * 3.0
	else:
		_lock_marker.visible = false


func _update_visual(delta: float) -> void:
	visual.basis = Basis.looking_at(facing, Vector3.UP)
	_squash = _squash.lerp(Vector3.ONE, 1.0 - exp(-12.0 * delta))
	var grounded := is_grounded() or _step_hold > 0
	var h_speed := Vector2(velocity.x, velocity.z).length()
	body_pivot.scale = _squash
	# J3 forward flip and bounce spins (procedural, on top of the clip).
	if _flip_speed > 0.0 and not grounded:
		_flip_angle += _flip_speed * delta
		if _flip_angle >= TAU:
			_flip_angle = 0.0
			_flip_speed = 0.0
	else:
		_flip_angle = 0.0
	body_pivot.rotation = Vector3(-_flip_angle, 0.0, 0.0)
	if _skidding:
		body_pivot.rotation.x = 0.3
	# Hurtbox shrinks during the J3 tuck-flip.
	hurt_shape.height = 0.8 if _flip_speed > 0.0 else 1.2
	_land_anim_left = maxf(_land_anim_left - delta, 0.0)
	_cheer_left = maxf(_cheer_left - delta, 0.0)
	_sword_trail.emitting = state == State.ATTACK and attack != null and attack.phase_at(attack_tick) != AttackDef.Phase.STARTUP and attack.phase_at(attack_tick) != AttackDef.Phase.DONE and attack_tick < attack.startup + attack.active + 3
	if sword != null and state != State.PLUNGE:
		sword.transform = _sword_rest
	_animate(grounded, h_speed)
	# Footsteps while running.
	if grounded and h_speed > 2.0 and state == State.NORMAL:
		_step_timer -= delta * h_speed / 7.0
		if _step_timer <= 0.0:
			_step_timer = 0.32
			AudioDirector.play(&"step" if randf() < 0.5 else &"step2", -14.0)
	# Invulnerability blink.
	visual.visible = state != State.FROZEN and (invuln_left <= 0.0 or int(invuln_left * 20.0) % 2 == 0)


func _point_sword_down() -> void:
	if sword == null:
		return
	var sc := sword.global_basis.get_scale()
	var y := Vector3.DOWN
	var z := facing
	var x := y.cross(z).normalized()
	sword.global_basis = Basis(x * sc.x, y * sc.y, x.cross(y).normalized() * sc.z)


## Picks the hero clip from state. Attacks are retimed so the clip spans the attack's ticks.
func _animate(grounded: bool, h_speed: float) -> void:
	if hero == null:
		return
	match state:
		State.DEAD:
			hero.play(&"Death_A", 0.1)
			return
		State.HURT:
			hero.play(&"Hit_A", 0.05, 1.6)
			return
		State.TALK:
			hero.play(&"Idle", 0.2)
			return
		State.PLUNGE:
			# Downward plunge: tucked, sword held point-down under the hero.
			hero.play(&"1H_Melee_Attack_Stab", 0.05, 0.0 if plunge_tick > 3 else 1.0, plunge_tick <= 1)
			if plunge_tick > settings.plunge_hang_ticks:
				body_pivot.scale = Vector3(0.8, 1.22, 0.8)
			_point_sword_down()
			return
		State.PLUNGE_LAND:
			hero.play(&"Jump_Land", 0.05, 1.4)
			return
		State.ATTACK:
			if attack != null:
				var clip: StringName = ATTACK_CLIPS.get(attack.id, &"1H_Melee_Attack_Slice_Diagonal")
				var dur := attack.total() / 60.0
				hero.play(clip, 0.06, hero.clip_length(clip) / dur, attack_tick <= 1)
			return
	if _cheer_left > 0.0 and grounded and h_speed < 0.5:
		hero.play(&"Cheer", 0.2)
	elif not grounded:
		hero.play(&"Jump_Idle", 0.15)
	elif _land_anim_left > 0.0 and h_speed < 1.0:
		hero.play(&"Jump_Land", 0.05, 1.5)
	elif h_speed > settings.run_speed * settings.walk_speed_scale + 0.5:
		hero.play(&"Running_A", 0.15, clampf(h_speed / 8.0, 0.8, 1.7))
	elif h_speed > 0.4:
		hero.play(&"Walking_A", 0.15, clampf(h_speed / 3.0, 0.7, 1.5))
	else:
		hero.play(&"Idle", 0.2)
