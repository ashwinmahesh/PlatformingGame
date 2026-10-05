class_name MovingPlatform
extends AnimatableBody3D
## Drifting log / lifting rock. Moves in the physics tick so riders inherit its velocity.

var travel: Vector3 = Vector3(4.0, 0.0, 0.0)
var period: float = 4.0
var phase: float = 0.0
var spin_speed: float = 0.0
var size: Vector3 = Vector3(3.0, 0.5, 1.4)
var color_name: StringName = &"bark_light"
var rounded: bool = true
## Raft: three logs lashed side by side with a flat top (Build 3: easier to land on).
var raft: bool = false
var _origin: Vector3
var _t: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = Layers.WORLD
	collision_mask = 0
	_origin = position
	_t = phase * period
	if raft:
		_build_raft()
	elif rounded:
		var shape := CylinderShape3D.new()
		shape.radius = size.z * 0.5
		shape.height = size.x
		var cs := Kit.add_shape(self, shape)
		cs.rotation.z = PI * 0.5
		var cm := CylinderMesh.new()
		cm.top_radius = size.z * 0.5
		cm.bottom_radius = size.z * 0.5
		cm.height = size.x
		cm.radial_segments = 10
		var mi := Kit.mesh_instance(self, cm, Kit.mat(color_name, 0.02))
		mi.rotation.z = PI * 0.5
		var moss := BoxMesh.new()
		moss.size = Vector3(size.x * 0.8, 0.06, size.z * 0.5)
		Kit.mesh_instance(self, moss, Kit.mat(&"moss"), Vector3(0.0, size.z * 0.5 - 0.02, 0.0))
	else:
		var b := BoxShape3D.new()
		b.size = size
		Kit.add_shape(self, b)
		var bm := BoxMesh.new()
		bm.size = size
		Kit.mesh_instance(self, bm, Kit.mat(color_name, 0.02))


func _physics_process(delta: float) -> void:
	_t += delta
	var k := sin(_t / period * TAU) * 0.5 + 0.5
	position = _origin + travel * (k - 0.5)
	if spin_speed != 0.0:
		rotation.y += spin_speed * delta


## size.x = length, size.z = width. Flat collision top so landings never slide off a curve.
func _build_raft() -> void:
	var b := BoxShape3D.new()
	b.size = Vector3(size.x, 0.9, size.z)
	Kit.add_shape(self, b, Vector3(0.0, -0.45, 0.0))
	var r := size.z / 6.0
	for i in 3:
		var cm := CylinderMesh.new()
		cm.top_radius = r
		cm.bottom_radius = r
		cm.height = size.x * (0.92 + 0.06 * float(i % 2))
		cm.radial_segments = 20
		var mi := Kit.mesh_instance(self, cm, Kit.mat(color_name, 0.03), Vector3(0.0, -r, (float(i) - 1.0) * r * 2.0))
		mi.rotation.z = PI * 0.5
	for x: float in [-size.x * 0.3, size.x * 0.3]:
		var band := BoxMesh.new()
		band.size = Vector3(0.25, 0.12, size.z + 0.1)
		Kit.mesh_instance(self, band, Kit.mat(&"thatch"), Vector3(x, 0.02, 0.0))
