class_name Quicksand
extends Area3D
## Sinking sand: walking through it is slow (Build 4, Sunscorch Canyon). Jump across instead.

var radius: float = 5.0


func _ready() -> void:
	collision_layer = Layers.INTERACT
	collision_mask = Layers.PLAYER_BODY
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = 1.2
	Kit.add_shape(self, c, Vector3(0.0, 0.3, 0.0))
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.06
	disc.radial_segments = 32
	Kit.mesh_instance(self, disc, Kit.mat(&"wood_warm"), Vector3(0.0, 0.03, 0.0))
	for i in 3:
		var swirl := TorusMesh.new()
		swirl.inner_radius = radius * (0.25 + i * 0.22)
		swirl.outer_radius = swirl.inner_radius + 0.15
		var t := Kit.mesh_instance(self, swirl, Kit.mat(&"bark_light"), Vector3(0.0, 0.05, 0.0))
		t.scale.y = 0.2


func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		var p := b as Player
		if p != null and p.is_on_floor():
			p.apply_slow(0.25)
