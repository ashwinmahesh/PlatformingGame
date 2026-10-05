class_name Bubbleton
extends OpenWorld
## World 4, Bubbleton Reef (Build 5, Ashwin: "one of the levels based on Bikini Bottom", walking
## and jumping normally): a goofy little town on the seafloor under drifting sky-flowers, with
## its own folk in bubble helmets. A pure platforming world. Four routes from the town square:
##   North  Jellyfish Fields - bounce on jellyfish up coral terraces; Jellyfloats drift about
##   East   Kelp Forest      - leaf ledges spiral up giant kelp; bubble columns lift you
##   West   Shipwreck        - ride sea turtles over the trench to an old ship; climb the masts
##   South  Coral Gardens    - a timed crystal puzzle, a lagoon to dive in, anglerfish lanterns
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
	regions = {"town": Vector3.ZERO, "jellyfish": Vector3(0.0, 0.0, -90.0), "kelp": Vector3(80.0, 0.0, 0.0), "ship": Vector3(-90.0, 0.0, 0.0), "coral": Vector3(0.0, 0.0, 70.0)}
	_seafloor()
	_town()
	_jellyfish_fields()
	_kelp_forest()
	_shipwreck()
	_coral_gardens()
	_side_spots()
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life(&"kelp")


# --- Seafloor, reef walls, the surface overhead ----------------------------------------------------

func _seafloor() -> void:
	var trench := Rect2(-72.0, -22.0, 22.0, 44.0)
	ground(Rect2(-150.0, -150.0, 300.0, 300.0), [trench], 0.0, 20.0, &"stone_dark", &"sand_light", 0.02)
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(22.0, 4.0, 44.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(-61.0, -14.0, 0.0)
	add_child(pit)
	Kit.block(self, Vector3(-61.0, -18.0, 0.0), Vector3(22.0, 2.0, 44.0), &"ink_navy", Layers.WORLD, &"")
	for i in 8:
		Whimsy.anemone(self, Vector3(-61.0 + _rng.randf_range(-9.0, 9.0), -18.0, _rng.randf_range(-20.0, 20.0)), &"portal_teal", 1.5)
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
	if p.x > -76.0 and p.x < -46.0 and absf(p.z) < 26.0:
		return true
	for c: Vector3 in [Vector3.ZERO, Vector3(0.0, 0.0, -90.0), Vector3(80.0, 0.0, 0.0), Vector3(-100.0, 0.0, 0.0), Vector3(0.0, 0.0, 70.0), Vector3(60.0, 0.0, 62.0), Vector3(-62.0, 0.0, 70.0)]:
		if Vector2(p.x - c.x, p.z - c.z).length() < 36.0:
			return true
	return absf(p.x) < 10.0 or absf(p.z) < 8.0


# --- Bubbleton (centre) ----------------------------------------------------------------------------

func _town() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w4_entrance", Vector3(0.0, 0.0, 22.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 30.0)
	add_child(exit)
	checkpoint(&"w4_cp_town", Vector3(-8.0, 0.0, 18.0))
	sign_post(Vector3(6.0, 0.0, 16.0), "Bring 3 Star Shards to wake the\nGreat Bubble in the square!")
	sign_post(Vector3(4.0, 0.0, -26.0), "North: Jellyfish Fields")
	sign_post(Vector3(28.0, 0.0, -2.0), "East: Kelp Forest", -PI * 0.5)
	sign_post(Vector3(-28.0, 0.0, 4.0), "West: Shipwreck", PI * 0.5)
	sign_post(Vector3(4.0, 0.0, 30.0), "South: Coral Gardens", PI)
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
	Whimsy.shell_house(self, Vector3(-22.0, 0.0, -10.0), deg_to_rad(70.0), &"coral_pink")
	Whimsy.shell_house(self, Vector3(23.0, 0.0, -14.0), deg_to_rad(-60.0), &"slime_blue", 0.9)
	Whimsy.shell_house(self, Vector3(-21.0, 0.0, 17.0), deg_to_rad(120.0), &"mush_purple", 0.85)
	_diner(Vector3(20.0, 0.0, 14.0))
	for spec: Array in [["barnacle", "Captain Barnacle", Vector3(5.0, 0.0, 9.0)], ["coralie", "Coralie", Vector3(14.0, 0.0, 9.0)], ["finn", "Finn", Vector3(-10.0, 0.0, -18.0)]]:
		var npc := Npc.new()
		npc.npc_id = str(spec[0])
		npc.display_name = str(spec[1])
		npc.bubble_helmet = true
		npc.position = spec[2] as Vector3
		add_child(npc)
	var path := RoundMesh.box(Vector3(5.0, 0.06, 70.0), 0.03)
	Kit.mesh_instance(self, path, Kit.mat(&"sand_mid"), Vector3(0.0, 0.03, 0.0))
	var cross := RoundMesh.box(Vector3(70.0, 0.06, 5.0), 0.03)
	Kit.mesh_instance(self, cross, Kit.mat(&"sand_mid"), Vector3(0.0, 0.03, 4.0))
	for z: float in [12.0, -16.0]:
		for x: float in [-4.0, 4.0]:
			Whimsy.lamp(self, Vector3(x, 0.0, z), x < 0.0)
	Whimsy.bunting(self, Vector3(-4.0, 3.0, 12.0), Vector3(4.0, 3.0, 12.0), 0.5)
	for i in 14:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(8.0, 30.0)
		var s := MeshInstance3D.new()
		s.mesh = GoalStar.star_mesh(0.5, 0.22, 0.08)
		s.material_override = Kit.mat([&"coral_orange", &"candy_pink", &"gold"][i % 3] as StringName, 0.01)
		s.position = Vector3(cos(a) * r, 0.06, sin(a) * r)
		s.rotation = Vector3(-PI * 0.5, 0.0, _rng.randf() * TAU)
		add_child(s)
	for spec: Array in [[-12.0, -2.0, &"coral_pink"], [12.0, -2.0, &"coral_orange"], [-14.0, 6.0, &"mush_purple"], [15.0, 4.0, &"gold"]]:
		Whimsy.coral(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as StringName, 1.3)
	heart_bush(Vector3(-16.0, 0.0, 26.0))
	Ambient.bubbles(self, LIFT + Vector3(0.0, 1.0, 0.0), Vector3(10.0, 2.0, 10.0), 30)
	Ambient.fish(self, Vector3(0.0, 9.0, 0.0), 14.0, 10, &"gold")
	sparkles(Vector3(0.0, 4.0, 0.0), Vector3(50.0, 8.0, 50.0), 40)
	add_capture_point("town", Vector3(24.0, 16.0, 40.0), Vector3(0.0, 4.0, -6.0))
	add_capture_point("star_flower", LIFT + Vector3(-10.0, STAR_Y + 8.0, 16.0), LIFT + Vector3(9.0, STAR_Y, 0.0))


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
	region(Vector3(0.0, 0.0, -40.0))
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
	region(Vector3(40.0, 0.0, 0.0), -90.0)
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
	region(Vector3(-40.0, 0.0, 0.0), 90.0)
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
	region(Vector3(0.0, 0.0, 40.0), 180.0)
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
	# The Clam Beds: jellyfish pads up two rock pillars to a seed.
	bouncer(Vector3(52.0, 0.0, 60.0), Springcap.Look.JELLY, 7.5, 12.0)
	Kit.pillar(self, Vector3(60.0, 6.0, 64.0), 3.6, 6.0, &"coral_orange", &"sand_light")
	bouncer(Vector3(61.0, 6.0, 64.0), Springcap.Look.JELLY, 7.5, 12.0)
	Kit.pillar(self, Vector3(69.0, 12.0, 57.0), 3.2, 12.0, &"mush_purple", &"sand_light")
	seed_at(&"w4_seed_clams", Vector3(69.0, 12.0, 57.0))
	for i in 8:
		var clam := SphereMesh.new()
		clam.radius = 1.0
		clam.height = 0.9
		clam.is_hemisphere = true
		Kit.mesh_instance(self, clam, Kit.mat([&"candy_pink", &"mush_spot", &"coral_orange"][i % 3] as StringName, 0.02), Vector3(48.0 + _rng.randf_range(0.0, 24.0), 0.0, 52.0 + _rng.randf_range(0.0, 20.0)))
	critter(SnapperCrab, Vector3(56.0, 0.5, 70.0))
	# The Sunken Statue: a cracked door in its plinth hides a seed.
	prop(&"statue_head", Vector3(-62.0, 5.0, 70.0), 0.7, 3.5, false)
	alcove(Vector3(-62.0, 0.0, 70.0), PI * 0.25, &"sea_violet")
	seed_at(&"w4_seed_statue", Vector3(-62.0, 0.0, 70.0))
	for i in 5:
		Whimsy.anemone(self, Vector3(-62.0 + _rng.randf_range(-9.0, 9.0), 0.0, 70.0 + _rng.randf_range(-9.0, 9.0)), &"candy_pink", 1.2)
	Ambient.fish(self, Vector3(-62.0, 8.0, 70.0), 8.0, 7, &"gold")
	add_capture_point("clam_beds", Vector3(40.0, 16.0, 84.0), Vector3(62.0, 6.0, 60.0))


func _on_shards_complete() -> void:
	_great_bubble.set_enabled(true)
	if hud != null:
		hud.show_banner("The Great Bubble wakes! Ride it up to the Grand Star!", 2.6)
	AudioDirector.play(&"warp")
