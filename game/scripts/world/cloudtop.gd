class_name Cloudtop
extends OpenWorld
## World 2, Cloudtop Steps (Build 4): a pure platforming world among floating islands. From the
## Sky Plaza, four routes lead out in any order:
##   North  Windy Heights   - wind columns carry you up between islands; Batlings swoop
##   East   Puffball Path   - clouds that vanish under your feet; Jellyfloats to bounce off
##   West   Windmill Isles  - spinning sails and drifting platforms; Hoppies charge
##   South  Bounce Gardens  - bouncy clouds up to treasure (and one Mimic)
## Each of the first three hides a Star Shard. With all three, a stairway of light appears up the
## Star Spire to the Grand Star. Falling into the clouds costs ½ heart.

const WORLD := &"world_02"
const SPIRE := Vector3(0.0, 0.0, -6.0)

var _spire_steps: Array[GhostPlatform] = []


func configure() -> void:
	world_id = WORLD
	# Build 5: a candy-bright sky world, deep blue above, pink-lilac at the horizon.
	sky_top = Color(0.18, 0.48, 0.98)
	sky_horizon = Color(0.98, 0.82, 0.95)
	sky_bottom = Color(1.0, 0.9, 0.98)
	cloud_cover = 0.5
	cloud_shade = Color(0.86, 0.78, 0.98)
	sun_energy = 1.12
	fog_color = Color(0.96, 0.88, 0.98)
	fog_begin = 100.0
	fog_end = 340.0
	tree_kinds = [&"blossom", &"teal", &"blossom", &"lime", &"violet", &"blossom", &"gold"]


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w2_entrance"
	music = &"cloudtop"
	floor_y = -30.0
	kill_y = -60.0
	_rng.seed = 202
	_cloud_sea()
	_plaza()
	_windy_heights()
	_puffball_path()
	_windmill_isles()
	_bounce_gardens()
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life()


# --- Helpers ----------------------------------------------------------------------------------

## A floating island: a grassy disc with a rocky underside tapering away below it.
func island(top_local: Vector3, radius: float, grass: int = -1) -> void:
	var top := P(top_local)
	Kit.pillar(self, top, radius, 2.5, &"bark_mid", &"grass_mid")
	var under := CylinderMesh.new()
	under.top_radius = radius * 0.95
	under.bottom_radius = radius * 0.15
	under.height = radius * 1.4
	under.radial_segments = 20
	Kit.mesh_instance(self, under, Kit.mat(&"stone_dark", 0.04), top + Vector3(0.0, -2.5 - radius * 0.7, 0.0))
	if grass != 0:
		_add_grass_disc(top, radius * 0.9, grass if grass > 0 else int(radius * radius * 0.5))


## A small decorative floating island (world position).
func island_at(top: Vector3, radius: float) -> void:
	Kit.pillar(self, top, radius, 2.0, &"bark_mid", &"grass_mid")
	var under := CylinderMesh.new()
	under.top_radius = radius * 0.95
	under.bottom_radius = radius * 0.15
	under.height = radius * 1.4
	under.radial_segments = 16
	Kit.mesh_instance(self, under, Kit.mat(&"stone_dark", 0.04), top + Vector3(0.0, -2.0 - radius * 0.7, 0.0))


## A solid cloud you can stand on.
func cloud(top_local: Vector3, size: Vector2) -> void:
	var top := P(top_local)
	var s := S(Vector3(size.x, 1.2, size.y))
	Kit.block(self, top, s, &"foam")
	for i in 4:
		var off := Vector3(_rng.randf_range(-0.4, 0.4) * s.x, -0.6, _rng.randf_range(-0.4, 0.4) * s.z)
		Kit.blob(self, top + off, minf(s.x, s.z) * 0.35, &"cloth_cream")


# --- Sea of clouds below ------------------------------------------------------------------------

func _cloud_sea() -> void:
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(600.0, 10.0, 600.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(0.0, -34.0, 0.0)
	add_child(pit)
	for i in 70:
		var p := Vector3(_rng.randf_range(-260.0, 260.0), _rng.randf_range(-34.0, -26.0), _rng.randf_range(-260.0, 260.0))
		Props.spawn(self, &"cloud_big" if i % 2 == 0 else &"cloud_small", p, _rng.randf() * TAU, _rng.randf_range(3.0, 5.0), false)
	for i in 10:
		var a := float(i) / 10.0 * TAU
		var r := _rng.randf_range(180.0, 240.0)
		var top := Vector3(cos(a) * r, _rng.randf_range(-10.0, 30.0), sin(a) * r)
		var rad := _rng.randf_range(8.0, 16.0)
		Kit.pillar(self, top, rad, 3.0, &"bark_mid", &"grass_mid", 0)
		var under := CylinderMesh.new()
		under.top_radius = rad
		under.bottom_radius = 1.0
		under.height = rad * 1.6
		Kit.mesh_instance(self, under, Kit.mat(&"stone_dark"), top + Vector3(0.0, -3.0 - rad * 0.8, 0.0))
		Props.spawn(self, &"tree_oak", top, a, 2.5, false)
	birds(Vector3.ZERO, 70.0, 30.0, 8)
	# Build 5: floating mushroom islets, rainbows and stardust between the islands.
	var caps: Array[StringName] = [&"pink", &"teal", &"purple", &"gold", &"blue"]
	for i in 12:
		var a := float(i) / 12.0 * TAU + 0.13
		var c := Vector3(cos(a) * _rng.randf_range(110.0, 160.0), _rng.randf_range(-8.0, 26.0), sin(a) * _rng.randf_range(110.0, 160.0))
		island_at(c, _rng.randf_range(5.0, 8.0))
		Whimsy.mushroom(self, c, _rng.randf_range(6.0, 12.0), _rng.randf_range(4.0, 7.0), caps[i % caps.size()])
	Whimsy.rainbow(self, Vector3(-60.0, -30.0, -120.0), 110.0, 0.5)
	Whimsy.rainbow(self, Vector3(120.0, -30.0, 40.0), 80.0, -1.2)
	Ambient.sparkles(self, Vector3(0.0, 10.0, 0.0), Vector3(240.0, 30.0, 240.0), 160)


# --- Sky Plaza (centre) -------------------------------------------------------------------------

func _plaza() -> void:
	region(Vector3.ZERO)
	island(Vector3.ZERO, 26.0)
	add_spawn(&"w2_entrance", Vector3(0.0, 0.0, 14.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 21.0)
	add_child(exit)
	checkpoint(&"w2_cp_plaza", Vector3(-8.0, 0.0, 12.0))
	sign_post(Vector3(6.0, 0.0, 10.0), "Find 3 Star Shards and a stairway\nof light climbs the Star Spire.")
	sign_post(Vector3(-4.0, 0.0, -20.0), "North: Windy Heights")
	sign_post(Vector3(20.0, 0.0, -4.0), "East: Puffball Path", -PI * 0.5)
	sign_post(Vector3(-20.0, 0.0, 4.0), "West: Windmill Isles", PI * 0.5)
	sign_post(Vector3(4.0, 0.0, 20.0), "South: Bounce Gardens", PI)
	# The Star Spire: a tall pillar; the stairway of light appears with 3 shards.
	Kit.pillar(self, SPIRE + Vector3(0.0, 26.0, 0.0), 3.0, 26.0, &"stone_light", &"gold")
	for i in 10:
		var a := float(i) / 10.0 * TAU * 1.25
		var step := GhostPlatform.new()
		step.size = Vector3(4.5, 0.6, 4.5)
		step.color_name = &"portal_teal"
		step.position = SPIRE + Vector3(cos(a) * 7.0, 2.6 + i * 2.6, sin(a) * 7.0)
		add_child(step)
		_spire_steps.append(step)
	var star := GoalStar.new()
	star.world_id = WORLD
	star.position = SPIRE + Vector3(0.0, 26.0, 0.0)
	add_child(star)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		prop(&"column", Vector3(cos(a) * 12.0, 0.0, -6.0 + sin(a) * 12.0), a, 1.6)
	tree_ring(Vector3.ZERO, 22.0, 18, [&"tree_oak", &"tree_default", &"tree_fat"], 1.1)
	heart_bush(Vector3(12.0, 0.0, 12.0))
	scatter(Vector3.ZERO, Vector2(18.0, 18.0), 26, [&"bush", &"flower_yellow", &"flower_purple", &"mushroom_red_group"], 10.0)
	animals(Bunny, Vector3.ZERO, 18.0, 5)
	butterflies(Vector3.ZERO, 16.0, 10)
	for spec: Array in [[-14.0, -14.0, &"candy_pink"], [15.0, 12.0, &"gold"], [-16.0, 14.0, &"slime_blue"]]:
		Whimsy.flower(self, Vector3(spec[0] as float, 0.0, spec[1] as float), 3.0, 2.0, spec[2] as StringName)
	for spec: Array in [[9.0, -16.0, &"crystal_violet"], [-10.0, -2.0, &"portal_teal"]]:
		Whimsy.crystal(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as StringName, 1.2)
	add_capture_point("plaza", Vector3(26.0, 18.0, 34.0), Vector3(0.0, 8.0, -6.0))


# --- North: Windy Heights (wind columns, Batlings) ----------------------------------------------

func _windy_heights() -> void:
	region(Vector3(0.0, 0.0, -26.0))
	cloud(Vector3(0.0, 0.0, -6.0), Vector2(8.0, 10.0))
	island(Vector3(0.0, 0.0, -22.0), 9.0)
	updraft(Vector3(0.0, -6.0, -36.0), Vector3(6.0, 16.0, 6.0), 10.0)
	island(Vector3(-4.0, 8.0, -50.0), 8.0)
	critter(Batling, Vector3(-4.0, 13.0, -50.0))
	updraft(Vector3(8.0, 1.0, -60.0), Vector3(6.0, 18.0, 6.0), 10.0)
	island(Vector3(12.0, 16.0, -72.0), 8.0)
	critter(Batling, Vector3(10.0, 21.0, -70.0))
	critter(Batling, Vector3(16.0, 20.0, -76.0))
	cloud(Vector3(2.0, 16.0, -84.0), Vector2(7.0, 7.0))
	island(Vector3(-8.0, 18.0, -94.0), 9.0)
	checkpoint(&"w2_cp_heights", Vector3(-8.0, 18.0, -90.0))
	stone(Vector3(-8.0, 19.5, -98.0), 3.0, 1.6, &"stone_light", &"gold")
	shard_at(&"w2_shard_heights", Vector3(-8.0, 19.5, -98.0))
	sign_post(Vector3(3.0, 0.0, -18.0), "Jump into the wind and let it lift you!")
	# A side island hides a seed in the lee of a rock.
	island(Vector3(-24.0, 6.0, -60.0), 6.0)
	cloud(Vector3(-14.0, 7.0, -55.0), Vector2(5.0, 5.0))
	prop(&"rock_tall_a", Vector3(-24.0, 6.0, -62.0), 0.0, 1.5)
	seed_at(&"w2_seed_lee", Vector3(-24.0, 6.0, -58.0))
	seed_at(&"w2_seed_updraft", Vector3(8.0, 14.0, -60.0))
	for spec: Vector3 in [Vector3(4.0, 0.0, -19.0), Vector3(0.0, 8.0, -47.0), Vector3(16.0, 16.0, -69.0), Vector3(-4.0, 18.0, -91.0)]:
		prop(&"tree_default", spec, 0.0, 1.0)
	add_capture_point("heights", Vector3(30.0, 30.0, -30.0), Vector3(0.0, 10.0, -90.0))


# --- East: Puffball Path (vanishing clouds, Jellyfloats) ----------------------------------------

func _puffball_path() -> void:
	region(Vector3(26.0, 0.0, 0.0), -90.0)
	for i in 6:
		var z := -6.0 - i * 7.5
		var x := sin(i * 1.3) * 5.0
		crumble(Vector3(x, 0.0 + i * 0.8, z), Vector3(5.5, 0.8, 5.5))
	island(Vector3(0.0, 5.0, -56.0), 9.0)
	checkpoint(&"w2_cp_puffball", Vector3(0.0, 5.0, -52.0))
	critter(Jellyfloat, Vector3(-6.0, 9.0, -66.0))
	critter(Jellyfloat, Vector3(6.0, 11.0, -72.0))
	sign_post(Vector3(-4.0, 5.0, -50.0), "Plunge onto a Jellyfloat\nto bounce up high!")
	cloud(Vector3(0.0, 5.0, -70.0), Vector2(6.0, 6.0))
	for i in 5:
		crumble(Vector3(-4.0 + i * 2.0, 8.0 + i * 1.6, -78.0 - i * 6.5), Vector3(5.0, 0.8, 5.0))
	island(Vector3(4.0, 16.0, -112.0), 8.0)
	stone(Vector3(4.0, 17.5, -116.0), 3.0, 1.6, &"stone_light", &"gold")
	shard_at(&"w2_shard_puffball", Vector3(4.0, 17.5, -116.0))
	critter(Batling, Vector3(0.0, 22.0, -108.0))
	# Under the big island: a hidden ledge with a seed (drop off the back edge).
	cloud(Vector3(4.0, 8.0, -124.0), Vector2(6.0, 6.0))
	seed_at(&"w2_seed_under", Vector3(4.0, 8.0, -124.0))
	seed_at(&"w2_seed_puff", Vector3(0.0, 13.0, -70.0))
	add_capture_point("puffball", Vector3(50.0, 24.0, 30.0), Vector3(90.0, 8.0, 0.0))


# --- West: Windmill Isles (spinning sails, drifting platforms, Hoppies) -------------------------

func _windmill_isles() -> void:
	region(Vector3(-26.0, 0.0, 0.0), 90.0)
	cloud(Vector3(0.0, 0.0, -6.0), Vector2(8.0, 10.0))
	island(Vector3(0.0, 0.0, -24.0), 10.0)
	critter(Hoppy, Vector3(3.0, 0.5, -24.0))
	prop(&"windmill", Vector3(-5.0, 0.0, -27.0), 0.0, 1.0)
	# Spinning sails: ride the turning bars across.
	mover(Vector3(0.0, 0.5, -44.0), Vector3(16.0, 1.0, 3.0), Vector3.ZERO, 6.0, &"wood_plank", 0.0, 0.5)
	island(Vector3(0.0, 1.0, -62.0), 9.0)
	checkpoint(&"w2_cp_windmill", Vector3(0.0, 1.0, -58.0))
	critter(Hoppy, Vector3(-3.0, 1.5, -64.0))
	critter(Hoppy, Vector3(4.0, 1.5, -66.0))
	mover(Vector3(0.0, 2.0, -80.0), Vector3(6.0, 1.0, 6.0), Vector3(14.0, 0.0, 0.0), 6.0, &"wood_plank")
	mover(Vector3(0.0, 4.0, -92.0), Vector3(6.0, 1.0, 6.0), Vector3(0.0, 4.0, 0.0), 5.0, &"wood_plank")
	mover(Vector3(0.0, 6.0, -104.0), Vector3(16.0, 1.0, 3.0), Vector3.ZERO, 6.0, &"wood_plank", 0.0, -0.45)
	island(Vector3(0.0, 8.0, -122.0), 9.0)
	prop(&"windmill", Vector3(5.0, 8.0, -126.0), PI, 1.2)
	stone(Vector3(-3.0, 9.5, -124.0), 3.0, 1.6, &"stone_light", &"gold")
	shard_at(&"w2_shard_windmill", Vector3(-3.0, 9.5, -124.0))
	chest(Vector3(6.0, 8.0, -117.0), PI, &"w2_seed_chest")
	seed_at(&"w2_seed_sails", Vector3(0.0, 5.0, -44.0))
	add_capture_point("windmill", Vector3(-40.0, 22.0, 26.0), Vector3(-90.0, 4.0, 0.0))


# --- South: Bounce Gardens (bouncy clouds, treasure, a Mimic) -----------------------------------

func _bounce_gardens() -> void:
	region(Vector3(0.0, 0.0, 26.0), 180.0)
	island(Vector3(0.0, 0.0, -18.0), 12.0)
	heart_bush(Vector3(6.0, 0.0, -16.0))
	bouncer(Vector3(-4.0, 0.0, -24.0), Springcap.Look.CLOUD, 7.0, 12.0)
	island(Vector3(-10.0, 9.0, -38.0), 7.0)
	bouncer(Vector3(-10.0, 9.0, -40.0), Springcap.Look.CLOUD, 7.0, 12.0)
	island(Vector3(4.0, 17.0, -50.0), 7.0)
	chest(Vector3(4.0, 17.0, -52.0), 0.0, &"w2_seed_garden")
	var mimic := critter(Mimic, Vector3(8.0, 17.0, -48.0))
	mimic.rotation.y = Y(0.3)
	bouncer(Vector3(12.0, 0.0, -30.0), Springcap.Look.CLOUD, 7.0, 12.0)
	island(Vector3(18.0, 8.0, -44.0), 6.0)
	seed_at(&"w2_seed_bounce", Vector3(18.0, 8.0, -44.0))
	sign_post(Vector3(-6.0, 0.0, -12.0), "Bouncy clouds! Plunge onto them\nto go even higher.")
	butterflies(Vector3(0.0, 2.0, -18.0), 10.0, 6)
	add_capture_point("gardens", Vector3(28.0, 24.0, 72.0), Vector3(0.0, 8.0, 60.0))


func _on_shards_complete() -> void:
	for i in _spire_steps.size():
		var step := _spire_steps[i]
		get_tree().create_timer(0.15 * i).timeout.connect(func() -> void:
			if is_instance_valid(step):
				step.set_solid(true)
				AudioDirector.play(&"ui_blip", -6.0, 1.0 + i * 0.05))
	if hud != null:
		hud.show_banner("A stairway of light climbs the Star Spire!", 2.4)
