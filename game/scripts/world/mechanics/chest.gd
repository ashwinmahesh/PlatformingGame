class_name TreasureChest
extends Node3D
## A real treasure chest: press E next to it to open it for a Glimmer Seed or a heart (Build 4).
## Its lookalike, the Mimic, bites.

var seed_id: StringName = &""
var opened: bool = false
var _lid: Node3D


func _ready() -> void:
	add_to_group(&"interactable")
	if seed_id != &"" and Progress.has_seed(seed_id):
		opened = true
	ChestLook.build(self)
	_lid = get_node("Lid") as Node3D
	if opened:
		_lid.rotation.x = -1.9
	var body := Kit.static_body(self, Vector3.ZERO, Layers.WORLD)
	var b := BoxShape3D.new()
	b.size = Vector3(1.6, 1.2, 1.1)
	Kit.add_shape(body, b, Vector3(0.0, 0.6, 0.0))


func interact(_p: Player) -> void:
	if opened:
		return
	opened = true
	remove_from_group(&"interactable")
	create_tween().tween_property(_lid, "rotation:x", -1.9, 0.35).set_trans(Tween.TRANS_BACK)
	AudioDirector.play(&"checkpoint")
	Fx.burst(get_parent(), global_position + Vector3.UP * 1.2, Palette.color(&"gold"), 16, 4.0, 0.1)
	if seed_id != &"":
		Pickup.spawn_seed(get_parent(), global_position + Vector3(0.0, 1.3, 1.2), seed_id)
	else:
		Pickup.spawn_heart(get_parent(), global_position + Vector3(0.0, 1.0, 1.2))
