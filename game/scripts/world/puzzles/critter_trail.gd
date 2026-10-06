class_name CritterTrail
extends Node3D
## Build 7 puzzle: a glowing little critter (a firefly, a seahorse...) waits at its first spot;
## come close and it flits to the next, and the next, until it settles over a hidden place and
## `found` fires (spawn the reward there). It waits for you at each stop.

signal found(at: Vector3)

var points: Array[Vector3] = []
var color_name: StringName = &"gold"
## What appears where it settles: a Star Shard or a seed id.
var reward_shard: StringName = &""
var reward_seed: StringName = &""
var _i: int = 0
var _bug: Node3D
var _moving: bool = false
var _done: bool = false


func _ready() -> void:
	_bug = Node3D.new()
	add_child(_bug)
	var body := SphereMesh.new()
	body.radius = 0.25
	body.height = 0.5
	var m := Kit.unique_mat(color_name)
	m.set_shader_parameter(&"flash", 1.2)
	m.set_shader_parameter(&"flash_color", Palette.color(color_name))
	Kit.mesh_instance(_bug, body, m)
	var light := OmniLight3D.new()
	light.light_color = Palette.color(color_name)
	light.omni_range = 4.0
	_bug.add_child(light)
	if not points.is_empty():
		_bug.global_position = points[0]


func _physics_process(_delta: float) -> void:
	if _done or _moving or points.is_empty():
		return
	_bug.position.y += sin(Time.get_ticks_msec() * 0.006) * 0.01
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p == null or p.global_position.distance_to(_bug.global_position) > 4.5:
		return
	_i += 1
	if _i >= points.size():
		_done = true
		AudioDirector.play(&"seed", -4.0, 1.3)
		var at := points[points.size() - 1]
		if reward_shard != &"":
			Pickup.spawn_shard(get_parent(), at, reward_shard)
		elif reward_seed != &"":
			Pickup.spawn_seed(get_parent(), at, reward_seed)
		found.emit(at)
		create_tween().tween_property(_bug, "scale", Vector3.ZERO, 1.0)
		return
	_moving = true
	AudioDirector.play(&"ui_blip", -6.0, 1.6)
	var t := create_tween()
	t.tween_property(_bug, "global_position", points[_i], _bug.global_position.distance_to(points[_i]) / 7.0).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: _moving = false)
