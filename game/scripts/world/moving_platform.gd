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
var _origin: Vector3
var _t: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = Layers.WORLD
	collision_mask = 0
	_origin = position
	_t = phase * period
	if rounded:
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
