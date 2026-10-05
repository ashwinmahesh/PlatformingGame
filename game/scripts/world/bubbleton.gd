class_name Bubbleton
extends OpenWorld
## World 4, Bubbleton Reef (Build 5, Ashwin: "one of the levels based on Bikini Bottom", walking
## and jumping normally): a goofy little town on the seafloor under drifting sky-flowers, with
## its own folk in bubble helmets. A pure platforming world laid out as a town (Build 6: "the
## levels shouldn't feel the same"): Main Street runs north from the South Gate past the Great
## Bubble plaza, with side lanes (Pineapple Row west, Grill Lane east), a rooftop run, an old
## cannery to break into, bells to ring in order and a crate to shove. Beyond the streets:
##   North end   Jellyfish Fields - bounce on jellyfish up coral terraces
##   North-east  Kelp Forest      - leaf ledges spiral up giant kelp; bubble columns lift you
##   South-west  Shipwreck        - ride sea turtles over the trench to an old ship
##   South-east  Coral Gardens    - a timed crystal puzzle, a lagoon to dive in, lanterns
## The three Star Shards (north, east, west) wake the Great Bubble in the square, which carries
## you up to the Grand Star on a sky-flower. Clearing it teaches the Air Dash.

const WORLD := &"world_04"
const LIFT := Vector3(0.0, 0.0, -6.0)
const STAR_Y := 44.0

var _great_bubble: Updraft


func configure() -> void:
	world_id = WORLD
	platform_colour = &"blue"
	model_tint = Color(0.9, 1.02, 1.08)
	# Under the sea: teal light from above, aqua haze, no clouds.
	sky_top = Color(0.04, 0.32, 0.58)
	sky_horizon = Color(0.22, 0.72, 0.82)
	sky_bottom = Color(0.16, 0.56, 0.68)
	cloud_cover = 0.0
	sun_color = Color(0.86, 1.0, 0.96)
	sun_energy = 1.05
	sun_angles = Vector2(-72.0, -20.0)
	ambient_color = Color(0.5, 0.85, 0.9)
	ambient_energy = 0.62
	fog_color = Color(0.2, 0.62, 0.74)
	fog_begin = 45.0
	fog_end = 230.0
	tops = {&"stone_dark": &"sand_light", &"stone_light": &"sand_light", &"coral_pink": &"sand_light", &"coral_orange": &"sand_light", &"mush_purple": &"sand_light", &"wood_warm": &"wood_plank", &"bark_mid": &"wood_plank", &"sea_violet": &"sand_light"}
	grass_density = 0.03


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w4_entrance"
	music = &"reef"
	floor_y = 0.0
	kill_y = -26.0
	_rng.seed = 404
	regions = {"main_street": Vector3.ZERO, "jellyfish": Vector3(0.0, 0.0, -110.0), "kelp": Vector3(80.0, 0.0, -40.0), "ship": Vector3(-90.0, 0.0, 40.0), "coral": Vector3(75.0, 0.0, 40.0), "pineapple_row": Vector3(-40.0, 0.0, -28.0), "tar_pits": Vector3(-70.0, 0.0, -60.0)}
	_seafloor()
	_town()
	_jellyfish_fields()
	_kelp_forest()
	_shipwreck()
	_coral_gardens()
	_side_spots()
	_landmarks()
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life(&"kelp")


# --- Seafloor, reef walls, the surface overhead ----------------------------------------------------

func _seafloor() -> void:
	var trench := Rect2(-72.0, 18.0, 22.0, 44.0)
	ground(Rect2(-150.0, -150.0, 300.0, 300.0), [trench], 0.0, 20.0, &"stone_dark", &"sand_light", 0.02)
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(22.0, 4.0, 44.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(-61.0, -14.0, 40.0)
	add_child(pit)
	Kit.block(self, Vector3(-61.0, -18.0, 40.0), Vector3(22.0, 2.0, 44.0), &"ink_navy", Layers.WORLD, &"")
	for i in 8:
		Whimsy.anemone(self, Vector3(-61.0 + _rng.randf_range(-9.0, 9.0), -18.0, 40.0 + _rng.randf_range(-20.0, 20.0)), &"portal_teal", 1.5)
	# Reef walls all round: slate rock crowned with coral and kelp.
	for side in 4:
		for i in 11:
			var t := -150.0 + (i + 0.5) * 300.0 / 11.0
			var h := _rng.randf_range(10.0, 18.0)
			var c := Vector3(t, h, -160.0) if side == 0 else (Vector3(t, h, 160.0) if side == 1 else (Vector3(-160.0, h, t) if side == 2 else Vector3(160.0, h, t)))
			var size := Vector3(30.0, h + 20.0, 22.0) if side < 2 else Vector3(22.0, h + 20.0, 30.0)
			Kit.block(self, c, size, [&"coral_orange", &"coral_pink", &"mush_purple"][(i + side) % 3] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_light")
			var brain := SphereMesh.new()
			brain.radius = _rng.randf_range(3.0, 5.0)
			brain.height = brain.radius * 1.4
			Kit.mesh_instance(self, brain, Kit.mat([&"candy_pink", &"gold", &"slime_blue"][i % 3] as StringName, 0.03), c + Vector3(_rng.randf_range(-8.0, 8.0), 0.5, 0.0))
			for k in 3:
				Whimsy.coral(self, c + Vector3(_rng.randf_range(-10.0, 10.0), 0.0, _rng.randf_range(-6.0, 6.0)), [&"coral_pink", &"coral_orange", &"mush_purple", &"gold"][k + i % 2] as StringName, _rng.randf_range(2.0, 3.5))
	for i in 70:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-140.0, 140.0))
		if _busy(p):
			continue
		Whimsy.kelp(self, p, _rng.randf_range(8.0, 20.0))
	for i in 50:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-140.0, 140.0))
		if _busy(p):
			continue
		Whimsy.coral(self, p, [&"coral_pink", &"coral_orange", &"mush_purple", &"gold", &"slime_blue"][i % 5] as StringName, _rng.randf_range(0.8, 1.8))
	for i in 40:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-140.0, 140.0))
		if _busy(p):
			continue
		Whimsy.anemone(self, p, [&"mush_purple", &"candy_pink", &"portal_teal"][i % 3] as StringName, _rng.randf_range(0.8, 1.6))
	# The surface far above: drifting sky-flowers and slanting rays of light.
	var petals: Array[StringName] = [&"candy_pink", &"slime_blue", &"gold", &"mush_purple", &"lime_pop", &"coral_orange"]
	for i in 26:
		Whimsy.sky_flower(self, Vector3(_rng.randf_range(-200.0, 200.0), _rng.randf_range(70.0, 95.0), _rng.randf_range(-200.0, 200.0)), _rng.randf_range(6.0, 14.0), petals[i % petals.size()])
	for i in 14:
		var ray := CylinderMesh.new()
		ray.top_radius = _rng.randf_range(2.0, 4.0)
		ray.bottom_radius = ray.top_radius * 1.8
		ray.height = 110.0
		ray.cap_top = false
		ray.cap_bottom = false
		var r := Kit.mesh_instance(self, ray, Fx.fx_mat(Color(Palette.color(&"bubble"), 0.05)), Vector3(_rng.randf_range(-120.0, 120.0), 50.0, _rng.randf_range(-120.0, 120.0)))
		r.rotation = Vector3(0.25, _rng.randf() * TAU, 0.0)
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 10:
		Ambient.bubbles(self, Vector3(_rng.randf_range(-120.0, 120.0), 2.0, _rng.randf_range(-120.0, 120.0)), Vector3(4.0, 2.0, 4.0), 18)
	for i in 6:
		Ambient.fish(self, Vector3(_rng.randf_range(-100.0, 100.0), _rng.randf_range(6.0, 18.0), _rng.randf_range(-100.0, 100.0)), _rng.randf_range(6.0, 12.0), 9, [&"sunset_orange", &"slime_blue", &"gold", &"candy_pink"][i % 4] as StringName)
	add_capture_point("reef", Vector3(40.0, 40.0, 100.0), Vector3(0.0, 8.0, -20.0))


func _busy(p: Vector3) -> bool:
	if p.x > -78.0 and p.x < -46.0 and p.z > 12.0 and p.z < 68.0:
		return true
	if absf(p.x) < 44.0 and absf(p.z) < 66.0:
		return true
	for c: Vector3 in regions.values():
		if Vector2(p.x - c.x, p.z - c.z).length() < 34.0:
			return true
	return false


# --- Bubbleton (centre) ----------------------------------------------------------------------------

func _town() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w4_entrance", Vector3(0.0, 0.0, 52.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 60.0)
	add_child(exit)
	checkpoint(&"w4_cp_town", Vector3(-8.0, 0.0, 48.0))
	sign_post(Vector3(6.0, 0.0, 46.0), "Main Street. Bring 3 Star Shards to wake\nthe Great Bubble in the plaza!")
	sign_post(Vector3(4.0, 0.0, -58.0), "North: Jellyfish Fields")
	sign_post(Vector3(12.0, 0.0, -18.0), "Grill Lane / Kelp Forest", -PI * 0.5)
	sign_post(Vector3(-12.0, 0.0, -18.0), "Pineapple Row / Tar Pits", PI * 0.5)
	sign_post(Vector3(-12.0, 0.0, 36.0), "Shipwreck (south-west)", PI * 0.5)
	sign_post(Vector3(12.0, 0.0, 36.0), "Coral Gardens (south-east)", -PI * 0.5)
	# The Great Bubble: asleep until the shards come home, then it lifts you to the Grand Star.
	Kit.pillar(self, LIFT + Vector3(0.0, 0.6, 0.0), 4.2, 0.6, &"coral_orange", &"gold")
	for i in 8:
		var a := float(i) / 8.0 * TAU
		Kit.pillar(self, LIFT + Vector3(cos(a) * 6.5, 3.5, sin(a) * 6.5), 0.6, 3.5, &"coral_pink", &"gold")
	_great_bubble = Updraft.new()
	_great_bubble.look = &"bubbles"
	_great_bubble.size = Vector3(6.0, STAR_Y + 2.0, 6.0)
	_great_bubble.lift = 12.0
	_great_bubble.enabled = false
	_great_bubble.position = LIFT + Vector3(0.0, 0.6, 0.0)
	add_child(_great_bubble)
	Kit.pillar(self, LIFT + Vector3(9.0, STAR_Y, 0.0), 6.5, 0.8, &"candy_pink", &"mush_spot")
	Whimsy.sky_flower(self, LIFT + Vector3(9.0, STAR_Y - 0.6, 0.0), 9.0, &"candy_pink")
	var star := GoalStar.new()
	star.world_id = WORLD
	star.position = LIFT + Vector3(9.0, STAR_Y, 0.0)
	add_child(star)
	# Houses and the diner.
	_main_street()
	_diner(Vector3(22.0, 0.0, 22.0))
	for spec: Array in [["barnacle", "Captain Barnacle", Vector3(5.0, 0.0, 40.0)], ["coralie", "Coralie", Vector3(13.0, 0.0, 16.0)], ["finn", "Finn", Vector3(-6.0, 0.0, -14.0)]]:
		var npc := Npc.new()
		npc.npc_id = str(spec[0])
		npc.display_name = str(spec[1])
		npc.bubble_helmet = true
		npc.position = spec[2] as Vector3
		add_child(npc)
	var path := RoundMesh.box(Vector3(10.0, 0.06, 124.0), 0.03)
	Kit.mesh_instance(self, path, Kit.mat(&"sand_mid"), Vector3(0.0, 0.03, 0.0))
	var cross := RoundMesh.box(Vector3(96.0, 0.06, 6.0), 0.03)
	Kit.mesh_instance(self, cross, Kit.mat(&"sand_mid"), Vector3(0.0, 0.03, -21.0))
	for z: float in [44.0, 28.0, 12.0, -4.0, -36.0, -52.0]:
		for x: float in [-5.5, 5.5]:
			Whimsy.lamp(self, Vector3(x, 0.0, z), x < 0.0 and int(z) % 32 == 12)
		Whimsy.bunting(self, Vector3(-5.5, 3.0, z), Vector3(5.5, 3.0, z), 0.6)
	for i in 14:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(8.0, 30.0)
		var s := MeshInstance3D.new()
		s.mesh = GoalStar.star_mesh(0.5, 0.22, 0.08)
		s.material_override = Kit.mat([&"coral_orange", &"candy_pink", &"gold"][i % 3] as StringName, 0.01)
		s.position = Vector3(cos(a) * r, 0.06, sin(a) * r)
		s.rotation = Vector3(-PI * 0.5, 0.0, _rng.randf() * TAU)
		add_child(s)
	for spec: Array in [[-8.0, -10.0, &"coral_pink"], [8.0, -10.0, &"coral_orange"], [-8.0, 2.0, &"mush_purple"], [8.0, 2.0, &"gold"]]:
		Whimsy.coral(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as StringName, 1.3)
	heart_bush(Vector3(-8.0, 0.0, 54.0))
	Ambient.bubbles(self, LIFT + Vector3(0.0, 1.0, 0.0), Vector3(10.0, 2.0, 10.0), 30)
	Ambient.fish(self, Vector3(0.0, 9.0, 0.0), 14.0, 10, &"gold")
	sparkles(Vector3(0.0, 4.0, 0.0), Vector3(50.0, 8.0, 50.0), 40)
	add_capture_point("town", Vector3(16.0, 18.0, 70.0), Vector3(0.0, 2.0, 0.0))
	add_capture_point("rooftops", Vector3(-4.0, 16.0, 56.0), Vector3(-18.0, 6.0, 20.0))
	add_capture_point("star_flower", LIFT + Vector3(-10.0, STAR_Y + 8.0, 16.0), LIFT + Vector3(9.0, STAR_Y, 0.0))


## Main Street (Build 6): a rooftop run down the west side, a bell puzzle in the plaza that opens
## the Old Cannery (a big secret room with its own climb), and a crate to shove onto a plate that
## holds the Treasure Vault open. Townsfolk line the street.
func _main_street() -> void:
	# West side: coral tenements with flat roofs stepping up, then a kelp-rope bridge over the street.
	var roof_cols: Array[StringName] = [&"coral_pink", &"coral_orange", &"mush_purple", &"slime_blue"]
	for i in 4:
		var top := Vector3(-17.0, 4.0 + i * 2.5, 44.0 - i * 13.0)
		plat(top, Vector2(8.0, 10.0), roof_cols[i], 0)
		for k in 3:
			var win := CylinderMesh.new()
			win.top_radius = 0.6
			win.bottom_radius = 0.6
			win.height = 0.15
			var wm := Kit.mesh_instance(self, win, Kit.mat(&"gold"), top + Vector3(4.05, -1.6 - k * 0.0, -3.0 + k * 3.0))
			wm.rotation.z = PI * 0.5
		Whimsy.coral(self, top + Vector3(-2.5, 0.0, 3.0), [&"gold", &"candy_pink"][i % 2] as StringName, 0.8)
	ledge(Vector3(-12.0, 1.5, 50.0), Vector3(2.6, 1.5, 2.6), &"wood_warm")
	seed_at(&"w4_seed_rooftops", Vector3(-17.0, 11.5, 5.0))
	ledge(Vector3(0.0, 11.0, 5.0), Vector3(22.0, 0.4, 1.6), &"kelp")
	Kit.pillar(self, Vector3(16.0, 11.0, 5.0), 3.0, 11.0, &"coral_orange", &"sand_light")
	heart_at(Vector3(16.0, 11.0, 5.0))
	# Plaza bells: ring them in the order on the sign to open the Old Cannery.
	var bells := BellSequence.new()
	bells.order = [0, 1, 2]
	add_child(bells)
	var bell_cols: Array[StringName] = [&"candy_pink", &"gold", &"slime_blue"]
	for i in 3:
		var a := PI * 0.75 + i * PI * 0.25
		var post := LIFT + Vector3(cos(a) * 11.0, 0.0, sin(a) * 11.0)
		var b := CrystalSwitch.new()
		b.position = post
		add_child(b)
		Kit.blob(self, post + Vector3(0.0, 2.6, 0.0), 0.35, bell_cols[i])
		bells.add(b)
	sign_post(LIFT + Vector3(-14.0, 0.0, 6.0), "Ring the bells: pink, then gold, then blue.", PI * 0.5)
	var cannery: Array = secret_cave(Vector3(-32.0, 0.0, -2.0), PI * 0.5, Vector3(16.0, 9.0, 14.0), &"stone_dark", &"gate")
	ledge(Vector3(-4.0, 1.5, 3.0), Vector3(3.0, 1.5, 3.0), &"wood_warm")
	ledge(Vector3(-5.0, 3.6, -1.0), Vector3(3.0, 0.5, 3.0), &"wood_plank")
	ledge(Vector3(-1.0, 5.6, -4.5), Vector3(4.0, 0.5, 2.4), &"wood_plank")
	ledge(Vector3(4.5, 7.4, -4.5), Vector3(3.0, 0.5, 2.4), &"wood_plank")
	seed_at(&"w4_seed_cannery", Vector3(4.5, 7.4, -4.5))
	chest(Vector3(5.0, 0.3, 3.0), PI, &"")
	critter(SnapperCrab, Vector3(2.0, 0.6, 0.0))
	sign_post(Vector3(-3.0, 0.3, 5.5), "The Old Cannery")
	_frame = cannery[0]
	var cannery_door := cannery[1] as VineGate
	bells.solved.connect(func() -> void:
		cannery_door.set_closed(false)
		if hud != null:
			hud.show_banner("The Old Cannery creaks open!", 2.2))
	# Treasure Vault: shove the crate onto the plate to hold its door open.
	var vault: Array = secret_cave(Vector3(34.0, 0.0, 4.0), -PI * 0.5, Vector3(12.0, 8.0, 12.0), &"coral_orange", &"gate")
	stone(Vector3(-3.0, 1.0, -2.0), 1.6, 1.0, &"coral_pink", &"gold")
	ledge(Vector3(0.0, 3.2, -4.0), Vector3(3.0, 0.5, 2.4), &"wood_plank")
	ledge(Vector3(3.5, 5.4, -1.0), Vector3(2.4, 0.5, 3.0), &"wood_plank")
	seed_at(&"w4_seed_vault", Vector3(3.5, 5.4, -1.0))
	heart_at(Vector3(-3.0, 1.0, -2.0))
	_frame = vault[0]
	var vault_door := vault[1] as VineGate
	var crate := PushBlock.new()
	crate.position = Vector3(14.0, 0.0, 11.0)
	add_child(crate)
	var plate := PressurePlate.new()
	plate.position = Vector3(14.0, 0.0, 2.0)
	add_child(plate)
	plate.changed.connect(func(on: bool) -> void: vault_door.set_closed(not on))
	sign_post(Vector3(18.0, 0.0, 12.0), "Push the crate onto the plate\nto hold the vault open.", -PI * 0.5)
	# Errand: Mrs. Puffle's spotted hat blew away up the Jellyfish Fields.
	var puffle := Npc.new()
	puffle.npc_id = "puffle"
	puffle.display_name = "Mrs. Puffle"
	puffle.bubble_helmet = true
	puffle.errand_flag = &"w4_found_hat"
	puffle.reward_seed = &"w4_seed_errand"
	puffle.position = Vector3(-14.0, 0.0, -18.0)
	add_child(puffle)
	var hat := ErrandItem.new()
	hat.flag = &"w4_found_hat"
	hat.label_text = "Spotted hat"
	hat.position = Vector3(-14.0, 12.0, -110.0)
	add_child(hat)
	for spec: Array in [["kip", "Bubbles", Vector3(-6.0, 0.0, 24.0)], ["marlo", "Old Salt", Vector3(6.0, 0.0, -40.0)]]:
		var npc := Npc.new()
		npc.npc_id = str(spec[0])
		npc.display_name = str(spec[1])
		npc.bubble_helmet = true
		npc.position = spec[2] as Vector3
		add_child(npc)
	# East side: cottages and kiosks between the landmarks.
	Whimsy.shell_house(self, Vector3(18.0, 0.0, 34.0), deg_to_rad(-90.0), &"mush_teal", 0.8)
	Whimsy.shell_house(self, Vector3(-18.0, 0.0, -48.0), deg_to_rad(90.0), &"coral_pink", 0.9)
	Whimsy.shell_house(self, Vector3(-30.0, 0.0, 26.0), deg_to_rad(120.0), &"gold", 0.8)
	Whimsy.stall(self, Vector3(8.5, 0.0, 30.0), -PI * 0.5, &"candy_pink")
	Whimsy.stall(self, Vector3(-8.5, 0.0, -32.0), PI * 0.5, &"slime_blue")
	for z: float in [36.0, -26.0]:
		prop(&"q_bench", Vector3(7.0, 0.0, z), -PI * 0.5, 1.0)


## The Kelp Shake Diner: an old brass diving helmet with portholes. Its dome hides a seed.
func _diner(base: Vector3) -> void:
	var body := Kit.static_body(self, base + Vector3(0.0, 5.6, 0.0))
	var sph := SphereShape3D.new()
	sph.radius = 6.25
	Kit.add_shape(body, sph)
	var dome := SphereMesh.new()
	dome.radius = 6.25
	dome.height = 12.5
	Kit.mesh_instance(body, dome, Kit.mat(&"gold", 0.04))
	var collar := TorusMesh.new()
	collar.inner_radius = 4.5
	collar.outer_radius = 5.8
	Kit.mesh_instance(self, collar, Kit.mat(&"wood_warm", 0.03), base + Vector3(0.0, 0.6, 0.0))
	for i in 3:
		var a := -0.6 + i * 0.6
		var port := CylinderMesh.new()
		port.top_radius = 1.2
		port.bottom_radius = 1.2
		port.height = 0.3
		var pm := Kit.unique_mat(&"water_light")
		pm.set_shader_parameter(&"flash", 0.25)
		pm.set_shader_parameter(&"flash_color", Palette.color(&"bubble"))
		var p := Kit.mesh_instance(self, port, pm, base + Vector3(sin(a) * 6.1, 5.6, cos(a) * 6.1))
		p.rotation = Vector3(PI * 0.5, a, 0.0)
		var rim := TorusMesh.new()
		rim.inner_radius = 1.15
		rim.outer_radius = 1.45
		var r := Kit.mesh_instance(self, rim, Kit.mat(&"wood_warm"), base + Vector3(sin(a) * 6.15, 5.6, cos(a) * 6.15))
		r.rotation = Vector3(PI * 0.5, a, 0.0)
	var title := Kit.label(self, base + Vector3(0.0, 13.5, 0.0), "Kelp Shake Diner", 64)
	title.modulate = Palette.color(&"candy_pink")
	# Barrels up to the roof.
	ledge(base + Vector3(-8.0, 1.5, 3.0), Vector3(2.4, 1.5, 2.4), &"wood_warm")
	ledge(base + Vector3(-8.5, 4.0, -0.5), Vector3(2.4, 1.0, 2.4), &"wood_warm")
	ledge(base + Vector3(-7.0, 6.5, -4.5), Vector3(2.4, 1.0, 2.4), &"wood_warm")
	ledge(base + Vector3(-4.5, 9.0, -6.5), Vector3(2.4, 1.0, 2.4), &"wood_warm")
	seed_at(&"w4_seed_diner", base + Vector3(0.0, 11.85, 0.0))


# --- North: Jellyfish Fields ------------------------------------------------------------------------

func _jellyfish_fields() -> void:
	region(Vector3(0.0, 0.0, -70.0))
	checkpoint(&"w4_cp_jelly", Vector3(-6.0, 0.0, -6.0))
	sign_post(Vector3(5.0, 0.0, -6.0), "Land on a jellyfish to bounce.\nPLUNGE onto one to go even higher!")
	bouncer(Vector3(0.0, 0.0, -12.0), Springcap.Look.JELLY, 7.0, 11.0)
	plat(Vector3(0.0, 6.0, -24.0), Vector2(20.0, 14.0), &"coral_orange")
	bouncer(Vector3(-6.0, 6.0, -28.0), Springcap.Look.JELLY, 7.0, 11.0)
	plat(Vector3(-14.0, 12.0, -40.0), Vector2(14.0, 14.0), &"coral_pink")
	bouncer(Vector3(-8.0, 12.0, -46.0), Springcap.Look.JELLY, 7.0, 11.0)
	plat(Vector3(4.0, 18.0, -56.0), Vector2(14.0, 12.0), &"mush_purple")
	bouncer(Vector3(2.0, 18.0, -60.0), Springcap.Look.JELLY, 7.5, 12.0)
	disc(Vector3(0.0, 24.0, -72.0), 6.5, &"coral_orange", &"sand_light", 12)
	for spec: Array in [[-10.0, 6.0, -20.0, &"mush_purple"], [9.0, 6.0, -29.0, &"gold"], [-19.0, 12.0, -36.0, &"coral_orange"], [9.0, 18.0, -52.0, &"candy_pink"], [-4.0, 24.0, -75.0, &"slime_blue"]]:
		Whimsy.coral(self, P(Vector3(spec[0] as float, spec[1] as float, spec[2] as float)), spec[3] as StringName, 1.2)
	stone(Vector3(0.0, 25.5, -72.0), 3.0, 1.5, &"stone_light", &"gold")
	# A second way up: a bubble column beside the summit.
	updraft(Vector3(12.0, 0.0, -72.0), Vector3(4.0, 26.0, 4.0), 11.0, &"bubbles")
	shard_at(&"w4_shard_jelly", Vector3(0.0, 25.5, -72.0))
	# A high coral perch for a seed: Plunge off a drifting Jellyfloat.
	Kit.pillar(self, P(Vector3(24.0, 23.0, -50.0)), 2.2, 4.0, &"coral_pink", &"coral_orange")
	seed_at(&"w4_seed_jellytop", Vector3(24.0, 23.0, -50.0))
	for spec: Array in [[16.0, 21.0, -46.0], [-6.0, 9.0, -32.0], [4.0, 15.0, -46.0], [-14.0, 4.0, -14.0]]:
		critter(Jellyfloat, Vector3(spec[0] as float, spec[1] as float, spec[2] as float))
	gloplets(Vector3(10.0, 0.0, -14.0), 10.0, [Vector3.ZERO, Vector3(3.0, 0.0, -3.0), Vector3(-3.0, 0.0, 2.0)], [Vector3(0.0, 0.0, 4.0)])
	for i in 18:
		var p := Vector3(_rng.randf_range(-28.0, 28.0), 0.0, _rng.randf_range(-70.0, -4.0))
		Whimsy.flower(self, P(p), _rng.randf_range(0.8, 1.6), _rng.randf_range(0.6, 1.0), [&"candy_pink", &"gold", &"slime_blue", &"mush_purple"][i % 4] as StringName, false)
	for spec: Array in [[-20.0, -20.0], [22.0, -26.0], [-22.0, -60.0], [18.0, -70.0]]:
		Whimsy.coral(self, P(Vector3(spec[0] as float, 0.0, spec[1] as float)), &"coral_pink", 2.0)
	Ambient.fish(self, P(Vector3(0.0, 14.0, -40.0)), 12.0, 8, &"candy_pink")
	add_capture_point("jellyfish", Vector3(30.0, 22.0, -20.0), Vector3(0.0, 10.0, -90.0))


# --- East: Kelp Forest -----------------------------------------------------------------------------

func _kelp_forest() -> void:
	region(Vector3(40.0, 0.0, -40.0), -90.0)
	checkpoint(&"w4_cp_kelp", Vector3(-6.0, 0.0, -6.0))
	sign_post(Vector3(5.0, 0.0, -6.0), "Climb the giant kelp.\nBubble columns carry you up!")
	# Two giant kelp trunks with leaf ledges spiralling up.
	for spec: Array in [[-6.0, -28.0, 0.0], [10.0, -52.0, 1.5]]:
		var c := Vector3(spec[0] as float, 0.0, spec[1] as float)
		Kit.pillar(self, P(c + Vector3(0.0, 30.0, 0.0)), 1.6, 30.0, &"kelp", &"lime_pop")
		for i in 11:
			var a := float(i) * 1.15 + (spec[2] as float)
			var y := 2.6 + i * 2.4
			ledge(c + Vector3(cos(a) * 3.4, y, sin(a) * 3.4), Vector3(3.6, 0.5, 3.0), &"lime_pop")
	critter(SnapperCrab, Vector3(4.0, 0.5, -18.0))
	critter(SnapperCrab, Vector3(-8.0, 0.5, -40.0))
	critter(SnapperCrab, Vector3(14.0, 0.5, -36.0))
	seed_at(&"w4_seed_kelp_low", Vector3(-6.0 + cos(4.0 * 1.15) * 3.4, 2.6 + 4.0 * 2.4, -28.0 + sin(4.0 * 1.15) * 3.4))
	# A bubble column between the trunks to a floating clam.
	updraft(Vector3(4.0, 0.0, -38.0), Vector3(4.0, 20.0, 4.0), 10.0, &"bubbles")
	stone(Vector3(8.5, 20.0, -38.0), 2.4, 1.0, &"mush_spot", &"candy_pink")
	seed_at(&"w4_seed_bubble", Vector3(8.5, 20.0, -38.0))
	# The canopy: a broad leaf on top of the second trunk holds the shard.
	stone(Vector3(10.0, 29.5, -52.0), 4.0, 1.0, &"kelp", &"lime_pop")
	stone(Vector3(10.0, 30.9, -52.0), 2.4, 1.4, &"stone_light", &"gold")
	shard_at(&"w4_shard_kelp", Vector3(10.0, 30.9, -52.0))
	critter(Jellyfloat, Vector3(2.0, 24.0, -46.0))
	for i in 40:
		Whimsy.kelp(self, P(Vector3(_rng.randf_range(-26.0, 26.0), 0.0, _rng.randf_range(-70.0, -10.0))), _rng.randf_range(10.0, 24.0))
	Ambient.fish(self, P(Vector3(0.0, 12.0, -40.0)), 10.0, 10, &"slime_blue")
	Ambient.bubbles(self, P(Vector3(0.0, 2.0, -40.0)), Vector3(30.0, 2.0, 40.0), 40)
	add_capture_point("kelp", Vector3(50.0, 20.0, 30.0), Vector3(90.0, 12.0, 0.0))


# --- West: Shipwreck ---------------------------------------------------------------------------------

func _shipwreck() -> void:
	region(Vector3(-40.0, 0.0, 40.0), 90.0)
	checkpoint(&"w4_cp_ship", Vector3(0.0, 0.0, -5.0))
	sign_post(Vector3(6.0, 0.0, -6.0), "Turtles ferry you over the trench.\nDon't fall in!")
	# Sea turtles swim back and forth over the trench.
	for spec: Array in [[-7.0, 0.0], [7.0, 3.5]]:
		var m := mover(Vector3(spec[0] as float, 0.0, -12.0), Vector3(5.0, 1.0, 5.0), Vector3(0.0, 0.0, -17.0), 7.5, &"kelp", spec[1] as float)
		Whimsy.turtle_on(m, Vector3(5.0, 1.0, 5.0))
	# The ship on the far bank.
	plat(Vector3(0.0, 4.0, -52.0), Vector2(12.0, 30.0), &"bark_mid", 0)
	for side: float in [-1.0, 1.0]:
		ledge(Vector3(6.5 * side, 5.2, -52.0), Vector3(1.0, 1.2, 30.0), &"wood_warm")
	ramp(Vector3(0.0, 0.0, -32.5), 6.0, 4.0, 6.0, &"wood_plank")
	for z: float in [-46.0, -60.0]:
		Kit.pillar(self, P(Vector3(0.0, 21.0, z)), 0.45, 17.0, &"bark_mid", &"", Layers.WORLD)
	ledge(Vector3(0.0, 6.5, -42.0), Vector3(2.4, 2.5, 2.4), &"wood_warm")
	ledge(Vector3(0.0, 9.0, -46.0), Vector3(7.0, 0.6, 1.6), &"wood_plank")
	for i in 4:
		var c := crumble(Vector3(0.0, 11.0 + i * 0.6, -48.5 - i * 2.8), Vector3(2.6, 0.6, 2.6), CrumblePlatform.Look.ROCK)
		c.name = "Plank%d" % i
	ledge(Vector3(0.0, 13.0, -60.0), Vector3(7.0, 0.6, 1.6), &"wood_plank")
	ledge(Vector3(3.6, 15.5, -60.0), Vector3(2.0, 0.5, 2.0), &"wood_plank")
	stone(Vector3(0.0, 18.0, -60.0), 2.2, 1.0, &"wood_warm", &"wood_plank")
	shard_at(&"w4_shard_ship", Vector3(0.0, 18.0, -60.0))
	var flag := Props.spawn(self, &"flag", P(Vector3(0.0, 21.0, -46.0)), Y(), 2.0, false)
	flag.name = "ShipFlag"
	var roller := SnowballRoller.new()
	roller.look = &"urchin"
	roller.radius = 0.8
	roller.interval = 3.6
	roller.speed = 6.0
	roller.start = P(Vector3(2.5, 4.0, -66.0))
	roller.end = P(Vector3(2.5, 4.0, -38.0))
	add_child(roller)
	chest(Vector3(-3.5, 4.0, -64.0), PI, &"w4_seed_chest")
	var mimic := critter(Mimic, Vector3(3.5, 4.0, -40.0))
	mimic.rotation.y = Y(PI)
	critter(SnapperCrab, Vector3(-2.0, 4.5, -54.0))
	alcove(Vector3(0.0, 0.0, -71.0), PI, &"wood_warm")
	seed_at(&"w4_seed_hold", Vector3(0.0, 0.0, -71.0))
	# A barrel bobbing off the bow, too far to jump (Air Dash).
	stone(Vector3(21.0, 4.5, -52.0), 1.6, 1.4, &"wood_warm", &"wood_plank")
	seed_at(&"w4_seed_barrel", Vector3(21.0, 4.5, -52.0))
	for i in 10:
		Whimsy.coral(self, P(Vector3(_rng.randf_range(-20.0, 20.0), 0.0, _rng.randf_range(-80.0, -34.0))), [&"coral_orange", &"mush_purple"][i % 2] as StringName, 1.2)
	Ambient.fish(self, P(Vector3(0.0, 10.0, -54.0)), 9.0, 8, &"sunset_orange")
	add_capture_point("ship", Vector3(-50.0, 18.0, 30.0), Vector3(-92.0, 6.0, 0.0))


# --- South: Coral Gardens ---------------------------------------------------------------------------

func _coral_gardens() -> void:
	region(Vector3(40.0, 0.0, 40.0), -90.0)
	checkpoint(&"w4_cp_coral", Vector3(-6.0, 0.0, -6.0))
	# Coral towers with a timed crystal puzzle: light all three to raise steps to a brain coral.
	var group := SwitchGroup.new()
	add_child(group)
	for spec: Array in [[-14.0, 3.0, -16.0], [14.0, 5.0, -22.0], [0.0, 7.0, -30.0]]:
		Kit.pillar(self, P(Vector3(spec[0] as float, spec[1] as float, spec[2] as float)), 2.4, spec[1] as float, &"coral_pink", &"coral_orange")
		var sw := CrystalSwitch.new()
		sw.hold = 12.0
		sw.position = P(Vector3(spec[0] as float, spec[1] as float, spec[2] as float))
		add_child(sw)
		group.add(sw)
	ledge(Vector3(-8.0, 1.5, -12.0), Vector3(3.0, 1.5, 3.0), &"coral_orange")
	ledge(Vector3(8.0, 2.5, -16.0), Vector3(3.0, 2.5, 3.0), &"coral_orange")
	ledge(Vector3(6.0, 4.0, -27.0), Vector3(3.0, 1.0, 3.0), &"coral_orange")
	var steps: Array[GhostPlatform] = []
	for i in 4:
		var g := GhostPlatform.new()
		g.size = Vector3(3.5, 0.6, 3.5)
		g.color_name = &"portal_teal"
		g.position = P(Vector3(-4.0 + i * 3.0, 9.0 + i * 2.6, -36.0 - i * 2.5))
		add_child(g)
		steps.append(g)
	var brain := SphereMesh.new()
	brain.radius = 3.0
	brain.height = 4.0
	Kit.mesh_instance(self, brain, Kit.mat(&"candy_pink", 0.03), P(Vector3(9.0, 17.0, -46.0)))
	Kit.pillar(self, P(Vector3(9.0, 18.6, -46.0)), 2.6, 1.0, &"candy_pink", &"coral_pink")
	Kit.pillar(self, P(Vector3(9.0, 17.0, -46.0)), 0.8, 17.0, &"coral_orange", &"", Layers.WORLD)
	seed_at(&"w4_seed_switch", Vector3(9.0, 18.6, -46.0))
	group.solved.connect(func() -> void:
		for g in steps:
			g.set_solid(true)
		if hud != null:
			hud.show_banner("Coral steps appear!", 2.0))
	sign_post(Vector3(4.0, 0.0, -8.0), "Light all three crystals quickly!")
	# The lagoon: dive to the bottom for a seed.
	var lc := Vector3(-20.0, 0.0, -40.0)
	for spec: Array in [[0.0, -8.5, 18.0, 1.0], [0.0, 8.5, 18.0, 1.0], [-8.5, 0.0, 1.0, 16.0], [8.5, 0.0, 1.0, 16.0]]:
		ledge(lc + Vector3(spec[0] as float, 2.5, spec[1] as float), Vector3(spec[2] as float, 2.5, spec[3] as float), &"coral_pink")
	water(lc + Vector3(0.0, 2.2, 0.0), Vector2(16.0, 16.0), 2.2)
	seed_at(&"w4_seed_lagoon", lc + Vector3(2.0, 0.0, 2.0))
	for i in 5:
		Whimsy.anemone(self, P(lc + Vector3(_rng.randf_range(-6.0, 6.0), 0.0, _rng.randf_range(-6.0, 6.0))), &"candy_pink", 0.9)
	# Anglerfish lanterns (Fireball) open a kelp-vine grotto.
	var door := alcove(Vector3(20.0, 0.0, -44.0), -PI * 0.5, &"sea_violet", &"gate") as VineGate
	seed_at(&"w4_seed_lanterns", Vector3(20.0, 0.0, -44.0))
	var lamps := SwitchGroup.new()
	add_child(lamps)
	for z: float in [-36.0, -52.0]:
		var l := CrystalSwitch.new()
		l.look = CrystalSwitch.Look.LANTERN
		l.needs = &"fireball"
		l.position = P(Vector3(16.0, 0.0, z))
		add_child(l)
		lamps.add(l)
	lamps.solved.connect(func() -> void:
		door.set_closed(false))
	for i in 24:
		Whimsy.coral(self, P(Vector3(_rng.randf_range(-28.0, 28.0), 0.0, _rng.randf_range(-60.0, -6.0))), [&"coral_pink", &"coral_orange", &"mush_purple", &"gold", &"slime_blue"][i % 5] as StringName, _rng.randf_range(0.8, 2.2))
	gloplets(Vector3(0.0, 0.0, -20.0), 10.0, [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 2.0)])
	critter(SnapperCrab, Vector3(-10.0, 0.5, -28.0))
	Ambient.fish(self, P(Vector3(0.0, 8.0, -30.0)), 10.0, 10, &"candy_pink")
	add_capture_point("coral", Vector3(-30.0, 16.0, 30.0), Vector3(0.0, 4.0, 80.0))


# --- Side spots between the routes (Build 5: "less linear") ------------------------------------------

func _side_spots() -> void:
	region(Vector3.ZERO)
	# The Clam Beds (far north-east): jellyfish pads up two rock pillars to a seed.
	var cb := Vector3(96.0, 0.0, -100.0)
	bouncer(cb + Vector3(-8.0, 0.0, -2.0), Springcap.Look.JELLY, 7.5, 12.0)
	Kit.pillar(self, cb + Vector3(0.0, 6.0, 2.0), 3.6, 6.0, &"coral_orange", &"sand_light")
	bouncer(cb + Vector3(1.0, 6.0, 2.0), Springcap.Look.JELLY, 7.5, 12.0)
	Kit.pillar(self, cb + Vector3(9.0, 12.0, -5.0), 3.2, 12.0, &"mush_purple", &"sand_light")
	seed_at(&"w4_seed_clams", cb + Vector3(9.0, 12.0, -5.0))
	for i in 8:
		var clam := SphereMesh.new()
		clam.radius = 1.0
		clam.height = 0.9
		clam.is_hemisphere = true
		Kit.mesh_instance(self, clam, Kit.mat([&"candy_pink", &"mush_spot", &"coral_orange"][i % 3] as StringName, 0.02), cb + Vector3(_rng.randf_range(-12.0, 12.0), 0.0, _rng.randf_range(-10.0, 10.0)))
	critter(SnapperCrab, cb + Vector3(-4.0, 0.5, 8.0))
	# The Sunken Statue (far west): a cracked door in its plinth hides a seed.
	var st := Vector3(-110.0, 0.0, -40.0)
	prop(&"statue_head", st + Vector3(0.0, 5.0, 0.0), 0.7, 3.5, false)
	alcove(st, PI * 0.25, &"sea_violet")
	seed_at(&"w4_seed_statue", st)
	for i in 5:
		Whimsy.anemone(self, st + Vector3(_rng.randf_range(-9.0, 9.0), 0.0, _rng.randf_range(-9.0, 9.0)), &"candy_pink", 1.2)
	Ambient.fish(self, st + Vector3(0.0, 8.0, 0.0), 8.0, 7, &"gold")
	add_capture_point("clam_beds", cb + Vector3(-22.0, 16.0, 24.0), cb)


# --- Seafloor landmarks (Build 6, Ashwin: "more dense... more buildings and Bikini Bottom themed
# things like the tar lake, a pineapple house, and a burger restaurant we can go inside") ------------
# Homages in this world's own style and with its own names and folk.

func _landmarks() -> void:
	region(Vector3.ZERO)
	_pineapple_row()
	_grill(Vector3(30.0, 0.0, -32.0))
	_tar_pits(Vector3(-70.0, 0.0, -60.0))
	_glass_dome(Vector3(26.0, 0.0, -54.0))
	_boat_lot(Vector3(24.0, 0.0, 46.0))
	for i in 4:
		Ambient.fish(self, Vector3(_rng.randf_range(-50.0, 50.0), _rng.randf_range(5.0, 12.0), _rng.randf_range(-50.0, 50.0)), 7.0, 6, [&"candy_pink", &"gold", &"slime_blue", &"lime_pop"][i] as StringName)


## Pineapple Row: a pineapple cottage, a stone-head house and a round rock house side by side.
func _pineapple_row() -> void:
	var pa := Vector3(-24.0, 0.0, -30.0)
	var key := "pineapple"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof: Array[Vector2] = []
	var pc: Array[Color] = []
	for i in 12:
		var t := float(i) / 11.0
		prof.append(Vector2(sin(t * PI * 0.92 + 0.12) * 5.2, t * 12.0))
		pc.append(Whimsy.vcol(&"sunset_orange" if i % 2 == 0 else &"gold"))
	prof[11] = Vector2(0.6, 12.0)
	var mesh := MeshInstance3D.new()
	mesh.name = key
	add_child(mesh)
	Whimsy._lathe(st, Transform3D.IDENTITY, prof, pc, 20)
	mesh.mesh = st.commit()
	mesh.material_override = Whimsy.material()
	mesh.position = pa
	var body := Kit.static_body(self, pa + Vector3(0.0, 5.5, 0.0))
	var c := CylinderShape3D.new()
	c.radius = 4.6
	c.height = 11.0
	Kit.add_shape(body, c)
	# Spiky leaf crown: broad leaves you can stand on, stepping up to the top.
	for i in 7:
		var a := float(i) / 7.0 * TAU
		var leaf := Kit.block(self, pa + Vector3(cos(a) * 3.2, 12.6 + (i % 2) * 1.6, sin(a) * 3.2), Vector3(3.6, 0.5, 1.8), &"kelp", Layers.WORLD | Layers.CAMERA_BLOCKER, &"lime_pop")
		leaf.rotation = Vector3(0.0, -a, 0.35)
	Kit.pillar(self, pa + Vector3(0.0, 15.0, 0.0), 1.6, 2.4, &"kelp", &"lime_pop")
	seed_at(&"w4_seed_pineapple", pa + Vector3(0.0, 15.0, 0.0))
	var door := CylinderMesh.new()
	door.top_radius = 1.2
	door.bottom_radius = 1.2
	door.height = 0.2
	Kit.mesh_instance(self, door, Kit.mat(&"slime_blue"), pa + Vector3(0.0, 1.4, 4.9)).rotation.x = PI * 0.5
	for spec: Array in [[2.6, 5.5], [-2.6, 7.5]]:
		var w := CylinderMesh.new()
		w.top_radius = 0.7
		w.bottom_radius = 0.7
		w.height = 0.2
		var wm := Kit.mesh_instance(self, w, Kit.mat(&"water_light"), pa + Vector3(spec[0] as float, spec[1] as float, 4.4))
		wm.rotation.x = PI * 0.5
		# Window boxes double as footholds up the side.
		ledge(pa + Vector3(spec[0] as float, (spec[1] as float) - 1.0, 5.4), Vector3(2.4, 0.5, 1.6), &"wood_warm")
	ledge(pa + Vector3(0.0, 9.5, 5.2), Vector3(2.4, 0.5, 1.6), &"wood_warm")
	# Neighbours: a stone-head house and a round rock house.
	prop(&"statue_head", pa + Vector3(-15.0, 0.0, -2.0), 0.3, 4.2)
	var rock := SphereMesh.new()
	rock.radius = 4.5
	rock.height = 6.0
	rock.is_hemisphere = true
	var rb := Kit.static_body(self, pa + Vector3(-30.0, 0.0, 0.0))
	Kit.mesh_instance(rb, rock, Kit.mat(&"stone_dark", 0.03))
	var rs := SphereShape3D.new()
	rs.radius = 4.5
	Kit.add_shape(rb, rs)
	Kit.pillar(self, pa + Vector3(-30.0, 6.5, 0.0), 0.25, 2.0, &"bark_mid")
	sign_post(pa + Vector3(6.0, 0.0, 8.0), "Pineapple Row")
	var nb := Npc.new()
	nb.npc_id = "finn"
	nb.display_name = "Finn's cousin Fern"
	nb.bubble_helmet = true
	nb.position = pa + Vector3(-8.0, 0.0, 7.0)
	add_child(nb)
	add_capture_point("pineapple_row", pa + Vector3(10.0, 12.0, 26.0), pa + Vector3(-12.0, 5.0, 0.0))


## The Salty Shell Grill: a burger joint you can walk into. Its roof is a platform with a seed.
func _grill(base: Vector3) -> void:
	var w := 18.0
	var d := 14.0
	var h := 6.0
	var wall := &"wood_plank"
	var layers := Layers.WORLD | Layers.CAMERA_BLOCKER
	Kit.block(self, base + Vector3(0.0, 0.3, 0.0), Vector3(w, 0.3, d), &"wood_warm", layers, &"")
	Kit.block(self, base + Vector3(0.0, h, -d * 0.5 + 0.5), Vector3(w, h, 1.0), wall, layers, &"")
	Kit.block(self, base + Vector3(-w * 0.5 + 0.5, h, 0.0), Vector3(1.0, h, d), wall, layers, &"")
	Kit.block(self, base + Vector3(w * 0.5 - 0.5, h, 0.0), Vector3(1.0, h, d), wall, layers, &"")
	# Front wall with a wide doorway.
	Kit.block(self, base + Vector3(-5.5, h, d * 0.5 - 0.5), Vector3(7.0, h, 1.0), wall, layers, &"")
	Kit.block(self, base + Vector3(5.5, h, d * 0.5 - 0.5), Vector3(7.0, h, 1.0), wall, layers, &"")
	Kit.block(self, base + Vector3(0.0, h, d * 0.5 - 0.5), Vector3(4.0, 1.6, 1.0), wall, layers, &"")
	Kit.block(self, base + Vector3(0.0, h + 0.8, 0.0), Vector3(w + 1.0, 0.8, d + 1.0), &"roof_red", layers, &"roof_red")
	# Big clam sign on the roof.
	var clam := SphereMesh.new()
	clam.radius = 3.0
	clam.height = 3.0
	clam.is_hemisphere = true
	var cm := Kit.mesh_instance(self, clam, Kit.mat(&"candy_pink", 0.04), base + Vector3(0.0, h + 3.8, d * 0.5 - 1.0))
	cm.rotation.x = PI * 0.5
	var title := Kit.label(self, base + Vector3(0.0, h + 2.6, d * 0.5 + 0.7), "The Salty Shell Grill", 72)
	title.modulate = Palette.color(&"gold")
	# Inside: counter, kitchen hatch, tables, a cook and a cashier.
	Kit.block(self, base + Vector3(0.0, 1.4, -2.0), Vector3(10.0, 1.1, 1.4), &"coral_orange", layers, &"wood_plank")
	for spec: Array in [[-5.5, 3.0], [5.5, 3.0], [-5.5, -0.5], [5.5, -0.5]]:
		prop(&"q_table", base + Vector3(spec[0] as float, 0.3, spec[1] as float), 0.0, 1.0)
		prop(&"q_bench", base + Vector3(spec[0] as float, 0.3, (spec[1] as float) + 1.4), 0.0, 1.0, false)
	var grill := RoundMesh.box(Vector3(3.0, 1.2, 1.2), 0.2)
	Kit.mesh_instance(self, grill, Kit.mat(&"stone_dark"), base + Vector3(-3.0, 0.9, -5.2))
	var glow := OmniLight3D.new()
	glow.light_color = Palette.color(&"sunset_orange")
	glow.light_energy = 1.4
	glow.omni_range = 6.0
	glow.position = base + Vector3(-3.0, 2.0, -5.0)
	add_child(glow)
	for spec: Array in [["barnacle", "Chef Pincer", Vector3(-3.0, 0.3, -4.0)], ["coralie", "Cashier Coral", Vector3(2.0, 0.3, -3.2)]]:
		var npc := Npc.new()
		npc.npc_id = str(spec[0])
		npc.display_name = str(spec[1])
		npc.bubble_helmet = true
		npc.position = base + (spec[2] as Vector3)
		add_child(npc)
	chest(base + Vector3(6.5, 0.3, -5.0), PI, &"w4_seed_grill")
	# Barrels up the side to the roof.
	ledge(base + Vector3(w * 0.5 + 2.0, 1.5, 4.0), Vector3(2.6, 1.5, 2.6), &"wood_warm")
	ledge(base + Vector3(w * 0.5 + 2.0, 4.0, 0.0), Vector3(2.6, 1.0, 2.6), &"wood_warm")
	heart_at(base + Vector3(0.0, h + 1.6, -3.0))
	add_capture_point("grill", base + Vector3(-8.0, 9.0, 24.0), base + Vector3(0.0, 3.0, 0.0))
	add_capture_point("grill_inside", base + Vector3(6.0, 3.5, 5.5), base + Vector3(-3.0, 1.5, -4.0))


## The tar pits: sticky, slow-going tar with stepping stones and a seed on the far rock.
func _tar_pits(c: Vector3) -> void:
	for spec: Array in [[0.0, 0.0, 9.0], [10.0, 6.0, 6.0], [-9.0, 7.0, 6.0], [4.0, -9.0, 5.5]]:
		var q := Quicksand.new()
		q.look = &"tar"
		q.radius = spec[2] as float
		q.position = c + Vector3(spec[0] as float, 0.0, spec[1] as float)
		add_child(q)
	for spec: Array in [[-4.0, 1.2, 4.0], [3.0, 1.6, -1.0], [9.0, 2.2, 5.0], [12.0, 3.0, -2.0]]:
		stone(c + Vector3(spec[0] as float, spec[1] as float, spec[2] as float), 2.0, 1.4, &"stone_dark", &"sea_violet")
	Kit.pillar(self, c + Vector3(16.0, 4.2, -7.0), 2.4, 4.2, &"stone_dark", &"sand_light")
	seed_at(&"w4_seed_tar", c + Vector3(16.0, 4.2, -7.0))
	sign_post(c + Vector3(-12.0, 0.0, -10.0), "Tar Pits: sticky! Hop the rocks.")
	Ambient.bubbles(self, c + Vector3(0.0, 0.5, 0.0), Vector3(14.0, 1.0, 14.0), 20)


## A glass dome with a little tree and lawn inside; climb the frame to sit on top.
func _glass_dome(c: Vector3) -> void:
	disc(c + Vector3(0.0, 0.4, 0.0), 8.0, &"stone_light", &"grass_mid", 30)
	var glass := SphereMesh.new()
	glass.radius = 8.0
	glass.height = 16.0
	glass.is_hemisphere = true
	Kit.mesh_instance(self, glass, Fx.fx_mat(Color(Palette.color(&"bubble"), 0.18)), c + Vector3(0.0, 0.4, 0.0))
	var body := Kit.static_body(self, c + Vector3(0.0, 0.4, 0.0))
	var sph := SphereShape3D.new()
	sph.radius = 8.0
	Kit.add_shape(body, sph)
	Whimsy.tree(self, c + Vector3(1.0, 0.4, 1.0), &"autumn", 1.1)
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.4
		var rib := TorusMesh.new()
		rib.inner_radius = 7.9
		rib.outer_radius = 8.2
		var r := Kit.mesh_instance(self, rib, Kit.mat(&"slime_blue"), c + Vector3(0.0, 0.4, 0.0))
		r.rotation = Vector3(PI * 0.5, a, 0.0)
	for k in 3:
		ledge(c + Vector3(-10.0 + k * 1.0, 2.0 + k * 2.5, -3.0 - k * 2.0), Vector3(2.6, 0.5, 2.6), &"slime_blue")
	seed_at(&"w4_seed_dome", c + Vector3(0.0, 8.4, 0.0))


## A lot of parked boat-cars to hop across.
func _boat_lot(c: Vector3) -> void:
	var cols: Array[StringName] = [&"roof_red", &"slime_blue", &"gold", &"mush_purple", &"lime_pop"]
	for i in 6:
		var p := c + Vector3((i % 3) * 7.0 - 7.0, 0.0, (i / 3) * 8.0 - 4.0)
		var hull := Kit.block(self, p + Vector3(0.0, 1.4 + (i % 2) * 0.8, 0.0), Vector3(3.6, 1.4 + (i % 2) * 0.8, 5.5), cols[i % cols.size()], Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
		hull.rotation.y = 0.2 * (i % 3) - 0.2
		var bubble := SphereMesh.new()
		bubble.radius = 1.4
		bubble.height = 1.6
		bubble.is_hemisphere = true
		Kit.mesh_instance(self, bubble, Fx.fx_mat(Color(Palette.color(&"bubble"), 0.4)), p + Vector3(0.0, 1.4 + (i % 2) * 0.8, 0.6))
	sign_post(c + Vector3(-11.0, 0.0, 0.0), "Bubble Boat Lot", PI * 0.5)


func _on_shards_complete() -> void:
	_great_bubble.set_enabled(true)
	if hud != null:
		hud.show_banner("The Great Bubble wakes! Ride it up to the Grand Star!", 2.6)
	AudioDirector.play(&"warp")
