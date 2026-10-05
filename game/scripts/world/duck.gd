class_name Duck
extends Node3D
## A duck paddling in slow circles on a pond or river (Build 4: "more alive").

var radius: float = 4.0
var speed: float = 0.25
var _center: Vector3
var _t: float = 0.0
var _visual: Node3D


func _ready() -> void:
	_center = position
	_t = fmod(position.x * 0.37 + position.z * 0.11, TAU)
	_visual = Node3D.new()
	add_child(_visual)
	_ball(0.32, &"cloth_cream", Vector3(0.0, 0.15, 0.0), Vector3(1.0, 0.7, 1.4))
	_ball(0.2, &"leaf_dark", Vector3(0.0, 0.5, -0.32), Vector3.ONE)
	_ball(0.09, &"gold", Vector3(0.0, 0.46, -0.52), Vector3(1.0, 0.6, 1.4))
	for side: float in [-1.0, 1.0]:
		_ball(0.03, &"bark_dark", Vector3(0.1 * side, 0.55, -0.45), Vector3.ONE)


func _ball(r: float, c: StringName, p: Vector3, s: Vector3) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	var mi := Kit.mesh_instance(_visual, m, Kit.mat(c, 0.02), p)
	mi.scale = s


func _process(delta: float) -> void:
	_t += delta * speed
	var p := _center + Vector3(cos(_t) * radius, sin(_t * 3.0) * 0.03, sin(_t) * radius)
	var ahead := _center + Vector3(cos(_t + 0.1) * radius, 0.0, sin(_t + 0.1) * radius)
	position = p
	var d := ahead - p
	d.y = 0.0
	if d.length() > 0.001:
		_visual.basis = Basis.looking_at(d.normalized(), Vector3.UP)
