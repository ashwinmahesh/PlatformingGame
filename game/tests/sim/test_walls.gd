extends TestCase
## Build 6 (Ashwin): wall jumps ("jump off a wall into a different direction"; later: "remove the
## jump reset... you should just get however many jumps you have left") and climbable ladders.

var p: Player
var inp: ScriptedInput


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(60.0, 2.0, 60.0))


func test_wall_slide_then_kick_off_keeps_the_jumps_left() -> void:
	# A tall wall north of the hero.
	floor_block(Vector3(0.0, 12.0, -4.0), Vector3(10.0, 12.0, 1.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)
	inp.move = Vector2(0.0, 1.0)
	inp.tap(&"jump")
	await ticks(12)
	inp.tap(&"jump")
	var slid := false
	for i in 90:
		await ticks(1)
		if p.wall_sliding:
			slid = true
			break
	check(slid, "pressing into the wall while falling slides down it")
	check(p.velocity.y >= -p.settings.wall_slide_speed - 0.01, "slowly")
	check_eq(p.jumps_used, 2, "two jumps spent on the way in")
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z > 4.0, "a jump kicks off the wall, away from it (vz %.1f)" % p.velocity.z)
	check(p.velocity.y > 0.0, "and upward")
	check_eq(p.jumps_used, 2, "the kick leaves the jump count as it was")
	inp.move = Vector2.ZERO
	await ticks(14)
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.y > 0.0 and p.jumps_used == 3, "the one jump left still works")
	await ticks(14)
	var vy := p.velocity.y
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.y <= vy, "and then there are none")


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


## Ashwin: "we shouldn't be able to infinitely keep bouncing off the same wall". After a kick
## the same wall only lets you slide until you touch something else.
func test_same_wall_gives_no_second_kick() -> void:
	floor_block(Vector3(0.0, 30.0, -4.0), Vector3(10.0, 30.0, 1.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)
	inp.move = Vector2(0.0, 1.0)
	inp.tap(&"jump")
	await ticks(30)
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z > 4.0, "first kick off the wall")
	# Air jump straight back into the same wall, higher up, and try again.
	await ticks(12)
	inp.tap(&"jump")
	for i in 40:
		await ticks(1)
		if p.is_on_wall():
			break
	check(p.is_on_wall() or p.global_position.z < -2.5, "back against the same wall")
	await ticks(4)
	var used := p.jumps_used
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z < 2.0, "the same wall gives no second kick (vz %.1f)" % p.velocity.z)
	check(p.jumps_used >= used, "and no jumps given back (%d)" % p.jumps_used)


## Zigzagging between two facing walls (a Lanternwick alley) still works.
func test_zigzag_between_two_walls() -> void:
	floor_block(Vector3(0.0, 30.0, -4.0), Vector3(10.0, 30.0, 1.0))
	floor_block(Vector3(0.0, 30.0, 4.0), Vector3(10.0, 30.0, 1.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)
	inp.move = Vector2(0.0, 1.0)
	inp.tap(&"jump")
	await ticks(30)
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z > 4.0, "kick off the north wall")
	inp.move = Vector2(0.0, -1.0)
	for i in 40:
		await ticks(1)
		if p.is_on_wall() and p.global_position.z > 2.0:
			break
	await ticks(2)
	inp.tap(&"jump")
	await ticks(2)
	check(p.velocity.z < -4.0, "then off the south wall (vz %.1f)" % p.velocity.z)
