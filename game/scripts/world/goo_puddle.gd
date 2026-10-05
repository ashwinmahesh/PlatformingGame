class_name GooPuddle
extends Node3D
## Goo left by Rolling Charge: slows you for 2 s (plan §8.5). Fades after a while.

var life: float = 6.0
var _mi: MeshInstance3D


func _ready() -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.1
	cm.height = 0.06
	_mi = Kit.mesh_instance(self, cm, Kit.slime_mat(&"gloop_pink", 0.0), Vector3(0.0, 0.04, 0.0))


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	scale = Vector3.ONE * clampf(life, 0.2, 1.0)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p != null and p.is_on_floor():
		var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
		if d < 1.1 and absf(p.global_position.y - global_position.y) < 0.6:
			p.apply_slow(2.0)
