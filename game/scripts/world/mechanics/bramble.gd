class_name Bramble
extends StaticBody3D
## A wall of thorny vines (Build 5): swords just bounce off, but a Fireball burns it away.
## Used to hide optional treasure behind the Fireball ability.

var size: Vector3 = Vector3(4.0, 3.5, 1.2)
var _last_id: int = -1
var _visual: Node3D


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	collision_mask = 0
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, size.y * 0.5, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position) if is_inside_tree() else 7
	for i in int(size.x * size.y * 1.4):
		var vine := CapsuleMesh.new()
		vine.radius = 0.16
		vine.height = rng.randf_range(1.0, 2.0)
		var v := Kit.mesh_instance(_visual, vine, Kit.mat(&"leaf_dark" if i % 3 else &"bark_mid", 0.015), Vector3(rng.randf_range(-0.5, 0.5) * size.x, rng.randf_range(0.2, 0.95) * size.y, rng.randf_range(-0.4, 0.4) * size.z))
		v.rotation = Vector3(rng.randf_range(-1.2, 1.2), rng.randf() * TAU, rng.randf_range(-1.2, 1.2))
	for i in int(size.x * 3.0):
		var thorn := CylinderMesh.new()
		thorn.top_radius = 0.0
		thorn.bottom_radius = 0.07
		thorn.height = 0.3
		var t := Kit.mesh_instance(_visual, thorn, Kit.mat(&"stone_light"), Vector3(rng.randf_range(-0.5, 0.5) * size.x, rng.randf_range(0.2, 0.95) * size.y, size.z * 0.45))
		t.rotation.x = PI * 0.5
	for i in 5:
		Kit.blob(_visual, Vector3(rng.randf_range(-0.45, 0.45) * size.x, rng.randf_range(0.3, 0.9) * size.y, size.z * 0.5), 0.18, &"mush_purple")
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var hb := BoxShape3D.new()
	hb.size = size + Vector3.ONE * 0.4
	Kit.add_shape(area, hb, Vector3(0.0, size.y * 0.5, 0.0))
	add_child(area)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	if StringName(str(atk.get("kind", ""))) != &"fireball":
		AudioDirector.play(&"hit", -4.0, 1.5)
		var hud := get_tree().get_first_node_in_group(&"hud") as Hud
		if hud != null and not Progress.has_ability(&"fireball"):
			hud.show_notice("Thorny brambles. Maybe fire would help...")
		return {"hit": true}
	AudioDirector.play(&"fire_pop")
	Fx.burst(get_parent(), global_position + Vector3.UP * size.y * 0.5, Palette.color(&"sunset_orange"), 30, 5.0, 0.16, 2.0, 0.7)
	Fx.burst(get_parent(), global_position + Vector3.UP * size.y * 0.5, Palette.color(&"bark_dark"), 16, 3.0, 0.12, -6.0, 0.6)
	collision_layer = 0
	var t := create_tween()
	t.tween_property(_visual, "scale", Vector3(1.1, 0.05, 1.1), 0.5)
	t.tween_callback(queue_free)
	return {"hit": true}
