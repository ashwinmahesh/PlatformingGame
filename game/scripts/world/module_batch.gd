class_name ModuleBatch
extends RefCounted
## Build 6 (World 6): a dense town is thousands of small kit pieces (wall panels, windows, roofs),
## so instead of one scene per piece, every placement of a model is gathered here and drawn as one
## MultiMesh per mesh, under the same toon materials Models.instance gives.

var _xf: Dictionary[String, Array] = {}


## Queue one copy of `path` at `xf` (the model's own origin, as Models.instance would place it).
func add(path: String, xf: Transform3D) -> void:
	if not _xf.has(path):
		_xf[path] = []
	_xf[path].append(xf)


## Places `path` with its base centre at `pos` (like Models.spawn), scaled `s`, turned `yaw`.
func place(path: String, pos: Vector3, yaw: float, s: Vector3) -> void:
	var b := Models.model_bounds(path)
	var off := -Vector3(b.get_center().x, b.position.y, b.get_center().z) * s
	var basis := Basis(Vector3.UP, yaw)
	add(path, Transform3D(basis * Basis.from_scale(s), pos + basis * off))


func count() -> int:
	var n := 0
	for k: String in _xf:
		n += (_xf[k] as Array).size()
	return n


func build(parent: Node3D) -> void:
	for path: String in _xf:
		var xfs: Array = _xf[path]
		var inst := Models.instance(path)
		for n in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			var local := mi.transform
			var p := mi.get_parent()
			while p != null and p != inst:
				local = (p as Node3D).transform * local
				p = p.get_parent()
			var mesh := mi.mesh.duplicate() as Mesh
			if mesh is ArrayMesh:
				for s in mesh.get_surface_count():
					(mesh as ArrayMesh).surface_set_material(s, mi.get_surface_override_material(s))
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, (xfs[i] as Transform3D) * local)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.name = path.get_file().get_basename()
			parent.add_child(mmi)
		inst.free()
	_xf.clear()
