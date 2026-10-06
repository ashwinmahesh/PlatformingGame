extends TestCase
## Magic on the real loop with the real resolver: Fireball, Vinelash, Thunderclap, Air Dash (Build 5/7)
## and the Build 7 world abilities: Frost Burst, Spring Boots, Gravity Orb, Star Rush, Mighty Roar.
## Locked until learned; once learned (abilities_override here), each does its job.

class Target:
	extends Node3D
	var kinds: Array[StringName] = []

	func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
		kinds.append(StringName(str(atk.get("kind", ""))))
		return {"hit": true}


var p: Player
var inp: ScriptedInput


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(80.0, 2.0, 80.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	await ticks(6)


func _target(at: Vector3) -> Target:
	var t := Target.new()
	t.position = at
	add_child(t)
	var a := Area3D.new()
	a.collision_layer = Layers.ENEMY_HURTBOX
	a.monitoring = false
	a.set_meta(&"actor", t)
	var s := SphereShape3D.new()
	s.radius = 0.6
	Kit.add_shape(a, s)
	t.add_child(a)
	return t


func _fireballs() -> int:
	return get_tree().get_nodes_in_group(&"player_projectile").size()


func test_magic_is_locked_until_learned() -> void:
	inp.tap(&"fireball")
	inp.tap(&"thunderclap")
	inp.tap(&"dash")
	await ticks(3)
	check_eq(_fireballs(), 0, "no Fireball before it is learned")
	check(p.clap_tick < 0, "no Thunderclap before it is learned")
	check_eq(p.dash_left, 0, "no Air Dash before it is learned")


func test_fireball_hits_a_target_at_range() -> void:
	p.abilities_override = [&"fireball"]
	p.facing = Vector3.FORWARD
	var t := _target(Vector3(0.0, 1.0, -14.0))
	inp.tap(&"fireball")
	await ticks(2)
	check_eq(_fireballs(), 1, "one Fireball in flight")
	await ticks(50)
	check(&"fireball" in t.kinds, "the Fireball hit the target 14 m away")
	check_eq(t.kinds.size(), 1, "it hit once and popped")
	check_eq(_fireballs(), 0, "the Fireball is gone after the hit")


func test_fireball_cooldown() -> void:
	p.abilities_override = [&"fireball"]
	inp.tap(&"fireball")
	await ticks(2)
	inp.tap(&"fireball")
	await ticks(2)
	check_eq(_fireballs(), 1, "a second press inside the cooldown does nothing")
	await ticks(Player.FIREBALL_COOLDOWN)
	inp.tap(&"fireball")
	await ticks(2)
	check(_fireballs() >= 1 and p.fireball_cooldown > 0, "after the cooldown it casts again")


func test_fireball_burns_brambles_but_swords_do_not() -> void:
	p.abilities_override = [&"fireball"]
	p.facing = Vector3.FORWARD
	var b := Bramble.new()
	b.position = Vector3(0.0, 0.0, -2.2)
	add_child(b)
	await ticks(2)
	inp.tap(&"attack")
	await ticks(30)
	check(is_instance_valid(b) and b.collision_layer != 0, "a sword slash doesn't cut brambles")
	inp.tap(&"fireball")
	await ticks(50)
	check(not is_instance_valid(b) or b.collision_layer == 0, "a Fireball burns them away")


## Build 7: the Vinelash replaces Glide. A hook flower 12 m up and ahead: one press zips you
## up to it and pops you over the top.
func test_vinelash_zips_to_a_hook_flower() -> void:
	var hb := HookBloom.new()
	hb.position = Vector3(0.0, 10.0, -8.0)
	add_child(hb)
	await ticks(2)
	inp.tap(&"vine")
	await ticks(3)
	check(p.vine_target == null, "no Vinelash before it is learned")
	p.abilities_override = [&"vine"]
	inp.tap(&"vine")
	var best := 0.0
	for i in 90:
		await ticks(1)
		best = maxf(best, p.global_position.y)
	check(best > 10.5, "zipped up to the flower and over it (peak %.1f m)" % best)


## With no flower in reach, the vine lashes the nearest monster.
func test_vinelash_lashes_a_monster() -> void:
	p.abilities_override = [&"vine"]
	var t := _target(Vector3(0.0, 1.0, -8.0))
	t.add_to_group(&"lockable")
	inp.tap(&"vine")
	await ticks(3)
	check(&"vine" in t.kinds, "the vine hits it")


func test_number_keys_cast_by_slot() -> void:
	p.abilities_override = [&"fireball"]
	inp.tap(&"ability_1")
	await ticks(3)
	check_eq(_fireballs(), 1, "key 1 casts slot 1, the Fireball")


func test_frost_burst_freezes_and_makes_floes() -> void:
	p.abilities_override = [&"frost"]
	var g := Puffcap.new()
	g.position = Vector3(0.0, 0.05, -4.0)
	add_child(g)
	var w := Kit.water(self, Vector3(0.0, 0.0, -14.0), Vector2(8.0, 12.0), 4.0)
	await ticks(6)
	p.facing = Vector3.FORWARD
	inp.tap(&"ability_5")
	await ticks(6)
	check(g.frozen_ticks > 0, "a monster in reach freezes")
	check(get_tree().get_nodes_in_group(&"ice_floe").size() >= 1, "water ahead freezes into floes")
	check(g.damage_to_player(p).is_empty(), "a frozen monster can't hurt you")
	w.queue_free()


func test_spring_boots_bound_high() -> void:
	p.abilities_override = [&"boots"]
	inp.tap(&"ability_6")
	var best := 0.0
	for i in 70:
		await ticks(1)
		best = maxf(best, p.global_position.y)
	check(best > Player.BOOTS_HEIGHT - 0.6, "a spring of about %.1f m (%.1f)" % [Player.BOOTS_HEIGHT, best])


func test_gravity_orb_drags_monsters_in() -> void:
	p.abilities_override = [&"orb"]
	var a := Puffcap.new()
	a.position = Vector3(4.0, 0.05, -9.0)
	add_child(a)
	await ticks(4)
	p.facing = Vector3.FORWARD
	var start := a.global_position
	inp.tap(&"ability_7")
	await ticks(90)
	check(not is_instance_valid(a) or a.global_position.distance_to(start) > 1.0, "the vortex drags it in")


func test_star_rush_bowls_through() -> void:
	p.abilities_override = [&"rush"]
	var t := _target(Vector3(0.0, 1.0, -6.0))
	p.facing = Vector3.FORWARD
	inp.tap(&"ability_8")
	await ticks(40)
	check(&"rush" in t.kinds, "the rush bowls into it")
	check(p.global_position.z < -6.0, "and carries on past")


func test_mighty_roar_stuns_far_around() -> void:
	p.abilities_override = [&"roar"]
	var k := Armorling.new()
	k.position = Vector3(8.0, 0.05, 0.0)
	add_child(k)
	await ticks(4)
	inp.tap(&"ability_9")
	await ticks(4)
	check(k.stunned_ticks > 0, "a Shieldknight 8 m off is stunned")
	check(not k.has_shield, "and its shield flies off")


func test_thunderclap_hits_everything_around() -> void:
	p.abilities_override = [&"thunderclap"]
	var near: Array[Target] = [_target(Vector3(3.0, 1.0, 0.0)), _target(Vector3(-2.0, 1.0, 3.0)), _target(Vector3(0.0, 1.0, -4.5))]
	var far := _target(Vector3(9.0, 1.0, 0.0))
	inp.tap(&"thunderclap")
	await ticks(12)
	for t in near:
		check_eq(t.kinds.count(&"thunder"), 1, "every target within %.1f m is hit once" % Player.CLAP_RADIUS)
	check_eq(far.kinds.size(), 0, "a target 9 m away is not hit")
	inp.tap(&"thunderclap")
	await ticks(3)
	check(p.clap_tick < 0, "the Thunderclap has a cooldown")


func test_air_dash_once_per_jump() -> void:
	p.abilities_override = [&"dash"]
	p.facing = Vector3.FORWARD
	inp.tap(&"jump")
	await ticks(10)
	var z0 := p.global_position.z
	var y0 := p.global_position.y
	inp.tap(&"dash")
	await ticks(Player.DASH_TICKS + 1)
	var moved := z0 - p.global_position.z
	check(moved > 3.8, "the air dash covers ground fast (moved %.2f m)" % moved)
	check(absf(p.global_position.y - y0) < 0.6, "it holds height while dashing")
	inp.tap(&"dash")
	await ticks(3)
	check_eq(p.dash_left, 0, "only one air dash per jump")
	await until_grounded(p)
	await ticks(Player.DASH_COOLDOWN)
	inp.tap(&"dash")
	await ticks(2)
	check(p.dash_left > 0, "landing restores the dash")
