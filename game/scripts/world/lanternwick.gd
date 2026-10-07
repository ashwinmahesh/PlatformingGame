class_name Lanternwick
extends OpenWorld
## World 6, Lanternwick (Build 6; Ashwin: "a dense city level which would look like the dense
## streets of old England full of alleyways and jammed with buildings"). A walled riverside town of
## timber-framed townhouses whose upper floors jut out over the streets, built from the Quaternius
## Medieval Village kit. A star world with a second world on the rooftops:
##   Clock Green   - the Clock Tower spiral, the town's main way up; a shard at the very top
##   Sweep's Run   - flat roof terraces all along the north bank, bridges over the alleys, and a
##                   chimney-stack climb to a shard
##   St. Wick's    - ring the churchyard bells in order and the crypt opens; a shard below
## With all three, a stairway of light climbs the Lantern Spire in the market to the Grand Star.

const WORLD := &"world_06"
const SPIRE := Vector3(0.0, 0.0, 57.0)
const COLS: Array[Vector2] = [Vector2(-90.0, -60.0), Vector2(-54.0, -22.0), Vector2(-16.0, 16.0), Vector2(22.0, 54.0), Vector2(60.0, 90.0)]
const SOUTH: Array[Vector2] = [Vector2(8.0, 36.0), Vector2(44.0, 70.0), Vector2(78.0, 100.0)]
const NORTH: Array[Vector2] = [Vector2(-46.0, -20.0), Vector2(-74.0, -54.0), Vector2(-98.0, -82.0)]
const RIVER := Rect2(-96.0, -12.0, 192.0, 12.0)
const WALL_H := 14.0
## Roof terraces on the north bank (Sweep's Run) and the south bank sit at 3 floors.
const TERRACE := TownHouse.FLOOR * 3.0 + 0.4

var _batch: ModuleBatch
## Every townhouse built: {pos, yaw, side, eave, ridge, flat} (Build 6 alleys use the side ones).
var _houses: Array[Dictionary] = []
var _spire_steps: Array[GhostPlatform] = []


func configure() -> void:
	world_id = WORLD
	platform_colour = &"yellow"
	model_tint = Color(1.06, 0.98, 0.92)
	# A golden late afternoon over the rooftops.
	sky_top = Color(0.16, 0.36, 0.86)
	sky_horizon = Color(1.0, 0.8, 0.62)
	sky_bottom = Color(1.0, 0.88, 0.76)
	cloud_cover = 0.42
	cloud_shade = Color(0.92, 0.74, 0.82)
	sun_color = Color(1.0, 0.86, 0.66)
	sun_energy = 1.1
	sun_angles = Vector2(-30.0, -50.0)
	fog_color = Color(1.0, 0.88, 0.8)
	fog_begin = 90.0
	fog_end = 300.0
	tree_kinds = [&"green", &"lime", &"autumn", &"green", &"blossom"]
	tops = {&"stone_light": &"stone_light", &"stone_dark": &"stone_dark", &"bark_mid": &"wood_plank"}
	grass_density = 0.01


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w6_entrance"
	music = &"lanternwick"
	floor_y = 0.0
	kill_y = -24.0
	_rng.seed = 606
	_batch = ModuleBatch.new()
	regions = {"gate": Vector3(0.0, 0.0, 90.0), "market": Vector3(0.0, 0.0, 57.0), "clock": Vector3(0.0, 0.0, 22.0), "river": Vector3(0.0, 0.0, -6.0), "church": Vector3(-38.0, 0.0, -64.0), "mill": Vector3(75.0, 0.0, -33.0)}
	_ground_and_walls()
	_river()
	_blocks()
	_gate_plaza()
	_market()
	_clock_green()
	_sweeps_run()
	_church()
	_mill()
	_courtyards()
	_streets()
	_alleys()
	_vine_routes()
	_more_stars()
	_batch.build(self)
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	finish_life()


func _on_shards_complete() -> void:
	for i in _spire_steps.size():
		var step := _spire_steps[i]
		get_tree().create_timer(0.15 * i).timeout.connect(func() -> void:
			if is_instance_valid(step):
				step.set_solid(true)
				AudioDirector.play(&"ui_blip", -6.0, 1.0 + i * 0.05))
	if hud != null:
		hud.show_banner("A stairway of light climbs the Lantern Spire!", 2.4)


# --- Helpers ----------------------------------------------------------------------------------

func house(base: Vector3, yaw: float, w: int, d: int, floors: int, roof: StringName = &"pitched", jetty: bool = true) -> Dictionary:
	return TownHouse.build(self, _batch, base, yaw, w, d, floors, roof, _rng.randi_range(0, 5), jetty)


## A washing line strung across an alley, hung with clothes.
func washing(a: Vector3, b: Vector3) -> void:
	var line := Node3D.new()
	line.position = (a + b) * 0.5
	add_child(line)
	line.basis = Basis.looking_at((b - a).normalized(), Vector3.UP)
	Kit.block(line, Vector3.ZERO, Vector3(0.06, 0.06, a.distance_to(b)), &"bark_dark", 0, &"")
	var cols: Array[StringName] = [&"cloth_cream", &"slime_blue", &"candy_pink", &"roof_red", &"gold", &"leaf_teal"]
	var n := int(a.distance_to(b) / 1.6)
	for i in range(1, n):
		var t := float(i) / float(n)
		var p := a.lerp(b, t) + Vector3.DOWN * (0.5 + sin(t * PI) * 0.4)
		var cloth := Kit.block(self, p, Vector3(0.9, 1.0 + (i % 3) * 0.3, 0.06), cols[(i + n) % cols.size()], 0, &"")
		cloth.rotation.y = atan2(b.x - a.x, b.z - a.z) + PI * 0.5


## Fills a block of the town with townhouses facing out on all four sides. gap_side 0-3 leaves a
## one-house opening (south, north, east, west) into the courtyard behind. Returns the courtyard.
func house_block(r: Rect2, floors_min: int, floors_max: int, flat: bool, gap_side: int = -1, jetty_ns: bool = true) -> Rect2:
	var dep := 2
	var hd := TownHouse.MOD * dep * 0.5
	var roof := &"flat" if flat else &"pitched"
	# South and north rows run the full width; east and west rows fill between them.
	for side in 4:
		var along := r.size.x if side < 2 else r.size.y - hd * 4.0
		var n_mod := int(floor(along / TownHouse.MOD))
		var start := (along - n_mod * TownHouse.MOD) * 0.5
		var mods: Array[int] = []
		var left := n_mod
		while left >= 2:
			var w := 3 if left >= 5 and _rng.randf() < 0.5 else 2
			if left == 3:
				w = 3
			mods.append(w)
			left -= w
		var gap_at := mods.size() / 2 if side == gap_side else -1
		var cursor := start
		for k in mods.size():
			var w := mods[k]
			if k == gap_at:
				cursor += TownHouse.MOD
			var mid := cursor + w * TownHouse.MOD * 0.5
			cursor += w * TownHouse.MOD
			if cursor > along + 0.01:
				break
			var floors := _rng.randi_range(floors_min, floors_max)
			var pos: Vector3
			var yaw := 0.0
			match side:
				0:
					pos = Vector3(r.position.x + mid, 0.0, r.end.y - hd)
				1:
					pos = Vector3(r.end.x - mid, 0.0, r.position.y + hd)
					yaw = PI
				2:
					pos = Vector3(r.end.x - hd, 0.0, r.end.y - hd * 2.0 - mid)
					yaw = PI * 0.5
				3:
					pos = Vector3(r.position.x + hd, 0.0, r.position.y + hd * 2.0 + mid)
					yaw = -PI * 0.5
			var info := house(pos, yaw, w, dep, floors, roof, jetty_ns if side < 2 else false)
			_houses.append({"pos": pos, "yaw": yaw, "side": side, "w": w, "eave": info["eave"], "ridge": info["ridge"], "flat": flat})
	return r.grow(-hd * 2.0)


# --- Ground, walls and river ------------------------------------------------------------------

func _ground_and_walls() -> void:
	var holes: Array[Rect2] = [RIVER]
	ground(Rect2(-100.0, -108.0, 200.0, 216.0), holes, 0.0, 18.0, &"stone_light", &"stone_light")
	# The town wall, with a walkable top (the wall-walk) and crenellations on the outer edge.
	var walls: Array[Array] = [[Vector3(0.0, WALL_H, -102.0), Vector3(200.0, WALL_H, 4.0)], [Vector3(-98.0, WALL_H, 0.0), Vector3(4.0, WALL_H, 208.0)], [Vector3(98.0, WALL_H, 0.0), Vector3(4.0, WALL_H, 208.0)],
		[Vector3(-53.0, WALL_H, 102.0), Vector3(94.0, WALL_H, 4.0)], [Vector3(53.0, WALL_H, 102.0), Vector3(94.0, WALL_H, 4.0)], [Vector3(0.0, WALL_H, 102.0), Vector3(12.0, WALL_H - 7.0, 4.0)]]
	for wdef in walls:
		var top := wdef[0] as Vector3
		var size := wdef[1] as Vector3
		var b := Kit.block(self, top, size, &"stone_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"stone_light")
		b.name = "TownWall"
	for i in 50:
		var t := -98.0 + i * 4.0
		for spec: Array in [[Vector3(t, WALL_H + 0.7, -103.4), Vector3(1.6, 1.4, 1.2)], [Vector3(t, WALL_H + 0.7, 103.4), Vector3(1.6, 1.4, 1.2)], [Vector3(-99.4, WALL_H + 0.7, t), Vector3(1.2, 1.4, 1.6)], [Vector3(99.4, WALL_H + 0.7, t), Vector3(1.2, 1.4, 1.6)]]:
			Kit.block(self, spec[0] as Vector3, spec[1] as Vector3, &"stone_light", Layers.WORLD, &"stone_light")
	# Rolling hills and far towers beyond the wall.
	for i in 12:
		var a := float(i) / 12.0 * TAU
		Whimsy.hill(self, Vector3(cos(a) * 190.0, -4.0, sin(a) * 190.0), _rng.randf_range(40.0, 60.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.3
		Whimsy.mountain(self, Vector3(cos(a) * 320.0, -10.0, sin(a) * 320.0), _rng.randf_range(60.0, 90.0), _rng.randf_range(90.0, 140.0), false)


func _river() -> void:
	water(Vector3(0.0, -1.0, -6.0), RIVER.size, 7.0, false)
	basin_at(Vector3(0.0, -1.0, -6.0), RIVER.size, 7.0, &"stone_dark", &"stone_light")
	# Two stone bridges; under the west one, a barnacled alcove with a seed.
	for x: float in [-40.0, 30.0]:
		HighTier.bridge(self, Vector3(x, 0.0, -14.0), Vector3(x, 0.0, 2.0), 7.0, &"stone_light", true, &"stone_dark")
		for z: float in [-9.0, -3.0]:
			Kit.pillar(self, Vector3(x, -0.3, z), 1.4, 7.6, &"stone_dark", &"")
	alcove(Vector3(-40.0, -8.0, -6.0), PI * 0.5, &"stone_dark")
	seed_at(&"w6_seed_river", Vector3(-40.0, -8.0, -6.0))
	# Barges moored along the quays, and ducks.
	for spec: Array in [[-70.0, -9.0], [-10.0, -3.0], [62.0, -9.0]]:
		var barge := Kit.block(self, Vector3(spec[0] as float, -0.4, spec[1] as float), Vector3(10.0, 1.4, 3.6), &"bark_mid", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")
		barge.name = "Barge"
		_batch.place(TownHouse.V + "Prop_Crate.gltf", Vector3(spec[0] as float - 2.0, -0.4, spec[1] as float), 0.3, Vector3.ONE * 1.6)
	for i in 4:
		var duck := Duck.new()
		duck.position = Vector3(-60.0 + i * 36.0, -1.0, -6.0)
		duck.radius = 3.0
		add_child(duck)
	Ambient.fish(self, Vector3(0.0, -4.0, -6.0), 30.0, 10, &"gold")
	critter(Jellyfloat, Vector3(-60.0, -4.0, -6.0))


# --- The blocks of houses ---------------------------------------------------------------------

func _blocks() -> void:
	for ci in COLS.size():
		var c := COLS[ci]
		for ri in SOUTH.size():
			var z := SOUTH[ri]
			if ci == 2:
				continue
			var r := Rect2(c.x, z.x, c.y - c.x, z.y - z.x)
			if ri == 0:
				# The south bank: three-storey houses with roof terraces facing the river.
				house_block(r, 3, 3, true, -1, true)
			else:
				house_block(r, 2, 4, false, [2, -1, -1, 3, -1][ci] if ri == 1 else -1, true)
		for ri in NORTH.size():
			var z := NORTH[ri]
			if ci == 4 and ri == 0:
				continue
			if ci == 1 and ri == 1:
				continue
			var r := Rect2(c.x, z.x, c.y - c.x, z.y - z.x)
			if ri == 0:
				house_block(r, 3, 3, true, -1, true)
			else:
				house_block(r, 2, 4, false, -1, true)


func _gate_plaza() -> void:
	region(Vector3.ZERO)
	add_spawn(&"w6_entrance", Vector3(0.0, 0.0, 92.0), Vector3.FORWARD)
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 98.0)
	add_child(exit)
	sign_post(Vector3(6.0, 0.0, 88.0), "Welcome to Lanternwick!\nFind 3 Star Shards and a stairway\nof light climbs the Lantern Spire.")
	# The Gatehouse Stair up to the wall-walk; a seed waits above the gate arch.
	ramp_tower(Vector3(12.0, 0.0, 89.0), 0.0, WALL_H, 4.0, 3.0, &"stone_light", &"wood_plank", &"stone_light")
	bridge(Vector3(12.0, WALL_H, 91.0), Vector3(12.0, WALL_H, 100.5), 3.0, &"wood_plank")
	seed_at(&"w6_seed_gatehouse", Vector3(0.0, WALL_H, 102.0))
	seed_at(&"w6_seed_wallwalk", Vector3(-98.0, WALL_H, -102.0))
	villager("pike", "Constable Pike", Vector3(-5.0, 0.0, 86.0))
	gloplets(Vector3(0.0, 0.0, 82.0), 8.0, [Vector3(-4.0, 0.0, 0.0), Vector3(4.0, 0.0, -2.0)])
	for spec: Array in [[-12.0, 84.0], [-12.0, 94.0]]:
		_batch.place(TownHouse.V + "Prop_Wagon.gltf", Vector3(spec[0] as float, 0.0, spec[1] as float), 0.2, Vector3.ONE * 1.5)
	add_capture_point("gate", Vector3(0.0, 9.0, 96.0), Vector3(0.0, 4.0, 60.0))


func _market() -> void:
	region(Vector3.ZERO)
	checkpoint(&"w6_cp_square", Vector3(-6.0, 0.0, 48.0))
	# The Lantern Spire; with 3 shards a stairway of light climbs it to the Grand Star.
	Kit.pillar(self, SPIRE + Vector3(0.0, 24.0, 0.0), 1.8, 24.0, &"stone_light", &"gold")
	for k in 4:
		Kit.pillar(self, SPIRE + Vector3(0.0, 4.0 + k * 6.0, 0.0), 2.1, 0.8, &"gold", &"gold", 0)
	for i in 10:
		var a := float(i) / 10.0 * TAU * 1.25
		var step := GhostPlatform.new()
		step.size = Vector3(4.5, 0.6, 4.5)
		step.color_name = &"portal_teal"
		step.position = SPIRE + Vector3(cos(a) * 7.0, 2.4 + i * 2.4, sin(a) * 7.0)
		add_child(step)
		_spire_steps.append(step)
	var star := GoalStar.new()
	star.world_id = WORLD
	star.position = SPIRE + Vector3(0.0, 24.0, 0.0)
	add_child(star)
	for k in 6:
		var a := float(k) / 6.0 * TAU
		Whimsy.lamp(self, SPIRE + Vector3(cos(a) * 10.5, 0.0, sin(a) * 10.5), k % 2 == 0)
	# Market stalls, the baker and the flower seller.
	Whimsy.stall(self, Vector3(9.0, 0.0, 47.0), -0.3, &"roof_red")
	Whimsy.stall(self, Vector3(11.0, 0.0, 62.0), 0.4, &"slime_blue")
	for i in 5:
		Whimsy.flower(self, Vector3(6.0 + i * 1.6, 0.0, 67.0), 0.8, 0.7, [&"candy_pink", &"gold", &"slime_blue"][i % 3] as StringName, false)
	villager("bun", "Baker Bun", Vector3(7.0, 0.0, 50.0), &"w6_found_pin", &"w6_seed_baker", Vector3(98.0, WALL_H + 0.3, -102.0), "Rolling pin")
	villager("rosie", "Rosie", Vector3(4.0, 0.0, 65.0))
	critter(Armorling, Vector3(10.0, 0.5, 56.0))
	# The Old Bell Inn's cellar: shove the crate onto the plate in High Street to hold it open.
	var cellar: Array = secret_cave(Vector3(-11.0, 0.0, 65.0), 0.0, Vector3(10.0, 7.0, 8.0), &"bark_mid", &"gate")
	stone(Vector3(-2.5, 1.2, -1.0), 1.4, 1.2, &"bark_mid", &"wood_plank")
	ledge(Vector3(0.5, 3.0, -2.0), Vector3(2.6, 0.5, 2.2), &"wood_plank")
	ledge(Vector3(3.0, 5.0, 0.0), Vector3(2.2, 0.5, 2.6), &"wood_plank")
	seed_at(&"w6_seed_cellar", Vector3(3.0, 5.0, 0.0))
	_frame = cellar[0]
	region(Vector3.ZERO)
	crate_puzzle(Vector3(-2.0, 0.0, 74.0), Vector3(-11.0, 0.0, 74.0), cellar[1] as VineGate)
	sign_post(Vector3(-15.0, 0.0, 74.0), "Old Bell Inn cellar: weigh down\nthe plate and the door stays open.", PI)
	add_capture_point("market", Vector3(18.0, 16.0, 76.0), Vector3(0.0, 6.0, 54.0))


func _clock_green() -> void:
	region(Vector3.ZERO)
	var c := Vector3(0.0, 0.0, 22.0)
	var top := 26.0
	ramp_tower(c, 0.0, top, 10.0, 4.0, &"stone_light", &"wood_plank", &"stone_light")
	# The clock room on top: four faces, and the shard on its roof (hop up from a ledge).
	Kit.block(self, c + Vector3(0.0, top + 5.0, 0.0), Vector3(6.0, 5.0, 6.0), &"stone_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"roof_red")
	for k in 4:
		var a := float(k) * PI * 0.5
		var dir := Vector3(sin(a), 0.0, cos(a))
		var face := CylinderMesh.new()
		face.top_radius = 2.2
		face.bottom_radius = 2.2
		face.height = 0.3
		var fm := Kit.mesh_instance(self, face, Kit.mat(&"cloth_cream", 0.03), c + Vector3(0.0, top + 2.6, 0.0) + dir * 3.1)
		fm.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
		var hand := Kit.mesh_instance(self, RoundMesh.box(Vector3(0.25, 1.8, 0.1), 0.05), Kit.mat(&"bark_dark"), c + Vector3(0.0, top + 3.1, 0.0) + dir * 3.3)
		hand.basis = Basis.looking_at(dir, Vector3.UP)
	ledge(c + Vector3(4.0, top + 1.8, 4.0), Vector3(2.0, 0.5, 2.0), &"wood_plank")
	shard_at(&"w6_shard_clock", c + Vector3(0.0, top + 5.0, 0.0))
	# The minute hand sticks out far enough to stand on, with a seed at its tip.
	ledge(c + Vector3(0.0, top + 2.0, 4.2), Vector3(0.8, 0.4, 2.4), &"bark_dark")
	seed_at(&"w6_seed_clock", c + Vector3(0.0, top + 2.0, 5.0))
	# Bridges from two of the spiral's landings across to the south-bank roof terraces.
	var rise := top / ceilf(top / (10.0 * tan(deg_to_rad(20.0))))
	bridge(c + Vector3(9.0, rise * 5.0, 6.0), Vector3(22.5, TERRACE, 28.0), 3.0, &"wood_plank")
	bridge(c + Vector3(-9.0, rise * 7.0, -6.0), Vector3(-22.5, TERRACE, 16.0), 3.0, &"wood_plank")
	sign_post(Vector3(-10.0, 0.0, 34.0), "The Clock Tower: up\nto the rooftops!", PI)
	for i in 6:
		Whimsy.tree(self, Vector3(-13.0 + (i % 2) * 26.0, 0.0, 11.0 + (i / 2) * 11.0), tree_kinds[i % tree_kinds.size()], 0.8, i)
	add_capture_point("clock", Vector3(30.0, 30.0, 50.0), Vector3(0.0, 16.0, 22.0))


func _sweeps_run() -> void:
	region(Vector3.ZERO)
	var y := TERRACE
	# Bridges over the alleys join the north-bank terraces into one long run.
	for x: Vector2 in [Vector2(-60.0, -54.0), Vector2(-22.0, -16.0), Vector2(16.0, 22.0)]:
		bridge(Vector3(x.x - 0.5, y, -23.0), Vector3(x.y + 0.5, y, -23.0), 3.0, &"wood_plank")
		washing(Vector3(x.x, y - 4.0, -36.0), Vector3(x.y, y - 4.0, -36.0))
	# The Sky Bridge over the river to the south-bank terraces.
	bridge(Vector3(38.0, y, -19.5), Vector3(38.0, y, 7.5), 3.6, &"wood_plank", true, &"roof_red")
	ledge(Vector3(38.0, y - 4.0, -6.0), Vector3(3.0, 0.5, 3.0), &"wood_plank")
	seed_at(&"w6_seed_skybridge", Vector3(38.0, y - 4.0, -6.0))
	for z: float in [-14.0, 0.0]:
		batling(Vector3(38.0, y - 2.0, z), true)
	# Ways up from the streets: hoists in two alleys and a springy awning by the quay.
	lift(Vector3(-57.0, 0.0, -36.0), y, 8.0)
	lift(Vector3(19.0, 0.0, -36.0), y, 8.0)
	bouncer(Vector3(-30.0, 0.0, -16.0), Springcap.Look.CLOUD, y + 2.0)
	checkpoint(&"w6_cp_quay", Vector3(-30.0, 0.0, -15.0))
	checkpoint(&"w6_cp_rooftops", Vector3(-72.0, y, -23.0))
	villager("soot", "Soot", Vector3(-66.0, y, -23.0))
	# The run ends at the mill yard: chimney stacks climb to the shard.
	bridge(Vector3(53.5, y, -30.0), Vector3(62.0, y + 1.0, -30.0), 3.0, &"wood_plank")
	var stacks: Array[Vector3] = [Vector3(64.0, y + 1.0, -30.0), Vector3(67.0, y + 3.2, -35.5), Vector3(64.0, y + 5.4, -41.0), Vector3(68.5, y + 7.6, -45.0)]
	for s in stacks:
		Kit.pillar(self, s, 1.9, s.y, &"roof_red", &"stone_dark")
	shard_at(&"w6_shard_sweep", stacks[stacks.size() - 1])
	place(Puffcap.new(), Vector3(-40.0, y + 0.5, -24.0))
	critter(Armorling, Vector3(0.0, y + 0.5, -24.0))
	add_capture_point("rooftops", Vector3(-20.0, y + 18.0, 10.0), Vector3(-30.0, y, -30.0))


func _church() -> void:
	region(Vector3.ZERO)
	var c := Vector3(-38.0, 0.0, -64.0)
	checkpoint(&"w6_cp_church", c + Vector3(0.0, 0.0, 12.0))
	# St. Wick's: a stone nave, a steeple and a little graveyard garden.
	Kit.block(self, c + Vector3(-6.0, 10.0, -2.0), Vector3(12.0, 10.0, 16.0), &"stone_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	var rb := Models.model_bounds(TownHouse.V + "Roof_RoundTiles_6x8.gltf")
	_batch.add(TownHouse.V + "Roof_RoundTiles_6x8.gltf", Transform3D(Basis.from_scale(Vector3(13.0 / rb.size.x, 6.0 / rb.size.y, 17.0 / rb.size.z)), c + Vector3(-6.0, 9.8, -2.0) - Vector3(rb.get_center().x * 13.0 / rb.size.x, rb.position.y * 6.0 / rb.size.y, rb.get_center().z * 17.0 / rb.size.z)))
	Kit.block(self, c + Vector3(0.0, 18.0, 8.0), Vector3(6.0, 18.0, 6.0), &"stone_light", Layers.WORLD | Layers.CAMERA_BLOCKER, &"stone_light")
	var spire := CylinderMesh.new()
	spire.top_radius = 0.0
	spire.bottom_radius = 3.6
	spire.height = 6.0
	spire.radial_segments = 4
	var sp := Kit.mesh_instance(self, spire, Kit.mat(&"stone_dark", 0.03), c + Vector3(0.0, 21.0, 8.0))
	sp.rotation.y = PI * 0.25
	seed_at(&"w6_seed_belfry", c + Vector3(-2.0, 18.0, 6.0))
	# From the Sweep's Run back terraces, a plank bridge drops onto the steeple roof.
	bridge(Vector3(-38.0, TERRACE, -47.0), Vector3(-38.0, 18.0, -53.4), 3.0, &"wood_plank")
	# The bells: ring them in order and the crypt opens.
	var bells := bell_puzzle(c + Vector3(10.0, 0.0, 2.0), 4.0, "St. Wick's bells: pink, gold, blue\nopen the crypt.")
	var crypt: Array = secret_cave(c + Vector3(10.0, 0.0, -6.0), PI, Vector3(12.0, 9.0, 9.0), &"stone_light", &"gate")
	stone(Vector3(-4.5, 1.2, -1.5), 1.6, 1.2, &"stone_light", &"moss")
	ledge(Vector3(-1.5, 3.2, -3.0), Vector3(2.8, 0.5, 2.4), &"stone_light")
	crumble(Vector3(1.8, 5.2, -2.0), Vector3(2.6, 0.5, 2.6), CrumblePlatform.Look.CLOUD)
	ledge(Vector3(4.6, 7.2, 0.5), Vector3(2.6, 0.5, 2.8), &"stone_light")
	shard_at(&"w6_shard_crypt", Vector3(4.6, 7.2, 0.5))
	_frame = crypt[0]
	region(Vector3.ZERO)
	var crypt_door := crypt[1] as VineGate
	bells.solved.connect(func() -> void:
		crypt_door.set_closed(false)
		if hud != null:
			hud.show_banner("The crypt of St. Wick's opens!", 2.0))
	villager("toll", "Toll", c + Vector3(4.0, 0.0, 8.0))
	for i in 6:
		var g := Kit.block(self, c + Vector3(6.0 + (i % 3) * 3.0, 1.0, 6.0 + (i / 3) * 3.0), Vector3(1.2, 1.0, 0.3), &"stone_dark", Layers.WORLD, &"")
		g.name = "Gravestone"
	place(Puffcap.new(), c + Vector3(-4.0, 0.5, 10.0))
	place(Puffcap.new(), c + Vector3(12.0, 0.5, 8.0))
	critter(Armorling, c + Vector3(6.0, 0.5, 12.0))
	add_capture_point("church", c + Vector3(24.0, 14.0, 24.0), c + Vector3(0.0, 6.0, 0.0))


func _mill() -> void:
	region(Vector3.ZERO)
	var c := Vector3(75.0, 0.0, -33.0)
	var info := house(c + Vector3(0.0, 0.0, -2.0), 0.0, 3, 3, 3, &"pitched", false)
	seed_at(&"w6_seed_mill", Vector3(c.x - 2.0, float(info["ridge"]), c.z - 2.0))
	# The water wheel turns in the river.
	var wheel := Node3D.new()
	wheel.position = Vector3(c.x, 1.0, -10.0)
	add_child(wheel)
	var rim := TorusMesh.new()
	rim.inner_radius = 3.4
	rim.outer_radius = 4.0
	var rm := Kit.mesh_instance(wheel, rim, Kit.mat(&"bark_mid", 0.03))
	rm.rotation.z = PI * 0.5
	for k in 8:
		var paddle := Kit.mesh_instance(wheel, RoundMesh.box(Vector3(2.0, 0.2, 7.6), 0.05), Kit.mat(&"wood_plank"))
		paddle.rotation.x = float(k) / 8.0 * PI
	wheel.set_meta(&"spin", true)
	create_tween().set_loops().tween_property(wheel, "rotation:x", -TAU, 8.0).from(0.0)
	boulderkin(Vector3(84.0, 0.5, -43.0), &"stone_dark", &"moss", &"portal_teal")
	villager("lumi", "Lumi", Vector3(30.0, 0.0, -16.0), &"w6_found_hook", &"w6_seed_lamplighter", Vector3(34.0, -7.7, -6.0), "Lantern hook")


func _courtyards() -> void:
	region(Vector3.ZERO)
	# Two courtyards open off the alleys: a garden with a chest, and one with a Mimic.
	var west := Rect2(COLS[0].x, SOUTH[1].x, COLS[0].y - COLS[0].x, SOUTH[1].y - SOUTH[1].x).grow(-TownHouse.MOD * 2.0)
	var wc := Vector3(west.get_center().x, 0.0, west.get_center().y)
	chest(wc + Vector3(-3.0, 0.0, -2.0), 0.4, &"w6_seed_courtyard_west")
	big_gloplet(wc + Vector3(3.0, 0.5, 2.0), preload("res://data/enemies/pink_gloplet.tres"))
	for i in 4:
		Whimsy.flower(self, wc + Vector3(-4.0 + i * 2.5, 0.0, 3.5), 0.9, 0.7, [&"candy_pink", &"gold"][i % 2] as StringName, false)
	var east := Rect2(COLS[3].x, SOUTH[1].x, COLS[3].y - COLS[3].x, SOUTH[1].y - SOUTH[1].x).grow(-TownHouse.MOD * 2.0)
	var ec := Vector3(east.get_center().x, 0.0, east.get_center().y)
	chest(ec + Vector3(3.0, 0.0, -2.0), -0.4, &"w6_seed_courtyard_east")
	critter(Mimic, ec + Vector3(-3.0, 0.5, 1.0))
	for cy: Vector3 in [wc, ec]:
		washing(cy + Vector3(-5.0, 7.0, 0.0), cy + Vector3(5.0, 7.0, 0.0))
		for k in 3:
			_batch.place(TownHouse.V + "Prop_Crate.gltf", cy + Vector3(5.0, 0.0, -4.0 + k * 1.2), 0.2 * k, Vector3.ONE * 1.4)


func _streets() -> void:
	region(Vector3.ZERO)
	# Lamps along the main streets (every other one lit) and washing over the alleys.
	var n := 0
	for z: float in [40.0, 74.0, 4.0, -16.0, -50.0, -78.0]:
		for i in 14:
			var x := -84.0 + i * 13.0
			if absf(x) < 18.0 and z in [40.0, 74.0]:
				continue
			Whimsy.lamp(self, Vector3(x, 0.0, z + (3.0 if z > 0.0 else -3.0)), n % 3 == 0)
			n += 1
	for ci in COLS.size() - 1:
		var x0 := COLS[ci].y
		var x1 := COLS[ci + 1].x
		for z: float in [58.0, 88.0, -64.0, -90.0]:
			if (ci == 1 or ci == 2) and z == 58.0:
				continue
			if ci <= 1 and z == -64.0:
				continue
			washing(Vector3(x0, 9.0, z), Vector3(x1, 9.0, z))
	# A few locals and troublemakers about town.
	batling(Vector3(-36.0, 8.0, 40.0))
	batling(Vector3(36.0, 8.0, 74.0))
	critter(Mimic, Vector3(-19.0, 0.5, 88.0))
	animals(Bunny, Vector3(0.0, 0.0, 22.0), 12.0, 4)
	birds(Vector3.ZERO, 70.0, 40.0, 8)
	add_capture_point("streets", Vector3(-19.0, 3.0, 76.0), Vector3(-19.0, 6.0, 40.0))
	add_capture_point("overview", Vector3(110.0, 70.0, 110.0), Vector3(0.0, 0.0, 0.0))


# --- Build 6: the alleys (Ashwin: "ways to get to the tops of the buildings from the alleys...
# the alleys are really boring") ---------------------------------------------------------------
# Every alley gets a ladder up one wall and a crate-and-ledge climb up the other (or a wall-jump
# between them), so nobody is ever stuck below; and something to find or do in each one.

func _alley_houses(side: int, x: float, z0: float, z1: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in _houses:
		var p := h["pos"] as Vector3
		if int(h["side"]) == side and absf(p.x - x) < 0.2 and p.z > z0 and p.z < z1:
			out.append(h)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["pos"] as Vector3).z < (b["pos"] as Vector3).z)
	return out


## Crates, then ledges every 3 m up the wall at x (facing dir), to the roof at `eave`.
## Returns the top ledge's top.
func _ledge_climb(x: float, dir: float, z: float, eave: float) -> Vector3:
	Kit.block(self, Vector3(x + dir * 0.8, 1.2, z - 1.6), Vector3(1.6, 1.2, 1.6), &"wood_warm", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")
	Kit.block(self, Vector3(x + dir * 0.8, 2.4, z), Vector3(1.6, 2.4, 1.6), &"wood_warm", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")
	var top := Vector3(x + dir * 0.8, 2.4, z)
	var h := 5.2
	var k := 0
	while h < eave - 0.4:
		top = Vector3(x + dir * 1.0, h, z + (1.6 if k % 2 == 0 else -1.6))
		Kit.block(self, top, Vector3(2.0, 0.4, 2.4), &"bark_mid", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")
		# A little bracket under each ledge so it reads as part of the wall.
		Kit.block(self, top + Vector3(-dir * 0.4, -0.4, 0.0), Vector3(1.0, 0.8, 0.3), &"bark_dark", 0, &"")
		h += 3.0
		k += 1
	return top


func _alleys() -> void:
	region(Vector3.ZERO)
	var hd := TownHouse.MOD
	var rows: Array[Vector2] = []
	rows.append_array(SOUTH)
	rows.append_array(NORTH)
	var n := 0
	var seeds := 0
	var folk: Array[Array] = [["mags", "Mags"], ["tom", "Old Tom"]]
	for ci in COLS.size() - 1:
		var x0 := COLS[ci].y
		var x1 := COLS[ci + 1].x
		var xm := (x0 + x1) * 0.5
		for row in rows:
			var left := _alley_houses(2, x0 - hd, row.x, row.y)
			var right := _alley_houses(3, x1 + hd, row.x, row.y)
			if left.is_empty() and right.is_empty():
				continue
			var zm := (row.x + row.y) * 0.5
			# A ladder up the west wall to the roof.
			if not left.is_empty():
				var lh := left[left.size() / 2]
				ladder(Vector3(x0, 0.0, (lh["pos"] as Vector3).z), float(lh["eave"]), PI * 0.5)
			# Crates and ledges up the east wall.
			var top := Vector3(xm, 0.0, zm)
			if not right.is_empty():
				var rh := right[0] if right.size() == 1 else right[right.size() - 1]
				top = _ledge_climb(x1, -1.0, (rh["pos"] as Vector3).z, float(rh["eave"]))
			# Something to find or do in every alley.
			match n % 4:
				0:
					if seeds < 8 and top.y > 3.0:
						seeds += 1
						seed_at(StringName("w6_seed_alley_%d" % seeds), top)
					place(Puffcap.new(), Vector3(xm, 0.5, zm + 4.0))
				1:
					if seeds < 8:
						seeds += 1
						# Hit the crystal and a stair of light climbs to a lantern-lit seed.
						var sw := CrystalSwitch.new()
						sw.position = Vector3(xm, 0.0, zm - 5.0)
						add_child(sw)
						var steps: Array[GhostPlatform] = []
						for i in 4:
							var gp := GhostPlatform.new()
							gp.size = Vector3(2.4, 0.4, 2.4)
							gp.color_name = &"gold"
							gp.position = Vector3(xm, 2.6 + i * 2.6, zm - 2.0 + i * 2.2)
							add_child(gp)
							steps.append(gp)
						seed_at(StringName("w6_seed_alley_%d" % seeds), Vector3(xm, 11.0, zm + 6.8))
						Whimsy.lamp(self, Vector3(xm, 0.0, zm - 7.0), true)
						sw.lit_changed.connect(func(on: bool) -> void:
							for st in steps:
								st.set_solid(on))
				2:
					if not folk.is_empty():
						var f: Array = folk.pop_front()
						villager(str(f[0]), str(f[1]), Vector3(xm, 0.0, zm))
					else:
						critter(Mimic, Vector3(xm, 0.5, zm + 3.0))
					heart_at(Vector3(xm + 1.5, 0.0, zm - 3.0))
				3:
					batling(Vector3(xm, 7.5, zm), true)
					heart_bush(Vector3(xm, 0.0, zm + 6.0))
			# Barrels, crates, flower pots and a wall lamp.
			for i in 3:
				var zz := zm - 9.0 + i * 9.0
				if absf(zz - zm) < 1.0:
					continue
				prop(&"barrel", Vector3(x0 + 0.8, 0.0, zz), _rng.randf() * TAU, 1.2)
				_batch.place(TownHouse.V + "Prop_Crate.gltf", Vector3(x1 - 0.9, 0.0, zz + 2.5), _rng.randf() * TAU, Vector3.ONE * 1.3)
			Whimsy.flower(self, Vector3(x0 + 0.7, 0.0, zm + 7.5), 0.7, 0.6, [&"candy_pink", &"gold", &"slime_blue"][n % 3] as StringName, false)
			n += 1
	# Ladders up the inside of the town wall to the wall-walk, from the west and east streets.
	for z: float in [-40.0, 20.0, 60.0]:
		ladder(Vector3(-96.0, 0.0, z), WALL_H, PI * 0.5)
		ladder(Vector3(96.0, 0.0, z), WALL_H, -PI * 0.5)


## Build 7 Vinelash: hook flowers just off the roof terraces on both banks, catchable from the quays.
func _vine_routes() -> void:
	region(Vector3.ZERO)
	for b: Vector3 in [Vector3(-75.0, TERRACE, -17.6), Vector3(0.0, TERRACE, -17.6), Vector3(-70.0, TERRACE, 5.6), Vector3(70.0, TERRACE, 5.6)]:
		hook(b)


# --- Build 7: six stars per world -----------------------------------------------------------------

func _more_stars() -> void:
	region(Vector3.ZERO)
	# Errand: Widow Wick's locket went off the west bridge into the river (dive for it).
	errand_star("wick", "Widow Wick", Vector3(-46.0, 0.0, 6.0), &"w6_found_locket", &"w6_shard_errand", Vector3(-58.0, -7.7, -6.0), "Silver locket")
	# Hidden: the walled garden in the north-west block has no door at all. Drop in from the
	# rooftops; a ladder gets you out again.
	var yard := Rect2(COLS[0].x, NORTH[1].x, COLS[0].y - COLS[0].x, NORTH[1].y - NORTH[1].x).grow(-TownHouse.MOD * 2.0)
	var yc := Vector3(yard.get_center().x, 0.0, yard.get_center().y)
	for i in 5:
		Whimsy.flower(self, yc + Vector3(-5.0 + i * 2.5, 0.0, 3.0), 1.0, 0.8, [&"candy_pink", &"gold", &"slime_blue"][i % 3] as StringName, false)
	stone(yc + Vector3(-3.0, 1.4, -2.0), 1.6, 1.4, &"stone_light", &"moss")
	ledge(yc + Vector3(0.0, 3.4, -3.0), Vector3(2.6, 0.5, 2.4), &"wood_plank")
	ledge(yc + Vector3(3.0, 5.6, -1.0), Vector3(2.4, 0.5, 2.6), &"wood_plank")
	shard_at(&"w6_shard_garden", yc + Vector3(3.0, 5.6, -1.0))
	# The way out: a ladder up the back of a west-side house to its roof.
	var back: Dictionary = {}
	for h in _houses:
		var hp := h["pos"] as Vector3
		if int(h["side"]) == 3 and absf(hp.x - (COLS[0].x + TownHouse.MOD)) < 0.2 and hp.z > yard.position.y and hp.z < yard.end.y:
			back = h
	if not back.is_empty():
		ladder(Vector3(yard.position.x, 0.0, (back["pos"] as Vector3).z), float(back["eave"]), PI * 0.5)
	# Puzzle: the Bell Inn's barrel lift. Shove the barrel-crate onto the plate in Lantern Lane and
	# the goods hoist carries you to a star on the inn's roof.
	var hoist := lift(Vector3(-19.0, 0.0, 40.0), 18.0, 8.0)
	hoist.set_physics_process(false)
	var crate := PushBlock.new()
	crate.position = Vector3(-30.0, 0.0, 40.0)
	add_child(crate)
	var plate := PressurePlate.new()
	plate.position = Vector3(-24.0, 0.0, 40.0)
	add_child(plate)
	plate.changed.connect(func(on: bool) -> void: hoist.set_physics_process(on))
	Kit.block(self, Vector3(-19.0, 18.0, 46.0), Vector3(4.0, 0.6, 4.0), &"wood_plank", Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	shard_at(&"w6_shard_hoist", Vector3(-19.0, 18.0, 46.0))
	sign_post(Vector3(-26.0, 0.0, 43.0), "Goods hoist: runs while the plate\nis weighed down.", PI)
	# Build 7: the six new monsters, spread across the worlds.
	critter(Hexwizard, Vector3(-30.0, 0.05, -60.0))
	critter(Wispghost, Vector3(-57.0, 1.0, 56.0))
	critter(Hexwizard, Vector3(70.0, 0.05, 88.0))
