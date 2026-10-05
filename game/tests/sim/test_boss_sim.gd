extends TestCase
## Mother Gloop in a physics scene: bounded exits and the watchdog.

var b: MotherGloop


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	var p := spawn_player(Vector3(0.0, 0.05, 12.0))
	p.invuln_left = 9999.0
	b = MotherGloop.new()
	b.arena_center = Vector3.ZERO
	b.arena_radius = 15.0
	b.stumps = []
	b.position = Vector3.ZERO
	add_child(b)
	await ticks(2)


func test_rolling_charge_that_misses_ends_in_unroll() -> void:
	b.phase = 3
	b.hp = 3
	b.forced_pattern = MotherGloop.Pattern.ROLLING_CHARGE
	b.start_fight()
	var saw_roll := false
	var reached := false
	for i in 600:
		await ticks(1)
		if b.state == MotherGloop.S.ROLL:
			saw_roll = true
		if saw_roll and b.state == MotherGloop.S.UNROLL:
			reached = true
			break
	check(saw_roll, "rolled")
	check(reached, "a roll with no stumps ends in Unroll")
	check_eq(b.watchdog_trips, 0, "no watchdog trips")


func test_hop_slam_opens_a_window() -> void:
	b.start_fight()
	var opened := false
	for i in 400:
		await ticks(1)
		if b.state == MotherGloop.S.CORE_WINDOW:
			opened = true
			break
	check(opened, "Hop Slam lands into a core window")
	check_eq(b.watchdog_trips, 0, "no watchdog trips")


func test_watchdog_fires() -> void:
	b.expect_watchdog = true
	b.start_fight()
	await ticks(1)
	b.state = MotherGloop.S.HOP_WARN
	b.state_ticks = 100000
	await ticks(1)
	check_eq(b.watchdog_trips, 1, "watchdog tripped")
	check_eq(b.state, MotherGloop.S.RECOVER, "dropped into recovery")
