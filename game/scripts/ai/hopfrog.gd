class_name Hopfrog
extends Critter
## Build 7 roster (inspired by Dragon Quest's frogs, our own design): a big frog. Tell: its throat
## puffs up for 0.7 s; then its tongue lashes out 7 m in a straight line. After a lash it pants,
## open from every side. Air Dash slips the tongue; a Vinelash outreaches it and stuns it; a Star
## Rush bowls it over.

enum S { HOP, PUFF, LASH, PANT }

const REACH := 7.0
var _aim: Vector3 = Vector3.FORWARD
var _tongue: MeshInstance3D


func _init() -> void:
	model_spec = ["Frog", 1.3, PI]
	max_hp = 3
	body_radius = 0.7
	body_half_height = 0.6
	body_center = 0.65
	color_name = &"leaf_teal"


func build_body() -> void:
	ball(_visual, 0.7, &"leaf_teal", Vector3(0.0, 0.65, 0.0))
	_tongue = Kit.mesh_instance(self, BoxMesh.new(), Kit.mat(&"candy_pink"))
	(_tongue.mesh as BoxMesh).size = Vector3(0.25, 0.25, 1.0)
	_tongue.visible = false


func state_name() -> String:
	return S.keys()[state]


func on_hit(atk: Dictionary) -> Dictionary:
	if StringName(str(atk.get("kind", ""))) == &"vine" and state in [S.PUFF, S.LASH]:
		set_state(S.PANT)
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func think(_delta: float) -> void:
	var p := player_ref()
	var to := flat_to(p.global_position) if p != null else Vector3.ZERO
	match state:
		S.HOP:
			if is_on_floor() and state_ticks % 50 == 49:
				var dir := (flat_to(home).normalized() if flat_to(home).length() > 6.0 else Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized())
				velocity = dir * 4.0 + Vector3.UP * 6.0
				face(dir)
			elif is_on_floor():
				velocity.x = 0.0
				velocity.z = 0.0
			if p != null and is_on_floor() and state_ticks > 40 and to.length() < REACH + 1.0 and can_see(p, REACH + 2.0):
				set_state(S.PUFF)
		S.PUFF:
			velocity.x = 0.0
			velocity.z = 0.0
			face(to)
			_aim = facing
			flash(Color(1.0, 0.55, 0.1), 0.2 + 0.3 * float(state_ticks) / 42.0)
			if state_ticks >= 42:
				flash(Color.WHITE, 0.0)
				AudioDirector.play(&"slash", -2.0, 0.6)
				set_state(S.LASH)
		S.LASH:
			if state_ticks >= 14:
				set_state(S.PANT)
		S.PANT:
			if state_ticks >= 70:
				set_state(S.HOP)


func animate(_delta: float) -> void:
	var out := state == S.LASH
	_tongue.visible = out
	if out:
		var len := REACH * clampf(state_ticks / 5.0, 0.0, 1.0)
		_tongue.global_transform = Transform3D(Basis.looking_at(_aim, Vector3.UP) * Basis.from_scale(Vector3(1.0, 1.0, len)), global_position + Vector3.UP * 0.7 + _aim * len * 0.5)
	if _visual != null:
		var puff := 1.0 + (0.25 * float(state_ticks) / 42.0 if state == S.PUFF else 0.0)
		_visual.scale = Vector3(puff, 1.0, puff)


func damage_to_player(p: Player) -> Dictionary:
	if state == S.LASH and p.dash_left <= 0 and p.rush_left <= 0:
		var rel := p.global_position + Vector3.UP * 0.6 - (global_position + Vector3.UP * 0.7)
		var along := rel.dot(_aim)
		if along > 0.0 and along < REACH and (rel - _aim * along).length() < 0.8:
			return {"halves": 2, "from": global_position, "cause": "hopfrog_tongue"}
	return super.damage_to_player(p)
