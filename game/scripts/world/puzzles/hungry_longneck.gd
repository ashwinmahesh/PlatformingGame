class_name HungryLongneck
extends Node3D
## Build 9 puzzle (Dinodew Jungle; creatures that react to the hero): Mossback, a giant gentle
## long-neck so old that moss carpets her back, her neck and her lowered tail. Her tail lies
## down to the ground behind her: walk up it. While she's hungry she holds her head high,
## looking for breakfast (the neck is far too steep to walk). Knock a melon off the big cycad
## (sword or Fireball) and it rolls into her trough: she bends down, munches, then rests her chin
## on the cliff top, and her neck is a mossy bridge up to the heights.
## The node's +Z is the way she faces; local y 0 is the ground she stands on.

signal fed

enum S { HUNGRY, EATING, RESTING }

const SCALE := 1.1
const HUNGRY_PITCH := -32.0
const EAT_PITCH := 26.0
const REST_PITCH := -4.0
const TAIL_DROP_DEG := Vector2(12.0, 20.0)
const NECK_CHAIN: Array[String] = ["Shoulders", "Neck", "Head"]
const TAIL_CHAIN: Array[String] = ["Tail1", "Tail2", "Tail3", "Tail4", "Tail5"]

var state: S = S.HUNGRY
var dino: Dino
## The trough she eats from (this node's frame) and the head carpet (where a seed can ride).
var trough_at: Vector3
var head_piece: AnimatableBody3D
## Where her tail tip's carpet ends (this node's frame): the mounting stone goes under it.
var tail_foot: Vector3
var _t: float = 0.0
var _pitch: float = HUNGRY_PITCH
var _melons: Array[Area3D] = []
var _in_trough: Node3D


func _ready() -> void:
	dino = Dino.new()
	dino.species = &"longneck"
	dino.model_scale = SCALE
	dino.clip = &""
	dino.colours = {"Brown": &"mush_teal", "Material": &"cloth_cream"}
	var posed: Array[String] = []
	posed.append_array(NECK_CHAIN)
	posed.append_array(TAIL_CHAIN)
	dino.posed_bones = posed
	add_child(dino)
	# The tail lies down behind her as a ramp: gently off her rump, then steadier to the ground.
	var near := deg_to_rad(TAIL_DROP_DEG.x)
	var far := deg_to_rad(TAIL_DROP_DEG.y)
	dino.aim_chain(["Tail1", "Tail2"], Vector3(0.0, -sin(near), -cos(near)))
	dino.aim_chain(["Tail3", "Tail4", "Tail5"], Vector3(0.0, -sin(far), -cos(far)))
	# Carpets are laid at the resting pose, so the bridge she makes is exactly them.
	dino.bend_pitch("Shoulders", REST_PITCH)
	dino.tick(0.0)
	var skin := dino.skin_points()
	dino.ridge_carpets(3.5, -2.0, 2.2, 3.2, ["Hips", "Torso", "Shoulders"], &"moss", &"moss", 0.35, skin)
	var tail: Array[String] = ["Back"]
	tail.append_array(TAIL_CHAIN)
	var tail_pieces := dino.ridge_carpets_at([-2.0, -7.0, -9.5, -12.0, -14.5, -17.0, -19.5, -22.0, -24.5, -27.0, -29.0], 2.0, tail, &"moss", &"moss", 0.35, skin)
	var last := tail_pieces[tail_pieces.size() - 1]
	var half := ((last.get_child(0) as CollisionShape3D).shape as BoxShape3D).size * 0.5
	tail_foot = to_local(last.global_transform * Vector3(0.0, half.y, -half.z))
	var neck := dino.ridge_carpets(3.5, 24.0, 2.3, 2.4, NECK_CHAIN, &"moss", &"moss", 0.35, skin)
	# A mossy brim off the end of her nose, to step across onto whatever her chin rests on.
	var tip: Vector3 = Dino.ridge_points(skin, 24.0, 24.0, 1.0)[0]
	head_piece = dino.carpet("Head", tip + Vector3(0.0, 0.0, -1.6), tip + Vector3(0.0, 0.0, 2.6), 2.2, 0.35, &"moss", &"moss", skin)
	neck.append(head_piece)
	for p in neck:
		for k in 2:
			Kit.blob(p, Vector3(randf_range(-0.6, 0.6), 0.22, randf_range(-0.8, 0.8)), 0.25, [&"candy_pink", &"gold", &"mush_spot"][k % 3] as StringName)
	# Where her mouth reaches when she bends down to eat: the trough goes there.
	dino.bend_pitch("Shoulders", EAT_PITCH)
	dino.tick(0.0)
	var mouth := Vector3(0.0, INF, 0.0)
	var front := -INF
	for q in dino.skin_points(false):
		front = maxf(front, q.z)
	for q in dino.skin_points(false):
		if q.z > front - 4.5 and q.y < mouth.y:
			mouth = q
	trough_at = Vector3(mouth.x, 0.0, mouth.z - 0.6)
	_build_trough()
	dino.bend_pitch("Shoulders", _pitch)
	dino.tick(0.0)


func _build_trough() -> void:
	var t := Kit.block(self, trough_at + Vector3(0.0, 0.9, 0.0), Vector3(3.6, 0.9, 2.2), &"wood_plank", Layers.WORLD, &"bark_dark")
	t.name = "Trough"
	for side: float in [-1.0, 1.0]:
		Kit.block(self, trough_at + Vector3(side * 1.9, 1.2, 0.0), Vector3(0.3, 1.2, 2.4), &"bark_mid", Layers.WORLD, &"")
	sign_text("Mossback's breakfast trough", trough_at + Vector3(0.0, 0.0, -2.6))


func sign_text(text: String, at: Vector3) -> void:
	Props.spawn(self, &"sign", at, PI, 1.6, false)
	var l := Kit.label(self, at + Vector3(0.0, 2.4, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


## A melon hanging at `world_pos`: knock it down (any hit) and it rolls into her trough.
func add_melon(world_pos: Vector3) -> Area3D:
	var m := Area3D.new()
	m.collision_layer = Layers.REFLECTABLE
	m.collision_mask = 0
	m.monitoring = false
	m.set_meta(&"actor", self)
	m.set_meta(&"melon", true)
	var s := SphereShape3D.new()
	s.radius = 1.0
	Kit.add_shape(m, s)
	var ball := SphereMesh.new()
	ball.radius = 0.7
	ball.height = 1.3
	Kit.mesh_instance(m, ball, Kit.mat(&"lime_pop", 0.03))
	for i in 3:
		var stripe := TorusMesh.new()
		stripe.inner_radius = 0.66
		stripe.outer_radius = 0.72
		var st := Kit.mesh_instance(m, stripe, Kit.mat(&"leaf_dark"))
		st.rotation = Vector3(PI * 0.5, i * PI / 3.0, 0.0)
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.06
	stalk.bottom_radius = 0.08
	stalk.height = 1.4
	Kit.mesh_instance(m, stalk, Kit.mat(&"bark_dark"), Vector3(0.0, 1.2, 0.0))
	get_parent().add_child(m)
	m.global_position = world_pos
	m.set_meta(&"home", world_pos)
	_melons.append(m)
	return m


func receive_player_attack(atk: Dictionary, area: Area3D) -> Dictionary:
	if area == null or not area.has_meta(&"melon") or area.has_meta(&"falling"):
		return {}
	drop_melon(area)
	return {"hit": true}


## The melon falls, bounces and rolls into the trough.
func drop_melon(m: Area3D) -> void:
	m.set_meta(&"falling", true)
	m.collision_layer = 0
	AudioDirector.play(&"coconut_break", -4.0, 0.7)
	var from := m.global_position
	var to := to_global(trough_at + Vector3(0.0, 1.3, 0.0))
	var fly := func(k: float) -> void:
		if is_instance_valid(m):
			m.global_position = from.lerp(to, k) + Vector3.UP * (sin(k * PI) * 3.0)
			m.rotation.x = k * 9.0
	var tw := create_tween()
	tw.tween_method(fly, 0.0, 1.0, 1.3)
	tw.tween_callback(func() -> void: _melon_landed(m))


func _melon_landed(m: Area3D) -> void:
	AudioDirector.play(&"land", 0.0, 0.7)
	Fx.burst(get_parent(), m.global_position, Palette.color(&"lime_pop"), 10, 3.0, 0.15)
	_in_trough = m
	if state == S.HUNGRY:
		state = S.EATING
		_t = 0.0
		AudioDirector.play(&"boss_roar", -10.0, 1.9)
	else:
		_finish_melon()


func _finish_melon() -> void:
	if _in_trough != null and is_instance_valid(_in_trough):
		var home := _in_trough.get_meta(&"home") as Vector3
		_in_trough.queue_free()
		# The cycad grows another (for next time, or for a friend).
		get_tree().create_timer(12.0).timeout.connect(func() -> void:
			if is_inside_tree():
				add_melon(home))
	_in_trough = null


func is_resting() -> bool:
	return state == S.RESTING


func _physics_process(delta: float) -> void:
	_t += delta
	match state:
		S.HUNGRY:
			# Craning about, looking for breakfast.
			_pitch = HUNGRY_PITCH + sin(_t * 0.7) * 4.0
		S.EATING:
			if _t < 2.2:
				_pitch = lerpf(HUNGRY_PITCH, EAT_PITCH, smoothstep(0.0, 2.2, _t))
			elif _t < 5.0:
				_pitch = EAT_PITCH + sin((_t - 2.2) * 9.0) * 2.0
				if _in_trough != null and is_instance_valid(_in_trough):
					_in_trough.scale = Vector3.ONE * clampf(1.0 - (_t - 2.2) / 2.8, 0.05, 1.0)
				if int(_t * 3.0) != int((_t - delta) * 3.0):
					AudioDirector.play(&"slime_land", -6.0, 0.6)
			elif _t < 7.6:
				_finish_melon()
				_pitch = lerpf(EAT_PITCH, REST_PITCH, smoothstep(5.0, 7.6, _t))
			else:
				_pitch = REST_PITCH
				state = S.RESTING
				Fx.burst(get_parent(), dino.bone_point("Head") + Vector3.UP * 2.0, Palette.color(&"candy_pink"), 24, 4.0, 0.2, -2.0, 1.2)
				AudioDirector.play(&"seed", -2.0, 0.8)
				var hud := get_tree().get_first_node_in_group(&"hud") as Hud
				if hud != null:
					hud.show_banner("Mossback rests her chin on the cliff!", 2.2)
				fed.emit()
		S.RESTING:
			_pitch = REST_PITCH
	dino.bend_pitch("Shoulders", _pitch)
