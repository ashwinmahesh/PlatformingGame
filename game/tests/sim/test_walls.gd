extends TestCase
## Build 6 (Ashwin): wall jumps ("jump off a wall into a different direction... reset the jump
## count so you can jump onto a wall, jump off and then do 2 more jumps") and climbable ladders.

var p: Player
var inp: ScriptedInput


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(60.0, 2.0, 60.0))


func test_wall_slide_then_kick_off_and_two_more_jumps() -> void:
	# A tall wall north of the hero.
	floor_block(Vector3(0.0, 12.0, -4.0), Vector3(10.0, 12.0, 1.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)
	inp.move = Vector2(0.0, 1.0)
	inp.tap(&"jump")
	var slid := false
	for i in 90:
		await ticks(1)
		if p.wall_sliding:
			slid = true
			break
	check(slid, "pressing into the wall while falling slides down it")
	check(p.velocity.y >= -p.settings.wall_slide_speed - 0.01, "slowly")
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z > 4.0, "a jump kicks off the wall, away from it (vz %.1f)" % p.velocity.z)
	check(p.velocity.y > 0.0, "and upward")
	check_eq(p.jumps_used, 1, "the jump count resets")
	inp.move = Vector2.ZERO
	await ticks(14)
	var y0 := p.global_position.y
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.y > 0.0 and p.jumps_used == 2, "a second jump in the air")
	await ticks(14)
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.y > 0.0 and p.jumps_used == 3, "and a third")
	check(p.global_position.y > y0, "climbing higher than the kick")


func test_ladder_climb_and_step_off_at_the_top() -> void:
	# A 6 m ledge with a ladder up its south face.
	floor_block(Vector3(0.0, 6.0, -8.0), Vector3(10.0, 6.0, 8.0))
	var l := Ladder.new()
	l.height = 6.0
	l.position = Vector3(0.0, 0.0, -4.0)
	add_child(l)
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)
	inp.move = Vector2(0.0, 1.0)
	var climbing := false
	for i in 120:
		await ticks(1)
		if p.state == Player.State.CLIMB:
			climbing = true
			break
	check(climbing, "walking into the ladder grabs it")
	for i in 240:
		await ticks(1)
		if p.state != Player.State.CLIMB:
			break
	await ticks(40)
	check(p.global_position.y > 5.8 and p.is_on_floor(), "climbed up and stepped off onto the ledge (y %.1f)" % p.global_position.y)


func test_jump_lets_go_of_a_ladder() -> void:
	floor_block(Vector3(0.0, 6.0, -8.0), Vector3(10.0, 6.0, 8.0))
	var l := Ladder.new()
	l.height = 6.0
	l.position = Vector3(0.0, 0.0, -4.0)
	add_child(l)
	p = spawn_player(Vector3(0.0, 0.05, -3.2))
	inp = input_of(p)
	await ticks(4)
	inp.move = Vector2(0.0, 1.0)
	await ticks(40)
	check_eq(p.state, Player.State.CLIMB, "on the ladder")
	inp.move = Vector2.ZERO
	inp.tap(&"jump")
	await ticks(3)
	check_eq(p.state, Player.State.NORMAL, "jump lets go")
	check(p.velocity.z > 2.0, "pushing off backwards")


## Build 6 (Ashwin: "we shouldn't have to perfectly touch the center of them to collect"):
## a seed a couple of metres off to the side drifts in and is collected.
func test_pickups_drift_in_when_close() -> void:
	Progress.new_game()
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	await ticks(6)
	var pk := Pickup.spawn_seed(self, Vector3(2.6, 0.6, 0.0), &"w1_seed_fernway")
	await ticks(60)
	check(not is_instance_valid(pk) or pk.is_queued_for_deletion(), "a seed 2.6 m away is collected without stepping on it")
	check(Progress.has_seed(&"w1_seed_fernway"), "and counted")
