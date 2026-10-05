class_name EncounterZone
extends Node3D
## Enemies belong to a zone (plan §8.1). Brains sleep while the player is outside the zone plus
## 6 m; a death respawn resets the whole zone. Every zone declares a bypass (plan §5.3).

const MARGIN := 6.0

var zone_id: StringName
var radius: float = 10.0
var bypass_note: String = ""
var spawns: Array[Dictionary] = []
var director: AttackDirector = AttackDirector.new()
var level_seed: int = 1


func add_spawn(local_pos: Vector3, def: EnemyDef) -> void:
	spawns.append({"pos": local_pos, "def": def})


func _ready() -> void:
	add_to_group(&"encounter_zone")
	spawn_all()


func spawn_all() -> void:
	for i in spawns.size():
		var g := Gloplet.new()
		var d: Dictionary = spawns[i]
		g.setup(d["def"] as EnemyDef, d["pos"] as Vector3, director, level_seed ^ hash("%s_%d" % [zone_id, i]))
		add_child(g)


func reset() -> void:
	for c in get_children():
		if c is Gloplet:
			director.release(c)
			c.queue_free()
	director = AttackDirector.new()
	spawn_all.call_deferred()


func _physics_process(_delta: float) -> void:
	director.advance()
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var on := p != null and p.global_position.distance_to(global_position) < radius + MARGIN
	for c in get_children():
		if c is Gloplet:
			(c as Gloplet).active = on
