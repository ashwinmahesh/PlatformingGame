class_name IceFloe
extends StaticBody3D
## Build 7 Frost Burst: water in front of the hero freezes into floes you can stand on for a while.

const LIFE := 10.0

var _t: float = 0.0
var _mi: MeshInstance3D


static func spawn(parent: Node, top: Vector3) -> IceFloe:
	for n in parent.get_tree().get_nodes_in_group(&"ice_floe"):
		if (n as Node3D).global_position.distance_to(top) < 1.5:
			(n as IceFloe)._t = 0.0
			return n as IceFloe
	var f := IceFloe.new()
	parent.add_child(f)
	f.global_position = top
	return f


func _ready() -> void:
	add_to_group(&"ice_floe")
	collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	set_meta(&"slippery", true)
	var c := CylinderShape3D.new()
	c.radius = 2.0
	c.height = 0.6
	Kit.add_shape(self, c, Vector3(0.0, -0.3, 0.0))
	var m := CylinderMesh.new()
	m.top_radius = 2.0
	m.bottom_radius = 1.7
	m.height = 0.6
	m.radial_segments = 7
	_mi = Kit.mesh_instance(self, m, Kit.mat(&"water_light", 0.03, &"foam"), Vector3(0.0, -0.3, 0.0))
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t > LIFE - 1.5:
		position.y -= delta * 0.4
	if _t > LIFE:
		queue_free()
