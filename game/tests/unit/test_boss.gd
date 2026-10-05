extends TestCase
## Mother Gloop logic (plan §15.3): choices, forced patterns, window cap, thresholds, minimum
## windows, body extensions, single defeat event.

var b: MotherGloop


func before_each() -> void:
	b = MotherGloop.new()
	b.rng.seed = 99


func _exit_tree() -> void:
	if is_instance_valid(b) and not b.is_inside_tree():
		b.free()


func _hit(raw: int) -> int:
	b.core_invuln = 0
	return b.apply_core_damage(raw)


func test_choice_is_always_legal() -> void:
	for ph: int in [1, 2, 3]:
		b.phase = ph
		b.last_pattern = MotherGloop.Pattern.NONE
		var prev := MotherGloop.Pattern.NONE
		for i in 10000:
			var c := b.choose_pattern()
			check(c in b.eligible_patterns(), "phase %d: legal choice" % ph)
			if b.eligible_patterns().size() > 1 and prev != MotherGloop.Pattern.NONE:
				check(c != prev, "phase %d: never repeats the previous pattern" % ph)
			prev = c
			if not failures.is_empty():
				return


func test_forced_first_pattern_per_phase() -> void:
	b.phase = 2
	b.forced_pattern = MotherGloop.Pattern.BOUNCE_BARRAGE
	check_eq(b.choose_pattern(), MotherGloop.Pattern.BOUNCE_BARRAGE, "phase 2 opens with Bounce Barrage")
	b.phase = 3
	b.forced_pattern = MotherGloop.Pattern.ROLLING_CHARGE
	check_eq(b.choose_pattern(), MotherGloop.Pattern.ROLLING_CHARGE, "phase 3 opens with Rolling Charge")


func test_thresholds_clamp_damage() -> void:
	b.hp = 7
	b.open_window(150)
	check_eq(_hit(2), 1, "2 damage at 7 HP stops at 6")
	check_eq(b.hp, 6, "hp at threshold")
	check_eq(b.state, MotherGloop.S.PHASE_CHANGE, "window closes into the phase change")
	b.hp = 4
	b.open_window(150)
	check_eq(_hit(2), 1, "2 damage at 4 HP stops at 3")
	check_eq(b.hp, 3, "hp at second threshold")


func test_window_cap_and_no_threshold_crossing_fuzz() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for trial in 300:
		b.free()
		b = MotherGloop.new()
		b.hp = rng.randi_range(1, 9)
		b.windows_opened = 1
		b.open_window(150)
		var start := b.hp
		var dealt := 0
		for i in 8:
			if b.state != MotherGloop.S.CORE_WINDOW:
				break
			dealt += _hit(rng.randi_range(1, 2))
		check(dealt <= MotherGloop.WINDOW_CAP, "at most 3 damage per window")
		for t in MotherGloop.THRESHOLDS:
			if start > t:
				check(b.hp >= t, "never crosses threshold %d in one window (from %d to %d)" % [t, start, b.hp])
				break
		if not failures.is_empty():
			return


func test_win_needs_at_least_three_windows() -> void:
	var windows := 0
	while b.hp > 0 and windows < 20:
		b.open_window(150)
		windows += 1
		while b.state == MotherGloop.S.CORE_WINDOW:
			if _hit(2) == 0:
				break
	check_eq(b.hp, 0, "defeated")
	check(windows >= 3, "at least 3 windows (took %d)" % windows)


func test_body_hits_extend_at_most_09s() -> void:
	b.open_window(150)
	for i in 10:
		b.extend_window()
	check_eq(b.window_extend, MotherGloop.BODY_EXTEND_MAX, "capped at 0.9 s (54 ticks)")


func test_first_window_is_long() -> void:
	b.open_window(150)
	check_eq(b.window_len, MotherGloop.WINDOW_FIRST, "first window lasts 4 s")
	b.open_window(150)
	check_eq(b.window_len, 150, "later windows use the pattern's length")


func test_defeat_fires_exactly_once() -> void:
	var count := [0]
	b.defeated_once.connect(func() -> void: count[0] += 1)
	b.hp = 1
	b.open_window(150)
	_hit(2)
	check_eq(b.hp, 0, "hp zero")
	b.hp = 1
	b.open_window(150)
	_hit(2)
	check_eq(count[0], 1, "boss_defeated exactly once")
	check_eq(b.defeated_count, 1, "defeated_count is 1")


func test_director_blocks_minions_during_boss_windows() -> void:
	var d := AttackDirector.new()
	var minion := RefCounted.new()
	d.boss_lock = true
	check(not d.request(minion), "no token while the boss winds up or her core is open")
	d.boss_lock = false
	check(d.request(minion), "token once she's done")
