class_name Hexwizard
extends Critter
## Build 7 roster (inspired by Dragon Quest's magicians, our own design): a little wizard. Tell: it
## raises its staff and glows for 0.8 s, then sends three slow homing hex orbs. Hit it and it
## blinks away to another spot. A Fireball mid-cast fizzles the spell and stuns it; the Mighty
## Roar pins it (no blinking); a Star Rush shrugs off the orbs.

enum S { WAIT, CAST, SHOOT, BLINK }

var spots: Array[Vector3] = []


func _init() -> void:
	model_spec = ["Wizard", 1.5, PI]
	max_hp = 3
	body_radius = 0.6
	body_half_height = 0.75
	body_center = 0.8
	color_name = &"crystal_violet"
	drop_heart_chance = 0.5


func build_body() -> void:
	ball(_visual, 0.6, &"crystal_violet", Vector3(0.0, 0.8, 0.0))


func _ready() -> void:
	super._ready()
	if spots.is_empty():
		for i in 4:
			var a := float(i) / 4.0 * TAU
			spots.append(home + Vector3(cos(a) * 6.0, 0.0, sin(a) * 6.0))


func state_name() -> String:
	return S.keys()[state]


func on_hit(atk: Dictionary) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	if state == S.CAST and kind == &"fireball":
		flash(Color.WHITE, 0.0)
		stunned_ticks = 120
		AudioDirector.play(&"poof", 0.0, 1.4)
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	if hp > 0 and stunned_ticks <= 0 and frozen_ticks <= 0:
		set_state(S.BLINK)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	match state:
		S.WAIT:
			face(to)
			if p != null and state_ticks > 80 and to.length() < 16.0 and can_see(p, 16.0):
				set_state(S.CAST)
		S.CAST:
			face(to)
			flash(Color(0.7, 0.3, 1.0), 0.3 + 0.4 * float(state_ticks) / 48.0)
			if state_ticks >= 48:
				flash(Color.WHITE, 0.0)
				for k in 3:
					var shot := EnemyShot.new()
					shot.kind = EnemyShot.Kind.HEX
					shot.color_name = &"crystal_violet"
					get_parent().add_child(shot)
					shot.home_in(global_position + Vector3.UP * 1.4, facing.rotated(Vector3.UP, deg_to_rad(-30.0 + k * 30.0)) + Vector3.UP * 0.3)
				AudioDirector.play(&"fireball", -4.0, 1.5)
				set_state(S.SHOOT)
		S.SHOOT:
			if state_ticks >= 90:
				set_state(S.WAIT)
		S.BLINK:
			if state_ticks == 1:
				Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"crystal_violet"), 14, 3.0, 0.1)
				var best := spots[0]
				for sp in spots:
					if p == null or sp.distance_to(p.global_position) > best.distance_to(p.global_position):
						best = sp
				global_position = best
				AudioDirector.play(&"warp", -4.0, 1.4)
			if state_ticks >= 30:
				set_state(S.WAIT)
