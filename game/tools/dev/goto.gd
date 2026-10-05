extends Node
## Dev tool: boots like the game (real save), goes to the hub, then walks through the Rootway to a
## world, and waits. Godot --path game res://tools/dev/goto.tscn -- --world=world_02 [--seconds=8]


func _ready() -> void:
	# The scene changes free the current scene, so the work runs on a copy parked under root.
	if not has_meta(&"keeper"):
		var keeper := Node.new()
		keeper.set_script(get_script())
		keeper.set_meta(&"keeper", true)
		get_tree().root.add_child.call_deferred(keeper)
		return
	var world := &"world_02"
	var secs := 8.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--world="):
			world = StringName(a.trim_prefix("--world="))
		elif a.begins_with("--seconds="):
			secs = float(a.trim_prefix("--seconds="))
	await get_tree().create_timer(0.5).timeout
	Router.go_to(Progress.HUB_SCENE, &"hub_arrival")
	await get_tree().create_timer(3.0).timeout
	var w := Progress.world_def(world)
	print("goto: entering ", world)
	Router.go_to(w.id, w.entrance_spawn)
	await get_tree().create_timer(secs).timeout
	print("goto: still running after ", secs, " s in ", Router.current_scene_id)
	get_tree().quit()
