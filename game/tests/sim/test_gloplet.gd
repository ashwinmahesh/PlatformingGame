extends TestCase
## Gloplet scenarios (plan §15.3).

var p: Player


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	p = spawn_player(Vector3(0.0, 0.05, -3.0))
	p.invuln_left = 9999.0
	await ticks(2)


func _gloplet(at: Vector3, director: AttackDirector, def: EnemyDef = preload("res://data/enemies/gloplet.tres")) -> Gloplet:
	var g := Gloplet.new()
	g.setup(def, at, director, 7)
	add_child(g)
	return g


func test_lunge_within_2s_lands_on_locked_point() -> void:
	var g := _gloplet(Vector3.ZERO, AttackDirector.new())
	var lunged_at := -1
	for i in 240:
		await ticks(1)
		if g.state == Gloplet.S.LUNGE and lunged_at < 0:
			lunged_at = i
		if lunged_at >= 0 and g.state == Gloplet.S.RECOVER:
			break
	check(lunged_at >= 0 and lunged_at <= 120, "lunge started within 2 s (tick %d)" % lunged_at)
	var flat := Vector2(g.global_position.x - g.lunge_target.x, g.global_position.z - g.lunge_target.z).length()
	check(flat <= 0.3, "landed within 0.3 m of the locked point (%.2f)" % flat)


func test_tokens_never_exceed_two() -> void:
	var d := AttackDirector.new()
	var gs: Array[Gloplet] = []
	for i in 4:
		gs.append(_gloplet(Vector3(-3.0 + i * 2.0, 0.0, 0.0), d))
	var max_tokens := 0
	for i in 600:
		d.advance()
		await ticks(1)
		max_tokens = maxi(max_tokens, d.melee_count())
	check(max_tokens <= 2, "at most 2 tokens (saw %d)" % max_tokens)
	check(max_tokens >= 1, "someone attacked")


func test_never_hops_off_island() -> void:
	var water := Kit.water(self, Vector3(30.0, 1.0, 30.0), Vector2(30.0, 30.0))
	water.monitoring = true
	Kit.pillar(self, Vector3(30.0, 2.0, 30.0), 3.0, 4.0, &"stone_light")
	var g := _gloplet(Vector3(30.0, 2.0, 30.0), AttackDirector.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	await ticks(2)
	var bad := 0
	for i in 500:
		var a := rng.randf() * TAU
		var r := rng.randf_range(3.6, 8.0)
		if g.is_hop_target_safe(Vector3(30.0 + cos(a) * r, 2.0, 30.0 + sin(a) * r)):
			bad += 1
	check_eq(bad, 0, "no target off the island is accepted (500 fuzz)")
	for i in 1200:
		await ticks(1)
	check(is_instance_valid(g) and g.state != Gloplet.S.DEFEATED, "still alive after 20 s of wandering")
	check(g.global_position.y > 1.5, "still on the island")


func test_leash_returns_home() -> void:
	var g := _gloplet(Vector3.ZERO, AttackDirector.new())
	for i in 60:
		await ticks(1)
	p.respawn_at(Vector3(18.0, 0.05, 18.0))
	var home_at := -1
	for i in 600:
		await ticks(1)
		if g.state == Gloplet.S.IDLE and g.global_position.distance_to(g.home) < 1.0:
			home_at = i
			break
	check(home_at >= 0, "returned home and idled")


func test_bouncer_respawns_after_6s() -> void:
	var g := _gloplet(Vector3(5.0, 0.0, 5.0), AttackDirector.new(), preload("res://data/enemies/bouncer.tres"))
	await ticks(2)
	g.receive_player_attack({"id": 1, "damage": 9, "kind": &"slash_1", "from": Vector3.ZERO}, null)
	await ticks(5)
	check_eq(g.state, Gloplet.S.DORMANT, "dormant puddle")
	await ticks(g.def.respawn_ticks)
	check_eq(g.state, Gloplet.S.IDLE, "back after 6 s")
	check(g.visible and g.hp == g.def.hp, "fully restored")
