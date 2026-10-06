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


# --- Build 7: six more monsters ----------------------------------------------------------------

func _until(c: Critter, s: int, n: int = 400) -> bool:
	for i in n:
		await ticks(1)
		if c.state == s:
			return true
	return false


func test_wispghost_only_solid_when_it_strikes_and_fire_lights_it() -> void:
	var g := _spawn(Wispghost.new(), Vector3(0.0, 1.0, -6.0)) as Wispghost
	await ticks(4)
	var res := g.receive_player_attack(_atk(&"slash_1", p.global_position, 1), null)
	check(res.is_empty(), "a sword passes through it while it drifts")
	check(not g.is_lockable(), "and you can't lock on")
	g.receive_player_attack(_atk(&"fireball", p.global_position, 2), null)
	check_eq(g.state, Wispghost.S.LIT, "a Fireball lights it up")
	var hp := g.hp
	g.receive_player_attack(_atk(&"slash_1", p.global_position, 3), null)
	check(g.hp < hp, "lit, the sword lands")


func test_wyrmling_inhales_then_breathes_and_frost_drops_it() -> void:
	var w := _spawn(Wyrmling.new(), Vector3(0.0, 4.0, -6.0)) as Wyrmling
	check(await _until(w, Wyrmling.S.INHALE), "it rears back first (the tell)")
	check(await _until(w, Wyrmling.S.BREATH, 80), "then breathes fire")
	w.receive_player_attack(_atk(&"frost", p.global_position, 5), null)
	check(w.frozen_ticks > 0 and w.state == Wyrmling.S.GROUNDED, "Frost Burst freezes it and down it comes")


func test_buzzbee_armour_and_vine() -> void:
	var b := _spawn(Buzzbee.new(), Vector3(0.0, 1.5, -5.0)) as Buzzbee
	await ticks(4)
	b.facing = Vector3.BACK
	var res := b.receive_player_attack(_atk(&"slash_1", b.global_position + Vector3.BACK * 2.0, 1), null)
	check(bool(res.get("blocked", false)), "its armour turns the sword from the front")
	check(await _until(b, Buzzbee.S.BUZZ), "it buzzes before it stings")
	b.receive_player_attack(_atk(&"vine", p.global_position, 2), null)
	check_eq(b.state, Buzzbee.S.DOWNED, "a Vinelash yank drags it down")


func test_whirlwisp_drags_you_in_and_an_orb_breaks_it() -> void:
	var w := _spawn(Whirlwisp.new(), Vector3(0.0, 0.3, -6.0)) as Whirlwisp
	check(await _until(w, Whirlwisp.S.SPIN_UP), "it spins up first (the tell)")
	check(await _until(w, Whirlwisp.S.VORTEX, 80), "then becomes a vortex")
	var z0 := p.global_position.z
	await ticks(30)
	check(p.global_position.z < z0 - 0.5, "the vortex drags the hero in")
	var orb := GravityOrb.new()
	add_child(orb)
	orb.global_position = w.global_position + Vector3.UP
	await ticks(3)
	check_eq(w.state, Whirlwisp.S.DIZZY, "a Gravity Orb nearby breaks it")


func test_hopfrog_tongue_and_dash() -> void:
	var f := _spawn(Hopfrog.new(), Vector3(0.0, 0.05, -5.0)) as Hopfrog
	check(await _until(f, Hopfrog.S.PUFF), "its throat puffs first (the tell)")
	check(await _until(f, Hopfrog.S.LASH, 60), "then the tongue lashes")
	await ticks(6)
	p.invuln_left = 0.0
	check(not f.damage_to_player(p).is_empty(), "the tongue reaches you")
	p.dash_left = 5
	check(f.damage_to_player(p).is_empty(), "an Air Dash slips it")
	p.dash_left = 0
	p.invuln_left = 999.0


func test_hexwizard_casts_homing_orbs_and_fire_fizzles_it() -> void:
	var w := _spawn(Hexwizard.new(), Vector3(0.0, 0.05, -8.0)) as Hexwizard
	check(await _until(w, Hexwizard.S.CAST), "it raises its staff first (the tell)")
	w.receive_player_attack(_atk(&"fireball", p.global_position, 7), null)
	check(w.stunned_ticks > 0, "a Fireball mid-cast fizzles it and stuns it")
	w.stunned_ticks = 0
	w.set_state(Hexwizard.S.CAST)
	var shots := 0
	for i in 70:
		await ticks(1)
		shots = maxi(shots, _count(EnemyShot))
	check_eq(shots, 3, "three homing hex orbs")
