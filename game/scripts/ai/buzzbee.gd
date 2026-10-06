class_name Buzzbee
extends Critter
## Build 7 roster (inspired by Dragon Quest's armoured bees, our own design): an armoured bee.
## Tell: it hovers and buzzes louder, shaking, for 0.6 s; then it stings in a straight dive. Its
## armour turns the sword from the front; Fireball and Thunderclap go through it, and a Vinelash
## yank drags it down where you can slash it.

enum S { HOVER, BUZZ, STING, RETURN, DOWNED }

var _dir: Vector3 = Vector3.FORWARD


func _init() -> void:
	model_spec = ["Armabee", 1.2, PI]
	max_hp = 2
	body_radius = 0.6
	body_half_height = 0.5
	body_center = 0.6
	uses_gravity = false
	color_name = &"gold"


func build_body() -> void:
	ball(_visual, 0.6, &"gold", Vector3(0.0, 0.6, 0.0))


func state_name() -> String:
	return S.keys()[state]


func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	if kind == &"vine":
		set_state(S.DOWNED)
		uses_gravity = true
		return {"hit": true}
	var from := atk.get("from", global_position) as Vector3
	var to_attacker := flat_to(from)
	var front := to_attacker.length() > 0.01 and facing.angle_to(to_attacker.normalized()) < deg_to_rad(70.0)
	if front and state != S.DOWNED and not (kind == &"fireball" or Critter.shakes(kind) or kind == &"plunge"):
		AudioDirector.play(&"hit", 0.0, 2.0)
		return {"hit": true, "blocked": true}
	take(int(atk.get("damage", 1)), from)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := (p.global_position + Vector3.UP * 0.6 - global_position) if p != null else Vector3.ZERO
	match state:
		S.HOVER:
			velocity = (home + Vector3(sin(state_ticks * 0.05), sin(state_ticks * 0.11) * 0.4, cos(state_ticks * 0.04)) - global_position) * 2.0
			face(Vector3(to.x, 0.0, to.z))
			if p != null and state_ticks > 70 and to.length() < 11.0 and can_see(p, 12.0):
				set_state(S.BUZZ)
		S.BUZZ:
			velocity = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
			face(Vector3(to.x, 0.0, to.z))
			flash(Color(1.0, 0.85, 0.2), 0.25 + 0.25 * absf(sin(state_ticks * 1.2)))
			if state_ticks >= 36:
				flash(Color.WHITE, 0.0)
				_dir = to.normalized()
				AudioDirector.play(&"dash", -4.0, 1.6)
				set_state(S.STING)
		S.STING:
			velocity = _dir * 15.0
			if state_ticks >= 32 or get_slide_collision_count() > 0:
				set_state(S.RETURN)
		S.RETURN:
			var back := home - global_position
			velocity = back.normalized() * minf(6.0, back.length() * 3.0)
			if back.length() < 0.6:
				set_state(S.HOVER)
		S.DOWNED:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 150:
				uses_gravity = false
				set_state(S.RETURN)
