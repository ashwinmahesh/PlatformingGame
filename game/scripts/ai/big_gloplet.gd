class_name BigGloplet
extends Critter
## Build 6 roster: a Gloplet twice the size (Quaternius blob). It quivers and squashes low (the
## tell), then belly-flops onto the spot you stood on with a small splash ring. Pop it and it
## splits into two little Gloplets of the same colour. Thunderclap catches the whole family.

enum S { WOBBLE, SQUASH, FLOP, SPLAT }

const SIGHT := 14.0

## The small Gloplets it splits into (also sets its colour).
var split_def: EnemyDef = preload("res://data/enemies/gloplet.tres")
var _target: Vector3
var _squash: float = 1.0


func _init() -> void:
	max_hp = 3
	body_radius = 1.1
	body_half_height = 0.9
	body_center = 0.95
	contact_halves = 1
	drop_heart_chance = 0.5


func _ready() -> void:
	color_name = split_def.color
	model_spec = ["GreenBlob" if color_name == &"slime_green" else "PinkBlob", 2.0, PI]
	super._ready()
	if color_name != &"slime_green" and color_name != &"gloop_pink":
		for m in _flash_mats:
			m.set_shader_parameter(&"albedo_color", Palette.color(color_name).lerp(Color.WHITE, 0.25))


func build_body() -> void:
	ball(_visual, 1.1, color_name, Vector3(0.0, 0.95, 0.0))


func state_name() -> String:
	return S.keys()[state]


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.WOBBLE:
			var drift := flat_to(home)
			drift = drift.normalized() * 1.0 if drift.length() > 4.0 else Vector3.ZERO
			velocity.x = drift.x
			velocity.z = drift.z
			if p != null and state_ticks > 50 and can_see(p, SIGHT) and is_on_floor():
				set_state(S.SQUASH)
		S.SQUASH:
			velocity.x = 0.0
			velocity.z = 0.0
			face(to)
			flash(Color(1.0, 0.55, 0.1), 0.25 + 0.25 * absf(sin(state_ticks * 0.7)))
			if state_ticks >= 40:
				flash(Color.WHITE, 0.0)
				_target = p.global_position
				var d := flat_to(_target)
				if d.length() > 9.0:
					d = d.normalized() * 9.0
				# A 0.8 s arc to where you stood.
				velocity = Vector3(d.x / 0.8, 12.0, d.z / 0.8)
				AudioDirector.play(&"slime_hop", 0.0, 0.6)
				set_state(S.FLOP)
		S.FLOP:
			if state_ticks > 6 and is_on_floor():
				velocity = Vector3.ZERO
				var w := Shockwave.new()
				w.color_name = color_name
				w.max_radius = 4.5
				get_parent().add_child(w)
				w.global_position = global_position + Vector3.UP * 0.05
				w.ground_y = global_position.y
				AudioDirector.play(&"slime_land", 0.0, 0.6)
				_squash = 0.5
				set_state(S.SPLAT)
		S.SPLAT:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 70:
				set_state(S.WOBBLE)


func animate(delta: float) -> void:
	var target := 1.0 + sin(state_ticks * 0.15) * 0.05
	if state == S.SQUASH:
		target = 1.0 - float(state_ticks) / 40.0 * 0.35
	elif state == S.FLOP:
		target = 1.25
	_squash = lerpf(_squash, target, 1.0 - exp(-12.0 * delta))
	var w := 1.0 + (1.0 - _squash) * 0.5
	_visual.scale = Vector3(w, _squash, w)


func defeat() -> void:
	if _dead:
		return
	var parent := get_parent()
	var at := global_position
	super.defeat()
	for side: float in [-1.0, 1.0]:
		var g := Gloplet.new()
		g.setup(split_def, at + facing.cross(Vector3.UP) * 1.2 * side + Vector3.UP * 0.3, null, int(hash(at)) + int(side))
		parent.add_child.call_deferred(g)
