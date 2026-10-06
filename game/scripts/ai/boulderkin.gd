class_name Boulderkin
extends Critter
## Build 6 roster: a lumbering heap of mossy rocks, 2.5x the hero, with a glowing crystal on its
## back. From range it heaves a boulder overhead and throws it (a ring marks where it lands;
## slash the boulder back at it to topple it). Up close it raises both fists and pounds out a
## ring of dust: jump or glide over it, or Air Dash through. Its stone front shrugs off hits;
## strike the crystal from behind, Plunge onto it, or topple it first.

enum S { IDLE, TURN, HEAVE, THROW, RAISE, POUND, RECOVER, TOPPLED }

const SIGHT := 22.0
const POUND_RANGE := 6.5
const TURN_RATE := 0.03

var stone: StringName = &"stone_dark"
var moss: StringName = &"moss"
var gem: StringName = &"portal_teal"
var _held: MeshInstance3D
var _fists: Array[Node3D] = []
var _crystal: MeshInstance3D
var _rock_body: Node3D
var _cool: int = 0


func _init() -> void:
	max_hp = 4
	body_radius = 1.5
	body_half_height = 1.9
	body_center = 2.0
	color_name = &"stone_light"
	contact_halves = 2
	drop_heart_chance = 1.0


func build_body() -> void:
	color_name = stone
	var limb := &"bark_dark" if stone == &"stone_dark" else &"stone_dark"
	_rock_body = Node3D.new()
	_visual.add_child(_rock_body)
	var hips := ball(_rock_body, 1.25, stone, Vector3(0.0, 1.5, 0.0), 0.05)
	hips.scale = Vector3(1.15, 0.9, 1.0)
	var chest := ball(_rock_body, 1.35, stone, Vector3(0.0, 2.9, 0.1), 0.05)
	chest.scale = Vector3(1.25, 0.85, 1.0)
	var head := ball(_rock_body, 0.7, stone, Vector3(0.0, 3.85, -0.45), 0.04)
	head.scale = Vector3(1.0, 0.8, 1.0)
	var cap := ball(_rock_body, 1.0, moss, Vector3(0.0, 3.75, 0.3), 0.02)
	cap.scale = Vector3(1.25, 0.45, 1.05)
	for side: float in [-1.0, 1.0]:
		ball(_rock_body, 0.13, &"gold", Vector3(0.25 * side, 3.95, -1.0), 0.0)
		var brow := ball(_rock_body, 0.22, limb, Vector3(0.28 * side, 4.12, -0.95), 0.0)
		brow.scale = Vector3(1.4, 0.45, 0.8)
		var leg := ball(_rock_body, 0.6, limb, Vector3(0.75 * side, 0.55, 0.0), 0.04)
		leg.scale = Vector3(1.0, 0.95, 1.1)
		var shoulder := Node3D.new()
		shoulder.position = Vector3(1.65 * side, 3.1, -0.1)
		_rock_body.add_child(shoulder)
		ball(shoulder, 0.5, stone, Vector3(0.0, -0.5, 0.0), 0.04)
		var fist := ball(shoulder, 0.75, limb, Vector3(0.0, -1.55, -0.15), 0.05)
		fist.scale = Vector3(1.0, 0.9, 1.1)
		_fists.append(shoulder)
	# The weak spot: a big teal crystal cluster on its back.
	var shard := PrismMesh.new()
	shard.size = Vector3(0.9, 1.6, 0.9)
	_crystal = Kit.mesh_instance(_rock_body, shard, flashy(gem, 0.03), Vector3(0.0, 3.2, 1.25))
	_crystal.rotation.x = 0.5
	for side: float in [-1.0, 1.0]:
		var small := Kit.mesh_instance(_rock_body, shard, flashy(gem, 0.02), Vector3(0.55 * side, 2.7, 1.2))
		small.scale = Vector3.ONE * 0.55
		small.rotation = Vector3(0.6, 0.0, -0.4 * side)
	var light := OmniLight3D.new()
	light.light_color = Palette.color(gem)
	light.omni_range = 4.0
	light.light_energy = 0.8
	light.position = Vector3(0.0, 3.2, 1.8)
	_rock_body.add_child(light)
	_held = ball(_rock_body, 0.8, limb, Vector3(0.0, 5.2, 0.0), 0.04)
	_held.visible = false


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state != S.TOPPLED


func _from_behind(from: Vector3) -> bool:
	var to_attacker := flat_to(from)
	return to_attacker.length() > 0.01 and rad_to_deg(facing.angle_to(to_attacker.normalized())) > 105.0


func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	var from := atk.get("from", global_position) as Vector3
	if Critter.shakes(kind) and state != S.TOPPLED:
		# Thunderclap rattles it: it drops whatever it's holding and staggers.
		_held.visible = false
		set_state(S.RECOVER)
		state_ticks = -40
		AudioDirector.play(&"boss_bonk", -4.0, 1.2)
		return {"hit": true, "blocked": true}
	if state == S.TOPPLED or kind == &"plunge" or _from_behind(from):
		take(int(atk.get("damage", 1)) + (1 if state == S.TOPPLED else 0), from)
		_crystal.scale = Vector3.ONE * 1.3
		create_tween().tween_property(_crystal, "scale", Vector3.ONE, 0.25)
		return {"hit": true}
	AudioDirector.play(&"hit", 0.0, 0.6)
	Fx.burst(get_parent(), global_position + Vector3.UP * 2.5 + facing * 1.3, Palette.color(stone), 6, 3.0, 0.12)
	return {"hit": true, "blocked": true}


## A thrown boulder slashed back at it knocks it flat, crystal up.
func hit_by_boulder() -> void:
	AudioDirector.play(&"boss_bonk")
	set_state(S.TOPPLED)


## Knockback from `take` would shove a 4 m rock heap about; it barely budges.
func take(dmg: int, from: Vector3) -> void:
	super.take(dmg, from)
	velocity = Vector3(0.0, velocity.y, 0.0)


func _turn_to(to: Vector3) -> void:
	if to.length() < 0.01:
		return
	var ang := facing.signed_angle_to(to.normalized(), Vector3.UP)
	facing = facing.rotated(Vector3.UP, clampf(ang, -TURN_RATE, TURN_RATE)).normalized()


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	_cool -= 1
	match state:
		S.IDLE:
			if p != null and can_see(p, SIGHT):
				set_state(S.TURN)
		S.TURN:
			# Lumbers round slowly, so a dash to its back works.
			_turn_to(to)
			var step := facing * 1.4 if to.length() > POUND_RANGE + 2.0 and flat_to(home).length() < 10.0 else Vector3.ZERO
			velocity.x = step.x
			velocity.z = step.z
			if p == null or to.length() > SIGHT + 6.0:
				set_state(S.IDLE)
			elif _cool <= 0 and to.length() < POUND_RANGE:
				set_state(S.RAISE)
			elif _cool <= 0 and state_ticks > 60 and to.length() > 8.0 and can_see(p, SIGHT):
				set_state(S.HEAVE)
		S.HEAVE:
			# Tell: rips a boulder from the ground and holds it overhead for 0.9 s.
			_turn_to(to)
			_held.visible = state_ticks > 10
			flash(Color(1.0, 0.55, 0.1), 0.2 * absf(sin(state_ticks * 0.4)))
			if state_ticks == 10:
				Fx.burst(get_parent(), global_position + facing * 1.5, Palette.color(&"bark_mid"), 10, 3.0, 0.15)
			if state_ticks >= 54:
				flash(Color.WHITE, 0.0)
				_held.visible = false
				var b := Boulder.new()
				b.thrower = self
				get_parent().add_child(b)
				b.launch(global_position + Vector3.UP * 5.2, p.global_position + p.velocity * Vector3(0.4, 0.0, 0.4), 1.15, 5.0)
				AudioDirector.play(&"spin", -2.0, 0.5)
				set_state(S.THROW)
		S.THROW:
			if state_ticks >= 20:
				_cool = 90
				set_state(S.RECOVER)
		S.RAISE:
			# Tell: both fists high, glowing, for 0.7 s.
			flash(Color(1.0, 0.55, 0.1), 0.3 + 0.3 * absf(sin(state_ticks * 0.6)))
			if state_ticks >= 42:
				flash(Color.WHITE, 0.0)
				var w := Shockwave.new()
				w.color_name = &"sand_mid"
				w.dash_dodges = true
				w.max_radius = 11.0
				get_parent().add_child(w)
				w.global_position = global_position + Vector3.UP * 0.05
				w.ground_y = global_position.y
				AudioDirector.play(&"boss_slam", -2.0, 1.2)
				Fx.burst(get_parent(), global_position + facing * 1.5, Palette.color(&"sand_mid"), 18, 5.0, 0.18)
				set_state(S.POUND)
		S.POUND:
			if state_ticks >= 18:
				_cool = 120
				set_state(S.RECOVER)
		S.RECOVER:
			if state_ticks >= 60:
				set_state(S.TURN)
		S.TOPPLED:
			if state_ticks % 15 == 0:
				Fx.burst(get_parent(), global_position + Vector3.UP * 2.5, Palette.color(&"gold"), 3, 1.5, 0.1, 0.0, 0.5)
			if state_ticks >= 180:
				_cool = 60
				set_state(S.TURN)


func animate(delta: float) -> void:
	var k := 1.0 - exp(-10.0 * delta)
	var arm := 0.0
	match state:
		S.HEAVE:
			arm = -2.6
		S.THROW:
			arm = 0.6
		S.RAISE:
			arm = -2.9
		S.POUND:
			arm = 0.9
		S.TURN:
			arm = sin(state_ticks * 0.08) * 0.3
	for f in _fists:
		f.rotation.x = lerpf(f.rotation.x, arm, k)
	_rock_body.rotation.x = lerpf(_rock_body.rotation.x, -1.2 if state == S.TOPPLED else 0.0, k * 0.6)
	_rock_body.position.y = lerpf(_rock_body.position.y, -0.6 if state == S.TOPPLED else 0.0, k * 0.6)
	_rock_body.position.y += sin(state_ticks * 0.16) * 0.03 if state == S.TURN else 0.0
	_crystal.rotation.y += delta * 0.8


func damage_to_player(p: Player) -> Dictionary:
	if state == S.TOPPLED:
		return {}
	return super.damage_to_player(p)
