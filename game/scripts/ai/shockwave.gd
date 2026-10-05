class_name Shockwave
extends Node3D
## Mother Gloop's landing ring: 0.5 m tall, spreads at 6 m/s (plan §8.5). Jump over it.

const SPEED := 6.0
const HEIGHT := 0.5
const BAND := 0.45

var ground_y: float = 0.0
var max_radius: float = 17.0
var radius: float = 0.5
var _mi: MeshInstance3D
var _mat: ShaderMaterial


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	# A goo wall exactly as tall and as thick as the part that hurts (Build 2: honest hitboxes).
	var wall := CylinderMesh.new()
	wall.top_radius = 1.0
	wall.bottom_radius = 1.0
	wall.height = HEIGHT
	wall.cap_top = false
	wall.cap_bottom = false
	wall.radial_segments = 48
	_mat = Fx.fx_mat(Color(Palette.color(&"gloop_pink"), 0.8))
	_mi = Kit.mesh_instance(self, wall, _mat, Vector3(0.0, HEIGHT * 0.5, 0.0))
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0 - BAND * 0.25
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 6
	var lip := Kit.mesh_instance(self, tm, Fx.fx_mat(Color(Palette.color(&"foam"), 0.9)), Vector3(0.0, HEIGHT, 0.0))
	lip.name = "Lip"


func _physics_process(delta: float) -> void:
	radius += SPEED * delta
	_mi.scale = Vector3(radius, 1.0, radius)
	(get_node("Lip") as Node3D).scale = Vector3(radius, 0.4, radius)
	if radius > max_radius:
		queue_free()


func damage_to_player(p: Player) -> Dictionary:
	var flat := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	if absf(flat - radius) > BAND or p.global_position.y - ground_y > HEIGHT:
		return {}
	return {"halves": 2, "from": global_position, "cause": "shockwave"}
