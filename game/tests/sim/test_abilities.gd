extends TestCase
## Build 5 magic on the real loop with the real resolver: Fireball, Glide, Thunderclap, Air Dash.
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


func test_glide_slows_the_fall() -> void:
	p.respawn_at(Vector3(0.0, 30.0, 0.0))
	await ticks(1)
	inp.press(&"jump")
	var fastest := 0.0
	for i in 120:
		await ticks(1)
		if p.velocity.y < 0.0:
			fastest = minf(fastest, p.velocity.y)
	check(fastest < -10.0, "without Glide the hero falls fast")
	p.abilities_override = [&"glide"]
	p.respawn_at(Vector3(0.0, 30.0, 0.0))
	await ticks(1)
	inp.release(&"jump")
	await ticks(1)
	inp.press(&"jump")
	fastest = 0.0
	var glided := false
	for i in 150:
		await ticks(1)
		glided = glided or p.gliding
		if p.gliding:
			fastest = minf(fastest, p.velocity.y)
	check(glided, "holding jump while falling glides")
	check(fastest >= -Player.GLIDE_FALL - 0.01, "the glide caps the fall speed")
	inp.release(&"jump")
	await ticks(2)
	check(not p.gliding, "letting go stops the glide")


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
