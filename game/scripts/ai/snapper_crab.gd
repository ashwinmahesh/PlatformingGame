class_name SnapperCrab
extends Hoppy
## A big red crab (Build 5, Bubbleton Reef; inspired by Dragon Quest's crab monsters, our own
## design). Same rules as the Hoppy: it clacks its claws, then charges sideways in a straight
## line; dodge and it skids on, hit a wall and it's dizzy and open.

var _claws: Array[Node3D] = []
var _pivot: Node3D


func _init() -> void:
	max_hp = 3
	body_radius = 0.75
	body_half_height = 0.45
	body_center = 0.55
	color_name = &"roof_red"


func build_body() -> void:
	# Built side-on: crabs scuttle sideways.
	_pivot = Node3D.new()
	_pivot.rotation.y = PI * 0.5
	_visual.add_child(_pivot)
	var shell := ball(_pivot, 0.75, &"roof_red", Vector3(0.0, 0.55, 0.0))
	shell.scale = Vector3(1.25, 0.65, 1.0)
	ball(_pivot, 0.5, &"coral_orange", Vector3(0.0, 0.42, 0.0), 0.0).scale = Vector3(1.2, 0.5, 0.9)
	for side: float in [-1.0, 1.0]:
		var stalk := CapsuleMesh.new()
		stalk.radius = 0.06
		stalk.height = 0.45
		Kit.mesh_instance(_pivot, stalk, Kit.mat(&"roof_red"), Vector3(0.22 * side, 0.95, -0.35))
		ball(_pivot, 0.13, &"mush_spot", Vector3(0.22 * side, 1.18, -0.35), 0.02)
		ball(_pivot, 0.06, &"ink_navy", Vector3(0.22 * side, 1.2, -0.46), 0.0)
		var claw_root := Node3D.new()
		claw_root.position = Vector3(0.95 * side, 0.6, -0.45)
		_pivot.add_child(claw_root)
		var claw := ball(claw_root, 0.32, &"roof_red", Vector3.ZERO)
		claw.scale = Vector3(1.0, 0.8, 1.3)
		var pincer := ball(claw_root, 0.16, &"sunset_orange", Vector3(0.0, 0.0, -0.35), 0.02)
		pincer.scale = Vector3(0.6, 0.5, 1.4)
		_claws.append(claw_root)
		for i in 3:
			var leg := CapsuleMesh.new()
			leg.radius = 0.06
			leg.height = 0.6
			var l := Kit.mesh_instance(_pivot, leg, Kit.mat(&"roof_red"), Vector3(0.8 * side, 0.25, -0.15 + i * 0.25))
			l.rotation.z = 0.9 * side


func animate(delta: float) -> void:
	super.animate(delta)
	for i in _claws.size():
		var c := _claws[i]
		c.rotation.x = sin(state_ticks * (0.9 if state == S.WINDUP else 0.15) + i) * (0.5 if state == S.WINDUP else 0.15)
