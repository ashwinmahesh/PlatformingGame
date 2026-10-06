class_name ModuleBatch
extends RefCounted
## Build 6 (World 6): a dense town is thousands of small kit pieces (wall panels, windows, roofs),
## so instead of one scene per piece, every placement of a model is gathered here and drawn as one
## MultiMesh per mesh, under the same toon materials Models.instance gives.

## Build 7 performance (Ashwin: "the city level is really laggy"): copies are grouped per model
## AND per 32 m cell, so each MultiMesh is small enough to be frustum-culled and faded out by
## distance. Wall pieces don't cast shadows (each house's plain interior box does instead).
const CELL := 32.0
const VISIBLE_TO := 120.0
const NO_SHADOW: Array[String] = ["Wall_", "Corner_", "Window", "Door", "Prop_Crate", "Prop_ExteriorBorder", "Balcony"]

var _xf: Dictionary[String, Array] = {}


## Queue one copy of `path` at `xf` (the model's own origin, as Models.instance would place it).
func add(path: String, xf: Transform3D) -> void:
	var key := "%s|%d|%d" % [path, int(floor(xf.origin.x / CELL)), int(floor(xf.origin.z / CELL))]
	if not _xf.has(key):
		_xf[key] = []
	_xf[key].append(xf)


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
	for key: String in _xf:
		var path := key.get_slice("|", 0)
		var xfs: Array = _xf[key]
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
			mmi.visibility_range_end = VISIBLE_TO
			mmi.visibility_range_end_margin = 12.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			for prefix in NO_SHADOW:
				if path.get_file().begins_with(prefix):
					mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.name = path.get_file().get_basename()
			parent.add_child(mmi)
		inst.free()
	_xf.clear()
