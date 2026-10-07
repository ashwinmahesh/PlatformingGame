class_name RushWall
extends StaticBody3D
## World 8: a wall of star-bricks. Swords, Plunges and spells just clank off it; a Star Rush (the
## ability Brickbloom Heights teaches) bowls straight through. Hides a seed for a return visit.
## `position` is the middle of its base.

var size: Vector3 = Vector3(4.0, 4.0, 1.2)
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
	Kit.mesh_instance(_visual, RoundMesh.box(size, 0.25), Kit.mat(&"gold", 0.03), Vector3(0.0, size.y * 0.5, 0.0))
	Kit.mesh_instance(_visual, BonkBrick.mortar_mesh(size), Kit.mat(&"sunset_orange"), Vector3(0.0, size.y, 0.0))
	var star := GoalStar.star_mesh(0.8, 0.36, 0.2)
	for side: float in [-1.0, 1.0]:
		for k in 2:
			var at := Vector3((k - 0.5) * size.x * 0.5, size.y * (0.35 + 0.3 * k), side * (size.z * 0.5 + 0.08))
			Kit.mesh_instance(_visual, star, Kit.mat(&"cloth_cream", 0.02), at).rotation.y = 0.0 if side > 0.0 else PI
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var hb := BoxShape3D.new()
	hb.size = size + Vector3.ONE * 0.6
	Kit.add_shape(area, hb, Vector3(0.0, size.y * 0.5, 0.0))
	add_child(area)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	if StringName(str(atk.get("kind", ""))) != &"rush":
		AudioDirector.play(&"hit", -4.0, 1.6)
		var hud := get_tree().get_first_node_in_group(&"hud") as Hud
		if hud != null and not Progress.has_ability(&"rush"):
			hud.show_notice("Star-bricks! Something fast and starry could bowl right through...")
		return {"hit": true}
	AudioDirector.play(&"coconut_break")
	Fx.burst(get_parent(), global_position + Vector3.UP * size.y * 0.5, Palette.color(&"gold"), 30, 6.0, 0.2, -10.0, 0.8)
	Fx.burst(get_parent(), global_position + Vector3.UP * size.y * 0.5, Palette.color(&"cloth_cream"), 12, 4.0, 0.12, -6.0, 0.6)
	collision_layer = 0
	queue_free()
	return {"hit": true}
