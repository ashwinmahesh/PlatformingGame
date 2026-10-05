class_name Sunscorch
extends BossWorld
## World 3, Sunscorch Canyon (Build 6 re-layout, Ashwin: "the levels shouldn't feel the same",
## "a dense and lively sandbox"). A high painted-desert plateau cut by one long winding gorge.
## You enter from the south and follow the gorge north and round to the east:
##   Oasis Camp bowl  - Sandy's camp, a pool, a lookout; a stair up to the high plateau, where
##                      mesas stack up to the Summit (Star Shard) and a far Glider's Perch
##   Ruins bowl       - turquoise ruins with Armorlings, a temple wall hiding a Star Shard, and
##                      a Fireball lantern vault; Professor Quill's lost book errand
##   Quicksand bowl   - slow sand, Pricklepots, three crystals for a bridge over the chasm to the
##                      third Star Shard, and a crate to shove onto the Sun Shrine's plate
##   Golem Gate       - a narrow slot to the Rumble Golem's ring
## Side canyons hide a second oasis, a cactus garden and two secret caves with their own climbs
## (Dusty's mine, a bramble cave). Rope bridges cross the gorge up on the plateau. Falling only
## drops you to the gorge floor; only the eastern chasm is a pit. Clearing it teaches Thunderclap.

const WORLD := &"world_03"
const ARENA := Vector3(60.0, 0.0, 114.0)
const ARENA_R := 18.0
const PLATEAU := 12.0
const STRIPES: Array[StringName] = [&"candy_pink", &"thatch", &"mush_spot", &"mush_purple", &"sunset_orange"]
const ROCKS: Array[StringName] = [&"roof_red", &"sunset_orange", &"wood_warm"]
## The gorge: [from, to, half-width] in world XZ; bowls are [centre, radius].
const GORGE: Array[Array] = [
	[Vector2(0.0, 152.0), Vector2(0.0, 70.0), 11.0], [Vector2(0.0, 70.0), Vector2(-50.0, 30.0), 11.0],
	[Vector2(-50.0, 30.0), Vector2(-55.0, -30.0), 11.0], [Vector2(-55.0, -30.0), Vector2(-10.0, -75.0), 11.0],
	[Vector2(-10.0, -75.0), Vector2(45.0, -95.0), 11.0], [Vector2(45.0, -95.0), Vector2(95.0, -50.0), 11.0],
	[Vector2(95.0, -50.0), Vector2(100.0, 20.0), 11.0], [Vector2(100.0, 20.0), Vector2(60.0, 75.0), 11.0],
	[Vector2(60.0, 75.0), Vector2(60.0, 98.0), 5.0],
	[Vector2(-50.0, 30.0), Vector2(-108.0, 42.0), 8.0], [Vector2(-10.0, -75.0), Vector2(-38.0, -128.0), 8.0],
	[Vector2(0.0, 70.0), Vector2(40.0, 96.0), 8.0],
]
const BOWLS: Array[Array] = [
	[Vector2(0.0, 70.0), 30.0], [Vector2(-55.0, -30.0), 26.0], [Vector2(95.0, -50.0), 26.0], [Vector2(60.0, 114.0), 18.0],
	[Vector2(-108.0, 42.0), 13.0], [Vector2(-38.0, -128.0), 15.0], [Vector2(40.0, 96.0), 14.0], [Vector2(0.0, 146.0), 13.0],
]
const CHASM := Rect2(124.0, -74.0, 26.0, 48.0)


func configure() -> void:
	world_id = WORLD
	model_tint = Color(1.08, 0.98, 0.86)
	platform_colour = &"yellow"
	sky_top = Color(0.08, 0.38, 0.95)
	sky_horizon = Color(0.72, 0.88, 1.0)
	sky_bottom = Color(0.92, 0.92, 0.95)
	cloud_cover = 0.32
	cloud_shade = Color(0.82, 0.8, 0.98)
	sun_color = Color(1.0, 0.92, 0.74)
	sun_energy = 1.2
	sun_angles = Vector2(-58.0, -30.0)
	fog_color = Color(0.82, 0.9, 1.0)
	fog_begin = 110.0
	fog_end = 360.0
	tree_kinds = [&"gold", &"autumn", &"lime", &"blossom"]
	tops = {&"roof_teal": &"stone_light", &"wood_warm": &"sand_mid", &"sunset_orange": &"sand_light", &"stone_light": &"sand_light", &"stone_dark": &"sand_mid", &"bark_light": &"sand_mid", &"bark_mid": &"sand_mid", &"roof_red": &"sand_mid"}
	grass_density = 0.015


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w3_entrance"
	music = &"canyon"
	floor_y = 0.0
	kill_y = -24.0
	_rng.seed = 303
	arena_center = ARENA
	arena_radius = ARENA_R
	arena_exit_spawn = &"w3_arena_exit"
	defeat_banner = "The Rumble Golem tumbles!"
	regions = {"entry": Vector3(0.0, 0.0, 140.0), "camp": Vector3(0.0, 0.0, 70.0), "plateau": Vector3(-55.0, 12.0, 110.0), "ruins": Vector3(-55.0, 0.0, -30.0), "narrows": Vector3(20.0, 0.0, -88.0), "flats": Vector3(95.0, 0.0, -50.0), "gate": Vector3(60.0, 0.0, 80.0), "golem": ARENA}
	_ground_and_plateau()
	_entry()
	_camp()
	_high_plateau()
	_ruins()
	_flats()
	_side_canyons()
	_golem_gate()
	_gorge_life()
	finish_boss_world()
	finish_life(&"moss")


func create_boss() -> BossBase:
	var g := RumbleGolem.new()
	g.rng.seed = 3303
	g.position = ARENA + Vector3(0.0, 0.0, 6.0)
	return g


# --- Helpers ----------------------------------------------------------------------------------

## A painted-desert mesa: sandy top, orange sides and candy-coloured bands.
func mesa(top_local: Vector3, size_xz: Vector2, base: StringName = &"wood_warm", bottom: float = 0.0, grass: bool = true) -> void:
	var top := P(top_local)
	var h := top.y - bottom
	var size := S(Vector3(size_xz.x, h, size_xz.y))
	var k := absi(int(top.x * 3.0 + top.z * 7.0))
	if base == &"wood_warm":
		base = ROCKS[k % ROCKS.size()]
	Kit.block(self, top, size, base, Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_light")
	var y := bottom + 1.6
	var i := 0
	while y < top.y - 1.2:
		Kit.block(self, Vector3(top.x, y + 0.5, top.z), Vector3(size.x + 0.5, 1.0, size.z + 0.5), STRIPES[(k + i) % STRIPES.size()], 0, &"")
		y += 2.8 + float((k + i) % 3) * 0.4
		i += 1
	if grass:
		_add_grass_area(top, Vector2(size.x, size.z), int(size.x * size.z * 0.03))


func balloon_lift(top_local: Vector3, travel_local: Vector3, period: float, colors: Array[StringName], phase: float = 0.0) -> void:
	var m := mover(top_local, Vector3(4.6, 1.0, 4.6), travel_local, period, &"wood_plank", phase)
	Whimsy.balloon(m, Vector3(0.0, 0.5, 0.0), colors)


func tumbleweed(start: Vector3, dir: Vector3, span: float, phase: float) -> void:
	var t := Tumbleweed.new()
	t.position = start
	t.dir = dir.normalized()
	t.span = span
	t.phase = phase
	add_child(t)


func npc(id: String, display: String, pos: Vector3, errand: StringName = &"", reward: StringName = &"") -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.display_name = display
	n.errand_flag = errand
	n.reward_seed = reward
	n.position = pos
	add_child(n)
	return n


## Distance from a point to the nearest open part of the gorge (negative inside).
static func gorge_distance(p: Vector2) -> float:
	var best := INF
	for seg in GORGE:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t) - float(seg[2]))
	for bowl in BOWLS:
		best = minf(best, p.distance_to(bowl[0] as Vector2) - float(bowl[1]))
	return best


## A rope bridge between two plateau-top points (over the gorge).
func rope_bridge(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var length := Vector2(b.x - a.x, b.z - a.z).length()
	var body := Kit.static_body(self, mid + Vector3.DOWN * 0.2)
	body.basis = Basis.looking_at(b - a, Vector3.UP)
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 0.4, length)
	Kit.add_shape(body, box)
	var n := int(length / 1.2)
	for i in n:
		var plank := RoundMesh.box(Vector3(4.0, 0.25, 0.9), 0.08)
		Kit.mesh_instance(body, plank, Kit.mat(&"wood_plank" if i % 2 else &"wood_warm"), Vector3(0.0, 0.0, -length * 0.5 + (i + 0.5) * length / n))
	for side: float in [-1.0, 1.0]:
		var rope := CylinderMesh.new()
		rope.top_radius = 0.05
		rope.bottom_radius = 0.05
		rope.height = length
		var r := Kit.mesh_instance(body, rope, Kit.mat(&"bark_mid"), Vector3(side * 2.0, 1.0, 0.0))
		r.rotation.x = PI * 0.5


# --- Ground, the plateau and the gorge --------------------------------------------------------

func _ground_and_plateau() -> void:
	var holes: Array[Rect2] = [Rect2(-24.0, 60.0, 14.0, 12.0), CHASM, Rect2(-116.0, 34.0, 16.0, 16.0)]
	ground(Rect2(-150.0, -160.0, 300.0, 320.0), holes, 0.0, 18.0, &"wood_warm", &"sand_light", 0.012)
	# The plateau: everything away from the gorge, built as merged runs of 8 m cells. Around the
	# Golem's ring it rises higher so nobody drops in past the gate.
	var cell := 8.0
	for zi in 40:
		var z := -160.0 + (zi + 0.5) * cell
		var run_start := -1
		var run_h := 0.0
		for xi in 38:
			var x := -150.0 + (xi + 0.5) * cell
			var p := Vector2(x, z)
			var solid := gorge_distance(p) > cell * 0.5 and not CHASM.grow(2.0).has_point(p)
			var h := PLATEAU + (10.0 if p.distance_to(Vector2(ARENA.x, ARENA.z)) < 40.0 else 0.0)
			if solid and run_start >= 0 and h != run_h:
				_plateau_run(run_start, xi, z, cell, run_h)
				run_start = -1
			if solid and run_start < 0:
				run_start = xi
				run_h = h
			elif not solid and run_start >= 0:
				_plateau_run(run_start, xi, z, cell, run_h)
				run_start = -1
		if run_start >= 0:
			_plateau_run(run_start, 38, z, cell, run_h)
	# Chasm: a pit with a ribbon of river far below.
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(CHASM.size.x, 4.0, CHASM.size.y)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(CHASM.get_center().x, -12.0, CHASM.get_center().y)
	add_child(pit)
	Kit.block(self, Vector3(CHASM.get_center().x, -16.0, CHASM.get_center().y), Vector3(CHASM.size.x, 2.0, CHASM.size.y), &"stone_dark", Layers.WORLD, &"")
	var river := PlaneMesh.new()
	river.size = Vector2(8.0, CHASM.size.y)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 1.5))
	Kit.mesh_instance(self, river, wm, Vector3(CHASM.get_center().x, -15.9, CHASM.get_center().y))
	# Outer walls, far buttes and balloons.
	for side in 4:
		var along := 300.0 if side < 2 else 320.0
		var n := int(along / 30.0)
		for i in n:
			var t := -along * 0.5 + (i + 0.5) * along / n
			var h := _rng.randf_range(26.0, 36.0)
			var c := Vector3(t, h, -168.0) if side == 0 else (Vector3(t, h, 168.0) if side == 1 else (Vector3(-158.0, h, t) if side == 2 else Vector3(158.0, h, t)))
			var size := Vector3(along / n + 2.0, h + 18.0, 16.0) if side < 2 else Vector3(16.0, h + 18.0, along / n + 2.0)
			Kit.block(self, c, size, ROCKS[(i + side) % ROCKS.size()], Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_mid")
	for i in 14:
		var a := float(i) / 14.0 * TAU + _rng.randf_range(-0.1, 0.1)
		var r := _rng.randf_range(230.0, 300.0)
		var top := Vector3(cos(a) * r, _rng.randf_range(40.0, 80.0), sin(a) * r)
		var rad := _rng.randf_range(14.0, 28.0)
		Kit.pillar(self, top, rad, top.y + 20.0, &"wood_warm", &"sand_light", 0)
		for b in 3:
			Kit.pillar(self, Vector3(top.x, top.y * (0.3 + b * 0.22), top.z), rad + 0.6, 2.2, STRIPES[(i + b) % STRIPES.size()], &"", 0)
	var bcols: Array[Array] = [[&"roof_red", &"gold"], [&"candy_pink", &"mush_spot"], [&"slime_blue", &"gold"], [&"mush_purple", &"candy_pink"]]
	for i in 5:
		var holder := Node3D.new()
		holder.position = Vector3(_rng.randf_range(-120.0, 120.0), _rng.randf_range(40.0, 60.0), _rng.randf_range(-130.0, 130.0))
		add_child(holder)
		var cols: Array[StringName] = []
		cols.assign(bcols[i % bcols.size()])
		Whimsy.balloon(holder, Vector3.ZERO, cols)
		Kit.mesh_instance(holder, RoundMesh.box(Vector3(1.6, 1.0, 1.6), 0.2), Kit.mat(&"wood_plank"), Vector3(0.0, -0.5, 0.0))
	birds(Vector3.ZERO, 90.0, 34.0, 7)
	add_capture_point("canyon", Vector3(30.0, 60.0, 150.0), Vector3(-10.0, 0.0, 20.0))


func _plateau_run(x0: int, x1: int, z: float, cell: float, h: float) -> void:
	var xa := -150.0 + x0 * cell
	var xb := -150.0 + x1 * cell
	var k := absi(int(z * 7.0 + xa))
	# Sharp-edged boxes (like the ground) so neighbouring strips read as one plateau top.
	var size := Vector3(xb - xa, h + 2.0, cell)
	var body := Kit.static_body(self, Vector3((xa + xb) * 0.5, h - size.y * 0.5, z))
	body.name = "Plateau"
	var shape := BoxShape3D.new()
	shape.size = size
	Kit.add_shape(body, shape)
	var bm := BoxMesh.new()
	bm.size = size
	Kit.mesh_instance(body, bm, Kit.mat(ROCKS[k % ROCKS.size()], 0.0, &"sand_light"))
	_add_grass_area(Vector3((xa + xb) * 0.5, h, z), Vector2(xb - xa, cell), int((xb - xa) * cell * 0.01))


# --- The south entry -------------------------------------------------------------------------

func _entry() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w3_entrance", Vector3(0.0, 0.0, 142.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 152.0)
	add_child(exit)
	sign_post(Vector3(6.0, 0.0, 138.0), "Sunscorch Canyon. Follow the gorge north.\nThree Star Shards open the Golem Gate.")
	for spec: Array in [[-8.0, 128.0, 6.0], [8.0, 116.0, 7.5], [-7.0, 100.0, 5.0], [7.0, 92.0, 6.5]]:
		Whimsy.cactus(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as float)
	critter(Pricklepot, Vector3(3.0, 0.0, 110.0))
	gloplets(Vector3(-2.0, 0.0, 120.0), 7.0, [Vector3.ZERO, Vector3(3.0, 0.0, 2.0)], [], preload("res://data/enemies/ember_gloplet.tres"))
	prop(&"statue_ring", Vector3(0.0, 0.0, 124.0), 0.0, 2.8, false)


# --- Oasis Camp bowl -------------------------------------------------------------------------

func _camp() -> void:
	region(Vector3.ZERO)
	var c := Vector3(0.0, 0.0, 70.0)
	checkpoint(&"w3_cp_camp", c + Vector3(6.0, 0.0, 22.0))
	water(c + Vector3(-17.0, -0.6, -4.0), Vector2(14.0, 12.0), 5.0)
	Kit.block(self, c + Vector3(-17.0, -5.6, -4.0), Vector3(14.0, 12.4, 12.0), &"stone_dark", Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_mid")
	prop(&"statue_head", c + Vector3(-20.0, -5.6, -7.0), 0.6, 1.4, false)
	seed_at(&"w3_seed_pond", c + Vector3(-15.0, -5.6, -2.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU
		prop([&"palm", &"palm_tall", &"palm_bend", &"palm_detailed"][i % 4] as StringName, c + Vector3(-17.0 + cos(a) * 10.0, 0.0, -4.0 + sin(a) * 9.0), _rng.randf() * TAU, 1.2)
	for i in 2:
		var duck := Duck.new()
		duck.position = c + Vector3(-19.0 + i * 4.0, -0.6, -4.0)
		duck.radius = 2.5
		add_child(duck)
	prop(&"tent_big", c + Vector3(14.0, 0.0, -8.0), -0.6, 1.0)
	prop(&"tent_small", c + Vector3(20.0, 0.0, 2.0), -1.2, 1.2)
	prop(&"campfire_stones", c + Vector3(10.0, 0.0, 4.0), 0.0, 1.2, false)
	prop(&"campfire", c + Vector3(10.0, 0.0, 4.0), 0.0, 1.0, false)
	var fire := OmniLight3D.new()
	fire.light_color = Palette.color(&"sunset_orange")
	fire.light_energy = 1.4
	fire.omni_range = 7.0
	fire.position = c + Vector3(10.0, 1.2, 4.0)
	add_child(fire)
	Whimsy.stall(self, c + Vector3(4.0, 0.0, -12.0), PI, &"sunset_orange")
	Whimsy.stall(self, c + Vector3(-4.0, 0.0, 14.0), PI * 0.5, &"candy_pink")
	for spec: Array in [[14.0, -14.0, &"barrel"], [15.5, -15.0, &"barrel"], [7.0, -16.0, &"crate"], [22.0, -4.0, &"sack"], [-4.0, 4.0, &"q_cart"], [18.0, 10.0, &"q_farm_crate"]]:
		prop(spec[2] as StringName, c + Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.0)
	npc("sandy", "Sandy", c + Vector3(8.0, 0.0, 8.0))
	# Lookout.
	ledge(c + Vector3(18.0, 1.5, 12.0), Vector3(3.0, 1.5, 3.0), &"wood_plank")
	ledge(c + Vector3(21.0, 3.0, 15.0), Vector3(3.0, 1.0, 3.0), &"wood_plank")
	ledge(c + Vector3(21.5, 5.5, 20.0), Vector3(5.0, 0.5, 5.0), &"wood_plank")
	seed_at(&"w3_seed_lookout", c + Vector3(21.5, 5.5, 20.0))
	# Spire and Springcap.
	Kit.pillar(self, c + Vector3(16.0, 10.0, -16.0), 2.6, 10.0, &"wood_warm", &"sand_light")
	bouncer(c + Vector3(12.0, 0.0, -12.0), Springcap.Look.MUSHROOM, 7.0, 13.0)
	seed_at(&"w3_seed_spire", c + Vector3(16.0, 10.0, -16.0))
	# Mesa Stair up to the high plateau (west side of the bowl), and a balloon lift on the east.
	mesa(c + Vector3(-14.0, 3.0, 18.0), Vector2(9.0, 9.0))
	mesa(c + Vector3(-22.0, 6.0, 8.0), Vector2(8.0, 8.0))
	mesa(c + Vector3(-25.0, 9.0, 20.0), Vector2(7.0, 8.0))
	critter(Hoppy, c + Vector3(-14.0, 3.5, 18.0))
	sign_post(c + Vector3(-8.0, 0.0, 22.0), "Climb the mesa stair to the high plateau.", PI * 0.25)
	balloon_lift(c + Vector3(26.0, 0.5, -16.0), Vector3(0.0, 11.5, 0.0), 8.0, [&"candy_pink", &"gold"])
	heart_bush(c + Vector3(-6.0, 0.0, -20.0))
	animals(Bunny, c, 22.0, 5)
	butterflies(c + Vector3(-17.0, 0.0, -4.0), 10.0, 8)
	sparkles(c + Vector3(-17.0, 1.5, -4.0), Vector3(20.0, 4.0, 20.0), 30)
	add_capture_point("camp", c + Vector3(24.0, 18.0, 36.0), c + Vector3(-6.0, 2.0, -4.0))


# --- The high plateau: mesa summit and Glider's Perch --------------------------------------------

func _high_plateau() -> void:
	region(Vector3.ZERO)
	checkpoint(&"w3_cp_mesa", Vector3(-38.0, PLATEAU, 92.0))
	mesa(Vector3(-56.0, 15.0, 98.0), Vector2(14.0, 14.0), &"wood_warm", PLATEAU)
	mesa(Vector3(-70.0, 18.0, 112.0), Vector2(12.0, 12.0), &"wood_warm", PLATEAU)
	balloon_lift(Vector3(-58.0, 18.5, 120.0), Vector3(0.0, 0.0, 8.0), 5.0, [&"slime_blue", &"mush_spot"])
	mesa(Vector3(-50.0, 21.0, 136.0), Vector2(11.0, 11.0), &"wood_warm", PLATEAU)
	Kit.pillar(self, Vector3(-38.0, 24.0, 136.0), 5.5, 3.0, &"sunset_orange", &"sand_light")
	stone(Vector3(-38.0, 25.5, 136.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w3_shard_mesa", Vector3(-38.0, 25.5, 136.0))
	prop(&"statue_head", Vector3(-46.0, 21.0, 140.0), -0.6, 1.3)
	critter(Hoppy, Vector3(-56.0, 15.5, 98.0))
	critter(Hoppy, Vector3(-70.0, 18.5, 112.0))
	critter(Batling, Vector3(-60.0, 24.0, 128.0))
	# Glider's Perch: a lone pillar far off the summit (Glide).
	Kit.pillar(self, Vector3(-38.0, 16.0, 108.0), 3.0, 4.0, &"roof_red", &"sand_light")
	seed_at(&"w3_seed_perch", Vector3(-38.0, 16.0, 108.0))
	sign_post(Vector3(-36.0, 24.0, 131.0), "That far pillar... if only you could float.", PI)
	# Skye the balloonist and Professor Quill's lost book, up here in the wind.
	npc("skye", "Skye", Vector3(-30.0, PLATEAU, 100.0))
	var book := ErrandItem.new()
	book.flag = &"w3_found_book"
	book.label_text = "Quill's notebook"
	book.color_name = &"roof_teal"
	book.position = Vector3(-67.0, 18.0, 115.0)
	add_child(book)
	for i in 10:
		var p := Vector3(_rng.randf_range(-110.0, -26.0), PLATEAU, _rng.randf_range(80.0, 150.0))
		if gorge_distance(Vector2(p.x, p.z)) < 6.0:
			continue
		Whimsy.cactus(self, p, _rng.randf_range(4.0, 7.0))
	# Rope bridges across the gorge up here, making the plateau one long high trail.
	rope_bridge(Vector3(-15.0, PLATEAU, 112.0), Vector3(15.0, PLATEAU, 112.0))
	rope_bridge(Vector3(-36.0, PLATEAU, 22.0), Vector3(-36.0, PLATEAU, 58.0))
	rope_bridge(Vector3(-80.0, PLATEAU, -10.0), Vector3(-80.0, PLATEAU, -54.0))
	rope_bridge(Vector3(20.0, PLATEAU, -68.0), Vector3(20.0, PLATEAU, -108.0))
	rope_bridge(Vector3(86.0, PLATEAU, 0.0), Vector3(116.0, PLATEAU, 0.0))
	add_capture_point("plateau", Vector3(-10.0, 36.0, 150.0), Vector3(-50.0, 16.0, 115.0))


# --- Ruins bowl ------------------------------------------------------------------------------

func _ruins() -> void:
	var c := Vector3(-55.0, 0.0, -30.0)
	region(c, 90.0)
	checkpoint(&"w3_cp_ruins", Vector3(0.0, 0.0, 18.0))
	plat(Vector3(0.0, 1.0, 0.0), Vector2(30.0, 24.0), &"roof_teal", 0)
	for spec: Array in [[-8.0, 4.0, 8.0, 1.2], [9.0, -2.0, 1.2, 8.0], [-10.0, -6.0, 1.2, 8.0]]:
		ledge(Vector3(spec[0] as float, 4.0, spec[1] as float), Vector3(spec[2] as float, 3.0, spec[3] as float), &"roof_teal")
	for x: float in [-6.0, 6.0]:
		for z: float in [9.0, 3.0, -3.0, -9.0]:
			prop(&"column_broken", Vector3(x, 1.0, z), _rng.randf() * TAU, _rng.randf_range(1.1, 1.5))
	for spec: Array in [[-4.0, 4.0], [5.0, -4.0], [0.0, -8.0]]:
		critter(Armorling, Vector3(spec[0] as float, 1.5, spec[1] as float))
	chest(Vector3(11.0, 1.0, 9.0), PI * 0.5, &"w3_seed_chest")
	var mimic := critter(Mimic, Vector3(-12.0, 1.0, -9.0))
	mimic.rotation.y = Y(-PI * 0.5)
	critter(Batling, Vector3(0.0, 7.0, 0.0))
	# Temple on the far side: a cracked wall hides the shard; lanterns open the vault.
	ramp(Vector3(0.0, 1.0, -12.0), 4.0, 3.0, 8.0, &"roof_teal")
	plat(Vector3(0.0, 4.0, -20.0), Vector2(22.0, 10.0), &"roof_teal", 0)
	alcove(Vector3(-3.0, 4.0, -21.0), 0.0, &"sunset_orange")
	stone(Vector3(-3.0, 5.0, -21.0), 1.4, 1.0, &"stone_light", &"gold")
	shard_at(&"w3_shard_ruins", Vector3(-3.0, 5.0, -21.0))
	var vault_door := alcove(Vector3(6.0, 4.0, -21.0), 0.0, &"roof_teal", &"gate") as VineGate
	seed_at(&"w3_seed_lanterns", Vector3(6.0, 4.0, -21.0))
	var lanterns := SwitchGroup.new()
	add_child(lanterns)
	for x: float in [3.0, 9.5]:
		var l := CrystalSwitch.new()
		l.look = CrystalSwitch.Look.LANTERN
		l.needs = &"fireball"
		l.position = P(Vector3(x, 4.0, -16.0))
		add_child(l)
		lanterns.add(l)
	lanterns.solved.connect(func() -> void:
		vault_door.set_closed(false)
		if hud != null:
			hud.show_banner("The vines draw back!", 2.0))
	sign_post(Vector3(-8.0, 4.0, -16.0), "Cracked walls crumble: three slashes or one PLUNGE.\nTwo lanterns stand cold and dark...")
	npc("quill", "Professor Quill", Vector3(10.0, 1.0, 2.0), &"w3_found_book", &"w3_seed_errand")
	for i in 5:
		Whimsy.crystal(self, P(Vector3(_rng.randf_range(-13.0, 13.0), 1.0, _rng.randf_range(-10.0, 10.0))), [&"crystal_violet", &"portal_teal", &"candy_pink"][i % 3] as StringName, _rng.randf_range(0.5, 0.9))
	sparkles(Vector3(0.0, 4.0, -6.0), Vector3(30.0, 8.0, 30.0), 30)
	add_capture_point("ruins", c + Vector3(30.0, 20.0, 18.0), c)


# --- Quicksand bowl, the chasm and the Sun Shrine ----------------------------------------------

func _flats() -> void:
	region(Vector3.ZERO)
	var c := Vector3(95.0, 0.0, -50.0)
	checkpoint(&"w3_cp_flats", c + Vector3(-18.0, 0.0, -10.0))
	sign_post(c + Vector3(-14.0, 0.0, -14.0), "Light all three crystals quickly and\na bridge spans the chasm to the east!")
	for spec: Array in [[-8.0, 4.0, 5.5], [6.0, -8.0, 5.0], [-2.0, 12.0, 5.0], [10.0, 8.0, 4.5], [-12.0, -8.0, 4.0]]:
		var q := Quicksand.new()
		q.radius = spec[2] as float
		q.position = c + Vector3(spec[0] as float, 0.0, spec[1] as float)
		add_child(q)
	for spec: Array in [[0.0, 0.0], [-6.0, 10.0], [8.0, 2.0], [-4.0, -6.0], [14.0, -2.0]]:
		stone(c + Vector3(spec[0] as float, 1.2, spec[1] as float), 2.5, 1.2, &"wood_warm", &"sand_light")
	var group := SwitchGroup.new()
	add_child(group)
	for spec: Array in [[-16.0, 8.0], [4.0, -18.0], [18.0, 14.0]]:
		stone(c + Vector3(spec[0] as float, 1.6, spec[1] as float), 2.4, 1.6, &"mush_purple", &"crystal_violet")
		var sw := CrystalSwitch.new()
		sw.hold = 14.0
		sw.position = c + Vector3(spec[0] as float, 1.6, spec[1] as float)
		add_child(sw)
		group.add(sw)
	var bridge: Array[GhostPlatform] = []
	for i in 3:
		var g := GhostPlatform.new()
		g.size = Vector3(3.4, 0.8, 6.0)
		g.color_name = &"crystal_violet"
		g.position = Vector3(122.5 + i * 3.4, 0.0, -50.0)
		add_child(g)
		bridge.append(g)
	group.solved.connect(func() -> void:
		for i in bridge.size():
			var step := bridge[i]
			get_tree().create_timer(0.12 * i).timeout.connect(func() -> void:
				if is_instance_valid(step):
					step.set_solid(true))
		if hud != null:
			hud.show_banner("A crystal bridge spans the chasm!", 2.2))
	Kit.block(self, Vector3(140.0, 0.0, -50.0), Vector3(18.0, 18.0, 22.0), &"wood_warm", Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_light")
	stone(Vector3(142.0, 1.5, -50.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w3_shard_flats", Vector3(142.0, 1.5, -50.0))
	critter(Armorling, Vector3(136.0, 0.5, -46.0))
	prop(&"rock_large_d", Vector3(144.0, 0.0, -42.0), 0.4, 1.2)
	seed_at(&"w3_seed_island", Vector3(146.0, 0.0, -56.0))
	heart_at(Vector3(136.0, 0.0, -58.0))
	gloplets(c + Vector3(6.0, 0.0, 8.0), 10.0, [Vector3.ZERO, Vector3(-4.0, 0.0, 3.0), Vector3(3.0, 0.0, -5.0)], [], preload("res://data/enemies/ember_gloplet.tres"))
	for spec: Array in [[-10.0, 14.0], [12.0, -12.0], [16.0, 6.0]]:
		critter(Pricklepot, c + Vector3(spec[0] as float, 0.0, spec[1] as float))
	# The Sun Shrine: shove the crate onto the plate to hold its door open.
	var shrine: Array = secret_cave(c + Vector3(-6.0, 0.0, -21.0), 0.0, Vector3(12.0, 8.0, 10.0), &"sunset_orange", &"gate")
	stone(Vector3(-3.0, 1.2, -1.0), 1.6, 1.2, &"stone_light", &"sand_light")
	ledge(Vector3(0.0, 3.2, -2.5), Vector3(3.0, 0.5, 2.4), &"wood_plank")
	ledge(Vector3(3.5, 5.4, 0.0), Vector3(2.4, 0.5, 3.0), &"wood_plank")
	seed_at(&"w3_seed_shrine", Vector3(3.5, 5.4, 0.0))
	_frame = shrine[0]
	var shrine_door := shrine[1] as VineGate
	var crate := PushBlock.new()
	crate.position = c + Vector3(-18.0, 0.0, -2.0)
	add_child(crate)
	var plate := PressurePlate.new()
	plate.position = c + Vector3(-18.0, 0.0, -11.0)
	add_child(plate)
	plate.changed.connect(func(on: bool) -> void: shrine_door.set_closed(not on))
	sign_post(c + Vector3(-22.0, 0.0, -6.0), "Sun Shrine: weigh down the plate\nand the door stays open.", PI * 0.5)
	for i in 4:
		tumbleweed(c + Vector3(-24.0, 0.0, -12.0 + i * 8.0), Vector3(1.0, 0.0, 0.2), 44.0, i * 3.1)
	add_capture_point("flats", c + Vector3(-30.0, 22.0, 30.0), c + Vector3(15.0, 0.0, -5.0))


# --- Side canyons: second oasis, cactus garden, Dusty's mine, bramble cave -------------------------

func _side_canyons() -> void:
	region(Vector3.ZERO)
	# Second oasis (west).
	water(Vector3(-108.0, -0.6, 42.0), Vector2(16.0, 16.0), 5.0)
	Kit.block(self, Vector3(-108.0, -5.6, 42.0), Vector3(16.0, 12.4, 16.0), &"stone_dark", Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_mid")
	seed_at(&"w3_seed_oasis2", Vector3(-106.0, -5.6, 44.0))
	for i in 6:
		var a := float(i) / 6.0 * TAU
		prop([&"palm", &"palm_tall", &"palm_bend"][i % 3] as StringName, Vector3(-108.0 + cos(a) * 11.5, 0.0, 42.0 + sin(a) * 11.5), a, 1.2)
	# Cactus garden (south-west of the narrows), with a chest and the bramble cave at the end.
	var cg := Vector3(-38.0, 0.0, -128.0)
	for i in 10:
		Whimsy.cactus(self, cg + Vector3(_rng.randf_range(-12.0, 12.0), 0.0, _rng.randf_range(-12.0, 12.0)), _rng.randf_range(3.5, 8.0))
	chest(cg + Vector3(8.0, 0.0, 6.0), PI * 0.8, &"w3_seed_cactus")
	gloplets(cg + Vector3(0.0, 0.0, 4.0), 8.0, [Vector3.ZERO, Vector3(3.0, 0.0, -2.0)], [], preload("res://data/enemies/ember_gloplet.tres"))
	var bramble: Array = secret_cave(cg + Vector3(-4.0, 0.0, -6.0), deg_to_rad(28.0), Vector3(14.0, 10.0, 12.0), &"stone_dark", &"bramble")
	ledge(Vector3(-4.0, 1.5, 2.0), Vector3(3.0, 1.5, 3.0), &"wood_warm")
	ledge(Vector3(-5.0, 3.8, -2.0), Vector3(3.0, 0.5, 2.4), &"wood_plank")
	crumble(Vector3(-1.0, 5.8, -4.0), Vector3(3.0, 0.6, 3.0), CrumblePlatform.Look.ROCK)
	ledge(Vector3(3.5, 7.6, -3.0), Vector3(3.0, 0.5, 3.0), &"wood_plank")
	seed_at(&"w3_seed_bramble", Vector3(3.5, 7.6, -3.0))
	_frame = bramble[0]
	# Dusty's mine (east of the camp): a cracked timber door and a climb up the shafts inside.
	npc("dusty", "Dusty", Vector3(32.0, 0.0, 92.0))
	var mine: Array = secret_cave(Vector3(44.0, 0.0, 100.0), deg_to_rad(-122.0), Vector3(16.0, 10.0, 14.0), &"bark_mid", &"break")
	ledge(Vector3(-5.0, 1.5, 3.0), Vector3(3.0, 1.5, 3.0), &"wood_warm")
	mover(Vector3(-1.0, 1.8, -1.0), Vector3(3.0, 0.6, 3.0), Vector3(0.0, 3.5, 0.0), 4.0, &"wood_plank")
	ledge(Vector3(3.5, 5.8, -3.5), Vector3(4.0, 0.5, 2.4), &"wood_plank")
	ledge(Vector3(5.0, 7.8, 1.0), Vector3(2.4, 0.5, 3.0), &"wood_plank")
	seed_at(&"w3_seed_mesa_cave", Vector3(5.0, 7.8, 1.0))
	prop(&"q_cart", Vector3(-3.0, 0.3, -4.0), 0.5, 1.0)
	_frame = mine[0]


# --- Golem Gate and the Rumble Golem's ring ------------------------------------------------------

func _golem_gate() -> void:
	region(Vector3.ZERO)
	checkpoint(&"w3_cp_gate", Vector3(64.0, 0.0, 72.0))
	sign_post(Vector3(56.0, 0.0, 74.0), "The Golem Gate opens for 3 Star Shards.\nSlam! Its fists get stuck: PLUNGE on the gem!")
	# Ledges up the gorge wall to a seed.
	var cols: Array[StringName] = [&"sunset_orange", &"candy_pink", &"mush_purple"]
	for i in 3:
		ledge(Vector3(76.0 + i * 4.0, 2.5 + i * 2.5, 52.0 - i * 6.0), Vector3(4.0, 1.0, 4.0), cols[i])
	seed_at(&"w3_seed_corridor", Vector3(84.0, 7.5, 40.0))
	heart_bush(Vector3(66.0, 0.0, 64.0))
	make_gate(Vector3(60.0, 0.0, 92.0), 12.0)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.3
		Whimsy.cactus(self, ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R - 1.2), 3.5, false)
	add_capture_point("gate", Vector3(60.0, 14.0, 60.0), Vector3(60.0, 2.0, 92.0))
	add_capture_point("golem", ARENA + Vector3(0.0, 16.0, -12.0), ARENA + Vector3(0.0, 0.0, 6.0))


# --- Life all along the gorge --------------------------------------------------------------------

func _gorge_life() -> void:
	region(Vector3.ZERO)
	var props: Array[StringName] = [&"rock_tall_c", &"rock_tall_e", &"stone_tall_c", &"rock_large_d", &"cactus_tall", &"palm_bend", &"q_barrel", &"q_crate"]
	for seg in GORGE:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var hw := float(seg[2])
		var n := int(a.distance_to(b) / 9.0)
		var side := (b - a).normalized().orthogonal()
		for i in n:
			var t := (i + 0.5) / n
			var along := a.lerp(b, t)
			var off := side * (hw - 2.5) * (1.0 if i % 2 == 0 else -1.0)
			var p := Vector3(along.x + off.x, 0.0, along.y + off.y)
			if _near_feature(p):
				continue
			if i % 3 == 0:
				Whimsy.cactus(self, p, _rng.randf_range(3.5, 7.0))
			else:
				prop(props[(i + int(a.x)) % props.size()], p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.4))
			# Wooden scaffolds against the walls: little climbs dotted along the gorge.
			if i % 5 == 2 and hw >= 10.0:
				var sp := Vector3(along.x - side.x * (hw - 2.0), 0.0, along.y - side.y * (hw - 2.0))
				if not _near_feature(sp):
					ledge(sp + Vector3(0.0, 2.2, 0.0), Vector3(3.0, 0.5, 3.0), &"wood_plank")
					ledge(sp + Vector3(0.0, 4.6, 0.0) + Vector3(side.x, 0.0, side.y) * 1.5, Vector3(3.0, 0.5, 3.0), &"wood_plank")
		if hw >= 10.0:
			tumbleweed(Vector3(a.x, 0.0, a.y), Vector3(b.x - a.x, 0.0, b.y - a.y), a.distance_to(b), float(n))
	for spec: Array in [[-40.0, 40.0], [-30.0, -60.0], [70.0, -80.0], [100.0, -10.0], [80.0, 50.0]]:
		critter(Hoppy, Vector3(spec[0] as float, 0.5, spec[1] as float))
	for spec: Array in [[-50.0, 10.0], [20.0, -85.0], [98.0, 0.0]]:
		critter(Pricklepot, Vector3(spec[0] as float, 0.0, spec[1] as float))
	# The plateau top is busy too: cacti, rock stacks, little mesas and palms.
	var top_props: Array[StringName] = [&"rock_tall_d", &"stone_tall_b", &"rock_large_d", &"cactus_short", &"q_rock_1", &"q_rock_2"]
	for i in 110:
		var q := Vector2(_rng.randf_range(-145.0, 145.0), _rng.randf_range(-155.0, 155.0))
		if gorge_distance(q) < 7.0 or CHASM.grow(6.0).has_point(q) or q.distance_to(Vector2(ARENA.x, ARENA.z)) < 40.0:
			continue
		var p := Vector3(q.x, PLATEAU, q.y)
		match i % 4:
			0:
				Whimsy.cactus(self, p, _rng.randf_range(4.0, 8.0))
			1:
				mesa(p + Vector3(0.0, _rng.randf_range(2.0, 4.0), 0.0), Vector2(_rng.randf_range(5.0, 8.0), _rng.randf_range(5.0, 8.0)), &"wood_warm", PLATEAU, false)
			_:
				prop(top_props[i % top_props.size()], p, _rng.randf() * TAU, _rng.randf_range(1.0, 1.8))
	animals(Bunny, Vector3(-30.0, 0.0, 45.0), 12.0, 3)
	animals(Bunny, Vector3(20.0, 0.0, -85.0), 12.0, 3)


## True near set pieces, so filler doesn't block a path or a puzzle.
func _near_feature(p: Vector3) -> bool:
	for c: Vector3 in [Vector3(0.0, 0.0, 70.0), Vector3(-55.0, 0.0, -30.0), Vector3(95.0, 0.0, -50.0), Vector3(60.0, 0.0, 92.0), Vector3(44.0, 0.0, 100.0), Vector3(-38.0, 0.0, -128.0), Vector3(-108.0, 0.0, 42.0), Vector3(80.0, 0.0, 46.0), Vector3(0.0, 0.0, 146.0)]:
		if Vector2(p.x - c.x, p.z - c.z).length() < (24.0 if c.z == 70.0 else 14.0):
			return true
	return false
