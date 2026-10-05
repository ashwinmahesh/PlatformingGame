class_name OpenWorld
extends Level
## Base for the Build 4 open worlds: a central area with regions around it, laid out in
## region-local coordinates (region(origin, yaw) sets the frame). Star Shards collected in any
## order open the world's goal. Helpers build big, low, forgiving platforms (Ashwin: "bigger
## platforms, lower heights") and fill the world with life (grass, animals, birds, butterflies).

## Build 5 pass (Ashwin: "make the platforms we can jump on larger... bring the heights down"):
## free-standing platforms from these helpers are widened by this factor.
const PLATFORM_GROW := 1.35

## Build 6 asset swap: jump platforms and moving platforms wear KayKit Platformer pieces in this
## colour (green, blue, red, yellow, neutral); &"" keeps the plain rounded blocks.
var platform_colour: StringName = &"green"

var world_id: StringName
var floor_y: float = -14.0
var lock: ShardLock
## Per-world top colours for blocks (a desert has no grassy tops) and grass density per m².
var tops: Dictionary[StringName, StringName] = {}
var grass_density: float = 1.0 / 7.0
## Region name -> centre, for "section_entered" telemetry.
var regions: Dictionary[String, Vector3] = {}
var _region_now: String = ""
var _frame: Transform3D = Transform3D.IDENTITY
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _grass_points: Array[Transform3D] = []
var _flower_points: Array[Transform3D] = []


func region(origin: Vector3, yaw_deg: float = 0.0) -> void:
	_frame = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), origin)


func P(local: Vector3) -> Vector3:
	return _frame * local


func Y(local_yaw: float = 0.0) -> float:
	return _frame.basis.get_euler().y + local_yaw


## Rotates a local size so axis-aligned boxes stay axis-aligned for 90° region turns.
func S(size: Vector3) -> Vector3:
	var x := _frame.basis * Vector3(size.x, 0.0, 0.0)
	var z := _frame.basis * Vector3(0.0, 0.0, size.z)
	return Vector3(absf(x.x) + absf(z.x), size.y, absf(x.z) + absf(z.z))


func top_of(color: StringName) -> StringName:
	return tops.get(color, Kit.TOPS.get(color, &""))


## Widens platform-like sizes (both sides under `limit`, thin enough to stand on, not walls).
func grown(size: Vector3, limit: float = 8.0, max_thick: float = 2.6) -> Vector3:
	if size.x < limit and size.z < limit and size.y <= max_thick:
		return Vector3(size.x * PLATFORM_GROW, size.y, size.z * PLATFORM_GROW)
	return size


func make_lock() -> void:
	var w := Progress.world_def(world_id)
	lock = ShardLock.new()
	lock.world_id = world_id
	lock.required = w.shards_required if w != null else 3
	add_child(lock)


# --- Terrain ----------------------------------------------------------------------------------

## Flat ground with rectangular holes (ponds, gorges), built from a few sharp-edged boxes so the
## top reads as one surface with no seams. Rects are world XZ (x, z, width, depth).
func ground(outer: Rect2, holes: Array[Rect2], top_y: float, depth: float, color: StringName, top_color: StringName, grass: float = 0.0) -> void:
	var xs: Array[float] = [outer.position.x, outer.end.x]
	for h in holes:
		xs.append(clampf(h.position.x, outer.position.x, outer.end.x))
		xs.append(clampf(h.end.x, outer.position.x, outer.end.x))
	xs.sort()
	var m := Kit.mat(color, 0.0, top_color)
	for i in xs.size() - 1:
		var x0 := xs[i]
		var x1 := xs[i + 1]
		if x1 - x0 < 0.01:
			continue
		var cx := (x0 + x1) * 0.5
		var cuts: Array[Vector2] = []
		for h in holes:
			if h.position.x < cx and h.end.x > cx:
				cuts.append(Vector2(h.position.y, h.end.y))
		cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var z := outer.position.y
		for c in cuts:
			if c.x > z:
				_ground_box(Rect2(x0, z, x1 - x0, c.x - z), top_y, depth, m, grass)
			z = maxf(z, c.y)
		if z < outer.end.y:
			_ground_box(Rect2(x0, z, x1 - x0, outer.end.y - z), top_y, depth, m, grass)


func _ground_box(r: Rect2, top_y: float, depth: float, m: Material, grass: float) -> void:
	var c := Vector3(r.get_center().x, top_y - depth * 0.5, r.get_center().y)
	var body := Kit.static_body(self, c)
	var shape := BoxShape3D.new()
	shape.size = Vector3(r.size.x, depth, r.size.y)
	Kit.add_shape(body, shape)
	var bm := BoxMesh.new()
	bm.size = shape.size
	Kit.mesh_instance(body, bm, m)
	if grass > 0.0:
		_add_grass_area(Vector3(c.x, top_y, c.z), r.size, int(r.size.x * r.size.y * grass))


## A plateau whose sides run down to the floor. Returns the body.
func plat(top_local: Vector3, size_xz: Vector2, color: StringName = &"bark_mid", grass: int = -1) -> StaticBody3D:
	var top := P(top_local)
	var size := S(Vector3(size_xz.x, top.y - floor_y, size_xz.y))
	var body := Kit.block(self, top, size, color, Layers.WORLD | Layers.CAMERA_BLOCKER, top_of(color))
	if grass != 0:
		_add_grass_area(top, Vector2(size.x, size.z), grass if grass > 0 else int(size.x * size.z * grass_density))
	return body


## A round plateau (pillar to the floor).
func disc(top_local: Vector3, radius: float, color: StringName = &"bark_mid", top_color: StringName = &"grass_mid", grass: int = -1) -> StaticBody3D:
	var top := P(top_local)
	var body := Kit.pillar(self, top, radius, top.y - floor_y, color, top_color)
	if grass != 0:
		_add_grass_disc(top, radius * 0.92, grass if grass > 0 else int(radius * radius * PI * grass_density))
	return body


## A floating ledge of `size` (y = thickness) with its top at top_local.
func ledge(top_local: Vector3, size: Vector3, color: StringName = &"stone_light", yaw: float = 0.0) -> StaticBody3D:
	var platformish := grown(size) != size
	size = grown(size)
	var actual := S(size) if yaw == 0.0 else size
	var b := Kit.block(self, P(top_local), actual, color, Layers.WORLD | Layers.CAMERA_BLOCKER, top_of(color))
	if yaw != 0.0:
		b.rotation.y = Y(yaw)
	if platformish:
		skin_platform(b, actual)
	return b


## Swaps a platform body's rounded block for a KayKit Platformer piece stretched to the same box.
func skin_platform(body: Node3D, size: Vector3) -> void:
	if platform_colour == &"":
		return
	for n in body.get_children():
		if n is MeshInstance3D:
			(n as MeshInstance3D).visible = false
	var long := maxf(size.x, size.z) > minf(size.x, size.z) * 2.2
	var piece := ("platform_6x2x1_%s" if long else "platform_4x4x1_%s") % platform_colour
	var holder := Node3D.new()
	body.add_child(holder)
	var fit := size
	if long and size.z > size.x:
		holder.rotation.y = PI * 0.5
		fit = Vector3(size.z, size.y, size.x)
	Models.fit(holder, "%s%s/%s.gltf" % [Models.KK_PLATFORM, platform_colour, piece], Vector3(0.0, size.y * 0.5, 0.0), fit)


## A round floating stepping-stone.
func stone(top_local: Vector3, radius: float, thickness: float = 1.6, color: StringName = &"stone_light", top_color: StringName = &"moss") -> StaticBody3D:
	if radius < 4.0:
		radius *= 1.3
	return Kit.pillar(self, P(top_local), radius, thickness, color, top_color)


## A gentle ramp between two heights along local -Z, width w.
func ramp(start_local: Vector3, length: float, rise: float, w: float, color: StringName = &"bark_mid") -> StaticBody3D:
	var b := Kit.ramp(self, Vector3.ZERO, w, length, rise, color)
	var start := P(start_local)
	var mid_off := b.position
	b.position = start + Basis(Vector3.UP, Y()) * mid_off
	b.rotation.y = Y()
	return b


## A little hut with one doorway (hidden areas). The door is &"break" (a cracked wall: 3 slashes
## or a Plunge), &"bramble" (Fireball) or &"gate" (opened by a puzzle). Inside is P(base_local).
## Returns the door.
func alcove(base_local: Vector3, yaw: float, color: StringName, door: StringName = &"break") -> Node3D:
	var root := Node3D.new()
	root.position = P(base_local)
	root.rotation.y = Y(yaw)
	add_child(root)
	var top := top_of(color)
	var layers := Layers.WORLD | Layers.CAMERA_BLOCKER
	Kit.block(root, Vector3(0.0, 4.0, -2.5), Vector3(6.0, 4.0, 1.0), color, layers, top)
	Kit.block(root, Vector3(-2.5, 4.0, 0.0), Vector3(1.0, 4.0, 6.0), color, layers, top)
	Kit.block(root, Vector3(2.5, 4.0, 0.0), Vector3(1.0, 4.0, 6.0), color, layers, top)
	Kit.block(root, Vector3(0.0, 5.0, 0.3), Vector3(6.6, 1.0, 6.8), color, layers, top)
	match door:
		&"bramble":
			var b := Bramble.new()
			b.size = Vector3(4.0, 4.0, 1.0)
			b.position = Vector3(0.0, 0.0, 2.5)
			root.add_child(b)
			return b
		&"gate":
			var g := VineGate.new()
			g.width = 4.2
			g.position = Vector3(0.0, 0.0, 2.6)
			root.add_child(g)
			g.set_closed.call_deferred(true)
			return g
	var w := BreakableWall.new()
	w.size = Vector3(4.0, 4.0, 1.0)
	w.color_name = color
	w.position = Vector3(0.0, 0.0, 2.5)
	root.add_child(w)
	return w


## Build 6 (Ashwin: "make the secret areas more expansive... each with some platforming"): a big
## walled room (size: width, height, depth) with one doorway on its local +Z side, closed by
## &"break", &"bramble", &"gate" or &"open". The current frame moves inside the room, with its
## origin at the floor centre, so the caller lays out the platforming with ledge()/stone()/
## seed_at() in room coordinates; restore it with `_frame = saved` (the return value's [0]).
## Returns [saved_frame, door].
func secret_cave(center_local: Vector3, yaw: float, size: Vector3, color: StringName, door: StringName = &"break") -> Array:
	var saved := _frame
	var origin := P(center_local)
	var basis := Basis(Vector3.UP, Y(yaw))
	_frame = Transform3D(basis, origin)
	var t := top_of(color)
	var layers := Layers.WORLD | Layers.CAMERA_BLOCKER
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var walls: Array[Array] = [[Vector3(0.0, size.y, -hz), Vector3(size.x + 2.0, size.y, 1.0)], [Vector3(-hx, size.y, 0.0), Vector3(1.0, size.y, size.z)], [Vector3(hx, size.y, 0.0), Vector3(1.0, size.y, size.z)],
		[Vector3(-hx * 0.5 - 1.25, size.y, hz), Vector3(hx - 2.5 + 1.0, size.y, 1.0)], [Vector3(hx * 0.5 + 1.25, size.y, hz), Vector3(hx - 2.5 + 1.0, size.y, 1.0)], [Vector3(0.0, size.y, hz), Vector3(5.0, size.y - 4.2, 1.0)]]
	for w in walls:
		var b := Kit.block(self, P(w[0] as Vector3), S(w[1] as Vector3), color, layers, t)
		b.name = "CaveWall"
	Kit.block(self, P(Vector3(0.0, size.y + 1.0, 0.0)), S(Vector3(size.x + 2.0, 1.0, size.z + 2.0)), color, layers, t)
	Kit.block(self, P(Vector3(0.0, 0.15, 0.0)), S(Vector3(size.x, 0.3, size.z)), color, layers, t)
	var light := OmniLight3D.new()
	light.light_color = Palette.color(&"gold")
	light.light_energy = 1.3
	light.omni_range = maxf(size.x, size.z)
	light.position = P(Vector3(0.0, size.y * 0.7, 0.0))
	add_child(light)
	var d: Node3D = null
	match door:
		&"bramble":
			var br := Bramble.new()
			br.size = Vector3(5.0, 4.2, 1.0)
			br.position = P(Vector3(0.0, 0.0, hz))
			br.rotation.y = Y()
			add_child(br)
			d = br
		&"gate":
			var g := VineGate.new()
			g.width = 5.2
			g.position = P(Vector3(0.0, 0.0, hz + 0.1))
			g.rotation.y = Y()
			add_child(g)
			g.set_closed.call_deferred(true)
			d = g
		&"break":
			var w := BreakableWall.new()
			w.size = Vector3(5.0, 4.2, 1.0)
			w.color_name = color
			w.position = P(Vector3(0.0, 0.0, hz))
			w.rotation.y = Y()
			add_child(w)
			d = w
	return [saved, d]


## Build 6 puzzle kits ---------------------------------------------------------------------------

## Three coloured bells to ring in order (sword, Fireball or Thunderclap). Returns the sequence.
func bell_puzzle(center_local: Vector3, radius: float, hint: String) -> BellSequence:
	var bells := BellSequence.new()
	bells.order = [0, 1, 2]
	add_child(bells)
	var cols: Array[StringName] = [&"candy_pink", &"gold", &"slime_blue"]
	for i in 3:
		var a := -PI * 0.5 + (i - 1) * 0.7
		var post := center_local + Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		var b := CrystalSwitch.new()
		b.position = P(post)
		add_child(b)
		Kit.blob(self, P(post + Vector3(0.0, 2.6, 0.0)), 0.35, cols[i])
		bells.add(b)
	sign_post(center_local + Vector3(0.0, 0.0, radius * 0.4), hint)
	return bells


## A crate to shove onto a plate; the plate holds `door` open while pressed.
func crate_puzzle(crate_local: Vector3, plate_local: Vector3, door: VineGate) -> void:
	var crate := PushBlock.new()
	crate.position = P(crate_local)
	add_child(crate)
	var plate := PressurePlate.new()
	plate.position = P(plate_local)
	add_child(plate)
	plate.changed.connect(func(on: bool) -> void: door.set_closed(not on))


## A villager; with an errand, `item_local` places the lost thing and talking hands over `reward`.
func villager(id: String, display: String, base_local: Vector3, errand: StringName = &"", reward: StringName = &"", item_local: Vector3 = Vector3.ZERO, item_name: String = "") -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.display_name = display
	n.errand_flag = errand
	n.reward_seed = reward
	n.position = P(base_local)
	add_child(n)
	if errand != &"":
		var item := ErrandItem.new()
		item.flag = errand
		item.label_text = item_name
		item.position = P(item_local)
		add_child(item)
	return n


func water(center_local: Vector3, size: Vector2, depth: float = 5.0) -> Area3D:
	var s := S(Vector3(size.x, 0.0, size.y))
	return Kit.water(self, P(center_local), Vector2(s.x, s.z), depth)


func mover(top_local: Vector3, size: Vector3, travel_local: Vector3, period: float, color: StringName = &"wood_plank", phase: float = 0.0, spin: float = 0.0) -> MovingPlatform:
	var m := MovingPlatform.new()
	m.rounded = false
	m.size = grown(size, 10.0, 99.0)
	m.travel = _frame.basis * travel_local
	m.period = period
	m.phase = phase
	m.spin_speed = spin
	m.color_name = color
	m.position = P(top_local) + Vector3.DOWN * size.y * 0.5
	m.rotation.y = Y()
	add_child(m)
	skin_platform(m, m.size)
	return m


func crumble(top_local: Vector3, size: Vector3, look: CrumblePlatform.Look = CrumblePlatform.Look.CLOUD) -> CrumblePlatform:
	var c := CrumblePlatform.new()
	c.size = grown(size)
	c.look = look
	c.position = P(top_local)
	add_child(c)
	return c


func bouncer(base_local: Vector3, look: Springcap.Look = Springcap.Look.MUSHROOM, land_h: float = 0.0, plunge_h: float = 0.0) -> Springcap:
	var s := Springcap.new()
	s.look = look
	s.land_height = land_h
	s.plunge_height = plunge_h
	s.position = P(base_local)
	add_child(s)
	return s


func updraft(base_local: Vector3, size: Vector3, lift: float = 9.0, look: StringName = &"wind") -> Updraft:
	var u := Updraft.new()
	u.size = size
	u.lift = lift
	u.look = look
	u.position = P(base_local)
	add_child(u)
	return u


# --- Things -----------------------------------------------------------------------------------

func prop(id: StringName, base_local: Vector3, yaw: float = 0.0, scale_mul: float = 1.0, collide: bool = true, leaf: StringName = &"") -> Node3D:
	return Props.spawn(self, id, P(base_local), Y(yaw), scale_mul, collide, leaf)


func sign_post(base_local: Vector3, text: String, yaw: float = 0.0) -> void:
	Props.spawn(self, &"sign", P(base_local), Y(yaw), 1.6, false)
	var l := Kit.label(self, P(base_local) + Vector3(0.0, 2.4, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func checkpoint(id: StringName, base_local: Vector3) -> void:
	var cp := Checkpoint.new()
	cp.checkpoint_id = id
	cp.world_id = world_id
	cp.position = P(base_local + Vector3(3.0, 0.0, 0.0))
	add_child(cp)
	add_spawn(id, P(base_local), Basis(Vector3.UP, Y()) * Vector3.FORWARD)


func seed_at(id: StringName, base_local: Vector3) -> void:
	Pickup.spawn_seed(self, P(base_local), id)


func shard_at(id: StringName, base_local: Vector3) -> void:
	Pickup.spawn_shard(self, P(base_local), id)


func heart_at(base_local: Vector3) -> void:
	Pickup.spawn_heart(self, P(base_local) + Vector3.UP * 0.4)


func heart_bush(base_local: Vector3) -> void:
	prop(&"bush_large", base_local, _rng.randf() * TAU, 1.0, false)
	heart_at(base_local + Vector3(0.0, 1.0, 0.0))


func chest(base_local: Vector3, yaw: float, seed_id: StringName = &"") -> TreasureChest:
	var c := TreasureChest.new()
	c.seed_id = seed_id
	c.position = P(base_local)
	c.rotation.y = Y(yaw)
	add_child(c)
	return c


func critter(script: GDScript, base_local: Vector3) -> Critter:
	var c := script.new() as Critter
	c.position = P(base_local)
	add_child(c)
	return c


func gloplets(center_local: Vector3, radius: float, spots: Array[Vector3], bouncer_spots: Array[Vector3] = [], def: EnemyDef = null) -> EncounterZone:
	var zone := EncounterZone.new()
	zone.zone_id = StringName("%s_zone_%d" % [world_id, get_child_count()])
	zone.radius = radius
	zone.position = P(center_local)
	for s in spots:
		zone.add_spawn(_frame.basis * s, def if def != null else preload("res://data/enemies/gloplet.tres"))
	for s in bouncer_spots:
		zone.add_spawn(_frame.basis * s, preload("res://data/enemies/bouncer.tres"))
	add_child(zone)
	return zone


func monkey(perches_local: Array[Vector3]) -> BonkMonkey:
	var m := BonkMonkey.new()
	for p in perches_local:
		m.perches.append(P(p))
	add_child(m)
	return m


# --- Life (Ashwin: "make the worlds denser and more alive") ------------------------------------

func _add_grass_area(top: Vector3, size: Vector2, count: int) -> void:
	for i in count:
		var p := top + Vector3(_rng.randf_range(-size.x, size.x) * 0.46, 0.0, _rng.randf_range(-size.y, size.y) * 0.46)
		_queue_plant(p)


func _add_grass_disc(top: Vector3, radius: float, count: int) -> void:
	for i in count:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * radius
		_queue_plant(top + Vector3(cos(a) * r, 0.0, sin(a) * r))


func _queue_plant(p: Vector3) -> void:
	var xf := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(2.4, 3.8)), p)
	if _rng.randf() < 0.12:
		_flower_points.append(xf)
	else:
		_grass_points.append(xf)


## Call at the end of build(): turns every queued grass tuft and flower into a few MultiMeshes.
func finish_life(grass_color: StringName = &"grass_light") -> void:
	Ambient.grass(self, _grass_points, grass_color)
	Ambient.flowers(self, _flower_points)


func sparkles(center_local: Vector3, size: Vector3, count: int = 40) -> void:
	Ambient.sparkles(self, P(center_local), size, count)


## A giant mushroom standing on ground at base_local; returns the top of its cap.
func giant_mushroom(base_local: Vector3, height: float, cap_r: float, kind: StringName = &"red") -> Vector3:
	Whimsy.mushroom(self, P(base_local), height, cap_r, kind)
	return Whimsy.cap_top(P(base_local), height, cap_r)


## A giant mushroom whose cap top lands at top_local (height is worked out). Returns the
## actual (snapped) top in world space.
func mushroom_platform(top_local: Vector3, ground_y: float, cap_r: float, kind: StringName = &"red") -> Vector3:
	if cap_r < 5.0:
		cap_r *= 1.2
	var base := Vector3(top_local.x, ground_y, top_local.z)
	var h := top_local.y - ground_y - snappedf(cap_r, 0.5) * 0.56
	return giant_mushroom(base, maxf(h, 1.0), cap_r, kind)


func butterflies(center_local: Vector3, radius: float, count: int = 6) -> void:
	Ambient.butterflies(self, P(center_local), radius, count)


func birds(center_local: Vector3, radius: float, height: float, count: int = 5) -> void:
	Ambient.birds(self, P(center_local), radius, height, count)


func fireflies(center_local: Vector3, radius: float, count: int = 24) -> void:
	Ambient.fireflies(self, P(center_local), radius, count)


func animals(script: GDScript, center_local: Vector3, radius: float, count: int) -> void:
	for i in count:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.0, radius)
		var c := script.new() as Node3D
		c.position = P(center_local) + Vector3(cos(a) * r, 0.5, sin(a) * r)
		add_child(c)


func scatter(top_local: Vector3, half: Vector2, count: int, ids: Array[StringName], keep_clear: float = 0.0, collide: bool = false) -> void:
	for i in count:
		var l := top_local + Vector3(_rng.randf_range(-half.x, half.x), 0.0, _rng.randf_range(-half.y, half.y))
		if keep_clear > 0.0 and Vector2(l.x - top_local.x, l.z - top_local.z).length() < keep_clear:
			continue
		prop(ids[_rng.randi() % ids.size()], l, _rng.randf() * TAU, _rng.randf_range(0.85, 1.25), collide)


func tree_ring(center_local: Vector3, radius: float, count: int, ids: Array[StringName], scale_mul: float = 1.0, leaf: StringName = &"") -> void:
	for i in count:
		var a := float(i) / count * TAU + _rng.randf_range(-0.15, 0.15)
		var r := radius + _rng.randf_range(-1.5, 1.5)
		prop(ids[i % ids.size()], center_local + Vector3(cos(a) * r, 0.0, sin(a) * r), _rng.randf() * TAU, scale_mul * _rng.randf_range(0.85, 1.2), true, leaf)


func tree_line(a_local: Vector3, b_local: Vector3, step: float, ids: Array[StringName], scale_mul: float = 1.0, leaf: StringName = &"") -> void:
	var n := maxi(int(a_local.distance_to(b_local) / step), 1)
	for i in n + 1:
		var p := a_local.lerp(b_local, float(i) / n) + Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
		prop(ids[_rng.randi() % ids.size()], p, _rng.randf() * TAU, scale_mul * _rng.randf_range(0.85, 1.2), true, leaf)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null or regions.is_empty():
		return
	var pos := player.global_position
	var current := ""
	var best := INF
	for key: String in regions:
		var d := Vector2(pos.x - regions[key].x, pos.z - regions[key].z).length()
		if d < best:
			best = d
			current = key
	if current != _region_now:
		if _region_now != "":
			Telemetry.log_event("section_left", {"section": _region_now})
		_region_now = current
		Telemetry.log_event("section_entered", {"section": current})
