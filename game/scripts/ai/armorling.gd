class_name Armorling
extends Critter
## An empty suit of armour (inspired by Dragon Quest's Restless Armour, our own design): its
## shield blocks sword hits from the front. Get behind it, or Plunge onto its helmet.

enum S { GUARD, WALK, WINDUP, SWING, RECOVER }

var _shield: Node3D
var _sword: Node3D


func _init() -> void:
	model_spec = ["Orc", 2.0, PI]
	max_hp = 3
	body_radius = 0.6
	body_half_height = 0.95
	body_center = 1.0
	color_name = &"stone_light"
	contact_halves = 1


func build_body() -> void:
	var torso := CapsuleMesh.new()
	torso.radius = 0.5
	torso.height = 1.4
	Kit.mesh_instance(_visual, torso, flashy(&"stone_light", 0.04), Vector3(0.0, 0.85, 0.0))
	ball(_visual, 0.45, &"stone_light", Vector3(0.0, 1.75, 0.0), 0.04)
	var visor := BoxMesh.new()
	visor.size = Vector3(0.5, 0.08, 0.1)
	Kit.mesh_instance(_visual, visor, Kit.mat(&"bark_dark"), Vector3(0.0, 1.78, -0.42))
	for side: float in [-1.0, 1.0]:
		ball(_visual, 0.06, &"portal_teal", Vector3(0.12 * side, 1.78, -0.47), 0.0)
		ball(_visual, 0.2, &"stone_dark", Vector3(0.22 * side, 0.12, -0.05), 0.02)
	var plume := SphereMesh.new()
	plume.radius = 0.18
	plume.height = 0.5
	Kit.mesh_instance(_visual, plume, Kit.mat(&"roof_red", 0.02), Vector3(0.0, 2.25, 0.05))
	_shield = Node3D.new()
	_shield.position = Vector3(-0.55, 1.0, -0.35)
	_visual.add_child(_shield)
	var sh := CylinderMesh.new()
	sh.top_radius = 0.55
	sh.bottom_radius = 0.55
	sh.height = 0.12
	var s := Kit.mesh_instance(_shield, sh, flashy(&"roof_blue", 0.03), Vector3.ZERO)
	s.rotation.x = PI * 0.5
	ball(_shield, 0.15, &"gold", Vector3(0.0, 0.0, -0.08), 0.0)
	_sword = Node3D.new()
	_sword.position = Vector3(0.6, 1.0, 0.0)
	_visual.add_child(_sword)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.1, 1.3, 0.06)
	Kit.mesh_instance(_sword, blade, Kit.mat(&"foam", 0.02), Vector3(0.0, 0.6, 0.0))


func state_name() -> String:
	return S.keys()[state]


## The shield blocks slashes from the front unless it's recovering from a swing.
func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	var plunge := kind == &"plunge" or kind == &"thunder"
	var from := atk.get("from", global_position) as Vector3
	var to_attacker := flat_to(from)
	var in_front := to_attacker.length() > 0.01 and rad_to_deg(facing.angle_to(to_attacker.normalized())) < 70.0
	if not plunge and in_front and state != S.RECOVER:
		AudioDirector.play(&"hit", 0.0, 1.8)
		Fx.burst(get_parent(), _shield.global_position, Palette.color(&"gold"), 6, 3.0, 0.08)
		_shield.scale = Vector3.ONE * 1.25
		create_tween().tween_property(_shield, "scale", Vector3.ONE, 0.2)
		return {"hit": true, "blocked": true}
	take(int(atk.get("damage", 1)) + (1 if plunge else 0), from)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.GUARD:
			velocity.x = 0.0
			velocity.z = 0.0
			if p != null and can_see(p, 12.0):
				set_state(S.WALK)
		S.WALK:
			# Turns slowly, so circling behind it works.
			var want := to.normalized()
			var ang := facing.signed_angle_to(want, Vector3.UP)
			facing = facing.rotated(Vector3.UP, clampf(ang, -0.035, 0.035)).normalized()
			velocity.x = facing.x * 2.4
			velocity.z = facing.z * 2.4
			if to.length() < 2.4:
				set_state(S.WINDUP)
			elif to.length() > 16.0 or flat_to(home).length() > 14.0:
				velocity = flat_to(home).normalized() * 2.4
				if flat_to(home).length() < 1.0:
					set_state(S.GUARD)
		S.WINDUP:
			velocity.x = 0.0
			velocity.z = 0.0
			_sword.rotation.z = lerpf(_sword.rotation.z, 1.6, 0.15)
			flash(Color(1.0, 0.55, 0.1), 0.25 + 0.25 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 42:
				flash(Color.WHITE, 0.0)
				AudioDirector.play(&"spin", -4.0, 0.8)
				set_state(S.SWING)
		S.SWING:
			_sword.rotation.z = lerpf(1.6, -1.6, clampf(state_ticks / 10.0, 0.0, 1.0))
			if state_ticks >= 12:
				set_state(S.RECOVER)
		S.RECOVER:
			_sword.rotation.z = lerpf(_sword.rotation.z, 0.0, 0.1)
			if state_ticks >= 70:
				set_state(S.WALK)


func damage_to_player(p: Player) -> Dictionary:
	if state == S.SWING:
		var to := p.global_position - global_position
		to.y = 0.0
		if to.length() < 2.6 and rad_to_deg(facing.angle_to(to.normalized())) < 80.0:
			return {"halves": 2, "from": global_position, "cause": "armorling_swing"}
	return super.damage_to_player(p)
