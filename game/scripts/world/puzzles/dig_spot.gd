class_name DigSpot
extends Area3D
## Build 7 puzzle: a faintly glittering patch a villager's riddle points to. Talk to it (E) and
## it gives up what's buried: `dug` fires once.

signal dug(at: Vector3)

var done: bool = false
## What's buried: a Star Shard or a seed id.
var reward_shard: StringName = &""
var reward_seed: StringName = &""
var _t: float = 0.0


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 0
	collision_mask = 0
	var s := SphereShape3D.new()
	s.radius = 1.0
	Kit.add_shape(self, s)


func interact(_p: Player) -> void:
	if done:
		return
	done = true
	remove_from_group(&"interactable")
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.3, Palette.color(&"bark_mid"), 16, 3.0, 0.12)
	AudioDirector.play(&"poof", -2.0, 0.8)
	if reward_shard != &"":
		Pickup.spawn_shard(get_parent(), global_position + Vector3.UP * 0.6, reward_shard)
	elif reward_seed != &"":
		Pickup.spawn_seed(get_parent(), global_position + Vector3.UP * 0.6, reward_seed)
	dug.emit(global_position)


func _process(delta: float) -> void:
	if done:
		return
	_t += delta
	if _t > 0.9:
		_t = 0.0
		Fx.burst(get_parent(), global_position + Vector3.UP * 0.1, Palette.color(&"gold"), 2, 0.6, 0.05, 1.0, 0.6)
