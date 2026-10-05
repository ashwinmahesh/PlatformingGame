class_name Frostfang
extends BossWorld
## World 5, Frostfang Peak (Build 5): a snowy storybook mountaintop under the northern lights.
## From Snowcap Village (igloos, snowmen and a steaming hot spring), four routes lead out:
##   North  Ice Slide Gorge     - a slippery slope with rolling snowballs, icicles, a floe crossing
##   East   Crystal Caverns     - an ice maze with melt-able walls and a thunder crystal
##   West   Frosted Pine Heights - penguins on the ice, floes over a frozen lake, pine-topped tiers
##   South  Summit Gate         - the shard-locked gate to the Avalanche Ape's frozen ring
## Every magic ability has a use here: Fireball melts ice walls, the Thunderclap wakes a crystal
## and stuns frost knights, Glide and Air Dash reach far-off seeds.

const WORLD := &"world_05"
const ARENA := Vector3(0.0, 0.0, 108.0)
const ARENA_R := 18.0
const WALL_H := 22.0
const PILLAR_R := 1.6

var _pillars: Array[Vector3] = []


func configure() -> void:
	world_id = WORLD
	sky_top = Color(0.1, 0.32, 0.82)
	sky_horizon = Color(0.78, 0.88, 1.0)
	sky_bottom = Color(0.9, 0.95, 1.0)
	cloud_cover = 0.35
	cloud_shade = Color(0.78, 0.8, 0.98)
	sun_color = Color(1.0, 0.97, 0.94)
	sun_energy = 1.12
	sun_angles = Vector2(-38.0, -30.0)
	fog_color = Color(0.86, 0.92, 1.0)
	fog_begin = 90.0
	fog_end = 320.0
	tree_kinds = [&"frost", &"frost", &"blossom", &"frost", &"teal"]
	tops = {&"stone_dark": &"mush_spot", &"stone_light": &"mush_spot", &"water_light": &"mush_spot", &"bark_mid": &"mush_spot", &"sea_violet": &"mush_spot", &"bubble": &"mush_spot"}
	grass_density = 0.004


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w5_entrance"
	music = &"frostfang"
	floor_y = 0.0
	kill_y = -24.0
	_rng.seed = 505
	arena_center = ARENA
	arena_radius = ARENA_R
	arena_exit_spawn = &"w5_arena_exit"
	defeat_banner = "The Avalanche Ape is all tuckered out!"
	regions = {"village": Vector3.ZERO, "slide": Vector3(0.0, 0.0, -90.0), "caverns": Vector3(80.0, 0.0, 0.0), "pines": Vector3(-100.0, 0.0, 0.0), "gate": Vector3(0.0, 0.0, 70.0), "ape": ARENA}
	for i in 4:
		var a := PI * 0.25 + i * PI * 0.5
		_pillars.append(ARENA + Vector3(cos(a), 0.0, sin(a)) * 9.0)
	_mountain()
	_village()
	_ice_slide()
	_crystal_caverns()
	_pine_heights()
	_summit_gate()
	finish_boss_world()
	finish_life(&"bubble")


func create_boss() -> BossBase:
	var ape := AvalancheApe.new()
	ape.pillars = _pillars
	ape.pillar_radius = PILLAR_R
	ape.rng.seed = 5505
	ape.position = ARENA + Vector3(0.0, 0.0, 6.0)
	return ape


func slippery(body: Node) -> void:
	body.set_meta(&"slippery", true)


# --- The mountaintop: snowfield, ice cliffs, peaks and northern lights -----------------------------

func _mountain() -> void:
	var lake := Rect2(-100.0, -22.0, 30.0, 44.0)
	ground(Rect2(-150.0, -150.0, 300.0, 300.0), [lake], 0.0, 18.0, &"stone_dark", &"mush_spot", 0.004)
	for side in 4:
		for i in 11:
			var t := -150.0 + (i + 0.5) * 300.0 / 11.0
			var h := _rng.randf_range(20.0, 34.0)
			var c := Vector3(t, h, -162.0) if side == 0 else (Vector3(t, h, 162.0) if side == 1 else (Vector3(-162.0, h, t) if side == 2 else Vector3(162.0, h, t)))
			var size := Vector3(30.0, h + 18.0, 26.0) if side < 2 else Vector3(26.0, h + 18.0, 30.0)
			Kit.block(self, c, size, [&"water_light", &"stone_dark", &"sea_violet"][(i + side) % 3] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_spot")
	for i in 14:
		var a := float(i) / 14.0 * TAU + _rng.randf_range(-0.08, 0.08)
		Whimsy.mountain(self, Vector3(cos(a) * 280.0, -20.0, sin(a) * 280.0), _rng.randf_range(60.0, 90.0), _rng.randf_range(130.0, 200.0), true)
	Whimsy.aurora(self, Vector3(0.0, 70.0, 0.0), 230.0)
	Ambient.snow(self, Vector3(0.0, 30.0, 0.0), Vector3(240.0, 20.0, 240.0), 500)
	var caps: Array[StringName] = [&"blue", &"purple", &"teal", &"pink"]
	for i in 36:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-140.0, 140.0))
		if _busy(p):
			continue
		if i % 3 == 0:
			Whimsy.mushroom(self, p, _rng.randf_range(4.0, 9.0), _rng.randf_range(3.0, 5.5), caps[i % caps.size()])
		else:
			Whimsy.pine(self, p, &"frost", _rng.randf_range(1.2, 2.2))
	for i in 20:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-140.0, 140.0))
		if _busy(p):
			continue
		Whimsy.crystal(self, p, [&"water_light", &"crystal_violet", &"portal_teal"][i % 3] as StringName, _rng.randf_range(0.8, 1.6))
	birds(Vector3.ZERO, 80.0, 30.0, 5)
	add_capture_point("peak", Vector3(50.0, 46.0, 110.0), Vector3(0.0, 0.0, -20.0))


func _busy(p: Vector3) -> bool:
	if p.x < -66.0 and p.x > -150.0 and absf(p.z) < 30.0:
		return true
	for c: Vector3 in [Vector3.ZERO, Vector3(0.0, 0.0, -90.0), Vector3(80.0, 0.0, -30.0), Vector3(-110.0, 0.0, 0.0), Vector3(0.0, 0.0, 70.0), ARENA]:
		if Vector2(p.x - c.x, p.z - c.z).length() < 42.0:
			return true
	return absf(p.x) < 10.0 or absf(p.z) < 8.0


# --- Snowcap Village (centre) -----------------------------------------------------------------------

func _village() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w5_entrance", Vector3(0.0, 0.0, 22.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 30.0)
	add_child(exit)
	checkpoint(&"w5_cp_village", Vector3(-8.0, 0.0, 18.0))
	sign_post(Vector3(6.0, 0.0, 14.0), "Find 3 Star Shards to open\nthe Summit Gate to the south!")
	sign_post(Vector3(4.0, 0.0, -28.0), "North: Ice Slide Gorge")
	sign_post(Vector3(28.0, 0.0, -2.0), "East: Crystal Caverns", -PI * 0.5)
	sign_post(Vector3(-28.0, 0.0, 4.0), "West: Frosted Pine Heights", PI * 0.5)
	sign_post(Vector3(4.0, 0.0, 30.0), "South: Summit Gate", PI)
	# The hot spring: warm, steamy and swimmable.
	var hs := Vector3(-14.0, 0.0, -10.0)
	for spec: Array in [[0.0, -6.0, 14.0, 1.0], [0.0, 6.0, 14.0, 1.0], [-6.5, 0.0, 1.0, 11.0], [6.5, 0.0, 1.0, 11.0]]:
		ledge(hs + Vector3(spec[0] as float, 1.8, spec[1] as float), Vector3(spec[2] as float, 1.8, spec[3] as float), &"stone_dark")
	water(hs + Vector3(0.0, 1.5, 0.0), Vector2(12.0, 11.0), 1.5)
	Ambient.motes(self, hs + Vector3(0.0, 3.0, 0.0), Vector3(12.0, 4.0, 10.0), Color(1.0, 1.0, 1.0, 0.45))
	Whimsy.igloo(self, Vector3(16.0, 0.0, -12.0), deg_to_rad(-120.0), 4.0)
	Whimsy.igloo(self, Vector3(19.0, 0.0, 8.0), deg_to_rad(-70.0), 3.5)
	Whimsy.igloo(self, Vector3(-21.0, 0.0, 14.0), deg_to_rad(110.0), 3.0)
	Whimsy.snowman(self, Vector3(7.0, 0.0, 5.0), 1.1, &"roof_red")
	Whimsy.snowman(self, Vector3(-6.0, 0.0, -24.0), 0.9, &"slime_blue")
	Whimsy.snowman(self, Vector3(24.0, 0.0, -2.0), 1.4, &"candy_pink")
	for spec: Array in [["tundra", "Tundra", Vector3(9.0, 0.0, 11.0)], ["lumen", "Lumen", Vector3(-5.0, 0.0, -6.0)]]:
		var npc := Npc.new()
		npc.npc_id = str(spec[0])
		npc.display_name = str(spec[1])
		npc.position = spec[2] as Vector3
		add_child(npc)
	var path := RoundMesh.box(Vector3(4.6, 0.06, 60.0), 0.03)
	Kit.mesh_instance(self, path, Kit.mat(&"bubble"), Vector3(0.0, 0.03, 0.0))
	for z: float in [14.0, -2.0, -18.0]:
		Whimsy.lamp(self, Vector3(-3.8, 0.0, z), z > 0.0)
		Whimsy.lamp(self, Vector3(3.8, 0.0, z + 0.5), z <= 0.0)
		Whimsy.bunting(self, Vector3(-3.8, 3.0, z), Vector3(3.8, 3.0, z + 0.5), 0.5)
	for i in 14:
		var a := float(i) / 14.0 * TAU + 0.1
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.3 or absf(wrapf(a + PI * 0.5, -PI, PI)) < 0.3:
			continue
		Whimsy.pine(self, Vector3(cos(a) * 32.0, 0.0, sin(a) * 32.0), tree_kinds[i % tree_kinds.size()], _rng.randf_range(1.0, 1.5))
	Whimsy.mushroom(self, Vector3(-24.0, 0.0, -24.0), 5.0, 4.0, &"blue")
	Whimsy.mushroom(self, Vector3(22.0, 0.0, 22.0), 4.0, 3.5, &"purple")
	Whimsy.crystal(self, Vector3(12.0, 0.0, -24.0), &"crystal_violet", 1.0)
	heart_bush(Vector3(-16.0, 0.0, 24.0))
	for i in 5:
		var pg := Penguin.new()
		pg.position = Vector3(_rng.randf_range(-20.0, 20.0), 0.5, _rng.randf_range(-20.0, 24.0))
		add_child(pg)
	sparkles(Vector3(0.0, 3.0, 0.0), Vector3(50.0, 6.0, 50.0), 40)
	add_capture_point("village", Vector3(24.0, 14.0, 38.0), Vector3(-4.0, 0.0, -6.0))


# --- North: Ice Slide Gorge ------------------------------------------------------------------------

func _ice_slide() -> void:
	region(Vector3(0.0, 0.0, -40.0))
	checkpoint(&"w5_cp_slide", Vector3(-8.0, 0.0, -2.0))
	sign_post(Vector3(8.0, 0.0, -2.0), "The slope is icy! Jump the snowballs.")
	slippery(ramp(Vector3(0.0, 0.0, -6.0), 44.0, 10.0, 12.0, &"water_light"))
	for x: float in [-3.0, 3.0]:
		var roller := SnowballRoller.new()
		roller.start = P(Vector3(x, 10.0, -50.0))
		roller.end = P(Vector3(x, 0.0, -6.0))
		roller.interval = 3.4 if x < 0.0 else 4.2
		roller.speed = 8.0
		add_child(roller)
	ledge(Vector3(-9.0, 3.0, -20.0), Vector3(4.0, 1.0, 4.0), &"stone_dark")
	ledge(Vector3(10.0, 8.0, -30.0), Vector3(4.0, 1.0, 4.0), &"stone_dark")
	seed_at(&"w5_seed_slide", Vector3(10.0, 8.0, -30.0))
	# The top shelf, an icicle arch, and a floe over the gap.
	plat(Vector3(0.0, 10.0, -60.0), Vector2(24.0, 20.0), &"stone_dark")
	for x: float in [-6.0, 6.0]:
		Kit.pillar(self, P(Vector3(x, 15.0, -62.0)), 1.2, 5.0, &"water_light", &"mush_spot")
	ledge(Vector3(0.0, 17.0, -62.0), Vector3(14.0, 2.0, 4.0), &"water_light")
	for x: float in [-2.5, 0.0, 2.5]:
		var ice := Icicle.new()
		ice.ground_y = 10.0
		ice.position = P(Vector3(x, 15.0, -62.0))
		add_child(ice)
	seed_at(&"w5_seed_icicle", Vector3(0.0, 10.0, -62.0))
	critter(Hoppy, Vector3(6.0, 10.5, -56.0))
	mover(Vector3(0.0, 10.6, -72.5), Vector3(5.0, 1.0, 5.0), Vector3(0.0, 0.0, -6.0), 5.0, &"bubble")
	plat(Vector3(0.0, 12.0, -90.0), Vector2(22.0, 18.0), &"stone_dark")
	stone(Vector3(0.0, 13.5, -94.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w5_shard_slide", Vector3(0.0, 13.5, -94.0))
	critter(Armorling, Vector3(-4.0, 12.5, -86.0))
	# An ice cave at the foot of the gap.
	alcove(Vector3(0.0, 0.0, -76.0), 0.0, &"water_light")
	seed_at(&"w5_seed_crevasse", Vector3(0.0, 0.0, -76.0))
	gloplets(Vector3(10.0, 0.0, -10.0), 9.0, [Vector3.ZERO, Vector3(3.0, 0.0, -3.0)], [], preload("res://data/enemies/frost_gloplet.tres"))
	tree_line(Vector3(-16.0, 0.0, -8.0), Vector3(-16.0, 0.0, -50.0), 7.0, [&"tree_pine", &"tree_cone"], 1.2)
	tree_line(Vector3(16.0, 0.0, -8.0), Vector3(16.0, 0.0, -50.0), 7.0, [&"tree_pine", &"tree_cone"], 1.2)
	Whimsy.snowman(self, P(Vector3(-8.0, 12.0, -96.0)), 1.0, &"gold")
	add_capture_point("slide", Vector3(26.0, 20.0, -20.0), Vector3(0.0, 6.0, -80.0))


# --- East: Crystal Caverns ---------------------------------------------------------------------------

func _crystal_caverns() -> void:
	region(Vector3(40.0, 0.0, 0.0), -90.0)
	checkpoint(&"w5_cp_caverns", Vector3(0.0, 0.0, -4.0))
	sign_post(Vector3(-6.0, 0.0, -4.0), "Cracked ice breaks: three slashes,\na PLUNGE, or one Fireball!")
	var wall_c := &"water_light"
	# Outer walls (an opening at the near end).
	ledge(Vector3(-19.0, 7.0, -36.0), Vector3(2.0, 7.0, 56.0), wall_c)
	ledge(Vector3(19.0, 7.0, -36.0), Vector3(2.0, 7.0, 56.0), wall_c)
	ledge(Vector3(0.0, 7.0, -63.0), Vector3(40.0, 7.0, 2.0), wall_c)
	# Serpentine inner walls, each with a cracked shortcut.
	_maze_wall(-20.0, 6.0, -20.0, -12.0)
	_maze_wall(-6.0, 18.0, -34.0, 6.0)
	_maze_wall(-18.0, 6.0, -48.0, -10.0)
	# Seeds: one frozen in a block, one atop a crystal pillar.
	alcove(Vector3(12.0, 0.0, -27.0), -PI * 0.5, &"water_light")
	seed_at(&"w5_seed_frozen", Vector3(12.0, 0.0, -27.0))
	ledge(Vector3(-13.0, 2.0, -26.0), Vector3(2.5, 2.0, 2.5), &"crystal_violet")
	Kit.pillar(self, P(Vector3(-13.0, 5.0, -30.0)), 1.4, 5.0, &"crystal_violet", &"mush_spot")
	seed_at(&"w5_seed_maze", Vector3(-13.0, 5.0, -30.0))
	# The shard at the far end; a thunder crystal raises steps to a high ledge.
	stone(Vector3(4.0, 1.5, -57.0), 2.6, 1.5, &"stone_light", &"gold")
	shard_at(&"w5_shard_cavern", Vector3(4.0, 1.5, -57.0))
	var bell := CrystalSwitch.new()
	bell.needs = &"thunder"
	bell.position = P(Vector3(-12.0, 0.0, -56.0))
	add_child(bell)
	sign_post(Vector3(-8.0, 0.0, -53.0), "This crystal only answers to thunder.")
	var steps: Array[GhostPlatform] = []
	for i in 3:
		var g := GhostPlatform.new()
		g.size = Vector3(3.0, 0.6, 3.0)
		g.color_name = &"gold"
		g.position = P(Vector3(6.0 + i * 3.5, 3.0 + i * 2.5, -54.0 - i * 1.5))
		add_child(g)
		steps.append(g)
	bell.lit_changed.connect(func(on: bool) -> void:
		if on:
			for g in steps:
				g.set_solid(true))
	ledge(Vector3(15.5, 10.5, -58.0), Vector3(3.0, 0.6, 3.0), &"gold")
	seed_at(&"w5_seed_thunder", Vector3(15.5, 10.5, -58.0))
	critter(Batling, Vector3(-6.0, 5.0, -28.0))
	critter(Batling, Vector3(8.0, 5.0, -44.0))
	critter(Armorling, Vector3(10.0, 0.5, -14.0))
	critter(Armorling, Vector3(-10.0, 0.5, -54.0))
	gloplets(Vector3(0.0, 0.0, -40.0), 8.0, [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 2.0)], [], preload("res://data/enemies/frost_gloplet.tres"))
	for i in 18:
		var p := Vector3(_rng.randf_range(-17.0, 17.0), 0.0, _rng.randf_range(-61.0, -8.0))
		Whimsy.crystal(self, P(p), [&"water_light", &"crystal_violet", &"portal_teal", &"candy_pink"][i % 4] as StringName, _rng.randf_range(0.5, 1.1), false)
	for i in 10:
		Whimsy.crystal(self, P(Vector3(-19.0 + (i % 2) * 38.0, 14.0, -12.0 - i * 5.0)), &"crystal_violet", 1.4, false)
	add_capture_point("caverns", Vector3(40.0, 22.0, 26.0), Vector3(90.0, 0.0, 0.0))


## A maze wall across the caverns from x0 to x1 (local) at z, with a cracked section at crack_x.
func _maze_wall(x0: float, x1: float, z: float, crack_x: float) -> void:
	var a := crack_x - 2.0
	var b := crack_x + 2.0
	if a > x0:
		ledge(Vector3((x0 + a) * 0.5, 7.0, z), Vector3(a - x0, 7.0, 1.5), &"water_light")
	if x1 > b:
		ledge(Vector3((b + x1) * 0.5, 7.0, z), Vector3(x1 - b, 7.0, 1.5), &"water_light")
	ledge(Vector3(crack_x, 7.0, z), Vector3(4.0, 3.0, 1.5), &"water_light")
	var w := BreakableWall.new()
	w.size = Vector3(4.0, 4.0, 1.5)
	w.color_name = &"water_light"
	w.position = P(Vector3(crack_x, 0.0, z))
	w.rotation.y = Y()
	add_child(w)


# --- West: Frosted Pine Heights ----------------------------------------------------------------------

func _pine_heights() -> void:
	region(Vector3(-40.0, 0.0, 0.0), 90.0)
	checkpoint(&"w5_cp_pines", Vector3(0.0, 0.0, -4.0))
	sign_post(Vector3(6.0, 0.0, -4.0), "Hop across on the drifting floes!")
	# Ice sheet on the shore, then the frozen lake (swimmable, if chilly).
	slippery(ledge(Vector3(0.0, 0.08, -19.0), Vector3(44.0, 0.3, 22.0), &"bubble"))
	Kit.block(self, Vector3(-85.0, -6.0, 0.0), Vector3(30.0, 12.0, 44.0), &"stone_dark", Layers.WORLD | Layers.CAMERA_BLOCKER, &"water_light")
	Kit.water(self, Vector3(-85.0, -0.6, 0.0), Vector2(30.0, 44.0), 5.4)
	seed_at(&"w5_seed_lake_bottom", Vector3(8.0, -6.0, -45.0))
	for spec: Array in [[-8.0, -34.0, 16.0, 6.0], [8.0, -41.0, -16.0, 6.5], [-8.0, -48.0, 16.0, 6.0], [8.0, -55.0, -16.0, 7.0]]:
		mover(Vector3(spec[0] as float, 0.0, spec[1] as float), Vector3(5.0, 1.0, 5.0), Vector3(spec[2] as float, 0.0, 0.0), spec[3] as float, &"bubble")
	stone(Vector3(20.0, 0.2, -46.0), 2.0, 1.0, &"bubble", &"mush_spot")
	seed_at(&"w5_seed_floe", Vector3(20.0, 0.2, -46.0))
	# Pine-topped tiers up to the shard.
	plat(Vector3(0.0, 3.0, -68.0), Vector2(24.0, 14.0), &"stone_dark")
	plat(Vector3(-8.0, 7.0, -84.0), Vector2(16.0, 14.0), &"stone_dark")
	plat(Vector3(8.0, 11.0, -98.0), Vector2(14.0, 12.0), &"stone_dark")
	stone(Vector3(8.0, 12.5, -100.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w5_shard_pines", Vector3(8.0, 12.5, -100.0))
	critter(Hoppy, Vector3(4.0, 3.5, -68.0))
	critter(Hoppy, Vector3(-8.0, 7.5, -84.0))
	bouncer(Vector3(3.0, 11.0, -95.0), Springcap.Look.MUSHROOM, 6.0, 11.0)
	ledge(Vector3(-4.0, 17.0, -96.0), Vector3(3.0, 0.6, 3.0), &"water_light")
	seed_at(&"w5_seed_pine_top", Vector3(-4.0, 17.0, -96.0))
	Whimsy.pine(self, P(Vector3(-12.0, 7.0, -88.0)), &"frost", 3.0)
	Whimsy.pine(self, P(Vector3(-6.0, 3.0, -72.0)), &"blossom", 1.6)
	for i in 6:
		var pg := Penguin.new()
		pg.position = P(Vector3(_rng.randf_range(-16.0, 16.0), 0.6, _rng.randf_range(-28.0, -10.0)))
		add_child(pg)
	gloplets(Vector3(0.0, 3.0, -66.0), 7.0, [Vector3(-3.0, 0.0, 0.0), Vector3(4.0, 0.0, 2.0)], [], preload("res://data/enemies/frost_gloplet.tres"))
	tree_line(Vector3(-24.0, 0.0, -8.0), Vector3(-24.0, 0.0, -28.0), 6.0, [&"tree_pine", &"tree_cone"], 1.2)
	tree_line(Vector3(24.0, 0.0, -8.0), Vector3(24.0, 0.0, -28.0), 6.0, [&"tree_pine", &"tree_cone"], 1.2)
	add_capture_point("pines", Vector3(-40.0, 22.0, 30.0), Vector3(-100.0, 4.0, 0.0))


# --- South: Summit Gate and the Avalanche Ape's ring ---------------------------------------------------

func _summit_gate() -> void:
	region(Vector3(0.0, 0.0, 40.0), 180.0)
	for x: float in [-16.0, 16.0]:
		Kit.block(self, P(Vector3(x, WALL_H, -27.0)), S(Vector3(6.0, WALL_H, 46.0)), &"water_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_spot")
	sign_post(Vector3(5.0, 0.0, -6.0), "The Summit Gate opens for 3 Star Shards.")
	var roller := SnowballRoller.new()
	roller.start = P(Vector3(-12.0, 0.0, -24.0))
	roller.end = P(Vector3(12.0, 0.0, -24.0))
	roller.interval = 3.0
	roller.speed = 7.0
	add_child(roller)
	critter(Armorling, Vector3(0.0, 0.5, -34.0))
	critter(Hoppy, Vector3(4.0, 0.5, -14.0))
	ledge(Vector3(-11.0, 2.5, -14.0), Vector3(4.0, 1.0, 4.0), &"water_light")
	ledge(Vector3(-11.0, 5.0, -20.0), Vector3(4.0, 1.0, 4.0), &"crystal_violet")
	ledge(Vector3(-11.0, 7.5, -30.0), Vector3(4.0, 1.0, 4.0), &"water_light")
	seed_at(&"w5_seed_summit", Vector3(-11.0, 7.5, -30.0))
	checkpoint(&"w5_cp_gate", Vector3(0.0, 0.0, -42.0))
	heart_bush(Vector3(8.0, 0.0, -44.0))
	for x: float in [-9.5, 9.5]:
		Kit.block(self, P(Vector3(x, WALL_H, -49.5)), S(Vector3(7.0, WALL_H, 3.0)), &"water_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_spot")
	Kit.block(self, P(Vector3(0.0, WALL_H, -49.5)), S(Vector3(12.0, WALL_H - 4.2, 3.0)), &"crystal_violet", Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_spot")
	make_gate(Vector3(0.0, 0.0, -49.5), 12.0)
	var n := 30
	for i in n:
		var a := float(i) / n * TAU
		if absf(wrapf(a + PI * 0.5, -PI, PI)) < deg_to_rad(17.0):
			continue
		var c := ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R + 2.0)
		var b := Kit.block(self, c + Vector3(0.0, WALL_H, 0.0), Vector3(4.9, WALL_H, 3.0), [&"water_light", &"bubble", &"crystal_violet"][i % 3] as StringName, Layers.WORLD | Layers.CAMERA_BLOCKER, &"mush_spot")
		b.rotation.y = -(a + PI * 0.5)
	for p in _pillars:
		Kit.pillar(self, p + Vector3(0.0, 5.0, 0.0), PILLAR_R, 5.0, &"water_light", &"mush_spot")
	for i in 6:
		var a := float(i) / 6.0 * TAU + 0.2
		Whimsy.crystal(self, ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R - 1.0), &"water_light", 1.1, false)
	sign_post(Vector3(-5.0, 0.0, -44.0), "Dodge its belly-slide into a frozen pillar,\nthen PLUNGE onto its dizzy head!")
	add_capture_point("gate", Vector3(0.0, 14.0, 52.0), Vector3(0.0, 2.0, 92.0))
	add_capture_point("ape", ARENA + Vector3(0.0, 16.0, -12.0), ARENA + Vector3(0.0, 0.0, 6.0))
