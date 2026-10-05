extends Level
## Mossbrook, the hub (plan §5.1): arrival green, Elder Fern's hut, Pip's hut with the rooftop
## course, the closed shop, the training yard and the Great Hollow Oak holding the Rootway.
## No enemies ever appear here. Glimmer Seeds bloom into flower beds (plan pillar 5).

const COURSE := "rooftop_course"
const FLOWER_BEDS: Array[Vector3] = [Vector3(-6.0, 0.0, 9.0), Vector3(6.5, 0.0, 10.0), Vector3(-9.0, 0.0, -14.0), Vector3(9.5, 0.0, -14.5), Vector3(0.0, 0.0, 26.0), Vector3(-4.0, 0.0, 30.0), Vector3(4.0, 0.0, 30.0), Vector3(-13.0, 0.0, 22.0), Vector3(13.0, 0.0, 22.0), Vector3(0.0, 0.0, 33.0)]

var _course_running: bool = false
var _course_time: float = 0.0
var _start_area: Area3D
var _finish_area: Area3D
var _fern: Npc
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Build 2: rebuilt at about 1.5x scale for the faster, higher hero, with KayKit Medieval houses
## and Kenney Nature Kit trees and plants (CC0).
func build() -> void:
	scene_id = Progress.HUB_SCENE
	default_spawn = &"hub_arrival"
	music = &"mossbrook"
	kill_y = -10.0
	_rng.seed = 7
	Kit.water(self, Vector3(0.0, -1.0, 0.0), Vector2(320.0, 320.0))
	Kit.pillar(self, Vector3(0.0, 0.0, -4.0), 42.0, 5.0, &"bark_mid", &"grass_mid")
	add_spawn(&"hub_arrival", Vector3(0.0, 0.0, 22.0))
	add_spawn(&"hub_rootway_exit", Vector3(0.0, 0.0, -11.0), Vector3.BACK)
	_great_oak()
	_huts()
	_npcs()
	_training_yard()
	_rooftop_course()
	_flowers()
	_scenery()
	add_capture_point("hub_overview", Vector3(0.0, 20.0, 46.0), Vector3(0.0, 2.0, -8.0))
	add_capture_point("hub_oak", Vector3(12.0, 5.0, -8.0), Vector3(0.0, 4.0, -26.0))


func _sign(pos: Vector3, text: String, yaw: float = 0.0) -> void:
	Props.spawn(self, &"sign", pos, yaw, 1.6, false)
	var l := Kit.label(self, pos + Vector3(0.0, 2.4, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _great_oak() -> void:
	var trunk := Kit.static_body(self, Vector3(0.0, 11.0, -34.0))
	var shape := CylinderShape3D.new()
	shape.radius = 7.0
	shape.height = 22.0
	Kit.add_shape(trunk, shape)
	var cm := CylinderMesh.new()
	cm.top_radius = 5.5
	cm.bottom_radius = 8.2
	cm.height = 22.0
	cm.radial_segments = 14
	Kit.mesh_instance(trunk, cm, Kit.mat(&"bark_mid", 0.06))
	for spec: Array in [[0.0, 27.0, -34.0, 13.0], [-9.0, 23.0, -31.0, 8.5], [9.5, 23.5, -35.0, 9.0], [0.0, 21.0, -24.0, 7.0]]:
		Kit.blob(self, Vector3(spec[0] as float, spec[1] as float, spec[2] as float), spec[3] as float, &"leaf_dark")
	# The Rootway: one Dream Pool arch per world in a crescent around the oak (Build 4).
	var n := Progress.WORLD_DEFS.size()
	for i in n:
		var w := Progress.WORLD_DEFS[i]
		var a := lerpf(-0.95, 0.95, float(i) / maxf(n - 1, 1)) if n > 1 else 0.0
		var arch := Portal.new()
		arch.target_scene = w.id
		arch.target_spawn = w.entrance_spawn
		arch.cleared = Progress.is_world_complete(w.id)
		arch.label_text = "%d. %s%s" % [i + 1, w.display_name, "  (Star)" if w.goal == &"star" else ""]
		arch.position = Vector3(sin(a) * 15.0, 0.0, -34.0 + cos(a) * 15.0)
		arch.rotation.y = a
		add_child(arch)
	if Progress.is_world_complete(&"world_01"):
		# Trophy pedestal: the Glimmer Crest beside the cleared arch.
		Kit.pillar(self, Vector3(-4.0, 1.0, -22.0), 0.45, 1.0, &"stone_light")
		var crest := CylinderMesh.new()
		crest.top_radius = 0.4
		crest.bottom_radius = 0.4
		crest.height = 0.08
		var c := Kit.mesh_instance(self, crest, Kit.mat(&"gold", 0.02), Vector3(-4.0, 1.5, -22.0))
		c.rotation.x = PI * 0.5


func _huts() -> void:
	Props.spawn(self, &"home_a_blue", Vector3(-17.0, 0.0, -6.0), 0.9)
	Props.spawn(self, &"home_a_green", Vector3(15.0, 0.0, -8.0), -0.8)
	var shop := Props.spawn(self, &"market", Vector3(-18.0, 0.0, 15.0), 2.2)
	Kit.label(shop, Vector3(0.0, 5.5, 0.0), "Shop\nOpening soon!", 40)
	Props.spawn(self, &"home_b_red", Vector3(17.0, 0.0, 15.0), -2.2)
	Props.spawn(self, &"windmill", Vector3(-28.0, 0.0, -18.0), 0.6)
	Props.spawn(self, &"well", Vector3(7.0, 0.0, 6.0), 0.3)
	for spec: Array in [[-11.0, 2.0, &"barrel"], [-12.0, 3.2, &"barrel"], [11.5, -1.0, &"crate"], [-14.0, 18.5, &"sack"], [-21.0, 11.0, &"wheelbarrow"], [20.5, 11.0, &"lumber"]]:
		Props.spawn(self, spec[2] as StringName, Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.0, (spec[2] as StringName) in [&"barrel", &"crate"])
	_sign(Vector3(3.5, 0.0, 19.0), "Welcome to Mossbrook!")


func _npcs() -> void:
	_fern = _npc("elder_fern", "Elder Fern", Vector3(-12.0, 0.0, -2.0))
	_npc("pip", "Pip", Vector3(11.0, 0.0, -3.0))
	_npc("old_bramble", "Old Bramble", Vector3(8.0, 0.0, -11.0))


func _npc(id: String, display: String, pos: Vector3) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.display_name = display
	n.position = pos
	add_child(n)
	return n


func _training_yard() -> void:
	for p: Vector3 in [Vector3(-23.0, 0.0, -1.0), Vector3(-27.0, 0.0, 1.5), Vector3(-24.5, 0.0, 5.0)]:
		var d := TrainingDummy.new()
		d.position = p
		add_child(d)
	for p: Vector3 in [Vector3(-30.0, 0.0, -4.0), Vector3(-31.0, 0.0, 4.0)]:
		Props.spawn(self, &"target", p, PI * 0.5, 1.0, false)
	Props.spawn(self, &"crate", Vector3(-33.0, 0.0, 9.0), 0.2, 2.0)
	Props.spawn(self, &"crate", Vector3(-35.0, 0.0, 13.5), 0.5, 3.4)
	var cap := Springcap.new()
	cap.position = Vector3(-29.0, 0.0, 10.0)
	add_child(cap)
	_sign(Vector3(-20.0, 0.0, -5.0), "Training Yard\nLock on: hold Q / LT", 0.8)


## Pip's rooftop course: crates -> Pip's roof -> two tall posts -> the tower top. Best time saved.
func _rooftop_course() -> void:
	Props.spawn(self, &"crate", Vector3(22.0, 0.0, -1.0), 0.3, 2.3)
	Props.spawn(self, &"column", Vector3(21.0, 0.0, -16.0), 0.0, 3.0)
	Props.spawn(self, &"column", Vector3(27.0, 0.0, -22.5), 0.0, 4.0)
	Props.spawn(self, &"tower", Vector3(31.0, 0.0, -31.0), -0.5, 1.2)
	var top := 2.19 * 5.0 * 1.2
	Props.spawn(self, &"flag", Vector3(31.0, top, -31.0), 0.0, 2.0, false)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.1
	Kit.mesh_instance(self, ring, Fx.fx_mat(Palette.color(&"gold")), Vector3(19.0, 0.08, 3.0))
	_start_area = _trigger(Vector3(19.0, 0.0, 3.0), 1.1)
	_finish_area = _trigger(Vector3(31.0, top, -31.0), 2.4)
	_start_area.body_entered.connect(func(b: Node3D) -> void:
		if b is Player:
			_course_running = true
			_course_time = 0.0
			AudioDirector.play(&"ui_blip"))
	_finish_area.body_entered.connect(func(b: Node3D) -> void:
		if b is Player and _course_running:
			_course_running = false
			var best := Progress.record_time(COURSE, _course_time)
			hud.show_banner(("New best!  %.2f s" if best else "%.2f s") % _course_time, 2.0)
			AudioDirector.play(&"seed")
			get_tree().create_timer(2.5).timeout.connect(func() -> void:
				if is_inside_tree():
					hud.set_timer_text("")))
	_sign(Vector3(16.5, 0.0, 4.0), "Pip's Rooftop Race\nStep in the ring, reach the tower top!", -0.4)


func _trigger(pos: Vector3, r: float) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = Layers.INTERACT
	a.collision_mask = Layers.PLAYER_BODY
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = 1.5
	Kit.add_shape(a, s, Vector3(0.0, 0.75, 0.0))
	a.position = pos
	add_child(a)
	return a


## Each Glimmer Seed adds a visible flower bed.
func _flowers() -> void:
	var seeds := Progress.seed_count()
	for i in mini(seeds, FLOWER_BEDS.size()):
		var c := FLOWER_BEDS[i]
		var bed := CylinderMesh.new()
		bed.top_radius = 1.8
		bed.bottom_radius = 1.9
		bed.height = 0.25
		Kit.mesh_instance(self, bed, Kit.mat(&"bark_dark"), c + Vector3(0.0, 0.12, 0.0))
		var kinds: Array[StringName] = [&"flower_red", &"flower_yellow", &"flower_purple", &"flower_red_b", &"flower_yellow_b"]
		for k in 9:
			var a := float(k) / 9.0 * TAU
			Props.spawn(self, kinds[k % kinds.size()], c + Vector3(cos(a) * 1.1, 0.25, sin(a) * 1.1), a, 1.3, false)


func _scenery() -> void:
	var trees: Array[StringName] = [&"tree_default", &"tree_oak", &"tree_detailed", &"tree_fat", &"tree_pine", &"tree_cone"]
	var i := 0
	for a_deg in range(0, 360, 14):
		var a := deg_to_rad(float(a_deg))
		var r := 37.0 + _rng.randf_range(0.0, 3.5)
		var p := Vector3(cos(a) * r, 0.0, -4.0 + sin(a) * r)
		if p.z < -26.0 and absf(p.x) < 12.0:
			continue
		Props.spawn(self, trees[i % trees.size()], p, _rng.randf() * TAU, _rng.randf_range(1.0, 1.4))
		i += 1
	for k in 60:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(6.0, 34.0)
		var p := Vector3(cos(a) * r, 0.0, -4.0 + sin(a) * r)
		if absf(p.x) < 3.0 and p.z > -26.0:
			continue
		var kinds: Array[StringName] = [&"grass", &"grass_large", &"flower_red", &"flower_yellow", &"flower_purple", &"bush_small", &"mushroom_red_group"]
		Props.spawn(self, kinds[k % kinds.size()], p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.3), false)
	for k in 8:
		var a := float(k) / 8.0 * TAU + 0.3
		Props.spawn(self, &"mountain" if k % 2 == 0 else &"hills_trees", Vector3(cos(a) * 120.0, -1.0, sin(a) * 120.0), _rng.randf() * TAU, _rng.randf_range(1.0, 1.4), false)
	for k in 6:
		Props.spawn(self, &"cloud_big" if k % 2 == 0 else &"cloud_small", Vector3(_rng.randf_range(-80.0, 80.0), _rng.randf_range(45.0, 70.0), _rng.randf_range(-90.0, 60.0)), _rng.randf() * TAU, _rng.randf_range(1.6, 2.4), false)


func after_spawn(_spawn_id: StringName) -> void:
	Progress.set_resume(Progress.HUB_SCENE, _spawn_id if _spawn_id != &"" else &"hub_arrival")
	if Progress.is_world_complete(&"world_01") and _fern != null:
		_fern.emote_joy()


func _process(delta: float) -> void:
	if _course_running:
		_course_time += delta
		hud.set_timer_text("Rooftop course  %.2f s   (best %.2f)" % [_course_time, Progress.best_time(COURSE)])
