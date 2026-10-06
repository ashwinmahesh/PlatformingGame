class_name Whirlwisp
extends Critter
## Build 7 roster (inspired by Dragon Quest's whirlwind spirits, our own design): a little tornado.
## Tell: it spins faster and kicks up a ring of dust for 0.8 s; then it becomes a vortex that drags
## you in. Afterwards it's dizzy and open. A Gravity Orb nearby breaks the vortex; Frost Burst
## freezes it; Spring Boots bound you clear.

enum S { WANDER, SPIN_UP, VORTEX, DIZZY }

const PULL_RADIUS := 8.0
var _spin: float = 0.0


func _init() -> void:
	model_spec = ["Hywirl", 1.6, PI]
	max_hp = 3
	body_radius = 0.7
	body_half_height = 0.8
	body_center = 0.9
	uses_gravity = false
	color_name = &"sky_top"


func build_body() -> void:
	ball(_visual, 0.7, &"foam", Vector3(0.0, 0.9, 0.0))


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state in [S.VORTEX, S.SPIN_UP]


func on_hit(atk: Dictionary) -> Dictionary:
	if state == S.VORTEX and StringName(str(atk.get("kind", ""))) not in [&"orb", &"frost", &"thunder", &"roar"]:
		AudioDirector.play(&"spin", -6.0, 2.0)
		return {"hit": true, "blocked": true}
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.WANDER:
			var drift := Vector3(sin(state_ticks * 0.013), 0.0, cos(state_ticks * 0.011)) * 2.0
			if flat_to(home).length() > 6.0:
				drift = flat_to(home).normalized() * 2.0
			velocity = drift + Vector3.UP * (home.y + 0.3 - global_position.y)
			if p != null and state_ticks > 80 and to.length() < 10.0:
				set_state(S.SPIN_UP)
		S.SPIN_UP:
			velocity = Vector3.ZERO
			if state_ticks % 8 == 0:
				Fx.ring(get_parent(), global_position + Vector3.UP * 0.1, Palette.color(&"sand_mid"), 2.0 + state_ticks * 0.06)
			if state_ticks >= 48:
				AudioDirector.play(&"spin", 0.0, 0.6)
				set_state(S.VORTEX)
		S.VORTEX:
			velocity = to.normalized() * 1.5 if to.length() > 1.0 else Vector3.ZERO
			if p != null and to.length() < PULL_RADIUS and p.dash_left <= 0:
				p.external_push = -to.normalized() * (3.5 * (1.0 - to.length() / PULL_RADIUS) + 1.0)
			for n in get_tree().get_nodes_in_group(&"gravity_orb"):
				if (n as Node3D).global_position.distance_to(global_position) < GravityOrb.PULL_RADIUS:
					set_state(S.DIZZY)
			if state_ticks >= 150:
				set_state(S.DIZZY)
		S.DIZZY:
			velocity = Vector3.ZERO
			if state_ticks % 15 == 0:
				Fx.burst(get_parent(), global_position + Vector3.UP * 2.0, Palette.color(&"gold"), 3, 1.0, 0.08, 0.0, 0.5)
			if state_ticks >= 110:
				set_state(S.WANDER)


func animate(delta: float) -> void:
	_spin += delta * (20.0 if state == S.VORTEX else (12.0 if state == S.SPIN_UP else 3.0))
	_visual.rotation.y = _spin
