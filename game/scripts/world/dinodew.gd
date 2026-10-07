class_name Dinodew
extends BossWorld
## World 9, Dinodew Jungle (Build 9, Ashwin: "a forest with large dinosaurs (we should be able to
## climb on some of the dinos)... densely packed small open-worlds with a lot of verticality").
## A storybook prehistoric jungle laid out as a giant staircase: three broad shelves climb north
## toward a smoking little volcano, and the Dewdrop River tumbles down the east side through the
## Spring Locks, winds west across the jungle floor and pools in Dew Lake.
##   The Fern Floor (y 0)     Nestling Village in eggshell huts, Dew Lake with Lookout Rock,
##                            Snoozer's haystack, giant ferns and mushrooms
##   The Cycad Shelf (y 6)    the Spring Locks, the fossil dig, the melon cycad
##   Canopy Heights (y 12)    the Roost treehouses, Ember Cone, the Tar Crater's turning log,
##                            the Skyfern, and the gate to Chomposaurus Rex's clearing
## Big gentle dinosaurs are the landmarks and the ways up: Mossback the long-neck (feed her and
## her neck is a bridge up the Great Cliff), Trundle the triceratops (rides a loop through the
## lake past Lookout Rock) and Snoozer the stegosaurus (ring his gong and he stands up).
## Clearing it with all six Star Shards teaches the Mighty Roar.

const WORLD := &"world_09"
const T1 := 6.0
const T2 := 12.0
const ARENA := Vector3(76.0, T2, -116.0)
const ARENA_R := 20.0
const WALL_H := 11.0
const LAKE := Rect2(-118.0, 10.0, 56.0, 56.0)
const LAKE_Y := -0.6
const LAKE_DEPTH := 10.0
const RIVER_NS := Rect2(66.0, -24.0, 12.0, 44.0)
const RIVER_EW := Rect2(-62.0, 10.0, 140.0, 10.0)
const RIVER_DEPTH := 8.0
const ROCK := Vector3(-90.0, 0.0, 36.0)
const ROCK_R := 4.5
const ROCK_TOP := 9.6
const CAUSEWAY_Y := -2.0
const MOSSBACK := Vector3(-52.0, 0.0, 1.25)
const SNOOZER := Vector3(68.0, 0.0, 58.0)
const LOCK1 := Rect2(57.5, -44.0, 20.5, 16.0)
const LOCK2 := Rect2(58.0, -66.0, 20.0, 18.0)
const HATCH := Vector3(50.0, -4.0, -36.0)
const TAR := Vector3(-14.0, T2, -112.0)
const TAR_HALF := 18.0
const TAR_Y := 8.6
const VOLCANO := Vector3(-80.0, T2, -110.0)
const SKYFERN := Vector3(20.0, T2, -84.0)
const MELON_TREE := Vector3(-40.5, T1, -27.0)
const SKYFERN_SHELF := 6.4
## Ember Cone's ramps run this far outside the tier they climb onto (their inner edge overlaps it).
const VOLCANO_LANE := 1.75
const SKYFERN_LAST_SHELF := 7.4

var mossback: HungryLongneck
var snoozer: SleepyDino
var trundle: Dino
var locks: SpringLocks
var turn_bridge: TurnBridge
var hatch_gate: VineGate
var nest_deck_top: float = 0.0
var _ferns: ModuleBatch = ModuleBatch.new()


func configure() -> void:
	world_id = WORLD
	platform_colour = &"green"
	model_tint = Color(1.02, 1.05, 0.95)
	sky_top = Color(0.12, 0.46, 0.92)
	sky_horizon = Color(0.86, 0.96, 0.82)
	sky_bottom = Color(0.9, 0.97, 0.88)
	cloud_cover = 0.48
	cloud_shade = Color(0.84, 0.86, 0.96)
	sun_color = Color(1.0, 0.95, 0.8)
	sun_energy = 1.15
	sun_angles = Vector2(-52.0, -40.0)
	ambient_energy = 0.6
	fog_color = Color(0.82, 0.95, 0.86)
	fog_begin = 80.0
	fog_end = 300.0
	saturation = 1.1
	tree_kinds = [&"teal", &"lime", &"blossom", &"green", &"teal", &"gold"]
	tops = {&"stone_dark": &"moss", &"stone_light": &"moss", &"bark_mid": &"grass_mid", &"bark_dark": &"grass_mid", &"sunset_orange": &"moss", &"wood_warm": &"grass_light"}
	grass_density = 0.05


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w9_entrance"
	music = &"world_09"
	floor_y = -18.0
	kill_y = -30.0
	_rng.seed = 909
	arena_center = ARENA
	arena_radius = ARENA_R
	arena_exit_spawn = &"w9_arena_exit"
	defeat_banner = "Chomposaurus Rex flops over for a nap!"
	regions = {"village": Vector3(0.0, 0.0, 66.0), "lake": Vector3(-90.0, 0.0, 38.0), "fern_floor": Vector3(0.0, 0.0, -8.0), "haystack": SNOOZER, "shelf": Vector3(0.0, T1, -46.0), "locks": Vector3(68.0, T1, -46.0), "roost": Vector3(-82.0, T2, -46.0), "volcano": VOLCANO, "tar": TAR, "skyfern": SKYFERN, "gate": Vector3(40.0, T2, -110.0), "rex": ARENA}
	_terrain()
	_water()
	_village()
	_honkers()
	_fern_floor()
	_mossback()
	_lake_and_trundle()
	_snoozer()
	_cycad_shelf()
	_spring_locks()
	_roost()
	_ember_cone()
	_tar_crater()
	_skyfern()
	_rex_gate()
	_ways_up()
	_monsters()
	_jungle()
	_ferns.build(self)
	finish_boss_world()
	finish_life(&"grass_light")


func create_boss() -> BossBase:
	var rex := ChompoRex.new()
	rex.rng.seed = 9909
	rex.position = ARENA + Vector3(0.0, 0.0, 8.0)
	return rex


# --- Helpers ----------------------------------------------------------------------------------

## A giant fern (Quaternius Fern_1, drawn in batches), `h` metres tall.
func fern(at: Vector3, h: float, yaw: float = -1.0) -> void:
	var path := Models.Q_NATURE + "Fern_1.gltf"
	var s := h / maxf(Models.model_bounds(path).size.y, 0.01)
	_ferns.place(path, at, _rng.randf() * TAU if yaw < 0.0 else yaw, Vector3.ONE * s)


## A cycad: a stout scaly trunk and a crown of fronds (Kenney palm, recoloured by the world).
func cycad(at: Vector3, s: float = 1.6) -> Node3D:
	return Props.spawn(self, [&"palm", &"palm_tall", &"palm_bend", &"palm_detailed"][_rng.randi() % 4] as StringName, at, _rng.randf() * TAU, s)


## An eggshell hut: a big cracked egg with a round door and a zigzag rim.
func egg_hut(at: Vector3, yaw: float, r: float = 3.6, shell: StringName = &"mush_spot", spots: StringName = &"candy_pink") -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	add_child(root)
	var body := Kit.static_body(root, Vector3(0.0, r * 0.9, 0.0))
	var cs := CylinderShape3D.new()
	cs.radius = r * 0.92
	cs.height = r * 1.8
	Kit.add_shape(body, cs)
	var egg := SphereMesh.new()
	egg.radius = r
	egg.height = r * 2.6
	Kit.mesh_instance(root, egg, Kit.mat(shell, 0.03), Vector3(0.0, r * 1.05, 0.0))
	for i in 7:
		var a := float(i) / 7.0 * TAU + 0.3
		var y := r * (0.6 + 0.9 * fmod(i * 0.37, 1.0))
		Kit.blob(root, Vector3(cos(a) * r * 0.86, y, sin(a) * r * 0.86), r * 0.16, spots)
	var door := CylinderMesh.new()
	door.top_radius = 0.95
	door.bottom_radius = 0.95
	door.height = 0.2
	var d := Kit.mesh_instance(root, door, Kit.mat(&"bark_dark"), Vector3(0.0, 1.1, r * 0.97))
	d.rotation.x = PI * 0.5
	# The zigzag cracked rim of the top half, lifted like a lid.
	for i in 10:
		var a := float(i) / 10.0 * TAU
		var tooth := PrismMesh.new()
		tooth.size = Vector3(r * 0.6, r * 0.45, 0.25)
		var t := Kit.mesh_instance(root, tooth, Kit.mat(shell), Vector3(cos(a) * r * 0.7, r * 2.15, sin(a) * r * 0.7))
		t.rotation.y = -a + PI * 0.5


func sign_at(at: Vector3, text: String, yaw: float = 0.0) -> void:
	Props.spawn(self, &"sign", at, yaw, 1.6, false)
	var l := Kit.label(self, at + Vector3(0.0, 2.4, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func cp(id: StringName, at: Vector3, look: Vector3 = Vector3.FORWARD) -> void:
	var c := Checkpoint.new()
	c.checkpoint_id = id
	c.world_id = world_id
	c.position = at + Vector3(2.5, 0.0, 0.0)
	add_child(c)
	add_spawn(id, at, look)


func npc(id: String, display: String, at: Vector3, errand: StringName = &"", item_at: Vector3 = Vector3.ZERO, item_name: String = "", shard: StringName = &"", seed: StringName = &"") -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.display_name = display
	n.errand_flag = errand
	n.reward_shard = shard
	n.reward_seed = seed
	n.position = at
	add_child(n)
	if errand != &"":
		var item := ErrandItem.new()
		item.flag = errand
		item.label_text = item_name
		item.color_name = &"gold"
		item.position = item_at
		add_child(item)
	return n


## A plain box with its top centre at `top` (world).
func box(top: Vector3, size: Vector3, color: StringName = &"stone_dark", top_color: StringName = &"auto") -> StaticBody3D:
	return Kit.block(self, top, size, color, Layers.WORLD | Layers.CAMERA_BLOCKER, top_color)


## A lift riding straight up and down between base.y and top_y (its top surface).
func lift_at(base: Vector3, top_y: float, period: float = 7.0) -> MovingPlatform:
	var m := MovingPlatform.new()
	m.rounded = false
	m.size = Vector3(4.6, 0.8, 4.6)
	m.travel = Vector3(0.0, top_y - base.y, 0.0)
	m.period = period
	m.phase = 0.75
	m.color_name = &"wood_plank"
	m.position = Vector3(base.x, (base.y + top_y) * 0.5 - 0.4, base.z)
	add_child(m)
	skin_platform(m, m.size)
	return m


## Rounded-rectangle loop (for walking dinosaurs) at height y, points every `step` metres.
static func loop_path(c: Vector3, w: float, d: float, r: float, step: float = 1.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	var hx := w * 0.5 - r
	var hz := d * 0.5 - r
	var corners: Array[Vector3] = [Vector3(hx, 0.0, -hz), Vector3(hx, 0.0, hz), Vector3(-hx, 0.0, hz), Vector3(-hx, 0.0, -hz)]
	for k in 4:
		var a0 := -PI * 0.5 + k * PI * 0.5
		var n := int(r * PI * 0.5 / step) + 1
		for i in n:
			var a := a0 + PI * 0.5 * i / n
			out.append(c + corners[k] + Vector3(cos(a), 0.0, sin(a)) * r)
		var a1 := a0 + PI * 0.5
		var from := c + corners[k] + Vector3(cos(a1), 0.0, sin(a1)) * r
		var to := c + corners[(k + 1) % 4] + Vector3(cos(a1), 0.0, sin(a1)) * r
		var m := maxi(int(from.distance_to(to) / step), 1)
		for i in m:
			out.append(from.lerp(to, float(i) / m))
	return out


# --- Terrain: three shelves, cliffs and the jungle wall ------------------------------------------

func _terrain() -> void:
	# The Fern Floor.
	ground(Rect2(-125.0, -24.0, 250.0, 145.0), [LAKE, RIVER_NS, RIVER_EW], 0.0, 18.0, &"bark_mid", &"grass_mid", 0.03)
	# The Cycad Shelf, with the Spring Locks (and the Hatchery under them) cut into it.
	var lock1_hole := Rect2(43.0, LOCK1.position.y, LOCK1.end.x - 43.0, LOCK1.size.y)
	ground(Rect2(-44.0, -70.0, 169.0, 46.0), [lock1_hole, Rect2(60.0, -28.0, 4.0, 4.0), LOCK2], T1, 24.0, &"bark_dark", &"moss", 0.03)
	# Canopy Heights, and the Great Cliff top in the west.
	var tar := Rect2(TAR.x - TAR_HALF, TAR.z - TAR_HALF, TAR_HALF * 2.0, TAR_HALF * 2.0)
	ground(Rect2(-125.0, -155.0, 250.0, 85.0), [tar], T2, 30.0, &"stone_dark", &"moss", 0.025)
	ground(Rect2(-125.0, -70.0, 81.0, 46.0), [], T2, 30.0, &"stone_dark", &"moss", 0.025)
	# Buttresses on the cliff faces so they read as rock, not walls (and give a hand up).
	for i in 9:
		var x := -38.0 + i * 18.0 + _rng.randf_range(-3.0, 3.0)
		if absf(x - 62.0) < 8.0 or absf(x - 72.0) < 8.0 or absf(x - 14.0) < 6.0 or absf(x + 24.0) < 6.0 or absf(x - 40.0) < 6.0 or absf(x - 96.0) < 6.0:
			continue
		box(Vector3(x, _rng.randf_range(2.6, 4.2), -23.0), Vector3(_rng.randf_range(4.0, 7.0), 4.0, 2.6), &"bark_dark", &"moss")
	for i in 8:
		var x := -40.0 + i * 20.0 + _rng.randf_range(-3.0, 3.0)
		if absf(x - 68.0) < 13.0 or absf(x + 30.0) < 6.0 or absf(x - 10.0) < 6.0 or absf(x - 46.0) < 6.0 or absf(x - 104.0) < 6.0 or absf(x - 28.0) < 6.0:
			continue
		box(Vector3(x, T1 + _rng.randf_range(2.4, 3.8), -69.0), Vector3(_rng.randf_range(4.0, 7.0), 4.0, 2.6), &"stone_dark", &"moss")
	# The jungle wall all round: tall mossy cliffs with trees on top.
	for side in 4:
		var along := 250.0 if side < 2 else 276.0
		var n := int(along / 25.0)
		for i in n:
			var t := -along * 0.5 + (i + 0.5) * along / n
			var h := _rng.randf_range(28.0, 40.0)
			var c: Vector3
			var size: Vector3
			match side:
				0:
					c = Vector3(t, h, -162.0)
					size = Vector3(along / n + 2.0, h + 20.0, 16.0)
				1:
					c = Vector3(t, h, 128.0)
					size = Vector3(along / n + 2.0, h + 20.0, 16.0)
				2:
					c = Vector3(-132.0, h, t - 17.0)
					size = Vector3(16.0, h + 20.0, along / n + 2.0)
				_:
					c = Vector3(132.0, h, t - 17.0)
					size = Vector3(16.0, h + 20.0, along / n + 2.0)
			box(c, size, [&"stone_dark", &"bark_dark", &"leaf_dark"][(i + side) % 3] as StringName, &"moss")
			Whimsy.tree(self, c + Vector3(0.0, 0.0, 0.0), tree_kinds[(i + side) % tree_kinds.size()], _rng.randf_range(2.2, 3.2), -1, _rng.randf() * TAU, false)
	# Far volcanoes and hills beyond the wall.
	for i in 12:
		var a := float(i) / 12.0 * TAU + _rng.randf_range(-0.1, 0.1)
		Whimsy.mountain(self, Vector3(cos(a) * 270.0, -20.0, sin(a) * 270.0 - 20.0), _rng.randf_range(60.0, 90.0), _rng.randf_range(110.0, 170.0), false)
	birds(Vector3(0.0, 0.0, -20.0), 90.0, 40.0, 7)
	add_capture_point("overview", Vector3(60.0, 70.0, 120.0), Vector3(-20.0, 4.0, -40.0))


# --- Water: Dew Lake, the Dewdrop River and its bridges ---------------------------------------

func _water() -> void:
	var lc := Vector3(LAKE.get_center().x, LAKE_Y, LAKE.get_center().y)
	Kit.water(self, lc, LAKE.size, LAKE_DEPTH)
	box(lc + Vector3(0.0, -LAKE_DEPTH, 0.0), Vector3(LAKE.size.x, 4.0, LAKE.size.y), &"sand_mid", &"sand_light")
	for r: Rect2 in [RIVER_NS, RIVER_EW]:
		var c := Vector3(r.get_center().x, LAKE_Y, r.get_center().y)
		Kit.water(self, c, r.size, RIVER_DEPTH)
		box(c + Vector3(0.0, -RIVER_DEPTH, 0.0), Vector3(r.size.x, 4.0, r.size.y), &"sand_mid", &"sand_light")
	# Arched footbridges over the river.
	for x: float in [6.0, -30.0, 44.0]:
		bridge(Vector3(x, 0.0, 7.0), Vector3(x, 1.6, 15.0), 3.6, &"wood_plank", true, &"roof_teal")
		bridge(Vector3(x, 1.6, 15.0), Vector3(x, 0.0, 23.0), 3.6, &"wood_plank", true, &"roof_teal")
	bridge(Vector3(63.0, 0.0, -6.0), Vector3(72.0, 1.6, -6.0), 3.6, &"wood_plank", true, &"roof_teal")
	bridge(Vector3(72.0, 1.6, -6.0), Vector3(81.0, 0.0, -6.0), 3.6, &"wood_plank", true, &"roof_teal")
	# Under the falls at the river's head: a seed in the plunge pool.
	seed_at(&"w9_seed_falls", Vector3(73.0, LAKE_Y - RIVER_DEPTH + 0.2, -20.0))
	Ambient.fish(self, Vector3(20.0, -3.0, 15.0), 18.0, 8, &"gold")
	Ambient.fish(self, Vector3(-90.0, -4.0, 38.0), 18.0, 10, &"sunset_orange")
	for i in 8:
		var x := -50.0 + i * 16.0
		prop(&"lily_large", Vector3(x, LAKE_Y + 0.05, 12.0 + fmod(i * 3.7, 6.0)), _rng.randf() * TAU, 1.0, false)


# --- Nestling Village (Fern Floor, south) ------------------------------------------------------

func _village() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w9_entrance", Vector3(0.0, 0.0, 104.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 112.0)
	add_child(exit)
	cp(&"w9_cp_village", Vector3(-6.0, 0.0, 74.0))
	sign_at(Vector3(6.0, 0.0, 98.0), "Dinodew Jungle! Find 3 Star Shards to open\nthe gate to Chomposaurus Rex, far up north.")
	sign_at(Vector3(-10.0, 0.0, 50.0), "West: Dew Lake and the Trundle Express", PI * 0.5)
	sign_at(Vector3(14.0, 0.0, 50.0), "East: Snoozer's haystack", -PI * 0.5)
	sign_at(Vector3(2.0, 0.0, 30.0), "North: the Fern Floor and the shelves", PI)
	var c := Vector3(0.0, 0.0, 66.0)
	for spec: Array in [[-16.0, -8.0, 0.6, &"mush_spot", &"candy_pink"], [16.0, -10.0, -0.7, &"cloth_cream", &"slime_blue"], [-20.0, 10.0, 2.2, &"mush_spot", &"lime_pop"], [20.0, 12.0, -2.4, &"cloth_cream", &"sunset_orange"], [-6.0, 22.0, 3.0, &"mush_spot", &"crystal_violet"], [10.0, 24.0, -2.8, &"cloth_cream", &"candy_pink"]]:
		egg_hut(c + Vector3(spec[0] as float, 0.0, spec[1] as float), float(spec[2]), _rng.randf_range(3.2, 4.2), spec[3] as StringName, spec[4] as StringName)
	# The square: a fossil-bone arch, lamps, bunting, a heart bush and a cookpot.
	var path := RoundMesh.box(Vector3(4.6, 0.06, 80.0), 0.03)
	Kit.mesh_instance(self, path, Kit.mat(&"sand_light"), Vector3(0.0, 0.03, 66.0))
	for z: float in [84.0, 70.0, 56.0, 42.0]:
		Whimsy.lamp(self, Vector3(-3.8, 0.0, z), z > 60.0)
		Whimsy.lamp(self, Vector3(3.8, 0.0, z + 0.5), false)
		Whimsy.bunting(self, Vector3(-3.8, 3.0, z), Vector3(3.8, 3.0, z + 0.5), 0.5)
	_bone_arch(Vector3(0.0, 0.0, 90.0), 0.0, 7.0)
	prop(&"campfire_stones", c + Vector3(6.0, 0.0, 2.0), 0.0, 1.2, false)
	prop(&"q_cauldron", c + Vector3(6.0, 0.0, 2.0), 0.0, 1.4)
	heart_bush(c + Vector3(-12.0, 0.0, -18.0))
	for spec: Array in [[10.0, -16.0, &"q_barrel_apples"], [11.5, -17.0, &"q_barrel"], [-14.0, 16.0, &"q_farm_crate"], [14.0, 18.0, &"q_cart"], [-9.0, -2.0, &"q_bench"]]:
		prop(spec[2] as StringName, c + Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.1)
	npc("gingko", "Grandpa Gingko", c + Vector3(4.0, 0.0, -4.0), &"w9_found_spectacles", TAR + Vector3(-2.0, 0.0, -TAR_HALF - 9.0), "Grandpa's spectacles", &"w9_shard_errand")
	npc("pipkin", "Pipkin", c + Vector3(-5.0, 0.0, 6.0))
	animals(Bunny, c, 20.0, 4)
	butterflies(c, 20.0, 8)
	sparkles(c + Vector3(0.0, 2.0, 0.0), Vector3(40.0, 4.0, 40.0), 30)
	add_capture_point("village", Vector3(26.0, 16.0, 100.0), c)


## Two parasaurolophus amble round the meadows south of the village and honk when you come by.
func _honkers() -> void:
	var schemes: Array[Dictionary] = [
		{"Green": &"lime_pop", "LightGreen": &"grass_light", "LightYellow": &"cloth_cream", "Red": &"candy_pink"},
		{"Green": &"slime_blue", "LightGreen": &"water_light", "LightYellow": &"cloth_cream", "Red": &"gold"},
	]
	var centres: Array[Vector3] = [Vector3(32.0, 0.0, 98.0), Vector3(-30.0, 0.0, 100.0)]
	for i in 2:
		var h := Honker.new()
		h.model_scale = 1.0
		var cols: Dictionary[String, StringName] = {}
		for k: String in schemes[i]:
			cols[k] = schemes[i][k] as StringName
		h.colours = cols
		h.clip = &"Walk"
		h.path = loop_path(centres[i], 16.0, 10.0, 4.5, 1.0)
		h.travelled = 7.0 * i
		add_child(h)


## A fossil arch: two giant curving rib bones meeting overhead.
func _bone_arch(at: Vector3, yaw: float, span: float) -> void:
	for side: float in [-1.0, 1.0]:
		for k in 6:
			var a := float(k) / 5.0 * PI * 0.5
			var p := at + Basis(Vector3.UP, yaw) * Vector3(side * span * 0.5 * cos(a), span * 0.75 * sin(a) + 0.4, 0.0)
			var b := Kit.mesh_instance(self, RoundMesh.box(Vector3(0.9, 1.6, 0.9), 0.4), Kit.mat(&"cloth_cream", 0.03), p)
			b.rotation = Vector3(0.0, yaw, side * (a - PI * 0.5))


# --- The Fern Floor (north strip) ---------------------------------------------------------------

func _fern_floor() -> void:
	region(Vector3.ZERO)
	cp(&"w9_cp_fernfloor", Vector3(-2.0, 0.0, -2.0))
	sign_at(Vector3(4.0, 0.0, -2.0), "The Cycad Shelf is up the Fern Ramp.\nThe Great Cliff's top is the Roost.", PI)
	# A giant mushroom grove with a springcap up to a seed on the tallest cap.
	var top := mushroom_platform(Vector3(30.0, 9.5, -8.0), 0.0, 5.0, &"red")
	seed_at(&"w9_seed_capstool", top)
	var pink := mushroom_platform(Vector3(15.0, 4.0, -15.0), 0.0, 4.0, &"pink")
	var teal := mushroom_platform(Vector3(40.0, 6.5, 2.0), 0.0, 3.5, &"teal")
	monkey([pink, teal])
	bouncer(Vector3(24.0, 0.0, -2.0), Springcap.Look.MUSHROOM, 6.0, 12.0)
	for spec: Array in [[-20.0, -10.0, 7.0, 4.5, &"purple"], [-30.0, 2.0, 5.0, 3.5, &"orange"], [50.0, -14.0, 8.0, 4.0, &"blue"]]:
		Whimsy.mushroom(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as float, spec[3] as float, spec[4] as StringName)
	gloplets(Vector3(-10.0, 0.0, -10.0), 9.0, [Vector3.ZERO, Vector3(3.0, 0.0, -2.0), Vector3(-3.0, 0.0, 2.0)])
	add_capture_point("fern_floor", Vector3(40.0, 18.0, 20.0), Vector3(0.0, 4.0, -20.0))


# --- Mossback the long-neck (the feeding puzzle) -----------------------------------------------

func _mossback() -> void:
	mossback = HungryLongneck.new()
	mossback.position = MOSSBACK
	mossback.rotation.y = PI
	add_child(mossback)
	# Her chin comes to rest at the Great Cliff's edge; a seed rides on her mossy brow.
	Pickup.spawn_seed(mossback.head_piece, Vector3(0.0, 0.7, -0.6), &"w9_seed_mossback")
	# The melon cycad on the Cycad Shelf's west corner; its melons hang out over the floor.
	var tree := cycad(MELON_TREE, 2.4)
	tree.name = "MelonCycad"
	for spec: Vector3 in [Vector3(-2.2, 6.0, 0.6), Vector3(-1.4, 6.4, 2.0), Vector3(0.8, 6.2, 1.8)]:
		mossback.add_melon(MELON_TREE + spec)
	# A mounting stone where her tail tip rests (over the river, on the south bank).
	# Mossy steps up to where her tail tip rests (south bank).
	var foot := mossback.to_global(mossback.tail_foot)
	var steps := int(ceil((foot.y - 0.1) / 0.3))
	for k in steps:
		var top := (foot.y - 0.1) * float(steps - k) / steps
		box(Vector3(foot.x, top, foot.z + 0.9 + k * 1.2), Vector3(3.6, top, 1.4), &"stone_light", &"moss")
	npc("cycadia", "Cycadia", Vector3(-44.0, 0.0, -14.0))
	sign_at(Vector3(-40.0, 0.0, -12.0), "Shh! Mossback is waiting for breakfast.", PI * 0.75)
	add_capture_point("mossback", Vector3(-24.0, 22.0, 26.0), MOSSBACK + Vector3(0.0, 8.0, -8.0))


# --- Dew Lake, Lookout Rock and the Trundle Express ---------------------------------------------

func _lake_and_trundle() -> void:
	region(Vector3.ZERO)
	# Lookout Rock: a tall mossy pillar out in the deep lake; the Star Shard waits on top.
	Kit.pillar(self, ROCK + Vector3(0.0, ROCK_TOP, 0.0), ROCK_R, ROCK_TOP + LAKE_DEPTH, &"stone_dark", &"moss")
	shard_at(&"w9_shard_lookout", ROCK + Vector3(0.0, ROCK_TOP, 0.0))
	Whimsy.tree(self, ROCK + Vector3(1.6, ROCK_TOP, -1.6), &"teal", 0.7, -1, 0.0, false)
	# Under the water: a giant ammonite shell holding a seed, and an old fossil ribcage.
	var amm := ROCK + Vector3(-18.0, LAKE_Y - LAKE_DEPTH, 14.0)
	var shell := TorusMesh.new()
	shell.inner_radius = 0.8
	shell.outer_radius = 2.6
	var sm := Kit.mesh_instance(self, shell, Kit.mat(&"coral_orange", 0.03), amm + Vector3(0.0, 2.6, 0.0))
	sm.rotation.x = PI * 0.5
	Kit.blob(self, amm + Vector3(0.0, 2.6, 0.0), 1.3, &"coral_pink")
	seed_at(&"w9_seed_lakebed", amm + Vector3(2.8, 0.3, 0.0))
	_bone_arch(ROCK + Vector3(14.0, LAKE_Y - LAKE_DEPTH, 16.0), 0.6, 8.0)
	for i in 6:
		Whimsy.kelp(self, ROCK + Vector3(_rng.randf_range(-24.0, 24.0), LAKE_Y - LAKE_DEPTH, _rng.randf_range(-24.0, 24.0)), _rng.randf_range(4.0, 7.0))
	# The old stepping-path Trundle wades along: a loop round the rock, under 1.4 m of water.
	var lx: Array[float] = [-82.0, -98.0]
	for x in lx:
		box(Vector3(x, CAUSEWAY_Y, 39.0), Vector3(7.0, CAUSEWAY_Y + LAKE_DEPTH - 0.6 + 1.0, 38.0), &"stone_light", &"stone_light")
	box(Vector3(-90.0, CAUSEWAY_Y, 17.0), Vector3(23.0, CAUSEWAY_Y + LAKE_DEPTH - 0.6 + 1.0, 8.0), &"stone_light", &"stone_light")
	for x in lx:
		region(Vector3(x, 0.0, 58.0), 180.0)
		ramp(Vector3(0.0, CAUSEWAY_Y, 0.0), 8.0, -CAUSEWAY_Y, 7.0, &"stone_light")
	region(Vector3.ZERO)
	# Trundle: a big triceratops with a saddle, walking the loop and stopping at the station
	# and beside the rock.
	trundle = Dino.new()
	trundle.species = &"trike"
	trundle.model_scale = 1.05
	trundle.colours = {"Purple": &"sunset_orange", "LightBrown": &"thatch", "Brown": &"bark_dark"}
	trundle.clip = &"Walk"
	trundle.calm = 0.35
	trundle.posed_bones = ["Tail1", "Tail2", "Tail3", "Tail4", "Tail5"]
	trundle.speed = 2.4
	trundle.path = _trundle_path()
	trundle.stops = [Vector2(_trundle_stop_at(Vector3(-90.0, 0.0, 78.0)), 7.0), Vector2(_trundle_stop_at(Vector3(-98.0, CAUSEWAY_Y, 37.0)), 6.0)]
	add_child(trundle)
	trundle.paused = true
	var down := deg_to_rad(12.0)
	trundle.aim_chain(["Tail1", "Tail2", "Tail3", "Tail4", "Tail5"], Vector3(0.0, -sin(down), -cos(down)))
	var skin := trundle.skin_points()
	var saddle := trundle.carpet("Torso", Vector3(0.5, 8.0, -5.0), Vector3(0.2, 8.0, 0.6), 3.4, 0.35, &"saddle", &"wood_plank", skin)
	saddle.name = "TrundleSaddle"
	var sxf := trundle.global_transform.affine_inverse() * saddle.global_transform
	for side: float in [-1.0, 1.0]:
		var rail := trundle.add_piece("Torso", sxf * Transform3D(Basis(), Vector3(side * 1.75, 0.55, 0.0)), Vector3(0.2, 0.75, 5.0), &"saddle")
		rail.name = "Rail"
	var tail := trundle.ridge_carpets(-5.4, -14.5, 2.2, 1.8, ["Back", "Tail1", "Tail2", "Tail3", "Tail4", "Tail5"], &"moss", &"moss", 0.3, skin)
	# The Trundle Stop, built round where he stands at the station: a deck where his tail tip
	# rests, and a tower deck level with his saddle.
	var last := tail[tail.size() - 1]
	var half := ((last.get_child(0) as CollisionShape3D).shape as BoxShape3D).size * 0.5
	var last_xf := trundle.global_transform.affine_inverse() * last.global_transform
	trundle.place_at(trundle.stops[0].x)
	var foot := trundle.global_transform * last_xf * Vector3(0.0, half.y, -half.z)
	var back := (trundle.global_transform.basis * last_xf.basis * Vector3.FORWARD) * Vector3(1.0, 0.0, 1.0)
	var deck := foot + back.normalized() * 1.6 + Vector3.DOWN * 0.2
	box(deck, Vector3(3.6, deck.y, 3.6), &"wood_plank", &"wood_plank")
	for k in 3:
		var h := deck.y * float(2 - k) / 3.0
		box(deck + back.normalized() * (3.0 + k * 2.2) + Vector3(0.0, h - deck.y, 0.0), Vector3(3.2, h, 2.4), &"wood_plank", &"wood_plank")
	var side := (trundle.global_basis * Vector3.RIGHT).normalized()
	var stop_top := trundle.global_transform * sxf * Vector3(0.0, 0.175, 0.0)
	var tower := stop_top + side * 5.0 + Vector3.DOWN * 0.15
	box(tower, Vector3(3.4, tower.y, 3.4), &"wood_plank", &"wood_plank")
	ladder(tower - Vector3(0.0, tower.y, 0.0) + side * 1.7, tower.y, atan2(side.x, side.z))
	Whimsy.bunting(self, deck + Vector3(0.0, 2.6, 0.0), tower + Vector3(0.0, 2.6, 0.0), 0.8)
	var st := tower * Vector3(1.0, 0.0, 1.0) + side * 6.0
	trundle.place_at(trundle.stops[0].x - 0.5)
	trundle.paused = false
	cp(&"w9_cp_lake", Vector3(-66.0, 0.0, 78.0))
	npc("fernanda", "Fernanda", st + Vector3(9.0, 0.0, 2.0))
	sign_at(st + Vector3(10.0, 0.0, -2.0), "Trundle Express: round the lake,\nstopping by Lookout Rock!", -PI * 0.5)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var p := Vector3(LAKE.get_center().x, 0.0, LAKE.get_center().y) + Vector3(cos(a) * 32.0, 0.0, sin(a) * 32.0)
		if p.x > -62.0 or absf(p.z - 78.0) < 6.0:
			continue
		cycad(p, 1.8)
	add_capture_point("trundle", Vector3(-60.0, 18.0, 60.0), ROCK + Vector3(0.0, 4.0, 0.0))


func _trundle_path() -> PackedVector3Array:
	var pts := loop_path(Vector3(-90.0, 0.0, 47.0), 16.0, 58.0, 8.0, 1.0)
	# In the water the path drops to the stepping-stones; on the south shore it is on land.
	for i in pts.size():
		var z := pts[i].z
		pts[i].y = lerpf(CAUSEWAY_Y, 0.0, clampf((z - 58.0) / 8.0, 0.0, 1.0))
	return pts


func _trundle_stop_at(p: Vector3) -> float:
	var path := _trundle_path()
	var best := 0.0
	var best_d := INF
	var d := 0.0
	for i in path.size():
		if path[i].distance_to(p) < best_d:
			best_d = path[i].distance_to(p)
			best = d
		d += path[i].distance_to(path[(i + 1) % path.size()])
	return best


# --- Snoozer's haystack (the gong puzzle) --------------------------------------------------------

func _snoozer() -> void:
	region(Vector3.ZERO)
	snoozer = SleepyDino.new()
	snoozer.position = SNOOZER
	snoozer.rotation.y = -PI * 0.5
	add_child(snoozer)
	# The Nest Tree: a giant tree whose branch holds a big stick nest, level with his
	# saddle only when he's standing.
	var awake_deck := SNOOZER.y + SleepyDino.BALE_TOP + snoozer.deck_top_local() - (SleepyDino.BALE_TOP - SleepyDino.SINK)
	nest_deck_top = awake_deck + 2.6
	var deck_world := snoozer.to_global(Vector3(0.0, 0.0, 0.1))
	var nest := Vector3(deck_world.x, nest_deck_top, deck_world.z - 8.0)
	var trunk := Vector3(nest.x + 2.0, 0.0, nest.z - 7.0)
	Kit.pillar(self, trunk + Vector3(0.0, nest_deck_top + 4.0, 0.0), 2.0, nest_deck_top + 4.0, &"bark_mid", &"bark_mid")
	Whimsy.canopy(self, trunk + Vector3(0.0, nest_deck_top + 9.0, 0.0), 9.0, &"teal")
	box(nest, Vector3(7.0, 0.8, 7.0), &"bark_mid", &"bark_light")
	bridge(trunk + Vector3(0.0, nest_deck_top - 0.3, 1.0), nest + Vector3(0.0, -0.3, -3.0), 2.4, &"bark_mid", false)
	for i in 12:
		var a := float(i) / 12.0 * TAU
		var stick := Kit.block(self, nest + Vector3(cos(a) * 2.9, 0.7, sin(a) * 2.9), Vector3(0.5, 0.7, 2.6), &"bark_light", 0, &"")
		stick.rotation.y = a
	for k in 3:
		var egg := SphereMesh.new()
		egg.radius = 0.5
		egg.height = 1.3
		Kit.mesh_instance(self, egg, Kit.mat([&"mush_spot", &"slime_blue", &"candy_pink"][k] as StringName, 0.03), nest + Vector3(-1.2 + k * 1.1, 0.6, 1.0))
	shard_at(&"w9_shard_snoozer", nest + Vector3(0.0, 0.0, -0.8))
	npc("dozy", "Dozy", SNOOZER + Vector3(-12.0, 0.0, 10.0))
	sign_at(SNOOZER + Vector3(-12.0, 0.0, 4.0), "Snoozer's haystack. Ring his gong!", -PI * 0.5)
	add_capture_point("snoozer", SNOOZER + Vector3(-26.0, 16.0, 20.0), SNOOZER + Vector3(0.0, 6.0, -6.0))


# --- The Cycad Shelf (y 6) ---------------------------------------------------------------------

func _cycad_shelf() -> void:
	region(Vector3.ZERO)
	cp(&"w9_cp_shelf", Vector3(4.0, T1, -36.0))
	# The fossil dig: a giant ribcage half out of the ground, a chest, and Ptilda's lost fan.
	var dig := Vector3(-8.0, T1, -52.0)
	for k in 6:
		_rib(dig + Vector3(-7.5 + k * 3.0, 0.0, 0.0), 7.0 - absf(k - 2.5) * 0.8)
	Kit.mesh_instance(self, RoundMesh.box(Vector3(19.0, 1.4, 1.4), 0.6), Kit.mat(&"cloth_cream", 0.03), dig + Vector3(0.0, 0.5, -4.6))
	var skull := SphereMesh.new()
	skull.radius = 2.4
	skull.height = 3.6
	Kit.mesh_instance(self, skull, Kit.mat(&"cloth_cream", 0.03), dig + Vector3(12.0, 1.4, -4.0))
	chest(dig + Vector3(-2.0, 0.0, -2.0), PI * 0.2, &"w9_seed_fossil")
	var fan := ErrandItem.new()
	fan.flag = &"w9_found_fan"
	fan.label_text = "Ptilda's feather fan"
	fan.color_name = &"candy_pink"
	fan.position = dig + Vector3(5.0, 3.8, -3.0)
	add_child(fan)
	ledge(dig + Vector3(5.0, 3.8, -3.0), Vector3(3.0, 0.6, 3.0), &"cloth_cream")
	ledge(dig + Vector3(1.0, 1.8, -1.0), Vector3(3.0, 0.6, 3.0), &"cloth_cream")
	sign_at(dig + Vector3(0.0, 0.0, 6.0), "The Old Fossil Dig", PI)
	for i in 10:
		var p := Vector3(_rng.randf_range(-40.0, 50.0), T1, _rng.randf_range(-66.0, -28.0))
		if p.distance_to(dig) < 14.0 or Vector2(p.x - 2.0, p.z + 36.0).length() < 6.0:
			continue
		cycad(p, _rng.randf_range(1.5, 2.2))
	add_capture_point("shelf", Vector3(-30.0, 24.0, -10.0), Vector3(10.0, T1, -50.0))


func _rib(at: Vector3, h: float) -> void:
	for side: float in [-1.0, 1.0]:
		for k in 5:
			var a := float(k) / 4.0 * PI * 0.45
			var p := at + Vector3(0.0, h * sin(a) + 0.3, side * h * 0.55 * cos(a))
			var b := Kit.mesh_instance(self, RoundMesh.box(Vector3(0.6, 1.8, 0.6), 0.28), Kit.mat(&"cloth_cream", 0.03), p)
			b.rotation.x = side * (PI * 0.5 - a)


# --- The Spring Locks (water levels) and the Hatchery -------------------------------------------

func _spring_locks() -> void:
	region(Vector3.ZERO)
	cp(&"w9_cp_locks", Vector3(48.0, T1, -60.0))
	var l1c := Vector3(LOCK1.get_center().x, 0.0, LOCK1.get_center().y)
	var l2c := Vector3(LOCK2.get_center().x, 0.0, LOCK2.get_center().y)
	# Lower lock: dug into the shelf, bed at -4; a doorway from the Fern Floor onto a shelf at 0.
	box(l1c + Vector3(-5.0, -4.0, 0.0), Vector3(LOCK1.size.x + 10.0, 6.0, LOCK1.size.y), &"sand_mid", &"sand_light")
	box(Vector3(62.0, 0.0, -31.0), Vector3(8.0, 4.0, 6.0), &"stone_light", &"moss")
	box(Vector3(62.0, 0.0, -26.0), Vector3(4.0, 10.0, 4.0), &"stone_light", &"moss")
	box(Vector3(62.0, T1, -26.0), Vector3(4.0, 2.4, 4.0), &"bark_dark", &"moss")
	ladder(Vector3(66.0, -4.0, -31.0), 4.0, PI * 0.5)
	# Divider between the locks, and the upper lock's tank walls up to the heights.
	box(Vector3(68.0, 7.5, -46.0), Vector3(20.0, 1.5, 4.0), &"stone_light", &"moss")
	box(Vector3(57.0, T2, -57.0), Vector3(2.0, T2 - 0.0, 22.0), &"stone_light", &"moss")
	box(Vector3(79.0, T2, -57.0), Vector3(2.0, T2 - 0.0, 22.0), &"stone_light", &"moss")
	box(Vector3(68.0, T2, -68.0), Vector3(24.0, T2, 4.0), &"stone_light", &"moss")
	box(l2c + Vector3(0.0, 0.0, 0.0), Vector3(LOCK2.size.x, 6.0, LOCK2.size.y), &"sand_mid", &"sand_light")
	# A step inside the upper lock for its wheel, and a ladder back up to the divider.
	box(Vector3(61.0, 5.4, -50.5), Vector3(4.0, 5.4, 5.0), &"stone_light", &"moss")
	ladder(Vector3(61.0, 5.4, -48.0), 2.1, PI)
	var lower := SpringLock.new()
	lower.size = LOCK1.size
	lower.depth = 10.0
	lower.levels = [-9.4, -0.6]
	lower.position = l1c + Vector3(0.0, T1, 0.0)
	var upper := SpringLock.new()
	upper.size = LOCK2.size
	upper.depth = T2
	upper.levels = [-7.0, -0.5]
	upper.position = l2c + Vector3(0.0, T2, 0.0)
	locks = SpringLocks.new()
	locks.full = 0
	lower.index = 1
	upper.index = 0
	add_child(lower)
	add_child(upper)
	add_child(locks)
	locks.add_lock(lower, Vector3(62.0, 0.0, -30.5), Vector3(76.0, 6.0, -44.5))
	locks.add_lock(upper, Vector3(61.0, 5.4, -52.0), Vector3(76.0, 12.0, -66.0))
	var fl := locks.add_float(2.4)
	fl.set_meta(&"offset", Vector3(-4.0, 0.0, 2.0))
	locks.float_lock = 1
	locks.gate_open_above = upper.position.y + upper.levels[1] - 0.6
	# The Hatchery: under the shelf, behind the lower lock's west wall, at its bed.
	var hatch: Array = secret_cave(HATCH, PI * 0.5, Vector3(16.0, 9.0, 14.0), &"stone_light", &"gate")
	ledge(Vector3(-4.5, 1.2, -3.0), Vector3(3.0, 1.2, 3.0), &"mush_spot")
	ledge(Vector3(-1.0, 3.2, -4.0), Vector3(3.0, 0.5, 2.6), &"wood_plank")
	crumble(Vector3(3.0, 5.0, -2.5), Vector3(2.6, 0.5, 2.6), CrumblePlatform.Look.ROCK)
	ledge(Vector3(5.0, 7.0, 1.5), Vector3(2.8, 0.5, 2.8), &"wood_plank")
	shard_at(&"w9_shard_hatchery", Vector3(5.0, 7.0, 1.5))
	ledge(Vector3(-5.0, 4.8, 1.0), Vector3(2.6, 0.5, 2.6), &"wood_plank")
	seed_at(&"w9_seed_hatchery", Vector3(-5.0, 4.8, 1.0))
	for k in 5:
		var egg := SphereMesh.new()
		egg.radius = 0.8
		egg.height = 2.0
		Kit.mesh_instance(self, egg, Kit.mat([&"mush_spot", &"slime_blue", &"candy_pink", &"lime_pop", &"gold"][k] as StringName, 0.03), P(Vector3(-5.0 + k * 2.5, 1.0, -5.5)))
	_frame = hatch[0]
	region(Vector3.ZERO)
	hatch_gate = hatch[1] as VineGate
	locks.gate = hatch_gate
	locks.keep_open_box = AABB(Vector3(42.0, -5.0, -45.0), Vector3(16.0, 11.0, 18.0))
	# A rope from the float over a tall pulley post and down to the gate.
	var pulley_at := Vector3(60.0, 17.5, -46.0)
	Kit.pillar(self, pulley_at + Vector3(0.0, -0.4, 0.0), 0.35, pulley_at.y - 0.4 - 7.5, &"bark_dark", &"gold")
	var pulley := TorusMesh.new()
	pulley.inner_radius = 0.4
	pulley.outer_radius = 0.7
	Kit.mesh_instance(self, pulley, Kit.mat(&"gold", 0.03), pulley_at).rotation.z = PI * 0.5
	locks.rope_anchor = pulley_at
	var gate_top := Vector3(57.2, 0.5, -36.0)
	var span := gate_top - pulley_at
	var up := span.normalized()
	var side := up.cross(Vector3.FORWARD).normalized()
	var rope := Kit.mesh_instance(self, RoundMesh.box(Vector3(0.12, 1.0, 0.12), 0.04), Kit.mat(&"wood_warm"))
	rope.transform = Transform3D(Basis(side, up, side.cross(up)).scaled(Vector3(1.0, span.length(), 1.0)), pulley_at + span * 0.5)
	npc("burble", "Burble", Vector3(52.0, T1, -48.0))
	sign_at(Vector3(56.0, T1, -40.0), "The Spring Locks: one spring, two locks.\nFill one, and the other drains!", -PI * 0.5)
	sign_at(Vector3(56.0, 0.0, -20.0), "Lower lock doorway", PI)
	# The falls: water pours from the lower lock down into the river.
	var fall := BoxMesh.new()
	fall.size = Vector3(8.0, 6.4, 0.5)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"vertical", true)
	wm.set_shader_parameter(&"flow", Vector2(0.0, 0.6))
	Kit.mesh_instance(self, fall, wm, Vector3(72.0, 2.8, -23.9))
	Ambient.motes(self, Vector3(72.0, 0.6, -21.0), Vector3(10.0, 2.0, 4.0), Color(1.0, 1.0, 1.0, 0.5))
	add_capture_point("locks", Vector3(40.0, 24.0, -18.0), Vector3(68.0, 4.0, -46.0))


# --- The Roost (the Great Cliff's top, y 12) ----------------------------------------------------

func _roost() -> void:
	region(Vector3.ZERO)
	var g := T2
	cp(&"w9_cp_roost", Vector3(-84.0, g, -40.0))
	sign_at(Vector3(-78.0, g, -36.0), "The Roost. Mind the edge!", PI)
	# Treehouses: giant trunks with round decks, rope bridges between them.
	var houses: Array[Vector3] = [Vector3(-104.0, g, -46.0), Vector3(-70.0, g, -58.0), Vector3(-62.0, g, -36.0), Vector3(-96.0, g, -62.0)]
	var deck_h: Array[float] = [6.0, 9.0, 6.0, 9.0]
	for i in houses.size():
		var h := houses[i]
		var top := h + Vector3(0.0, deck_h[i], 0.0)
		var crown := 12.0 if i == 3 else 8.0
		Kit.pillar(self, top + Vector3(0.0, crown, 0.0), 1.4, deck_h[i] + crown, &"bark_mid", &"bark_mid")
		Whimsy.canopy(self, top + Vector3(0.0, crown + 3.0 + (3.0 if i == 3 else 0.0), 0.0), 7.0, tree_kinds[i % tree_kinds.size()])
		Kit.pillar(self, top, 5.5, 0.8, &"wood_plank", &"wood_plank")
		var hut_a := 2.4 + i * 1.3
		egg_hut(top + Vector3(cos(hut_a), 0.0, sin(hut_a)) * 3.4, hut_a + PI * 0.5, 1.5, &"mush_spot", [&"candy_pink", &"slime_blue", &"lime_pop", &"gold"][i] as StringName)
		ladder(h + Vector3(0.0, 0.0, 5.5), deck_h[i], 0.0)
	for pair: Array in [[0, 1], [1, 2], [0, 3], [3, 1]]:
		var a := houses[pair[0] as int] + Vector3(0.0, deck_h[pair[0] as int], 0.0)
		var b := houses[pair[1] as int] + Vector3(0.0, deck_h[pair[1] as int], 0.0)
		var d := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		bridge(a + d * 4.9, b - d * 4.9, 2.8, &"wood_plank", true, &"bark_dark")
	# Shelf fungi up the last trunk to a crow's nest seed.
	var t3 := houses[3] + Vector3(0.0, deck_h[3], 0.0)
	Kit.pillar(self, t3 + Vector3(2.6, 2.4, 0.0), 1.6, 0.5, &"sunset_orange", &"mush_spot")
	Kit.pillar(self, t3 + Vector3(0.0, 4.8, 2.6), 1.6, 0.5, &"gold", &"mush_spot")
	Kit.pillar(self, t3 + Vector3(-2.6, 7.2, 0.0), 1.8, 0.5, &"mush_red", &"mush_spot")
	seed_at(&"w9_seed_roost_top", t3 + Vector3(-3.0, 7.2, 0.0))
	npc("ptilda", "Ptilda", Vector3(-88.0, g, -48.0), &"", Vector3.ZERO, "", &"", &"w9_seed_roost_errand").errand_flag = &"w9_found_fan"
	npc("tuffy", "Tuffy", Vector3(-70.0, g + 9.0, -56.0))
	for i in 10:
		var p := Vector3(_rng.randf_range(-120.0, -48.0), g, _rng.randf_range(-68.0, -28.0))
		var near := false
		for h in houses:
			if Vector2(p.x - h.x, p.z - h.z).length() < 8.0:
				near = true
		if not near and Vector2(p.x + 84.0, p.z + 40.0).length() > 6.0:
			fern(p, _rng.randf_range(3.0, 5.0))
	add_capture_point("roost", Vector3(-40.0, 34.0, -20.0), Vector3(-84.0, 16.0, -48.0))


# --- Ember Cone (volcano) and the lava tube ------------------------------------------------------

func _ember_cone() -> void:
	region(Vector3.ZERO)
	var radii: Array[float] = [26.0, 21.0, 16.5, 12.5, 8.5]
	var cols: Array[StringName] = [&"stone_dark", &"bark_dark", &"stone_dark", &"bark_dark", &"stone_dark"]
	for i in radii.size():
		var top := 3.0 * (i + 1)
		Kit.pillar(self, VOLCANO + Vector3(0.0, top, 0.0), radii[i], top + 2.0, cols[i], &"moss" if i < 3 else &"sand_mid")
	# A ramp up round the outside of each tier, a quarter turn on from the last (the first starts
	# on the heights' ground). Its top end lies right beside the next tier's rim.
	for i in range(-1, radii.size() - 1):
		var top := 3.0 * (i + 1)
		var lane := radii[i + 1] + VOLCANO_LANE
		var a0 := i * PI * 0.5 + 0.4
		var da := 9.4 / lane
		var a := VOLCANO + Vector3(cos(a0), 0.0, sin(a0)) * lane + Vector3(0.0, top, 0.0)
		var b := VOLCANO + Vector3(cos(a0 + da), 0.0, sin(a0 + da)) * lane + Vector3(0.0, top + 3.0, 0.0)
		bridge(a, b, 3.8, &"sand_mid", false)
		# A flat landing past the top, so running off the end still finds the tier.
		var along := (b - a) * Vector3(1.0, 0.0, 1.0)
		var land := box(b + along.normalized() * 2.2, Vector3(3.8, 0.6, 4.4), &"sand_mid", &"sand_light")
		land.rotation.y = atan2(along.x, along.z)
	# The crater: a glowing pool (too hot to touch) inside a ring of rocks.
	var crater := VOLCANO + Vector3(0.0, 15.0, 0.0)
	var lava := CylinderMesh.new()
	lava.top_radius = 3.4
	lava.bottom_radius = 3.4
	lava.height = 0.2
	var lm := Kit.unique_mat(&"sunset_orange")
	lm.set_shader_parameter(&"flash", 0.7)
	lm.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	Kit.mesh_instance(self, lava, lm, crater + Vector3(0.0, 0.12, 0.0))
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var ps := CylinderShape3D.new()
	ps.radius = 3.2
	ps.height = 1.0
	Kit.add_shape(pit, ps)
	pit.position = crater + Vector3(0.0, 0.4, 0.0)
	add_child(pit)
	for i in 9:
		var a := float(i) / 9.0 * TAU
		box(crater + Vector3(cos(a) * 5.4, 1.6, sin(a) * 5.4), Vector3(2.4, 1.6, 2.4), &"stone_dark", &"sand_mid").rotation.y = a
	var glow := OmniLight3D.new()
	glow.light_color = Palette.color(&"sunset_orange")
	glow.light_energy = 2.0
	glow.omni_range = 12.0
	glow.distance_fade_enabled = true
	glow.distance_fade_begin = 80.0
	glow.position = crater + Vector3(0.0, 2.0, 0.0)
	add_child(glow)
	Ambient.motes(self, crater + Vector3(0.0, 5.0, 0.0), Vector3(6.0, 8.0, 6.0), Color(0.6, 0.6, 0.65, 0.6))
	seed_at(&"w9_seed_summit", crater + Vector3(5.4, 1.6, 0.0))
	# The lava tube: a cracked rock behind the cone, steam rising inside, a climb to a shard.
	var tube: Array = secret_cave(Vector3(VOLCANO.x, T2, -144.0), 0.0, Vector3(14.0, 18.0, 12.0), &"stone_dark", &"break")
	ledge(Vector3(-4.5, 1.4, -3.0), Vector3(3.0, 1.4, 3.0), &"sunset_orange")
	updraft(Vector3(-0.5, 0.3, -2.0), Vector3(4.0, 9.0, 4.0), 9.0, &"wind")
	ledge(Vector3(3.5, 7.0, -3.5), Vector3(3.0, 0.5, 2.6), &"stone_dark")
	crumble(Vector3(4.0, 9.6, 1.0), Vector3(2.6, 0.5, 2.6), CrumblePlatform.Look.ROCK)
	ledge(Vector3(0.0, 12.0, 3.0), Vector3(2.8, 0.5, 2.6), &"stone_dark")
	ledge(Vector3(-4.0, 14.4, 0.0), Vector3(3.0, 0.5, 3.0), &"sunset_orange")
	shard_at(&"w9_shard_lavatube", Vector3(-4.0, 14.4, 0.0))
	for k in 4:
		Whimsy.crystal(self, P(Vector3(-5.0 + k * 3.2, 0.3, -5.2)), &"sunset_orange", 0.9, false)
	_frame = tube[0]
	region(Vector3.ZERO)
	Ambient.motes(self, Vector3(VOLCANO.x, T2 + 2.0, -137.0), Vector3(5.0, 3.0, 2.0), Color(1.0, 1.0, 1.0, 0.5))
	add_capture_point("volcano", Vector3(-40.0, 40.0, -80.0), VOLCANO + Vector3(0.0, 10.0, 0.0))


# --- The Tar Crater and its turning log (turn bridge) --------------------------------------------

func _tar_crater() -> void:
	region(Vector3.ZERO)
	cp(&"w9_cp_crater", TAR + Vector3(0.0, 0.0, TAR_HALF + 8.0))
	# The pit: tar three metres down (it's a sticky pit: in you go, back you come).
	box(Vector3(TAR.x, TAR_Y - 0.6, TAR.z), Vector3(TAR_HALF * 2.0, 6.0, TAR_HALF * 2.0), &"bark_dark", &"bark_dark")
	var tar := PlaneMesh.new()
	tar.size = Vector2(TAR_HALF * 2.0, TAR_HALF * 2.0)
	var tm := Kit.unique_mat(&"ink_navy")
	Kit.mesh_instance(self, tar, tm, Vector3(TAR.x, TAR_Y - 0.5, TAR.z))
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var ps := BoxShape3D.new()
	ps.size = Vector3(TAR_HALF * 2.0, 2.0, TAR_HALF * 2.0)
	Kit.add_shape(pit, ps)
	pit.position = Vector3(TAR.x, TAR_Y - 0.4, TAR.z)
	add_child(pit)
	Ambient.motes(self, Vector3(TAR.x, TAR_Y + 0.5, TAR.z), Vector3(30.0, 1.0, 30.0), Color(0.3, 0.25, 0.35, 0.5))
	# Four landings jutting over the tar.
	var dirs: Array[Vector3] = [Vector3(0.0, 0.0, -1.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0)]
	for d in dirs:
		var c := TAR + d * (TAR_HALF - 1.5)
		box(c, Vector3(5.0, TAR.y - TAR_Y + 3.0, 5.0) if d.x == 0.0 else Vector3(5.0, TAR.y - TAR_Y + 3.0, 5.0), &"stone_dark", &"moss")
	# The pivot stump and the log bridge (it starts east-west; whack the wheel at its middle
	# while riding it and it swings north-south).
	Kit.pillar(self, TAR + Vector3(0.0, -1.7, 0.0), 2.0, TAR.y - 1.7 - (TAR_Y - 3.6), &"bark_mid", &"bark_light")
	turn_bridge = TurnBridge.new()
	turn_bridge.position = TAR
	turn_bridge.length = (TAR_HALF - 3.6) * 2.0
	turn_bridge.width = 3.6
	turn_bridge.stops = [PI * 0.5, 0.0]
	turn_bridge.index = 0
	add_child(turn_bridge)
	turn_bridge.add_lever(Vector3(0.0, 0.0, 0.0))
	# The north nook (only the log reaches it): the pterosaur's nest, with Grandpa's spectacles.
	var nn := TAR + Vector3(0.0, 0.0, -TAR_HALF - 9.0)
	box(nn + Vector3(-11.0, 12.0, 0.0), Vector3(2.0, 12.0, 18.0), &"stone_dark", &"moss")
	box(nn + Vector3(11.0, 12.0, 0.0), Vector3(2.0, 12.0, 18.0), &"stone_dark", &"moss")
	for i in 12:
		var a := float(i) / 12.0 * TAU
		var stick := Kit.block(self, nn + Vector3(cos(a) * 3.4, 0.8, -2.0 + sin(a) * 3.4), Vector3(0.6, 0.8, 3.0), &"bark_light", 0, &"")
		stick.rotation.y = a
	ladder(nn + Vector3(-10.0, 0.0, -6.0), 12.0, PI * 0.5)
	# The east nook: a seed on a mossy stump.
	var en := TAR + Vector3(TAR_HALF + 8.0, 0.0, 0.0)
	box(en + Vector3(0.0, 12.0, -9.0), Vector3(16.0, 12.0, 2.0), &"stone_dark", &"moss")
	box(en + Vector3(0.0, 12.0, 9.0), Vector3(16.0, 12.0, 2.0), &"stone_dark", &"moss")
	box(en + Vector3(9.0, 12.0, 0.0), Vector3(2.0, 12.0, 20.0), &"stone_dark", &"moss")
	Kit.pillar(self, en + Vector3(2.0, 1.2, 0.0), 1.6, 1.2, &"bark_mid", &"moss")
	ladder(en + Vector3(4.0, 0.0, -8.0), 12.0, 0.0)
	seed_at(&"w9_seed_tar_nook", en + Vector3(2.0, 1.2, 0.0))
	npc("amberly", "Amberly", TAR + Vector3(4.0, 0.0, TAR_HALF + 3.0))
	sign_at(TAR + Vector3(-4.0, 0.0, TAR_HALF + 3.0), "The Tar Crater. The old log turns!\nStep on from the west side.", 0.0)
	add_capture_point("tar_crater", TAR + Vector3(-30.0, 22.0, 30.0), TAR)


# --- The Skyfern (Vinelash and platforming up to a crown) ----------------------------------------

func _skyfern() -> void:
	region(Vector3.ZERO)
	var c := SKYFERN
	Kit.pillar(self, c + Vector3(0.0, 21.0, 0.0), 3.6, 21.0, &"bark_mid", &"bark_light")
	# Shelf fungi spiral up the trunk to the crown: a climb, with one that crumbles and one that
	# drifts. Hook flowers off to the side are the Vinelash shortcut.
	var cols: Array[StringName] = [&"mush_red", &"sunset_orange", &"gold", &"mush_purple", &"mush_teal", &"candy_pink"]
	for i in 6:
		var a := i * PI * 0.5
		var r := SKYFERN_LAST_SHELF if i == 5 else SKYFERN_SHELF
		var s := Vector3(cos(a) * r, 3.0 * (i + 1), sin(a) * r)
		if i == 3:
			crumble(c + s, Vector3(3.8, 0.6, 3.8), CrumblePlatform.Look.ROCK)
		elif i == 4:
			mover(c + s, Vector3(3.8, 0.6, 3.8), Vector3(0.0, 0.0, 3.0), 5.0, cols[i])
		else:
			Kit.pillar(self, c + s, 2.9, 0.6, cols[i], &"mush_spot")
	hook(c + Vector3(-11.0, 8.0, 6.0))
	hook(c + Vector3(-9.0, 18.0, -3.0))
	# The crown: a mossy deck round the trunk top, ringed with giant fronds.
	var crown := c + Vector3(0.0, 21.0, 0.0)
	Kit.pillar(self, crown, 4.4, 0.8, &"bark_mid", &"moss")
	shard_at(&"w9_shard_crown", crown + Vector3(2.4, 0.0, 0.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU
		fern(crown + Vector3(cos(a) * 4.0, 0.0, sin(a) * 4.0), 6.0, a)
	sign_at(c + Vector3(4.0, 0.0, 6.0), "The Skyfern. Climb the shelf fungi to the crown!\n(Vinelash, 2 / G: catch the flowers.)", PI)
	critter(Batling, c + Vector3(6.0, 14.0, 4.0))
	add_capture_point("skyfern", c + Vector3(26.0, 30.0, 20.0), c + Vector3(-2.0, 14.0, 0.0))


# --- The gate and Chomposaurus Rex's clearing ---------------------------------------------------

func _rex_gate() -> void:
	region(Vector3.ZERO)
	cp(&"w9_cp_gate", Vector3(36.0, T2, -102.0))
	npc("bixby", "Ranger Bixby", Vector3(42.0, T2, -104.0))
	sign_at(Vector3(44.0, T2, -98.0), "Rex's Clearing. 3 Star Shards open the gate.\nWhen his tail crest glows: PLUNGE it!", -PI * 0.5)
	heart_bush(Vector3(34.0, T2, -96.0))
	# A walled lane to the gate, and the ring of mossy rocks round the clearing.
	box(Vector3(48.0, T2 + WALL_H, -122.0), Vector3(12.0, WALL_H, 2.0), &"stone_dark", &"moss")
	box(Vector3(48.0, T2 + WALL_H, -110.0), Vector3(12.0, WALL_H, 2.0), &"stone_dark", &"moss")
	region(Vector3(54.0, T2, -116.0), -90.0)
	make_gate(Vector3.ZERO, 10.0)
	region(Vector3.ZERO)
	box(Vector3(54.0, T2 + WALL_H, -116.0), Vector3(3.0, WALL_H - 4.2, 12.0), &"stone_dark", &"moss")
	var n := 34
	for i in n:
		var a := float(i) / n * TAU
		if absf(wrapf(a - PI, -PI, PI)) < deg_to_rad(15.0):
			continue
		var c := ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R + 2.5)
		var b := box(c + Vector3(0.0, WALL_H, 0.0), Vector3(4.9, WALL_H, 3.0), [&"stone_dark", &"bark_dark", &"leaf_dark"][i % 3] as StringName, &"moss")
		b.rotation.y = -(a + PI * 0.5)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.2
		fern(ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R + 0.5), 5.0, a)
	add_capture_point("gate", Vector3(30.0, T2 + 12.0, -90.0), Vector3(54.0, T2 + 2.0, -116.0))
	add_capture_point("rex", ARENA + Vector3(-20.0, 16.0, 14.0), ARENA + Vector3(0.0, 3.0, 4.0))


# --- Ways up (Build 6 accessibility: several on every face, easy ways down) ----------------------

func _ways_up() -> void:
	region(Vector3.ZERO)
	# Fern Floor -> Cycad Shelf: the Fern Ramp, ladders, a springcap and a hook flower.
	ramp(Vector3(14.0, 0.0, -4.0), 20.0, T1, 6.0, &"wood_plank")
	sign_at(Vector3(20.0, 0.0, -2.0), "The Fern Ramp, up to the Cycad Shelf", PI)
	for x: float in [-24.0, 40.0, 96.0]:
		ladder(Vector3(x, 0.0, -23.4), T1, 0.0)
	bouncer(Vector3(-12.0, 0.0, -20.0), Springcap.Look.GLOWCAP, 8.0)
	hook(Vector3(4.0, T1, -26.0))
	# Cycad Shelf -> Canopy Heights: the Cycad Ramp, ladders, a lift.
	ramp(Vector3(-30.0, T1, -48.0), 22.0, T2 - T1, 6.0, &"wood_plank")
	for x: float in [10.0, 46.0, 104.0]:
		ladder(Vector3(x, T1, -69.4), T2 - T1, 0.0)
	lift_at(Vector3(28.0, T1, -67.5), T2, 7.0)
	sign_at(Vector3(24.0, T1, -62.0), "Lift to Canopy Heights", PI)
	# Fern Floor -> the Great Cliff (12 m): a spiral stair, ladders with a halfway ledge.
	ramp_tower(Vector3(-104.0, 0.0, -12.0), 0.0, T2, 8.0, 4.0, &"stone_dark", &"wood_plank", &"moss")
	bridge(Vector3(-104.0, T2, -16.0), Vector3(-104.0, T2, -24.6), 3.6, &"wood_plank", true, &"bark_dark")
	ledge(Vector3(-80.0, 6.0, -22.0), Vector3(6.0, 0.6, 3.0), &"stone_dark")
	seed_at(&"w9_seed_cliff", Vector3(-78.0, 6.0, -22.0))
	ladder(Vector3(-82.0, 0.0, -20.4), 6.0, 0.0)
	ladder(Vector3(-78.0, 6.0, -23.4), 6.0, 0.0)
	ladder(Vector3(-114.0, 0.0, -23.4), T2, 0.0)
	# Easy ways down from the heights: the Great Cliff lift and a bounce pad back up.
	lift_at(Vector3(-66.0, 0.0, -21.4), T2, 8.0)
	sign_at(Vector3(-70.0, 0.0, -14.0), "Lift to the Roost", PI)


# --- Monsters (Mighty Roar counters the Shieldknights and Hexwizards) ----------------------------

func _monsters() -> void:
	region(Vector3.ZERO)
	critter(Hopfrog, Vector3(-58.0, 0.05, 72.0))
	critter(Hopfrog, Vector3(-56.0, 0.05, 28.0))
	critter(Buzzbee, Vector3(30.0, 2.0, 80.0))
	critter(Buzzbee, Vector3(-28.0, 2.0, -4.0))
	big_gloplet(Vector3(46.0, 0.5, 30.0))
	critter(Armorling, Vector3(20.0, T1 + 0.5, -40.0))
	critter(Armorling, Vector3(-20.0, T1 + 0.5, -60.0))
	place(Puffcap.new(), Vector3(36.0, T1, -56.0))
	place(Puffcap.new(), Vector3(90.0, T1, -40.0))
	boulderkin(Vector3(100.0, T1 + 0.5, -54.0), &"sunset_orange", &"moss", &"gold")
	critter(Mimic, Vector3(-16.0, T1 + 0.3, -42.0)).rotation.y = 0.4
	critter(Hexwizard, TAR + Vector3(10.0, 0.0, TAR_HALF + 10.0))
	critter(Hexwizard, Vector3(-46.0, T2, -86.0))
	critter(Armorling, Vector3(36.0, T2 + 0.5, -112.0))
	critter(Wyrmling, VOLCANO + Vector3(0.0, 22.0, 14.0))
	critter(Wispghost, Vector3(-90.0, T2 + 1.0, -40.0))
	batling(Vector3(-62.0, T2 + 6.0, -46.0), false)
	batling(Vector3(-80.0, 4.6, -21.0), true)
	gloplets(Vector3(-2.0, T2, -84.0), 9.0, [Vector3.ZERO, Vector3(3.0, 0.0, 2.0), Vector3(-3.0, 0.0, -2.0)])


# --- Jungle dressing: ferns, cycads, trees, flowers ---------------------------------------------

func _jungle() -> void:
	region(Vector3.ZERO)
	for i in 160:
		var p := Vector3(_rng.randf_range(-122.0, 122.0), 0.0, _rng.randf_range(-150.0, 118.0))
		p.y = _ground_y(p)
		if p.y < -0.5 or _busy(p):
			continue
		match i % 5:
			0, 1, 2:
				fern(p, _rng.randf_range(2.5, 5.5))
			3:
				Whimsy.tree(self, p, tree_kinds[i % tree_kinds.size()], _rng.randf_range(1.2, 1.9), -1, _rng.randf() * TAU)
			_:
				cycad(p, _rng.randf_range(1.4, 2.0))
	for i in 50:
		var p := Vector3(_rng.randf_range(-122.0, 122.0), 0.0, _rng.randf_range(-150.0, 118.0))
		p.y = _ground_y(p)
		if p.y < -0.5 or _busy(p):
			continue
		prop([&"q_flowers_3", &"q_flowers_4", &"q_bush_flowers", &"q_fern", &"q_mushrooms"][i % 5] as StringName, p, _rng.randf() * TAU, _rng.randf_range(1.2, 2.0), false)
	fireflies(Vector3(-84.0, T2 + 2.0, -46.0), 20.0, 20)
	butterflies(Vector3(0.0, T1, -46.0), 30.0, 8)


## Top of the terrain at p (x, z): which shelf it's on; -INF in water or pits.
func _ground_y(p: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	if LAKE.has_point(q) or RIVER_NS.has_point(q) or RIVER_EW.has_point(q):
		return -INF
	if p.z >= -24.0:
		return 0.0
	if p.z >= -70.0 and p.x >= -44.0:
		if Rect2(43.0, -66.0, 37.0, 42.0).has_point(q):
			return -INF
		return T1
	if Rect2(TAR.x - TAR_HALF - 2.0, TAR.z - TAR_HALF - 12.0, TAR_HALF * 2.0 + 14.0, TAR_HALF * 2.0 + 14.0).has_point(q):
		return -INF
	return T2


## True near set pieces, so dressing never blocks a path, a puzzle or a dinosaur.
func _busy(p: Vector3) -> bool:
	var spots: Array[Array] = [
		[Vector3(0.0, 0.0, 66.0), 28.0], [Vector3(0.0, 0.0, 100.0), 10.0], [MOSSBACK + Vector3(0.0, 0.0, 3.0), 30.0],
		[Vector3(-90.0, 0.0, 80.0), 14.0], [SNOOZER, 16.0], [SNOOZER + Vector3(-8.0, 0.0, -14.0), 10.0],
		[Vector3(14.0, 0.0, -14.0), 8.0], [Vector3(30.0, 0.0, -6.0), 12.0], [Vector3(15.0, 0.0, -15.0), 6.0], [Vector3(40.0, 0.0, 2.0), 6.0], [Vector3(-8.0, T1, -52.0), 14.0],
		[Vector3(68.0, 0.0, -46.0), 18.0], [Vector3(-84.0, T2, -48.0), 26.0], [VOLCANO, 26.0],
		[Vector3(VOLCANO.x, T2, -144.0), 12.0], [TAR, 30.0], [SKYFERN, 16.0], [ARENA, 28.0], [Vector3(40.0, T2, -110.0), 12.0],
		[Vector3(-104.0, 0.0, -12.0), 10.0], [Vector3(-30.0, T1, -58.0), 6.0], [Vector3(28.0, T1, -66.0), 6.0],
		[Vector3(-80.0, 0.0, -20.0), 6.0], [Vector3(-66.0, 0.0, -20.0), 6.0], [Vector3(4.0, T1, -36.0), 6.0],
	]
	for s in spots:
		var c := s[0] as Vector3
		if Vector2(p.x - c.x, p.z - c.z).length() < float(s[1]):
			return true
	for x: float in [6.0, -30.0, 44.0]:
		if absf(p.x - x) < 4.0 and absf(p.z - 15.0) < 12.0:
			return true
	# Keep clear of every cliff face and ladder foot.
	return absf(p.z + 24.0) < 4.0 or (absf(p.z + 70.0) < 4.0 and p.x > -44.0) or (absf(p.x + 44.0) < 4.0 and p.z < -24.0 and p.z > -70.0)
