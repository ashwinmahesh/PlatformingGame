class_name GravityOrb
extends Node3D
## Build 7 Gravity Orb: a slow violet orb. When it hits something (or after 0.7 s) it opens a
## vortex that drags nearby monsters in for 1.5 s, then pops, hurting everything in the middle.

const SPEED := 10.0
const PULL_RADIUS := 7.0
const POP_RADIUS := 3.2

var dir: Vector3 = Vector3.FORWARD
var attack_id: int = 0
var open: bool = false
var popped: bool = false
var _t: float = 0.0
var _vortex: MeshInstance3D


func _ready() -> void:
	add_to_group(&"gravity_orb")
	var s := SphereMesh.new()
	s.radius = 0.45
	s.height = 0.9
	var m := Fx.fx_mat(Color(Palette.color(&"crystal_violet"), 0.9))
	Kit.mesh_instance(self, s, m)
	var light := OmniLight3D.new()
	light.light_color = Palette.color(&"crystal_violet")
	light.omni_range = 5.0
	add_child(light)


func _physics_process(delta: float) -> void:
	if popped:
		return
	_t += delta
	if not open:
		var step := dir * SPEED * delta
		var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step * 2.0, Layers.WORLD | Layers.ENEMY_BODY)
		if _t > 0.7 or not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			_open()
		else:
			global_position += step
		return
	_vortex.rotation.y += delta * 6.0
	_vortex.scale = Vector3.ONE * (0.6 + 0.4 * sin(_t * 12.0))
	for n in get_tree().get_nodes_in_group(&"enemy"):
		var e := n as Node3D
		if e == null or e is BossBase:
			continue
		var to := global_position - e.global_position
		to.y = 0.0
		if to.length() < PULL_RADIUS and to.length() > 0.6:
			e.global_position += to.normalized() * minf(5.0 * delta, to.length() - 0.6)
	if _t > 2.2:
		popped = true
		Fx.burst(get_parent(), global_position, Palette.color(&"crystal_violet"), 30, 6.0, 0.12, 0.0, 0.5)
		AudioDirector.play(&"poof", 0.0, 0.6)
		get_tree().create_timer(0.1).timeout.connect(queue_free)


func _open() -> void:
	open = true
	_t = 0.7
	var tm := TorusMesh.new()
	tm.inner_radius = 0.6
	tm.outer_radius = 1.4
	_vortex = Kit.mesh_instance(self, tm, Fx.fx_mat(Color(Palette.color(&"crystal_violet"), 0.6)))
	AudioDirector.play(&"spin", -4.0, 0.5)


func pop_attack_dict() -> Dictionary:
	return {"id": attack_id, "damage": 2, "kind": &"orb", "from": global_position, "hitstop": 4, "knockback": 2.0}
