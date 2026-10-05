class_name Whimsy
extends RefCounted
## Storybook set pieces built in code (Build 5, Ashwin: "vibrant and fun... like Dragon Quest...
## giant mushroom forests... whimsical and magical"): puffball trees, giant mushrooms you can stand
## on, giant flowers, glowing crystals, rolling hills, blue mountains and rainbows.
## Meshes carry their colours as vertex colours taken from Palette, are merged into one mesh per
## piece, and are cached per kind and variant so a forest reuses a handful of meshes.

const VARIANTS := 4

## Canopy colours per tree kind: [shade, light].
const TREE_KINDS: Dictionary[StringName, Array] = {
	&"green": [&"leaf_dark", &"grass_light"],
	&"lime": [&"grass_mid", &"lime_pop"],
	&"teal": [&"leaf_teal", &"water_light"],
	&"blossom": [&"candy_pink", &"mush_spot"],
	&"autumn": [&"sunset_orange", &"thatch"],
	&"violet": [&"mush_purple", &"crystal_violet"],
	&"gold": [&"wood_warm", &"gold"],
	&"frost": [&"water_light", &"mush_spot"],
}
## Cap colours per mushroom kind: [rim, crown].
const MUSHROOM_KINDS: Dictionary[StringName, Array] = {
	&"red": [&"roof_red", &"mush_red"],
	&"purple": [&"mush_purple", &"crystal_violet"],
	&"teal": [&"roof_teal", &"mush_teal"],
	&"orange": [&"wood_warm", &"sunset_orange"],
	&"pink": [&"gloop_pink", &"candy_pink"],
	&"blue": [&"roof_blue", &"slime_blue"],
	&"gold": [&"wood_warm", &"gold"],
}

static var _meshes: Dictionary[String, ArrayMesh] = {}
static var _shapes: Dictionary[String, Shape3D] = {}


static func clear_cache() -> void:
	_meshes.clear()
	_shapes.clear()


## Palette colour as a vertex colour. Vertex colours reach the shader as linear values, so the
## sRGB palette colour is converted here (otherwise everything turns pastel).
static func vcol(name: StringName, mul: float = 1.0) -> Color:
	var c := Palette.color(name)
	return Color(c.r * mul, c.g * mul, c.b * mul).srgb_to_linear()


static func material() -> Material:
	return Kit.mat(&"mush_spot")


# --- Mesh building ------------------------------------------------------------------------------

## Emits a triangle wound clockwise as seen from its normal side (Godot's front face).
static func _tri(st: SurfaceTool, p: Array, n: Array, c: Array) -> void:
	var p0: Vector3 = p[0]
	var face := ((p[1] as Vector3) - p0).cross((p[2] as Vector3) - p0)
	var avg: Vector3 = (n[0] as Vector3) + (n[1] as Vector3) + (n[2] as Vector3)
	var second := 1 if face.dot(avg) < 0.0 else 2
	for i: int in [0, second, 3 - second]:
		st.set_color(c[i])
		st.set_normal(n[i])
		st.add_vertex(p[i])


## Sphere (optionally squashed on y) with a shade-to-light colour gradient from bottom to top.
static func _sphere(st: SurfaceTool, xf: Transform3D, radius: float, lo: Color, hi: Color, squash: float = 1.0, rings: int = 8, segs: int = 12) -> void:
	var pts: Array[Array] = []
	for r in rings + 1:
		var th := PI * float(r) / rings
		var row: Array = []
		for s in segs + 1:
			var ph := TAU * float(s) / segs
			var unit := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			var p := Vector3(unit.x, unit.y * squash, unit.z) * radius
			var n := Vector3(unit.x, unit.y / maxf(squash, 0.05), unit.z).normalized()
			var c := lo.lerp(hi, smoothstep(-0.7, 0.85, unit.y))
			row.append([xf * p, (xf.basis * n).normalized(), c])
		pts.append(row)
	for r in rings:
		for s in segs:
			var a: Array = pts[r][s]
			var b: Array = pts[r][s + 1]
			var cc: Array = pts[r + 1][s + 1]
			var d: Array = pts[r + 1][s]
			if r > 0:
				_tri(st, [a[0], b[0], cc[0]], [a[1], b[1], cc[1]], [a[2], b[2], cc[2]])
			if r < rings - 1:
				_tri(st, [a[0], cc[0], d[0]], [a[1], cc[1], d[1]], [a[2], cc[2], d[2]])


## Surface of revolution from a (radius, height) profile listed bottom to top, one colour per point.
## flat = faceted (crystals).
static func _lathe(st: SurfaceTool, xf: Transform3D, profile: Array[Vector2], colors: Array[Color], segs: int = 16, flat: bool = false, jitter: float = 0.0, jitter_seed: int = 0) -> void:
	var n2: Array[Vector2] = []
	for i in profile.size():
		var t := profile[mini(i + 1, profile.size() - 1)] - profile[maxi(i - 1, 0)]
		n2.append(Vector2(t.y, -t.x).normalized())
	var ring: Array[Array] = []
	for i in profile.size():
		var row: Array = []
		for s in segs + 1:
			var a := TAU * float(s % segs) / segs
			var r := profile[i].x * (1.0 + jitter * sin(a * 3.0 + jitter_seed) * sin(a * 5.0 + jitter_seed * 1.7 + i))
			var p := Vector3(cos(a) * r, profile[i].y, sin(a) * r)
			var n := Vector3(n2[i].x * cos(a), n2[i].y, n2[i].x * sin(a)).normalized()
			row.append([xf * p, (xf.basis * n).normalized(), colors[i]])
		ring.append(row)
	for i in profile.size() - 1:
		for s in segs:
			var a: Array = ring[i][s]
			var b: Array = ring[i][s + 1]
			var c: Array = ring[i + 1][s + 1]
			var d: Array = ring[i + 1][s]
			if flat:
				var fn := ((b[0] as Vector3) - (a[0] as Vector3)).cross((c[0] as Vector3) - (a[0] as Vector3)).normalized()
				var mid := ((a[0] as Vector3) + (c[0] as Vector3)) * 0.5 - xf.origin
				if fn.dot(mid) < 0.0:
					fn = -fn
				_tri(st, [a[0], b[0], c[0]], [fn, fn, fn], [a[2], b[2], c[2]])
				_tri(st, [a[0], c[0], d[0]], [fn, fn, fn], [a[2], c[2], d[2]])
			else:
				if profile[i].x > 0.001 or profile[i + 1].x > 0.001:
					_tri(st, [a[0], b[0], c[0]], [a[1], b[1], c[1]], [a[2], b[2], c[2]])
					_tri(st, [a[0], c[0], d[0]], [a[1], c[1], d[1]], [a[2], c[2], d[2]])


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _place(parent: Node, mesh: Mesh, pos: Vector3, yaw: float, s: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material()
	mi.position = pos
	mi.rotation.y = yaw
	mi.scale = Vector3.ONE * s
	parent.add_child(mi)
	return mi


# --- Trees -------------------------------------------------------------------------------------

static func tree_mesh(kind: StringName, variant: int) -> ArrayMesh:
	var key := "tree|%s|%d" % [kind, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var cols: Array = TREE_KINDS.get(kind, TREE_KINDS[&"green"])
	var lo := vcol(cols[0], 0.92)
	var hi := vcol(cols[1])
	var st := _begin()
	var lean := Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), rng.randf_range(0.03, 0.12))
	var trunk_h := rng.randf_range(2.6, 3.4)
	var tp: Array[Vector2] = [Vector2(0.55, 0.0), Vector2(0.4, 0.35), Vector2(0.3, 1.2), Vector2(0.27, trunk_h * 0.8), Vector2(0.32, trunk_h)]
	var tc: Array[Color] = [vcol(&"bark_dark"), vcol(&"bark_mid"), vcol(&"bark_mid"), vcol(&"bark_light"), vcol(&"bark_light")]
	_lathe(st, Transform3D(lean, Vector3.ZERO), tp, tc, 10)
	var top := lean * Vector3(0.0, trunk_h, 0.0)
	var main_r := rng.randf_range(1.6, 1.9)
	_sphere(st, Transform3D(Basis(), top + Vector3(0.0, main_r * 0.55, 0.0)), main_r, lo, hi, 0.88)
	var n := rng.randi_range(3, 5)
	for i in n:
		var a := float(i) / n * TAU + rng.randf_range(-0.3, 0.3)
		var r := rng.randf_range(1.0, 1.35)
		var off := Vector3(cos(a) * rng.randf_range(1.1, 1.5), rng.randf_range(-0.1, 0.9), sin(a) * rng.randf_range(1.1, 1.5))
		_sphere(st, Transform3D(Basis(), top + Vector3(0.0, main_r * 0.55, 0.0) + off), r, lo, hi, 0.9)
	_sphere(st, Transform3D(Basis(), top + Vector3(rng.randf_range(-0.3, 0.3), main_r * 1.35, rng.randf_range(-0.3, 0.3))), rng.randf_range(1.0, 1.2), lo, hi, 0.9)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A puffball tree, about 6 m tall at s = 1. Trunk collision only.
static func tree(parent: Node, pos: Vector3, kind: StringName = &"green", s: float = 1.0, variant: int = -1, yaw: float = 0.0, collide: bool = true) -> Node3D:
	var v := variant if variant >= 0 else absi(hash(pos)) % VARIANTS
	var mi := _place(parent, tree_mesh(kind, v), pos, yaw, s)
	if collide:
		var body := Kit.static_body(mi, Vector3(0.0, 1.5, 0.0), Layers.WORLD)
		var c := CylinderShape3D.new()
		c.radius = 0.4
		c.height = 3.0
		Kit.add_shape(body, c)
	return mi


## Pointy storybook pine: stacked rounded cones.
static func pine_mesh(kind: StringName, variant: int) -> ArrayMesh:
	var key := "pine|%s|%d" % [kind, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var cols: Array = TREE_KINDS.get(kind, TREE_KINDS[&"green"])
	var st := _begin()
	var trunk: Array[Vector2] = [Vector2(0.4, 0.0), Vector2(0.3, 1.4), Vector2(0.25, 2.0)]
	var trunk_c: Array[Color] = [vcol(&"bark_dark"), vcol(&"bark_mid"), vcol(&"bark_mid")]
	_lathe(st, Transform3D.IDENTITY, trunk, trunk_c, 8)
	var tiers := rng.randi_range(3, 4)
	var y := 1.2
	var r := rng.randf_range(2.0, 2.3)
	for i in tiers:
		var h := r * 1.15
		var lo := vcol(cols[0], 0.9 + 0.04 * i)
		var hi := vcol(cols[1])
		var prof: Array[Vector2] = [Vector2(0.0, y - 0.15), Vector2(r * 0.85, y), Vector2(r, y + 0.15), Vector2(r * 0.55, y + h * 0.5), Vector2(0.12, y + h)]
		var pc: Array[Color] = [lo, lo, lo.lerp(hi, 0.4), hi, hi]
		_lathe(st, Transform3D.IDENTITY, prof, pc, 14)
		y += h * 0.55
		r *= 0.74
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func pine(parent: Node, pos: Vector3, kind: StringName = &"green", s: float = 1.0, collide: bool = true) -> Node3D:
	var mi := _place(parent, pine_mesh(kind, absi(hash(pos)) % VARIANTS), pos, fposmod(pos.x * 1.7, TAU), s)
	if collide:
		var body := Kit.static_body(mi, Vector3(0.0, 1.5, 0.0), Layers.WORLD)
		var c := CylinderShape3D.new()
		c.radius = 0.45
		c.height = 3.0
		Kit.add_shape(body, c)
	return mi


# --- Giant mushrooms ----------------------------------------------------------------------------

static func _cap_profile(cap_r: float, base_y: float) -> Array[Vector2]:
	return [
		Vector2(0.0, base_y + 0.02 * cap_r), Vector2(cap_r * 0.35, base_y), Vector2(cap_r * 0.92, base_y - 0.06 * cap_r),
		Vector2(cap_r, base_y + 0.04 * cap_r), Vector2(cap_r * 0.97, base_y + 0.16 * cap_r), Vector2(cap_r * 0.86, base_y + 0.32 * cap_r),
		Vector2(cap_r * 0.62, base_y + 0.46 * cap_r), Vector2(cap_r * 0.32, base_y + 0.54 * cap_r), Vector2(0.0, base_y + 0.56 * cap_r),
	]


## Unit mushroom: stem height 1 and cap radius 1 are scaled by the caller's sizes via the key.
static func mushroom_mesh(kind: StringName, height: float, cap_r: float, spots: bool) -> ArrayMesh:
	var key := "mush|%s|%.1f|%.1f|%s" % [kind, height, cap_r, spots]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var cols: Array = MUSHROOM_KINDS.get(kind, MUSHROOM_KINDS[&"red"])
	var st := _begin()
	var sr := clampf(cap_r * 0.24, 0.35, 3.0)
	var sp: Array[Vector2] = [Vector2(sr * 1.35, 0.0), Vector2(sr * 1.15, height * 0.08), Vector2(sr * 0.95, height * 0.4), Vector2(sr * 0.9, height * 0.85), Vector2(sr * 1.05, height)]
	var cream := vcol(&"cloth_cream")
	var sc: Array[Color] = [vcol(&"stone_light", 0.92), cream, cream, cream, cream]
	_lathe(st, Transform3D.IDENTITY, sp, sc, 16)
	var prof := _cap_profile(cap_r, height)
	var gill := vcol(&"stone_light", 0.86)
	var rim := vcol(cols[0])
	var crown := vcol(cols[1])
	var pc: Array[Color] = [gill, gill, gill, rim, rim, rim.lerp(crown, 0.5), crown, crown, crown]
	_lathe(st, Transform3D.IDENTITY, prof, pc, 24)
	if spots:
		var count := int(clampf(cap_r * 2.2, 5.0, 16.0))
		for i in count:
			# Golden-angle spread so spots cover the whole cap evenly.
			var a := i * 2.39996 + rng.randf_range(-0.25, 0.25)
			var t := lerpf(0.92, 0.22, sqrt((i + 0.5) / count)) + rng.randf_range(-0.05, 0.05)
			# Point and normal on the dome between profile points 4 (rim) and 8 (top).
			var f := t * 4.0
			var i0 := 4 + mini(int(f), 3)
			var k := f - float(i0 - 4)
			var p2 := prof[i0].lerp(prof[i0 + 1], k)
			var tg := prof[i0 + 1] - prof[i0]
			var nn := Vector2(tg.y, -tg.x).normalized()
			var p := Vector3(cos(a) * p2.x, p2.y, sin(a) * p2.x)
			var n := Vector3(nn.x * cos(a), nn.y, nn.x * sin(a)).normalized()
			var b := Basis(Quaternion(Vector3.UP, n))
			var sr2 := cap_r * rng.randf_range(0.09, 0.16)
			_sphere(st, Transform3D(b, p + n * sr2 * 0.12), sr2, vcol(&"mush_spot", 0.95), vcol(&"mush_spot"), 0.32, 5, 10)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A giant mushroom: stand on the cap (convex collision), walk round the stem.
static func mushroom(parent: Node, pos: Vector3, height: float, cap_r: float, kind: StringName = &"red", collide: bool = true, spots: bool = true) -> Node3D:
	height = snappedf(height, 0.5)
	cap_r = snappedf(cap_r, 0.5)
	var mi := _place(parent, mushroom_mesh(kind, height, cap_r, spots), pos, fposmod(pos.x * 0.9 + pos.z, TAU), 1.0)
	if collide:
		var body := Kit.static_body(mi, Vector3.ZERO)
		var stem := CylinderShape3D.new()
		stem.radius = clampf(cap_r * 0.24, 0.35, 3.0)
		stem.height = height
		Kit.add_shape(body, stem, Vector3(0.0, height * 0.5, 0.0))
		var key := "cap|%.1f|%.1f" % [height, cap_r]
		if not _shapes.has(key):
			var pts := PackedVector3Array()
			for p2 in _cap_profile(cap_r, height):
				for s in 16:
					var a := TAU * s / 16.0
					pts.append(Vector3(cos(a) * p2.x, p2.y, sin(a) * p2.x))
			var cs := ConvexPolygonShape3D.new()
			cs.points = pts
			_shapes[key] = cs
		Kit.add_shape(body, _shapes[key])
	return mi


## Top of a giant mushroom's cap (for placing things on it).
static func cap_top(pos: Vector3, height: float, cap_r: float) -> Vector3:
	return pos + Vector3(0.0, snappedf(height, 0.5) + snappedf(cap_r, 0.5) * 0.56, 0.0)


# --- Giant flowers, crystals --------------------------------------------------------------------

static func flower_mesh(petal: StringName, height: float, r: float) -> ArrayMesh:
	var key := "flower|%s|%.1f|%.1f" % [petal, height, r]
	if _meshes.has(key):
		return _meshes[key]
	var st := _begin()
	var sp: Array[Vector2] = [Vector2(r * 0.12, 0.0), Vector2(r * 0.1, height * 0.5), Vector2(r * 0.11, height)]
	var stc: Array[Color] = [vcol(&"leaf_dark"), vcol(&"grass_mid"), vcol(&"grass_mid")]
	_lathe(st, Transform3D.IDENTITY, sp, stc, 8)
	for side: float in [-1.0, 1.0]:
		var leaf := Transform3D(Basis(Vector3.FORWARD, 0.9 * side), Vector3(r * 0.35 * side, height * 0.35, 0.0))
		_sphere(st, leaf, r * 0.35, vcol(&"leaf_dark"), vcol(&"grass_light"), 0.3, 5, 10)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var b := Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, -0.18)
		var xf := Transform3D(b, Vector3(cos(a) * r * 0.62, height + 0.05, sin(a) * r * 0.62))
		_sphere(st, xf.scaled_local(Vector3(1.0, 1.0, 0.62)), r * 0.52, vcol(petal, 0.85), vcol(petal), 0.22, 5, 10)
	_sphere(st, Transform3D(Basis(), Vector3(0.0, height + 0.2, 0.0)), r * 0.32, vcol(&"sunset_orange"), vcol(&"gold"), 0.45, 6, 12)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A giant flower whose petals are a platform.
static func flower(parent: Node, pos: Vector3, height: float, r: float, petal: StringName = &"candy_pink", collide: bool = true) -> Node3D:
	height = snappedf(height, 0.5)
	r = snappedf(r, 0.5)
	var mi := _place(parent, flower_mesh(petal, height, r), pos, fposmod(pos.z * 1.3, TAU), 1.0)
	if collide:
		var body := Kit.static_body(mi, Vector3.ZERO)
		var top := CylinderShape3D.new()
		top.radius = r * 1.05
		top.height = 0.5
		Kit.add_shape(body, top, Vector3(0.0, height + 0.05, 0.0))
		var stem := CylinderShape3D.new()
		stem.radius = r * 0.14
		stem.height = height
		Kit.add_shape(body, stem, Vector3(0.0, height * 0.5, 0.0))
	return mi


static func crystal_mesh(color: StringName, variant: int) -> ArrayMesh:
	var key := "crystal|%s|%d" % [color, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var st := _begin()
	var lo := vcol(color, 0.8)
	var hi := vcol(color).lerp(Color.WHITE, 0.35)
	for i in rng.randi_range(4, 6):
		var h := rng.randf_range(1.2, 2.6) * (1.6 if i == 0 else 1.0)
		var r := h * 0.22
		var b := Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), 0.0 if i == 0 else rng.randf_range(0.25, 0.6))
		var off := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-0.6, 0.6), 0.0, rng.randf_range(-0.6, 0.6))
		var cp: Array[Vector2] = [Vector2(r * 0.8, -0.2), Vector2(r, h * 0.15), Vector2(r, h * 0.72), Vector2(0.0, h)]
		var cc: Array[Color] = [lo, lo, hi, hi]
		_lathe(st, Transform3D(b, off), cp, cc, 6, true)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Glowing crystal cluster about 3 m tall at s = 1.
static func crystal(parent: Node, pos: Vector3, color: StringName = &"crystal_violet", s: float = 1.0, collide: bool = true) -> Node3D:
	var mi := _place(parent, crystal_mesh(color, absi(hash(pos)) % VARIANTS), pos, fposmod(pos.x, TAU), s)
	var m := Kit.unique_mat(&"mush_spot")
	m.set_shader_parameter(&"flash", 0.28)
	m.set_shader_parameter(&"flash_color", Palette.color(color))
	mi.material_override = m
	if collide:
		var body := Kit.static_body(mi, Vector3(0.0, 1.2, 0.0), Layers.WORLD)
		var c := CylinderShape3D.new()
		c.radius = 0.8
		c.height = 2.4
		Kit.add_shape(body, c)
	return mi


# --- Landscape: hills, mountains, rainbows -----------------------------------------------------

static func hill_mesh(variant: int) -> ArrayMesh:
	var key := "hill|%d" % variant
	if _meshes.has(key):
		return _meshes[key]
	var st := _begin()
	var prof: Array[Vector2] = []
	var cols: Array[Color] = []
	for i in 9:
		var t := float(i) / 8.0
		prof.append(Vector2(cos(t * PI * 0.5), sin(t * PI * 0.5) * 0.55))
		cols.append(vcol(&"leaf_dark").lerp(vcol(&"grass_light"), smoothstep(0.0, 1.0, t)))
	prof[8] = Vector2(0.0, 0.55)
	_lathe(st, Transform3D.IDENTITY, prof, cols, 28, false, 0.06, variant)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Backdrop hill (no collision): radius r, height about 0.55 r * squash.
static func hill(parent: Node, pos: Vector3, r: float, squash: float = 1.0) -> Node3D:
	var mi := _place(parent, hill_mesh(absi(hash(pos)) % VARIANTS), pos, fposmod(pos.x, TAU), r)
	mi.scale = Vector3(r, r * squash, r)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func mountain_mesh(variant: int, snow: bool) -> ArrayMesh:
	var key := "mountain|%d|%s" % [variant, snow]
	if _meshes.has(key):
		return _meshes[key]
	var st := _begin()
	var base := vcol(&"sea_violet").lerp(vcol(&"roof_blue"), 0.4)
	var mid := vcol(&"crystal_violet").lerp(vcol(&"sky_top"), 0.5)
	var cap := vcol(&"mush_spot")
	var prof: Array[Vector2] = [Vector2(1.0, 0.0), Vector2(0.82, 0.22), Vector2(0.6, 0.48), Vector2(0.42, 0.66), Vector2(0.3, 0.78), Vector2(0.16, 0.92), Vector2(0.0, 1.0)]
	var cols: Array[Color] = [base, base, mid, mid if not snow else cap, cap if snow else mid, cap if snow else mid, cap if snow else mid]
	_lathe(st, Transform3D.IDENTITY, prof, cols, 20, false, 0.12, variant * 3)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Distant blue mountain with a snow cap (no collision).
static func mountain(parent: Node, pos: Vector3, r: float, h: float, snow: bool = true) -> Node3D:
	var mi := _place(parent, mountain_mesh(absi(hash(pos)) % VARIANTS, snow), pos, fposmod(pos.z, TAU), 1.0)
	mi.scale = Vector3(r, h, r)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A soft see-through rainbow arc of radius r facing along yaw.
static func rainbow(parent: Node, center: Vector3, r: float, yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = center
	root.rotation.y = yaw
	parent.add_child(root)
	var bands: Array[StringName] = [&"roof_red", &"sunset_orange", &"gold", &"grass_light", &"slime_blue", &"mush_purple"]
	for i in bands.size():
		var t := TorusMesh.new()
		t.inner_radius = r - (i + 1) * r * 0.035
		t.outer_radius = r - i * r * 0.035
		t.rings = 48
		t.ring_segments = 6
		var mi := Kit.mesh_instance(root, t, Fx.fx_mat(Color(Palette.color(bands[i]), 0.42)))
		mi.rotation.x = PI * 0.5
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


# --- Village pieces (Build 5: a busier, cosier Mossbrook) -----------------------------------------

## A big puffy canopy of overlapping spheres (for the Great Oak and other giant trees).
static func canopy(parent: Node, center: Vector3, radius: float, kind: StringName = &"green") -> MeshInstance3D:
	var key := "canopy|%s|%.1f" % [kind, radius]
	if not _meshes.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		var cols: Array = TREE_KINDS.get(kind, TREE_KINDS[&"green"])
		var lo := vcol(cols[0], 0.9)
		var hi := vcol(cols[1])
		var st := _begin()
		_sphere(st, Transform3D.IDENTITY, radius, lo, hi, 0.8, 12, 18)
		for i in 7:
			var a := float(i) / 7.0 * TAU + rng.randf_range(-0.2, 0.2)
			var off := Vector3(cos(a) * radius * 0.75, rng.randf_range(-0.25, 0.3) * radius, sin(a) * radius * 0.75)
			_sphere(st, Transform3D(Basis(), off), radius * rng.randf_range(0.5, 0.62), lo, hi, 0.85, 10, 14)
		_sphere(st, Transform3D(Basis(), Vector3(0.0, radius * 0.7, 0.0)), radius * 0.55, lo, hi, 0.85, 10, 14)
		_meshes[key] = st.commit()
	var mi := _place(parent, _meshes[key], center, 0.0, 1.0)
	return mi


## A mushroom cottage: fat stem with a door and round glowing windows under a spotted cap.
static func mushroom_house(parent: Node, pos: Vector3, yaw: float, kind: StringName = &"red", stem_r: float = 2.6, stem_h: float = 4.2, cap_r: float = 5.5) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * Props.BUILDING_SCALE
	parent.add_child(root)
	var key := "mhouse|%s|%.1f|%.1f|%.1f" % [kind, stem_r, stem_h, cap_r]
	if not _meshes.has(key):
		var cols: Array = MUSHROOM_KINDS.get(kind, MUSHROOM_KINDS[&"red"])
		var st := _begin()
		var cream := vcol(&"cloth_cream")
		var sp: Array[Vector2] = [Vector2(stem_r * 1.12, 0.0), Vector2(stem_r * 1.05, stem_h * 0.15), Vector2(stem_r, stem_h * 0.6), Vector2(stem_r * 0.92, stem_h)]
		var sc: Array[Color] = [vcol(&"stone_light", 0.9), cream, cream, cream]
		_lathe(st, Transform3D.IDENTITY, sp, sc, 20)
		var prof := _cap_profile(cap_r, stem_h)
		var gill := vcol(&"stone_light", 0.86)
		var rim := vcol(cols[0])
		var crown := vcol(cols[1])
		var pc: Array[Color] = [gill, gill, gill, rim, rim, rim.lerp(crown, 0.5), crown, crown, crown]
		_lathe(st, Transform3D.IDENTITY, prof, pc, 28)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		for i in 12:
			var a := i * 2.39996
			var t := lerpf(0.9, 0.25, sqrt((i + 0.5) / 12.0))
			var f := t * 4.0
			var i0 := 4 + mini(int(f), 3)
			var p2 := prof[i0].lerp(prof[i0 + 1], f - float(i0 - 4))
			var tg := prof[i0 + 1] - prof[i0]
			var nn := Vector2(tg.y, -tg.x).normalized()
			var n := Vector3(nn.x * cos(a), nn.y, nn.x * sin(a)).normalized()
			var sr2 := cap_r * rng.randf_range(0.1, 0.15)
			_sphere(st, Transform3D(Basis(Quaternion(Vector3.UP, n)), Vector3(cos(a) * p2.x, p2.y, sin(a) * p2.x) + n * sr2 * 0.12), sr2, vcol(&"mush_spot", 0.95), vcol(&"mush_spot"), 0.32, 5, 10)
		_meshes[key] = st.commit()
	_place(root, _meshes[key], Vector3.ZERO, 0.0, 1.0)
	var body := Kit.static_body(root, Vector3.ZERO)
	var stem := CylinderShape3D.new()
	stem.radius = stem_r
	stem.height = stem_h
	Kit.add_shape(body, stem, Vector3(0.0, stem_h * 0.5, 0.0))
	var pts := PackedVector3Array()
	for p2 in _cap_profile(cap_r, stem_h):
		for s in 16:
			var a := TAU * s / 16.0
			pts.append(Vector3(cos(a) * p2.x, p2.y, sin(a) * p2.x))
	var cs := ConvexPolygonShape3D.new()
	cs.points = pts
	Kit.add_shape(body, cs)
	# Door, step and windows on the +Z side.
	var door := RoundMesh.box(Vector3(1.3, 2.1, 0.3), 0.15)
	Kit.mesh_instance(root, door, Kit.mat(&"bark_mid"), Vector3(0.0, 1.05, stem_r - 0.02))
	var knob := SphereMesh.new()
	knob.radius = 0.08
	knob.height = 0.16
	Kit.mesh_instance(root, knob, Kit.mat(&"gold"), Vector3(0.4, 1.0, stem_r + 0.16))
	Kit.pillar(root, Vector3(0.0, 0.15, stem_r + 0.5), 0.9, 0.15, &"stone_light")
	for side: float in [-1.0, 1.0]:
		var a := side * 0.85
		var win := CylinderMesh.new()
		win.top_radius = 0.42
		win.bottom_radius = 0.42
		win.height = 0.12
		var w := Kit.mesh_instance(root, win, Kit.mat(&"gold"), Vector3(sin(a) * stem_r, 2.6, cos(a) * stem_r))
		w.rotation = Vector3(PI * 0.5, a, 0.0)
		var m := Kit.unique_mat(&"gold")
		m.set_shader_parameter(&"flash", 0.35)
		m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
		w.material_override = m
	return root


## Little triangle flags strung between two points with a gentle sag.
static func bunting(parent: Node, a: Vector3, b: Vector3, sag: float = 0.8) -> void:
	var n := maxi(int(a.distance_to(b) / 0.9), 2)
	var colors: Array[StringName] = [&"roof_red", &"gold", &"roof_blue", &"candy_pink", &"grass_light", &"sunset_orange"]
	var line := ImmediateMesh.new()
	line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in n + 1:
		var t := float(i) / n
		line.surface_add_vertex(a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t))
	line.surface_end()
	Kit.mesh_instance(parent, line, Kit.mat(&"bark_dark"))
	var dir := (b - a)
	dir.y = 0.0
	var yaw := atan2(dir.x, dir.z)
	for i in n:
		var t := (i + 0.5) / n
		var p := a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		var flag := PrismMesh.new()
		flag.size = Vector3(0.5, 0.6, 0.04)
		var f := Kit.mesh_instance(parent, flag, Kit.mat(colors[i % colors.size()]), p + Vector3.DOWN * 0.32)
		f.rotation = Vector3(0.0, yaw + PI * 0.5, PI)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A storybook lamp post with a warm glowing lantern.
static func lamp(parent: Node, pos: Vector3, with_light: bool = true) -> void:
	Kit.pillar(parent, pos + Vector3(0.0, 2.6, 0.0), 0.1, 2.6, &"bark_dark", &"", Layers.WORLD)
	var arm := RoundMesh.box(Vector3(0.7, 0.1, 0.1), 0.04)
	Kit.mesh_instance(parent, arm, Kit.mat(&"bark_dark"), pos + Vector3(0.3, 2.55, 0.0))
	var glass := SphereMesh.new()
	glass.radius = 0.28
	glass.height = 0.5
	var m := Kit.unique_mat(&"thatch")
	m.set_shader_parameter(&"flash", 0.7)
	m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	Kit.mesh_instance(parent, glass, m, pos + Vector3(0.6, 2.25, 0.0))
	var hat := CylinderMesh.new()
	hat.top_radius = 0.05
	hat.bottom_radius = 0.34
	hat.height = 0.25
	Kit.mesh_instance(parent, hat, Kit.mat(&"roof_red"), pos + Vector3(0.6, 2.58, 0.0))
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Palette.color(&"gold")
		l.light_energy = 0.8
		l.omni_range = 6.0
		l.position = pos + Vector3(0.6, 2.2, 0.0)
		parent.add_child(l)


## Market stall: a counter under a striped awning, with goods on top.
static func stall(parent: Node, pos: Vector3, yaw: float, stripe: StringName = &"roof_red") -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * Props.BUILDING_SCALE
	parent.add_child(root)
	Kit.block(root, Vector3(0.0, 1.1, 0.0), Vector3(3.2, 1.1, 1.2), &"wood_plank", Layers.WORLD, &"")
	for x: float in [-1.5, 1.5]:
		Kit.pillar(root, Vector3(x, 2.9, -0.5), 0.08, 2.9, &"bark_mid", &"", 0)
		Kit.pillar(root, Vector3(x, 2.9, 0.55), 0.08, 2.9, &"bark_mid", &"", 0)
	for i in 6:
		var s := RoundMesh.box(Vector3(0.56, 0.08, 1.7), 0.03)
		var mi := Kit.mesh_instance(root, s, Kit.mat(stripe if i % 2 == 0 else &"mush_spot"), Vector3(-1.4 + i * 0.56, 3.0, 0.05))
		mi.rotation.x = -0.25
	var goods: Array[StringName] = [&"sunset_orange", &"roof_red", &"grass_light", &"gold", &"candy_pink"]
	for i in 7:
		var g := SphereMesh.new()
		g.radius = 0.16
		g.height = 0.3
		Kit.mesh_instance(root, g, Kit.mat(goods[i % goods.size()], 0.01), Vector3(-1.2 + i * 0.4, 1.25, 0.1 * (i % 2)))
	return root


# --- Desert pieces (Build 5, Sunscorch Canyon) ----------------------------------------------------

static func cactus_mesh(height: float, variant: int) -> ArrayMesh:
	var key := "cactus|%.1f|%d" % [height, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var st := _begin()
	var r := clampf(height * 0.13, 0.4, 1.6)
	var lo := vcol(&"leaf_dark")
	var hi := vcol(&"kelp")
	var prof: Array[Vector2] = [Vector2(r * 0.9, 0.0), Vector2(r, height * 0.1), Vector2(r, height * 0.85), Vector2(r * 0.75, height * 0.97), Vector2(0.0, height + r * 0.1)]
	var pc: Array[Color] = [lo, lo.lerp(hi, 0.3), hi, hi, hi]
	_lathe(st, Transform3D.IDENTITY, prof, pc, 12, false, 0.08, variant)
	for side: float in [-1.0, 1.0]:
		if variant % 2 == 1 and side > 0.0:
			continue
		var y0 := height * rng.randf_range(0.35, 0.55)
		var out := r * 2.2
		var elbow := Transform3D(Basis(Vector3.FORWARD, side * PI * 0.5), Vector3(side * r * 0.6, y0, 0.0))
		var arm: Array[Vector2] = [Vector2(r * 0.55, 0.0), Vector2(r * 0.6, out)]
		var ac: Array[Color] = [hi, hi]
		_lathe(st, elbow, arm, ac, 10)
		var up_h := height * rng.randf_range(0.25, 0.4)
		var up: Array[Vector2] = [Vector2(r * 0.6, 0.0), Vector2(r * 0.6, up_h * 0.85), Vector2(r * 0.4, up_h * 0.98), Vector2(0.0, up_h + 0.1)]
		var uc: Array[Color] = [hi, hi, hi, hi]
		_lathe(st, Transform3D(Basis(), Vector3(side * (r * 0.6 + out), y0 - r * 0.6, 0.0)), up, uc, 10)
		_sphere(st, Transform3D(Basis(), Vector3(side * (r * 0.6 + out), y0 - r * 0.6, 0.0)), r * 0.6, hi, hi, 1.0, 6, 10)
	for i in 5:
		var a := float(i) / 5.0 * TAU
		var xf := Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, -0.3), Vector3(cos(a) * r * 0.35, height + r * 0.1, sin(a) * r * 0.35))
		_sphere(st, xf, r * 0.35, vcol(&"candy_pink", 0.9), vcol(&"candy_pink"), 0.4, 5, 8)
	_sphere(st, Transform3D(Basis(), Vector3(0.0, height + r * 0.2, 0.0)), r * 0.18, vcol(&"gold"), vcol(&"gold"), 0.7, 5, 8)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A giant storybook cactus (pink flower on top). Trunk collision only.
static func cactus(parent: Node, pos: Vector3, height: float = 5.0, collide: bool = true) -> Node3D:
	height = snappedf(height, 0.5)
	var mi := _place(parent, cactus_mesh(height, absi(hash(pos)) % VARIANTS), pos, fposmod(pos.x * 1.3, TAU), 1.0)
	if collide:
		var body := Kit.static_body(mi, Vector3(0.0, height * 0.5, 0.0), Layers.WORLD)
		var c := CylinderShape3D.new()
		c.radius = clampf(height * 0.13, 0.4, 1.6)
		c.height = height
		Kit.add_shape(body, c)
	return mi


## A striped hot-air balloon to hang over a basket platform (decoration only).
static func balloon(parent: Node3D, top: Vector3, colors: Array[StringName]) -> void:
	var key := "balloon|%s" % [colors]
	if not _meshes.has(key):
		var st := _begin()
		var prof: Array[Vector2] = []
		var pc: Array[Color] = []
		for i in 11:
			var t := float(i) / 10.0
			var ang := lerpf(-PI * 0.42, PI * 0.5, t)
			prof.append(Vector2(cos(ang) * 2.2 * (1.0 - 0.25 * (1.0 - t)), 2.6 + sin(ang) * 2.4))
			pc.append(vcol(colors[i % colors.size()]))
		prof[10] = Vector2(0.0, 5.0)
		_lathe(st, Transform3D.IDENTITY, prof, pc, 18)
		_meshes[key] = st.commit()
	var mi := _place(parent, _meshes[key], top + Vector3(0.0, 2.2, 0.0), 0.0, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 4:
		var a := float(i) / 4.0 * TAU + PI * 0.25
		var rope := CylinderMesh.new()
		rope.top_radius = 0.04
		rope.bottom_radius = 0.04
		rope.height = 3.0
		var r := Kit.mesh_instance(parent, rope, Kit.mat(&"bark_dark"), top + Vector3(cos(a) * 1.75, 1.45, sin(a) * 1.75))
		r.rotation = Vector3(sin(a) * 0.2, 0.0, -cos(a) * 0.2)


# --- Undersea pieces (Build 5, Bubbleton Reef) ----------------------------------------------------

## Branching coral: a cluster of rounded fingers. About 3 m tall at s = 1.
static func coral_mesh(color: StringName, variant: int) -> ArrayMesh:
	var key := "coral|%s|%d" % [color, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var st := _begin()
	var lo := vcol(color, 0.8)
	var hi := vcol(color).lerp(Color.WHITE, 0.2)
	for i in rng.randi_range(5, 8):
		var tilt := Basis(Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized(), rng.randf_range(0.0, 0.6))
		var h := rng.randf_range(1.4, 3.0)
		var r := rng.randf_range(0.18, 0.3)
		var prof: Array[Vector2] = [Vector2(r * 1.2, 0.0), Vector2(r, h * 0.6), Vector2(r * 0.9, h)]
		var pc: Array[Color] = [lo, lo.lerp(hi, 0.5), hi]
		_lathe(st, Transform3D(tilt, Vector3(rng.randf_range(-0.4, 0.4), 0.0, rng.randf_range(-0.4, 0.4))), prof, pc, 8)
		_sphere(st, Transform3D(tilt, Vector3.ZERO).translated_local(Vector3(0.0, h, 0.0)), r * 1.3, hi, hi, 1.0, 5, 8)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func coral(parent: Node, pos: Vector3, color: StringName = &"coral_pink", s: float = 1.0) -> Node3D:
	var mi := _place(parent, coral_mesh(color, absi(hash(pos)) % VARIANTS), pos, fposmod(pos.x * 2.1, TAU), s)
	return mi


## A wavy kelp stalk with leaves, h metres tall (no collision).
static func kelp_mesh(h: float, variant: int) -> ArrayMesh:
	var key := "kelp|%.0f|%d" % [h, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var st := _begin()
	var segs := int(h / 1.5)
	var pos := Vector3.ZERO
	for i in segs:
		var bend := Basis(Vector3.FORWARD, sin(i * 0.9 + variant) * 0.18)
		var prof: Array[Vector2] = [Vector2(0.3, 0.0), Vector2(0.26, 1.6)]
		var pc: Array[Color] = [vcol(&"kelp", 0.85), vcol(&"kelp")]
		_lathe(st, Transform3D(bend, pos), prof, pc, 8)
		pos += bend * Vector3(0.0, 1.5, 0.0)
		if i % 2 == 1:
			var side := 1.0 if i % 4 == 1 else -1.0
			var leaf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, side * 1.0), pos)
			_sphere(st, leaf.scaled_local(Vector3(0.5, 1.0, 0.16)), 1.3, vcol(&"kelp", 0.9), vcol(&"lime_pop"), 1.0, 5, 8)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func kelp(parent: Node, pos: Vector3, h: float = 10.0) -> Node3D:
	var mi := _place(parent, kelp_mesh(snappedf(h, 3.0), absi(hash(pos)) % VARIANTS), pos, fposmod(pos.z, TAU), 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A sea anemone: a squat base with a crown of fat tentacles.
static func anemone(parent: Node, pos: Vector3, color: StringName = &"mush_purple", s: float = 1.0) -> Node3D:
	var key := "anemone|%s" % color
	if not _meshes.has(key):
		var st := _begin()
		var base: Array[Vector2] = [Vector2(0.6, 0.0), Vector2(0.55, 0.5), Vector2(0.7, 0.7)]
		var bc: Array[Color] = [vcol(&"coral_orange", 0.9), vcol(&"coral_orange"), vcol(&"coral_orange")]
		_lathe(st, Transform3D.IDENTITY, base, bc, 12)
		for i in 12:
			var a := float(i) / 12.0 * TAU
			var r := 0.5 if i % 2 == 0 else 0.3
			var b := Basis(Vector3(-sin(a), 0.0, cos(a)), 0.45 if i % 2 == 0 else 0.2)
			var t: Array[Vector2] = [Vector2(0.09, 0.0), Vector2(0.08, 0.7), Vector2(0.0, 0.85)]
			var tc: Array[Color] = [vcol(color, 0.8), vcol(color), vcol(color).lerp(Color.WHITE, 0.4)]
			_lathe(st, Transform3D(b, Vector3(cos(a) * r, 0.65, sin(a) * r)), t, tc, 6)
		_meshes[key] = st.commit()
	return _place(parent, _meshes[key], pos, fposmod(pos.x, TAU), s)


## A flat storybook "sky flower": the shapes drifting at the sea surface overhead.
static func sky_flower(parent: Node, pos: Vector3, r: float, color: StringName) -> Node3D:
	var key := "skyflower|%s" % color
	if not _meshes.has(key):
		var st := _begin()
		for i in 5:
			var a := float(i) / 5.0 * TAU
			_sphere(st, Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 0.62, 0.0, sin(a) * 0.62)).scaled_local(Vector3(1.0, 1.0, 0.75)), 0.55, vcol(color, 0.95), vcol(color), 0.12, 4, 10)
		_sphere(st, Transform3D.IDENTITY, 0.45, vcol(&"mush_spot"), vcol(&"mush_spot"), 0.14, 4, 10)
		_meshes[key] = st.commit()
	var mi := _place(parent, _meshes[key], pos, fposmod(pos.x * 0.37, TAU), r)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A spiral seashell cottage (conch-like) with a round door and porthole windows.
static func shell_house(parent: Node, pos: Vector3, yaw: float, color: StringName = &"coral_pink", s: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * s * Props.BUILDING_SCALE
	parent.add_child(root)
	var key := "shellhouse|%s" % color
	if not _meshes.has(key):
		var st := _begin()
		var lo := vcol(color, 0.85)
		var hi := vcol(&"mush_spot")
		var prof: Array[Vector2] = []
		var pc: Array[Color] = []
		for i in 13:
			var t := float(i) / 12.0
			prof.append(Vector2(4.0 * (1.0 - t) + 0.6 * sin(t * PI * 5.0) * (1.0 - t), t * 9.0))
			pc.append(lo.lerp(hi, 0.18 + 0.18 * sin(t * PI * 5.0)))
		prof[12] = Vector2(0.0, 9.3)
		_lathe(st, Transform3D.IDENTITY, prof, pc, 20)
		_meshes[key] = st.commit()
	_place(root, _meshes[key], Vector3.ZERO, 0.0, 1.0)
	var body := Kit.static_body(root, Vector3.ZERO)
	var c := CylinderShape3D.new()
	c.radius = 3.6
	c.height = 6.0
	Kit.add_shape(body, c, Vector3(0.0, 3.0, 0.0))
	var door := CylinderMesh.new()
	door.top_radius = 0.9
	door.bottom_radius = 0.9
	door.height = 0.2
	var d := Kit.mesh_instance(root, door, Kit.mat(&"bark_mid"), Vector3(0.0, 1.0, 3.75))
	d.rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		var win := CylinderMesh.new()
		win.top_radius = 0.45
		win.bottom_radius = 0.45
		win.height = 0.15
		var a := side * 0.7
		var w := Kit.mesh_instance(root, win, Kit.mat(&"gold"), Vector3(sin(a) * 3.15, 3.6, cos(a) * 3.15))
		w.rotation = Vector3(PI * 0.5, a, 0.0)
		var m := Kit.unique_mat(&"gold")
		m.set_shader_parameter(&"flash", 0.4)
		m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
		w.material_override = m
	return root


## A friendly sea turtle shell to ride: decoration for a moving platform (child of it).
static func turtle_on(platform: Node3D, size: Vector3) -> void:
	var shell := SphereMesh.new()
	shell.radius = size.x * 0.55
	shell.height = size.x * 0.5
	shell.is_hemisphere = true
	Kit.mesh_instance(platform, shell, Kit.mat(&"kelp", 0.03), Vector3(0.0, -size.y * 0.5 - 0.05, 0.0)).scale = Vector3(1.0, 0.35, 1.0)
	var head := SphereMesh.new()
	head.radius = 0.6
	head.height = 1.1
	Kit.mesh_instance(platform, head, Kit.mat(&"lime_pop", 0.03), Vector3(0.0, -size.y * 0.5, -size.z * 0.6))
	for side: float in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.1
		eye.height = 0.2
		Kit.mesh_instance(platform, eye, Kit.mat(&"ink_navy"), Vector3(0.25 * side, -size.y * 0.5 + 0.2, -size.z * 0.6 - 0.5))
		for fz: float in [-0.3, 0.3]:
			var flip := SphereMesh.new()
			flip.radius = 0.6
			flip.height = 0.3
			var f := Kit.mesh_instance(platform, flip, Kit.mat(&"lime_pop", 0.02), Vector3(size.x * 0.5 * side, -size.y * 0.6, fz * size.z))
			f.scale = Vector3(1.6, 1.0, 0.8)


# --- Snow pieces (Build 5, Frostfang Peak) --------------------------------------------------------

## A snow-block igloo you can stand on, door facing +Z.
static func igloo(parent: Node, pos: Vector3, yaw: float, r: float = 4.0) -> Node3D:
	r *= Props.BUILDING_SCALE
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	parent.add_child(root)
	var key := "igloo"
	if not _meshes.has(key):
		var st := _begin()
		var prof: Array[Vector2] = []
		var pc: Array[Color] = []
		for i in 9:
			var t := float(i) / 8.0
			prof.append(Vector2(cos(t * PI * 0.5), sin(t * PI * 0.5)))
			pc.append(vcol(&"bubble" if i % 2 == 0 else &"mush_spot"))
		prof[8] = Vector2(0.0, 1.0)
		_lathe(st, Transform3D.IDENTITY, prof, pc, 24)
		_meshes[key] = st.commit()
	var mi := _place(root, _meshes[key], Vector3.ZERO, 0.0, r)
	mi.scale = Vector3.ONE * r
	var body := Kit.static_body(root, Vector3.ZERO)
	var sph := SphereShape3D.new()
	sph.radius = r
	Kit.add_shape(body, sph)
	var door := CylinderMesh.new()
	door.top_radius = r * 0.32
	door.bottom_radius = r * 0.32
	door.height = r * 0.5
	var d := Kit.mesh_instance(root, door, Kit.mat(&"ink_navy"), Vector3(0.0, 0.0, r * 0.82))
	d.rotation.x = PI * 0.5
	var tunnel := CylinderMesh.new()
	tunnel.top_radius = r * 0.42
	tunnel.bottom_radius = r * 0.42
	tunnel.height = r * 0.6
	var t := Kit.mesh_instance(root, tunnel, Kit.mat(&"mush_spot", 0.02), Vector3(0.0, r * 0.05, r * 0.95))
	t.rotation.x = PI * 0.5
	return root


## A cheery snowman (decoration with a small collider).
static func snowman(parent: Node, pos: Vector3, s: float = 1.0, scarf: StringName = &"roof_red") -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * s
	parent.add_child(root)
	var key := "snowman|%s" % scarf
	if not _meshes.has(key):
		var st := _begin()
		var snow := vcol(&"mush_spot")
		var shade := vcol(&"bubble")
		_sphere(st, Transform3D(Basis(), Vector3(0.0, 0.8, 0.0)), 0.9, shade, snow, 0.9)
		_sphere(st, Transform3D(Basis(), Vector3(0.0, 2.0, 0.0)), 0.65, shade, snow, 0.95)
		_sphere(st, Transform3D(Basis(), Vector3(0.0, 2.95, 0.0)), 0.48, shade, snow)
		var nose: Array[Vector2] = [Vector2(0.09, 0.0), Vector2(0.0, 0.45)]
		var nc: Array[Color] = [vcol(&"sunset_orange"), vcol(&"sunset_orange")]
		_lathe(st, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.0, 2.95, -0.42)), nose, nc, 6)
		for side: float in [-1.0, 1.0]:
			_sphere(st, Transform3D(Basis(), Vector3(0.17 * side, 3.08, -0.4)), 0.06, vcol(&"ink_navy"), vcol(&"ink_navy"), 1.0, 4, 6)
		var scarf_p: Array[Vector2] = [Vector2(0.62, 0.0), Vector2(0.66, 0.12), Vector2(0.62, 0.24)]
		var sc: Array[Color] = [vcol(scarf), vcol(scarf), vcol(scarf)]
		_lathe(st, Transform3D(Basis(), Vector3(0.0, 2.48, 0.0)), scarf_p, sc, 12)
		var hat: Array[Vector2] = [Vector2(0.55, 0.0), Vector2(0.55, 0.06), Vector2(0.34, 0.08), Vector2(0.34, 0.5), Vector2(0.0, 0.52)]
		var hc: Array[Color] = [vcol(&"ink_navy"), vcol(&"ink_navy"), vcol(&"ink_navy"), vcol(&"ink_navy"), vcol(&"ink_navy")]
		_lathe(st, Transform3D(Basis(), Vector3(0.0, 3.35, 0.0)), hat, hc, 12)
		_meshes[key] = st.commit()
	_place(root, _meshes[key], Vector3.ZERO, fposmod(pos.x, TAU), 1.0)
	var body := Kit.static_body(root, Vector3(0.0, 1.0, 0.0), Layers.WORLD)
	var c := CylinderShape3D.new()
	c.radius = 0.8
	c.height = 2.0
	Kit.add_shape(body, c)
	return root


## Northern lights: soft glowing curtains high in the sky.
static func aurora(parent: Node, center: Vector3, radius: float) -> void:
	var colors: Array[StringName] = [&"portal_teal", &"lime_pop", &"candy_pink", &"crystal_violet"]
	for band in 4:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var c := Palette.color(colors[band])
		var n := 48
		var prev_lo := Vector3.ZERO
		var prev_hi := Vector3.ZERO
		for i in n + 1:
			var t := float(i) / n
			var a := lerpf(-1.1, 1.1, t) + band * 0.5
			var wob := sin(t * 9.0 + band) * 0.06
			var r := radius * (1.0 + wob)
			var base := center + Vector3(cos(a) * r, band * 6.0, sin(a) * r)
			var lo := base
			var hi := base + Vector3(0.0, 22.0 + 6.0 * sin(t * 6.0 + band), 0.0)
			if i > 0:
				var fade_lo := Color(c, 0.0)
				var fade_hi := Color(c * 1.6, 0.4 * sin(t * PI))
				for v: Array in [[prev_lo, fade_lo], [prev_hi, fade_hi], [hi, fade_hi], [prev_lo, fade_lo], [hi, fade_hi], [lo, fade_lo]]:
					st.set_color(v[1] as Color)
					st.add_vertex(v[0] as Vector3)
			prev_lo = lo
			prev_hi = hi
		var mi := Kit.mesh_instance(parent, st.commit(), Fx.fx_mat(Color(1.0, 1.0, 1.0, 1.0)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
