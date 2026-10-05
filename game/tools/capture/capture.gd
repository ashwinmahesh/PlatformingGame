extends Node
## Capture tool (plan Appendix D). Loads a scene, visits each capture_point marker, saves PNGs.
## make capture SCENE=res://scenes/levels/w1/glimmerbrook.tscn   (needs a window, not --headless)


func _ready() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	Router.pending_spawn = StringName(str(args.get("spawn", "")))
	var level: Node = (load(str(args["scene"])) as PackedScene).instantiate()
	add_child(level)
	for i in 30:
		await get_tree().process_frame
	var hud := get_tree().get_first_node_in_group(&"hud") as CanvasLayer
	if hud != null and str(args.get("hud", "0")) != "1":
		hud.visible = false
	var cam := Camera3D.new()
	cam.far = 400.0
	add_child(cam)
	DirAccess.make_dir_recursive_absolute(str(args["out"]))
	var points := get_tree().get_nodes_in_group(&"capture_point")
	if str(args.get("player_cam", "0")) == "1":
		points = [null]
	for point: Node in points:
		if point != null:
			cam.make_current()
			cam.global_transform = (point as Node3D).global_transform
			cam.fov = float(point.get_meta(&"fov", 60.0))
		for i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var file_name := "player_view" if point == null else String(point.name)
		img.save_png("%s/%s.png" % [args["out"], file_name])
		print("capture: ", file_name)
	AudioDirector.shutdown()
	get_tree().quit(0)


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {"scene": "", "out": OS.get_user_data_dir() + "/captures"}
	for a in raw:
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			out[kv[0]] = kv[1]
	return out
