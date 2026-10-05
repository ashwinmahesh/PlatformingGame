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


func test_thresholds_start_phases() -> void:
	b.hp = 4
	b.open_window(150)
	check_eq(_hit(1), 1, "a Plunge deals 1")
	check_eq(b.hp, 3, "hp at the first threshold")
	check_eq(b.state, MotherGloop.S.PHASE_CHANGE, "phase 2 starts")
	b.hp = 2
	b.open_window(150)
	_hit(1)
	check_eq(b.hp, 1, "hp at the second threshold")
	check_eq(b.state, MotherGloop.S.PHASE_CHANGE, "phase 3 starts")


func test_one_plunge_per_opening() -> void:
	b.windows_opened = 1
	b.open_window(150)
	check_eq(_hit(1), 1, "first Plunge lands")
	check(b.state != MotherGloop.S.CORE_WINDOW, "the core closes as soon as it's hit")
	check_eq(_hit(1), 0, "a second Plunge in the same opening does nothing")
	check_eq(b.hp, MotherGloop.MAX_HP - 1, "exactly 1 damage")


func test_window_cap_fuzz() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for trial in 300:
		b.free()
		b = MotherGloop.new()
		b.hp = rng.randi_range(1, MotherGloop.MAX_HP)
		b.windows_opened = 1
		b.open_window(150)
		var dealt := 0
		for i in 8:
			if b.state != MotherGloop.S.CORE_WINDOW:
				break
			dealt += _hit(rng.randi_range(1, 2))
		check(dealt <= MotherGloop.WINDOW_CAP, "at most one hit per opening")
		if not failures.is_empty():
			return


func test_win_takes_five_clean_plunges() -> void:
	var windows := 0
	while b.hp > 0 and windows < 20:
		b.open_window(150)
		windows += 1
		while b.state == MotherGloop.S.CORE_WINDOW:
			if _hit(1) == 0:
				break
	check_eq(b.hp, 0, "defeated")
	check_eq(windows, MotherGloop.MAX_HP, "exactly 5 openings, one Plunge each")


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
