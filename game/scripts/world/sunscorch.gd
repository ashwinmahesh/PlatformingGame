class_name Sunscorch
extends BossWorld
## World 3, Sunscorch Canyon (Build 5): a painted-desert open world walled in by candy-striped
## canyon cliffs. From the Oasis Camp in the middle, four routes lead out in any order:
##   North  Mesa Climb      - striped mesas in easy steps, a balloon lift, charging Hoppies
##   East   Quicksand Flats - slow sand, Pricklepots, and three crystals that raise a bridge
##   West   Sunken Ruins    - Armorlings, a Mimic, lanterns and a cracked temple wall
##   South  Golem Gate      - the shard-locked gate to the Rumble Golem's bowl
## A Star Shard waits at the end of each of the first three. Falling off a mesa only drops you
## on the sand; only the eastern gorge is a pit. Clearing the world teaches the Thunderclap.
## Some seeds wait behind brambles and lanterns (Fireball) or past wide gaps (Glide).

const WORLD := &"world_03"
const ARENA := Vector3(0.0, 0.0, 108.0)
const ARENA_R := 18.0
const WALL_H := 22.0
const STRIPES: Array[StringName] = [&"candy_pink", &"thatch", &"mush_spot", &"mush_purple", &"sunset_orange"]
const ROCKS: Array[StringName] = [&"roof_red", &"sunset_orange", &"wood_warm"]


func configure() -> void:
	world_id = WORLD
	# Deep blue sky over pale sand and red-orange cliffs (contrast, not one orange wash).
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
	regions = {"camp": Vector3.ZERO, "mesas": Vector3(0.0, 0.0, -90.0), "flats": Vector3(80.0, 0.0, 0.0), "ruins": Vector3(-72.0, 0.0, 0.0), "gate": Vector3(0.0, 0.0, 70.0), "golem": ARENA}
	_canyon()
	_camp()
	_mesa_climb()
	_quicksand_flats()
	_sunken_ruins()
	_golem_gate()
	_wilds()
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


## A world-space striped wall block (canyon walls, the arena bowl).
func wall(top: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	var k := absi(int(top.x * 5.0 + top.z * 3.0))
	var b := Kit.block(self, top, size, ROCKS[k % ROCKS.size()], Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_mid")
	b.rotation.y = yaw
	var y := top.y - size.y + 2.0
	var i := 0
	while y < top.y - 1.5:
		var band := Kit.block(self, Vector3(top.x, y + 0.6, top.z), Vector3(size.x + 0.5, 1.2, size.z + 0.5), STRIPES[(k + i) % STRIPES.size()], 0, &"")
		band.rotation.y = yaw
		y += 3.2 + float((k + i) % 3) * 0.6
		i += 1


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


# --- The canyon: sand floor, the eastern gorge, striped cliffs all round ------------------------

func _canyon() -> void:
	var holes: Array[Rect2] = [Rect2(-22.0, -18.0, 16.0, 14.0), Rect2(98.0, -50.0, 52.0, 100.0)]
	ground(Rect2(-150.0, -160.0, 300.0, 320.0), holes, 0.0, 18.0, &"wood_warm", &"sand_light", 0.012)
	# The gorge: a long drop to a ribbon of river (a pit; falling costs ½ heart).
	var pit := Area3D.new()
	pit.collision_layer = Layers.HAZARD
	pit.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	pit.set_meta(&"kind", &"pit")
	pit.add_to_group(&"hazard")
	var shape := BoxShape3D.new()
	shape.size = Vector3(52.0, 4.0, 100.0)
	Kit.add_shape(pit, shape)
	pit.position = Vector3(124.0, -12.0, 0.0)
	add_child(pit)
	Kit.block(self, Vector3(124.0, -16.0, 0.0), Vector3(52.0, 2.0, 100.0), &"stone_dark", Layers.WORLD, &"")
	var river := PlaneMesh.new()
	river.size = Vector2(10.0, 100.0)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 1.5))
	Kit.mesh_instance(self, river, wm, Vector3(124.0, -15.9, 0.0))
	# Candy-striped canyon walls round the edge.
	for side in 4:
		var along := 300.0 if side < 2 else 320.0
		var n := int(along / 28.0)
		for i in n:
			var t := -along * 0.5 + (i + 0.5) * along / n
			var h := _rng.randf_range(26.0, 40.0)
			var inset := _rng.randf_range(-2.0, 3.0)
			match side:
				0:
					wall(Vector3(t, h, -167.0 + inset), Vector3(along / n + 2.0, h + 18.0, 16.0))
				1:
					wall(Vector3(t, h, 167.0 - inset), Vector3(along / n + 2.0, h + 18.0, 16.0))
				2:
					wall(Vector3(-157.0 + inset, h, t), Vector3(16.0, h + 18.0, along / n + 2.0))
				3:
					wall(Vector3(157.0 - inset, h, t), Vector3(16.0, h + 18.0, along / n + 2.0))
	# Far buttes and balloons drifting high above.
	for i in 16:
		var a := float(i) / 16.0 * TAU + _rng.randf_range(-0.1, 0.1)
		var r := _rng.randf_range(230.0, 300.0)
		var top := Vector3(cos(a) * r, _rng.randf_range(40.0, 80.0), sin(a) * r)
		var rad := _rng.randf_range(14.0, 28.0)
		Kit.pillar(self, top, rad, top.y + 20.0, &"wood_warm", &"sand_light", 0)
		for b in 3:
			Kit.pillar(self, Vector3(top.x, top.y * (0.3 + b * 0.22), top.z), rad + 0.6, 2.2, STRIPES[(i + b) % STRIPES.size()], &"", 0)
	var bcols: Array[Array] = [[&"roof_red", &"gold"], [&"candy_pink", &"mush_spot"], [&"slime_blue", &"gold"], [&"mush_purple", &"candy_pink"]]
	for i in 5:
		var holder := Node3D.new()
		holder.position = Vector3(_rng.randf_range(-120.0, 120.0), _rng.randf_range(38.0, 60.0), _rng.randf_range(-130.0, 130.0))
		add_child(holder)
		var cols: Array[StringName] = []
		cols.assign(bcols[i % bcols.size()])
		Whimsy.balloon(holder, Vector3.ZERO, cols)
		var basket := RoundMesh.box(Vector3(1.6, 1.0, 1.6), 0.2)
		Kit.mesh_instance(holder, basket, Kit.mat(&"wood_plank"), Vector3(0.0, -0.5, 0.0))
	birds(Vector3.ZERO, 90.0, 34.0, 7)
	add_capture_point("canyon", Vector3(60.0, 50.0, 110.0), Vector3(0.0, 0.0, -20.0))


# --- Oasis Camp (centre) -------------------------------------------------------------------------

func _camp() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w3_entrance", Vector3(0.0, 0.0, 16.0))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 24.0)
	add_child(exit)
	checkpoint(&"w3_cp_camp", Vector3(-8.0, 0.0, 14.0))
	sign_post(Vector3(6.0, 0.0, 12.0), "Find 3 Star Shards to open\nthe Golem Gate to the south!")
	sign_post(Vector3(4.0, 0.0, -24.0), "North: Mesa Climb")
	sign_post(Vector3(26.0, 0.0, -2.0), "East: Quicksand Flats", -PI * 0.5)
	sign_post(Vector3(-28.0, 0.0, 4.0), "West: Sunken Ruins", PI * 0.5)
	sign_post(Vector3(4.0, 0.0, 28.0), "South: Golem Gate", PI)
	# The oasis pool: swim down for a seed by the sunken statue.
	water(Vector3(-14.0, -0.6, -11.0), Vector2(16.0, 14.0), 4.0)
	Kit.block(self, Vector3(-14.0, -4.5, -11.0), Vector3(16.0, 13.5, 14.0), &"stone_dark", Layers.WORLD | Layers.CAMERA_BLOCKER, &"sand_mid")
	prop(&"statue_head", Vector3(-17.0, -4.5, -14.0), 0.6, 1.4, false)
	seed_at(&"w3_seed_pond", Vector3(-12.0, -4.5, -9.0))
	for i in 6:
		prop(&"waterlily", Vector3(-14.0 + _rng.randf_range(-6.0, 6.0), -0.55, -11.0 + _rng.randf_range(-5.0, 5.0)), _rng.randf() * TAU, 1.4, false)
	for i in 2:
		var duck := Duck.new()
		duck.position = Vector3(-16.0 + i * 5.0, -0.6, -11.0)
		duck.radius = 3.0
		add_child(duck)
	var palms: Array[StringName] = [&"palm", &"palm_tall", &"palm_bend", &"palm_detailed"]
	for i in 10:
		var a := float(i) / 10.0 * TAU + 0.2
		prop(palms[i % palms.size()], Vector3(-14.0 + cos(a) * 11.5, 0.0, -11.0 + sin(a) * 10.5), _rng.randf() * TAU, _rng.randf_range(1.0, 1.4))
	# Camp: tents, stalls, a campfire and Sandy.
	prop(&"tent_big", Vector3(12.0, 0.0, -6.0), -0.6, 1.2)
	prop(&"tent_small", Vector3(18.0, 0.0, 2.0), -1.2, 1.4)
	prop(&"campfire_stones", Vector3(11.0, 0.0, 3.0), 0.0, 1.2, false)
	prop(&"campfire", Vector3(11.0, 0.0, 3.0), 0.0, 1.0, false)
	var fire := OmniLight3D.new()
	fire.light_color = Palette.color(&"sunset_orange")
	fire.light_energy = 1.4
	fire.omni_range = 7.0
	fire.position = Vector3(11.0, 1.2, 3.0)
	add_child(fire)
	Whimsy.stall(self, Vector3(4.0, 0.0, -10.0), PI, &"sunset_orange")
	Whimsy.stall(self, Vector3(-4.0, 0.0, 6.0), PI * 0.5, &"candy_pink")
	for spec: Array in [[14.0, -12.0, &"barrel"], [15.0, -13.5, &"barrel"], [7.0, -13.0, &"crate"], [20.0, -3.0, &"sack"], [-6.0, 2.0, &"pot"]]:
		prop(spec[2] as StringName, Vector3(spec[0] as float, 0.0, spec[1] as float), _rng.randf() * TAU, 1.0, (spec[2] as StringName) in [&"barrel", &"crate"])
	var sandy := Npc.new()
	sandy.npc_id = "sandy"
	sandy.display_name = "Sandy"
	sandy.position = Vector3(8.0, 0.0, 8.0)
	add_child(sandy)
	# The lookout: crates up to a little platform with a seed.
	ledge(Vector3(16.0, 1.5, 10.0), Vector3(3.0, 1.5, 3.0), &"wood_plank")
	ledge(Vector3(19.0, 3.0, 12.5), Vector3(3.0, 1.0, 3.0), &"wood_plank")
	ledge(Vector3(19.5, 5.5, 17.0), Vector3(5.0, 0.5, 5.0), &"wood_plank")
	for c: Vector3 in [Vector3(17.5, 0.0, 15.0), Vector3(21.5, 0.0, 15.0), Vector3(17.5, 0.0, 19.0), Vector3(21.5, 0.0, 19.0)]:
		Kit.pillar(self, c + Vector3(0.0, 5.0, 0.0), 0.18, 5.0, &"bark_mid", &"", 0)
	Whimsy.bunting(self, Vector3(17.5, 5.6, 15.0), Vector3(21.5, 5.6, 19.0), 0.4)
	seed_at(&"w3_seed_lookout", Vector3(19.5, 5.5, 17.0))
	heart_bush(Vector3(20.0, 0.0, -14.0))
	for spec: Array in [[-24.0, 14.0, 6.0], [26.0, 18.0, 7.0], [-26.0, -22.0, 5.5], [24.0, -24.0, 8.0]]:
		Whimsy.cactus(self, Vector3(spec[0] as float, 0.0, spec[1] as float), spec[2] as float)
	Whimsy.flower(self, Vector3(-4.0, 0.0, -20.0), 2.5, 2.0, &"sunset_orange")
	Whimsy.crystal(self, Vector3(-22.0, 0.0, 6.0), &"crystal_violet", 0.9)
	scatter(Vector3.ZERO, Vector2(28.0, 28.0), 26, [&"cactus_short", &"cactus_tall", &"rock_small", &"flower_yellow", &"flower_red", &"bush_small"], 8.0)
	animals(Bunny, Vector3.ZERO, 26.0, 6)
	butterflies(Vector3(-14.0, 0.0, -11.0), 14.0, 8)
	sparkles(Vector3(-14.0, 1.5, -11.0), Vector3(30.0, 4.0, 30.0), 40)
	add_capture_point("camp", Vector3(26.0, 14.0, 34.0), Vector3(-4.0, 0.0, -6.0))


# --- North: Mesa Climb ----------------------------------------------------------------------------

func _mesa_climb() -> void:
	region(Vector3(0.0, 0.0, -40.0))
	ramp(Vector3(0.0, 0.0, -6.0), 10.0, 3.0, 8.0, &"sunset_orange")
	mesa(Vector3(0.0, 3.0, -24.0), Vector2(22.0, 16.0))
	critter(Hoppy, Vector3(4.0, 3.5, -26.0))
	mesa(Vector3(-16.0, 6.0, -40.0), Vector2(16.0, 16.0))
	balloon_lift(Vector3(-28.0, 0.5, -40.0), Vector3(0.0, 5.5, 0.0), 6.0, [&"roof_red", &"gold"])
	checkpoint(&"w3_cp_mesa", Vector3(-16.0, 6.0, -36.0))
	mesa(Vector3(2.0, 9.0, -54.0), Vector2(16.0, 14.0))
	critter(Hoppy, Vector3(4.0, 9.5, -56.0))
	critter(Hoppy, Vector3(-2.0, 9.5, -51.0))
	mesa(Vector3(-10.0, 12.0, -70.0), Vector2(14.0, 12.0))
	critter(Batling, Vector3(-10.0, 16.0, -70.0))
	balloon_lift(Vector3(1.0, 13.5, -72.0), Vector3(0.0, 0.0, -6.0), 5.0, [&"slime_blue", &"mush_spot"])
	mesa(Vector3(12.0, 15.0, -82.0), Vector2(15.0, 15.0))
	stone(Vector3(12.0, 16.5, -82.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w3_shard_mesa", Vector3(12.0, 16.5, -82.0))
	prop(&"statue_head", Vector3(16.0, 15.0, -87.0), -0.6, 1.3)
	Whimsy.cactus(self, P(Vector3(7.0, 15.0, -87.0)), 4.0)
	sign_post(Vector3(-4.0, 0.0, -4.0), "Climb the mesas to the summit.\nFell off? It's only sand!")
	# A spire for a seed: Plunge onto the cactus-flower Springcap.
	Kit.pillar(self, P(Vector3(24.0, 10.0, -40.0)), 2.6, 10.0, &"wood_warm", &"sand_light")
	bouncer(Vector3(20.0, 0.0, -35.0), Springcap.Look.MUSHROOM, 7.0, 13.0)
	seed_at(&"w3_seed_spire", Vector3(24.0, 10.0, -40.0))
	# A cracked hut against the first mesa hides a seed.
	alcove(Vector3(14.5, 0.0, -24.0), PI * 0.5, &"stone_light")
	seed_at(&"w3_seed_mesa_cave", Vector3(14.5, 0.0, -24.0))
	# Glider's Perch: a lone mesa too far to jump to from the summit (Glide).
	mesa(Vector3(42.0, 10.0, -82.0), Vector2(10.0, 10.0))
	seed_at(&"w3_seed_perch", Vector3(42.0, 10.0, -82.0))
	Whimsy.flower(self, P(Vector3(44.0, 10.0, -84.0)), 2.0, 1.5, &"candy_pink")
	sign_post(Vector3(17.0, 15.0, -77.0), "Too far to jump...\nif only you could float.", -PI * 0.5)
	for spec: Array in [[14.0, -12.0], [-14.0, -14.0], [-24.0, -56.0]]:
		critter(Pricklepot, Vector3(spec[0] as float, 0.0, spec[1] as float))
	for spec: Array in [[-24.0, -20.0, 7.0], [22.0, -60.0, 9.0], [-30.0, -70.0, 6.0], [30.0, -10.0, 5.0]]:
		Whimsy.cactus(self, P(Vector3(spec[0] as float, 0.0, spec[1] as float)), spec[2] as float)
	scatter(Vector3(0.0, 0.0, -50.0), Vector2(34.0, 40.0), 24, [&"rock_tall_c", &"rock_tall_d", &"cactus_tall", &"rock_small_c"], 0.0, true)
	sparkles(Vector3(12.0, 17.0, -82.0), Vector3(14.0, 4.0, 14.0), 24)
	add_capture_point("mesas", Vector3(40.0, 24.0, -20.0), Vector3(0.0, 8.0, -100.0))


# --- East: Quicksand Flats ------------------------------------------------------------------------

func _quicksand_flats() -> void:
	region(Vector3(40.0, 0.0, 0.0), -90.0)
	checkpoint(&"w3_cp_flats", Vector3(-6.0, 0.0, -8.0))
	sign_post(Vector3(4.0, 0.0, -6.0), "Light all three crystals quickly\nand a bridge appears over the gorge!")
	for spec: Array in [[-10.0, -18.0, 5.5], [8.0, -22.0, 5.0], [-4.0, -32.0, 6.0], [12.0, -38.0, 5.5], [-14.0, -42.0, 5.0], [2.0, -48.0, 5.0], [16.0, -14.0, 4.5]]:
		var q := Quicksand.new()
		q.radius = spec[2] as float
		q.position = P(Vector3(spec[0] as float, 0.0, spec[1] as float))
		add_child(q)
	for spec: Array in [[0.0, -16.0], [-12.0, -28.0], [6.0, -30.0], [-6.0, -40.0], [10.0, -46.0], [-8.0, -52.0]]:
		stone(Vector3(spec[0] as float, 1.2, spec[1] as float), 2.5, 1.2, &"wood_warm", &"sand_light")
	var group := SwitchGroup.new()
	add_child(group)
	for spec: Array in [[-18.0, -24.0], [18.0, -34.0], [-2.0, -54.0]]:
		stone(Vector3(spec[0] as float, 1.6, spec[1] as float), 2.4, 1.6, &"mush_purple", &"crystal_violet")
		var sw := CrystalSwitch.new()
		sw.hold = 14.0
		sw.position = P(Vector3(spec[0] as float, 1.6, spec[1] as float))
		add_child(sw)
		group.add(sw)
	var bridge: Array[GhostPlatform] = []
	for i in 4:
		var g := GhostPlatform.new()
		g.size = Vector3(6.0, 0.8, 5.2)
		g.color_name = &"crystal_violet"
		g.position = P(Vector3(0.0, 0.0, -60.5 - i * 5.0))
		g.rotation.y = Y()
		add_child(g)
		bridge.append(g)
	group.solved.connect(func() -> void:
		for i in bridge.size():
			var step := bridge[i]
			get_tree().create_timer(0.12 * i).timeout.connect(func() -> void:
				if is_instance_valid(step):
					step.set_solid(true))
		if hud != null:
			hud.show_banner("A crystal bridge spans the gorge!", 2.2))
	# The shard island across the gorge.
	ledge(Vector3(0.0, 0.0, -89.0), Vector3(24.0, 18.0, 22.0), &"wood_warm")
	stone(Vector3(0.0, 1.5, -94.0), 3.0, 1.5, &"stone_light", &"gold")
	shard_at(&"w3_shard_flats", Vector3(0.0, 1.5, -94.0))
	critter(Armorling, Vector3(-4.0, 0.5, -86.0))
	prop(&"statue_ring", Vector3(0.0, 0.0, -84.0), 0.0, 1.6, false)
	prop(&"rock_large_d", Vector3(8.0, 0.0, -97.0), 0.4, 1.2)
	seed_at(&"w3_seed_island", Vector3(9.0, 0.0, -93.0))
	heart_at(Vector3(-8.0, 0.0, -96.0))
	Whimsy.cactus(self, P(Vector3(-9.0, 0.0, -92.0)), 5.0)
	# Monsters on the flats.
	gloplets(Vector3(6.0, 0.0, -28.0), 12.0, [Vector3.ZERO, Vector3(-4.0, 0.0, 3.0), Vector3(3.0, 0.0, -5.0)], [], preload("res://data/enemies/ember_gloplet.tres"))
	for spec: Array in [[-8.0, -36.0], [12.0, -50.0], [20.0, -24.0]]:
		critter(Pricklepot, Vector3(spec[0] as float, 0.0, spec[1] as float))
	# A bramble-sealed hut (Fireball) with a seed.
	alcove(Vector3(-22.0, 0.0, -46.0), PI * 0.5, &"stone_light", &"bramble")
	seed_at(&"w3_seed_bramble", Vector3(-22.0, 0.0, -46.0))
	for i in 4:
		tumbleweed(P(Vector3(-28.0, 0.0, -12.0 - i * 11.0)), _frame.basis * Vector3(1.0, 0.0, -0.2), 56.0, i * 3.1)
	for spec: Array in [[24.0, -10.0, 6.0], [-26.0, -20.0, 7.5], [26.0, -48.0, 5.0], [-24.0, -58.0, 6.5]]:
		Whimsy.cactus(self, P(Vector3(spec[0] as float, 0.0, spec[1] as float)), spec[2] as float)
	for i in 4:
		Whimsy.crystal(self, P(Vector3(_rng.randf_range(-26.0, 26.0), 0.0, _rng.randf_range(-56.0, -10.0))), [&"crystal_violet", &"candy_pink"][i % 2] as StringName, _rng.randf_range(0.6, 1.0))
	add_capture_point("flats", Vector3(40.0, 22.0, 34.0), Vector3(96.0, 0.0, 0.0))
	add_capture_point("gorge", Vector3(90.0, 14.0, 24.0), Vector3(124.0, 0.0, 0.0))


# --- West: Sunken Ruins ---------------------------------------------------------------------------

func _sunken_ruins() -> void:
	region(Vector3(-40.0, 0.0, 0.0), 90.0)
	checkpoint(&"w3_cp_ruins", Vector3(0.0, 0.0, -6.0))
	ramp(Vector3(0.0, 0.0, -9.0), 4.0, 1.0, 12.0, &"roof_teal")
	plat(Vector3(0.0, 1.0, -30.0), Vector2(40.0, 34.0), &"roof_teal", 0)
	sign_post(Vector3(6.0, 0.0, -6.0), "Armorlings block swords from the front.\nGet behind them, or PLUNGE!")
	for spec: Array in [[-10.0, -22.0, 8.0, 1.2], [12.0, -26.0, 1.2, 8.0], [-14.0, -36.0, 1.2, 10.0], [8.0, -40.0, 10.0, 1.2]]:
		ledge(Vector3(spec[0] as float, 4.0, spec[1] as float), Vector3(spec[2] as float, 3.0, spec[3] as float), &"roof_teal")
	for x: float in [-7.0, 7.0]:
		for z: float in [-16.0, -22.0, -28.0, -34.0, -40.0]:
			prop(&"column_broken", Vector3(x, 1.0, z), _rng.randf() * TAU, _rng.randf_range(1.1, 1.5))
	prop(&"statue_head", Vector3(-16.0, 1.0, -16.0), 0.8, 1.6)
	prop(&"statue_head", Vector3(16.0, 1.0, -44.0), -2.4, 1.6)
	for spec: Array in [[-6.0, -24.0], [6.0, -32.0], [0.0, -40.0]]:
		critter(Armorling, Vector3(spec[0] as float, 1.5, spec[1] as float))
	chest(Vector3(14.0, 1.0, -18.0), PI * 0.5, &"w3_seed_chest")
	var mimic := critter(Mimic, Vector3(-15.0, 1.0, -42.0))
	mimic.rotation.y = Y(-PI * 0.5)
	critter(Batling, Vector3(0.0, 6.0, -28.0))
	critter(Batling, Vector3(10.0, 7.0, -38.0))
	# The temple: a cracked wall hides the shard.
	ramp(Vector3(0.0, 1.0, -43.0), 5.0, 3.0, 8.0, &"roof_teal")
	plat(Vector3(0.0, 4.0, -56.0), Vector2(26.0, 16.0), &"roof_teal", 0)
	alcove(Vector3(0.0, 4.0, -59.0), 0.0, &"sunset_orange")
	stone(Vector3(0.0, 5.0, -59.0), 1.4, 1.0, &"stone_light", &"gold")
	shard_at(&"w3_shard_ruins", Vector3(0.0, 5.0, -59.0))
	sign_post(Vector3(-5.0, 4.0, -51.0), "Cracked walls crumble:\nthree slashes or one PLUNGE.")
	# Lantern vault (Fireball): light both lanterns to open the vines.
	var vault_door := alcove(Vector3(-10.0, 4.0, -59.0), 0.0, &"roof_teal", &"gate") as VineGate
	seed_at(&"w3_seed_lanterns", Vector3(-10.0, 4.0, -59.0))
	var lanterns := SwitchGroup.new()
	add_child(lanterns)
	for x: float in [-6.0, -12.0]:
		var l := CrystalSwitch.new()
		l.look = CrystalSwitch.Look.LANTERN
		l.needs = &"fireball"
		l.position = P(Vector3(x, 4.0, -51.5))
		add_child(l)
		lanterns.add(l)
	lanterns.solved.connect(func() -> void:
		vault_door.set_closed(false)
		if hud != null:
			hud.show_banner("The vines draw back!", 2.0))
	sign_post(Vector3(-15.0, 4.0, -51.0), "Two lanterns, cold and dark...", PI * 0.25)
	for i in 5:
		Whimsy.crystal(self, P(Vector3(_rng.randf_range(-18.0, 18.0), 1.0, _rng.randf_range(-46.0, -14.0))), [&"crystal_violet", &"portal_teal", &"candy_pink"][i % 3] as StringName, _rng.randf_range(0.5, 0.9))
	for spec: Array in [[-22.0, -8.0, 6.0], [22.0, -12.0, 7.0], [-24.0, -50.0, 5.5], [22.0, -58.0, 6.5]]:
		Whimsy.cactus(self, P(Vector3(spec[0] as float, 0.0, spec[1] as float)), spec[2] as float)
	scatter(Vector3(0.0, 1.0, -30.0), Vector2(18.0, 15.0), 14, [&"statue_block", &"stone_tall_b", &"rock_small", &"pot"], 0.0, true)
	sparkles(Vector3(0.0, 4.0, -40.0), Vector3(36.0, 8.0, 40.0), 40)
	add_capture_point("ruins", Vector3(-30.0, 18.0, 30.0), Vector3(-80.0, 2.0, 0.0))
	add_capture_point("temple", Vector3(-80.0, 12.0, 14.0), Vector3(-98.0, 5.0, 0.0))


# --- South: Golem Gate and the Rumble Golem's bowl -----------------------------------------------

func _golem_gate() -> void:
	region(Vector3(0.0, 0.0, 40.0), 180.0)
	for x: float in [-16.0, 16.0]:
		var top := P(Vector3(x, WALL_H, -27.0))
		wall(top, S(Vector3(6.0, WALL_H, 46.0)))
	sign_post(Vector3(5.0, 0.0, -6.0), "The Golem Gate opens for 3 Star Shards.")
	critter(Hoppy, Vector3(0.0, 0.5, -22.0))
	critter(Batling, Vector3(-5.0, 5.0, -30.0))
	critter(Batling, Vector3(5.0, 6.0, -36.0))
	for spec: Array in [[6.0, -14.0], [-6.0, -38.0]]:
		critter(Pricklepot, Vector3(spec[0] as float, 0.0, spec[1] as float))
	for z: float in [-14.0, -32.0]:
		prop(&"statue_ring", Vector3(0.0, 0.0, z), 0.0, 3.2, false)
	# Ledges up the corridor wall to a seed.
	ledge(Vector3(-11.0, 2.5, -18.0), Vector3(4.0, 1.0, 4.0), &"sunset_orange")
	ledge(Vector3(-11.0, 5.0, -24.0), Vector3(4.0, 1.0, 4.0), &"candy_pink")
	ledge(Vector3(-11.0, 7.5, -30.0), Vector3(4.0, 1.0, 4.0), &"mush_purple")
	seed_at(&"w3_seed_corridor", Vector3(-11.0, 7.5, -30.0))
	checkpoint(&"w3_cp_gate", Vector3(0.0, 0.0, -42.0))
	heart_bush(Vector3(8.0, 0.0, -44.0))
	# The gate in a stone archway.
	for x: float in [-9.5, 9.5]:
		wall(P(Vector3(x, WALL_H, -49.5)), S(Vector3(7.0, WALL_H, 3.0)))
	wall(P(Vector3(0.0, WALL_H, -49.5)), S(Vector3(12.0, WALL_H - 4.2, 3.0)))
	make_gate(Vector3(0.0, 0.0, -49.5), 12.0)
	# The bowl: a ring of striped cliffs with a gap for the gate.
	var n := 30
	for i in n:
		var a := float(i) / n * TAU
		if absf(wrapf(a + PI * 0.5, -PI, PI)) < deg_to_rad(17.0):
			continue
		var c := ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R + 2.0)
		wall(c + Vector3(0.0, WALL_H, 0.0), Vector3(4.9, WALL_H, 3.0), -(a + PI * 0.5))
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.3
		Whimsy.cactus(self, ARENA + Vector3(cos(a), 0.0, sin(a)) * (ARENA_R - 1.2), 3.5, false)
	sign_post(Vector3(-5.0, 0.0, -44.0), "Slam! The Golem's fists get stuck.\nPLUNGE on the glowing gem!")
	add_capture_point("gate", Vector3(0.0, 14.0, 52.0), Vector3(0.0, 2.0, 92.0))
	add_capture_point("golem", ARENA + Vector3(0.0, 16.0, -12.0), ARENA + Vector3(0.0, 0.0, 6.0))


# --- The open sand between the routes --------------------------------------------------------------

func _wilds() -> void:
	region(Vector3.ZERO)
	# North-east: a little mesa with a heart and a balloon above.
	mesa(Vector3(56.0, 4.0, -56.0), Vector2(12.0, 12.0))
	heart_at(Vector3(56.0, 4.0, -56.0))
	critter(Hoppy, Vector3(58.0, 4.5, -58.0))
	# North-west: a giant fossil in the sand.
	for i in 7:
		var rib := CapsuleMesh.new()
		rib.radius = 0.6
		rib.height = 9.0 - absf(i - 3.0) * 1.2
		for side: float in [-1.0, 1.0]:
			var r := Kit.mesh_instance(self, rib, Kit.mat(&"mush_spot", 0.02), Vector3(-60.0 + side * 3.2, 3.0, -64.0 + i * 3.2))
			r.rotation.z = side * 0.55
	var skull := SphereMesh.new()
	skull.radius = 3.0
	skull.height = 5.0
	Kit.mesh_instance(self, skull, Kit.mat(&"mush_spot", 0.02), Vector3(-60.0, 2.0, -70.0))
	# South-east: a cactus garden and ember slimes; south-west: a crystal geode.
	gloplets(Vector3(56.0, 0.0, 60.0), 12.0, [Vector3.ZERO, Vector3(4.0, 0.0, -3.0), Vector3(-3.0, 0.0, 4.0)], [], preload("res://data/enemies/ember_gloplet.tres"))
	for i in 9:
		Whimsy.cactus(self, Vector3(_rng.randf_range(40.0, 80.0), 0.0, _rng.randf_range(40.0, 90.0)), _rng.randf_range(4.0, 9.0))
	for i in 6:
		var a := float(i) / 6.0 * TAU
		Whimsy.crystal(self, Vector3(-60.0 + cos(a) * 4.0, 0.0, 66.0 + sin(a) * 4.0), [&"crystal_violet", &"candy_pink", &"portal_teal"][i % 3] as StringName, _rng.randf_range(1.0, 1.8))
	critter(Pricklepot, Vector3(-52.0, 0.0, 56.0))
	critter(Pricklepot, Vector3(-66.0, 0.0, 52.0))
	# Scattered life everywhere.
	for i in 40:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-150.0, 150.0))
		if _busy(p):
			continue
		Whimsy.cactus(self, p, _rng.randf_range(3.5, 8.0))
	for i in 30:
		var p := Vector3(_rng.randf_range(-140.0, 140.0), 0.0, _rng.randf_range(-150.0, 150.0))
		if _busy(p):
			continue
		prop([&"rock_tall_c", &"rock_tall_e", &"stone_tall_c", &"rock_large_d", &"cactus_tall", &"palm_bend"][i % 6] as StringName, p, _rng.randf() * TAU, _rng.randf_range(1.0, 1.8))
	for i in 5:
		tumbleweed(Vector3(-130.0, 0.0, -120.0 + i * 55.0), Vector3(1.0, 0.0, 0.15), 240.0, i * 7.0)
	animals(Bunny, Vector3(40.0, 0.0, 40.0), 30.0, 4)
	animals(Bunny, Vector3(-40.0, 0.0, -40.0), 30.0, 4)


## True near paths, regions and set pieces, so filler doesn't block the way.
func _busy(p: Vector3) -> bool:
	if p.x > 92.0 and absf(p.z) < 56.0:
		return true
	for c: Vector3 in [Vector3.ZERO, Vector3(0.0, 0.0, -90.0), Vector3(80.0, 0.0, 0.0), Vector3(-72.0, 0.0, 0.0), Vector3(0.0, 0.0, 70.0), ARENA]:
		if Vector2(p.x - c.x, p.z - c.z).length() < 40.0:
			return true
	return absf(p.x) < 14.0 or absf(p.z) < 10.0
