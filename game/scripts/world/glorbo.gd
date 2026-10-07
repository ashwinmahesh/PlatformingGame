class_name Glorbo
extends BossWorld
## World 7, Planet Glorbo (Build 7; Ashwin: "an alien world with weird plants and colors"). A
## candy-coloured moon under a violet sky: a deep crater bowl round a lake of glowing goo, a rim
## plateau all the way round it, and the Orbit Walk, a ring of floating decks high over the crater.
##   Crater floor - the Landing Pad (south), Gloop Lake and its island, the Bloomstalk spire (west)
##                  and the Hollow Meteor (north, a secret)
##   Rim          - Zorp's dome village (north), the Glass Lab and the Bloom Gate (east), the
##                  Antenna Tower (south-west) and the dish field (south)
##   Orbit Walk   - Starport, Comet Deck, Moon Garden and the Saucer, joined by bridges and a
##                  floating ferry, with stepping-stone asteroids up to the Crown Asteroid
## Its new puzzle is the bloom-bud (BloomPad): hit one and it unfurls into a platform for a while.
## Its other two are mirrors (the Glass Lab) and a thunder dynamo (the Antenna Tower's steps).

const WORLD := &"world_07"
const RIM := 10.0
const CRATER := 60.0
const LAKE := 15.0
const ORBIT := 24.0
const ARENA := Vector3(88.0, RIM, 0.0)
const ARENA_R := 16.0
const WALL_H := 16.0
const SPIRE := Vector3(-44.0, 0.0, 0.0)
const SPIRE_TOP := 17.4
const CROWN := Vector3(0.0, 32.0, 0.0)
const TOWER := Vector3(-84.0, RIM, 44.0)
const STARPORT := Vector3(-36.0, ORBIT, -36.0)
const COMET := Vector3(36.0, ORBIT, -36.0)
const GARDEN := Vector3(36.0, ORBIT + 2.0, 36.0)
const SAUCER := Vector3(-36.0, ORBIT - 2.0, 36.0)
const MIRRORS := Vector3(68.0, RIM, -26.0)
const LAB := Vector3(86.0, RIM, -58.0)

var bloom_pads: Array[BloomPad] = []
var spire_pads: Array[BloomPad] = []
var tower_steps: Array[GhostPlatform] = []
var mirror_puzzle: BeamPuzzle
var dynamo: ThunderDynamo
var lab_door: VineGate
var _batch: ModuleBatch
## Places scenery scatter keeps clear of: (x, z, radius).
var _keep: Array[Vector3] = []


func configure() -> void:
	world_id = WORLD
	platform_colour = &"blue"
	model_tint = Color(1.02, 0.96, 1.08)
	# A violet sky with a pink horizon and a minty sun.
	sky_top = Color(0.3, 0.1, 0.56)
	sky_horizon = Color(1.0, 0.6, 0.76)
	sky_bottom = Color(1.0, 0.76, 0.86)
	cloud_cover = 0.3
	cloud_shade = Color(0.86, 0.62, 0.96)
	sun_color = Color(0.88, 1.0, 0.92)
	sun_energy = 1.1
	sun_angles = Vector2(-42.0, 30.0)
	fog_color = Color(0.94, 0.74, 0.96)
	fog_begin = 110.0
	fog_end = 420.0
	saturation = 1.12
	tree_kinds = [&"teal", &"blossom", &"lime", &"teal"]
	tops = {&"sea_violet": &"mush_teal", &"crystal_violet": &"lime_pop", &"mush_purple": &"lime_pop", &"stone_light": &"mush_teal", &"bubble": &"bubble"}
	grass_density = 0.003


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w7_entrance"
	music = &"world_07"
	floor_y = 0.0
	kill_y = -30.0
	_rng.seed = 707
	_batch = ModuleBatch.new()
	arena_center = ARENA
	arena_radius = ARENA_R
	arena_exit_spawn = &"w7_arena_exit"
	defeat_banner = "Queen Bloomzilla wilts for a nap!"
	regions = {"landing": Vector3(0.0, 0.0, 44.0), "lake": Vector3.ZERO, "spire": SPIRE, "meteor": Vector3(16.0, 0.0, -50.0), "village": Vector3(0.0, RIM, -84.0), "lab": LAB, "tower": TOWER, "dishes": Vector3(10.0, RIM, 88.0), "orbit": STARPORT, "crown": CROWN, "queen": ARENA}
	_terrain()
	_landing()
	_lake()
	_bloomstalk()
	_meteor()
	_village()
	_glass_lab()
	_antenna_tower()
	_dish_field()
	_orbit_walk()
	_crown()
	_bloom_gate()
	_monsters()
	_scatter()
	_batch.build(self)
	finish_boss_world()
	finish_life(&"lime_pop")


func create_boss() -> BossBase:
	var q := QueenBloomzilla.new()
	q.rng.seed = 7707
	q.position = ARENA + Vector3(4.0, 0.0, 0.0)
	return q


# --- Helpers ----------------------------------------------------------------------------------

## A bloom-bud with its top at `top` (world) and a stem down to `ground_y`.
func bloom(top: Vector3, ground_y: float, color: StringName = &"candy_pink", open_time: float = 9.0, radius: float = 2.4) -> BloomPad:
	var b := BloomPad.new()
	b.position = top
	b.stalk = top.y - ground_y
	b.color_name = color
	b.open_time = open_time
	b.radius = radius
	add_child(b)
	bloom_pads.append(b)
	return b


## A sourced model you can bump into and stand on (a convex hull per mesh).
func solid(path: String, pos: Vector3, yaw: float, s: float) -> Node3D:
	var m := Models.spawn(self, path, pos, yaw, s)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	body.collision_mask = 0
	add_child(body)
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var cs := CollisionShape3D.new()
		cs.shape = mi.mesh.create_convex_shape(true, true)
		body.add_child(cs)
		cs.global_transform = mi.global_transform
	keep_clear(pos, Models.model_bounds(path).size.x * s * 0.6 + 2.0)
	return m


## A giant alien plant from the space kit, `h` metres tall, with a trunk you bump into.
func plant(file: String, pos: Vector3, h: float, collide: bool = true) -> void:
	var path := Models.Q_SPACE + file
	var b := Models.model_bounds(path)
	var s := h / maxf(b.size.y, 0.01)
	_batch.place(path, pos, _rng.randf() * TAU, Vector3.ONE * s)
	if collide:
		var body := Kit.static_body(self, pos + Vector3.UP * h * 0.3, Layers.WORLD)
		var c := CylinderShape3D.new()
		c.radius = clampf(minf(b.size.x, b.size.z) * s * 0.12, 0.4, 1.2)
		c.height = h * 0.6
		Kit.add_shape(body, c)


func keep_clear(p: Vector3, r: float) -> void:
	_keep.append(Vector3(p.x, p.z, r))


func _busy(p: Vector3) -> bool:
	for k in _keep:
		if Vector2(p.x - k.x, p.z - k.y).length() < k.z:
			return true
	# Keep the crater cliffs and the world's edge clear so the ways up stay in sight.
	if absf(absf(p.x) - CRATER) < 6.0 or absf(absf(p.z) - CRATER) < 6.0:
		return true
	return absf(p.x) > 106.0 or absf(p.z) > 106.0


## Stepped crystal columns (forgiving hops) from `a` to `b` (tops), `n` of them.
func crystal_steps(a: Vector3, b: Vector3, n: int, ground_y: float, color: StringName = &"crystal_violet") -> void:
	for i in n:
		var t := float(i) / maxf(n - 1, 1)
		var top := a.lerp(b, t)
		Kit.pillar(self, top, 1.9, top.y - ground_y, color, &"lime_pop")
		keep_clear(top, 4.0)


# --- Terrain, sky and the edge of the world ----------------------------------------------------

func _terrain() -> void:
	region(Vector3.ZERO)
	var bowl := Rect2(-CRATER, -CRATER, CRATER * 2.0, CRATER * 2.0)
	ground(bowl, [Rect2(-LAKE, -LAKE, LAKE * 2.0, LAKE * 2.0)], 0.0, 20.0, &"sea_violet", &"mush_teal", 0.004)
	ground(Rect2(-112.0, -112.0, 224.0, 224.0), [bowl], RIM, 30.0, &"mush_purple", &"lime_pop", 0.003)
	# Tall candy rocks all round the edge (you can't fall off the moon).
	for side in 4:
		for i in 9:
			var t := -112.0 + (i + 0.5) * 224.0 / 9.0
			var h := _rng.randf_range(14.0, 26.0)
			var c := Vector3(t, RIM + h, -120.0) if side == 0 else (Vector3(t, RIM + h, 120.0) if side == 1 else (Vector3(-120.0, RIM + h, t) if side == 2 else Vector3(120.0, RIM + h, t)))
			var size := Vector3(26.0, h + 30.0, 16.0) if side < 2 else Vector3(16.0, h + 30.0, 26.0)
			Kit.block(self, c, size, [&"crystal_violet", &"sea_violet", &"mush_purple"][(i + side) % 3] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"lime_pop")
	# Planets hang in the sky.
	Models.spawn(self, Models.Q_SPACE + "Planet.glb", Vector3(-150.0, 120.0, -250.0), 0.4, 18.0)
	Models.spawn(self, Models.Q_SPACE + "Planet.glb", Vector3(240.0, 80.0, 150.0), 2.2, 8.0)
	Models.spawn(self, Models.Q_SPACE + "Planet.glb", Vector3(-260.0, 60.0, 180.0), 4.0, 5.0)
	Ambient.sparkles(self, Vector3(0.0, 40.0, 0.0), Vector3(200.0, 30.0, 200.0), 120)
	Ambient.motes(self, Vector3(0.0, 8.0, 0.0), Vector3(110.0, 10.0, 110.0), Color(0.8, 1.0, 0.7, 0.6))
	add_capture_point("overview", Vector3(0.0, 58.0, 108.0), Vector3(0.0, 4.0, -10.0))


# --- South: the Landing Pad (crater floor) -----------------------------------------------------

func _landing() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w7_entrance", Vector3(0.0, 0.0, 44.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 53.0)
	add_child(exit)
	keep_clear(Vector3(0.0, 0.0, 44.0), 14.0)
	checkpoint(&"w7_cp_landing", Vector3(-8.0, 0.0, 40.0))
	sign_post(Vector3(6.0, 0.0, 47.0), "Find 3 Star Shards to open\nthe Bloom Gate on the east rim!")
	# A glowing path down to the goo.
	Kit.mesh_instance(self, RoundMesh.box(Vector3(4.0, 0.06, 26.0), 0.03), Kit.mat(&"bubble"), Vector3(0.0, 0.03, 30.0))
	for z: float in [22.0, 34.0, 46.0]:
		Whimsy.lamp(self, Vector3(-3.4, 0.0, z), z < 30.0)
		Whimsy.lamp(self, Vector3(3.4, 0.0, z + 0.5), false)
	# Blip's saucer, parked crooked on its pad.
	Kit.pillar(self, Vector3(-20.0, 0.4, 44.0), 6.5, 0.4, &"stone_light", &"gold")
	solid(Models.KN_SPACE + "hangar_roundGlass.glb", Vector3(-20.0, 0.4, 44.0), 0.6, 3.6)
	keep_clear(Vector3(-20.0, 0.0, 44.0), 10.0)
	errand_star("blip", "Blip", Vector3(-12.0, 0.0, 36.0), &"w7_found_antenna", &"w7_shard_errand", Vector3(6.0, -9.3, -4.0), "Blip's antenna")
	chest(Vector3(-29.0, 0.0, 52.0), PI * 0.75, &"w7_seed_chest")
	heart_bush(Vector3(14.0, 0.0, 50.0))
	for spec: Array in [["satelliteDish_large.glb", Vector3(16.0, 0.0, 36.0), 6.0], ["machine_generator.glb", Vector3(-10.0, 0.0, 50.0), 5.0], ["rock_crystalsLargeA.glb", Vector3(24.0, 0.0, 52.0), 7.0]]:
		solid(Models.KN_SPACE + str(spec[0]), spec[1] as Vector3, _rng.randf() * TAU, spec[2] as float)
	# Ways up to the south rim: a ramp along the cliff, a ladder and a glowcap.
	bridge(Vector3(14.0, 0.0, 56.0), Vector3(40.0, RIM, 56.0), 5.0, &"stone_light", true, &"crystal_violet")
	Kit.block(self, Vector3(44.0, RIM, 56.5), Vector3(8.0, RIM, 7.0), &"mush_purple", Layers.WORLD | Layers.CAMERA_BLOCKER, &"lime_pop")
	keep_clear(Vector3(28.0, 0.0, 56.0), 6.0)
	ladder(Vector3(-32.0, 0.0, CRATER), RIM, PI)
	bouncer(Vector3(-44.0, 0.0, 56.0), Springcap.Look.GLOWCAP, 13.0)
	sign_post(Vector3(-40.0, 0.0, 50.0), "Bounce up to the rim!", PI * 0.75)
	add_capture_point("landing", Vector3(14.0, 14.0, 58.0), Vector3(-6.0, 0.0, 24.0))


# --- Centre: Gloop Lake ------------------------------------------------------------------------

func _lake() -> void:
	region(Vector3.ZERO)
	var c := Vector3(0.0, -0.4, 0.0)
	Kit.water(self, c, Vector2(LAKE * 2.0, LAKE * 2.0), 9.0)
	var mi := get_child(get_child_count() - 2) as MeshInstance3D
	if mi != null and mi.material_override is ShaderMaterial:
		var wm := mi.material_override as ShaderMaterial
		wm.set_shader_parameter(&"light_col", Color(0.72, 1.0, 0.56))
		wm.set_shader_parameter(&"mid_col", Color(0.36, 0.86, 0.5))
		wm.set_shader_parameter(&"deep_col", Color(0.2, 0.52, 0.5))
		wm.set_shader_parameter(&"foam_col", Color(0.94, 1.0, 0.86))
	basin_at(c, Vector2(LAKE * 2.0, LAKE * 2.0), 9.0, &"sea_violet", &"mush_teal")
	keep_clear(Vector3.ZERO, LAKE + 6.0)
	# Gloop Rock in the middle, with a giant flower and a seed; bloom-buds cross from both shores.
	Kit.pillar(self, Vector3(0.0, 3.0, 0.0), 4.5, 12.4, &"sea_violet", &"mush_teal")
	Whimsy.flower(self, Vector3(1.8, 3.0, -1.6), 6.0, 2.6, &"candy_pink")
	seed_at(&"w7_seed_island", Vector3(-1.5, 3.0, 1.5))
	for z: float in [10.6, -10.6]:
		bloom(Vector3(0.0, 1.4, z), -9.4, &"lime_pop")
	bloom(Vector3(10.6, 1.4, 0.0), -9.4, &"portal_teal")
	# The lake bed: a seed among glowing crystals, Blip's lost antenna, fish and kelp.
	seed_at(&"w7_seed_lake_bed", Vector3(-8.0, -9.4, 8.0))
	for i in 7:
		var a := float(i) / 7.0 * TAU + 0.3
		Whimsy.crystal(self, Vector3(cos(a) * 10.0, -9.4, sin(a) * 10.0), [&"portal_teal", &"lime_pop", &"candy_pink"][i % 3] as StringName, 0.9, false)
	for i in 6:
		Whimsy.kelp(self, Vector3(_rng.randf_range(-12.0, 12.0), -9.4, _rng.randf_range(-12.0, 12.0)), _rng.randf_range(4.0, 7.0))
	Ambient.fish(self, Vector3(0.0, -5.0, 0.0), 9.0, 8, &"candy_pink")
	Ambient.bubbles(self, Vector3(0.0, -4.0, 0.0), Vector3(26.0, 8.0, 26.0), 30)
	sign_post(Vector3(-5.0, 0.0, 18.0), "Gloop Lake. Bop a bud\nand it blooms into a step!", PI)
	add_capture_point("lake", Vector3(-18.0, 10.0, 26.0), Vector3(0.0, 0.0, 0.0))


# --- West: the Bloomstalk (crater floor) --------------------------------------------------------
# Puzzle star: seven bloom-buds wind up round a crystal spire. Each opens for ten seconds when
# you hit it (sword from the bud below, a jumping slash or a Fireball), so you climb by blooming
# the next one up. One more bud above the spire leads on to the Orbit Walk.

func _bloomstalk() -> void:
	region(Vector3.ZERO)
	Kit.pillar(self, SPIRE + Vector3(0.0, SPIRE_TOP, 0.0), 3.0, SPIRE_TOP, &"crystal_violet", &"gold")
	keep_clear(SPIRE, 14.0)
	var cols: Array[StringName] = [&"candy_pink", &"lime_pop", &"portal_teal"]
	for k in 7:
		var a := -0.2 + k * TAU / 7.0
		var y := 2.2 * (k + 1)
		spire_pads.append(bloom(SPIRE + Vector3(cos(a) * 5.5, y, sin(a) * 5.5), 0.0, cols[k % 3], 10.0, 2.2))
	shard_at(&"w7_shard_bloom", SPIRE + Vector3(0.0, SPIRE_TOP, 0.0))
	# On up to the Orbit Walk's west stop.
	bloom(SPIRE + Vector3(3.0, SPIRE_TOP + 2.4, 6.0), 0.0, &"candy_pink", 10.0, 2.2)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		Whimsy.crystal(self, SPIRE + Vector3(cos(a) * 9.0, 0.0, sin(a) * 9.0), cols[i % 3], 1.2, false)
	sign_post(SPIRE + Vector3(9.0, 0.0, 9.0), "The Bloomstalk: bop each bud\nto open the next step up.", PI * 0.25)
	villager("quasa", "Quasa", SPIRE + Vector3(11.0, 0.0, 5.0))
	checkpoint(&"w7_cp_spire", SPIRE + Vector3(12.0, 0.0, -5.0))
	# A ladder up the west cliff.
	ladder(Vector3(-CRATER, 0.0, -18.0), RIM, PI * 0.5)
	add_capture_point("spire", SPIRE + Vector3(22.0, 12.0, 18.0), SPIRE + Vector3(0.0, 9.0, 0.0))


# --- North: the Hollow Meteor (crater floor, hidden) ---------------------------------------------
# Hidden star: a fallen meteor by the north cliff. Its cracked face looks at the cliff, so you
# only find it by walking round the back; break it open and climb inside.

func _meteor() -> void:
	region(Vector3.ZERO)
	var c := Vector3(16.0, 0.0, -50.0)
	keep_clear(c, 12.0)
	var cave: Array = secret_cave(c, PI, Vector3(14.0, 9.0, 12.0), &"sunset_orange", &"break")
	stone(Vector3(-4.0, 1.2, 2.0), 1.8, 1.2, &"crystal_violet", &"lime_pop")
	ledge(Vector3(-1.0, 3.2, -1.5), Vector3(2.6, 0.5, 2.6), &"crystal_violet")
	crumble(Vector3(2.5, 4.8, -3.0), Vector3(2.6, 0.5, 2.6), CrumblePlatform.Look.ROCK)
	ledge(Vector3(5.0, 6.4, 0.5), Vector3(2.4, 0.5, 2.4), &"crystal_violet")
	shard_at(&"w7_shard_hidden", Vector3(5.0, 6.4, 0.5))
	ledge(Vector3(-5.0, 5.2, -4.0), Vector3(2.2, 0.5, 2.2), &"crystal_violet")
	seed_at(&"w7_seed_meteor", Vector3(-5.0, 5.2, -4.0))
	for i in 4:
		Whimsy.crystal(self, P(Vector3(-5.0 + i * 3.4, 0.3, 5.0)), &"lime_pop", 0.7, false)
	_frame = cave[0]
	region(Vector3.ZERO)
	# Rocky cladding so it reads as one great meteor.
	for spec: Array in [[Vector3(16.0, 0.0, -37.0), 0.0], [Vector3(2.0, 0.0, -50.0), 1.6], [Vector3(30.0, 0.0, -50.0), -1.6]]:
		Models.spawn(self, Models.Q_SPACE + "Rock_Large.glb", spec[0] as Vector3, spec[1] as float, 1.7)
	Models.spawn(self, Models.KN_SPACE + "meteor.glb", Vector3(16.0, 9.5, -50.0), 0.7, 11.0)
	for i in 3:
		Models.spawn(self, Models.KN_SPACE + "rock_crystalsLargeB.glb", Vector3(9.0 + i * 7.0, 0.0, -42.0), i * 1.3, 5.0)
	add_capture_point("meteor", Vector3(40.0, 14.0, -50.0), Vector3(16.0, 2.0, -57.0))


# --- North rim: Zorp's dome village ---------------------------------------------------------------

func _village() -> void:
	region(Vector3.ZERO)
	var v := Vector3(0.0, RIM, -84.0)
	keep_clear(v, 26.0)
	checkpoint(&"w7_cp_village", v + Vector3(4.0, 0.0, 8.0))
	sign_post(v + Vector3(-6.0, 0.0, 14.0), "Zorp's Dome Village", PI)
	var dome := v + Vector3(18.0, 0.0, -6.0)
	solid(Models.Q_SPACE + "Geodesic_Dome.glb", dome, 0.3, 1.5)
	solid(Models.Q_SPACE + "House_Cylinder.glb", v + Vector3(-16.0, 0.0, -10.0), 0.6, 1.3)
	solid(Models.Q_SPACE + "House_Single.glb", v + Vector3(-50.0, 0.0, -12.0), PI * 0.5, 1.3)
	solid(Models.Q_SPACE + "House_Long.glb", v + Vector3(32.0, 0.0, 12.0), -PI * 0.5, 1.3)
	solid(Models.Q_SPACE + "Base_Large.glb", v + Vector3(-2.0, 0.0, -20.0), 0.0, 1.2)
	for spec: Array in [[Vector3(-16.0, 5.6, -10.0), "Roof_Antenna.glb"], [Vector3(-2.0, 6.0, -20.0), "Roof_Radar.glb"]]:
		Models.spawn(self, Models.Q_SPACE + str(spec[1]), v + (spec[0] as Vector3), 0.0, 1.3)
	for i in 4:
		solid(Models.Q_SPACE + "Solar_Panel_Structure.glb", v + Vector3(-36.0 + i * 6.0, 0.0, -24.0), 0.0, 1.0)
	# The radar mast and its catwalk to the dome's crown (a seed up top).
	var crown := dome + Vector3(0.0, Models.model_bounds(Models.Q_SPACE + "Geodesic_Dome.glb").size.y * 1.5 + 0.1, 0.0)
	var mast := dome + Vector3(-11.0, 0.0, 5.0)
	var mast_h := crown.y - RIM
	Kit.block(self, Vector3(mast.x, crown.y, mast.z), Vector3(4.0, mast_h, 4.0), &"stone_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_teal")
	ladder(mast + Vector3(0.0, 0.0, 2.0), mast_h)
	bridge(Vector3(mast.x + 2.0, crown.y, mast.z), crown, 2.6, &"wood_plank", true, &"crystal_violet")
	seed_at(&"w7_seed_dome", crown)
	Models.spawn(self, Models.KN_SPACE + "satelliteDish_large.glb", v + Vector3(10.0, 0.0, 14.0), 2.6, 6.0)
	for k in 4:
		Whimsy.lamp(self, v + Vector3(-12.0 + k * 8.0, 0.0, 6.0), k % 2 == 0)
	Whimsy.bunting(self, v + Vector3(-12.0, 3.0, 6.0), v + Vector3(12.0, 3.0, 6.0), 0.6)
	villager("zorp", "Zorp", v + Vector3(2.0, 0.0, 2.0), &"w7_found_socks", &"w7_seed_errand", COMET + Vector3(6.0, 0.3, -5.0), "Zorp's space socks")
	villager("mimsy", "Mimsy", v + Vector3(-8.0, 0.0, 8.0))
	# Ways down to the crater and up to the Orbit Walk.
	ladder(Vector3(-10.0, 0.0, -CRATER), RIM)
	ladder(Vector3(46.0, 0.0, -CRATER), RIM)
	bouncer(Vector3(0.0, 0.0, -56.0), Springcap.Look.GLOWCAP, 13.0)
	ramp_tower(Vector3(-36.0, 0.0, -76.0), RIM, ORBIT, 8.0, 4.0, &"crystal_violet", &"stone_light", &"lime_pop")
	keep_clear(Vector3(-36.0, 0.0, -76.0), 12.0)
	bridge(Vector3(-36.0, ORBIT, -72.0), Vector3(-36.0, ORBIT, -47.0), 3.6, &"stone_light", true, &"crystal_violet")
	sign_post(Vector3(-27.0, RIM, -68.0), "The Star Stair: up to\nthe Orbit Walk!", PI * 0.75)
	add_capture_point("village", v + Vector3(10.0, 16.0, 32.0), v + Vector3(0.0, 2.0, -6.0))


# --- East rim: the Glass Lab (mirror puzzle) -------------------------------------------------------
# Puzzle star: a beam of starlight runs from the lens into four mirrors. Hit a mirror to turn it;
# three need turning (the fourth is a decoy) to light the green crystal, and the lab door opens.

func _glass_lab() -> void:
	region(Vector3.ZERO)
	keep_clear(MIRRORS + Vector3(4.0, 0.0, -8.0), 14.0)
	keep_clear(LAB, 12.0)
	mirror_puzzle = BeamPuzzle.new()
	mirror_puzzle.position = MIRRORS
	mirror_puzzle.source_dir = Vector3.FORWARD
	mirror_puzzle.target = Vector3(14.0, 0.0, -12.0)
	mirror_puzzle.max_length = 18.0
	add_child(mirror_puzzle)
	mirror_puzzle.add_mirror(Vector3(0.0, 0.0, -6.0), false)
	mirror_puzzle.add_mirror(Vector3(8.0, 0.0, -6.0), false)
	mirror_puzzle.add_mirror(Vector3(8.0, 0.0, -12.0), false)
	mirror_puzzle.add_mirror(Vector3(-6.0, 0.0, -6.0), true)
	var cave: Array = secret_cave(LAB, 0.0, Vector3(14.0, 9.0, 12.0), &"bubble", &"gate")
	ledge(Vector3(-4.5, 1.6, -2.0), Vector3(2.6, 1.6, 2.6), &"crystal_violet")
	ledge(Vector3(-1.0, 3.6, -3.6), Vector3(2.4, 0.5, 2.4), &"crystal_violet")
	ledge(Vector3(2.6, 5.4, -1.8), Vector3(2.4, 0.5, 2.4), &"crystal_violet")
	ledge(Vector3(5.2, 6.4, 1.8), Vector3(2.4, 0.5, 2.4), &"lime_pop")
	shard_at(&"w7_shard_mirrors", Vector3(5.2, 6.4, 1.8))
	ledge(Vector3(-5.0, 5.0, 3.0), Vector3(2.2, 0.5, 2.2), &"crystal_violet")
	seed_at(&"w7_seed_lab", Vector3(-5.0, 5.0, 3.0))
	_frame = cave[0]
	region(Vector3.ZERO)
	lab_door = cave[1] as VineGate
	mirror_puzzle.solved.connect(func() -> void:
		lab_door.set_closed(false)
		if hud != null:
			hud.show_banner("Starlight wakes the Glass Lab!", 2.0))
	Models.spawn(self, Models.Q_SPACE + "Geodesic_Dome.glb", LAB + Vector3(0.0, 10.0, 0.0), 0.0, 1.4)
	sign_post(MIRRORS + Vector3(-3.0, 0.0, 3.0), "Bop a mirror to turn it.\nLight up the crystal!", PI)
	villager("gleep", "Gleep", MIRRORS + Vector3(-6.0, 0.0, 1.0))
	checkpoint(&"w7_cp_lab", Vector3(64.0, RIM, -14.0))
	# Ways up from the crater: a lift and a ladder on the east cliff.
	lift(Vector3(CRATER - 2.4, 0.0, -14.0), RIM, 6.0, &"stone_light")
	ladder(Vector3(CRATER, 0.0, 30.0), RIM, -PI * 0.5)
	add_capture_point("lab", MIRRORS + Vector3(-10.0, 12.0, 12.0), MIRRORS + Vector3(8.0, 0.0, -18.0))


# --- South-west rim: the Antenna Tower (thunder dynamo) ---------------------------------------
# Puzzle star: give the coil a Thunderclap and ten glowing steps light up round the tower for
# twenty seconds. Climb fast; the star waits on the cap.

func _antenna_tower() -> void:
	region(Vector3.ZERO)
	keep_clear(TOWER, 14.0)
	var cap := TOWER.y + 24.0
	Kit.pillar(self, Vector3(TOWER.x, cap - 1.0, TOWER.z), 2.4, cap - 1.0 - TOWER.y, &"stone_light", &"mush_teal")
	Kit.pillar(self, Vector3(TOWER.x, cap, TOWER.z), 3.5, 1.0, &"crystal_violet", &"gold")
	Models.spawn(self, Models.Q_SPACE + "Roof_Antenna.glb", Vector3(TOWER.x + 1.6, cap, TOWER.z - 1.6), 0.0, 1.4)
	shard_at(&"w7_shard_dynamo", Vector3(TOWER.x - 1.0, cap, TOWER.z + 1.0))
	for k in 10:
		var a := 0.6 + k * deg_to_rad(52.0)
		var step := GhostPlatform.new()
		step.size = Vector3(3.6, 0.6, 3.6)
		step.color_name = [&"portal_teal", &"lime_pop"][k % 2] as StringName
		step.position = TOWER + Vector3(cos(a) * 6.0, 2.2 * (k + 1), sin(a) * 6.0)
		add_child(step)
		tower_steps.append(step)
	dynamo = ThunderDynamo.new()
	dynamo.run_time = 20.0
	dynamo.position = TOWER + Vector3(9.0, 0.0, -3.0)
	add_child(dynamo)
	dynamo.powered_changed.connect(_power_tower)
	sign_post(TOWER + Vector3(11.0, 0.0, 2.0), "The Antenna Tower runs on thunder.\nJolt the coil, then climb fast!", PI * 0.5)
	add_capture_point("tower", TOWER + Vector3(26.0, 18.0, -14.0), TOWER + Vector3(0.0, 12.0, 0.0))


func _power_tower(on: bool) -> void:
	for i in tower_steps.size():
		tower_steps[i].set_solid(on)
	if on and hud != null:
		hud.show_banner("The tower steps light up!", 1.6)


# --- South rim: the dish field ---------------------------------------------------------------------

func _dish_field() -> void:
	region(Vector3.ZERO)
	var f := Vector3(10.0, RIM, 88.0)
	for i in 4:
		solid(Models.KN_SPACE + "satelliteDish_large.glb", f + Vector3(-30.0 + i * 18.0, 0.0, 6.0 * (i % 2)), PI + i * 0.3, 8.0)
	for i in 3:
		solid(Models.Q_SPACE + "Solar_Panel_Structure.glb", f + Vector3(-22.0 + i * 18.0, 0.0, -10.0), 0.0, 1.1)
	solid(Models.Q_SPACE + "Connector.glb", f + Vector3(30.0, 0.0, -6.0), 0.4, 1.6)
	# The Crystal Steps: forgiving hops up to a high spire with a seed.
	crystal_steps(f + Vector3(36.0, 2.2, 4.0), f + Vector3(56.0, 13.2, 10.0), 6, RIM)
	Kit.pillar(self, f + Vector3(62.0, 15.2, 12.0), 3.0, 15.2, &"crystal_violet", &"gold")
	seed_at(&"w7_seed_rim_spire", f + Vector3(62.0, 15.2, 12.0))
	keep_clear(f + Vector3(50.0, 0.0, 8.0), 16.0)
	boulderkin(f + Vector3(0.0, 0.5, 4.0), &"crystal_violet", &"lime_pop", &"candy_pink")
	add_capture_point("dishes", f + Vector3(0.0, 14.0, -26.0), f + Vector3(10.0, 2.0, 4.0))


# --- The Orbit Walk: a ring of floating decks high over the crater ------------------------------

func _orbit_walk() -> void:
	region(Vector3.ZERO)
	deck(STARPORT, Vector2(26.0, 22.0), &"stone_light", &"mush_teal", &"pillars", 0.0, &"crystal_violet")
	deck(COMET, Vector2(22.0, 18.0), &"stone_light", &"mush_teal", &"pillars", 0.0, &"crystal_violet")
	deck(GARDEN, Vector2(24.0, 22.0), &"stone_light", &"lime_pop", &"pillars", 0.0, &"crystal_violet")
	Kit.pillar(self, SAUCER, 11.0, 1.4, &"stone_light", &"gold")
	for i in 3:
		var a := float(i) / 3.0 * TAU + 0.5
		Kit.pillar(self, SAUCER + Vector3(cos(a) * 6.0, -1.4, sin(a) * 6.0), 0.9, SAUCER.y - 1.4, &"crystal_violet", &"crystal_violet")
	for p: Vector3 in [STARPORT, COMET, GARDEN, SAUCER]:
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				keep_clear(p + Vector3(sx * 9.5, 0.0, sz * 8.0), 4.5)
	# Stops between the decks, joined by bridges (north, east, west) and a ferry (south).
	var north := Vector3(0.0, ORBIT, -36.0)
	var east := Vector3(36.0, ORBIT + 1.0, 0.0)
	var west := Vector3(-36.0, ORBIT - 1.2, 0.0)
	for stop: Vector3 in [north, east, west]:
		Kit.pillar(self, stop, 5.0, 2.0, &"mush_purple", &"lime_pop")
		Models.spawn(self, Models.Q_SPACE + "Rock_Large.glb", stop + Vector3(0.0, -5.0, 0.0), _rng.randf() * TAU, 1.1)
	bridge(Vector3(-23.0, ORBIT, -36.0), Vector3(-5.0, ORBIT, -36.0), 3.6, &"stone_light", true, &"crystal_violet")
	bridge(Vector3(5.0, ORBIT, -36.0), Vector3(25.0, ORBIT, -36.0), 3.6, &"stone_light", true, &"crystal_violet")
	bridge(Vector3(36.0, ORBIT, -27.0), Vector3(36.0, ORBIT + 1.0, -5.0), 3.6, &"stone_light", true, &"crystal_violet")
	bridge(Vector3(36.0, ORBIT + 1.0, 5.0), Vector3(36.0, ORBIT + 2.0, 25.0), 3.6, &"stone_light", true, &"crystal_violet")
	bridge(Vector3(-36.0, SAUCER.y, 25.0), Vector3(-36.0, west.y, 5.0), 3.6, &"stone_light", true, &"crystal_violet")
	bridge(Vector3(-36.0, west.y, -5.0), Vector3(-36.0, ORBIT, -25.0), 3.6, &"stone_light", true, &"crystal_violet")
	mover(Vector3(-0.5, ORBIT, 36.0), Vector3(5.0, 1.0, 5.0), Vector3(41.0, 0.0, 0.0), 14.0, &"gold")
	Kit.pillar(self, Vector3(0.0, ORBIT + 2.0, 27.0), 4.0, 1.6, &"mush_purple", &"lime_pop")
	# Ways up from the crater: a ladder to the Saucer, lifts to the Comet Deck and Moon Garden.
	ladder(Vector3(SAUCER.x, 0.0, SAUCER.z + 11.0), SAUCER.y)
	lift(Vector3(COMET.x + 13.4, 0.0, COMET.z), COMET.y, 9.0, &"stone_light")
	lift(Vector3(GARDEN.x, 0.0, GARDEN.z + 13.4), GARDEN.y, 9.0, &"stone_light")
	keep_clear(Vector3(SAUCER.x, 0.0, SAUCER.z + 11.0), 5.0)
	keep_clear(Vector3(COMET.x + 13.4, 0.0, COMET.z), 5.0)
	keep_clear(Vector3(GARDEN.x, 0.0, GARDEN.z + 13.4), 5.0)
	# Starport: Nebby's observatory, the high checkpoint and a seed on the control tower.
	checkpoint(&"w7_cp_orbit", STARPORT + Vector3(-4.0, 0.0, 6.0))
	villager("nebby", "Nebby", STARPORT + Vector3(4.0, 0.0, 4.0))
	solid(Models.Q_SPACE + "House_Cylinder.glb", STARPORT + Vector3(-7.0, 0.0, -5.0), 0.0, 1.0)
	Models.spawn(self, Models.Q_SPACE + "Roof_Radar.glb", STARPORT + Vector3(-7.0, 4.3, -5.0), 0.0, 1.0)
	for i in 3:
		Kit.block(self, STARPORT + Vector3(-1.5 + i * 0.0, 1.4 + i * 1.4, -1.0 - i * 2.6), Vector3(2.6, 1.4 * (i + 1), 2.4), [&"candy_pink", &"lime_pop", &"portal_teal"][i] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	seed_at(&"w7_seed_starport", STARPORT + Vector3(-5.2, 4.4, -3.6))
	solid(Models.KN_SPACE + "satelliteDish_large.glb", STARPORT + Vector3(8.0, 0.0, -6.0), 2.4, 5.0)
	sign_post(STARPORT + Vector3(0.0, 0.0, 9.0), "The Orbit Walk", PI)
	# Comet Deck: crates, a comet, and Zorp's socks.
	solid(Models.KN_SPACE + "meteor.glb", COMET + Vector3(-5.0, 0.0, 4.0), 0.4, 4.0)
	for i in 3:
		Kit.block(self, COMET + Vector3(6.5, 1.2 * (i + 1), 4.0 - i * 2.4), Vector3(2.4, 1.2 * (i + 1), 2.4), &"wood_warm", Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	seed_at(&"w7_seed_comet", COMET + Vector3(6.5, 3.6, -0.8))
	# Moon Garden: giant alien flowers and a cracked vault with a seed.
	for i in 5:
		Whimsy.flower(self, GARDEN + Vector3(-8.0 + i * 4.0, 0.0, -6.0 + (i % 2) * 3.0), _rng.randf_range(3.0, 5.0), _rng.randf_range(1.4, 2.2), [&"candy_pink", &"lime_pop", &"portal_teal", &"gold", &"crystal_violet"][i] as StringName, false)
	alcove(GARDEN + Vector3(7.0, 0.0, 6.0), PI, &"crystal_violet")
	seed_at(&"w7_seed_garden_vault", GARDEN + Vector3(7.0, 0.0, 6.0))
	villager("orla", "Orla", GARDEN + Vector3(-4.0, 0.0, 6.0))
	# The Saucer: a glass dome on top with a seed, bloomed up to from the deck.
	solid(Models.KN_SPACE + "hangar_roundGlass.glb", SAUCER + Vector3(0.0, 0.0, -2.0), 0.0, 2.6)
	bloom(SAUCER + Vector3(4.5, 2.4, 3.0), SAUCER.y, &"lime_pop", 9.0, 2.0)
	seed_at(&"w7_seed_saucer", SAUCER + Vector3(0.0, Models.model_bounds(Models.KN_SPACE + "hangar_roundGlass.glb").size.y * 2.6, -2.0))
	add_capture_point("orbit", Vector3(-8.0, 44.0, -70.0), Vector3(0.0, 22.0, 0.0))
	add_capture_point("starport", STARPORT + Vector3(14.0, 10.0, 16.0), STARPORT)


# --- The Crown Asteroid (star) ---------------------------------------------------------------------

func _crown() -> void:
	region(Vector3.ZERO)
	Kit.pillar(self, CROWN, 5.5, 2.0, &"crystal_violet", &"gold")
	Models.spawn(self, Models.Q_SPACE + "Rock_Large.glb", CROWN + Vector3(0.0, -6.0, 0.0), 0.8, 1.3)
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.4
		Whimsy.crystal(self, CROWN + Vector3(cos(a) * 4.0, 0.0, sin(a) * 4.0), [&"lime_pop", &"candy_pink"][i % 2] as StringName, 0.8, false)
	shard_at(&"w7_shard_asteroid", CROWN)
	# Stepping-stone asteroids from the north stop.
	for k in 4:
		var top := Vector3(0.0, ORBIT + 1.8 * (k + 1), -27.0 + k * 5.8)
		if k % 2 == 1:
			crumble(top, Vector3(3.6, 0.8, 3.6), CrumblePlatform.Look.ROCK)
		else:
			Kit.pillar(self, top, 2.4, 1.6, &"mush_purple", &"lime_pop")
	# A Vinelash hook flower on the south side, in reach from the ferry stop.
	hook(CROWN + Vector3(0.0, 0.0, 5.0))
	add_capture_point("crown", CROWN + Vector3(14.0, 8.0, 14.0), CROWN)


# --- East rim: the Bloom Gate and Queen Bloomzilla's ring ----------------------------------------

func _bloom_gate() -> void:
	region(Vector3.ZERO)
	keep_clear(ARENA, ARENA_R + 8.0)
	var n := 28
	for i in n:
		var a := float(i) / n * TAU
		if absf(wrapf(a - PI, -PI, PI)) < deg_to_rad(17.0):
			continue
		var c := ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R + 2.0)
		var b := Kit.block(self, c + Vector3(0.0, WALL_H, 0.0), Vector3(4.9, WALL_H, 3.0), [&"crystal_violet", &"mush_purple", &"sea_violet"][i % 3] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"lime_pop")
		b.rotation.y = -(a + PI * 0.5)
	region(Vector3(ARENA.x - ARENA_R - 2.0, RIM, 0.0), 90.0)
	make_gate(Vector3.ZERO, 12.0)
	region(Vector3.ZERO)
	for z: float in [-7.5, 7.5]:
		Kit.pillar(self, Vector3(ARENA.x - ARENA_R - 2.0, RIM + 9.0, z), 1.4, 9.0, &"crystal_violet", &"gold")
	sign_post(Vector3(64.0, RIM, 10.0), "The Bloom Gate opens\nfor 3 Star Shards.", -PI * 0.5)
	sign_post(Vector3(64.0, RIM, -9.0), "When the Queen slams and wilts,\nbop her glowing heart!", -PI * 0.5)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.2
		Whimsy.flower(self, ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R - 1.0), 4.0, 1.8, [&"candy_pink", &"lime_pop"][i % 2] as StringName, false)
	add_capture_point("gate", Vector3(50.0, 22.0, 0.0), ARENA)
	add_capture_point("queen", ARENA + Vector3(-12.0, 12.0, -10.0), ARENA + Vector3(4.0, 3.0, 0.0))


# --- Monsters ----------------------------------------------------------------------------------------

func _monsters() -> void:
	region(Vector3.ZERO)
	critter(Whirlwisp, Vector3(-22.0, 0.3, 26.0))
	critter(Whirlwisp, Vector3(28.0, 0.3, -12.0))
	critter(Hopfrog, Vector3(18.0, 0.0, 20.0))
	critter(Hopfrog, Vector3(-19.0, 0.0, -19.0))
	place(Puffcap.new(), Vector3(-28.0, 0.0, -32.0))
	big_gloplet(Vector3(32.0, 0.5, 24.0), preload("res://data/enemies/pink_gloplet.tres"))
	critter(Buzzbee, Vector3(10.0, RIM + 2.0, -74.0))
	critter(Buzzbee, Vector3(72.0, RIM + 2.0, -20.0))
	critter(Armorling, Vector3(66.0, RIM + 0.5, 14.0))
	critter(Pricklepot, Vector3(-80.0, RIM, -10.0))
	critter(Pricklepot, Vector3(-70.0, RIM, 70.0))
	critter(Hexwizard, STARPORT + Vector3(6.0, 0.0, -2.0))
	critter(Wyrmling, COMET + Vector3(0.0, 4.0, 0.0))
	critter(Wyrmling, GARDEN + Vector3(0.0, 4.0, 0.0))
	critter(Buzzbee, Vector3(0.0, ORBIT + 2.0, -36.0))
	batling(SAUCER + Vector3(0.0, -3.0, 9.0), true)
	critter(Wispghost, Vector3(-70.0, RIM + 1.0, -40.0))
	gloplets(Vector3(-80.0, RIM, -60.0), 8.0, [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 2.0)], [Vector3(0.0, 0.0, -3.0)], preload("res://data/enemies/pink_gloplet.tres"))


# --- Alien plants everywhere -------------------------------------------------------------------------

func _scatter() -> void:
	var trees: Array[String] = ["Tree_Swirl.glb", "Tree_Spiral.glb", "Tree_Blob.glb", "Tree_Light.glb", "Tree_Floating.glb"]
	var n := 0
	for i in 400:
		if n >= 80:
			break
		var p := Vector3(_rng.randf_range(-106.0, 106.0), 0.0, _rng.randf_range(-106.0, 106.0))
		p.y = 0.0 if absf(p.x) < CRATER and absf(p.z) < CRATER else RIM
		if _busy(p):
			continue
		plant(trees[n % trees.size()], p, _rng.randf_range(8.0, 16.0))
		keep_clear(p, 3.0)
		n += 1
	# Little moon flowers and bushes between them.
	var petals: Array[StringName] = [&"candy_pink", &"lime_pop", &"portal_teal", &"gold", &"crystal_violet", &"sunset_orange"]
	for i in 160:
		var p := Vector3(_rng.randf_range(-106.0, 106.0), 0.0, _rng.randf_range(-106.0, 106.0))
		p.y = 0.0 if absf(p.x) < CRATER and absf(p.z) < CRATER else RIM
		if _busy(p):
			continue
		if i % 4 == 0:
			plant("Bush.glb", p, _rng.randf_range(1.6, 2.6), false)
		else:
			Whimsy.flower(self, p, _rng.randf_range(1.0, 2.4), _rng.randf_range(0.5, 0.9), petals[i % petals.size()], false)
	for i in 30:
		var p := Vector3(_rng.randf_range(-100.0, 100.0), 0.0, _rng.randf_range(-100.0, 100.0))
		p.y = 0.0 if absf(p.x) < CRATER and absf(p.z) < CRATER else RIM
		if _busy(p):
			continue
		if i % 3 == 0:
			Whimsy.mushroom(self, p, _rng.randf_range(4.0, 8.0), _rng.randf_range(3.0, 5.0), [&"purple", &"teal", &"pink", &"blue"][i % 4] as StringName)
		else:
			_batch.place(Models.KN_SPACE + str(["rock_crystalsLargeA.glb", "rock_crystalsLargeB.glb", "rock_crystals.glb"][i % 3]), p, _rng.randf() * TAU, Vector3.ONE * _rng.randf_range(4.0, 8.0))
		keep_clear(p, 4.0)
