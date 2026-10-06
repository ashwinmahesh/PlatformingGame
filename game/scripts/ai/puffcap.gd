class_name Puffcap
extends Critter
## Build 6 roster: a walking mushroom (Quaternius Mushnub). From range it swells its cap and lobs
## a spore ball (a ring marks where it lands). Come close and it ducks under its cap: sword hits
## bounce off, but the cap is a trampoline. Fireball scorches the cap off its guard and
## Thunderclap shakes it out; a Plunge onto the cap bounces you high.

enum S { WANDER, WINDUP, LOB, DUCK, SCORCHED, COOLDOWN }

const SIGHT := 14.0
const DUCK_RANGE := 3.0
const BOUNCE := 7.0

var _cap_area: Area3D
var _cap_y: float = 1.55
var _squash: float = 1.0


func _init() -> void:
	model_spec = ["Mushnub", 1.6, PI]
	max_hp = 2
	body_radius = 0.65
	body_half_height = 0.75
	body_center = 0.8
	color_name = &"roof_red"
	drop_heart_chance = 0.3


func build_body() -> void:
	ball(_visual, 0.7, &"roof_red", Vector3(0.0, 0.8, 0.0))
	_cap_area = Area3D.new()
	_cap_area.collision_layer = Layers.BOUNCE
	_cap_area.monitoring = false
	_cap_area.set_meta(&"actor", self)
	var c := CylinderShape3D.new()
	c.radius = 0.95
	c.height = 0.6
	Kit.add_shape(_cap_area, c)
	_cap_area.position.y = _cap_y
	add_child(_cap_area)


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state != S.SCORCHED


## Landing on the cap always bounces you (it's the Puffcap's trampoline).
func on_player_land(_p: Player) -> float:
	_squash = 0.55
	AudioDirector.play(&"slime_hop", -4.0, 1.3)
	return BOUNCE


func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	if state == S.DUCK:
		if kind == &"fireball" or Critter.shakes(kind):
			Fx.burst(get_parent(), global_position + Vector3.UP * 1.2, Palette.color(&"gold" if kind == &"fireball" else &"portal_teal"), 12, 3.0, 0.1)
			set_state(S.SCORCHED)
			take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
			return {"hit": true}
		if kind == &"plunge":
			return {"hit": true, "bounce": BOUNCE}
		AudioDirector.play(&"slime_hop", 0.0, 0.7)
		_squash = 0.7
		return {"hit": true, "blocked": true}
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	if state != S.SCORCHED and hp > 0:
		set_state(S.DUCK)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.WANDER:
			var to_home := flat_to(home)
			var drift := Vector3(sin(state_ticks * 0.01), 0.0, cos(state_ticks * 0.013)) * 1.2
			if to_home.length() > 3.0:
				drift = to_home.normalized() * 1.2
			velocity.x = drift.x
			velocity.z = drift.z
			face(drift)
			if p != null and to.length() < DUCK_RANGE:
				set_state(S.DUCK)
			elif p != null and state_ticks > 30 and can_see(p, SIGHT):
				set_state(S.WINDUP)
		S.WINDUP:
			# Tell: the cap swells and glows for 0.6 s before the lob.
			velocity.x = 0.0
			velocity.z = 0.0
			face(to)
			flash(Color(1.0, 0.55, 0.1), 0.25 + 0.3 * absf(sin(state_ticks * 0.5)))
			_squash = 1.0 + float(state_ticks) / 36.0 * 0.3
			if p != null and to.length() < DUCK_RANGE:
				flash(Color.WHITE, 0.0)
				set_state(S.DUCK)
			elif state_ticks >= 36:
				flash(Color.WHITE, 0.0)
				var shot := EnemyShot.new()
				shot.color_name = &"portal_magenta"
				get_parent().add_child(shot)
				shot.lob(global_position + Vector3.UP * 1.8, p.global_position + Vector3(0.0, 0.05, 0.0), 1.0, 3.5)
				AudioDirector.play(&"poof", -2.0, 0.8)
				set_state(S.LOB)
		S.LOB:
			if state_ticks >= 16:
				set_state(S.COOLDOWN)
		S.DUCK:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 90 and (p == null or to.length() > DUCK_RANGE + 1.0):
				set_state(S.COOLDOWN)
		S.SCORCHED:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 120:
				set_state(S.COOLDOWN)
		S.COOLDOWN:
			if p != null and to.length() < DUCK_RANGE:
				set_state(S.DUCK)
			elif state_ticks >= 110:
				set_state(S.WANDER)


func animate(delta: float) -> void:
	var target := 1.0
	match state:
		S.DUCK:
			target = 0.5
		S.SCORCHED:
			target = 0.8
		S.LOB:
			target = 1.2
	if state != S.WINDUP:
		_squash = lerpf(_squash, target, 1.0 - exp(-10.0 * delta))
	_visual.scale = Vector3(1.0 + (1.0 - _squash) * 0.4, _squash, 1.0 + (1.0 - _squash) * 0.4)
	_cap_area.position.y = _cap_y * _squash
	if state == S.SCORCHED:
		if state_ticks % 20 == 0:
			Fx.burst(get_parent(), global_position + Vector3.UP * 1.3, Palette.color(&"bark_dark"), 3, 1.0, 0.08, 1.0, 0.6)
