class_name PushBlock
extends AnimatableBody3D
## A big block you shove by walking into it (Build 6 world puzzles). Keep pushing for a moment and
## it slides one step (`step` metres) along the side you pushed, if nothing is in the way. Push it
## under a high ledge, onto a pressure pad, or into a gap.

signal moved(to: Vector3)

var size: Vector3 = Vector3(3.0, 3.0, 3.0)
var step: float = 3.0
var color_name: StringName = &"wood_warm"
var _push_ticks: int = 0
var _push_dir: Vector3 = Vector3.ZERO
var _sliding: bool = false
var _probe: Area3D


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	collision_mask = 0
	sync_to_physics = false
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, size.y * 0.5, 0.0))
	Kit.mesh_instance(self, RoundMesh.box(size, 0.3), Kit.mat(color_name, 0.0, &"gold"), Vector3(0.0, size.y * 0.5, 0.0))
	for side: float in [-1.0, 1.0]:
		var arrow := PrismMesh.new()
		arrow.size = Vector3(0.9, 0.8, 0.1)
		var a := Kit.mesh_instance(self, arrow, Kit.mat(&"gold"), Vector3(0.0, size.y * 0.55, side * (size.z * 0.5 + 0.02)))
		a.rotation.z = -PI * 0.5
	_probe = Area3D.new()
	_probe.collision_layer = 0
	_probe.collision_mask = Layers.PLAYER_BODY
	var pb := BoxShape3D.new()
	pb.size = size + Vector3(1.0, -0.4, 1.0)
	Kit.add_shape(_probe, pb, Vector3(0.0, size.y * 0.5, 0.0))
	add_child(_probe)


func _physics_process(_delta: float) -> void:
	if _sliding:
		return
	var pushing := false
	for b in _probe.get_overlapping_bodies():
		var p := b as Player
		if p == null or not p.is_grounded():
			continue
		var to := global_position - p.global_position
		to.y = 0.0
		var inp := p.last_input.move
		if inp.length() < 0.5:
			continue
		var want := Basis(Vector3.UP, p.camera_yaw) * Vector3(inp.x, 0.0, -inp.y)
		var axis := Vector3(signf(to.x), 0.0, 0.0) if absf(to.x) > absf(to.z) else Vector3(0.0, 0.0, signf(to.z))
		if want.normalized().dot(axis) > 0.7:
			pushing = true
			if axis != _push_dir:
				_push_ticks = 0
			_push_dir = axis
	_push_ticks = _push_ticks + 1 if pushing else 0
	if _push_ticks >= 24:
		_push_ticks = 0
		_try_slide(_push_dir)


func _try_slide(dir: Vector3) -> void:
	var q := PhysicsShapeQueryParameters3D.new()
	var b := BoxShape3D.new()
	b.size = size * 0.9
	q.shape = b
	q.transform = Transform3D(Basis(), global_position + dir * step + Vector3.UP * size.y * 0.5)
	q.collision_mask = Layers.WORLD
	q.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty():
		AudioDirector.play(&"hit", -6.0, 0.6)
		return
	# Needs floor under the new spot (no shoving blocks into the void).
	var ray := PhysicsRayQueryParameters3D.create(global_position + dir * step + Vector3.UP * 0.5, global_position + dir * step + Vector3.DOWN * 1.0, Layers.WORLD)
	ray.exclude = [get_rid()]
	if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		return
	_sliding = true
	AudioDirector.play(&"boss_roll", -8.0, 1.6)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "global_position", global_position + dir * step, 0.35)
	t.tween_callback(func() -> void:
		_sliding = false
		moved.emit(global_position))
