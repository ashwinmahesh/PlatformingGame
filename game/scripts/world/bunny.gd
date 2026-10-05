class_name Bunny
extends Node3D
## A harmless wild bunny (Build 4: "more alive"): hops around its home and scampers away from you.

var color_name: StringName = &"cloth_cream"
var _home: Vector3
var _from: Vector3
var _to: Vector3
var _t: float = 1.0
var _wait: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _visual: Node3D


func _ready() -> void:
	_rng.seed = hash(position)
	_home = position
	color_name = [&"cloth_cream", &"wood_plank", &"stone_light"][_rng.randi() % 3]
	_visual = Node3D.new()
	add_child(_visual)
	_ball(0.28, color_name, Vector3(0.0, 0.25, 0.0))
	_ball(0.2, color_name, Vector3(0.0, 0.5, -0.2))
	_ball(0.1, &"foam", Vector3(0.0, 0.3, 0.27))
	for side: float in [-1.0, 1.0]:
		var ear := CapsuleMesh.new()
		ear.radius = 0.06
		ear.height = 0.34
		var e := Kit.mesh_instance(_visual, ear, Kit.mat(color_name, 0.015), Vector3(0.07 * side, 0.78, -0.18))
		e.rotation.z = 0.15 * side
		_ball(0.035, &"bark_dark", Vector3(0.09 * side, 0.55, -0.37))
	_snap_to_ground()
	_from = position
	_to = position


func _ball(r: float, c: StringName, p: Vector3) -> void:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	Kit.mesh_instance(_visual, s, Kit.mat(c, 0.02), p)


func _ground(at: Vector3) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2.0, at + Vector3.DOWN * 4.0, Layers.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return null if hit.is_empty() else hit["position"]


func _snap_to_ground() -> void:
	var g: Variant = _ground(position)
	if g != null:
		position = g as Vector3


func _process(delta: float) -> void:
	if _t < 1.0:
		_t = minf(_t + delta * 3.0, 1.0)
		position = _from.lerp(_to, _t) + Vector3.UP * sin(_t * PI) * 0.45
		return
	_wait -= delta
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	var flee := p != null and p.global_position.distance_to(global_position) < 5.0
	if _wait > 0.0 and not flee:
		return
	var dir: Vector3
	if flee:
		dir = (global_position - p.global_position).normalized()
	else:
		var a := _rng.randf() * TAU
		dir = Vector3(cos(a), 0.0, sin(a))
		if position.distance_to(_home) > 6.0:
			dir = (_home - position).normalized()
	dir.y = 0.0
	var g: Variant = _ground(position + dir * 1.2)
	if g == null or absf((g as Vector3).y - position.y) > 0.8:
		_wait = 0.5
		return
	_from = position
	_to = g as Vector3
	_t = 0.0
	_wait = 0.15 if flee else _rng.randf_range(0.6, 2.5)
	_visual.basis = Basis.looking_at(dir.normalized(), Vector3.UP)
