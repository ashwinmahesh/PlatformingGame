extends TestCase
## Every world in Progress.WORLD_DEFS (Build 4/5): its scene loads cleanly, every spawn, Glimmer
## Seed and Star Shard its data names is really placed, and its goal exists. Boss worlds built on
## BossWorld are then played to victory (teaching their ability) with no watchdog trips.


func before_each() -> void:
	Progress.new_game()


func _load(w: WorldDef, spawn: StringName) -> Level:
	Router.pending_spawn = spawn
	var lvl := (load(w.scene_path) as PackedScene).instantiate() as Level
	add_child(lvl)
	await ticks(3)
	return lvl


func test_every_world_is_complete_and_consistent() -> void:
	for w in Progress.WORLD_DEFS:
		var lvl := await _load(w, w.entrance_spawn)
		check(lvl.player != null, "%s: hero spawned" % w.id)
		for sp in w.spawn_ids:
			check(lvl.spawns.has(sp), "%s: spawn %s exists" % [w.id, sp])
		var seeds: Array[StringName] = []
		var shards: Array[StringName] = []
		for n in lvl.find_children("*", "", true, false):
			if n is Pickup:
				var pk := n as Pickup
				if pk.kind == Pickup.Kind.SEED:
					seeds.append(pk.seed_id)
				elif pk.kind == Pickup.Kind.SHARD:
					shards.append(pk.seed_id)
			elif n is TreasureChest and (n as TreasureChest).seed_id != &"":
				seeds.append((n as TreasureChest).seed_id)
			elif n is Npc and (n as Npc).reward_seed != &"":
				seeds.append((n as Npc).reward_seed)
		for s in w.seed_ids:
			check(s in seeds, "%s: seed %s is placed" % [w.id, s])
		check_eq(seeds.size(), w.seed_ids.size(), "%s: no extra seeds" % w.id)
		for s in w.shard_ids:
			check(s in shards, "%s: shard %s is placed" % [w.id, s])
		if w.goal == &"star":
			check(not lvl.find_children("*", "GoalStar", true, false).is_empty(), "%s: a Grand Star waits" % w.id)
		else:
			check(lvl.get("boss") != null, "%s: a boss waits" % w.id)
		await ticks(120)
		check(lvl.player.state != Player.State.DEAD, "%s: standing at the entrance is safe" % w.id)
		lvl.queue_free()
		await ticks(3)


func test_boss_worlds_play_to_victory() -> void:
	for w in Progress.WORLD_DEFS:
		if w.goal != &"boss" or w.id == &"world_01":
			continue
		var lvl := await _load(w, w.entrance_spawn)
		var bw := lvl as BossWorld
		check(bw != null, "%s: built on BossWorld" % w.id)
		if bw == null:
			continue
		var learned: Array[StringName] = []
		var on_learn := func(a: StringName) -> void: learned.append(a)
		Events.ability_learned.connect(on_learn)
		var p := lvl.player
		p.respawn_at(bw.arena_center + Vector3(0.0, 0.05, -6.0))
		p.invuln_left = 9999.0
		await ticks(3)
		check(bw.fight_started, "%s: walking into the arena starts the fight" % w.id)
		var boss := bw.boss
		var hits := 0
		for i in 9000:
			await ticks(1)
			p.invuln_left = 9999.0
			if p.global_position.distance_to(bw.arena_center) > bw.arena_radius:
				p.respawn_at(bw.arena_center + Vector3(0.0, 0.05, -6.0))
			# The Ape only opens up after sliding into a pillar: stand behind one, as a player would.
			var ape := boss as AvalancheApe
			if ape != null and ape.state == AvalancheApe.S.SLIDE_WINDUP and ape.state_ticks == 2:
				var best := ape.pillars[0]
				for pil in ape.pillars:
					if pil.distance_to(ape.global_position) < best.distance_to(ape.global_position):
						best = pil
				var away := best - ape.global_position
				away.y = 0.0
				p.respawn_at(best + away.normalized() * 3.0 + Vector3.UP * 0.05)
			if boss.weak_open and boss.weak_invuln <= 0:
				hits += boss.apply_weak_hit()
			if boss.hp <= 0:
				break
		check_eq(boss.hp, 0, "%s: %s defeated" % [w.id, boss.boss_name])
		check_eq(hits, boss.max_hp, "%s: one hit per opening" % w.id)
		check_eq(boss.watchdog_trips, 0, "%s: no watchdog trips" % w.id)
		await ticks(2)
		check(Progress.is_world_complete(w.id), "%s: victory committed" % w.id)
		if w.ability != &"":
			check(w.ability in learned, "%s: clearing it teaches %s" % [w.id, w.ability])
			check(p.has_ability(w.ability), "%s: the hero can now use %s" % [w.id, w.ability])
		Events.ability_learned.disconnect(on_learn)
		lvl.queue_free()
		await ticks(3)


## Bubbleton Reef (Build 5): the shards wake the Great Bubble, which really carries the hero up
## to the Grand Star; touching it clears the world and teaches the Air Dash.
func test_bubbleton_great_bubble_reaches_the_star() -> void:
	var w := Progress.world_def(&"world_04")
	var lvl := await _load(w, w.entrance_spawn)
	var p := lvl.player
	var inp := ScriptedInput.new()
	p.input_source = inp
	p.respawn_at(Bubbleton.LIFT + Vector3(0.0, 0.7, 0.0))
	inp.tap(&"jump")
	await ticks(120)
	check(p.global_position.y < 8.0, "the Great Bubble sleeps before the shards come home")
	for s in w.shard_ids:
		Progress.collect_shard(s)
	await ticks(2)
	p.respawn_at(Bubbleton.LIFT + Vector3(0.0, 0.7, 0.0))
	await ticks(2)
	inp.tap(&"jump")
	var top := 0.0
	for i in 600:
		await ticks(1)
		top = maxf(top, p.global_position.y)
		# Steer toward world +X (the star flower) whatever way the camera faces.
		var local := Basis(Vector3.UP, -p.camera_yaw) * Vector3.RIGHT
		inp.move = Vector2(local.x, -local.z) if p.global_position.y > Bubbleton.STAR_Y + 0.5 or top > Bubbleton.STAR_Y + 0.5 else Vector2.ZERO
		if Progress.is_world_complete(&"world_04"):
			break
	check(top > Bubbleton.STAR_Y, "the bubble lifts the hero above the star flower (top %.1f m)" % top)
	check(Progress.is_world_complete(&"world_04"), "touching the Grand Star clears the world")
	check(p.has_ability(&"dash"), "and teaches the Air Dash")
	lvl.queue_free()
	await ticks(3)


## Build 6 upper tiers (Ashwin: "a whole other world at higher levels"): each world's high
## checkpoint stands on solid ground well above the valley floor.
func test_every_world_has_a_high_tier() -> void:
	var high: Dictionary[StringName, StringName] = {&"world_01": &"w1_cp_canopy", &"world_02": &"w2_cp_kingdom", &"world_03": &"w3_cp_town", &"world_04": &"w4_cp_heights", &"world_05": &"w5_cp_rim", &"world_06": &"w6_cp_rooftops"}
	for w in Progress.WORLD_DEFS:
		var sp: StringName = high.get(w.id, &"")
		check(sp != &"", "%s: has a high tier" % w.id)
		if sp == &"":
			continue
		var lvl := await _load(w, sp)
		await ticks(90)
		check(lvl.player.is_on_floor(), "%s: the high checkpoint is on solid ground" % w.id)
		check(lvl.player.global_position.y > 11.0, "%s: and up high (y %.1f)" % [w.id, lvl.player.global_position.y])
		lvl.queue_free()
		await ticks(3)


## Regression (Ashwin, Build 6: "every time I try to go into world 2, the game just crashes",
## right after a first clear of Bubbleton): from that save state, the hub and every world load and
## the hero stands safely; then the same with every world cleared and every ability learned.
func test_every_world_loads_from_a_played_save() -> void:
	for cleared: Array in [["world_04"], ["world_01", "world_02", "world_03", "world_04", "world_05", "world_06"]]:
		Progress.new_game()
		for wid: String in cleared:
			Progress.commit_victory(StringName(wid))
		Progress.set_flag(&"w4_found_hat")
		Progress.set_flag(&"w6_found_hook")
		for s: StringName in [&"w6_seed_cellar", &"w6_seed_clock", &"w4_seed_kelp_crown"]:
			Progress.collect_seed(s)
		Progress.collect_shard(&"w6_shard_clock")
		Router.pending_spawn = &"hub_rootway_exit"
		var hub := (load("res://scenes/hub/mossbrook.tscn") as PackedScene).instantiate() as Level
		add_child(hub)
		await ticks(30)
		check(hub.player != null and hub.player.state != Player.State.DEAD, "%d cleared: the hub loads" % cleared.size())
		hub.queue_free()
		await ticks(3)
		for w in Progress.WORLD_DEFS:
			var lvl := await _load(w, w.entrance_spawn)
			await ticks(60)
			check(lvl.player != null and lvl.player.state != Player.State.DEAD, "%d cleared: %s loads and the hero stands" % [cleared.size(), w.id])
			lvl.queue_free()
			await ticks(3)


## Build 6 accessibility: every ladder in every world (and the hub) stands on ground and leads
## onto something solid at the top.
func test_every_ladder_leads_somewhere() -> void:
	var paths: Array[String] = ["res://scenes/hub/mossbrook.tscn"]
	for w in Progress.WORLD_DEFS:
		paths.append(w.scene_path)
	for path in paths:
		Router.pending_spawn = &""
		var lvl := (load(path) as PackedScene).instantiate() as Level
		add_child(lvl)
		await ticks(3)
		var space := get_world_3d().direct_space_state
		var bad: Array[String] = []
		var count := 0
		for n in lvl.find_children("*", "Ladder", true, false):
			var l := n as Ladder
			count += 1
			var out := l.out_dir()
			var foot := l.global_position + out * 0.8
			var top := l.global_position + Vector3.UP * l.height - out * 1.4
			var q1 := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 1.0, foot + Vector3.DOWN * 1.5, Layers.WORLD)
			var q2 := PhysicsRayQueryParameters3D.create(top + Vector3.UP * 1.2, top + Vector3.DOWN * 1.2, Layers.WORLD)
			var h1 := space.intersect_ray(q1)
			var h2 := space.intersect_ray(q2)
			if h1.is_empty() or h2.is_empty():
				bad.append("%s%s" % ["foot " if h1.is_empty() else "top ", str(l.global_position.snapped(Vector3.ONE * 0.1))])
		check(bad.is_empty(), "%s: %d ladders all lead somewhere %s" % [path.get_file(), count, str(bad.slice(0, 6))])
		print("    ladders: %s %d" % [path.get_file(), count])
		if path.ends_with("sunscorch.tscn"):
			check(count >= 15, "Sunscorch: ladders all along the gorge walls (%d)" % count)
		if path.ends_with("lanternwick.tscn"):
			check(count >= 20, "Lanternwick: a ladder in every alley (%d)" % count)
		lvl.queue_free()
		await ticks(3)


## Regression (Ashwin: "the hitbox for the golem gem is off... when I do, I get transported way
## up in the air"): with the Golem kneeling, a Plunge from just above the visible gem lands, a
## sword slash at the gem lands too, and the hero only hops a little.
func test_golem_gem_takes_hits_and_only_hops_you() -> void:
	var w := Progress.world_def(&"world_03")
	var lvl := await _load(w, w.entrance_spawn)
	var bw := lvl as BossWorld
	var p := lvl.player
	var inp := ScriptedInput.new()
	p.input_source = inp
	p.respawn_at(bw.arena_center + Vector3(0.0, 0.05, -6.0))
	p.invuln_left = 9999.0
	await ticks(3)
	var golem := bw.boss as RumbleGolem
	for i in 140:
		await ticks(1)
		p.invuln_left = 9999.0
	golem.hit_by_boulder()
	await ticks(40)
	check(golem.weak_open, "the Golem kneels and the gem opens")
	var gem := golem.gem_position()
	var hp := golem.hp
	p.respawn_at(gem + Vector3(0.0, 3.0, 0.0))
	p.invuln_left = 9999.0
	await ticks(2)
	inp.tap(&"plunge")
	var peak := -INF
	for i in 90:
		await ticks(1)
		p.invuln_left = 9999.0
		peak = maxf(peak, p.global_position.y)
	check_eq(golem.hp, hp - 1, "a Plunge onto the visible gem hurts the Golem")
	check(peak < gem.y + 6.0, "and the hop off is small (peak %.1f m, gem at %.1f m)" % [peak, gem.y])
	# Open it again and slash it from the ground beside the gem.
	golem.weak_invuln = 0
	golem.hit_by_boulder()
	await ticks(40)
	gem = golem.gem_position()
	var flat := Vector3(gem.x, golem.global_position.y, gem.z)
	var away := (flat - golem.global_position).normalized()
	p.respawn_at(flat + away * 1.6 + Vector3.UP * maxf(gem.y - golem.global_position.y - 1.2, 0.05))
	p.facing = -away
	hp = golem.hp
	inp.tap(&"jump")
	await ticks(8)
	inp.tap(&"attack")
	await ticks(30)
	check(golem.hp < hp, "a sword slash at the open gem hurts it too")
	lvl.queue_free()
	await ticks(3)
