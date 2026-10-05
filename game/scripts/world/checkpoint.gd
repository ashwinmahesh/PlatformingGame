class_name Checkpoint
extends Area3D
## Checkpoint lantern (plan §5.3, §9.8). Touching it saves; dying respawns you here.

var checkpoint_id: StringName
var world_id: StringName
var lit: bool = false
var _flame: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group(&"checkpoint")
	collision_layer = Layers.INTERACT
	collision_mask = Layers.PLAYER_BODY
	var s := CylinderShape3D.new()
	s.radius = 1.4
	s.height = 3.0
	Kit.add_shape(self, s, Vector3(0.0, 1.5, 0.0))
	var post := CylinderMesh.new()
	post.top_radius = 0.07
	post.bottom_radius = 0.09
	post.height = 2.0
	Kit.mesh_instance(self, post, Kit.mat(&"bark_dark"), Vector3(0.0, 1.0, 0.0))
	var cage := BoxMesh.new()
	cage.size = Vector3(0.4, 0.5, 0.4)
	Kit.mesh_instance(self, cage, Kit.mat(&"bark_mid", 0.02), Vector3(0.0, 2.2, 0.0))
	var flame := SphereMesh.new()
	flame.radius = 0.15
	flame.height = 0.3
	_flame = Kit.mesh_instance(self, flame, Fx.fx_mat(Palette.color(&"stone_dark")), Vector3(0.0, 2.2, 0.0))
	_light = OmniLight3D.new()
	_light.light_color = Palette.color(&"gold")
	_light.omni_range = 4.0
	_light.light_energy = 0.0
	_light.position.y = 2.2
	add_child(_light)
	body_entered.connect(_on_body_entered)
	set_lit(Progress.checkpoint_for(world_id) == checkpoint_id)


func set_lit(on: bool) -> void:
	lit = on
	_flame.material_override = Fx.fx_mat(Palette.color(&"gold") if on else Palette.color(&"stone_dark"))
	_light.light_energy = 1.2 if on else 0.0


func _on_body_entered(body: Node3D) -> void:
	if not body is Player or lit:
		return
	for c in get_tree().get_nodes_in_group(&"checkpoint"):
		(c as Checkpoint).set_lit(false)
	set_lit(true)
	Progress.set_checkpoint(world_id, checkpoint_id)
	Events.checkpoint_reached.emit(checkpoint_id)
	Events.notice.emit("Checkpoint")
	AudioDirector.play(&"checkpoint")
	Fx.burst(get_parent(), global_position + Vector3.UP * 2.2, Palette.color(&"gold"), 14, 3.0, 0.08, -1.0, 0.8)
	Telemetry.log_event("checkpoint", {"id": String(checkpoint_id)})
