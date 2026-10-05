class_name Tumbleweed
extends Node3D
## A tumbleweed bouncing across the sand with the wind (Build 4, Sunscorch Canyon: "more alive").
## It rolls along a line, fades out at the far end and starts again. Harmless, no collision.

var dir: Vector3 = Vector3(1.0, 0.0, 0.25).normalized()
var span: float = 90.0
var speed: float = 4.5
var phase: float = 0.0
var _start: Vector3
var _t: float = 0.0
var _ball: Node3D


func _ready() -> void:
	_start = position
	_t = phase
	_ball = Node3D.new()
	add_child(_ball)
	for i in 4:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.48
		ring.outer_radius = 0.58
		ring.rings = 12
		ring.ring_segments = 6
		var r := Kit.mesh_instance(_ball, ring, Kit.mat(&"bark_light" if i % 2 == 0 else &"wood_plank", 0.012))
		r.rotation = Vector3(i * 0.8, i * 1.3, i * 0.4)
	for i in 6:
		var twig := CylinderMesh.new()
		twig.top_radius = 0.025
		twig.bottom_radius = 0.025
		twig.height = 1.0
		var t := Kit.mesh_instance(_ball, twig, Kit.mat(&"bark_mid"))
		t.rotation = Vector3(i * 1.1, i * 0.7, i * 1.9)


func _process(delta: float) -> void:
	_t += delta
	var d := fmod(_t * speed, span)
	var fade := clampf(minf(d, span - d) / 5.0, 0.0, 1.0)
	position = _start + dir * d + Vector3.UP * (0.55 + absf(sin(_t * 2.6)) * 0.9)
	scale = Vector3.ONE * maxf(fade, 0.02)
	_ball.rotate(dir.cross(Vector3.DOWN).normalized(), delta * speed / 0.55)
