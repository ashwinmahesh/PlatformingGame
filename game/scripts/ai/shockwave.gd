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
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 6
	_mat = Fx.fx_mat(Color(Palette.color(&"gloop_pink"), 0.85))
	_mi = Kit.mesh_instance(self, tm, _mat, Vector3(0.0, 0.25, 0.0))


func _physics_process(delta: float) -> void:
	radius += SPEED * delta
	_mi.scale = Vector3(radius, HEIGHT * 4.0, radius)
	if radius > max_radius:
		queue_free()


func damage_to_player(p: Player) -> Dictionary:
	var flat := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	if absf(flat - radius) > BAND or p.global_position.y - ground_y > HEIGHT:
		return {}
	return {"halves": 2, "from": global_position, "cause": "shockwave"}
