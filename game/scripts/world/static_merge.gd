class_name StaticMerge
extends RefCounted
## Build 7 performance (Ashwin: "the city level is really laggy"): levels are built from thousands
## of small static meshes (blocks, lamps, posts, cloth, rocks), each its own draw call. After a
## level is built, every mesh that can never move is merged with others that share its material,
## per 32 m cell, so it draws in a handful of calls and still culls by area.
## A mesh counts as static when every node between it and the level is a plain Node3D,
## MeshInstance3D or StaticBody3D with no script, and its subtree has no animation or skeleton.

const CELL := 32.0


static func merge(level: Node3D) -> int:
	var groups: Dictionary[String, Array] = {}
	var mats: Dictionary[String, Material] = {}
	var shadows: Dictionary[String, int] = {}
	var victims: Array[MeshInstance3D] = []
	var inv := level.global_transform.affine_inverse()
	for n in level.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.visible or not _static(mi, level) or mi.skeleton != NodePath("") and mi.get_node_or_null(mi.skeleton) is Skeleton3D:
			continue
		if mi.visibility_range_end > 0.0 or mi.mesh.get_surface_count() == 0:
			continue
		var xf := inv * mi.global_transform
		var cell := Vector2i(int(floor(xf.origin.x / CELL)), int(floor(xf.origin.z / CELL)))
		var ok := true
		var parts: Array = []
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m == null or (mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES):
				ok = false
				break
			parts.append([s, m])
		if not ok:
			continue
		for part: Array in parts:
			var m := part[1] as Material
			var key := "%d|%d|%d|%d" % [m.get_instance_id(), cell.x, cell.y, int(mi.cast_shadow)]
			if not groups.has(key):
				groups[key] = []
				mats[key] = m
				shadows[key] = int(mi.cast_shadow)
			groups[key].append([mi.mesh, int(part[0]), xf, mi])
		victims.append(mi)
	var made := 0
	for key: String in groups:
		var items: Array = groups[key]
		if items.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for it: Array in items:
			st.append_from(it[0] as Mesh, int(it[1]), it[2] as Transform3D)
		var mesh := st.commit()
		var out := MeshInstance3D.new()
		out.mesh = mesh
		out.material_override = mats[key]
		out.cast_shadow = shadows[key] as GeometryInstance3D.ShadowCastingSetting
		out.name = "Merged"
		level.add_child(out)
		made += 1
	# Drop an original only when every one of its surfaces went into a merged mesh.
	var left: Dictionary[int, int] = {}
	for mi in victims:
		left[mi.get_instance_id()] = mi.mesh.get_surface_count()
	for key: String in groups:
		if (groups[key] as Array).size() >= 2:
			for it: Array in groups[key]:
				var id := (it[3] as Node).get_instance_id()
				left[id] = left[id] - 1
	for mi in victims:
		if left[mi.get_instance_id()] <= 0:
			# A merged mesh that carries its own collision (Whimsy mushrooms, trees, cacti keep
			# their StaticBody as a child) stays as an empty node so the collision survives.
			if mi.get_child_count() > 0:
				mi.mesh = null
			else:
				mi.queue_free()
	return made


static func _static(n: Node, level: Node) -> bool:
	if not n.get_children().is_empty():
		for c in n.get_children():
			if c is AnimationPlayer or c is Skeleton3D or c is MeshInstance3D:
				return false
	var p := n.get_parent()
	while p != null and p != level:
		if p.get_script() != null:
			return false
		if not (p.get_class() in ["Node3D", "StaticBody3D", "MeshInstance3D"]):
			return false
		for c in p.get_children():
			if c is AnimationPlayer or c is Skeleton3D:
				return false
		p = p.get_parent()
	return p == level
