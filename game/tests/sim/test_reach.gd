extends TestCase
## Reach scenarios on the real controller (plan §7.3, T-009). Prints a table and checks the
## level facts that depend on it: the clearing's seed ledge needs a Bouncer, and the Springcap
## Plunge clears the Fernway cliff.

const SEED_LEDGE_RISE := Glimmerbrook.SEED_LEDGE_RISE
const CLIFF := Glimmerbrook.CLIFF


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(60.0, 2.0, 60.0))


func _apex(presses: Array[int]) -> float:
	var p := spawn_player(Vector3(0.0, 0.05, 0.0), false)
	await ticks(4)
	var inp := input_of(p)
	var start := p.global_position.y
	var best := 0.0
	inp.press(&"jump")
	var t := 0
	for i in 160:
		if t in presses:
			inp.press(&"jump")
		await ticks(1)
		t += 1
		best = maxf(best, p.global_position.y - start)
		if t > 5 and p.is_on_floor():
			break
	p.queue_free()
	await ticks(1)
	return best


func test_reach_heights() -> void:
	var j1 := await _apex([])
	var s := (preload("res://data/movement/hero_movement.tres") as MovementSettings)
	var t1 := int(s.jump_velocity(0) / s.gravity_up * 60.0)
	var t2 := t1 + int(s.jump_velocity(1) / s.gravity_up * 60.0)
	var j2 := await _apex([t1])
	var j3 := await _apex([t1, t2])
	print("    reach: J1 apex %.2f m, J1+J2 %.2f m, triple %.2f m" % [j1, j2, j3])
	check(absf(j1 - s.jump_heights[0]) < 0.4, "J1 close to its tuned height (%.2f)" % j1)
	check(j3 < SEED_LEDGE_RISE, "triple jump alone can't reach the clearing seed ledge (%.2f < %.1f)" % [j3, SEED_LEDGE_RISE])
	check(j3 < CLIFF, "triple jump alone can't climb the Fernway cliff, so the Plunge stays required")


func test_springcap_plunge_clears_cliff() -> void:
	var cap := Springcap.new()
	add_child(cap)
	var p := spawn_player(Vector3(0.0, 4.0, 0.0))
	await ticks(2)
	var inp := input_of(p)
	inp.tap(&"plunge")
	var best := 0.0
	var bounced := false
	for i in 200:
		await ticks(1)
		if p.velocity.y > 5.0:
			bounced = true
		if bounced:
			best = maxf(best, p.global_position.y)
	print("    reach: Springcap Plunge apex %.2f m above its base" % best)
	check(bounced, "the Springcap launched the Plunge")
	check(best > CLIFF + 1.0, "clears the 8 m Fernway cliff with margin")
	# Landing without a Plunge gives only the small bounce.
	p.respawn_at(Vector3(0.0, 4.0, 0.0))
	best = 0.0
	for i in 120:
		await ticks(1)
		best = maxf(best, p.global_position.y)
	check(best < CLIFF - 2.0, "a plain landing bounce stays well under the cliff (%.2f)" % best)
	# J1 onto the cap, small bounce, then J2 + J3: still short of the cliff top.
	var s := (preload("res://data/movement/hero_movement.tres") as MovementSettings)
	var reach := 1.2 + s.springcap_height + s.jump_heights[1] + s.jump_heights[2]
	check(reach < CLIFF, "small bounce + two air jumps can't skip the Plunge (%.1f < %.1f)" % [reach, CLIFF])
