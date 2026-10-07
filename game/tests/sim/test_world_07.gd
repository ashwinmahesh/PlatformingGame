extends TestCase
## World 7, Planet Glorbo (Build 7): the bloom-bud on the real loop, the Bloomstalk climb, the
## Glass Lab's mirrors, the Antenna Tower's thunder steps and Queen Bloomzilla's drooping heart.


func _load(spawn: StringName) -> Glorbo:
	Progress.new_game()
	Router.pending_spawn = spawn
	var lvl := (load("res://scenes/levels/w7/glorbo.tscn") as PackedScene).instantiate() as Glorbo
	add_child(lvl)
	await ticks(3)
	return lvl


func _atk(kind: StringName, id: int) -> Dictionary:
	return {"id": id, "damage": 1, "kind": kind, "from": Vector3.ZERO, "hitstop": 0, "knockback": 1.0}


func _flat_gap(a: BloomPad, b_pos: Vector3, b_radius: float) -> float:
	var d := Vector2(a.global_position.x - b_pos.x, a.global_position.z - b_pos.z).length()
	return d - a.radius - b_radius


func test_bloom_pad_opens_when_hit_carries_you_and_curls_shut() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(30.0, 2.0, 30.0))
	var pad := BloomPad.new()
	pad.open_time = 3.0
	pad.position = Vector3(0.0, 3.0, 0.0)
	add_child(pad)
	var p := spawn_player(Vector3(0.0, 6.0, 0.0))
	await ticks(60)
	check(p.global_position.y < 1.0, "a closed bud is no platform: the hero drops past it (y %.1f)" % p.global_position.y)
	pad.receive_player_attack(_atk(&"slash_1", 1), null)
	check(pad.is_open, "a hit opens it")
	p.respawn_at(Vector3(0.0, 4.0, 0.0))
	await ticks(40)
	check(p.is_on_floor() and absf(p.global_position.y - 3.0) < 0.3, "the open bloom holds the hero up (y %.2f)" % p.global_position.y)
	await ticks(150)
	check(not pad.is_open, "after a while it curls shut")
	await ticks(60)
	check(p.global_position.y < 1.0, "and the hero drops (y %.1f)" % p.global_position.y)


## Puzzle star: every bud is a small hop up and close enough to bop from the one below; opened,
## each holds the hero; the last is a hop from the spire top, where the star waits.
func test_bloomstalk_climbs_bud_by_bud_to_the_star() -> void:
	var lvl := await _load(&"w7_cp_spire")
	var p := lvl.player
	p.invuln_left = 9999.0
	var pads := lvl.spire_pads
	check_eq(pads.size(), 7, "seven buds wind up the spire")
	check(pads[0].global_position.y <= 2.5, "the first bud is a hop off the ground")
	for k in pads.size():
		var pad := pads[k]
		if k > 0:
			var prev := pads[k - 1]
			check(pad.global_position.y - prev.global_position.y <= 2.5, "bud %d is a small hop above the last" % k)
			check(_flat_gap(prev, pad.global_position, pad.radius) <= 1.0, "bud %d is a short step from the last (%.1f m)" % [k, _flat_gap(prev, pad.global_position, pad.radius)])
			# Standing at the near edge of the bud below, the next bud's hit zone (1.8 m) is
			# within a sword's length (about 2 m) in front of the hero.
			check(_flat_gap(prev, pad.global_position, 0.0) - 1.8 <= 1.5, "bud %d can be bopped from the bud below" % k)
		pad.receive_player_attack(_atk(&"slash_1", 100 + k), null)
		p.respawn_at(pad.global_position + Vector3.UP * 0.6)
		p.invuln_left = 9999.0
		await ticks(20)
		check(p.is_on_floor() and absf(p.global_position.y - pad.global_position.y) < 0.4, "bloomed bud %d holds the hero (y %.1f)" % [k, p.global_position.y])
	var top := Glorbo.SPIRE + Vector3(0.0, Glorbo.SPIRE_TOP, 0.0)
	var last := pads[pads.size() - 1]
	check(top.y - last.global_position.y <= 2.5, "the spire top is a hop above the last bud")
	check(_flat_gap(last, top, 3.0) <= 1.0, "and a short step across")
	var star := false
	for n in lvl.find_children("*", "Pickup", true, false):
		var pk := n as Pickup
		if pk.seed_id == &"w7_shard_bloom" and pk.global_position.distance_to(top) < 1.5:
			star = true
	check(star, "the Bloomstalk star sits on the spire top")
	lvl.queue_free()
	await ticks(3)


func test_glass_lab_opens_when_starlight_reaches_the_crystal() -> void:
	var lvl := await _load(&"w7_cp_lab")
	var mp := lvl.mirror_puzzle
	await ticks(2)
	check(not mp.done, "the crystal starts dark")
	mp.mirrors[3].flip()
	await ticks(2)
	check(not mp.done, "turning the decoy mirror alone does nothing")
	mp.mirrors[3].flip()
	for i in 3:
		mp.mirrors[i].flip()
		await ticks(2)
	check(mp.done, "three turned mirrors light the crystal")
	check(not bool(lvl.lab_door.get("_closed")), "and the Glass Lab's door opens")
	lvl.queue_free()
	await ticks(3)


func test_antenna_tower_steps_light_on_thunder_and_lead_to_the_cap() -> void:
	var lvl := await _load(&"w7_entrance")
	var p := lvl.player
	p.invuln_left = 9999.0
	var steps := lvl.tower_steps
	check(not steps[0].solid, "the tower steps start as ghosts")
	lvl.dynamo.receive_player_attack(_atk(&"thunder", 1), null)
	await ticks(2)
	var all_solid := true
	for s in steps:
		all_solid = all_solid and s.solid
	check(all_solid, "a Thunderclap on the coil lights every step")
	var prev_y := Glorbo.TOWER.y
	for s in steps:
		check(s.global_position.y - prev_y <= 2.5, "each step is a small hop up")
		prev_y = s.global_position.y
	var cap_y := Glorbo.TOWER.y + 24.0
	check(cap_y - prev_y <= 2.5, "the cap is a hop above the last step")
	p.respawn_at(steps[steps.size() - 1].global_position + Vector3.UP * 0.6)
	await ticks(20)
	p.invuln_left = 9999.0
	check(p.is_on_floor(), "a lit step holds the hero")
	await ticks(1260)
	check(not steps[0].solid, "after twenty seconds the steps fade again")
	lvl.queue_free()
	await ticks(3)


## Queen Bloomzilla: after her slam she wilts forward and her heart droops within reach; the hit
## zone follows the drawn heart, a Plunge on it hurts her, and the hop off is small.
func test_queen_heart_droops_follows_the_body_and_only_hops_you() -> void:
	var lvl := await _load(&"w7_entrance")
	var p := lvl.player
	var inp := ScriptedInput.new()
	p.input_source = inp
	p.respawn_at(lvl.arena_center + Vector3(-8.0, 0.05, 0.0))
	p.invuln_left = 9999.0
	await ticks(3)
	check(lvl.fight_started, "walking into the ring starts the fight")
	var q := lvl.boss as QueenBloomzilla
	for i in 120:
		await ticks(1)
		p.invuln_left = 9999.0
	var upright := q.core_position()
	q.set_state(QueenBloomzilla.S.SLAM_WINDUP)
	var wilted := false
	for i in 200:
		await ticks(1)
		p.invuln_left = 9999.0
		if q.state == QueenBloomzilla.S.WILT and q.state_ticks > 40:
			wilted = true
			break
	check(wilted and q.weak_open, "after the slam she wilts and her heart opens")
	var heart := q.core_position()
	check(heart.y < upright.y - 1.5, "the heart droops low (%.1f m, was %.1f m)" % [heart.y - q.ground_y, upright.y - q.ground_y])
	check(heart.y - q.ground_y < 4.0, "low enough to reach with a jumping slash")
	var weak := ((q.get("_weak_area") as Area3D).get_child(0) as Node3D).global_position
	check(weak.distance_to(heart) < 0.3, "the hit zone sits on the drawn heart")
	var hp := q.hp
	p.respawn_at(heart + Vector3(0.0, 3.0, 0.0))
	p.invuln_left = 9999.0
	await ticks(2)
	inp.tap(&"plunge")
	var peak := -INF
	for i in 90:
		await ticks(1)
		p.invuln_left = 9999.0
		peak = maxf(peak, p.global_position.y)
	check_eq(q.hp, hp - 1, "a Plunge onto the drooping heart hurts her")
	check(peak < heart.y + 6.0, "and the hop off is small (peak %.1f, heart %.1f)" % [peak, heart.y])
	lvl.queue_free()
	await ticks(3)
