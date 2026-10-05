class_name PressurePlate
extends Area3D
## A big stone button set in the floor (Build 6 world puzzles). Pressed while the hero or a
## PushBlock stands on it; emits `changed` on each change.

signal changed(pressed: bool)

var radius: float = 1.6
var pressed: bool = false
var _cap: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER_BODY | Layers.WORLD
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = 1.2
	Kit.add_shape(self, c, Vector3(0.0, 0.6, 0.0))
	var ring := CylinderMesh.new()
	ring.top_radius = radius + 0.3
	ring.bottom_radius = radius + 0.4
	ring.height = 0.2
	Kit.mesh_instance(self, ring, Kit.mat(&"stone_dark"), Vector3(0.0, 0.1, 0.0))
	var cap := CylinderMesh.new()
	cap.top_radius = radius
	cap.bottom_radius = radius
	cap.height = 0.3
	_cap = Kit.mesh_instance(self, cap, Kit.unique_mat(&"gold"), Vector3(0.0, 0.3, 0.0))


func _physics_process(_delta: float) -> void:
	var on := false
	for b in get_overlapping_bodies():
		if b is Player or b is PushBlock:
			on = true
	if on != pressed:
		pressed = on
		_cap.position.y = 0.12 if on else 0.3
		(_cap.material_override as ShaderMaterial).set_shader_parameter(&"flash", 0.5 if on else 0.0)
		AudioDirector.play(&"ui_blip", -4.0, 1.3 if on else 0.8)
		changed.emit(on)
