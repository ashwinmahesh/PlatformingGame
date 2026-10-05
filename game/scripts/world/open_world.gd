class_name OpenWorld
extends Level
## Base for the Build 4 open worlds: a central area with regions around it, laid out in
## region-local coordinates (region(origin, yaw) sets the frame). Star Shards collected in any
## order open the world's goal. Helpers build big, low, forgiving platforms (Ashwin: "bigger
## platforms, lower heights") and fill the world with life (grass, animals, birds, butterflies).

var world_id: StringName
var floor_y: float = -14.0
var lock: ShardLock
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


func make_lock() -> void:
	var w := Progress.world_def(world_id)
	lock = ShardLock.new()
	lock.world_id = world_id
	lock.required = w.shards_required if w != null else 3
	add_child(lock)


# --- Terrain ----------------------------------------------------------------------------------

## A plateau whose sides run down to the floor. Returns the body.
func plat(top_local: Vector3, size_xz: Vector2, color: StringName = &"bark_mid", grass: int = -1) -> StaticBody3D:
	var top := P(top_local)
	var size := S(Vector3(size_xz.x, top.y - floor_y, size_xz.y))
	var body := Kit.block(self, top, size, color)
	if grass != 0:
		_add_grass_area(top, Vector2(size.x, size.z), grass if grass > 0 else int(size.x * size.z / 7.0))
	return body


## A round plateau (pillar to the floor).
func disc(top_local: Vector3, radius: float, color: StringName = &"bark_mid", top_color: StringName = &"grass_mid", grass: int = -1) -> StaticBody3D:
	var top := P(top_local)
	var body := Kit.pillar(self, top, radius, top.y - floor_y, color, top_color)
	if grass != 0:
		_add_grass_disc(top, radius * 0.92, grass if grass > 0 else int(radius * radius * 0.45))
	return body


## A floating ledge of `size` (y = thickness) with its top at top_local.
func ledge(top_local: Vector3, size: Vector3, color: StringName = &"stone_light", yaw: float = 0.0) -> StaticBody3D:
	var b := Kit.block(self, P(top_local), S(size) if yaw == 0.0 else size, color)
	if yaw != 0.0:
		b.rotation.y = Y(yaw)
	return b


## A round floating stepping-stone.
func stone(top_local: Vector3, radius: float, thickness: float = 1.6, color: StringName = &"stone_light", top_color: StringName = &"moss") -> StaticBody3D:
	return Kit.pillar(self, P(top_local), radius, thickness, color, top_color)


## A gentle ramp between two heights along local -Z, width w.
func ramp(start_local: Vector3, length: float, rise: float, w: float, color: StringName = &"bark_mid") -> StaticBody3D:
	var b := Kit.ramp(self, Vector3.ZERO, w, length, rise, color)
	var start := P(start_local)
	var mid_off := b.position
	b.position = start + Basis(Vector3.UP, Y()) * mid_off
	b.rotation.y = Y()
	return b


func water(center_local: Vector3, size: Vector2, depth: float = 5.0) -> Area3D:
	var s := S(Vector3(size.x, 0.0, size.y))
	return Kit.water(self, P(center_local), Vector2(s.x, s.z), depth)


func mover(top_local: Vector3, size: Vector3, travel_local: Vector3, period: float, color: StringName = &"wood_plank", phase: float = 0.0, spin: float = 0.0) -> MovingPlatform:
	var m := MovingPlatform.new()
	m.rounded = false
	m.size = size
	m.travel = _frame.basis * travel_local
	m.period = period
	m.phase = phase
	m.spin_speed = spin
	m.color_name = color
	m.position = P(top_local) + Vector3.DOWN * size.y * 0.5
	m.rotation.y = Y()
	add_child(m)
	return m


func crumble(top_local: Vector3, size: Vector3, look: CrumblePlatform.Look = CrumblePlatform.Look.CLOUD) -> CrumblePlatform:
	var c := CrumblePlatform.new()
	c.size = size
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


func updraft(base_local: Vector3, size: Vector3, lift: float = 9.0) -> Updraft:
	var u := Updraft.new()
	u.size = size
	u.lift = lift
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


func gloplets(center_local: Vector3, radius: float, spots: Array[Vector3], bouncer_spots: Array[Vector3] = []) -> EncounterZone:
	var zone := EncounterZone.new()
	zone.zone_id = StringName("%s_zone_%d" % [world_id, get_child_count()])
	zone.radius = radius
	zone.position = P(center_local)
	for s in spots:
		zone.add_spawn(_frame.basis * s, preload("res://data/enemies/gloplet.tres"))
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
