class_name Fireball
extends Node3D
## The hero's first magic (Build 5, learned by clearing Glimmerbrook): a bright ball of flame that
## flies straight ahead (or at the lock-on target). It hits like a sword slash through the
## CombatResolver, lights lanterns and crystal switches, burns brambles and melts ice.

const SPEED := 24.0
const LIFE := 1.25

var dir: Vector3 = Vector3.FORWARD
var attack_id: int = 0
var radius: float = 0.55
var shape: SphereShape3D
var done: bool = false
var _t: float = 0.0
var _core: Node3D


func _ready() -> void:
	add_to_group(&"player_projectile")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	shape = SphereShape3D.new()
	shape.radius = radius
	_core = Node3D.new()
	add_child(_core)
	var core := SphereMesh.new()
	core.radius = 0.32
	core.height = 0.64
	var m := Kit.unique_mat(&"gold")
	m.set_shader_parameter(&"flash", 1.4)
	m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	Kit.mesh_instance(_core, core, m)
	var glow := SphereMesh.new()
	glow.radius = 0.55
	glow.height = 1.1
	Kit.mesh_instance(_core, glow, Fx.fx_mat(Color(Palette.color(&"sunset_orange") * 1.6, 0.5)))
	for i in 4:
		var flame := PrismMesh.new()
		flame.size = Vector3(0.3, 0.6, 0.3)
		var f := Kit.mesh_instance(_core, flame, Fx.fx_mat(Color(Palette.color(&"roof_red") * 1.4, 0.75)), Vector3(cos(i * PI * 0.5) * 0.35, 0.0, sin(i * PI * 0.5) * 0.35))
		f.rotation = Vector3(PI * 0.5, i * PI * 0.5, 0.0)
	var light := OmniLight3D.new()
	light.light_color = Palette.color(&"sunset_orange")
	light.light_energy = 2.0
	light.omni_range = 5.0
	add_child(light)
	var trail := CPUParticles3D.new()
	trail.amount = 24
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector3(0.0, 2.0, 0.0)
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.spread = 180.0
	var dot := SphereMesh.new()
	dot.radius = 0.14
	dot.height = 0.28
	trail.mesh = dot
	trail.material_override = Fx.fx_mat(Color(1.8, 1.0, 0.3, 0.8))
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	trail.scale_amount_curve = curve
	add_child(trail)


func attack_dict() -> Dictionary:
	return {"id": attack_id, "damage": 1, "kind": &"fireball", "from": global_position - dir * 1.5, "hitstop": 3, "knockback": 1.2}


func _physics_process(delta: float) -> void:
	if done:
		return
	_t += delta
	_core.rotation += Vector3(7.0, 11.0, 5.0) * delta
	var step := dir * SPEED * delta
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step + dir * radius * 0.6, Layers.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position = (hit["position"] as Vector3) - dir * 0.2
		var c := hit["collider"] as Node
		if c != null and c.has_method(&"receive_player_attack"):
			c.call(&"receive_player_attack", attack_dict(), null)
		pop()
		return
	global_position += step
	if _t >= LIFE:
		pop()


func pop() -> void:
	if done:
		return
	done = true
	Fx.burst(get_parent(), global_position, Palette.color(&"sunset_orange"), 14, 4.0, 0.12, -3.0, 0.4)
	Fx.burst(get_parent(), global_position, Palette.color(&"gold"), 8, 2.5, 0.1, 1.0, 0.3)
	AudioDirector.play(&"fire_pop", -4.0)
	queue_free()
