extends TestCase
## Gate B combat tests (plan §15.2, 17-25), on the real loop with the real resolver.

class Target:
	extends Node3D
	var hits: int = 0

	func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
		hits += 1
		var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
		return {"hit": true, "bounce": float(atk.get("bounce", 2.2)) if plunge else 0.0}


var p: Player
var inp: ScriptedInput
var jumps: Array[int] = []


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	p.jumped.connect(func(n: int) -> void: jumps.append(n))
	await ticks(6)


func _target(at: Vector3, radius: float = 0.6) -> Target:
	var t := Target.new()
	t.position = at
	add_child(t)
	var a := Area3D.new()
	a.collision_layer = Layers.ENEMY_HURTBOX
	a.monitoring = false
	a.set_meta(&"actor", t)
	var s := SphereShape3D.new()
	s.radius = radius
	Kit.add_shape(a, s)
	t.add_child(a)
	return t


func _gloplet(at: Vector3, hp: int = 2) -> Gloplet:
	var d := (preload("res://data/enemies/gloplet.tres") as EnemyDef).duplicate() as EnemyDef
	d.hp = hp
	d.heart_drop_chance = 0.0
	var g := Gloplet.new()
	g.setup(d, at, AttackDirector.new(), 1)
	add_child(g)
	return g


func _plunge_until_bounce() -> bool:
	inp.tap(&"plunge")
	for i in 120:
		await ticks(1)
		if p.velocity.y > 0.0 and p.state == Player.State.NORMAL:
			return true
	return false


func test_17_plunge_refund() -> void:
	_target(Vector3(0.0, 3.0, 0.0))
	# After J3: J3 is available again, and only J3.
	p.respawn_at(Vector3(0.0, 9.0, 0.0))
	await ticks(1)
	inp.tap(&"jump")
	await ticks(3)
	inp.tap(&"jump")
	await ticks(3)
	check_eq(p.jumps_used, 3, "J2 and J3 spent")
	check(await _plunge_until_bounce(), "bounced off the hurtbox")
	check_eq(p.jumps_used, 2, "refund leaves J3 available")
	jumps.clear()
	await ticks(p.hitstop_ticks + 1)
	inp.tap(&"jump")
	await ticks(3)
	inp.tap(&"jump")
	await ticks(3)
	check_eq(jumps, [3] as Array[int], "exactly one jump (J3) after the pogo")
	# After J1 (normalised): J2 and J3 stay available, with no extra jump.
	p.respawn_at(Vector3(0.0, 9.0, 0.0))
	await ticks(10)
	check_eq(p.jumps_used, 1, "airborne normalisation")
	check(await _plunge_until_bounce(), "bounced again")
	check_eq(p.jumps_used, 1, "no extra jump granted")


func test_18_plunge_kill_still_bounces() -> void:
	var g := _gloplet(Vector3(0.0, 0.0, -4.0), 1)
	g.active = false
	await ticks(10)
	p.respawn_at(g.global_position + Vector3(0.0, 5.0, 0.0))
	await ticks(1)
	check(await _plunge_until_bounce(), "bounced")
	check(not is_instance_valid(g) or g.state in [Gloplet.S.DEFEATED, Gloplet.S.DORMANT], "the Gloplet was defeated")


func test_19_hurt_in_air() -> void:
	inp.tap(&"jump")
	await ticks(4)
	inp.tap(&"jump")
	await ticks(2)
	check_eq(p.jumps_used, 2, "J2 used")
	p.take_damage(1, p.global_position + Vector3(1.0, 0.0, 0.0))
	check_eq(p.jumps_used, 2, "getting hurt doesn't reset jumps")
	jumps.clear()
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps.size(), 0, "press during hurt stun discarded")
	await ticks(p.settings.hurt_ticks + 1)
	check(not p.has_buffered_jump(), "the discarded press wasn't buffered")


func test_20_jump_cancel_windows() -> void:
	# Startup: the jump cancels the attack and no hitbox appears.
	inp.tap(&"attack")
	await ticks(1)
	check_eq(p.attack_phase(), AttackDef.Phase.STARTUP, "in startup")
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps, [1] as Array[int], "jump fires in startup")
	check(p.attack == null, "attack cancelled before its hitbox")
	await until_grounded(p)
	await ticks(4)
	# Active: held, fires on the first recovery tick.
	jumps.clear()
	var tick_at_jump: Array[int] = []
	p.jumped.connect(func(_n: int) -> void: tick_at_jump.append(p.attack_tick))
	inp.tap(&"attack")
	for i in 10:
		await ticks(1)
		if p.attack_phase() == AttackDef.Phase.ACTIVE:
			break
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps.size(), 0, "held during active ticks")
	await ticks(6)
	check_eq(jumps, [1] as Array[int], "fired after active")
	var def := Player.ATTACK_SLASH_1
	check_eq(tick_at_jump.back(), def.startup + def.active, "on the first recovery tick")
	await until_grounded(p)
	await ticks(4)
	# Recovery: fires immediately.
	jumps.clear()
	inp.tap(&"attack")
	for i in 20:
		await ticks(1)
		if p.attack_phase() == AttackDef.Phase.RECOVERY:
			break
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps, [1] as Array[int], "fires immediately in recovery")


func test_21_one_air_slash_per_launch() -> void:
	inp.tap(&"jump")
	await ticks(3)
	inp.tap(&"attack")
	await ticks(1)
	check(p.attack != null and p.attack.is_air, "air slash")
	await ticks(Player.ATTACK_AIR.total() + 1)
	inp.tap(&"attack")
	await ticks(1)
	check(p.attack == null, "no second air slash on the same launch")
	inp.tap(&"jump")
	await ticks(2)
	inp.tap(&"attack")
	await ticks(1)
	check(p.attack != null and p.attack.is_air, "a new launch refills it")


func _wait_attack_tick(t: int) -> bool:
	for i in 60:
		if p.state == Player.State.ATTACK and p.attack_tick >= t:
			return true
		await ticks(1)
	return false


func test_22_ties_go_to_the_player() -> void:
	p.invuln_left = 99.0
	var a := _gloplet(Vector3(0.0, 0.0, -0.6), 3)
	a.active = false
	p.facing = Vector3.FORWARD
	await ticks(4)
	inp.tap(&"attack")
	check(await _wait_attack_tick(Player.ATTACK_SLASH_1.startup - 1), "attack started")
	p.invuln_left = 0.0
	var hp := p.hp
	await ticks(1)
	check(p.is_sword_active(), "sword active this tick")
	check_eq(a.hp, 2, "the Gloplet was hit")
	check_eq(p.hp, hp, "no contact damage from the enemy you hit this tick")
	# A different enemy still damages you on such a tick.
	p.invuln_left = 99.0
	a.queue_free()
	await ticks(30)
	p.respawn_at(Vector3(0.0, 0.05, 0.0), Vector3.FORWARD)
	var b := _gloplet(Vector3(0.0, 0.0, 0.25), 3)
	b.active = false
	await ticks(2)
	inp.tap(&"attack")
	check(await _wait_attack_tick(Player.ATTACK_SLASH_1.startup - 1), "second attack started")
	p.invuln_left = 0.0
	hp = p.hp
	await ticks(1)
	check(p.hp < hp, "the other Gloplet's contact still lands")


func test_24_jump_during_hitstop_not_lost() -> void:
	p.add_hitstop(6)
	await ticks(2)
	inp.tap(&"jump")
	await ticks(2)
	check_eq(jumps.size(), 0, "frozen during hit-stop")
	await ticks(6)
	check_eq(jumps, [1] as Array[int], "press survived hit-stop")


func test_25_knockback_stops_at_edge() -> void:
	floor_block(Vector3(10.0, 3.0, 0.0), Vector3(2.0, 1.0, 2.0))
	p.respawn_at(Vector3(10.7, 3.05, 0.0))
	await until_grounded(p)
	await ticks(3)
	p.take_damage(1, p.global_position + Vector3(-1.0, 0.0, 0.0))
	await ticks(30)
	check(p.is_on_floor() and p.global_position.y > 2.9, "still on the ledge")
	check(p.global_position.x <= 11.05, "stopped at the edge (x %.2f)" % p.global_position.x)


## Ashwin: swing toward the camera's facing, and the slash covers a wide arc side to side.
func test_slash_faces_camera_and_hits_wide() -> void:
	p.camera_yaw = PI * 0.5
	p.facing = Vector3.FORWARD
	var cam_fwd := Basis(Vector3.UP, PI * 0.5) * Vector3.FORWARD
	var right := cam_fwd.cross(Vector3.UP).normalized()
	var side := _target(p.global_position + Vector3.UP * 0.65 + cam_fwd * 2.1 + right * 2.4, 0.4)
	var behind := _target(p.global_position + Vector3.UP * 0.65 - cam_fwd * 2.5, 0.4)
	inp.tap(&"attack")
	await ticks(14)
	check(p.facing.distance_to(cam_fwd) < 0.05, "the hero turned to face where the camera looks")
	check(side.hits >= 1, "a target 2.4 m off to the side of the swing is hit")
	check_eq(behind.hits, 0, "nothing behind the hero is hit")
