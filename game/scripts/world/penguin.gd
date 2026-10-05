class_name Penguin
extends Bunny
## A waddling penguin (Build 5, Frostfang Peak: "more alive"). Same wander-and-scurry brain as
## the bunny, with a penguin body.


func _ready() -> void:
	_rng.seed = hash(position)
	_home = position
	_visual = Node3D.new()
	add_child(_visual)
	_ball(0.34, &"ink_navy", Vector3(0.0, 0.38, 0.0))
	_ball(0.27, &"mush_spot", Vector3(0.0, 0.36, -0.12))
	_ball(0.24, &"ink_navy", Vector3(0.0, 0.78, 0.0))
	_ball(0.1, &"sunset_orange", Vector3(0.0, 0.76, -0.24))
	for side: float in [-1.0, 1.0]:
		_ball(0.045, &"mush_spot", Vector3(0.1 * side, 0.86, -0.2))
		_ball(0.1, &"sunset_orange", Vector3(0.14 * side, 0.04, -0.08))
		var wing := SphereMesh.new()
		wing.radius = 0.16
		wing.height = 0.5
		Kit.mesh_instance(_visual, wing, Kit.mat(&"ink_navy", 0.02), Vector3(0.33 * side, 0.42, 0.0))
	_snap_to_ground()
	_from = position
	_to = position
