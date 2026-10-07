extends TestCase

func test_merge_kills_cap() -> void:
	var root := Node3D.new()
	add_child(root)
	Whimsy.mushroom(root, Vector3(0.0, 0.0, 0.0), 6.0, 5.0, &"red")
	Whimsy.mushroom(root, Vector3(10.0, 0.0, 0.0), 6.0, 5.0, &"red")
	await ticks(2)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0.0, 15.0, 0.0), Vector3(0.0, 0.5, 0.0), Layers.WORLD)
	print("before merge ", space.intersect_ray(q).get("position", "none"))
	print("merged ", StaticMerge.merge(root))
	await ticks(2)
	print("after merge ", space.intersect_ray(q).get("position", "none"))
	print("bodies left ", root.find_children("*", "StaticBody3D", true, false).size())
