class_name BossWorld
extends OpenWorld
## Shared flow for the open worlds that end in a boss (Build 4, Worlds 3 and 5): a shard-locked
## gate, a round arena that starts the fight when you walk in, the victory commit before any
## presentation (plan §9.8), a return arch home, and a full fight reset when you fall.

var boss: BossBase
var gate: VineGate
var return_arch: Portal
var fight_started: bool = false
var arena_center: Vector3
var arena_radius: float = 18.0
var arena_exit_spawn: StringName
var defeat_banner: String = "Victory!"
var _victory_running: bool = false


## Subclasses create and configure their boss here (not yet added to the tree).
func create_boss() -> BossBase:
	return null


func spawn_boss() -> void:
	boss = create_boss()
	boss.world_id = world_id
	boss.arena_center = arena_center
	boss.arena_radius = arena_radius
	add_child(boss)


## The gate that the Star Shards open, at a local position in the current region frame.
func make_gate(base_local: Vector3, width: float) -> void:
	gate = VineGate.new()
	gate.width = width
	gate.position = P(base_local)
	gate.rotation.y = Y()
	add_child(gate)
	gate.set_closed.call_deferred(true)


func finish_boss_world() -> void:
	make_lock()
	lock.unlocked.connect(_on_shards_complete)
	Events.boss_defeated.connect(_on_boss_defeated)
	add_spawn(arena_exit_spawn, arena_center + Vector3(0.0, 0.0, -arena_radius + 5.0), Vector3.BACK)
	spawn_boss()


func _on_shards_complete() -> void:
	gate.set_closed(false)
	if hud != null:
		hud.show_banner("The gate is open!", 2.2)
	AudioDirector.play(&"gate")


func after_spawn(spawn_id: StringName) -> void:
	if spawn_id == arena_exit_spawn and Progress.is_world_complete(world_id):
		if boss != null:
			boss.queue_free()
			boss = null
		_open_return_arch(false)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null or boss == null:
		return
	var pos := player.global_position
	var in_arena := Vector2(pos.x - arena_center.x, pos.z - arena_center.z).length() < arena_radius - 3.0 and pos.y > arena_center.y - 2.0
	if not fight_started and in_arena and not boss.gone:
		fight_started = true
		gate.set_closed(true)
		boss.start_fight()
		AudioDirector.play_music(&"boss")
	if hud != null:
		hud.set_boss(boss.hp, boss.max_hp, fight_started and not boss.gone)


func _on_boss_defeated(defeated_world: StringName) -> void:
	if defeated_world != world_id or _victory_running:
		return
	_victory_running = true
	var first_clear := Progress.commit_victory(world_id)
	Telemetry.log_event("boss_defeated", {"first_clear": first_clear})
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	AudioDirector.play_music(&"victory", 0.3)
	hud.show_banner(defeat_banner, 2.0)
	player.refill()
	player.cheer()
	await get_tree().create_timer(2.8).timeout
	if not is_inside_tree():
		return
	if first_clear:
		hud.show_banner("New heart!", 2.5)
		AudioDirector.play(&"seed")
	gate.set_closed(false)
	_open_return_arch(true)


func _open_return_arch(animate: bool) -> void:
	if return_arch != null:
		return
	return_arch = Portal.new()
	return_arch.target_scene = Progress.HUB_SCENE
	return_arch.target_spawn = &"hub_rootway_exit"
	return_arch.cleared = true
	return_arch.label_text = "Home to Mossbrook"
	return_arch.position = arena_center
	return_arch.rotation.y = PI
	add_child(return_arch)
	if animate:
		return_arch.scale = Vector3.ONE * 0.05
		create_tween().tween_property(return_arch, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)
		Fx.burst(self, return_arch.global_position + Vector3.UP, Palette.color(&"portal_teal"), 24, 5.0)


## Falling resets the fight: a fresh boss, no boulders, icicles or rings left over.
func on_player_respawned() -> void:
	if boss == null or boss.defeated_count > 0:
		return
	for n in get_children():
		if n is Shockwave or n is Boulder or n is FallingHazard:
			n.queue_free()
	boss.queue_free()
	spawn_boss()
	fight_started = false
	gate.set_closed(not lock.open)
	AudioDirector.play_music(music)
