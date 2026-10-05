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
