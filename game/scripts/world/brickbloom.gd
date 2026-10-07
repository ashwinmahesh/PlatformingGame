class_name Brickbloom
extends OpenWorld
## World 8, Brickbloom Heights (Build 8; Ashwin: "3 new whimsical levels (dont think realistic)...
## One of them is Mario themed... densely packed small open-worlds with a lot of verticality").
## Our own homage to the classic side-scrolling platformers: a toy-box kingdom of chunky candy
## blocks stacked round a tall castle in a moat, with warp pipes between the tiers, bricks to bonk
## from below, seeds in hoops, springy pads, cannons on the battlements and a flagpole fort in the
## sky. The shape is stacked plateaus round the castle, every tier joined to the next:
##   South   Welcome Meadow    - the pipe plaza, a bonk-brick row, balloon hooks, the drawbridge
##   Centre  Castle Brickbloom - bailey (3 m), the rampart ring (12 m, the upper world's hub), the
##                               keep's spiral to its roof (21 m) and the Star Turret (34 m)
##   East    Toybox Terraces   - five stacked blocks climbing 3 m at a time to the Wobbly Tower
##   North   Cannon Ridge      - cannon lanes at 12 m; the Sky Rows climb from it to the Flagpole Fort
##   West    Weigh-House Green - the Great Brass Balance and Mortimer's brickworks
##   Corners Counting Court (SW), Bonk Lane and the Sun-and-Moon Steps (SE), Brickbeard's Knoll (NW)
## Six stars: the Counting Blocks (sequence puzzle), the Great Brass Balance (weight scale), Mortimer's
## golden trowel (errand), the Bonus Room behind the pipe at the bottom of the moat (hidden), the
## Flagpole Fort at the end of the Sky Rows (platforming) and Old Brickbeard's riddle. Three build a
## stair of blocks up the Star Turret to the Grand Star; clearing it with all six teaches Star Rush.

const WORLD := &"world_08"
const BAILEY := 3.0
const RAMPART := 12.0
const KEEP_TOP := 21.0
const STAR_TOP := 34.0
const ISLAND := 24.0
const MOAT := 36.0
const WATER_Y := -1.0
const MOAT_BED := -10.0
const RIDGE := Vector3(0.0, 12.0, -50.0)
const BALANCE := Vector3(-88.0, 0.0, -4.0)
const BALANCE_TRAVEL := 17.0
const COURT := Vector3(-56.0, 0.0, 84.0)
const COURT_TOP := 18.0
const FORT := Vector3(24.0, 22.0, -126.0)
const BONUS := Vector3(60.0, -50.0, 96.0)
const SUNMOON := Vector3(100.0, 0.0, 90.0)
const TOWER_TOP := Vector3(100.5, 24.0, -43.0)
const MOAT_PIPE := Vector3(-30.0, MOAT_BED, -30.0)
const KK := "res://assets/models/kk_platformer/"
const TOY: Array[StringName] = [&"roof_red", &"thatch", &"roof_blue", &"slime_green", &"mush_purple", &"sunset_orange", &"candy_pink"]

var counting: SequenceBlocks
var balance: BalanceLift
var flips: FlipBlocks
var pipes: Dictionary[StringName, WarpPipe] = {}
var _batch: ModuleBatch
var stair: Array[GhostPlatform] = []


func configure() -> void:
	world_id = WORLD
	platform_colour = &"red"
	model_tint = Color(1.05, 1.0, 0.97)
	# A bright toy-box morning: deep cyan-blue sky, mint horizon, big fluffy clouds.
	sky_top = Color(0.1, 0.5, 1.0)
	sky_horizon = Color(0.74, 0.96, 0.98)
	sky_bottom = Color(0.88, 0.98, 1.0)
	cloud_cover = 0.56
	cloud_shade = Color(0.84, 0.88, 1.0)
	sun_color = Color(1.0, 0.95, 0.84)
	sun_energy = 1.15
	sun_angles = Vector2(-52.0, -30.0)
	fog_color = Color(0.84, 0.95, 1.0)
	fog_begin = 120.0
	fog_end = 380.0
	saturation = 1.12
	tree_kinds = [&"lime", &"gold", &"blossom", &"lime", &"green"]
	tops = {&"roof_red": &"grass_mid", &"thatch": &"grass_mid", &"roof_blue": &"grass_mid", &"mush_purple": &"grass_mid", &"slime_green": &"grass_light", &"candy_pink": &"grass_mid", &"sunset_orange": &"grass_mid", &"roof_teal": &"grass_mid", &"stone_light": &"stone_light", &"bark_mid": &"grass_mid"}
	grass_density = 0.035


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w8_entrance"
	music = &"world_08"
	floor_y = -14.0
	kill_y = -72.0
	_rng.seed = 808
	_batch = ModuleBatch.new()
	region(Vector3.ZERO)
	regions = {"meadow": Vector3(0.0, 0.0, 80.0), "castle": Vector3.ZERO, "terraces": Vector3(80.0, 0.0, 10.0), "ridge": Vector3(0.0, 0.0, -50.0), "sky_rows": Vector3(10.0, 0.0, -105.0),
		"green": Vector3(-80.0, 0.0, 0.0), "brickworks": Vector3(-92.0, 0.0, 40.0), "court": COURT, "knoll": Vector3(-84.0, 0.0, -84.0), "lane": Vector3(80.0, 0.0, 80.0), "bonus": BONUS}
	_ground_and_moat()
	_border()
	_meadow()
	_castle()
	_keep()
	_terraces()
	_ridge()
	_sky_rows()
	_north_fields()
	_green()
	_brickworks()
	_counting_court()
	_bonk_lane()
	_sun_moon_steps()
	_bonus_room()
	_pipes()
	_hooks()
	_critters()
	_batch.build(self)
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life()


## With three stars a stair of blocks pops out round the Star Turret, one block at a time.
func _on_shards_complete() -> void:
	for i in stair.size():
		var step := stair[i]
		get_tree().create_timer(0.2 * i).timeout.connect(func() -> void:
			if is_instance_valid(step):
				step.set_solid(true)
				AudioDirector.play(&"ui_blip", -6.0, 1.0 + i * 0.08))
	if hud != null:
		hud.show_banner("A stair of blocks climbs the Star Turret!", 2.4)


# --- Helpers ----------------------------------------------------------------------------------

func _layers() -> int:
	return Layers.WORLD | Layers.CAMERA_BLOCKER


func _kk(piece: String, col: String) -> String:
	if col == "neutral":
		return "%sneutral/%s.gltf" % [KK, piece]
	return "%s%s/%s_%s.gltf" % [KK, col, piece, col]


## A brick (see BonkBrick) whose top centre is `top`.
func _brick(top: Vector3, kind: BonkBrick.Kind, color: StringName = &"roof_red") -> BonkBrick:
	var b := BonkBrick.new()
	b.kind = kind
	b.color_name = color
	b.position = top
	add_child(b)
	return b


## A brick hiding a Glimmer Seed.
func _seed_brick(top: Vector3, id: StringName) -> BonkBrick:
	var b := _brick(top, BonkBrick.Kind.SEED, &"sunset_orange")
	b.hold(Pickup.spawn_seed(self, top, id))
	return b


## A floating row of bricks you can stand on.
func _brick_row(top: Vector3, size: Vector3, color: StringName = &"roof_red") -> StaticBody3D:
	var b := Kit.block(self, top, size, color, _layers(), &"sunset_orange")
	Kit.mesh_instance(b, BonkBrick.mortar_mesh(size, 0.6, false), Kit.mat(&"cloth_cream"), Vector3(0.0, size.y * 0.5, 0.0))
	return b


## A warp pipe standing on `base`.
func _pipe(base: Vector3, h: float, col: String, label: String = "", enterable: bool = true, auto: bool = false) -> WarpPipe:
	var p := WarpPipe.new()
	p.height = h
	p.colour = col
	p.label_text = label
	p.enterable = enterable
	p.auto = auto
	p.position = base + Vector3.UP * h
	add_child(p)
	return p


## A stack of big dice (decoration you can stand on).
func _toy_stack(base: Vector3, n: int, s: float = 2.2) -> void:
	for i in n:
		var top := base + Vector3(_rng.randf_range(-0.3, 0.3), s * (i + 1), _rng.randf_range(-0.3, 0.3))
		var b := Kit.block(self, top, Vector3(s, s, s), TOY[_rng.randi() % TOY.size()], Layers.WORLD, &"")
		b.rotation.y = _rng.randf_range(-0.5, 0.5)
		Kit.mesh_instance(b, PipBlock.pip_mesh(Vector3(s, s, s), _rng.randi_range(1, 6), s * 0.08), Kit.mat(&"cloth_cream"), Vector3(0.0, s * 0.5, 0.0))


## A giant beach ball (solid).
func _ball(at: Vector3, col: String, r: float) -> void:
	var body := Kit.static_body(self, at + Vector3.UP * r, Layers.WORLD)
	var sh := SphereShape3D.new()
	sh.radius = r
	Kit.add_shape(body, sh)
	var m := Models.instance(_kk("ball", col))
	m.scale = Vector3.ONE * r
	body.add_child(m)


func _flag(base: Vector3, col: String, s: float = 2.0, yaw: float = 0.0) -> void:
	Models.spawn(self, _kk("flag_C", col), base, yaw, s)


## A hoop standing at `base` facing along `yaw`; returns the middle of its ring.
func _hoop(base: Vector3, yaw: float, col: String, s: float = 1.4) -> Vector3:
	Models.spawn(self, _kk("hoop", col), base, yaw, s)
	return base + Vector3.UP * 3.0 * s


func _cones(a: Vector3, b: Vector3, n: int, col: String) -> void:
	for i in n:
		_batch.place(_kk("cone", col), a.lerp(b, float(i) / maxf(n - 1, 1)), 0.0, Vector3.ONE * 2.2)


func _cannon(at: Vector3, yaw: float, interval: float, phase: float, lane: float) -> BrickCannon:
	var c := BrickCannon.new()
	c.interval = interval
	c.phase = phase
	c.lane = lane
	c.position = at
	c.rotation.y = yaw
	add_child(c)
	return c


func _spring(base: Vector3, land_h: float, plunge_h: float, col: String = "red") -> SpringPad:
	var s := SpringPad.new()
	s.colour = col
	s.land_height = land_h
	s.plunge_height = plunge_h
	s.position = base
	add_child(s)
	return s


## A little party balloon holding a hook flower up in the air.
func _balloon(base: Vector3, col: StringName) -> void:
	var b := SphereMesh.new()
	b.radius = 1.1
	b.height = 2.5
	var m := Kit.unique_mat(col, 0.03)
	m.set_shader_parameter(&"flash", 0.15)
	m.set_shader_parameter(&"flash_color", Palette.color(&"foam"))
	Kit.mesh_instance(self, b, m, base + Vector3(0.0, 4.4, 0.0))
	Kit.mesh_instance(self, RoundMesh.box(Vector3(0.04, 1.6, 0.04), 0.01), Kit.mat(&"cloth_cream"), base + Vector3(0.0, 2.4, 0.0))


## A cloud you can stand on.
func _cloud(top: Vector3, size: Vector2) -> void:
	Kit.block(self, top, Vector3(size.x, 1.2, size.y), &"foam", _layers(), &"cloth_cream")
	for i in 5:
		var off := Vector3(_rng.randf_range(-0.4, 0.4) * size.x, -0.7, _rng.randf_range(-0.4, 0.4) * size.y)
		Kit.blob(self, top + off, minf(size.x, size.y) * 0.32, &"cloth_cream")


# --- Ground, moat and border ------------------------------------------------------------------

func _ground_and_moat() -> void:
	var holes: Array[Rect2] = [Rect2(-MOAT, -MOAT, MOAT * 2.0, MOAT * 2.0)]
	ground(Rect2(-125.0, -140.0, 250.0, 265.0), holes, 0.0, 14.0, &"bark_mid", &"grass_mid", 0.03)
	# The castle island, its bailey paved.
	plat(Vector3(0.0, BAILEY, 0.0), Vector2(ISLAND * 2.0, ISLAND * 2.0), &"stone_light", 0)
	# The moat: four strips of deep water over one sandy bed; the banks are the walls.
	var strips: Array[Rect2] = [Rect2(-MOAT, -MOAT, MOAT * 2.0, MOAT - ISLAND), Rect2(-MOAT, ISLAND, MOAT * 2.0, MOAT - ISLAND), Rect2(-MOAT, -ISLAND, MOAT - ISLAND, ISLAND * 2.0), Rect2(ISLAND, -ISLAND, MOAT - ISLAND, ISLAND * 2.0)]
	for r in strips:
		Kit.water(self, Vector3(r.get_center().x, WATER_Y, r.get_center().y), r.size, WATER_Y - MOAT_BED)
	Kit.block(self, Vector3(0.0, MOAT_BED, 0.0), Vector3(MOAT * 2.0, 2.0, MOAT * 2.0), &"sand_mid", _layers(), &"sand_light")
	# Things down in the moat: a seed in a sunken brick arch, weeds, fish and ducks.
	for x: float in [12.0, 20.0]:
		_brick_row(Vector3(x, MOAT_BED + 3.0, 30.0), Vector3(1.6, 3.0, 2.0), &"roof_red")
	_brick_row(Vector3(16.0, MOAT_BED + 4.0, 30.0), Vector3(9.6, 1.0, 2.0), &"roof_red")
	seed_at(&"w8_seed_moat", Vector3(16.0, MOAT_BED + 0.4, 30.0))
	for p: Vector3 in [Vector3(-26.0, MOAT_BED, 31.0), Vector3(-8.0, MOAT_BED, 33.0), Vector3(30.0, MOAT_BED, -10.0), Vector3(-30.0, MOAT_BED, 8.0), Vector3(4.0, MOAT_BED, -31.0)]:
		Whimsy.kelp(self, p, 6.0)
	for f: Array in [[Vector3(-18.0, -5.0, 30.0), &"gold"], [Vector3(20.0, -6.0, -30.0), &"sunset_orange"], [Vector3(30.0, -5.0, 0.0), &"candy_pink"]]:
		Ambient.fish(self, f[0] as Vector3, 4.0, 6, f[1] as StringName)
	for d: Vector3 in [Vector3(-20.0, WATER_Y, 30.0), Vector3(20.0, WATER_Y, -30.0), Vector3(-30.0, WATER_Y, -6.0)]:
		var duck := Duck.new()
		duck.position = d
		duck.radius = 3.5
		add_child(duck)


## Giant toy blocks round the edge, and hills and clouds beyond.
func _border() -> void:
	var k := 0
	for z: float in [-138.0, 123.0]:
		var x := -125.0
		while x < 124.9:
			var w := minf(16.0, 125.0 - x)
			var h := 18.0 + float(k % 3) * 3.0
			Kit.block(self, Vector3(x + w * 0.5, h, z), Vector3(w, h - floor_y, 4.0), TOY[k % TOY.size()], _layers(), &"grass_mid")
			x += w
			k += 1
	for x: float in [-123.0, 123.0]:
		var z := -136.0
		while z < 120.9:
			var d := minf(16.0, 121.0 - z)
			var h := 18.0 + float(k % 3) * 3.0
			Kit.block(self, Vector3(x, h, z + d * 0.5), Vector3(4.0, h - floor_y, d), TOY[k % TOY.size()], _layers(), &"grass_mid")
			z += d
			k += 1
	for i in 14:
		var a := float(i) / 14.0 * TAU
		Whimsy.hill(self, Vector3(cos(a) * 200.0, -6.0, sin(a) * 200.0), _rng.randf_range(45.0, 70.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.2
		Whimsy.mountain(self, Vector3(cos(a) * 330.0, -10.0, sin(a) * 330.0), _rng.randf_range(60.0, 90.0), _rng.randf_range(90.0, 140.0), false)
	for i in 18:
		var a := float(i) / 18.0 * TAU + _rng.randf_range(-0.1, 0.1)
		var r := _rng.randf_range(150.0, 230.0)
		Props.spawn(self, &"cloud_big" if i % 2 == 0 else &"cloud_small", Vector3(cos(a) * r, _rng.randf_range(40.0, 70.0), sin(a) * r), _rng.randf() * TAU, _rng.randf_range(3.0, 5.0), false)
	Whimsy.rainbow(self, Vector3(-40.0, -20.0, -170.0), 120.0, 0.3)


# --- South: the Welcome Meadow ---------------------------------------------------------------

func _meadow() -> void:
	add_spawn(&"w8_entrance", Vector3(0.0, 0.0, 104.0), Vector3.FORWARD)
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 112.0)
	add_child(exit)
	sign_post(Vector3(7.0, 0.0, 100.0), "Welcome to Brickbloom Heights!\nFind 3 Star Shards and a stair of\nblocks climbs the castle's Star Turret.")
	villager("gable", "Gable", Vector3(-6.0, 0.0, 98.0))
	checkpoint(&"w8_cp_meadow", Vector3(-8.0, 0.0, 70.0))
	# The drawbridge over the south moat to the castle gate.
	HighTier.bridge(self, Vector3(0.0, 0.0, MOAT + 0.3), Vector3(0.0, BAILEY, ISLAND - 0.3), 7.0, &"wood_plank", true, &"roof_red")
	for x: float in [-5.0, 5.0]:
		Kit.pillar(self, Vector3(x, 4.0, MOAT + 1.5), 0.7, 4.0, &"stone_light", &"gold")
		_flag(Vector3(x, 4.0, MOAT + 1.5), "red" if x < 0.0 else "yellow", 1.4)
	# A row of bricks over the path; one glints.
	var kinds: Array[int] = [BonkBrick.Kind.BREAK, BonkBrick.Kind.PLAIN, BonkBrick.Kind.SEED, BonkBrick.Kind.PLAIN, BonkBrick.Kind.BREAK, BonkBrick.Kind.BREAK]
	for i in kinds.size():
		var top := Vector3(-7.5 + i * 3.0, 6.0, 86.0)
		if kinds[i] == BonkBrick.Kind.SEED:
			_seed_brick(top, &"w8_seed_brick_meadow")
		else:
			_brick(top, kinds[i] as BonkBrick.Kind)
	sign_post(Vector3(-12.0, 0.0, 88.0), "Jump and bonk the bricks\nfrom below!", 0.3)
	# Toys strewn about the meadow.
	_toy_stack(Vector3(22.0, 0.0, 94.0), 3)
	_toy_stack(Vector3(-24.0, 0.0, 104.0), 2)
	_toy_stack(Vector3(28.0, 0.0, 50.0), 2)
	_ball(Vector3(-18.0, 0.0, 92.0), "blue", 2.2)
	_ball(Vector3(30.0, 0.0, 76.0), "yellow", 2.6)
	_cones(Vector3(-4.0, 0.0, 44.0), Vector3(-4.0, 0.0, 56.0), 4, "red")
	_cones(Vector3(4.0, 0.0, 44.0), Vector3(4.0, 0.0, 56.0), 4, "yellow")
	for i in 8:
		var a := float(i) / 8.0 * TAU
		Whimsy.flower(self, Vector3(cos(a) * 26.0, 0.0, 96.0 + sin(a) * 8.0), 1.2, 0.9, [&"candy_pink", &"gold", &"slime_blue", &"mush_purple"][i % 4] as StringName, false)
	scatter(Vector3(0.0, 0.0, 80.0), Vector2(32.0, 30.0), 34, [&"flower_red", &"flower_yellow", &"flower_purple", &"bush"] as Array[StringName], 8.0)
	heart_bush(Vector3(26.0, 0.0, 66.0))
	heart_bush(Vector3(-28.0, 0.0, 60.0))
	butterflies(Vector3(0.0, 1.0, 84.0), 22.0, 10)
	birds(Vector3.ZERO, 90.0, 45.0, 8)
	add_capture_point("meadow", Vector3(0.0, 10.0, 118.0), Vector3(0.0, 10.0, 30.0))


# --- Castle Brickbloom --------------------------------------------------------------------------

func _castle() -> void:
	var wall_h := RAMPART - BAILEY
	var it := ISLAND - 2.5
	# Curtain walls whose tops are the rampart ring; the gate in the south wall.
	var walls: Array[Array] = [
		[Vector3(0.0, RAMPART, -it), Vector3(ISLAND * 2.0, wall_h, 5.0)],
		[Vector3(it, RAMPART, 0.0), Vector3(5.0, wall_h, ISLAND * 2.0 - 10.0)],
		[Vector3(-it, RAMPART, 0.0), Vector3(5.0, wall_h, ISLAND * 2.0 - 10.0)],
		[Vector3(-14.0, RAMPART, it), Vector3(20.0, wall_h, 5.0)],
		[Vector3(14.0, RAMPART, it), Vector3(20.0, wall_h, 5.0)],
		[Vector3(0.0, RAMPART, it), Vector3(8.0, 3.0, 5.0)],
	]
	for w in walls:
		var b := Kit.block(self, w[0] as Vector3, w[1] as Vector3, &"stone_light", _layers(), &"sand_light")
		b.name = "CastleWall"
	# Merlons along the outer edges (gaps where the bridges meet the ramparts).
	var o := ISLAND - 0.6
	for i in 15:
		var t := -21.0 + i * 3.0
		if absf(t) > 3.0:
			Kit.block(self, Vector3(t, RAMPART + 1.2, -o), Vector3(1.6, 1.2, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
		Kit.block(self, Vector3(t, RAMPART + 1.2, o), Vector3(1.6, 1.2, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
	for i in 12:
		var t := -16.5 + i * 3.0
		if absf(t + 6.0) > 3.0:
			Kit.block(self, Vector3(o, RAMPART + 1.2, t), Vector3(1.2, 1.2, 1.6), &"stone_light", Layers.WORLD, &"roof_red")
		Kit.block(self, Vector3(-o, RAMPART + 1.2, t), Vector3(1.2, 1.2, 1.6), &"stone_light", Layers.WORLD, &"roof_red")
	# Corner turrets: three with pointy roofs and flags; the north-east one is a flat lookout.
	for c: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		var at := Vector3(c.x * it, 0.0, c.y * it)
		Kit.pillar(self, at + Vector3(0.0, 15.0, 0.0), 4.5, 15.0 - MOAT_BED, &"stone_light", &"sand_light")
		Kit.pillar(self, at + Vector3(0.0, 9.0, 0.0), 4.7, 0.6, &"gold", &"gold", 0)
		if c == Vector2(1.0, -1.0):
			for k in 8:
				var a := float(k) / 8.0 * TAU
				Kit.block(self, at + Vector3(cos(a) * 3.8, 16.2, sin(a) * 3.8), Vector3(1.2, 1.2, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
			continue
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 5.2
		cone.height = 7.0
		var roof := Kit.static_body(self, at + Vector3(0.0, 15.0 + 3.5, 0.0))
		Kit.mesh_instance(roof, cone, Kit.mat(&"roof_blue" if c.y < 0.0 else &"roof_red", 0.03))
		Kit.add_shape(roof, cone.create_convex_shape())
		_flag(at + Vector3(0.0, 21.6, 0.0), "yellow" if c.x < 0.0 else "blue", 1.6)
	# The lookout turret: a step up from the north rampart, and a seed on top.
	Kit.block(self, Vector3(15.6, RAMPART + 1.5, -it), Vector3(2.4, 1.5, 3.0), &"stone_light", _layers(), &"roof_red")
	seed_at(&"w8_seed_turret", Vector3(it, 15.0, -it))
	# The gatehouse: a striped arch over the gate.
	Models.spawn(self, _kk("arch_wide", "red"), Vector3(0.0, BAILEY, ISLAND - 0.6), 0.0, 1.45)
	# Bailey: a lift and ladders up to the ramparts, banners and barrels.
	lift(Vector3(-16.5, BAILEY, 16.5), RAMPART, 7.0, &"thatch")
	ladder(Vector3(8.0, BAILEY, -it + 2.5), RAMPART - BAILEY, 0.0)
	ladder(Vector3(it - 2.5, BAILEY, 4.0), RAMPART - BAILEY, -PI * 0.5)
	for spec: Array in [[Vector3(-12.0, BAILEY, -18.4), 0.0], [Vector3(12.0, BAILEY, -18.4), 0.0], [Vector3(-18.4, BAILEY, -4.0), PI * 0.5], [Vector3(18.4, BAILEY, 12.0), -PI * 0.5]]:
		Props.spawn(self, &"q_banner_1", spec[0] as Vector3, spec[1] as float, 1.6, false)
	for spec: Vector3 in [Vector3(16.0, BAILEY, 17.0), Vector3(17.2, BAILEY, 15.6), Vector3(-17.0, BAILEY, -16.0)]:
		prop(&"barrel", spec, _rng.randf() * TAU, 1.3)
	checkpoint(&"w8_cp_bailey", Vector3(-4.0, BAILEY, 15.0))
	# Ramparts: the upper world's ring. Captain Corbel keeps watch; a cannon sweeps the north walk.
	checkpoint(&"w8_cp_ramparts", Vector3(-12.0, RAMPART, it))
	villager("corbel", "Captain Corbel", Vector3(8.0, RAMPART, it), &"w8_found_spyglass", &"w8_seed_spyglass", Vector3(5.0, KEEP_TOP + 0.3, 5.0), "Corbel's spyglass")
	_cannon(Vector3(-17.0, RAMPART, -it), -PI * 0.5, 4.5, 0.0, 30.0)
	sign_post(Vector3(-4.0, RAMPART, -it + 1.5), "Cannon! It glows and puffs\nbefore it fires.", PI)
	for x: float in [-10.0, 10.0]:
		Whimsy.lamp(self, Vector3(x, BAILEY, 19.0 - 1.5), x < 0.0)
	sparkles(Vector3(0.0, 14.0, 0.0), Vector3(40.0, 16.0, 40.0), 50)
	add_capture_point("castle", Vector3(42.0, 32.0, 52.0), Vector3(0.0, 14.0, 0.0))
	add_capture_point("ramparts", Vector3(-12.0, RAMPART + 3.0, ISLAND - 2.5), Vector3(14.0, 14.0, -40.0))


## The keep: a spiral walk round it up to its roof, the Star Turret on top, and the Grand Star.
func _keep() -> void:
	ramp_tower(Vector3.ZERO, BAILEY, KEEP_TOP, 16.0, 4.0, &"stone_light", &"wood_plank", &"thatch")
	# A spur from the spiral's second landing across to the east rampart.
	bridge(Vector3(12.0, RAMPART, -10.0), Vector3(ISLAND - 5.0, RAMPART, -10.0), 3.6, &"wood_plank")
	# Battlements on three sides of the roof (the spiral arrives on the south side).
	for i in 6:
		var t := -6.5 + i * 2.6
		Kit.block(self, Vector3(t, KEEP_TOP + 1.0, -7.5), Vector3(1.2, 1.0, 1.0), &"stone_light", Layers.WORLD, &"roof_red")
		Kit.block(self, Vector3(-7.5, KEEP_TOP + 1.0, t), Vector3(1.0, 1.0, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
		Kit.block(self, Vector3(7.5, KEEP_TOP + 1.0, t), Vector3(1.0, 1.0, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
	# The Star Turret, 13 m of it, too tall to jump.
	Kit.pillar(self, Vector3(0.0, STAR_TOP, 0.0), 2.6, STAR_TOP - KEEP_TOP, &"stone_light", &"gold")
	for k in 3:
		Kit.pillar(self, Vector3(0.0, KEEP_TOP + 3.5 + k * 4.0, 0.0), 2.85, 0.5, &"roof_red", &"roof_red", 0)
	var cols: Array[StringName] = [&"roof_red", &"sunset_orange", &"thatch", &"slime_green", &"roof_blue"]
	for i in 5:
		var a := -PI * 0.5 + i * 0.9
		var step := GhostPlatform.new()
		step.size = Vector3(4.5, 1.0, 4.5)
		step.color_name = cols[i]
		step.position = Vector3(cos(a) * 6.5, KEEP_TOP + 2.2 * (i + 1), sin(a) * 6.5)
		add_child(step)
		stair.append(step)
	var star := GoalStar.new()
	star.world_id = WORLD
	star.position = Vector3(0.0, STAR_TOP, 0.0)
	add_child(star)
	_flag(Vector3(-6.0, KEEP_TOP, 6.0), "red", 2.2)
	_flag(Vector3(6.0, KEEP_TOP, 6.0), "yellow", 2.2)
	add_capture_point("keep", Vector3(22.0, 30.0, 22.0), Vector3(0.0, 26.0, 0.0))


# --- East: the Toybox Terraces ------------------------------------------------------------------

func _terraces() -> void:
	# Five stacked toy blocks, 3 m apart in height, each joined to the next.
	plat(Vector3(54.0, 3.0, 42.0), Vector2(28.0, 20.0), &"roof_red")
	plat(Vector3(80.0, 6.0, 36.0), Vector2(20.0, 24.0), &"thatch")
	plat(Vector3(96.0, 9.0, 8.0), Vector2(20.0, 24.0), &"roof_blue")
	plat(Vector3(52.0, 12.0, -6.0), Vector2(24.0, 20.0), &"slime_green")
	plat(Vector3(96.0, 15.0, -34.0), Vector2(20.0, 20.0), &"mush_purple")
	# Ways up from the meadow: a step and a ladder onto the red block.
	plat(Vector3(44.0, 1.5, 54.0), Vector2(3.0, 3.0), &"candy_pink", 0)
	ladder(Vector3(60.0, 0.0, 52.0), 3.0, 0.0)
	# Steps between the blocks, and bridges to the green block and the purple summit.
	plat(Vector3(69.0, 4.5, 40.0), Vector2(3.0, 3.0), &"sunset_orange", 0)
	plat(Vector3(88.0, 7.5, 22.0), Vector2(3.0, 3.0), &"candy_pink", 0)
	bridge(Vector3(86.3, 9.0, -1.0), Vector3(63.7, 12.0, -1.0), 4.0, &"wood_plank")
	bridge(Vector3(96.0, 9.0, -4.3), Vector3(96.0, 15.0, -23.7), 4.0, &"wood_plank")
	# The green block joins the castle's east rampart; a ladder and a lift climb its south face.
	bridge(Vector3(39.7, RAMPART, -6.0), Vector3(ISLAND + 0.3, RAMPART, -6.0), 4.0, &"wood_plank", true, &"roof_red")
	ladder(Vector3(46.0, 0.0, 4.0), 12.0, 0.0)
	lift(Vector3(60.0, 0.0, 6.8), 12.0, 8.0, &"thatch")
	ladder(Vector3(106.0, 0.0, -30.0), 15.0, PI * 0.5)
	checkpoint(&"w8_cp_terraces", Vector3(90.0, 9.0, 14.0))
	# The Wobbly Tower on the summit: three toy blocks stacked crooked, Mortimer's trowel on top.
	Kit.block(self, Vector3(100.0, 18.0, -38.0), Vector3(6.0, 3.0, 6.0), &"roof_red", _layers(), &"grass_mid")
	var t2 := Kit.block(self, Vector3(98.0, 21.0, -41.0), Vector3(5.0, 3.0, 5.0), &"thatch", _layers(), &"grass_mid")
	t2.rotation.y = 0.25
	var t3 := Kit.block(self, TOWER_TOP, Vector3(4.6, 3.0, 4.6), &"roof_blue", _layers(), &"grass_mid")
	t3.rotation.y = -0.2
	sign_post(Vector3(92.0, 15.0, -26.0), "The Wobbly Tower")
	_flag(TOWER_TOP + Vector3(1.6, 0.0, 1.6), "green", 1.6)
	# A star-brick shed on the red block (Star Rush), a chest, and a Mimic pretending.
	_rush_hut(Vector3(62.0, 3.0, 35.5), 0.0)
	seed_at(&"w8_seed_rush", Vector3(62.0, 3.0, 35.5))
	chest(Vector3(46.0, 3.0, 44.0), 0.3, &"w8_seed_chest")
	critter(Mimic, Vector3(50.0, 3.5, 47.0))
	# Toys and arrows up the route.
	_toy_stack(Vector3(76.0, 6.0, 44.0), 2)
	_toy_stack(Vector3(102.0, 9.0, 16.0), 3)
	_ball(Vector3(60.0, 12.0, -12.0), "red", 1.8)
	_ball(Vector3(84.0, 6.0, 28.0), "green", 2.0)
	for spec: Array in [[Vector3(66.0, 3.0, 44.0), -PI * 0.5], [Vector3(86.0, 6.0, 28.0), PI], [Vector3(88.0, 9.0, 0.0), PI * 0.5], [Vector3(96.0, 9.0, -2.0), PI]]:
		Models.spawn(self, _kk("signage_arrow_stand", "yellow"), spec[0] as Vector3, spec[1] as float, 1.4)
	_flag(Vector3(40.5, 3.0, 50.5), "yellow", 1.6)
	_flag(Vector3(105.0, 15.0, -25.0), "red", 1.8)
	add_capture_point("terraces", Vector3(60.0, 32.0, 72.0), Vector3(88.0, 10.0, -4.0))


## A little shed whose door is a wall of star-bricks.
func _rush_hut(base: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = base
	root.rotation.y = yaw
	add_child(root)
	Kit.block(root, Vector3(0.0, 4.0, -2.5), Vector3(6.0, 4.0, 1.0), &"thatch", _layers(), &"roof_red")
	Kit.block(root, Vector3(-2.5, 4.0, 0.0), Vector3(1.0, 4.0, 6.0), &"thatch", _layers(), &"roof_red")
	Kit.block(root, Vector3(2.5, 4.0, 0.0), Vector3(1.0, 4.0, 6.0), &"thatch", _layers(), &"roof_red")
	Kit.block(root, Vector3(0.0, 5.0, 0.3), Vector3(6.6, 1.0, 6.8), &"roof_red", _layers(), &"roof_red")
	var w := RushWall.new()
	w.size = Vector3(4.0, 4.0, 1.0)
	w.position = Vector3(0.0, 0.0, 2.5)
	root.add_child(w)


# --- North: Cannon Ridge and the Sky Rows ----------------------------------------------------------

func _ridge() -> void:
	plat(RIDGE, Vector2(64.0, 24.0), &"roof_blue")
	# Across the north moat from the ramparts.
	bridge(Vector3(0.0, RAMPART, -ISLAND - 0.3), Vector3(0.0, RAMPART, -37.7), 4.0, &"wood_plank", true, &"roof_red")
	# Ways up: a ramp tower at the west end, ladders on both faces, steps at the east end.
	ramp_tower(Vector3(-44.0, 0.0, -50.0), 0.0, RAMPART, 8.0, 4.0, &"thatch", &"wood_plank", &"grass_mid")
	bridge(Vector3(-36.3, RAMPART, -50.0), Vector3(-31.7, RAMPART, -50.0), 4.0, &"wood_plank")
	ladder(Vector3(-20.0, 0.0, -38.0), RAMPART, 0.0)
	ladder(Vector3(20.0, 0.0, -38.0), RAMPART, 0.0)
	ladder(Vector3(-10.0, 0.0, -62.0), RAMPART, PI)
	plat(Vector3(36.0, 3.0, -42.0), Vector2(4.0, 4.0), &"sunset_orange", 0)
	plat(Vector3(36.0, 6.0, -47.0), Vector2(4.0, 4.0), &"thatch", 0)
	plat(Vector3(36.0, 9.0, -52.0), Vector2(4.0, 4.0), &"candy_pink", 0)
	checkpoint(&"w8_cp_ridge", Vector3(-12.0, RAMPART, -40.0))
	villager("lettie", "Lettie", Vector3(-6.0, RAMPART, -41.0))
	# Two cannons sweep the length of the ridge in two lanes.
	_cannon(Vector3(29.0, RAMPART, -44.0), PI * 0.5, 4.2, 0.0, 56.0)
	_cannon(Vector3(29.0, RAMPART, -56.0), PI * 0.5, 5.0, 0.5, 56.0)
	_toy_stack(Vector3(-26.0, RAMPART, -58.0), 2)
	_flag(Vector3(-30.0, RAMPART, -39.5), "blue", 1.8)
	_flag(Vector3(30.0, RAMPART, -61.0), "yellow", 1.8)
	add_capture_point("ridge", Vector3(-40.0, 30.0, -20.0), Vector3(10.0, 14.0, -60.0))


func _sky_rows() -> void:
	# A spring pad at the ridge's north edge onto the first row.
	_spring(Vector3(10.0, RAMPART, -59.0), 6.5, 12.0)
	sign_post(Vector3(4.0, RAMPART, -58.0), "The Sky Rows: all the way\nto the Flagpole Fort!", PI)
	_brick_row(Vector3(10.0, 16.0, -70.0), Vector3(12.0, 1.2, 5.0))
	mover(Vector3(0.0, 17.0, -80.0), Vector3(6.0, 1.0, 5.0), Vector3(16.0, 0.0, 0.0), 6.0, &"wood_plank")
	_brick_row(Vector3(-10.0, 18.0, -90.0), Vector3(10.0, 1.2, 5.0))
	batling(Vector3(-10.0, 16.4, -90.0), true)
	var ring := _hoop(Vector3(-11.0, 18.0, -91.0), 0.0, "yellow", 1.4)
	seed_at(&"w8_seed_hoop", ring + Vector3.DOWN * 0.4)
	crumble(Vector3(-2.0, 19.0, -98.0), Vector3(4.0, 0.8, 4.0), CrumblePlatform.Look.ROCK)
	crumble(Vector3(6.0, 20.0, -103.0), Vector3(4.0, 0.8, 4.0), CrumblePlatform.Look.ROCK)
	crumble(Vector3(14.0, 21.0, -108.0), Vector3(4.0, 0.8, 4.0), CrumblePlatform.Look.ROCK)
	_brick_row(Vector3(23.0, 21.0, -114.0), Vector3(5.0, 1.2, 10.0))
	batling(Vector3(10.0, 25.0, -104.0))
	# The Flagpole Fort: a floating fort with a cannon on its step, a finish arch, the flagpole
	# and the Star Shard.
	var f := FORT
	Kit.block(self, f, Vector3(16.0, 2.0, 10.0), &"roof_red", _layers(), &"grass_mid")
	var under := CylinderMesh.new()
	under.top_radius = 6.0
	under.bottom_radius = 1.0
	under.height = 7.0
	Kit.mesh_instance(self, under, Kit.mat(&"bark_mid"), f + Vector3(0.0, -5.5, 0.0))
	for x: float in [-7.4, 7.4]:
		Kit.block(self, f + Vector3(x, 1.2, -1.0), Vector3(1.2, 1.2, 8.0), &"stone_light", Layers.WORLD, &"roof_red")
	Kit.block(self, f + Vector3(0.0, 1.2, -4.4), Vector3(16.0, 1.2, 1.2), &"stone_light", Layers.WORLD, &"roof_red")
	Models.spawn(self, _kk("signage_finish_wide", "neutral"), f + Vector3(-3.5, 0.0, 4.4), 0.0, 1.0)
	_cannon(f + Vector3(-1.0, 0.0, 4.0), PI, 3.6, 0.3, 14.0)
	Kit.pillar(self, f + Vector3(5.0, 13.0, -1.5), 0.25, 13.0, &"cloth_cream", &"gold")
	var knob := SphereMesh.new()
	knob.radius = 0.55
	knob.height = 1.1
	Kit.mesh_instance(self, knob, Kit.mat(&"gold", 0.03), f + Vector3(5.0, 13.4, -1.5))
	Models.spawn(self, _kk("flag_A", "green"), f + Vector3(5.0, 10.0, -1.5), PI * 0.5, 2.0)
	Kit.pillar(self, f + Vector3(2.0, 0.8, -1.5), 1.4, 0.8, &"stone_light", &"gold")
	shard_at(&"w8_shard_flagpole", f + Vector3(2.0, 0.8, -1.5))
	add_capture_point("sky_rows", Vector3(52.0, 34.0, -78.0), Vector3(8.0, 19.0, -106.0))


func _north_fields() -> void:
	# Brickbeard's Knoll: two stacked blocks with steps up.
	plat(Vector3(-84.0, 3.0, -84.0), Vector2(20.0, 20.0), &"candy_pink")
	plat(Vector3(-86.0, 6.0, -88.0), Vector2(12.0, 12.0), &"thatch")
	plat(Vector3(-72.0, 1.5, -80.0), Vector2(3.0, 3.0), &"sunset_orange", 0)
	plat(Vector3(-78.0, 4.5, -86.0), Vector2(3.0, 3.0), &"roof_blue", 0)
	villager("brickbeard", "Old Brickbeard", Vector3(-86.0, 6.0, -88.0))
	_flag(Vector3(-90.0, 6.0, -92.0), "blue", 2.0)
	# The beach ball that never rolls, between two red flags; three big steps west, the dig spot.
	_ball(Vector3(-50.0, 0.0, -104.0), "red", 2.4)
	_flag(Vector3(-50.0, 0.0, -97.0), "red", 2.0)
	_flag(Vector3(-50.0, 0.0, -111.0), "red", 2.0)
	var dig := DigSpot.new()
	dig.position = Vector3(-58.0, 0.2, -104.0)
	dig.reward_shard = &"w8_shard_riddle"
	add_child(dig)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		prop(&"q_clover", Vector3(-58.0 + cos(a) * 1.6, 0.0, -104.0 + sin(a) * 1.6), a, 1.0, false)
	_toy_stack(Vector3(30.0, 0.0, -90.0), 3)
	_toy_stack(Vector3(-20.0, 0.0, -124.0), 2)
	_ball(Vector3(40.0, 0.0, -118.0), "blue", 2.0)
	scatter(Vector3(0.0, 0.0, -100.0), Vector2(60.0, 30.0), 30, [&"flower_yellow", &"flower_purple", &"bush", &"q_mushrooms"] as Array[StringName], 0.0)
	heart_bush(Vector3(-20.0, 0.0, -88.0))
	butterflies(Vector3(-40.0, 1.0, -100.0), 18.0, 6)


# --- West: the Weigh-House Green and the brickworks -----------------------------------------------

func _green() -> void:
	balance = BalanceLift.new()
	balance.travel = BALANCE_TRAVEL
	balance.spacing = 16.0
	balance.pan_size = Vector2(6.0, 6.0)
	balance.position = BALANCE
	add_child(balance)
	# The crown on top of the pivot, and the Star Shard on it.
	Kit.pillar(self, BALANCE + Vector3(0.0, BALANCE_TRAVEL + 3.0, 0.0), 2.6, 1.0, &"gold", &"thatch")
	shard_at(&"w8_shard_balance", BALANCE + Vector3(0.0, BALANCE_TRAVEL + 3.0, 0.0))
	sign_post(BALANCE + Vector3(13.0, 0.0, 7.0), "The Great Brass Balance\nHeavy side sinks, light side rises.", PI * 0.2)
	villager("brixie", "Brixie", BALANCE + Vector3(12.0, 0.0, 10.0))
	Props.spawn(self, &"home_a_green", BALANCE + Vector3(-18.0, 0.0, 20.0), 0.6)
	checkpoint(&"w8_cp_green", Vector3(-62.0, 0.0, 4.0))
	_flag(BALANCE + Vector3(-8.0, 0.0, 6.0), "yellow", 1.6)
	_flag(BALANCE + Vector3(8.0, 0.0, 6.0), "red", 1.6)
	heart_bush(Vector3(-66.0, 0.0, -24.0))
	scatter(Vector3(-80.0, 0.0, -10.0), Vector2(30.0, 30.0), 24, [&"flower_red", &"flower_yellow", &"bush"] as Array[StringName], 12.0)
	add_capture_point("balance", Vector3(-58.0, 16.0, 26.0), Vector3(-88.0, 9.0, -4.0))


func _brickworks() -> void:
	var c := Vector3(-92.0, 0.0, 38.0)
	# The kiln: a round base, a roof, and a chimney with a seed on top.
	Kit.pillar(self, c + Vector3(0.0, 3.0, 0.0), 6.0, 3.0 - floor_y, &"roof_red", &"sand_light")
	Kit.pillar(self, c + Vector3(0.0, 6.0, 0.0), 4.4, 3.0, &"sunset_orange", &"stone_light")
	Kit.pillar(self, c + Vector3(-2.0, 9.0, -2.0), 1.5, 3.0, &"roof_red", &"stone_dark")
	seed_at(&"w8_seed_kiln", c + Vector3(-2.0, 9.0, -2.0))
	var door := Kit.mesh_instance(self, RoundMesh.box(Vector3(2.0, 2.4, 0.3), 0.2), Kit.mat(&"bark_dark"), c + Vector3(0.0, 1.2, 6.0))
	door.name = "KilnDoor"
	# Brick pallets, the step up onto the kiln (one stacked on another).
	for top: Vector3 in [c + Vector3(7.6, 1.5, 0.0), c + Vector3(10.0, 1.5, 4.0), c + Vector3(10.0, 3.0, 4.0)]:
		var size := Vector3(2.4, 1.5, 2.4)
		Kit.block(self, top, size, &"roof_red", _layers(), &"sunset_orange")
		Kit.mesh_instance(self, BonkBrick.mortar_mesh(size, 0.5, false), Kit.mat(&"cloth_cream"), top)
	# Errand: a cannonball knocked Mortimer's golden trowel onto the top of the Wobbly Tower.
	errand_star("mortimer", "Mortimer", c + Vector3(10.0, 0.0, -6.0), &"w8_found_trowel", &"w8_shard_errand", TOWER_TOP + Vector3(0.0, 0.3, 0.0), "Golden trowel")
	prop(&"q_cart", c + Vector3(-8.0, 0.0, 8.0), 0.6, 1.2)
	for k in 3:
		prop(&"q_crate", c + Vector3(8.0, 0.0, -10.0 + k * 1.6), _rng.randf(), 1.1)
	sign_post(c + Vector3(12.0, 0.0, 2.0), "Mortimer's Brickworks", -PI * 0.5)
	add_capture_point("brickworks", c + Vector3(24.0, 14.0, 22.0), c + Vector3(0.0, 4.0, 0.0))


# --- South-west: the Counting Court -------------------------------------------------------------

func _counting_court() -> void:
	var c := COURT
	# The Star Plinth: 18 m of sheer stone with the Star Shard on top.
	Kit.pillar(self, c + Vector3(0.0, COURT_TOP, 0.0), 2.6, COURT_TOP, &"stone_light", &"gold")
	for k in 3:
		Kit.pillar(self, c + Vector3(0.0, 4.0 + k * 5.0, 0.0), 2.85, 0.5, TOY[k], TOY[k], 0)
	shard_at(&"w8_shard_counting", c + Vector3(0.0, COURT_TOP, 0.0))
	# The foot step the staircase starts from.
	Kit.block(self, c + Vector3(5.4, 2.6, 0.0), Vector3(3.0, 2.6, 3.0), &"stone_light", _layers(), &"gold")
	# The Counting Blocks, jumbled round the court (the four sits on a pedestal).
	counting = SequenceBlocks.new()
	add_child(counting)
	var order: Array[int] = [3, 1, 5, 2, 4]
	for slot in 5:
		var a := deg_to_rad(36.0 + slot * 72.0)
		var n := order[slot]
		var foot := c + Vector3(cos(a) * 11.0, 0.0, sin(a) * 11.0)
		var top := foot + Vector3(0.0, 5.6, 0.0)
		if n == 4:
			Kit.block(self, foot + Vector3(0.0, 1.4, 0.0), Vector3(3.4, 1.4, 3.4), &"stone_light", _layers(), &"gold")
			top.y = 7.0
		counting.add_block(top, n, TOY[n])
	for i in 5:
		var a := deg_to_rad(55.0 * (i + 1))
		counting.stair.append(c + Vector3(cos(a) * 5.4, 2.6 * (i + 2), sin(a) * 5.4))
	counting.solved.connect(func() -> void:
		if hud != null:
			hud.show_banner("The Counting Blocks climb the Star Plinth!", 2.2))
	# A low wall round the court with its way in on the east, Tumbledot by the gap.
	for k in 10:
		if k == 0:
			continue
		var a := float(k) / 10.0 * TAU
		var w := Kit.block(self, c + Vector3(cos(a) * 18.0, 1.2, sin(a) * 18.0), Vector3(10.0, 1.2, 1.0), TOY[k % TOY.size()], Layers.WORLD, &"cloth_cream")
		w.rotation.y = -a + PI * 0.5
	villager("tumbledot", "Tumbledot", c + Vector3(19.0, 0.0, 5.0))
	sign_post(c + Vector3(19.0, 0.0, -4.0), "The Counting Court", -PI * 0.5)
	for i in 6:
		var a := float(i) / 6.0 * TAU + 0.3
		Whimsy.flower(self, c + Vector3(cos(a) * 15.0, 0.0, sin(a) * 15.0), 1.0, 0.8, [&"candy_pink", &"gold", &"slime_blue"][i % 3] as StringName, false)
	add_capture_point("counting", c + Vector3(24.0, 14.0, 20.0), c + Vector3(0.0, 6.0, 0.0))


# --- South-east: Bonk Lane and the Sun-and-Moon Steps -------------------------------------------

func _bonk_lane() -> void:
	var kinds: Array[int] = [BonkBrick.Kind.BREAK, BonkBrick.Kind.BREAK, BonkBrick.Kind.PLAIN, BonkBrick.Kind.SEED, BonkBrick.Kind.BREAK, BonkBrick.Kind.PLAIN, BonkBrick.Kind.BREAK, BonkBrick.Kind.BREAK]
	for i in kinds.size():
		var top := Vector3(50.0 + i * 3.0, 6.0, 74.0)
		if kinds[i] == BonkBrick.Kind.SEED:
			_seed_brick(top, &"w8_seed_brick_lane")
		else:
			_brick(top, kinds[i] as BonkBrick.Kind)
	# A second row higher up: stand on the first to bonk it.
	for i in 4:
		_brick(Vector3(56.0 + i * 3.0, 12.0, 74.0), BonkBrick.Kind.BREAK if i % 3 != 0 else BonkBrick.Kind.PLAIN, &"sunset_orange")
	_cones(Vector3(46.0, 0.0, 80.0), Vector3(76.0, 0.0, 80.0), 6, "blue")
	_toy_stack(Vector3(82.0, 0.0, 70.0), 2)
	_ball(Vector3(44.0, 0.0, 66.0), "green", 1.6)


func _sun_moon_steps() -> void:
	var c := SUNMOON
	flips = FlipBlocks.new()
	add_child(flips)
	# Three stone posts (always solid), with sun and moon steps between them.
	Kit.pillar(self, c + Vector3(6.0, 6.0, 2.0), 2.6, 6.0, &"stone_light", &"thatch")
	Kit.pillar(self, c + Vector3(-6.0, 12.0, 0.0), 2.6, 12.0, &"stone_light", &"thatch")
	Kit.pillar(self, c + Vector3(6.0, 18.0, -4.0), 2.6, 18.0, &"stone_light", &"thatch")
	flips.add_step(c + Vector3(0.0, 3.0, 6.0), Vector3(4.0, 0.8, 4.0), true)
	flips.add_step(c + Vector3(0.0, 9.0, 0.0), Vector3(4.0, 0.8, 4.0), false)
	flips.add_step(c + Vector3(0.0, 15.0, -2.0), Vector3(4.0, 0.8, 4.0), true)
	flips.add_switch(c + Vector3(-6.0, 6.0, 8.0))
	flips.add_switch(c + Vector3(6.0, 12.2, 2.0))
	flips.add_switch(c + Vector3(-6.0, 18.2, 0.0))
	seed_at(&"w8_seed_sunmoon", c + Vector3(6.0, 18.0, -4.0))
	sign_post(c + Vector3(-10.0, 0.0, 10.0), "Sun & Moon Steps: bonk a flip\nbrick and the steps swap.", PI * 0.25)
	_flag(c + Vector3(6.0, 18.0, -6.0), "yellow", 1.6)
	add_capture_point("sun_moon", c + Vector3(-24.0, 16.0, 24.0), c + Vector3(0.0, 9.0, 0.0))


# --- The Bonus Room (hidden, under the meadow) ----------------------------------------------------

func _bonus_room() -> void:
	var c := BONUS
	var hx := 16.0
	var hz := 11.0
	var h := 24.0
	Kit.block(self, c, Vector3(hx * 2.0 + 2.0, 2.0, hz * 2.0 + 2.0), &"roof_blue", _layers(), &"thatch")
	Kit.block(self, c + Vector3(0.0, h + 1.0, 0.0), Vector3(hx * 2.0 + 2.0, 1.0, hz * 2.0 + 2.0), &"roof_blue", _layers(), &"")
	var walls: Array[Array] = [[Vector3(-hx - 0.5, h, 0.0), Vector3(1.0, h, hz * 2.0)], [Vector3(hx + 0.5, h, 0.0), Vector3(1.0, h, hz * 2.0)], [Vector3(0.0, h, -hz - 0.5), Vector3(hx * 2.0 + 2.0, h, 1.0)], [Vector3(0.0, h, hz + 0.5), Vector3(hx * 2.0 + 2.0, h, 1.0)]]
	for k in walls.size():
		var w: Array = walls[k]
		Kit.block(self, c + (w[0] as Vector3), w[1] as Vector3, TOY[k + 1], _layers(), &"")
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 1.6
	light.omni_range = 34.0
	light.position = c + Vector3(0.0, 15.0, 0.0)
	add_child(light)
	Kit.label(self, c + Vector3(0.0, 10.0, -hz + 0.4), "BONUS ROOM", 90).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# A climb of brick rows, a mover, a spring pad and a crumbly block up to the Star Shard.
	_brick_row(c + Vector3(-11.0, 3.0, -5.0), Vector3(6.0, 1.0, 4.0))
	_brick_row(c + Vector3(-4.0, 6.0, -8.0), Vector3(5.0, 1.0, 4.0), &"sunset_orange")
	mover(c + Vector3(5.0, 9.0, -6.0), Vector3(5.0, 1.0, 4.0), Vector3(0.0, 0.0, 8.0), 5.0, &"wood_plank")
	_spring(c + Vector3(-3.0, 0.0, 3.0), 9.5, 14.0, "yellow")
	crumble(c + Vector3(12.0, 12.0, 4.0), Vector3(4.0, 0.8, 4.0), CrumblePlatform.Look.ROCK)
	_brick_row(c + Vector3(4.0, 15.0, 8.0), Vector3(6.0, 1.0, 3.0), &"candy_pink")
	var ring := _hoop(c + Vector3(4.0, 15.0, 8.0), PI * 0.5, "blue", 1.3)
	seed_at(&"w8_seed_bonus", ring + Vector3.DOWN * 0.4)
	_brick_row(c + Vector3(-6.0, 18.0, 6.0), Vector3(6.0, 1.0, 4.0))
	_brick_row(c + Vector3(-13.0, 20.5, -3.0), Vector3(5.0, 1.0, 6.0), &"thatch")
	shard_at(&"w8_shard_bonus", c + Vector3(-13.0, 20.5, -3.0))
	sparkles(c + Vector3(0.0, 10.0, 0.0), Vector3(30.0, 18.0, 20.0), 50)
	add_capture_point("bonus", c + Vector3(14.0, 12.0, 10.0), c + Vector3(-4.0, 10.0, -4.0))


# --- Warp pipes -------------------------------------------------------------------------------------

func _pipes() -> void:
	sign_post(Vector3(0.0, 0.0, 67.0), "Warp pipes! Plunge in, or stand\non top and press E.")
	var pairs: Array[Array] = [
		[&"plaza_east", Vector3(-12.0, 0.0, 62.0), 2.4, "green", "To the Toybox Terraces", &"terraces", Vector3(56.0, RAMPART, -12.0), 1.8, "green", "To the Pipe Plaza"],
		[&"plaza_north", Vector3(12.0, 0.0, 62.0), 3.2, "yellow", "To Cannon Ridge", &"ridge", Vector3(-20.0, RAMPART, -50.0), 2.0, "yellow", "To the Pipe Plaza"],
		[&"green", Vector3(-52.0, 0.0, -20.0), 2.4, "red", "To the ramparts", &"ramparts", Vector3(-ISLAND + 2.5, RAMPART, 8.0), 1.6, "red", "To the Weigh-House Green"],
		[&"bailey", Vector3(15.0, BAILEY, -14.0), 2.0, "blue", "To the keep roof", &"keep", Vector3(-5.5, KEEP_TOP, -5.5), 1.4, "blue", "To the bailey"],
	]
	for p in pairs:
		var a := _pipe(p[1] as Vector3, p[2] as float, str(p[3]), str(p[4]))
		var b := _pipe(p[6] as Vector3, p[7] as float, str(p[8]), str(p[9]))
		WarpPipe.pair(a, b)
		pipes[p[0] as StringName] = a
		pipes[p[5] as StringName] = b
	# The secret one: at the bottom of the moat's north-west corner, bubbling. It drops you into the
	# Bonus Room; the room's way out comes up on the bank nearby. Neither leads back in.
	var moat := _pipe(MOAT_PIPE, 2.2, "green", "", true, true)
	var arrive := _pipe(BONUS + Vector3(-12.0, 0.0, 7.0), 1.6, "green", "", false)
	var leave := _pipe(BONUS + Vector3(12.0, 0.0, 7.0), 1.6, "red", "Way out")
	var bank := _pipe(Vector3(-46.0, 0.0, -32.0), 1.4, "red", "", false)
	moat.target = arrive.global_position
	moat.target_facing = Vector3.RIGHT
	leave.target = bank.global_position
	leave.target_facing = Vector3.BACK
	pipes[&"moat"] = moat
	pipes[&"bonus_in"] = arrive
	pipes[&"bonus_out"] = leave
	pipes[&"bank"] = bank
	Ambient.bubbles(self, MOAT_PIPE + Vector3(0.0, 5.0, 0.0), Vector3(2.0, 8.0, 2.0), 16)


## Vinelash: hook flowers on balloons rise from the meadow to a cloud with a seed.
func _hooks() -> void:
	var cols: Array[StringName] = [&"candy_pink", &"slime_blue"]
	var bases: Array[Vector3] = [Vector3(-6.0, 4.0, 74.0), Vector3(-12.0, 11.0, 68.0)]
	for i in bases.size():
		hook(bases[i])
		_balloon(bases[i], cols[i])
	_cloud(Vector3(-18.0, 18.0, 60.0), Vector2(7.0, 7.0))
	hook(Vector3(-18.0, 18.0, 63.2))
	seed_at(&"w8_seed_hook", Vector3(-18.5, 18.0, 59.0))
	sign_post(Vector3(-2.0, 0.0, 76.0), "Balloon hooks: Vinelash (2 / G)\nup to the cloud!", PI * 0.75)


# --- Monsters -----------------------------------------------------------------------------------

func _critters() -> void:
	var meadow: Array[Vector3] = [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 2.0), Vector3(0.0, 0.0, -3.0)]
	gloplets(Vector3(-24.0, 0.0, 46.0), 9.0, meadow)
	var fields: Array[Vector3] = [Vector3(-4.0, 0.0, 0.0), Vector3(4.0, 0.0, 2.0)]
	gloplets(Vector3(10.0, 0.0, -100.0), 9.0, fields)
	# Star Rush counters both Hopfrogs and both Hexwizards.
	critter(Hopfrog, Vector3(80.0, 6.05, 38.0))
	critter(Hopfrog, Vector3(-64.0, 0.05, 22.0))
	var wiz := Hexwizard.new()
	wiz.spots = [Vector3(5.0, KEEP_TOP + 0.05, -4.0), Vector3(-4.0, KEEP_TOP + 0.05, 4.0), Vector3(4.0, KEEP_TOP + 0.05, 4.0), Vector3(-4.0, KEEP_TOP + 0.05, -3.0)]
	place(wiz, Vector3(5.0, KEEP_TOP + 0.05, -4.0))
	var wiz2 := Hexwizard.new()
	wiz2.spots = [Vector3(14.0, RAMPART + 0.05, -50.0), Vector3(-14.0, RAMPART + 0.05, -50.0), Vector3(0.0, RAMPART + 0.05, -52.0), Vector3(20.0, RAMPART + 0.05, -48.0)]
	place(wiz2, Vector3(14.0, RAMPART + 0.05, -50.0))
	critter(Buzzbee, Vector3(100.0, 12.0, 6.0))
	critter(Buzzbee, Vector3(70.0, 4.0, 82.0))
	critter(Armorling, Vector3(14.0, BAILEY + 0.5, 15.0))
	place(Puffcap.new(), Vector3(-24.0, RAMPART + 0.5, -46.0))
	place(Puffcap.new(), Vector3(-30.0, 0.5, -118.0))
	big_gloplet(Vector3(92.0, 15.5, -28.0), preload("res://data/enemies/pink_gloplet.tres"))
	big_gloplet(Vector3(-104.0, 0.5, -34.0))
	boulderkin(Vector3(-104.0, 0.5, 50.0), &"roof_red", &"sunset_orange", &"gold")
	batling(Vector3(32.0, 10.4, -6.0), true)
	add_capture_point("overview", Vector3(150.0, 110.0, 150.0), Vector3(0.0, 0.0, -10.0))
	add_capture_point("upper", Vector3(-46.0, 38.0, 34.0), Vector3(12.0, 14.0, -42.0))
