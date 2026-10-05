extends Level
## Mossbrook, the hub (plan §5.1): arrival green, Elder Fern's hut, Pip's hut with the rooftop
## course, the closed shop, the training yard and the Great Hollow Oak holding the Rootway.
## No enemies ever appear here. Glimmer Seeds bloom into flower beds (plan pillar 5).

const COURSE := "rooftop_course"
const FLOWER_BEDS: Array[Vector3] = [Vector3(-4.0, 0.0, 6.0), Vector3(4.5, 0.0, 6.5), Vector3(-6.5, 0.0, -9.0), Vector3(6.5, 0.0, -9.5), Vector3(0.0, 0.0, 16.0)]

var _course_running: bool = false
var _course_time: float = 0.0
var _start_area: Area3D
var _finish_area: Area3D
var _fern: Npc


func build() -> void:
	scene_id = Progress.HUB_SCENE
	default_spawn = &"hub_arrival"
	music = &"mossbrook"
	kill_y = -10.0
	Kit.water(self, Vector3(0.0, -1.0, 0.0), Vector2(200.0, 200.0))
	Kit.pillar(self, Vector3(0.0, 0.0, -2.0), 30.0, 5.0, &"bark_mid", &"grass_mid")
	add_spawn(&"hub_arrival", Vector3(0.0, 0.0, 13.0))
	add_spawn(&"hub_rootway_exit", Vector3(0.0, 0.0, -11.5), Vector3.BACK)
	_great_oak()
	_huts()
	_npcs()
	_training_yard()
	_rooftop_course()
	_flowers()
	_scenery()
	add_capture_point("hub_overview", Vector3(0.0, 14.0, 30.0), Vector3(0.0, 2.0, -6.0))
	add_capture_point("hub_oak", Vector3(8.0, 4.0, -4.0), Vector3(0.0, 3.0, -17.0))


func _sign(pos: Vector3, text: String) -> void:
	var board := BoxMesh.new()
	board.size = Vector3(1.4, 0.7, 0.1)
	Kit.mesh_instance(self, board, Kit.mat(&"wood_plank", 0.02), pos + Vector3(0.0, 1.2, 0.0))
	var post := CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.08
	post.height = 1.1
	Kit.mesh_instance(self, post, Kit.mat(&"bark_dark"), pos + Vector3(0.0, 0.55, 0.0))
	var l := Kit.label(self, pos + Vector3(0.0, 2.3, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _great_oak() -> void:
	var trunk := Kit.static_body(self, Vector3(0.0, 8.0, -22.0))
	var shape := CylinderShape3D.new()
	shape.radius = 5.5
	shape.height = 16.0
	Kit.add_shape(trunk, shape)
	var cm := CylinderMesh.new()
	cm.top_radius = 4.5
	cm.bottom_radius = 6.5
	cm.height = 16.0
	cm.radial_segments = 12
	Kit.mesh_instance(trunk, cm, Kit.mat(&"bark_mid", 0.05))
	for spec: Array in [[0.0, 19.0, -22.0, 9.0], [-6.0, 16.0, -20.0, 6.0], [6.5, 16.5, -23.0, 6.5], [0.0, 15.0, -15.0, 5.0]]:
		Kit.blob(self, Vector3(spec[0] as float, spec[1] as float, spec[2] as float), spec[3] as float, &"leaf_dark")
	# The Rootway: World 1's Dream Pool at the oak's door, and a dormant arch for later worlds.
	var arch := Portal.new()
	arch.target_scene = &"world_01"
	arch.target_spawn = &"w1_entrance"
	arch.cleared = Progress.is_world_complete(&"world_01")
	arch.label_text = "Glimmerbrook Wilds"
	arch.position = Vector3(0.0, 0.0, -14.6)
	add_child(arch)
	var dormant := Portal.new()
	dormant.dormant = true
	dormant.label_text = "Not yet..."
	dormant.position = Vector3(-7.5, 0.0, -14.5)
	dormant.rotation.y = 0.5
	add_child(dormant)
	if Progress.is_world_complete(&"world_01"):
		# Trophy pedestal: the Glimmer Crest beside the cleared arch.
		Kit.pillar(self, Vector3(-3.4, 1.0, -13.4), 0.45, 1.0, &"stone_light")
		var crest := CylinderMesh.new()
		crest.top_radius = 0.4
		crest.bottom_radius = 0.4
		crest.height = 0.08
		var c := Kit.mesh_instance(self, crest, Kit.mat(&"gold", 0.02), Vector3(-3.4, 1.5, -13.4))
		c.rotation.x = PI * 0.5


func _huts() -> void:
	Kit.hut(self, Vector3(-11.0, 0.0, -4.0), Vector3(5.0, 3.2, 4.5), &"roof_teal", 0.3)
	Kit.hut(self, Vector3(10.0, 0.0, -5.0), Vector3(4.5, 3.0, 4.5), &"roof_blue", -0.2)
	var shop := Kit.hut(self, Vector3(-12.0, 0.0, 9.0), Vector3(4.5, 3.0, 4.0), &"roof_red", 1.2)
	Kit.label(shop, Vector3(0.0, 2.0, 3.0), "Shop\nOpening soon!", 34)
	Kit.hut(self, Vector3(11.0, 0.0, 9.5), Vector3(4.0, 2.8, 4.0), &"thatch", -1.1)
	_sign(Vector3(2.5, 0.0, 11.0), "Welcome to Mossbrook!")


func _npcs() -> void:
	_fern = _npc("elder_fern", "Elder Fern", Vector3(-8.0, 0.0, -1.0), &"roof_teal", &"cloth_cream", &"skin_dark", 1.05)
	_npc("pip", "Pip", Vector3(8.0, 0.0, -1.5), &"roof_blue", &"roof_red", &"skin_light", 0.8)
	_npc("old_bramble", "Old Bramble", Vector3(3.6, 0.0, -12.0), &"bark_light", &"leaf_dark", &"skin_mid", 1.15)


func _npc(id: String, display: String, pos: Vector3, tunic: StringName, hat: StringName, skin: StringName, s: float) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.display_name = display
	n.tunic = tunic
	n.hat = hat
	n.skin = skin
	n.body_scale = s
	n.position = pos
	add_child(n)
	return n


func _training_yard() -> void:
	for p: Vector3 in [Vector3(-16.0, 0.0, -10.0), Vector3(-18.5, 0.0, -13.0), Vector3(-14.0, 0.0, -14.5)]:
		var d := TrainingDummy.new()
		d.position = p
		add_child(d)
	Kit.block(self, Vector3(-20.0, 1.2, -6.0), Vector3(2.5, 1.2, 2.5), &"wood_warm")
	Kit.block(self, Vector3(-22.5, 2.8, -9.0), Vector3(2.0, 2.8, 2.0), &"wood_warm")
	Kit.block(self, Vector3(-21.0, 4.6, -12.5), Vector3(2.0, 4.6, 2.0), &"wood_warm")
	var cap := Springcap.new()
	cap.position = Vector3(-21.0, 0.0, -2.0)
	add_child(cap)
	_sign(Vector3(-15.0, 0.0, -6.5), "Training Yard\nLock on: hold Right mouse / Q")


## Pip's rooftop course: crates -> Pip's roof -> posts -> the tower flag. Best time is saved.
func _rooftop_course() -> void:
	Kit.block(self, Vector3(13.8, 1.0, -1.0), Vector3(1.6, 1.0, 1.6), &"wood_warm")
	Kit.block(self, Vector3(14.6, 2.2, -3.9), Vector3(1.5, 2.2, 1.5), &"wood_warm")
	Kit.pillar(self, Vector3(12.6, 6.0, -10.0), 0.9, 6.0, &"bark_light", &"moss")
	Kit.pillar(self, Vector3(15.6, 7.4, -12.8), 0.9, 7.4, &"bark_light", &"moss")
	Kit.block(self, Vector3(18.5, 8.6, -16.0), Vector3(3.6, 8.6, 3.6), &"stone_light")
	var pole := CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.05
	pole.height = 2.4
	Kit.mesh_instance(self, pole, Kit.mat(&"bark_dark"), Vector3(18.5, 9.8, -16.0))
	var flag := BoxMesh.new()
	flag.size = Vector3(0.9, 0.55, 0.05)
	Kit.mesh_instance(self, flag, Kit.mat(&"roof_red", 0.02), Vector3(18.95, 10.7, -16.0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.1
	Kit.mesh_instance(self, ring, Fx.fx_mat(Palette.color(&"gold")), Vector3(12.0, 0.08, 1.5))
	_start_area = _trigger(Vector3(12.0, 0.0, 1.5), 1.1)
	_finish_area = _trigger(Vector3(18.5, 8.6, -16.0), 1.6)
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
		bed.top_radius = 1.3
		bed.bottom_radius = 1.4
		bed.height = 0.25
		Kit.mesh_instance(self, bed, Kit.mat(&"bark_dark"), c + Vector3(0.0, 0.12, 0.0))
		for k in 7:
			var a := float(k) / 7.0 * TAU
			var col: StringName = [&"gloop_pink", &"gold", &"portal_magenta", &"cloth_cream"][k % 4]
			Kit.blob(self, c + Vector3(cos(a) * 0.8, 0.45, sin(a) * 0.8), 0.22, col)


func _scenery() -> void:
	var i := 0
	for a_deg in range(0, 360, 24):
		var a := deg_to_rad(float(a_deg))
		var r := 26.0 + float(i % 3)
		var p := Vector3(cos(a) * r, 0.0, -2.0 + sin(a) * r)
		if p.z < -18.0 and absf(p.x) < 8.0:
			continue
		Kit.tree(self, p, 7.0 + float(i % 4), &"leaf_dark" if i % 2 == 0 else &"leaf_teal", i)
		i += 1


func after_spawn(_spawn_id: StringName) -> void:
	Progress.set_resume(Progress.HUB_SCENE, _spawn_id if _spawn_id != &"" else &"hub_arrival")
	if Progress.is_world_complete(&"world_01") and _fern != null:
		_fern.emote_joy()


func _process(delta: float) -> void:
	if _course_running:
		_course_time += delta
		hud.set_timer_text("Rooftop course  %.2f s   (best %.2f)" % [_course_time, Progress.best_time(COURSE)])
