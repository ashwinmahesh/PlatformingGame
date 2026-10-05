extends TestCase
## Slice loop (plan §13.1 item 5, §15.1 `make loop`): enter World 1 -> reach the arena -> beat
## Mother Gloop -> victory commit before presentation -> return arch -> quit and resume.


func before_each() -> void:
	Progress.new_game()


func _level(path: String, spawn: StringName) -> Level:
	Router.pending_spawn = spawn
	var lvl := (load(path) as PackedScene).instantiate() as Level
	add_child(lvl)
	await ticks(3)
	return lvl


func test_world_loop_victory_and_resume() -> void:
	var lvl := await _level("res://scenes/levels/w1/glimmerbrook.tscn", &"w1_cp_lily_gate")
	var p := lvl.player
	check(p != null, "hero spawned")
	check(p.global_position.distance_to(lvl.spawns[&"w1_cp_lily_gate"][0] as Vector3) < 1.5, "spawned at the Lily Gate checkpoint")
	var boss := lvl.get("boss") as MotherGloop
	check(boss != null, "Mother Gloop is waiting")
	# Walk through the gate into the arena.
	p.respawn_at(Vector3(0.0, Glimmerbrook.RIDGE_Y + 0.05, Glimmerbrook.FIGHT_TRIGGER_Z - 3.0))
	p.invuln_left = 9999.0
	await ticks(3)
	check(bool(lvl.get("fight_started")), "entering the arena starts the fight")
	# Drive her through every window as fast as the rules allow.
	var windows := 0
	for i in 6000:
		await ticks(1)
		p.invuln_left = 9999.0
		if boss.state == MotherGloop.S.CORE_WINDOW:
			windows += 1
			while boss.state == MotherGloop.S.CORE_WINDOW:
				boss.core_invuln = 0
				if boss.apply_core_damage(1) == 0:
					break
		if boss.hp <= 0:
			break
	check_eq(boss.hp, 0, "defeated")
	check_eq(windows, MotherGloop.MAX_HP, "one opening per hit point")
	check_eq(boss.watchdog_trips, 0, "no watchdog trips during the whole fight")
	await ticks(2)
	check(Progress.is_world_complete(&"world_01"), "victory committed before the presentation")
	check_eq(Progress.max_halves(), 8, "new heart derived from completion")
	await get_tree().create_timer(6.0).timeout
	check(lvl.get("return_arch") != null, "return arch opened")
	# Quit and relaunch: reload from disk and Continue.
	Progress.data = Progress.fresh_data()
	check(Progress.load_save(), "save loads")
	check(Progress.is_world_complete(&"world_01"), "completion kept")
	check_eq(Progress.resume_target(), [&"world_01", &"w1_arena_exit"] as Array[StringName], "Continue goes to the arena exit")
	lvl.queue_free()
	await ticks(2)
	# Continuing at the arena exit: no boss, return arch open.
	var again := await _level("res://scenes/levels/w1/glimmerbrook.tscn", &"w1_arena_exit")
	await ticks(2)
	check(again.get("boss") == null, "no boss after a win when resuming at the exit")
	check(again.get("return_arch") != null, "return arch open on resume")
	again.queue_free()
	await ticks(2)


func test_hub_loads_with_rootway() -> void:
	var hub := await _level("res://scenes/hub/mossbrook.tscn", &"hub_arrival")
	var portals := 0
	for n in hub.get_children():
		if n is Portal and not (n as Portal).dormant:
			portals += 1
	check(portals >= 1, "the Rootway portal to World 1 exists")
	check_eq(get_tree().get_nodes_in_group(&"interactable").size(), 3, "three villagers to talk to")
	hub.queue_free()
	await ticks(2)
