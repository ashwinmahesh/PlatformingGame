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
