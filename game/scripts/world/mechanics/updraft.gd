class_name Updraft
extends Area3D
## A wind column that lifts the hero while they're airborne inside it (Build 4, Cloudtop Steps).

var size: Vector3 = Vector3(4.0, 12.0, 4.0)
var lift: float = 9.0


func _ready() -> void:
	collision_layer = Layers.INTERACT
	collision_mask = Layers.PLAYER_BODY
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, size.y * 0.5, 0.0))
	var streaks := CPUParticles3D.new()
	streaks.amount = 40
	streaks.lifetime = 1.4
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	streaks.emission_box_extents = Vector3(size.x * 0.45, 0.2, size.z * 0.45)
	streaks.direction = Vector3.UP
	streaks.spread = 3.0
	streaks.initial_velocity_min = size.y * 0.6
	streaks.initial_velocity_max = size.y * 0.8
	streaks.gravity = Vector3.ZERO
	var m := BoxMesh.new()
	m.size = Vector3(0.06, 0.9, 0.06)
	streaks.mesh = m
	streaks.material_override = Fx.fx_mat(Color(Palette.color(&"foam"), 0.7))
	add_child(streaks)
	var swirl := CylinderMesh.new()
	swirl.top_radius = size.x * 0.5
	swirl.bottom_radius = size.x * 0.5
	swirl.height = size.y
	swirl.cap_top = false
	swirl.cap_bottom = false
	Kit.mesh_instance(self, swirl, Fx.fx_mat(Color(Palette.color(&"sky_top"), 0.12)), Vector3(0.0, size.y * 0.5, 0.0))


func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		var p := b as Player
		if p != null and p.state in [Player.State.NORMAL, Player.State.ATTACK]:
			p.external_lift = lift
