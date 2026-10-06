class_name Wyrmling
extends Critter
## Build 7 roster (inspired by Dragon Quest's baby dragons, our own design): a little dragon that
## circles overhead. Tell: it rears back and its throat glows for 0.75 s, then a cone of fire.
## Frost Burst freezes it and it drops; the Vinelash yanks it to the ground; a Gravity Orb drags it.

enum S { CIRCLE, INHALE, BREATH, GROUNDED }

const SIGHT := 14.0
var _flame: MeshInstance3D


func _init() -> void:
	model_spec = ["Dragon", 1.8, PI]
	max_hp = 3
	body_radius = 0.8
	body_half_height = 0.7
	body_center = 0.9
	uses_gravity = false
	color_name = &"roof_red"
	drop_heart_chance = 0.4


func build_body() -> void:
	ball(_visual, 0.8, &"roof_red", Vector3(0.0, 0.9, 0.0))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.2
	cone.bottom_radius = 2.4
	cone.height = 6.0
	_flame = Kit.mesh_instance(self, cone, Fx.fx_mat(Color(Palette.color(&"sunset_orange") * 1.4, 0.55)), Vector3.ZERO)
	_flame.visible = false


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state != S.GROUNDED


func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	if kind == &"vine" and state != S.GROUNDED:
		set_state(S.GROUNDED)
		uses_gravity = true
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func _freeze(ticks: int) -> void:
	super._freeze(ticks)
	set_state(S.GROUNDED)
	uses_gravity = true


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.CIRCLE:
			var a := state_ticks * 0.015
			var target := home + Vector3(cos(a) * 6.0, 4.0, sin(a) * 6.0)
			velocity = (target - global_position) * 1.2
			face(velocity)
			if p != null and state_ticks > 120 and to.length() < SIGHT and can_see(p, SIGHT + 4.0):
				set_state(S.INHALE)
		S.INHALE:
			velocity = velocity.lerp(Vector3.ZERO, 0.15)
			face(to)
			flash(Color(1.0, 0.5, 0.1), 0.3 + 0.4 * float(state_ticks) / 45.0)
			if state_ticks >= 45:
				flash(Color.WHITE, 0.0)
				AudioDirector.play(&"fireball", 0.0, 0.6)
				set_state(S.BREATH)
		S.BREATH:
			velocity = Vector3.ZERO
			if state_ticks >= 40:
				set_state(S.CIRCLE)
		S.GROUNDED:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 180:
				uses_gravity = false
				set_state(S.CIRCLE)


func animate(_delta: float) -> void:
	_flame.visible = state == S.BREATH
	if _flame.visible:
		var dir := (facing + Vector3.DOWN * 0.5).normalized()
		_flame.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), global_position + Vector3.UP * 0.9 + dir * 3.2)


func damage_to_player(p: Player) -> Dictionary:
	if state == S.BREATH and frozen_ticks <= 0:
		var d := p.global_position + Vector3.UP * 0.6 - (global_position + Vector3.UP * 0.9)
		var dir := (facing + Vector3.DOWN * 0.5).normalized()
		if d.length() < 7.0 and d.normalized().dot(dir) > 0.8:
			return {"halves": 2, "from": global_position, "cause": "wyrmling_fire"}
	return super.damage_to_player(p)
