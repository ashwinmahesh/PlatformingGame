extends Node
## Dev tool: prints a coarse top-down height map of a level (max solid top per cell) so new
## layers can be placed clear of what's there. Godot --headless res://tools/dev/heightmap.tscn -- --scene=...

const CELL := 8.0
const HALF := 200.0


func _ready() -> void:
	var scene := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.trim_prefix("--scene=")
	var level: Node = (load(scene) as PackedScene).instantiate()
	add_child(level)
	for i in 10:
		await get_tree().physics_frame
	var space := get_viewport().get_world_3d().direct_space_state
	var chars := " .:-=+*#%@"
	var n := int(HALF * 2.0 / CELL)
	print("legend: ' ' none/void, digits = top height in metres / 4 (0-9), '~' water, '^' >= 40 m")
	var header := "      "
	for x in n:
		header += str(abs(int(-HALF + x * CELL)) / 10 % 10) if x % 5 == 0 else " "
	print(header)
	for z in n:
		var row := "%5d " % int(-HALF + z * CELL)
		for x in n:
			var p := Vector3(-HALF + (x + 0.5) * CELL, 120.0, -HALF + (z + 0.5) * CELL)
			var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 200.0, Layers.WORLD)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				row += " "
				continue
			var y := (hit["position"] as Vector3).y
			if y < -8.0:
				row += " "
			elif y >= 40.0:
				row += "^"
			else:
				row += str(clampi(int(floor(maxf(y, 0.0) / 4.0)), 0, 9))
		print(row)
	get_tree().quit()
