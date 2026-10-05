class_name ShardLock
extends Node
## Emits `unlocked` once the world's Star Shard count reaches its requirement (Build 4).

signal unlocked

var world_id: StringName
var required: int = 3
var open: bool = false


func _ready() -> void:
	Events.shard_collected.connect(func(_id: StringName) -> void: _check())
	_check.call_deferred()


func _check() -> void:
	if open:
		return
	if Progress.world_shard_count(world_id) >= required:
		open = true
		unlocked.emit()
