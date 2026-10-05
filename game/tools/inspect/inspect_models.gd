extends SceneTree
## Prints the bounds, materials and animation players of every imported model (asset intake check).


func _init() -> void:
	for dir_path: String in ["res://assets/models/kenney_nature/", "res://assets/models/kaykit_medieval/", "res://assets/models/kaykit_adventurers/"]:
		for f in DirAccess.get_files_at(dir_path):
			if not (f.ends_with(".glb") or f.ends_with(".gltf")):
				continue
			var ps := load(dir_path + f) as PackedScene
			if ps == null:
				print("FAILED ", f)
				continue
			var root := ps.instantiate() as Node3D
			var box := AABB()
			var first := true
			var mats: Array[String] = []
			for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
				var xf := _xform_to(root, mi)
				var b := xf * mi.get_aabb()
				box = b if first else box.merge(b)
				first = false
				for s in mi.mesh.get_surface_count():
					var m := mi.mesh.surface_get_material(s)
					var desc := m.get_class()
					if m is BaseMaterial3D:
						var bm := m as BaseMaterial3D
						desc = "%s tex=%s col=%s" % [m.resource_name, bm.albedo_texture != null, bm.albedo_color.to_html(false)]
					if not desc in mats:
						mats.append(desc)
			var anims := ""
			var ap := root.find_children("*", "AnimationPlayer", true, false)
			if not ap.is_empty():
				anims = " anims=%d" % (ap[0] as AnimationPlayer).get_animation_list().size()
			print("%s size=%s pos=%s%s mats=%s" % [f, box.size.snapped(Vector3.ONE * 0.01), box.position.snapped(Vector3.ONE * 0.01), anims, mats])
			root.free()
	quit()


func _xform_to(root: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
