class_name Glimmerbrook
extends Level
## World 1, Glimmerbrook Wilds (plan §5.3), all nine sections: Stump Ring -> Fernway (Springcap
## teaches the Plunge) -> Sunny Clearing (Gloplets, Bouncer) -> River Crossing (stones, drifting
## logs, sinking lily pads) -> Bonk Grove (coconut monkeys, canopy route) -> Waterfall Climb
## (rising rock) -> Ridge Run (bridges over the forest) -> Lily Gate -> Gloop Lake (Mother Gloop).
## The route runs toward -Z.
##
## Build 2: fitted to Ashwin's tuning (J1 3.4 m, triple about 9.4 m, run 12 m/s). The Fernway cliff
## is 14 m, out of triple-jump reach, so the Springcap Plunge stays required. The plateaus stand on
## a forest floor (falling in costs ½ heart). Dressed with Kenney Nature Kit and KayKit (CC0).

const WORLD := &"world_01"
const GLOPLET := preload("res://data/enemies/gloplet.tres")
const BOUNCER := preload("res://data/enemies/bouncer.tres")
const FLOOR_Y := -14.0
const FERN_Y := 5.0
const CLIFF := 14.0
const TOP_Y := FERN_Y + CLIFF
const SEED_LEDGE_RISE := 11.5
const WATERFALL_RISE := 18.0
const RIDGE_Y := TOP_Y + WATERFALL_RISE
const ARENA_CENTER := Vector3(0.0, RIDGE_Y, -396.0)
const ARENA_RADIUS := 18.0
const FIGHT_TRIGGER_Z := -377.0
## Section boundaries along -Z for the event log (plan §7.3).
const SECTIONS: Array[Array] = [
	["s1_stump_ring", 14.0], ["s2_fernway", -18.0], ["s3_sunny_clearing", -70.0],
	["s4_river_crossing", -126.0], ["s5_bonk_grove", -184.0], ["s6_waterfall_climb", -248.0],
	["s7_ridge_run", -268.0], ["s8_lily_gate", -346.0], ["s9_gloop_lake", -375.0],
]

var boss: MotherGloop
var gate: VineGate
var return_arch: Portal
var fight_started: bool = false
var _section: String = ""
var _victory_running: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w1_entrance"
	music = &"glimmerbrook"
	kill_y = FLOOR_Y - 10.0
	_rng.seed = 2026
	_forest_floor()
	_stump_ring()
	_fernway()
	_sunny_clearing()
	_river()
	_bonk_grove()
	_waterfall_climb()
	_ridge_run()
	_lily_gate()
	_arena()
	_scenery()
	Events.boss_defeated.connect(_on_boss_defeated)


# --- Helpers ----------------------------------------------------------------------------------

## A plateau whose sides run all the way down to the forest floor.
func _plateau(top_center: Vector3, size_xz: Vector2, color: StringName = &"bark_mid") -> StaticBody3D:
	return Kit.block(self, top_center, Vector3(size_xz.x, top_center.y - FLOOR_Y, size_xz.y), color)


func _sign(pos: Vector3, text: String, yaw: float = 0.0) -> void:
	Props.spawn(self, &"sign", pos, yaw, 1.6, false)
	var l := Kit.label(self, pos + Vector3(0.0, 2.4, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _checkpoint(id: StringName, pos: Vector3, look: Vector3 = Vector3.FORWARD) -> void:
	var cp := Checkpoint.new()
	cp.checkpoint_id = id
	cp.world_id = WORLD
	cp.position = pos + Vector3(3.0, 0.0, 0.0)
	add_child(cp)
	add_spawn(id, pos, look)


func _seed(id: StringName, pos: Vector3) -> void:
	Pickup.spawn_seed(self, pos, id)


func _heart_bush(pos: Vector3) -> void:
	Props.spawn(self, &"bush_large", pos, _rng.randf() * TAU, 1.0, false)
	Pickup.spawn_heart(self, pos + Vector3(0.0, 1.4, 0.0))


func _zone(id: StringName, center: Vector3, radius: float, bypass: String, spawns: Array[Array]) -> EncounterZone:
	var zone := EncounterZone.new()
	zone.zone_id = id
	zone.radius = radius
	zone.bypass_note = bypass
	zone.position = center
	for s in spawns:
		zone.add_spawn(s[0] as Vector3, s[1] as EnemyDef)
	add_child(zone)
	return zone


func _monkey(perches: Array[Vector3]) -> BonkMonkey:
	var m := BonkMonkey.new()
	m.perches = perches
	add_child(m)
	return m


## Wooden canopy platform (with a rim of leaves) for the Bonk Grove's high route.
func _canopy(top_center: Vector3, size: float) -> void:
	Kit.block(self, top_center, Vector3(size, 0.8, size), &"wood_plank")
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.4
		Props.spawn(self, &"bush_small", top_center + Vector3(cos(a), 0.0, sin(a)) * size * 0.42, a, 0.9, false)


## Scatter non-colliding decoration over a rectangle of ground (x0..x1, z0..z1) at height y.
func _scatter(y: float, x0: float, x1: float, z0: float, z1: float, count: int, ids: Array[StringName], keep_clear: float = 0.0) -> void:
	for i in count:
		var p := Vector3(_rng.randf_range(x0, x1), y, _rng.randf_range(z0, z1))
		if keep_clear > 0.0 and absf(p.x) < keep_clear:
			continue
		Props.spawn(self, ids[_rng.randi() % ids.size()], p, _rng.randf() * TAU, _rng.randf_range(0.8, 1.25), false)


## Trees along a section's edges (trunks collide; canopies never block the camera).
func _tree_row(y: float, x: float, z0: float, z1: float, step: float) -> void:
	var trees: Array[StringName] = [&"tree_default", &"tree_oak", &"tree_detailed", &"tree_fat", &"tree_tall"]
	var z := z0
	while z > z1:
		Props.spawn(self, trees[_rng.randi() % trees.size()], Vector3(x + _rng.randf_range(-1.0, 1.0), y, z), _rng.randf() * TAU, _rng.randf_range(0.9, 1.25), true, &"leaf_dark" if _rng.randf() < 0.4 else &"")
		z -= step * _rng.randf_range(0.8, 1.2)


## The forest the plateaus stand in (Build 2: forest backdrop, not water). Falling in costs ½ heart.
func _forest_floor() -> void:
	Kit.block(self, Vector3(0.0, FLOOR_Y, -200.0), Vector3(420.0, 2.0, 760.0), &"grass_mid", Layers.WORLD)
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(420.0, 6.0, 760.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(0.0, FLOOR_Y + 2.5, -200.0)
	add_child(pit)
	var trees: Array[StringName] = [&"tree_pine", &"tree_cone", &"tree_default", &"tree_oak", &"tree_tall", &"tree_fat"]
	for i in 220:
		var p := Vector3(_rng.randf_range(-120.0, 120.0), FLOOR_Y + 1.0, _rng.randf_range(40.0, -460.0))
		if absf(p.x) < 26.0 and p.z < 18.0 and p.z > -420.0:
			continue
		Props.spawn(self, trees[i % trees.size()], p, _rng.randf() * TAU, _rng.randf_range(1.4, 2.4), false, &"leaf_dark" if i % 3 == 0 else &"")
	for i in 40:
		var side := -1.0 if i % 2 == 0 else 1.0
		Props.spawn(self, &"forest_cluster" if i % 3 else &"forest_cluster_b", Vector3(side * _rng.randf_range(32.0, 110.0), FLOOR_Y + 1.0, _rng.randf_range(40.0, -460.0)), _rng.randf() * TAU, _rng.randf_range(1.4, 2.2), false)


# --- Section 1: Stump Ring ---------------------------------------------------------------------

func _stump_ring() -> void:
	_plateau(Vector3(0.0, 0.0, 0.0), Vector2(26.0, 28.0))
	add_spawn(&"w1_entrance", Vector3(0.0, 0.0, 4.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 10.0)
	add_child(exit)
	_checkpoint(&"w1_cp_stump", Vector3(-7.0, 0.0, -2.0))
	_sign(Vector3(4.5, 0.0, 1.5), "Jump: Space / A\nPress again in the air:\ndouble, then triple jump!")
	# Mushroom steps up to the Fernway (J1 and J2 refresher).
	Kit.pillar(self, Vector3(-3.0, 2.4, -8.0), 1.6, 2.4 - FLOOR_Y, &"cloth_cream", &"roof_teal")
	Kit.pillar(self, Vector3(2.5, 4.4, -12.5), 1.6, 4.4 - FLOOR_Y, &"cloth_cream", &"roof_teal")
	_scatter(0.0, -12.0, 12.0, 12.0, -13.0, 26, [&"grass", &"grass_large", &"flower_red", &"flower_yellow", &"flower_purple", &"mushroom_red_group"], 3.0)
	for spec: Array in [[-10.0, 9.0], [10.5, 8.0], [-10.5, -10.0], [10.0, -8.0]]:
		Props.spawn(self, &"tree_oak", Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.2)
	Props.spawn(self, &"rock_tall_a", Vector3(-11.0, 0.0, -1.0), 0.5, 1.3)
	add_capture_point("s1_overview", Vector3(12.0, 9.0, 16.0), Vector3(0.0, 1.0, -8.0))


# --- Section 2: Fernway ------------------------------------------------------------------------

func _fernway() -> void:
	_plateau(Vector3(0.0, FERN_Y, -44.0), Vector2(20.0, 52.0))
	Kit.block(self, Vector3(-11.5, FERN_Y + 9.0, -44.0), Vector3(3.0, 9.0 + FERN_Y - FLOOR_Y, 52.0), &"stone_dark")
	Props.spawn(self, &"log_large", Vector3(-2.0, FERN_Y, -27.0), PI * 0.5, 1.6)
	Props.spawn(self, &"log_large", Vector3(3.0, FERN_Y, -30.0), PI * 0.5 + 0.2, 1.3)
	# Two Gloplets on the path, with a log-beam bypass along the right edge.
	_zone(&"w1_fernway", Vector3(-2.0, FERN_Y, -44.0), 8.0, "log beam along the right edge", [
		[Vector3.ZERO, GLOPLET], [Vector3(-3.0, 0.0, -6.0), GLOPLET],
	])
	Kit.block(self, Vector3(7.8, FERN_Y + 1.2, -44.0), Vector3(1.8, 1.2, 18.0), &"bark_light")
	_sign(Vector3(5.0, FERN_Y, -21.0), "Attack: F / X\nThree presses for a combo!")
	# Optional shelf mushrooms (triple jump) to a seed, far enough from the cliff that they
	# can't be used to skip the Springcap.
	Kit.pillar(self, Vector3(-6.8, FERN_Y + 3.5, -24.0), 1.5, 4.0, &"cloth_cream", &"roof_red")
	Kit.pillar(self, Vector3(-6.8, FERN_Y + 7.0, -30.0), 1.4, 8.0, &"cloth_cream", &"roof_red")
	Kit.pillar(self, Vector3(-6.4, FERN_Y + 10.5, -36.0), 1.4, 11.0, &"cloth_cream", &"roof_red")
	_seed(&"w1_seed_fernway", Vector3(-6.4, FERN_Y + 10.5, -36.0))
	# The Springcap: the required Plunge lesson up a 14 m cliff.
	var cap := Springcap.new()
	cap.position = Vector3(0.0, FERN_Y, -66.0)
	add_child(cap)
	_sign(Vector3(-4.5, FERN_Y, -62.5), "Spotted mushrooms bounce!\nJump, then PLUNGE onto it:\nShift / B")
	_tree_row(FERN_Y, 8.6, -20.0, -68.0, 6.0)
	_scatter(FERN_Y, -9.0, 9.0, -19.0, -69.0, 46, [&"grass", &"grass_large", &"grass_leafs", &"flower_yellow", &"flower_purple", &"mushroom_tan_group", &"bush_small"], 2.5)
	for z: float in [-52.0, -60.0]:
		Props.spawn(self, &"rock_large_b", Vector3(-8.0, FERN_Y, z), _rng.randf() * TAU, 1.0)
	add_capture_point("s2_springcap", Vector3(8.0, FERN_Y + 7.0, -50.0), Vector3(0.0, FERN_Y + 6.0, -68.0))


# --- Section 3: Sunny Clearing -----------------------------------------------------------------

func _sunny_clearing() -> void:
	_plateau(Vector3(0.0, TOP_Y, -98.0), Vector2(44.0, 56.0))
	_checkpoint(&"w1_cp_clearing", Vector3(0.0, TOP_Y, -76.0))
	_zone(&"w1_clearing", Vector3(-4.0, TOP_Y, -98.0), 12.0, "left meadow edge", [
		[Vector3(-4.0, 0.0, 3.0), GLOPLET], [Vector3(3.5, 0.0, -1.5), GLOPLET], [Vector3(-1.5, 0.0, -7.0), GLOPLET],
	])
	_zone(&"w1_bouncer", Vector3(12.0, TOP_Y, -104.0), 6.0, "optional seed route only", [[Vector3.ZERO, BOUNCER]])
	# Seed ledge: out of triple-jump reach from the ground; pogo off the blue Bouncer.
	Kit.block(self, Vector3(16.0, TOP_Y + SEED_LEDGE_RISE, -111.0), Vector3(4.0, 1.2, 4.0), &"stone_light")
	_seed(&"w1_seed_clearing", Vector3(16.0, TOP_Y + SEED_LEDGE_RISE, -111.0))
	_sign(Vector3(6.0, TOP_Y, -95.0), "Blue slimes go flat after a lunge.\nLand on one to bounce sky-high!")
	_heart_bush(Vector3(-16.0, TOP_Y, -80.0))
	_heart_bush(Vector3(17.0, TOP_Y, -120.0))
	_tree_row(TOP_Y, -20.0, -74.0, -122.0, 7.0)
	_tree_row(TOP_Y, 20.0, -74.0, -100.0, 7.0)
	_scatter(TOP_Y, -20.0, 20.0, -72.0, -124.0, 70, [&"grass", &"grass_large", &"flower_red", &"flower_yellow", &"flower_purple", &"flower_red_b", &"flower_yellow_b", &"bush", &"mushroom_red"])
	Props.spawn(self, &"rock_tall_b", Vector3(-17.0, TOP_Y, -110.0), 0.3, 1.4)
	Props.spawn(self, &"log_stack", Vector3(18.0, TOP_Y, -80.0), 0.6, 1.2)
	add_capture_point("s3_clearing", Vector3(-16.0, TOP_Y + 9.0, -72.0), Vector3(0.0, TOP_Y, -102.0))


# --- Section 4: River Crossing -----------------------------------------------------------------

func _river() -> void:
	var water_y := TOP_Y - 1.0
	Kit.water(self, Vector3(0.0, water_y, -154.0), Vector2(50.0, 56.0))
	Kit.block(self, Vector3(0.0, water_y - 4.0, -154.0), Vector3(50.0, water_y - 4.0 - FLOOR_Y, 56.0), &"stone_dark")
	Kit.block(self, Vector3(-24.5, TOP_Y, -154.0), Vector3(3.0, TOP_Y - FLOOR_Y, 56.0), &"stone_dark")
	Kit.block(self, Vector3(24.5, TOP_Y, -154.0), Vector3(3.0, TOP_Y - FLOOR_Y, 56.0), &"stone_dark")
	# Build 2: every stepping piece is much wider (Ashwin: "too small").
	for spec: Array in [[0.0, -131.0], [3.0, -137.5], [-1.5, -144.0]]:
		Kit.pillar(self, Vector3(spec[0] as float, TOP_Y - 0.2, spec[1] as float), 2.5, 8.0, &"stone_light", &"moss")
	for spec: Array in [[-151.0, 0.0], [-158.5, 0.5]]:
		var log_p := MovingPlatform.new()
		log_p.size = Vector3(6.5, 2.6, 2.6)
		log_p.travel = Vector3(9.0, 0.0, 0.0)
		log_p.period = 3.8
		log_p.phase = spec[1] as float
		log_p.position = Vector3(0.0, TOP_Y - 1.2, spec[0] as float)
		log_p.rotation.y = PI * 0.5
		add_child(log_p)
	for spec: Array in [[0.0, -165.5], [-2.0, -171.5], [1.0, -177.5]]:
		var pad := SinkingPad.new()
		pad.radius = 2.8
		pad.position = Vector3(spec[0] as float, TOP_Y - 0.4, spec[1] as float)
		add_child(pad)
	# Optional seed island off the drifting logs.
	Kit.pillar(self, Vector3(15.0, TOP_Y + 1.0, -154.0), 2.0, 9.0, &"stone_light", &"moss")
	_seed(&"w1_seed_river", Vector3(15.0, TOP_Y + 1.0, -154.0))
	_sign(Vector3(-6.0, TOP_Y, -123.5), "Lily pads sink a moment\nafter you land. Keep hopping!")
	for i in 10:
		Props.spawn(self, &"waterlily", Vector3(_rng.randf_range(-20.0, 20.0), water_y + 0.05, _rng.randf_range(-130.0, -178.0)), _rng.randf() * TAU, 1.0, false)
	add_capture_point("s4_river", Vector3(14.0, TOP_Y + 7.0, -124.0), Vector3(0.0, water_y, -152.0))


# --- Section 5: Bonk Grove ---------------------------------------------------------------------

func _bonk_grove() -> void:
	_plateau(Vector3(0.0, TOP_Y, -215.0), Vector2(44.0, 66.0))
	_checkpoint(&"w1_cp_far_bank", Vector3(0.0, TOP_Y, -187.0))
	# Giant trees hold the canopy platforms.
	for spec: Array in [[-13.0, -196.0], [11.0, -201.0], [-9.0, -219.0], [13.0, -227.0], [-3.0, -240.0]]:
		Props.spawn(self, &"tree_oak", Vector3(spec[0] as float, TOP_Y, spec[1] as float), _rng.randf() * TAU, 2.6)
	# Canopy route: steps up, then platform to platform past the monkeys' perches.
	Kit.pillar(self, Vector3(-16.0, TOP_Y + 3.2, -189.0), 1.6, 3.2, &"bark_light", &"moss")
	_canopy(Vector3(-11.0, TOP_Y + 6.4, -194.0), 5.0)
	_canopy(Vector3(-4.0, TOP_Y + 9.0, -201.0), 5.0)
	_canopy(Vector3(5.0, TOP_Y + 9.5, -207.0), 5.0)
	_canopy(Vector3(11.0, TOP_Y + 8.0, -215.0), 5.0)
	_canopy(Vector3(5.0, TOP_Y + 11.5, -223.0), 4.0)
	_canopy(Vector3(-4.0, TOP_Y + 9.0, -231.0), 5.0)
	_seed(&"w1_seed_grove", Vector3(5.0, TOP_Y + 11.5, -223.0))
	# Monkeys perch on the canopy and lob coconuts at the ground route.
	_monkey([Vector3(-4.0, TOP_Y + 9.0, -201.0), Vector3(11.0, TOP_Y + 8.0, -215.0)])
	_monkey([Vector3(5.0, TOP_Y + 9.5, -207.0), Vector3(-4.0, TOP_Y + 9.0, -231.0)])
	_monkey([Vector3(12.0, TOP_Y + 6.0, -236.0), Vector3(-12.0, TOP_Y + 6.0, -238.0)])
	Kit.pillar(self, Vector3(12.0, TOP_Y + 6.0, -236.0), 1.6, 6.0, &"bark_mid", &"moss")
	Kit.pillar(self, Vector3(-12.0, TOP_Y + 6.0, -238.0), 1.6, 6.0, &"bark_mid", &"moss")
	_zone(&"w1_grove", Vector3(0.0, TOP_Y, -222.0), 14.0, "canopy route above", [
		[Vector3(-6.0, 0.0, 10.0), GLOPLET], [Vector3(8.0, 0.0, -10.0), GLOPLET],
	])
	# Ground route cover.
	for spec: Array in [[3.0, -197.0], [-5.0, -209.0], [6.0, -219.0], [-2.0, -229.0]]:
		Props.spawn(self, &"rock_large_a", Vector3(spec[0] as float, TOP_Y, spec[1] as float), _rng.randf() * TAU, 1.1)
	_sign(Vector3(-6.0, TOP_Y, -186.0), "Coconut monkeys! Watch for the red rings.\nSlash a coconut to send it home.")
	_heart_bush(Vector3(17.0, TOP_Y, -190.0))
	_heart_bush(Vector3(-18.0, TOP_Y, -244.0))
	_scatter(TOP_Y, -20.0, 20.0, -186.0, -246.0, 60, [&"grass", &"grass_large", &"mushroom_red_group", &"mushroom_tan_group", &"bush", &"flower_purple", &"grass_leafs"], 1.5)
	add_capture_point("s5_grove", Vector3(-18.0, TOP_Y + 14.0, -186.0), Vector3(0.0, TOP_Y + 4.0, -218.0))


# --- Section 6: Waterfall Climb ----------------------------------------------------------------

func _waterfall_climb() -> void:
	_plateau(Vector3(0.0, TOP_Y, -257.0), Vector2(44.0, 18.0))
	# The cliff: 18 m, climbed on ledges and a rising rock beside the waterfall.
	_plateau(Vector3(0.0, RIDGE_Y, -273.0), Vector2(30.0, 14.0), &"stone_dark")
	Kit.block(self, Vector3(-6.0, TOP_Y + 4.0, -259.0), Vector3(5.0, 4.0, 5.0), &"stone_light")
	var riser := MovingPlatform.new()
	riser.rounded = false
	riser.size = Vector3(4.5, 1.0, 4.5)
	riser.travel = Vector3(0.0, 8.0, 0.0)
	riser.period = 4.0
	riser.color_name = &"stone_light"
	riser.position = Vector3(1.0, TOP_Y + 7.5, -258.0)
	add_child(riser)
	Kit.block(self, Vector3(8.0, TOP_Y + 9.5, -262.0), Vector3(5.5, 1.5, 5.5), &"stone_light")
	_checkpoint(&"w1_cp_waterfall", Vector3(7.0, TOP_Y + 9.5, -261.0))
	Kit.block(self, Vector3(1.0, TOP_Y + 14.0, -264.5), Vector3(4.5, 1.5, 4.5), &"stone_light")
	_zone(&"w1_waterfall", Vector3(4.0, TOP_Y + 9.5, -262.0), 8.0, "Gloplets sit beside the ledges", [
		[Vector3(5.5, 0.0, 0.0), GLOPLET], [Vector3(-3.0, 4.5, -2.5), GLOPLET],
	])
	_seed(&"w1_seed_waterfall", Vector3(1.0, TOP_Y + 17.0, -258.0))
	# Waterfall into a pool beside the route.
	var fall := BoxMesh.new()
	fall.size = Vector3(8.0, WATERFALL_RISE + 2.0, 0.5)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 3.0))
	wm.set_shader_parameter(&"vertical", true)
	Kit.mesh_instance(self, fall, wm, Vector3(-13.0, TOP_Y + WATERFALL_RISE * 0.5, -265.8))
	Kit.water(self, Vector3(-13.0, TOP_Y - 0.4, -259.0), Vector2(10.0, 12.0))
	Kit.block(self, Vector3(-13.0, TOP_Y - 2.0, -259.0), Vector3(10.0, 2.0, 12.0), &"stone_dark")
	_sign(Vector3(10.0, TOP_Y, -250.0), "Ride the rising rock.\nTriple jump to the top!")
	add_capture_point("s6_waterfall", Vector3(16.0, TOP_Y + 8.0, -244.0), Vector3(0.0, TOP_Y + 9.0, -262.0))


# --- Section 7: Ridge Run ----------------------------------------------------------------------

func _ridge_run() -> void:
	_plateau(Vector3(0.0, RIDGE_Y, -286.0), Vector2(14.0, 12.0))
	Kit.block(self, Vector3(0.0, RIDGE_Y - 0.1, -298.0), Vector3(2.2, 1.0, 12.0), &"bark_light")
	_plateau(Vector3(0.0, RIDGE_Y, -308.0), Vector2(10.0, 9.0))
	_plateau(Vector3(2.0, RIDGE_Y, -322.0), Vector2(10.0, 9.0))
	var swing := MovingPlatform.new()
	swing.rounded = false
	swing.size = Vector3(5.0, 1.0, 5.0)
	swing.travel = Vector3(12.0, 0.0, 0.0)
	swing.period = 4.2
	swing.color_name = &"wood_plank"
	swing.position = Vector3(2.0, RIDGE_Y - 0.5, -333.0)
	add_child(swing)
	_plateau(Vector3(0.0, RIDGE_Y, -342.0), Vector2(12.0, 8.0))
	# Optional high route on the left with a seed.
	Kit.pillar(self, Vector3(-9.0, RIDGE_Y + 3.0, -306.0), 1.6, 3.0 + RIDGE_Y - FLOOR_Y, &"stone_light", &"moss")
	Kit.pillar(self, Vector3(-11.0, RIDGE_Y + 6.0, -314.0), 1.6, 6.0 + RIDGE_Y - FLOOR_Y, &"stone_light", &"moss")
	Kit.pillar(self, Vector3(-9.0, RIDGE_Y + 8.5, -322.0), 1.6, 8.5 + RIDGE_Y - FLOOR_Y, &"stone_light", &"moss")
	_seed(&"w1_seed_ridge", Vector3(-9.0, RIDGE_Y + 8.5, -322.0))
	_zone(&"w1_ridge", Vector3(0.0, RIDGE_Y, -315.0), 10.0, "jump past them pad to pad", [
		[Vector3(0.0, 0.0, 7.0), GLOPLET], [Vector3(2.0, 0.0, -7.0), GLOPLET], [Vector3(3.0, 0.0, -9.0), BOUNCER],
	])
	Kit.pillar(self, Vector3(10.0, RIDGE_Y + 5.0, -314.0), 1.4, 5.0 + RIDGE_Y - FLOOR_Y, &"bark_mid", &"moss")
	_monkey([Vector3(10.0, RIDGE_Y + 5.0, -314.0)])
	for spec: Array in [[-5.0, -283.0], [5.0, -289.0], [3.0, -340.0]]:
		Props.spawn(self, &"tree_pine", Vector3(spec[0] as float, RIDGE_Y, spec[1] as float), _rng.randf() * TAU, 1.1)
	add_capture_point("s7_ridge", Vector3(16.0, RIDGE_Y + 9.0, -290.0), Vector3(0.0, RIDGE_Y, -320.0))


# --- Section 8: Lily Gate -----------------------------------------------------------------------

func _lily_gate() -> void:
	_plateau(Vector3(0.0, RIDGE_Y, -360.0), Vector2(40.0, 28.0))
	_checkpoint(&"w1_cp_lily_gate", Vector3(0.0, RIDGE_Y, -365.0))
	_heart_bush(Vector3(-8.0, RIDGE_Y, -356.0))
	_heart_bush(Vector3(8.0, RIDGE_Y, -352.0))
	_sign(Vector3(-5.0, RIDGE_Y, -369.0), "Mother Gloop's lake ahead.\nPlunge onto her glowing core!")
	_tree_row(RIDGE_Y, -17.0, -348.0, -372.0, 6.0)
	_tree_row(RIDGE_Y, 17.0, -348.0, -372.0, 6.0)
	_scatter(RIDGE_Y, -15.0, 15.0, -347.0, -373.0, 34, [&"grass", &"grass_large", &"flower_purple", &"flower_red", &"bush", &"mushroom_red_group"], 2.5)
	add_capture_point("s8_lily_gate", Vector3(10.0, RIDGE_Y + 6.0, -348.0), Vector3(0.0, RIDGE_Y, -373.0))


# --- Section 9: Gloop Lake (boss arena) ---------------------------------------------------------

func _arena() -> void:
	Kit.water(self, ARENA_CENTER + Vector3(0.0, -1.0, 0.0), Vector2(80.0, 56.0))
	Kit.block(self, ARENA_CENTER + Vector3(0.0, -4.0, 0.0), Vector3(80.0, ARENA_CENTER.y - 4.0 - FLOOR_Y, 56.0), &"stone_dark")
	Kit.pillar(self, ARENA_CENTER, ARENA_RADIUS + 0.5, ARENA_CENTER.y - FLOOR_Y, &"bark_mid", &"grass_mid")
	Kit.block(self, Vector3(0.0, RIDGE_Y, -376.0), Vector3(8.0, RIDGE_Y - FLOOR_Y, 4.0), &"bark_mid")
	var stump_positions: Array[Vector3] = []
	for i in 4:
		var a := PI * 0.25 + i * PI * 0.5
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * 10.0
		Kit.pillar(self, p + Vector3(0.0, 2.8, 0.0), 1.1, 2.8, &"bark_light", &"moss")
		stump_positions.append(p)
	# Bank rocks back up the knockback ledge guard.
	for i in 30:
		var a := float(i) / 30.0 * TAU
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.24:
			continue
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * (ARENA_RADIUS + 0.3)
		Props.spawn(self, &"rock_tall_a" if i % 2 == 0 else &"rock_tall_b", p, a, 1.0)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.4
		Props.spawn(self, &"waterlily", ARENA_CENTER + Vector3(cos(a) * 26.0, -0.95, sin(a) * 22.0), a, 1.6, false)
	gate = VineGate.new()
	gate.width = 8.0
	gate.position = Vector3(0.0, RIDGE_Y, -375.0)
	add_child(gate)
	add_spawn(&"w1_arena_exit", ARENA_CENTER + Vector3(0.0, 0.0, 11.0), Vector3.FORWARD)
	_spawn_boss(stump_positions)
	add_capture_point("s9_arena", ARENA_CENTER + Vector3(17.0, 14.0, 21.0), ARENA_CENTER)


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
	boss.position = ARENA_CENTER + Vector3(0.0, 0.0, -5.0)
	add_child(boss)


func _scenery() -> void:
	# Landmark: the great waterfall above Gloop Lake, visible from the very first spot.
	Kit.block(self, Vector3(0.0, RIDGE_Y + 34.0, -430.0), Vector3(60.0, RIDGE_Y + 34.0 - FLOOR_Y, 12.0), &"stone_dark")
	var fall := BoxMesh.new()
	fall.size = Vector3(12.0, 40.0, 0.5)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 2.5))
	wm.set_shader_parameter(&"vertical", true)
	Kit.mesh_instance(self, fall, wm, Vector3(0.0, RIDGE_Y + 18.0, -423.7))
	for i in 10:
		var side := -1.0 if i % 2 == 0 else 1.0
		Props.spawn(self, &"mountain", Vector3(side * _rng.randf_range(150.0, 190.0), FLOOR_Y, 20.0 - float(i / 2) * 110.0), _rng.randf() * TAU, _rng.randf_range(1.6, 2.2), false)
	for i in 9:
		Props.spawn(self, &"cloud_big" if i % 2 == 0 else &"cloud_small", Vector3(_rng.randf_range(-110.0, 110.0), _rng.randf_range(70.0, 95.0), _rng.randf_range(20.0, -440.0)), _rng.randf() * TAU, _rng.randf_range(1.8, 2.8), false)


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
	var z := player.global_position.z
	var current := ""
	for s in SECTIONS:
		if z <= float(s[1]):
			current = str(s[0])
	if current != _section:
		if _section != "":
			Telemetry.log_event("section_left", {"section": _section})
		_section = current
		Telemetry.log_event("section_entered", {"section": current})
	if not fight_started and boss != null and z < FIGHT_TRIGGER_Z and player.global_position.y > ARENA_CENTER.y - 2.0:
		fight_started = true
		gate.set_closed(true)
		boss.start_fight()
		AudioDirector.play_music(&"boss")
	if boss != null and hud != null:
		hud.set_boss(boss.hp, MotherGloop.MAX_HP, fight_started and boss.state != MotherGloop.S.GONE)


## The victory commit happens before any presentation (plan §9.8).
func _on_boss_defeated(world_id: StringName) -> void:
	if world_id != WORLD or _victory_running:
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
	return_arch.position = ARENA_CENTER + Vector3(0.0, 0.0, -3.0)
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
	gate.set_closed(false)
	AudioDirector.play_music(&"glimmerbrook")
