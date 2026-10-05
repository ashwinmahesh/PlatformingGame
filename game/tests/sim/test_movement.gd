extends TestCase
## Gate A movement tests (plan §15.2, 1-16), on the real loop in physics scenes.

var p: Player
var inp: ScriptedInput
var jumps: Array[int] = []


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(40.0, 2.0, 40.0))
	p = spawn_player(Vector3(0.0, 0.05, 0.0))
	inp = input_of(p)
	p.jumped.connect(func(n: int) -> void: jumps.append(n))
	await ticks(8)


func _v(i: int) -> float:
	return p.settings.jump_velocity(i)


func _g_tick() -> float:
	return p.settings.gravity_up / 60.0


func test_01_ground_press_gives_j1() -> void:
	inp.tap(&"jump")
	await ticks(1)
	check_eq(p.jumps_used, 1, "jumps_used after J1")
	check_eq(jumps, [1] as Array[int], "jump events")
	check_near(p.velocity.y, _v(0) - _g_tick(), 0.05, "J1 launch speed")


func test_02_three_presses_then_nothing() -> void:
	for i in 3:
		inp.tap(&"jump")
		await ticks(12)
	check_eq(jumps, [1, 2, 3] as Array[int], "J1, J2, J3")
	var vy_before := p.velocity.y
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps.size(), 3, "a fourth press does nothing")
	check(p.velocity.y < vy_before, "no fourth launch")


func test_03_holding_never_repeats() -> void:
	inp.press(&"jump")
	await ticks(150)
	check_eq(jumps, [1] as Array[int], "one jump while held through a landing")


func test_04_walk_off_within_coyote_gives_j1() -> void:
	_ledge_setup()
	inp.move = Vector2(0.0, 1.0)
	var left := await _walk_until_airborne()
	check(left, "walked off the ledge")
	await ticks(2)
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps, [1] as Array[int], "J1 inside coyote time")
	check_near(p.velocity.y, _v(0) - _g_tick(), 0.05, "J1 height")


func test_05_walk_off_after_coyote_gives_j2_j3() -> void:
	_ledge_setup()
	inp.move = Vector2(0.0, 1.0)
	await _walk_until_airborne()
	await ticks(10)
	inp.tap(&"jump")
	await ticks(6)
	inp.tap(&"jump")
	await ticks(6)
	inp.tap(&"jump")
	await ticks(2)
	check_eq(jumps, [2, 3] as Array[int], "J2 then J3 then nothing")


func test_06_buffer_010s_before_contact_gives_j1() -> void:
	var land := await _drop_landing_tick()
	await _reset_drop()
	# The press is processed on tick land-6; contact is detected by tick land's move.
	await ticks(land - 7)
	inp.tap(&"jump")
	await ticks(7)
	check_eq(jumps.size(), 0, "no jump before contact")
	await ticks(1)
	check_eq(jumps, [1] as Array[int], "buffered J1 on the tick after contact")


func test_07_buffer_020s_before_contact_expires() -> void:
	var land := await _drop_landing_tick()
	await _reset_drop()
	await ticks(land - 13)
	inp.tap(&"jump")
	await ticks(30)
	check_eq(jumps.size(), 0, "press 0.20 s early expired")


func test_08_press_on_contact_tick_jumps_next_tick() -> void:
	var land := await _drop_landing_tick()
	await _reset_drop()
	await ticks(land - 1)
	inp.tap(&"jump")
	await ticks(1)
	check(p.is_on_floor(), "contact detected on the press tick")
	check_eq(jumps.size(), 0, "no jump on the contact tick")
	await ticks(1)
	check_eq(jumps, [1] as Array[int], "J1 on the next tick")


func test_09_air_jump_left_one_tick_before_contact() -> void:
	# Default: an air press with jumps left is always an air jump.
	var land := await _drop_landing_tick(false)
	await _reset_drop(false)
	await ticks(land - 2)
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps, [2] as Array[int], "air jump by default")
	# Prefer ground jump: the press is held and becomes J1.
	jumps.clear()
	p.settings.prefer_ground_jump = true
	await _reset_drop(false)
	await ticks(land - 2)
	inp.tap(&"jump")
	await ticks(6)
	check_eq(jumps, [1] as Array[int], "prefer ground jump holds the press for J1")


func test_10_teleport_midair_leaves_j2_j3() -> void:
	p.respawn_at(Vector3(0.0, 6.0, 0.0))
	await ticks(10)
	inp.tap(&"jump")
	await ticks(4)
	inp.tap(&"jump")
	await ticks(4)
	check_eq(jumps, [2, 3] as Array[int], "J2 and J3 after a mid-air teleport")


func test_11_ceiling_bonk() -> void:
	floor_block(Vector3(0.0, 4.2, 0.0), Vector3(6.0, 1.0, 6.0))
	inp.tap(&"jump")
	var bonked := false
	for i in 30:
		await ticks(1)
		if p.velocity.y <= 0.0 and not p.is_on_floor():
			bonked = true
			break
	check(bonked, "hit the ceiling")
	check(p.global_position.y < 3.0, "stopped under the ceiling")
	check_eq(p.jumps_used, 1, "jump stays spent")
	check(not p.has_buffered_jump(), "buffer cleared")
	await until_grounded(p)
	await ticks(1)
	check_eq(p.jumps_used, 0, "landing resets normally")


func test_12_walls_never_reset_jumps() -> void:
	floor_block(Vector3(0.0, 8.0, -1.2), Vector3(6.0, 8.0, 1.0))
	inp.move = Vector2(0.0, 1.0)
	inp.tap(&"jump")
	await ticks(10)
	inp.tap(&"jump")
	await ticks(12)
	check(p.is_on_wall() or p.global_position.z < -0.2, "pressed against the wall")
	check_eq(p.jumps_used, 2, "wall contact never resets jumps")


func test_13_moving_platforms() -> void:
	for spec: Array in [[Vector3(6.0, 0.0, 0.0), "sideways"], [Vector3(0.0, 3.0, 0.0), "vertical"]]:
		var plat := MovingPlatform.new()
		plat.rounded = false
		plat.size = Vector3(4.0, 0.5, 4.0)
		plat.travel = spec[0] as Vector3
		plat.period = 3.0
		plat.position = Vector3(20.0, 4.0, 20.0)
		add_child(plat)
		await ticks(2)
		p.respawn_at(plat.global_position + Vector3(0.0, 0.6, 0.0))
		jumps.clear()
		await until_grounded(p)
		await ticks(20)
		check_eq(p.jumps_used, 0, "%s: landing on a platform resets jumps" % spec[1])
		var pv := p.get_platform_velocity()
		inp.tap(&"jump")
		await ticks(1)
		check_eq(jumps, [1] as Array[int], "%s: jumped" % spec[1])
		check_near(p.velocity.y, _v(0) - _g_tick(), 0.05, "%s: only horizontal platform velocity added" % spec[1])
		check_near(p.velocity.x, pv.x, 0.6, "%s: horizontal push inherited" % spec[1])
		plat.queue_free()
		await ticks(2)


func test_14_steps() -> void:
	# Steps of 0.1/0.2/0.35 m climb at full speed; 0.4 m blocks.
	for h: float in [0.1, 0.2, 0.35]:
		p.respawn_at(Vector3(0.0, 0.05, 6.0))
		var step := floor_block(Vector3(0.0, h, 0.0), Vector3(4.0, h, 3.0))
		await ticks(4)
		inp.move = Vector2(0.0, 1.0)
		var max_vy := 0.0
		for i in 100:
			await ticks(1)
			max_vy = maxf(max_vy, p.velocity.y)
		inp.move = Vector2.ZERO
		check(p.global_position.z < -2.5, "%.2f m step: walked across" % h)
		check(max_vy < 3.0, "%.2f m step: no launch (max vy %.2f)" % [h, max_vy])
		step.queue_free()
		await ticks(2)
	p.respawn_at(Vector3(0.0, 0.05, 6.0))
	var wall := floor_block(Vector3(0.0, 0.4, 0.0), Vector3(4.0, 0.4, 3.0))
	await ticks(4)
	inp.move = Vector2(0.0, 1.0)
	await ticks(60)
	check(p.global_position.z > 1.0 and p.global_position.y < 0.2, "0.4 m step blocks")
	wall.queue_free()


func test_15_respawn_resets_state() -> void:
	inp.tap(&"jump")
	await ticks(3)
	inp.tap(&"jump")
	await ticks(1)
	p.respawn_at(Vector3(2.0, 0.05, 2.0))
	check_eq(p.jumps_used, 0, "jumps reset")
	check(not p.has_buffered_jump(), "buffer cleared")
	check_eq(p.coyote_left, 0.0, "coyote cleared")


func test_16_air_jump_replaces_vertical_speed() -> void:
	p.respawn_at(Vector3(0.0, 30.0, 0.0))
	await ticks(1)
	inp.tap(&"jump")
	await ticks(1)
	check_eq(jumps, [2] as Array[int], "J2 first (airborne)")
	await ticks(50)
	check(p.velocity.y < -10.0, "falling fast (%.1f)" % p.velocity.y)
	inp.tap(&"jump")
	await ticks(1)
	check_near(p.velocity.y, _v(2) - _g_tick(), 0.05, "J3 replaces vertical speed")


# --- helpers ----------------------------------------------------------------------------------

func _ledge_setup() -> void:
	# The test floor ends at z = -20; walk off a raised ledge closer by.
	floor_block(Vector3(0.0, 3.0, 4.0), Vector3(4.0, 1.0, 4.0))
	p.respawn_at(Vector3(0.0, 3.05, 5.5))
	await until_grounded(p)
	await ticks(4)


func _walk_until_airborne() -> bool:
	for i in 120:
		await ticks(1)
		if not p.is_on_floor():
			return true
	return false


## Drop from 4 m with every jump spent (or with an air jump left); returns ticks until contact.
func _drop_landing_tick(spent: bool = true) -> int:
	await _reset_drop(spent)
	var t := 0
	while t < 300:
		await ticks(1)
		t += 1
		if p.is_on_floor():
			return t
	return -1


func _reset_drop(spent: bool = true) -> void:
	p.respawn_at(Vector3(0.0, 4.0, 0.0))
	p.jumps_used = 3 if spent else 1
	jumps.clear()
	await ticks(0)


func _ticks_until_jump(n: int) -> int:
	for i in n:
		if not jumps.is_empty():
			return i
		await ticks(1)
	return 0 if not jumps.is_empty() else -1
