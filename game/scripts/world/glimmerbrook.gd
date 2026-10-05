class_name Glimmerbrook
extends OpenWorld
## World 1, Glimmerbrook Wilds, rebuilt as a small open world (Build 4). From the Stump Ring
## Meadow in the middle, four regions open in any order:
##   North  Fernway Cliffs  - slimes, shelf mushrooms, the Springcap Plunge up to the Cliff Garden
##   East   River & Falls   - stepping stones, slow rafts, sinking lily pads, swimming, a waterfall
##   West   Mushroom Grove  - coconut monkeys and a route over giant mushroom caps
##   South  Sunny Glade     - the Lily Gate to Gloop Lake (Mother Gloop)
## A Star Shard waits at the top of the Cliff Garden, the waterfall and the treetops; all three
## open the Lily Gate. 10 Glimmer Seeds, 4 of them hidden. Platforms are big and low (Ashwin).

const WORLD := &"world_01"
const CLIFF := 11.5
const SEED_LEDGE_RISE := 10.5
const ARENA_CENTER := Vector3(0.0, 0.0, 112.0)
const ARENA_RADIUS := 18.0
const TREES: Array[StringName] = [&"tree_default", &"tree_oak", &"tree_detailed", &"tree_fat", &"tree_tall"]
const REGIONS: Dictionary[String, Vector3] = {
	"meadow": Vector3.ZERO, "fernway": Vector3(0.0, 0.0, -60.0), "cliff_garden": Vector3(0.0, 0.0, -100.0),
	"river": Vector3(70.0, 0.0, 0.0), "falls": Vector3(128.0, 0.0, 0.0), "grove": Vector3(-66.0, 0.0, 0.0),
	"glade": Vector3(0.0, 0.0, 58.0), "gloop_lake": ARENA_CENTER,
}

var boss: MotherGloop
var gate: VineGate
var return_arch: Portal
var fight_started: bool = false
var _section: String = ""
var _victory_running: bool = false


func configure() -> void:
	world_id = WORLD
	tree_kinds = [&"green", &"lime", &"green", &"blossom", &"green", &"teal", &"lime", &"autumn"]


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w1_entrance"
	music = &"glimmerbrook"
	kill_y = floor_y - 10.0
	_rng.seed = 2026
	_forest_floor()
	_meadow()
	_fernway()
	_river_and_falls()
	_bonk_grove()
	_glade_and_lake()
	_sky()
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life()
	Events.boss_defeated.connect(_on_boss_defeated)


# --- The forest the world stands in ----------------------------------------------------------

func _forest_floor() -> void:
	Kit.block(self, Vector3(0.0, floor_y, 0.0), Vector3(520.0, 2.0, 520.0), &"grass_mid", Layers.WORLD)
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(520.0, 6.0, 520.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(0.0, floor_y + 2.5, 0.0)
	add_child(pit)
	var trees: Array[StringName] = [&"tree_pine", &"tree_cone", &"tree_default", &"tree_oak", &"tree_tall", &"tree_fat"]
	for i in 320:
		var p := Vector3(_rng.randf_range(-230.0, 230.0), floor_y + 1.0, _rng.randf_range(-230.0, 230.0))
		if _near_land(p):
			continue
		Props.spawn(self, trees[i % trees.size()], p, _rng.randf() * TAU, _rng.randf_range(1.6, 2.6), false, &"leaf_dark" if i % 3 == 0 else &"")
	# Build 5: giant mushrooms rise out of the forest all around (Ashwin: "giant mushroom forests").
	var caps: Array[StringName] = [&"red", &"purple", &"teal", &"orange", &"pink", &"red", &"blue"]
	for i in 70:
		var p := Vector3(_rng.randf_range(-200.0, 200.0), floor_y + 1.0, _rng.randf_range(-200.0, 200.0))
		if _near_land(p):
			continue
		Whimsy.mushroom(self, p, _rng.randf_range(8.0, 22.0), _rng.randf_range(4.0, 9.0), caps[i % caps.size()])
	# Rolling hills and big trees at the edge of the world.
	for i in 36:
		var a := float(i) / 36.0 * TAU + _rng.randf_range(-0.05, 0.05)
		var r := _rng.randf_range(190.0, 230.0)
		Whimsy.hill(self, Vector3(cos(a) * r, floor_y, sin(a) * r), _rng.randf_range(40.0, 60.0), _rng.randf_range(0.7, 1.1))
	for i in 40:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(150.0, 190.0)
		Whimsy.tree(self, Vector3(cos(a) * r, floor_y + 1.0, sin(a) * r), tree_kinds[i % tree_kinds.size()], _rng.randf_range(2.6, 3.6), -1, _rng.randf() * TAU, false)


## True near the walkable plateaus, so floor trees don't poke up through them.
func _near_land(p: Vector3) -> bool:
	for c: Vector3 in REGIONS.values():
		if Vector2(p.x - c.x, p.z - c.z).length() < 48.0:
			return true
	return false


# --- Stump Ring Meadow (centre) ---------------------------------------------------------------

func _meadow() -> void:
	region(Vector3.ZERO)
	disc(Vector3.ZERO, 34.0)
	add_spawn(&"w1_entrance", P(Vector3(0.0, 0.0, 14.0)))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 24.0)
	add_child(exit)
	checkpoint(&"w1_cp_stump", Vector3(-9.0, 0.0, 10.0))
	sign_post(Vector3(5.0, 0.0, 9.0), "Find 3 Star Shards to open\nthe Lily Gate to the south!")
	sign_post(Vector3(-4.0, 0.0, -28.0), "North: Fernway Cliffs")
	sign_post(Vector3(28.0, 0.0, -4.0), "East: River & Waterfall", -PI * 0.5)
	sign_post(Vector3(-28.0, 0.0, 4.0), "West: Mushroom Grove", PI * 0.5)
	sign_post(Vector3(5.0, 0.0, 28.0), "South: Lily Gate", PI)
	sign_post(Vector3(-5.0, 0.0, 18.0), "Space: jump (x3)  F: attack\nShift in the air: PLUNGE")
	# The old stump the meadow is named for.
	Kit.pillar(self, Vector3(0.0, 1.6, -4.0), 4.5, 1.6, &"bark_mid", &"bark_light")
	for i in 6:
		var a := float(i) / 6.0 * TAU
		prop(&"mushroom_red_group", Vector3(cos(a) * 5.4, 0.0, -4.0 + sin(a) * 5.4), a, 1.3, false)
	# Trees around the edge, leaving the four exits open.
	for i in 40:
		var a := float(i) / 40.0 * TAU
		var exit_gap := false
		for e: float in [0.0, PI * 0.5, PI, PI * 1.5]:
			if absf(wrapf(a - e, -PI, PI)) < 0.32:
				exit_gap = true
		if exit_gap:
			continue
		prop(TREES[i % TREES.size()], Vector3(cos(a) * 30.0, 0.0, sin(a) * 30.0), _rng.randf() * TAU, _rng.randf_range(1.0, 1.4))
	gloplets(Vector3(14.0, 0.0, -14.0), 8.0, [Vector3.ZERO, Vector3(3.0, 0.0, -3.0)])
	scatter(Vector3.ZERO, Vector2(26.0, 26.0), 40, [&"bush", &"bush_small", &"mushroom_red_group", &"mushroom_tan_group", &"rock_small", &"stump"], 9.0)
	heart_bush(Vector3(-18.0, 0.0, -16.0))
	# Giant flowers to bounce about on, and glowing crystals by the old stump.
	Whimsy.flower(self, P(Vector3(16.0, 0.0, 10.0)), 2.5, 2.5, &"candy_pink")
	Whimsy.flower(self, P(Vector3(20.0, 0.0, 16.0)), 4.5, 2.5, &"gold")
	Whimsy.flower(self, P(Vector3(-16.0, 0.0, 14.0)), 3.0, 2.0, &"slime_blue")
	Whimsy.crystal(self, P(Vector3(-6.0, 0.0, -10.0)), &"crystal_violet", 0.9)
	Whimsy.crystal(self, P(Vector3(7.0, 0.0, -9.0)), &"portal_teal", 0.7)
	animals(Bunny, Vector3.ZERO, 22.0, 8)
	butterflies(Vector3(0.0, 0.0, 0.0), 20.0, 10)
	sparkles(Vector3(0.0, 2.0, 0.0), Vector3(50.0, 4.0, 50.0), 60)
	add_capture_point("meadow", Vector3(20.0, 14.0, 40.0), Vector3(0.0, 0.0, -10.0))


# --- North: Fernway Cliffs --------------------------------------------------------------------

func _fernway() -> void:
	region(Vector3(0.0, 0.0, -34.0))
	plat(Vector3(0.0, 0.0, -23.5), Vector2(30.0, 53.0))
	prop(&"log_large", Vector3(-4.0, 0.0, -10.0), PI * 0.5, 1.7)
	prop(&"log_large", Vector3(5.0, 0.0, -15.0), PI * 0.5 + 0.2, 1.4)
	gloplets(Vector3(-3.0, 0.0, -30.0), 9.0, [Vector3.ZERO, Vector3(-4.0, 0.0, -5.0), Vector3(4.0, 0.0, -6.0)])
	ledge(Vector3(-12.0, 1.2, -30.0), Vector3(2.6, 1.2, 18.0), &"bark_light")
	# Optional shelf mushrooms up to a seed.
	mushroom_platform(Vector3(-10.0, 3.0, -12.0), 0.0, 3.0, &"orange")
	mushroom_platform(Vector3(-11.0, 6.0, -19.0), 0.0, 3.0, &"pink")
	var shelf_top := mushroom_platform(Vector3(-9.0, 9.0, -26.0), 0.0, 3.0, &"red")
	Pickup.spawn_seed(self, shelf_top, &"w1_seed_fernway")
	_fern_nook()
	# The Springcap: Plunge onto it to reach the Cliff Garden.
	bouncer(Vector3(0.0, 0.0, -45.0))
	sign_post(Vector3(-6.0, 0.0, -42.0), "Spotted mushrooms bounce!\nJump, then PLUNGE onto it:\nShift / B")
	tree_line(Vector3(14.0, 0.0, -2.0), Vector3(14.0, 0.0, -48.0), 7.0, TREES)
	tree_line(Vector3(-14.0, 0.0, -36.0), Vector3(-14.0, 0.0, -48.0), 6.0, TREES)
	scatter(Vector3(0.0, 0.0, -24.0), Vector2(12.0, 22.0), 30, [&"bush", &"mushroom_tan_group", &"rock_small", &"bush_small"], 0.0)
	animals(Bunny, Vector3(0.0, 0.0, -20.0), 10.0, 3)
	# Cliff Garden on top.
	plat(Vector3(0.0, CLIFF, -66.0), Vector2(42.0, 32.0))
	checkpoint(&"w1_cp_clearing", Vector3(0.0, CLIFF, -54.0))
	gloplets(Vector3(-8.0, CLIFF, -68.0), 10.0, [Vector3.ZERO, Vector3(-4.0, 0.0, 4.0), Vector3(3.0, 0.0, -4.0)])
	gloplets(Vector3(11.0, CLIFF, -70.0), 6.0, [], [Vector3.ZERO])
	ledge(Vector3(15.0, CLIFF + SEED_LEDGE_RISE, -77.0), Vector3(5.0, 1.2, 5.0), &"stone_light")
	seed_at(&"w1_seed_clearing", Vector3(15.0, CLIFF + SEED_LEDGE_RISE, -77.0))
	sign_post(Vector3(7.0, CLIFF, -63.0), "Blue slimes go flat after a lunge.\nLand on one to bounce sky-high!")
	disc(Vector3(-12.0, CLIFF + 1.5, -77.0), 4.0, &"bark_mid", &"grass_mid", 10)
	shard_at(&"w1_shard_cliff", Vector3(-12.0, CLIFF + 1.5, -77.0))
	_hollow_tree(P(Vector3(-15.0, CLIFF, -60.0)), 3.2, 7.0, Y(0.0), &"w1_seed_hollow_tree")
	tree_line(Vector3(19.0, CLIFF, -54.0), Vector3(19.0, CLIFF, -80.0), 6.5, TREES)
	tree_line(Vector3(-19.0, CLIFF, -70.0), Vector3(-19.0, CLIFF, -80.0), 6.0, TREES)
	scatter(Vector3(0.0, CLIFF, -66.0), Vector2(18.0, 13.0), 30, [&"bush", &"flower_red_b", &"mushroom_red", &"rock_small"], 0.0)
	heart_bush(Vector3(5.0, CLIFF, -80.0))
	sign_post(Vector3(-4.0, CLIFF, -52.0), "Drop off the cliff to go back down.")
	butterflies(Vector3(0.0, CLIFF, -66.0), 14.0, 6)
	sparkles(Vector3(0.0, CLIFF + 2.0, -66.0), Vector3(36.0, 4.0, 28.0), 40)
	Whimsy.flower(self, P(Vector3(12.0, CLIFF, -60.0)), 3.0, 2.0, &"candy_pink")
	Whimsy.crystal(self, P(Vector3(-16.0, CLIFF, -74.0)), &"crystal_violet")
	animals(Bunny, Vector3(0.0, CLIFF, -70.0), 12.0, 3)
	add_capture_point("fernway", Vector3(16.0, 12.0, -10.0), Vector3(0.0, 4.0, -70.0))
	add_capture_point("cliff_garden", Vector3(-20.0, CLIFF + 10.0, -84.0), Vector3(0.0, CLIFF, -100.0))


## Hidden nook in a rock outcrop beside the Fernway path, its doorway half hidden by bushes.
func _fern_nook() -> void:
	var c := Vector3(10.0, 0.0, -38.0)
	ledge(c + Vector3(4.0, 5.0, 0.0), Vector3(1.0, 5.0, 9.0), &"stone_dark")
	ledge(c + Vector3(0.0, 5.0, 4.5), Vector3(9.0, 5.0, 1.0), &"stone_dark")
	ledge(c + Vector3(0.0, 5.0, -4.5), Vector3(9.0, 5.0, 1.0), &"stone_dark")
	ledge(c + Vector3(-4.0, 5.0, 2.75), Vector3(1.0, 5.0, 3.5), &"stone_dark")
	ledge(c + Vector3(-4.0, 5.0, -2.75), Vector3(1.0, 5.0, 3.5), &"stone_dark")
	ledge(c + Vector3(-4.0, 5.0, 0.0), Vector3(1.0, 1.5, 2.2), &"stone_dark")
	ledge(c + Vector3(0.0, 6.0, 0.0), Vector3(10.0, 1.0, 10.0), &"stone_dark")
	seed_at(&"w1_seed_fern_nook", c + Vector3(1.5, 0.0, 0.0))
	heart_at(c + Vector3(1.0, 0.0, 2.5))
	prop(&"mushroom_red_group", c + Vector3(2.5, 0.0, -2.5), 0.4, 1.4, false)
	_glow(P(c + Vector3(0.0, 2.5, 0.0)), &"gold", 1.2, 7.0)
	prop(&"bush_detailed", c + Vector3(-5.0, 0.0, 1.0), 0.3, 1.2, false)
	prop(&"bush_detailed", c + Vector3(-5.0, 0.0, -1.2), 1.3, 1.1, false)


## A hollow tree you can walk into (hidden area): a ring of bark with a gap facing the meadow.
func _hollow_tree(center: Vector3, radius: float, height: float, opening_yaw: float, seed_id: StringName) -> void:
	for i in 14:
		var a := float(i) / 14.0 * TAU
		if absf(wrapf(a - opening_yaw, -PI, PI)) < 0.42:
			continue
		var p := center + Vector3(cos(a), 0.0, sin(a)) * radius
		var seg := Kit.block(self, p + Vector3(0.0, height, 0.0), Vector3(1.6, height, 1.3), &"bark_mid")
		seg.rotation.y = -a
	Kit.pillar(self, center + Vector3(0.0, height + 0.8, 0.0), radius + 0.9, 1.6, &"bark_mid", &"bark_light")
	for spec: Array in [[0.0, 3.0, 0.0, 4.6], [-2.2, 1.8, 1.5, 3.4], [2.4, 2.0, -1.2, 3.6], [0.5, 1.4, 2.8, 3.0]]:
		Kit.blob(self, center + Vector3(spec[0] as float, height + 1.6 + (spec[1] as float), spec[2] as float), spec[3] as float, &"leaf_dark")
	Pickup.spawn_seed(self, center, seed_id)
	Pickup.spawn_heart(self, center + Vector3(0.8, 0.4, 0.8))
	Props.spawn(self, &"mushroom_tan_group", center + Vector3(-1.0, 0.0, -0.8), 0.0, 1.2, false)
	_glow(center + Vector3(0.0, 2.0, 0.0), &"gold", 1.4, 6.0)


func _glow(at: Vector3, color: StringName, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = Palette.color(color)
	l.light_energy = energy
	l.omni_range = range_m
	l.position = at
	add_child(l)


# --- East: River & Waterfall ------------------------------------------------------------------

func _river_and_falls() -> void:
	region(Vector3(36.0, 0.0, 0.0), -90.0)
	plat(Vector3(0.0, 0.0, -6.0), Vector2(30.0, 16.0))
	sign_post(Vector3(-6.0, 0.0, -10.0), "Rafts drift slowly. Lily pads\nsink a moment after you land.")
	# The river: wide stones, slow rafts, sinking lily pads. You can swim, too.
	water(Vector3(0.0, -1.0, -34.0), Vector2(44.0, 40.0), 4.0)
	plat(Vector3(0.0, -5.0, -34.0), Vector2(44.0, 40.0), &"stone_dark", 0)
	plat(Vector3(-23.5, 0.0, -34.0), Vector2(3.0, 40.0), &"stone_dark", 0)
	plat(Vector3(23.5, 0.0, -34.0), Vector2(3.0, 40.0), &"stone_dark", 0)
	for spec: Array in [[0.0, -19.0], [6.0, -25.0], [-2.0, -31.0]]:
		stone(Vector3(spec[0] as float, -0.3, spec[1] as float), 3.5, 1.6)
	for spec: Array in [[-37.5, 0.0], [-44.0, 0.5]]:
		var raft := MovingPlatform.new()
		raft.raft = true
		raft.size = Vector3(7.0, 1.0, 4.6)
		raft.travel = _frame.basis * Vector3(8.0, 0.0, 0.0)
		raft.period = 8.0
		raft.phase = spec[1] as float
		raft.color_name = &"bark_light"
		raft.position = P(Vector3(0.0, -0.6, spec[0] as float))
		raft.rotation.y = Y(PI * 0.5)
		add_child(raft)
	var pad := SinkingPad.new()
	pad.radius = 3.4
	pad.position = P(Vector3(0.0, -0.4, -50.0))
	add_child(pad)
	stone(Vector3(15.0, 0.6, -34.0), 3.0, 2.0)
	seed_at(&"w1_seed_river", Vector3(15.0, 0.6, -34.0))
	# Riverbed log ring (dive with Shift).
	for i in 5:
		var a := float(i) / 5.0 * TAU
		prop(&"rock_large_c", Vector3(-12.0 + cos(a) * 3.2, -5.0, -30.0 + sin(a) * 3.2), a, 0.8, false)
	prop(&"log_large", Vector3(-12.0, -5.0, -27.0), 0.4, 1.2, false)
	seed_at(&"w1_seed_riverbed", Vector3(-12.0, -4.7, -30.0))
	for i in 8:
		prop(&"waterplant", Vector3(_rng.randf_range(-18.0, 18.0), -5.0, _rng.randf_range(-16.0, -52.0)), _rng.randf() * TAU, 1.6, false)
	for i in 3:
		var duck := Duck.new()
		duck.position = P(Vector3(-14.0 + i * 12.0, -1.0, -40.0 + i * 3.0))
		duck.radius = 3.0
		add_child(duck)
	# Far bank, carved for a pool under the waterfall.
	plat(Vector3(5.0, 0.0, -66.0), Vector2(26.0, 24.0))
	plat(Vector3(-15.5, 0.0, -66.0), Vector2(5.0, 24.0))
	plat(Vector3(-10.5, 0.0, -57.0), Vector2(5.0, 6.0))
	plat(Vector3(-10.5, -7.0, -69.0), Vector2(5.0, 18.0), &"stone_dark", 0)
	water(Vector3(-10.5, -0.5, -79.0), Vector2(5.0, 38.0), 6.5)
	checkpoint(&"w1_cp_far_bank", Vector3(2.0, 0.0, -58.0))
	# Waterfall Climb: big ledges and a slow rising rock up 12 m.
	ledge(Vector3(-2.0, 3.0, -70.0), Vector3(7.0, 3.0, 7.0), &"stone_light")
	mover(Vector3(6.0, 6.0, -73.0), Vector3(6.0, 1.0, 6.0), Vector3(0.0, 5.0, 0.0), 5.0, &"stone_light")
	ledge(Vector3(13.0, 9.0, -74.0), Vector3(7.0, 1.5, 7.0), &"stone_light")
	gloplets(Vector3(13.0, 9.0, -74.0), 5.0, [Vector3(1.5, 0.0, 0.0)])
	seed_at(&"w1_seed_waterfall", Vector3(6.0, 14.0, -73.0))
	# Top of the falls, with the cliff carved around a hidden grotto behind the water.
	plat(Vector3(4.0, 12.0, -92.0), Vector2(24.0, 28.0))
	plat(Vector3(-14.5, 12.0, -92.0), Vector2(3.0, 28.0), &"stone_dark", 0)
	plat(Vector3(-10.5, -7.0, -92.0), Vector2(5.0, 28.0), &"stone_dark", 0)
	plat(Vector3(-10.5, 12.0, -101.0), Vector2(5.0, 10.0), &"stone_dark", 0)
	ledge(Vector3(-10.5, 12.0, -87.0), Vector3(5.0, 7.0, 18.0), &"stone_dark")
	ledge(Vector3(-10.5, 5.0, -79.5), Vector3(5.0, 7.5, 3.0), &"stone_dark")
	ledge(Vector3(-10.5, 0.2, -92.5), Vector3(5.0, 0.8, 6.0), &"stone_light")
	seed_at(&"w1_seed_waterfall_cave", Vector3(-10.5, 0.2, -93.5))
	heart_at(Vector3(-10.0, 0.2, -91.0))
	_glow(P(Vector3(-10.5, 2.0, -92.0)), &"gold", 1.6, 9.0)
	_glow(P(Vector3(-10.5, -3.5, -80.0)), &"portal_teal", 1.3, 6.0)
	var fall := BoxMesh.new()
	fall.size = Vector3(5.0, 14.0, 0.5)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 3.0))
	wm.set_shader_parameter(&"vertical", true)
	var fm := Kit.mesh_instance(self, fall, wm, P(Vector3(-10.5, 5.0, -77.6)))
	fm.rotation.y = Y()
	checkpoint(&"w1_cp_waterfall", Vector3(4.0, 12.0, -82.0))
	disc(Vector3(4.0, 13.5, -100.0), 3.5, &"stone_light", &"moss", 8)
	shard_at(&"w1_shard_waterfall", Vector3(4.0, 13.5, -100.0))
	gloplets(Vector3(6.0, 12.0, -92.0), 7.0, [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 3.0)])
	tree_line(Vector3(14.0, 12.0, -84.0), Vector3(14.0, 12.0, -104.0), 6.0, [&"tree_pine", &"tree_cone"])
	tree_line(Vector3(16.0, 0.0, -56.0), Vector3(16.0, 0.0, -76.0), 6.5, TREES)
	scatter(Vector3(4.0, 0.0, -66.0), Vector2(10.0, 9.0), 14, [&"bush", &"rock_small", &"mushroom_red"], 0.0)
	heart_bush(Vector3(14.0, 0.0, -60.0))
	fireflies(Vector3(-10.0, 0.0, -78.0), 6.0, 30)
	add_capture_point("river", Vector3(20.0, 10.0, 22.0), Vector3(70.0, 0.0, 0.0))
	add_capture_point("falls", Vector3(110.0, 12.0, 14.0), Vector3(116.0, 6.0, -10.0))


# --- West: Mushroom Grove (Build 5: giant mushrooms instead of plain treetops) ------------------

func _bonk_grove() -> void:
	region(Vector3(-36.0, 0.0, 0.0), 90.0)
	plat(Vector3(0.0, 0.0, -30.0), Vector2(52.0, 60.0))
	checkpoint(&"w1_cp_grove", Vector3(0.0, 0.0, -6.0))
	# Towering mushrooms over the grove (scenery you walk under).
	for spec: Array in [[-14.0, -12.0, &"purple"], [13.0, -18.0, &"teal"], [-10.0, -36.0, &"red"], [15.0, -42.0, &"blue"], [0.0, -55.0, &"pink"]]:
		giant_mushroom(Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf_range(13.0, 16.0), _rng.randf_range(6.0, 7.5), spec[2] as StringName)
	# Cap-top route: wide caps in easy steps.
	mushroom_platform(Vector3(-19.0, 2.5, -6.0), 0.0, 2.5, &"orange")
	mushroom_platform(Vector3(-13.0, 5.0, -14.0), 0.0, 3.5, &"red")
	var c2 := mushroom_platform(Vector3(-5.0, 7.5, -21.0), 0.0, 3.5, &"purple")
	var c3 := mushroom_platform(Vector3(5.0, 8.0, -28.0), 0.0, 3.5, &"teal")
	var c4 := mushroom_platform(Vector3(12.0, 7.0, -36.0), 0.0, 3.5, &"pink")
	var c5 := mushroom_platform(Vector3(4.0, 10.5, -44.0), 0.0, 3.5, &"gold")
	var c6 := mushroom_platform(Vector3(-6.0, 8.0, -49.0), 0.0, 3.5, &"red")
	var c7 := mushroom_platform(Vector3(-14.0, 6.0, -41.0), 0.0, 3.5, &"blue")
	var c8 := mushroom_platform(Vector3(14.0, 5.0, -54.0), 0.0, 3.0, &"orange")
	Pickup.spawn_shard(self, c5, &"w1_shard_grove")
	Pickup.spawn_seed(self, c7, &"w1_seed_grove")
	monkey(_locals([c2, c4]))
	monkey(_locals([c3, c6]))
	monkey(_locals([c8, c7]))
	gloplets(Vector3(0.0, 0.0, -32.0), 14.0, [Vector3(-6.0, 0.0, 6.0), Vector3(7.0, 0.0, -6.0), Vector3(-3.0, 0.0, -12.0)])
	sign_post(Vector3(-6.0, 0.0, -4.0), "Coconut monkeys! Watch for the red rings.\nSlash a coconut to send it home.", PI * 0.5)
	for spec: Array in [[4.0, -14.0], [-6.0, -26.0], [7.0, -40.0], [-3.0, -46.0]]:
		prop(&"rock_large_a", Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.2)
	tree_line(Vector3(24.0, 0.0, -6.0), Vector3(24.0, 0.0, -58.0), 7.0, TREES, 1.1)
	tree_line(Vector3(-24.0, 0.0, -10.0), Vector3(-24.0, 0.0, -58.0), 7.0, TREES, 1.1)
	scatter(Vector3(0.0, 0.0, -30.0), Vector2(22.0, 27.0), 40, [&"mushroom_red_group", &"mushroom_tan_group", &"bush", &"grass_leafs", &"stump_old"], 0.0)
	for i in 6:
		Whimsy.crystal(self, P(Vector3(_rng.randf_range(-20.0, 20.0), 0.0, _rng.randf_range(-56.0, -8.0))), [&"crystal_violet", &"portal_teal", &"candy_pink"][i % 3] as StringName, _rng.randf_range(0.6, 1.1))
	heart_bush(Vector3(18.0, 0.0, -10.0))
	heart_bush(Vector3(-18.0, 0.0, -56.0))
	fireflies(Vector3(0.0, 2.0, -32.0), 18.0, 40)
	sparkles(Vector3(0.0, 6.0, -30.0), Vector3(44.0, 12.0, 52.0), 70)
	birds(Vector3(0.0, 0.0, -30.0), 26.0, 24.0, 5)
	add_capture_point("grove", Vector3(-20.0, 16.0, 28.0), Vector3(-66.0, 4.0, 0.0))
	add_capture_point("grove_caps", Vector3(-40.0, 14.0, 6.0), Vector3(-66.0, 6.0, -6.0))


## World positions -> local positions in the current region frame (for monkey perches).
func _locals(points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var inv := Transform3D(Basis(Vector3.UP, Y()), P(Vector3.ZERO)).affine_inverse()
	for w in points:
		out.append(inv * w)
	return out


# --- South: Sunny Glade, Lily Gate and Gloop Lake ---------------------------------------------

func _glade_and_lake() -> void:
	region(Vector3(0.0, 0.0, 36.0), 180.0)
	plat(Vector3(0.0, 0.0, -20.5), Vector2(40.0, 47.0))
	gloplets(Vector3(-4.0, 0.0, -22.0), 10.0, [Vector3.ZERO, Vector3(4.0, 0.0, -3.0)], [Vector3(-5.0, 0.0, 4.0)])
	heart_bush(Vector3(14.0, 0.0, -10.0))
	heart_bush(Vector3(-14.0, 0.0, -34.0))
	checkpoint(&"w1_cp_lily_gate", Vector3(0.0, 0.0, -36.0))
	# Ridge: optional stepping pillars over the forest to a seed.
	stone(Vector3(24.0, 2.0, -10.0), 3.0, 2.0 - floor_y, &"stone_light")
	stone(Vector3(31.0, 4.0, -16.0), 3.0, 4.0 - floor_y, &"stone_light")
	stone(Vector3(37.0, 6.0, -9.0), 3.0, 6.0 - floor_y, &"stone_light")
	stone(Vector3(41.0, 8.0, -1.0), 3.0, 8.0 - floor_y, &"stone_light")
	seed_at(&"w1_seed_ridge", Vector3(41.0, 8.0, -1.0))
	# The Lily Gate: opens once you have 3 Star Shards.
	plat(Vector3(0.0, 0.0, -50.0), Vector2(10.0, 12.0))
	gate = VineGate.new()
	gate.width = 10.0
	gate.position = P(Vector3(0.0, 0.0, -50.0))
	gate.rotation.y = Y()
	add_child(gate)
	gate.set_closed.call_deferred(true)
	sign_post(Vector3(-6.0, 0.0, -44.0), "The Lily Gate opens\nfor 3 Star Shards.")
	# Gloop Lake.
	water(Vector3(0.0, -1.0, -76.0), Vector2(80.0, 56.0))
	plat(Vector3(0.0, -5.0, -76.0), Vector2(80.0, 56.0), &"stone_dark", 0)
	disc(Vector3(0.0, 0.0, -76.0), ARENA_RADIUS + 0.5, &"bark_mid", &"grass_mid", 60)
	var stump_positions: Array[Vector3] = []
	for i in 4:
		var a := PI * 0.25 + i * PI * 0.5
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * 10.0
		Kit.pillar(self, p + Vector3(0.0, 2.8, 0.0), 1.1, 2.8, &"bark_light", &"moss")
		stump_positions.append(p)
	for i in 30:
		var a := float(i) / 30.0 * TAU
		if absf(wrapf(a + PI * 0.5, -PI, PI)) < 0.26:
			continue
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * (ARENA_RADIUS + 0.3)
		# Build 5: a fairy ring of mushrooms round the arena.
		Whimsy.mushroom(self, p, 1.5 + float(i % 3) * 0.5, 1.5 + float(i % 2) * 0.5, [&"red", &"orange", &"pink", &"purple"][i % 4] as StringName)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.4
		Props.spawn(self, &"waterlily", ARENA_CENTER + Vector3(cos(a) * 26.0, -0.95, sin(a) * 22.0), a, 1.6, false)
	for i in 2:
		var duck := Duck.new()
		duck.position = ARENA_CENTER + Vector3(-28.0 + i * 56.0, -1.0, 8.0)
		duck.radius = 4.0
		add_child(duck)
	add_spawn(&"w1_arena_exit", ARENA_CENTER + Vector3(0.0, 0.0, -12.0), Vector3.BACK)
	_spawn_boss(stump_positions)
	tree_line(Vector3(19.0, 0.0, -2.0), Vector3(19.0, 0.0, -42.0), 7.0, TREES)
	tree_line(Vector3(-19.0, 0.0, -2.0), Vector3(-19.0, 0.0, -42.0), 7.0, TREES)
	scatter(Vector3(0.0, 0.0, -20.0), Vector2(16.0, 20.0), 30, [&"bush", &"flower_purple", &"mushroom_red_group", &"rock_small"], 0.0)
	animals(Bunny, Vector3(0.0, 0.0, -20.0), 14.0, 4)
	butterflies(Vector3(0.0, 0.0, -20.0), 14.0, 8)
	add_capture_point("glade", Vector3(-16.0, 10.0, 30.0), Vector3(0.0, 0.0, 70.0))
	add_capture_point("gloop_lake", ARENA_CENTER + Vector3(17.0, 14.0, -21.0), ARENA_CENTER)


func _spawn_boss(stump_positions: Array[Vector3] = []) -> void:
	if stump_positions.is_empty():
		for i in 4:
			var a := PI * 0.25 + i * PI * 0.5
			stump_positions.append(ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * 10.0)
	boss = MotherGloop.new()
	boss.arena_center = ARENA_CENTER
	boss.arena_radius = ARENA_RADIUS
	boss.stumps = stump_positions
	boss.stump_radius = 1.1
	boss.rng.seed = 1234
	boss.position = ARENA_CENTER + Vector3(0.0, 0.0, 5.0)
	add_child(boss)


func _sky() -> void:
	# Build 5: storybook blue mountains with snow caps, a rainbow over the falls.
	for i in 16:
		var a := float(i) / 16.0 * TAU + _rng.randf_range(-0.08, 0.08)
		var r := _rng.randf_range(300.0, 360.0)
		Whimsy.mountain(self, Vector3(cos(a) * r, floor_y - 20.0, sin(a) * r), _rng.randf_range(70.0, 110.0), _rng.randf_range(120.0, 200.0), i % 4 != 1)
	Whimsy.rainbow(self, Vector3(150.0, floor_y, -40.0), 90.0, -PI * 0.5 + 0.4)
	for i in 10:
		Props.spawn(self, &"cloud_big" if i % 2 == 0 else &"cloud_small", Vector3(_rng.randf_range(-200.0, 200.0), _rng.randf_range(60.0, 90.0), _rng.randf_range(-200.0, 200.0)), _rng.randf() * TAU, _rng.randf_range(2.0, 3.0), false)
	birds(Vector3.ZERO, 60.0, 40.0, 6)


func _on_shards_complete() -> void:
	gate.set_closed(false)
	if hud != null:
		hud.show_banner("The Lily Gate is open!", 2.2)
	AudioDirector.play(&"gate")


func after_spawn(spawn_id: StringName) -> void:
	# Continuing from the arena exit after a win: the boss is gone and the return arch is open.
	if spawn_id == &"w1_arena_exit" and Progress.is_world_complete(WORLD):
		if boss != null:
			boss.queue_free()
			boss = null
		_open_return_arch(false)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null:
		return
	var pos := player.global_position
	var current := ""
	var best := INF
	for key: String in REGIONS:
		var d := Vector2(pos.x - REGIONS[key].x, pos.z - REGIONS[key].z).length()
		if d < best:
			best = d
			current = key
	if current != _section:
		if _section != "":
			Telemetry.log_event("section_left", {"section": _section})
		_section = current
		Telemetry.log_event("section_entered", {"section": current})
	var in_arena := Vector2(pos.x - ARENA_CENTER.x, pos.z - ARENA_CENTER.z).length() < ARENA_RADIUS - 3.0 and pos.y > ARENA_CENTER.y - 2.0
	if not fight_started and boss != null and in_arena:
		fight_started = true
		gate.set_closed(true)
		boss.start_fight()
		AudioDirector.play_music(&"boss")
	if boss != null and hud != null:
		hud.set_boss(boss.hp, MotherGloop.MAX_HP, fight_started and boss.state != MotherGloop.S.GONE)


## The victory commit happens before any presentation (plan §9.8).
func _on_boss_defeated(defeated_world: StringName) -> void:
	if defeated_world != WORLD or _victory_running:
		return
	_victory_running = true
	var first_clear := Progress.commit_victory(WORLD)
	Telemetry.log_event("boss_defeated", {"first_clear": first_clear})
	for m in get_tree().get_nodes_in_group(&"boss_minion"):
		m.queue_free()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	AudioDirector.play_music(&"victory", 0.3)
	hud.show_banner("Mother Gloop popped!", 2.0)
	player.refill()
	player.cheer()
	await get_tree().create_timer(2.8).timeout
	if not is_inside_tree():
		return
	if first_clear:
		hud.show_banner("New heart!  Glimmer Crest found!", 2.5)
		AudioDirector.play(&"seed")
	gate.set_closed(false)
	_open_return_arch(true)


func _open_return_arch(animate: bool) -> void:
	if return_arch != null:
		return
	return_arch = Portal.new()
	return_arch.target_scene = Progress.HUB_SCENE
	return_arch.target_spawn = &"hub_rootway_exit"
	return_arch.cleared = true
	return_arch.label_text = "Home to Mossbrook"
	return_arch.position = ARENA_CENTER + Vector3(0.0, 0.0, 3.0)
	return_arch.rotation.y = PI
	add_child(return_arch)
	if animate:
		return_arch.scale = Vector3.ONE * 0.05
		create_tween().tween_property(return_arch, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)
		Fx.burst(self, return_arch.global_position + Vector3.UP, Palette.color(&"portal_teal"), 24, 5.0)


## Dying resets the fight: her HP and scale, minions, goo and rings; you start at the checkpoint.
func on_player_respawned() -> void:
	if boss == null or boss.defeated_count > 0:
		return
	for n in get_children():
		if n is GooPuddle or n is Shockwave or (n is Gloplet and n.is_in_group(&"boss_minion")):
			n.queue_free()
	boss.queue_free()
	_spawn_boss()
	fight_started = false
	gate.set_closed(not lock.open)
	AudioDirector.play_music(&"glimmerbrook")
