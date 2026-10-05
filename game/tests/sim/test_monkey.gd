extends TestCase
## Bonk monkey scenarios (plan §15.2 test 23, §15.3).

var p: Player
var m: BonkMonkey


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	floor_block(Vector3(0.0, 6.0, -8.0), Vector3(4.0, 1.0, 4.0))
	p = spawn_player(Vector3(0.0, 0.05, 2.0))
	p.invuln_left = 9999.0
	m = BonkMonkey.new()
	m.perches = [Vector3(0.0, 6.0, -6.5)]
	add_child(m)
	await ticks(2)


func test_monkey_throws_with_a_ring() -> void:
	var thrown := false
	for i in 200:
		await ticks(1)
		if is_instance_valid(m.last_coconut):
			thrown = true
			break
	check(thrown, "the monkey threw a coconut at the hero in range")
	check(m.aim_point.distance_to(Vector3(p.global_position.x, 0.0, p.global_position.z)) < 1.0, "aimed where the hero stood")


func test_23_reflected_coconut_hits_the_thrower() -> void:
	for i in 200:
		await ticks(1)
		if is_instance_valid(m.last_coconut):
			break
	var nut := m.last_coconut
	check(nut != null, "a coconut is in the air")
	await ticks(10)
	var res := nut.receive_player_attack({"id": 99, "kind": &"slash_1", "damage": 1}, null)
	check(bool(res.get("hit", false)), "slashing the coconut reflects it")
	for i in 60:
		await ticks(1)
		if m.state == BonkMonkey.S.STUNNED:
			break
	check_eq(m.state, BonkMonkey.S.STUNNED, "the reflected coconut knocked its thrower off the perch")
	check(m.global_position.y < 1.0, "the monkey is on the ground, in sword range")


func test_stunned_monkey_falls_to_a_combo() -> void:
	m.hit_by_coconut()
	await ticks(2)
	for i in 3:
		m.receive_player_attack({"id": 200 + i, "kind": &"slash_1", "damage": 1}, null)
	await ticks(2)
	check(not is_instance_valid(m), "3 hits while stunned defeat it")
