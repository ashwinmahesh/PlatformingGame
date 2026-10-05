class_name Shroomlet
extends Critter
## A walking mushroom (inspired by Dragon Quest's Funghoul, our own design): shuffles about and
## puffs a spore cloud when you get close. Its springy cap is a bounce surface.

enum S { WANDER, WINDUP, PUFF, COOLDOWN }

var _cap: Node3D
var _feet: Array[MeshInstance3D] = []
var _step: float = 0.0


func _init() -> void:
	max_hp = 2
	body_radius = 0.65
	body_half_height = 0.7
	body_center = 0.75
	color_name = &"roof_red"


func build_body() -> void:
	var stem := CapsuleMesh.new()
	stem.radius = 0.42
	stem.height = 1.1
	Kit.mesh_instance(_visual, stem, flashy(&"cloth_cream", 0.03), Vector3(0.0, 0.6, 0.0))
	for side: float in [-1.0, 1.0]:
		ball(_visual, 0.08, &"bark_dark", Vector3(0.14 * side, 0.75, -0.38), 0.0)
		_feet.append(ball(_visual, 0.16, &"bark_light", Vector3(0.22 * side, 0.08, 0.0), 0.02))
	ball(_visual, 0.05, &"gloop_pink", Vector3(0.0, 0.6, -0.42), 0.0)
	_cap = Node3D.new()
	_cap.position.y = 1.2
	_visual.add_child(_cap)
	var dome := SphereMesh.new()
	dome.radius = 0.85
	dome.height = 0.85
	dome.is_hemisphere = true
	Kit.mesh_instance(_cap, dome, flashy(&"portal_magenta", 0.04), Vector3.ZERO)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		ball(_cap, 0.12, &"cloth_cream", Vector3(cos(a) * 0.5, 0.3, sin(a) * 0.5), 0.0)
	var area := Area3D.new()
	area.collision_layer = Layers.BOUNCE
	area.monitoring = false
	area.set_meta(&"actor", self)
	var c := CylinderShape3D.new()
	c.radius = 0.85
	c.height = 0.6
	Kit.add_shape(area, c, Vector3(0.0, 1.55, 0.0))
	add_child(area)


func state_name() -> String:
	return S.keys()[state]


## Landing on the cap bounces you (platforming use).
func on_player_land(_p: Player) -> float:
	_cap.scale = Vector3(1.3, 0.6, 1.3)
	create_tween().tween_property(_cap, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
	return 5.0


func think(_delta: float) -> void:
	var p := player_ref()
	match state:
		S.WANDER:
			var to_home := flat_to(home)
			var drift := Vector3(sin(state_ticks * 0.01), 0.0, cos(state_ticks * 0.013)) * 1.2
			if to_home.length() > 3.0:
				drift = to_home.normalized() * 1.2
			velocity.x = drift.x
			velocity.z = drift.z
			face(drift)
			if p != null and global_position.distance_to(p.global_position) < 5.5 and can_see(p, 6.0):
				set_state(S.WINDUP)
		S.WINDUP:
			velocity.x = 0.0
			velocity.z = 0.0
			flash(Color(1.0, 0.55, 0.1), 0.25 + 0.3 * absf(sin(state_ticks * 0.5)))
			if state_ticks >= 42:
				flash(Color.WHITE, 0.0)
				var cloud := SporeCloud.new()
				get_parent().add_child(cloud)
				cloud.global_position = global_position
				AudioDirector.play(&"poof", -2.0, 0.8)
				set_state(S.PUFF)
		S.PUFF:
			if state_ticks >= 20:
				set_state(S.COOLDOWN)
		S.COOLDOWN:
			if state_ticks >= 150:
				set_state(S.WANDER)


func animate(delta: float) -> void:
	_step += delta * Vector2(velocity.x, velocity.z).length() * 4.0
	for i in _feet.size():
		_feet[i].position.y = 0.08 + maxf(sin(_step + i * PI), 0.0) * 0.12
	var squash := 1.0
	if state == S.WINDUP:
		squash = 1.0 - float(state_ticks) / 42.0 * 0.3
	elif state == S.PUFF:
		squash = 1.2
	_visual.scale = Vector3(2.0 - squash, squash, 2.0 - squash)
