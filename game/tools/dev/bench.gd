extends Node
## Dev tool: frame-time benchmark. Loads a level like the game does (hero, camera, HUD), stands
## at a spawn and measures for a few seconds. Prints fps, frame ms, draw calls, objects and lights.
## Godot --path game --resolution 1920x1080 res://tools/dev/bench.tscn -- --scene=... [--spawn=...] [--seconds=6]


func _ready() -> void:
	var scene := ""
	var secs := 6.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.trim_prefix("--scene=")
		elif a.begins_with("--spawn="):
			Router.pending_spawn = StringName(a.trim_prefix("--spawn="))
		elif a.begins_with("--seconds="):
			secs = float(a.trim_prefix("--seconds="))
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var lvl := (load(scene) as PackedScene).instantiate() as Level
	add_child(lvl)
	for i in 60:
		await get_tree().process_frame
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var worst := 0.0
	var last := t0
	var draws := 0.0
	var prims := 0.0
	while Time.get_ticks_usec() - t0 < int(secs * 1e6):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		frames += 1
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	var lights := get_tree().root.find_children("*", "OmniLight3D", true, false).size()
	var shadow_lights := 0
	for l in get_tree().root.find_children("*", "Light3D", true, false):
		if (l as Light3D).shadow_enabled:
			shadow_lights += 1
	print("bench %s: %.1f fps (%.2f ms avg, %.1f ms worst) draws %.0f prims %.0fk nodes %d omni %d shadowed %d physics %.2f ms" % [scene.get_file(), 1000.0 / ms, ms, worst, draws / frames, prims / frames / 1000.0, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), lights, shadow_lights, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	if "--breakdown" in OS.get_cmdline_user_args():
		await _breakdown(lvl)
	get_tree().quit()


## Hide one kind of node at a time and report how many primitives it was costing.
func _breakdown(lvl: Node) -> void:
	var groups: Dictionary[String, Array] = {"multimesh": [], "mesh": [], "gpu_particles": [], "cpu_particles": []}
	for n in lvl.find_children("*", "MultiMeshInstance3D", true, false):
		groups["multimesh"].append(n)
	for n in lvl.find_children("*", "MeshInstance3D", true, false):
		groups["mesh"].append(n)
	for n in lvl.find_children("*", "GPUParticles3D", true, false):
		groups["gpu_particles"].append(n)
	for n in lvl.find_children("*", "CPUParticles3D", true, false):
		groups["cpu_particles"].append(n)
	var base := await _prims()
	for k: String in groups:
		for n: Node3D in groups[k]:
			n.visible = false
		var p := await _prims()
		print("  without %s (%d): %.0fk prims (saves %.0fk)" % [k, groups[k].size(), p / 1000.0, (base - p) / 1000.0])
		for n: Node3D in groups[k]:
			n.visible = true
	# Biggest single meshes by triangle count, grouped by parent name.
	var mesh_tris: Dictionary[String, int] = {}
	var mesh_n: Dictionary[String, int] = {}
	for n: MeshInstance3D in groups["mesh"]:
		if n.mesh == null or not n.is_visible_in_tree():
			continue
		var tris := 0
		for si in n.mesh.get_surface_count():
			var arr := n.mesh.surface_get_arrays(si)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			tris += (idx as PackedInt32Array).size() / 3 if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var key := "%s/%s" % [String(n.get_parent().name).rstrip("0123456789").substr(0, 24), n.mesh.get_class()]
		mesh_tris[key] = mesh_tris.get(key, 0) + tris
		mesh_n[key] = mesh_n.get(key, 0) + 1
	var mk := mesh_tris.keys()
	mk.sort_custom(func(a: String, b: String) -> bool: return mesh_tris[a] > mesh_tris[b])
	for k: String in mk.slice(0, 12):
		print("  mesh %s x%d: %dk tris" % [k, mesh_n[k], mesh_tris[k] / 1000])
	# Biggest multimesh sources by name.
	var by_name: Dictionary[String, int] = {}
	for n: MultiMeshInstance3D in groups["multimesh"]:
		var mm := n.multimesh
		if mm == null or mm.mesh == null:
			continue
		var tris := 0
		for si in mm.mesh.get_surface_count():
			var arr := mm.mesh.surface_get_arrays(si)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			tris += (idx as PackedInt32Array).size() / 3 if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		var key := String(n.name).rstrip("0123456789")
		by_name[key] = by_name.get(key, 0) + tris * mm.instance_count
	var keys := by_name.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return by_name[a] > by_name[b])
	for k: String in keys.slice(0, 12):
		print("  multimesh %s: %dk tris total" % [k, by_name[k] / 1000])


func _prims() -> float:
	for i in 5:
		await get_tree().process_frame
	return Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
