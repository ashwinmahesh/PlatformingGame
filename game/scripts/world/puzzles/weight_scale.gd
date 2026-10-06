class_name WeightScale
extends Node3D
## Build 7 puzzle: two pans on a beam. Whatever stands on a pan (the hero, a crate) weighs it
## down and lifts the other by `travel`. Put a crate on one pan and ride the other one up.

var pan_size: Vector2 = Vector2(4.0, 4.0)
var spacing: float = 10.0
var travel: float = 6.0
var _pans: Array[AnimatableBody3D] = []
var _zones: Array[Area3D] = []
var _tilt: float = 0.0


func _ready() -> void:
	Kit.pillar(self, Vector3(0.0, travel + 2.0, 0.0), 0.5, travel + 2.0, &"bark_dark", &"gold")
	Kit.mesh_instance(self, RoundMesh.box(Vector3(spacing + 1.0, 0.3, 0.4), 0.1), Kit.mat(&"bark_mid"), Vector3(0.0, travel + 2.1, 0.0)).name = "Beam"
	for side: float in [-1.0, 1.0]:
		var pan := AnimatableBody3D.new()
		pan.collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
		pan.position = Vector3(side * spacing * 0.5, travel * 0.5, 0.0)
		add_child(pan)
		var b := BoxShape3D.new()
		b.size = Vector3(pan_size.x, 0.5, pan_size.y)
		Kit.add_shape(pan, b, Vector3(0.0, -0.25, 0.0))
		Kit.mesh_instance(pan, RoundMesh.box(b.size, 0.15), Kit.mat(&"gold", 0.03), Vector3(0.0, -0.25, 0.0))
		var zone := Area3D.new()
		zone.collision_layer = 0
		zone.collision_mask = Layers.PLAYER_BODY | Layers.WORLD
		var zs := BoxShape3D.new()
		zs.size = Vector3(pan_size.x - 0.4, 1.6, pan_size.y - 0.4)
		Kit.add_shape(zone, zs, Vector3(0.0, 0.85, 0.0))
		pan.add_child(zone)
		_pans.append(pan)
		_zones.append(zone)


func _weight(i: int) -> int:
	var n := 0
	for b in _zones[i].get_overlapping_bodies():
		if b is Player or b is PushBlock:
			n += 1
	return n


func _physics_process(delta: float) -> void:
	var target := clampf(float(_weight(0) - _weight(1)), -1.0, 1.0)
	_tilt = move_toward(_tilt, target, delta * 0.6)
	_pans[0].position.y = travel * 0.5 - _tilt * travel * 0.5
	_pans[1].position.y = travel * 0.5 + _tilt * travel * 0.5
