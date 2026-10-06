extends TestCase
## Build 6 world puzzles on the real loop: shoving a crate onto a pressure plate, and ringing bells
## in order.


func test_push_crate_onto_plate() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	var crate := PushBlock.new()
	crate.position = Vector3(0.0, 0.0, 0.0)
	add_child(crate)
	var plate := PressurePlate.new()
	plate.radius = 1.2
	plate.position = Vector3(0.0, 0.0, -3.0)
	add_child(plate)
	var p := spawn_player(Vector3(0.0, 0.05, 2.4))
	var inp := input_of(p)
	await ticks(4)
	check(not plate.pressed, "the plate starts up")
	inp.move = Vector2(0.0, 1.0)
	await ticks(90)
	inp.move = Vector2.ZERO
	await ticks(30)
	check(crate.global_position.z < -2.5, "pushing into the crate shoves it a step (z %.2f)" % crate.global_position.z)
	check(plate.pressed, "the crate holds the plate down")


func test_bells_in_order() -> void:
	var seq := BellSequence.new()
	seq.order = [0, 1, 2]
	add_child(seq)
	var bells: Array[CrystalSwitch] = []
	for i in 3:
		var b := CrystalSwitch.new()
		b.position = Vector3(i * 3.0, 0.0, 0.0)
		add_child(b)
		seq.add(b)
		bells.append(b)
	var solved := [false]
	seq.solved.connect(func() -> void: solved[0] = true)
	bells[1].set_lit(true)
	await ticks(2)
	check(not bells[1].lit, "a wrong first bell resets")
	for i in 3:
		bells[i].set_lit(true)
		await ticks(1)
	check(solved[0], "pink, gold, blue in order solves it")


## Build 7 puzzle kit: each mechanic does its one job on the real loop.
func test_braziers_light_with_fireball() -> void:
	var set := BrazierSet.new()
	add_child(set)
	var a := set.add(Vector3(0.0, 0.0, -6.0))
	var b := set.add(Vector3(3.0, 0.0, -6.0))
	var solved := [false]
	set.solved.connect(func() -> void: solved[0] = true)
	a.receive_player_attack({"id": 1, "kind": &"slash_1"}, null)
	check(not a.lit, "a sword doesn't light it")
	a.receive_player_attack({"id": 2, "kind": &"fireball"}, null)
	b.receive_player_attack({"id": 3, "kind": &"fireball"}, null)
	check(solved[0], "both lit by Fireballs: solved")


func test_beam_reaches_target_after_flips() -> void:
	var bp := BeamPuzzle.new()
	bp.source_dir = Vector3.RIGHT
	bp.target = Vector3(6.0, 0.0, 6.0)
	add_child(bp)
	var m := bp.add_mirror(Vector3(6.0, 0.0, 0.0), true)
	await ticks(2)
	var solved_before := bp.done
	m.flip()
	await ticks(2)
	check(not solved_before and bp.done, "flipping the mirror bends the beam onto the target")


func test_water_lock_changes_level() -> void:
	var wl := WaterLock.new()
	wl.levels = [-6.0, 0.0]
	add_child(wl)
	var crank := wl.add_wheel(Vector3(8.0, 0.0, 0.0)) as WaterWheelCrank
	var before := wl.surface()
	crank.receive_player_attack({"id": 5}, null)
	await ticks(100)
	check(wl.surface() > before + 5.0, "the wheel raises the water")


func test_dynamo_runs_on_thunder() -> void:
	var d := ThunderDynamo.new()
	add_child(d)
	d.receive_player_attack({"id": 1, "kind": &"slash_1"}, null)
	check(not d.powered, "a sword only sparks")
	d.receive_player_attack({"id": 2, "kind": &"thunder"}, null)
	check(d.powered, "Thunderclap powers it")


func test_colour_lock_mixes() -> void:
	var cl := ColourLock.new()
	cl.want = [true, false, true]
	add_child(cl)
	for i in 3:
		cl.add_crystal(Vector3(i * 2.0, 0.0, 0.0), i)
	await ticks(1)
	var hits := cl.find_children("*", "ColourCrystalHit", true, false)
	(hits[0] as ColourCrystalHit).receive_player_attack({"id": 1}, null)
	(hits[2] as ColourCrystalHit).receive_player_attack({"id": 2}, null)
	check(cl.done, "red + blue makes the purple: solved")


func test_critter_trail_leads_to_a_reward() -> void:
	Progress.new_game()
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	var p := spawn_player(Vector3(0.0, 0.05, 0.0))
	var ct := CritterTrail.new()
	ct.points = [Vector3(0.0, 1.0, -2.0), Vector3(0.0, 1.0, -10.0)]
	ct.reward_seed = &"w1_seed_fernway"
	add_child(ct)
	await ticks(20)
	p.respawn_at(Vector3(0.0, 0.05, -9.0))
	await ticks(100)
	# The seed drifts straight to the hero (pickup magnet), so it's already collected.
	check(Progress.has_seed(&"w1_seed_fernway") or not get_tree().get_nodes_in_group(&"pickup").is_empty(), "following it to the end turns up the seed")


func test_dig_spot_and_turn_bridge() -> void:
	Progress.new_game()
	var p := spawn_player(Vector3(0.0, 0.05, 0.0))
	var ds := DigSpot.new()
	ds.reward_seed = &"w1_seed_fernway"
	add_child(ds)
	ds.interact(p)
	check(ds.done and not get_tree().get_nodes_in_group(&"pickup").is_empty(), "digging turns up the seed")
	var tb := TurnBridge.new()
	add_child(tb)
	tb.add_lever(Vector3(3.0, 0.0, 0.0))
	await ticks(1)
	var lever := tb.find_children("*", "WaterWheelCrank", true, false)[0] as WaterWheelCrank
	lever.receive_player_attack({"id": 9}, null)
	check_eq(tb.index, 1, "the lever swings the bridge round")
