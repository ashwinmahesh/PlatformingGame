class_name Mimic
extends Critter
## A treasure chest that bites (inspired by Dragon Quest's Mimic, our own design). It looks
## exactly like a real chest until you come close or try to open it.

enum S { DORMANT, REVEAL, CHASE, WINDUP, BITE, RECOVER }

var _lid: Node3D
var _teeth: Node3D


func _init() -> void:
	max_hp = 3
	body_radius = 0.8
	body_half_height = 0.6
	body_center = 0.6
	color_name = &"wood_warm"
	contact_halves = 1
	drop_heart_chance = 1.0


func build_body() -> void:
	add_to_group(&"interactable")
	ChestLook.build(_visual)
	_lid = _visual.get_node("Lid") as Node3D
	_teeth = Node3D.new()
	_teeth.visible = false
	_visual.add_child(_teeth)
	for i in 6:
		var tooth := CylinderMesh.new()
		tooth.top_radius = 0.0
		tooth.bottom_radius = 0.09
		tooth.height = 0.22
		var t := Kit.mesh_instance(_teeth, tooth, Kit.mat(&"foam"), Vector3(-0.6 + i * 0.24, 0.9, -0.42))
		t.rotation.x = PI
	var tongue := SphereMesh.new()
	tongue.radius = 0.3
	tongue.height = 0.2
	Kit.mesh_instance(_teeth, tongue, Kit.mat(&"gloop_pink"), Vector3(0.0, 0.82, -0.1))
	for side: float in [-1.0, 1.0]:
		ball(_teeth, 0.1, &"gold", Vector3(0.3 * side, 1.25, -0.2), 0.0)
	for n in _visual.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.material_override is ShaderMaterial and not mi.material_override in _flash_mats:
			var m := (mi.material_override as ShaderMaterial).duplicate() as ShaderMaterial
			mi.material_override = m
			_flash_mats.append(m)


func state_name() -> String:
	return S.keys()[state]


func harmful() -> bool:
	return state in [S.CHASE, S.BITE]


func is_lockable() -> bool:
	return state != S.DORMANT and super.is_lockable()


## Trying to open it wakes it up.
func interact(_p: Player) -> void:
	if state == S.DORMANT:
		_reveal()


func on_hit(atk: Dictionary) -> Dictionary:
	if state == S.DORMANT:
		_reveal()
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


func _reveal() -> void:
	remove_from_group(&"interactable")
	set_state(S.REVEAL)
	AudioDirector.play(&"boss_roar", -6.0, 2.2)


func think(_delta: float) -> void:
	var p := player_ref()
	match state:
		S.DORMANT:
			velocity.x = 0.0
			velocity.z = 0.0
			if p != null and global_position.distance_to(p.global_position) < 2.6:
				_reveal()
		S.REVEAL:
			if state_ticks >= 24:
				set_state(S.CHASE)
		S.CHASE:
			var to := flat_to(p.global_position)
			face(to)
			if is_on_floor() and state_ticks % 24 == 0:
				velocity = to.normalized() * minf(5.0, to.length() * 2.0) + Vector3.UP * 4.5
			if to.length() < 2.4 and is_on_floor():
				set_state(S.WINDUP)
		S.WINDUP:
			velocity.x = 0.0
			velocity.z = 0.0
			flash(Color(1.0, 0.55, 0.1), 0.3 + 0.3 * absf(sin(state_ticks * 0.6)))
			if state_ticks >= 24:
				flash(Color.WHITE, 0.0)
				velocity = facing * 8.0 + Vector3.UP * 3.5
				AudioDirector.play(&"slime_hop", 0.0, 0.6)
				set_state(S.BITE)
		S.BITE:
			if state_ticks > 4 and is_on_floor():
				set_state(S.RECOVER)
		S.RECOVER:
			velocity.x = 0.0
			velocity.z = 0.0
			if state_ticks >= 50:
				set_state(S.CHASE)


func animate(_delta: float) -> void:
	var open := state != S.DORMANT
	_teeth.visible = open
	var target := -0.9 if state in [S.CHASE, S.RECOVER] else (-1.5 if state in [S.REVEAL, S.WINDUP] else (-0.2 if state == S.BITE else 0.0))
	if state == S.CHASE:
		target = -0.5 - absf(sin(state_ticks * 0.25)) * 0.6
	_lid.rotation.x = lerpf(_lid.rotation.x, target, 0.3)
