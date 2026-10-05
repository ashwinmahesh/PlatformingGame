class_name WorldDef
extends Resource
## One world (plan §9.7). Rewards listed here are derived from completion, never stored.

@export var id: StringName
@export var display_name: String = ""
@export var scene_path: String = ""
@export var entrance_spawn: StringName
@export var arena_exit_spawn: StringName
@export var spawn_ids: Array[StringName] = []
@export var seed_ids: Array[StringName] = []
@export var first_clear_heart_containers: int = 1
## Build 4 open worlds: Star Shards found around the world open the goal.
@export var shard_ids: Array[StringName] = []
@export var shards_required: int = 3
## &"boss" or &"star": what the shards unlock.
@export var goal: StringName = &"boss"
@export var color: StringName = &"leaf_teal"
