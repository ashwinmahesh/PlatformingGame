extends TestCase
## Build 6 enemy roster (Ashwin: "5-6 basic non-boss enemy types that are varied in design, size
## and dynamic in what they can do"). Each monster on the real physics loop: its tell, its
## attack, and the abilities that counter it.

var p: Player


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(80.0, 2.0, 80.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	p.invuln_left = 999.0
	await ticks(6)


func _spawn(c: Critter, at: Vector3) -> Critter:
	c.position = at
	add_child(c)
	return c


func _atk(kind: StringName, from: Vector3, id: int) -> Dictionary:
	return {"id": id, "damage": 1, "kind": kind, "from": from, "hitstop": 0, "knockback": 1.0}


func _count(script: GDScript) -> int:
	var n := 0
	for c in get_children():
		if c.get_script() == script:
			n += 1
	return n


func test_puffcap_lobs_spores_ducks_and_is_scorched_by_fire() -> void:
	var m := _spawn(Puffcap.new(), Vector3(0.0, 0.05, -10.0)) as Puffcap
	var lobbed := false
	for i in 140:
		await ticks(1)
		if _count(EnemyShot) > 0:
			lobbed = true
			break
	check(lobbed, "a Puffcap lobs a spore ball at range")
	p.global_position = m.global_position + Vector3(0.0, 0.05, 2.0)
	await ticks(30)
	check_eq(m.state, Puffcap.S.DUCK, "it ducks under its cap up close")
	var res := m.receive_player_attack(_atk(&"slash_1", p.global_position, 1), null)
	check(bool(res.get("blocked", false)), "the sword glances off the ducked cap")
	check_eq(m.hp, 2, "no damage through the cap")
	m.receive_player_attack(_atk(&"fireball", p.global_position, 2), null)
	check_eq(m.state, Puffcap.S.SCORCHED, "a Fireball scorches it out of its guard")
	check_eq(m.hp, 1, "and hurts it")
	check(m.on_player_land(p) > 5.0, "its cap is a trampoline")


func test_pricklepot_fires_a_fan_of_needles() -> void:
	_spawn(Pricklepot.new(), Vector3(0.0, 0.05, -5.0))
	var most := 0
	for i in 120:
		await ticks(1)
		most = maxi(most, _count(EnemyShot))
	check_eq(most, 5, "five needles fan out as it pops up")


func test_shieldknight_blocks_charges_into_walls_and_loses_its_shield_to_thunder() -> void:
	floor_block(Vector3(0.0, 4.0, 2.0), Vector3(20.0, 4.0, 1.0))
	var k := _spawn(Armorling.new(), Vector3(0.0, 0.05, -8.0)) as Armorling
	await ticks(4)
	k.facing = Vector3.BACK
	var res := k.receive_player_attack(_atk(&"slash_1", p.global_position, 1), null)
	check(bool(res.get("blocked", false)), "its shield blocks a slash from the front")
	var charged := false
	for i in 300:
		await ticks(1)
		if k.state == Armorling.S.CHARGE:
			charged = true
			p.global_position = Vector3(8.0, 0.05, 0.0)
			break
	check(charged, "it charges from mid range")
	var stunned := false
	for i in 120:
		await ticks(1)
		if k.state == Armorling.S.STUNNED:
			stunned = true
			break
	check(stunned, "charging into a wall stuns it")
	k.facing = (p.global_position - k.global_position).normalized()
	k.receive_player_attack(_atk(&"thunder", p.global_position, 2), null)
	check(not k.has_shield, "Thunderclap knocks its shield away")
	var hp := k.hp
	k.set_state(Armorling.S.WALK)
	k.receive_player_attack(_atk(&"slash_1", k.global_position + k.facing * 2.0, 3), null)
	check(k.hp < hp, "without a shield, front hits land")


func test_mimic_only_hurts_while_panting() -> void:
	var m := _spawn(Mimic.new(), Vector3(0.0, 0.05, -2.0)) as Mimic
	await ticks(40)
	check(m.state != Mimic.S.DORMANT, "it wakes when you come close")
	m.set_state(Mimic.S.CHASE)
	var hp := m.hp
	var res := m.receive_player_attack(_atk(&"slash_1", p.global_position, 1), null)
	check(bool(res.get("blocked", false)) and m.hp == hp, "its lid clamps on the sword while it chases")
	m.receive_player_attack(_atk(&"thunder", p.global_position, 2), null)
	check_eq(m.state, Mimic.S.RECOVER, "Thunderclap knocks the wind out of it")
	m.receive_player_attack(_atk(&"slash_1", p.global_position, 3), null)
	check_eq(m.hp, hp - 2, "panting, it takes sword hits")


func test_boulderkin_throws_pounds_and_has_a_weak_back() -> void:
	var b := _spawn(Boulderkin.new(), Vector3(0.0, 0.05, -14.0)) as Boulderkin
	var threw := false
	for i in 300:
		await ticks(1)
		if _count(Boulder) > 0:
			threw = true
			break
	check(threw, "it heaves a boulder at you from range")
	await ticks(90)
	p.global_position = b.global_position + Vector3(0.0, 0.05, 4.0)
	var pounded := false
	for i in 300:
		await ticks(1)
		if _count(Shockwave) > 0:
			pounded = true
			break
	check(pounded, "up close it pounds out a dust ring")
	b.facing = Vector3.BACK
	var hp := b.hp
	var res := b.receive_player_attack(_atk(&"slash_1", b.global_position + Vector3.BACK * 3.0, 10), null)
	check(bool(res.get("blocked", false)) and b.hp == hp, "its stone front shrugs off the sword")
	b.receive_player_attack(_atk(&"slash_1", b.global_position + Vector3.FORWARD * 3.0, 11), null)
	check_eq(b.hp, hp - 1, "the crystal on its back is the weak spot")
	b.hit_by_boulder()
	check_eq(b.state, Boulderkin.S.TOPPLED, "a boulder slashed back topples it")


func test_big_gloplet_flops_and_splits_in_two() -> void:
	var g := _spawn(BigGloplet.new(), Vector3(0.0, 0.05, -7.0)) as BigGloplet
	var flopped := false
	for i in 200:
		await ticks(1)
		if g.state == BigGloplet.S.FLOP:
			flopped = true
			break
	check(flopped, "it belly-flops toward you after squashing")
	g.defeat()
	await ticks(3)
	check_eq(_count(Gloplet), 2, "it splits into two Gloplets")


func test_perched_batling_drops_on_you() -> void:
	var b := Batling.new()
	b.perched = true
	_spawn(b, Vector3(0.0, 4.0, -10.0))
	await ticks(30)
	check_eq(b.state, Batling.S.PERCH, "it hangs still while you're away")
	p.global_position = Vector3(0.0, 0.05, -8.0)
	var dropped := false
	for i in 60:
		await ticks(1)
		if b.state in [Batling.S.DROP, Batling.S.WINDUP, Batling.S.SWOOP]:
			dropped = true
			break
	check(dropped, "it drops when you pass beneath")
