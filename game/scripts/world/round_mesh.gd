class_name RoundMesh
extends RefCounted
## Soft shapes for the level geometry (Build 3: "too boxy, make things round and smooth").
## Rounded boxes (an inner box grown by a sphere) and lathed pillars with rounded rims, plus
## smooth-normal versions of faceted sourced meshes. Everything is cached.

static var _cache: Dictionary[String, Mesh] = {}


static func clear_cache() -> void:
	_cache.clear()


## Box of `size` with every edge rounded by `radius`.
static func box(size: Vector3, radius: float, segs: int = 4) -> Mesh:
	var key := "box|%s|%.3f|%d" % [size.snapped(Vector3.ONE * 0.01), radius, segs]
	if _cache.has(key):
		return _cache[key]
	var h := size * 0.5
	var r := minf(radius, minf(h.x, minf(h.y, h.z)) * 0.95)
	var e := h - Vector3.ONE * r
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	# Each face: axis index of the normal, sign, and the two in-plane axes.
	for face: Array in [[0, 1.0, 1, 2], [0, -1.0, 1, 2], [1, 1.0, 0, 2], [1, -1.0, 0, 2], [2, 1.0, 0, 1], [2, -1.0, 0, 1]]:
		var ax: int = face[0]
		var sgn: float = face[1]
		var au: int = face[2]
		var av: int = face[3]
		var cu := _coords(h[au], e[au], segs)
		var cv := _coords(h[av], e[av], segs)
		var base := verts.size()
		for v in cv:
			for u in cu:
				var p := Vector3.ZERO
				p[ax] = h[ax] * sgn
				p[au] = u
				p[av] = v
				var inner := p.clamp(-e, e)
				var d := p - inner
				var n := d.normalized() if d.length() > 0.0001 else Vector3.ZERO
				if n == Vector3.ZERO:
					n[ax] = sgn
				verts.append(inner + n * r)
				norms.append(n)
		var w := cu.size()
		for j in cv.size() - 1:
			for i in w - 1:
				var a := base + j * w + i
				_quad(idx, verts, norms, a, a + 1, a + w + 1, a + w)
	var m := _build(verts, norms, idx)
	_cache[key] = m
	return m


## Coordinates along one axis: dense across the rounded edges, one span across the flat middle.
static func _coords(h: float, e: float, segs: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in segs + 1:
		out.append(lerpf(-h, -e, float(i) / segs))
	for i in segs + 1:
		var c := lerpf(e, h, float(i) / segs)
		if out.is_empty() or absf(out[out.size() - 1] - c) > 0.0001:
			out.append(c)
	return out


## Pillar of `radius` and `height` (centred on its middle) with a rounded top rim.
static func pillar(radius: float, height: float, rim: float = 0.25, sides: int = 28) -> Mesh:
	var key := "pillar|%.3f|%.3f|%.3f|%d" % [radius, height, rim, sides]
	if _cache.has(key):
		return _cache[key]
	var rr := minf(rim, minf(radius * 0.5, height * 0.45))
	var hy := height * 0.5
	# Profile from the bottom centre round to the top centre: [radius, y, normal_r, normal_y].
	var prof: Array[Vector4] = [Vector4(0.0, -hy, 0.0, -1.0), Vector4(radius * 1.04, -hy, 0.0, -1.0), Vector4(radius * 1.04, -hy, 1.0, 0.0)]
	prof.append(Vector4(radius, hy - rr, 1.0, 0.0))
	for i in range(1, 6):
		var a := float(i) / 5.0 * PI * 0.5
		prof.append(Vector4(radius - rr + cos(a) * rr, hy - rr + sin(a) * rr, cos(a), sin(a)))
	prof.append(Vector4(0.0, hy, 0.0, 1.0))
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var rows := prof.size()
	for s in sides + 1:
		var t := float(s) / sides * TAU
		var c := cos(t)
		var sn := sin(t)
		for pr in prof:
			verts.append(Vector3(pr.x * c, pr.y, pr.x * sn))
			norms.append(Vector3(pr.z * c, pr.w, pr.z * sn).normalized())
	for s in sides:
		for k in rows - 1:
			var a := s * rows + k
			_quad(idx, verts, norms, a, a + 1, a + rows + 1, a + rows)
	var m := _build(verts, norms, idx)
	_cache[key] = m
	return m


## Same mesh with smooth (averaged) normals, so faceted low-poly models shade soft and round.
static func smoothed(src: Mesh) -> Mesh:
	var key := "smooth|%d" % src.get_instance_id()
	if _cache.has(key):
		return _cache[key]
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var pos: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var ind: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if ind.is_empty():
			for i in pos.size():
				ind.append(i)
		var acc: Dictionary[Vector3i, Vector3] = {}
		for t in range(0, ind.size() - 2, 3):
			var p0 := pos[ind[t]]
			var fn := (pos[ind[t + 1]] - p0).cross(pos[ind[t + 2]] - p0)
			if not nrm.is_empty() and fn.dot(nrm[ind[t]]) < 0.0:
				fn = -fn
			for k in 3:
				var key3 := Vector3i((pos[ind[t + k]] * 1000.0).round())
				acc[key3] = acc.get(key3, Vector3.ZERO) + fn
		var new_n := PackedVector3Array()
		new_n.resize(pos.size())
		for i in pos.size():
			var n: Vector3 = acc.get(Vector3i((pos[i] * 1000.0).round()), Vector3.UP)
			new_n[i] = n.normalized() if n.length() > 0.00001 else Vector3.UP
		arrays[Mesh.ARRAY_NORMAL] = new_n
		arrays[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	_cache[key] = out
	return out


## Adds two triangles, wound clockwise as seen from outside (Godot's front face).
static func _quad(idx: PackedInt32Array, verts: PackedVector3Array, norms: PackedVector3Array, a: int, b: int, c: int, d: int) -> void:
	for tri: Array in [[a, b, c], [a, c, d]]:
		var i0: int = tri[0]
		var i1: int = tri[1]
		var i2: int = tri[2]
		var fn := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0])
		if fn.length() < 0.0000001:
			continue
		var n := norms[i0] + norms[i1] + norms[i2]
		if fn.dot(n) > 0.0:
			idx.append_array([i0, i2, i1])
		else:
			idx.append_array([i0, i1, i2])


static func _build(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m
