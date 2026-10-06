class_name Wispghost
extends Critter
## Build 7 roster (inspired by Dragon Quest's ghosts, our own design): a giggling ghost that drifts
## half-seen through walls. Tell: it turns solid and flickers purple before it lunges. Only solid,
## it can be hit. A Fireball lights it up (solid and dizzy); Thunderclap or a Roar stuns it.

enum S { DRIFT, WINDUP, LUNGE, TIRED, LIT }

const SIGHT := 12.0


func _init() -> void:
	model_spec = ["Ghost", 1.6, PI]
	max_hp = 2
	body_radius = 0.6
	body_half_height = 0.7
	body_center = 1.2
	uses_gravity = false
	color_name = &"crystal_violet"
	drop_heart_chance = 0.3


func build_body() -> void:
	ball(_visual, 0.6, &"foam", Vector3(0.0, 1.2, 0.0))


func state_name() -> String:
	return S.keys()[state]


func _solid() -> bool:
	return state != S.DRIFT


func harmful() -> bool:
	return state == S.LUNGE


func is_lockable() -> bool:
	return _solid() and super.is_lockable()


func on_hit(atk: Dictionary) -> Dictionary:
	if not _solid():
		if StringName(str(atk.get("kind", ""))) == &"fireball":
			set_state(S.LIT)
			return {"hit": true}
		return {}
	if StringName(str(atk.get("kind", ""))) == &"fireball":
		set_state(S.LIT)
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := (p.global_position + Vector3.UP * 0.8 - global_position) if p != null else Vector3.ZERO
	collision_mask = Layers.WORLD if _solid() else 0
	match state:
		S.DRIFT:
			var bob := Vector3(sin(state_ticks * 0.02) * 3.0, 1.0 + sin(state_ticks * 0.05) * 0.5, cos(state_ticks * 0.017) * 3.0)
			velocity = (home + bob - global_position) * 1.5
			if p != null and state_ticks > 90 and to.length() < SIGHT:
				set_state(S.WINDUP)
		S.WINDUP:
			velocity = Vector3.ZERO
			face(to)
			flash(Color(0.8, 0.3, 1.0), 0.3 + 0.3 * absf(sin(state_ticks * 0.7)))
			if state_ticks >= 40:
				flash(Color.WHITE, 0.0)
				velocity = to.normalized() * 11.0
				AudioDirector.play(&"spin", -6.0, 1.8)
				set_state(S.LUNGE)
		S.LUNGE:
			if state_ticks >= 28 or get_slide_collision_count() > 0:
				set_state(S.TIRED)
		S.TIRED:
			velocity = velocity.lerp(Vector3.ZERO, 0.1)
			if state_ticks >= 80:
				set_state(S.DRIFT)
		S.LIT:
			velocity = velocity.lerp(Vector3.DOWN * 1.0, 0.1)
			if state_ticks % 15 == 0:
				Fx.burst(get_parent(), global_position + Vector3.UP * 1.6, Palette.color(&"gold"), 3, 1.0, 0.08, 0.0, 0.5)
			if state_ticks >= 160:
				set_state(S.DRIFT)


func animate(_delta: float) -> void:
	if _model == null:
		return
	var fade := 0.65 if state == S.DRIFT else 0.0
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.transparency = lerpf(mi.transparency, fade, 0.15)
