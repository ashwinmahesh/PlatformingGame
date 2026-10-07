extends TestCase
## World 8, Brickbloom Heights, on the real physics loop in the real level: the Counting Blocks
## count up and climb into a stair to their star; the Great Brass Balance carries a hero up to
## its crown and resets; Old Brickbeard's riddle digs up a star; warp pipes carry you between the
## tiers and the moat pipe into the Bonus Room and out again; bricks give up their seeds; the sun
## and moon steps swap; star-bricks only fall to a Star Rush; cannons tell before they fire; no
## gated star can be reached with a plain triple jump; and the Grand Star clears the world and
## teaches Star Rush once all six stars are in.

const W8 := &"world_08"


func before_each() -> void:
	Progress.new_game()


func _load(spawn: StringName = &"w8_entrance") -> Brickbloom:
	Router.pending_spawn = spawn
	var w := Progress.world_def(W8)
	var lvl := (load(w.scene_path) as PackedScene).instantiate() as Brickbloom
	add_child(lvl)
	await ticks(3)
	return lvl


func _scripted(p: Player) -> ScriptedInput:
	var inp := ScriptedInput.new()
	p.input_source = inp
	return inp


## Stick input that moves the hero toward `dir` (world, flat) whatever way the camera faces.
func _toward(p: Player, dir: Vector3) -> Vector2:
	var local := Basis(Vector3.UP, -p.camera_yaw) * Vector3(dir.x, 0.0, dir.z).normalized()
	return Vector2(local.x, -local.z)


func _free(lvl: Node) -> void:
	lvl.queue_free()
	await ticks(3)


## Jump toward `target` (a top to land on): steer while still short of it, double-jump on the way
## down if it's still ahead. Stops once landed.
func _hop_to(p: Player, inp: ScriptedInput, target: Vector3, max_ticks: int = 180) -> void:
	inp.tap(&"jump")
	var second := false
	for i in max_ticks:
		var flat := Vector3(target.x - p.global_position.x, 0.0, target.z - p.global_position.z)
		inp.move = _toward(p, flat) if flat.length() > 0.8 else Vector2.ZERO
		if not second and i > 8 and p.velocity.y < 0.0 and flat.length() > 1.2:
			inp.tap(&"jump")
			second = true
		await ticks(1)
		if i > 10 and p.is_on_floor():
			break
	inp.move = Vector2.ZERO
	await ticks(20)


## Jump straight up from `foot` (a hero standing there) and give the bonk time to land.
func _hop_under(p: Player, inp: ScriptedInput, foot: Vector3) -> void:
	p.respawn_at(foot + Vector3.UP * 0.05)
	await ticks(4)
	inp.tap(&"jump")
	await ticks(45)


func test_counting_blocks_count_up_and_climb_to_the_star() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var seq := lvl.counting
	var by_number: Dictionary[int, PipBlock] = {}
	for b in seq.blocks:
		by_number[b.number] = b
	check_eq(by_number.size(), 5, "five Counting Blocks")
	var foot_of := func(b: PipBlock) -> Vector3:
		return Vector3(b.global_position.x, b.global_position.y - b.size.y - 3.6, b.global_position.z)
	# Wrong first: block two buzzes and nothing stays lit.
	await _hop_under(p, inp, foot_of.call(by_number[2]) as Vector3)
	check(not by_number[2].lit, "bonking two first is wrong: it stays dark")
	# One to five, each bonked from below in turn.
	for n in range(1, 6):
		await _hop_under(p, inp, foot_of.call(by_number[n]) as Vector3)
		check(by_number[n].lit, "block %d lights when bonked in turn" % n)
	check(seq.done, "counting one to five solves it")
	await ticks(200)
	for n in range(1, 6):
		check(by_number[n].global_position.distance_to(seq.stair[n - 1]) < 0.2, "block %d flew into its stair spot" % n)
	# Every step of the stair is a hop of under 3 m, ending a short hop under the plinth's top.
	var prev := Brickbloom.COURT.y + 2.6
	for n in range(1, 6):
		var rise := seq.stair[n - 1].y - prev
		check(rise > 0.0 and rise <= 3.0, "stair step %d rises %.1f m" % [n, rise])
		prev = seq.stair[n - 1].y
	check(Brickbloom.COURT_TOP - prev <= 3.0, "the plinth is a short hop from the top step")
	# From the top step, a jump toward the plinth collects the star.
	var top := seq.stair[4]
	p.respawn_at(top + Vector3.UP * 0.1)
	await ticks(6)
	await _hop_to(p, inp, Brickbloom.COURT + Vector3(0.0, Brickbloom.COURT_TOP, 0.0))
	check(Progress.has_shard(&"w8_shard_counting"), "the stair leads to the Counting Court's star")
	await _free(lvl)


func test_balance_lifts_a_hero_to_its_crown_and_resets() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var bl := lvl.balance
	var near := Brickbloom.BALANCE + Vector3(bl.spacing * 0.5, 0.0, 0.0)
	await ticks(10)
	check(bl.near_pan_top() < 0.1, "the sandbag holds the near pan on the ground (%.1f)" % bl.near_pan_top())
	check(bl.far_pan_top() > bl.travel - 0.1, "and the far pan hangs high under the hopper")
	# Bonking the brick from the ground beside the pan does nothing to the hero (they're not on it):
	# so stand on the near pan and bonk it.
	await _hop_under(p, inp, near)
	check(not bl.loaded, "bonking the brick drops the big weight")
	var best := 0.0
	for i in 420:
		await ticks(1)
		best = maxf(best, p.global_position.y)
		if p.global_position.y > bl.travel - 0.3 and p.is_on_floor():
			break
	check(best > bl.travel - 0.5, "three pips beat a sandbag and a hero: the near pan rides up (top %.1f m)" % best)
	# From the raised pan, a jump onto the crown takes the star.
	await _hop_to(p, inp, Brickbloom.BALANCE + Vector3(0.0, Brickbloom.BALANCE_TRAVEL + 3.0, 0.0))
	check(Progress.has_shard(&"w8_shard_balance"), "the crown's Star Shard is collected")
	# Off the pan for a few seconds, the weight is winched back and the near pan comes home.
	p.respawn_at(Brickbloom.BALANCE + Vector3(0.0, 0.05, 14.0))
	for i in 600:
		await ticks(1)
		if bl.loaded and bl.near_pan_top() < 0.1:
			break
	check(bl.loaded, "the weight goes back into the hopper")
	check(bl.near_pan_top() < 0.1, "and the near pan settles back on the ground")
	await ticks(90)
	check(bl.brick.position.distance_to(Vector3(bl.spacing * 0.5, 6.0, 0.0)) < 0.1, "the brick slides back over the near pan")
	await _free(lvl)


func test_riddle_dig_turns_up_a_star() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var digs := lvl.find_children("*", "DigSpot", true, false)
	check_eq(digs.size(), 1, "one dig spot")
	var dig := digs[0] as DigSpot
	check_eq(dig.reward_shard, &"w8_shard_riddle", "it holds the riddle's star")
	# Brickbeard's riddle: the ball between two red flags, three big steps toward the sunset (west).
	p.respawn_at(dig.global_position + Vector3(1.2, 0.0, 0.0), Vector3.LEFT)
	await ticks(6)
	inp.tap(&"interact")
	await ticks(60)
	check(dig.done, "talking to the glitter digs it up")
	check(Progress.has_shard(&"w8_shard_riddle"), "and the star drifts to the hero")
	await _free(lvl)


func test_warp_pipes_link_the_tiers_and_the_moat_hides_the_bonus_room() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	# Plunge into the plaza's green pipe: out of the pipe on the green terrace.
	var a := lvl.pipes[&"plaza_east"]
	var b := lvl.pipes[&"terraces"]
	p.respawn_at(a.global_position + Vector3.UP * 3.0)
	await ticks(2)
	inp.tap(&"plunge")
	await ticks(90)
	check(p.global_position.distance_to(b.global_position) < 4.0, "a Plunge into the plaza pipe pops out on the terraces (%.1f m off)" % p.global_position.distance_to(b.global_position))
	check(p.global_position.y > Brickbloom.RAMPART, "up on the 12 m tier")
	# Stand on the ridge pipe and press E: back down to the plaza.
	var r := lvl.pipes[&"ridge"]
	var q := lvl.pipes[&"plaza_north"]
	p.respawn_at(r.global_position + Vector3.UP * 0.1)
	await ticks(10)
	inp.tap(&"interact")
	await ticks(90)
	check(p.global_position.distance_to(q.global_position) < 4.0, "E on top of the ridge pipe comes out at the plaza")
	# The moat pipe: swim down into it and you're in the Bonus Room.
	var moat := lvl.pipes[&"moat"]
	p.respawn_at(moat.global_position + Vector3.UP * 0.6)
	await ticks(90)
	var inside := lvl.pipes[&"bonus_in"]
	check(p.global_position.distance_to(inside.global_position) < 4.0, "the moat pipe drops you into the Bonus Room")
	check(p.global_position.y < -40.0, "deep under the meadow")
	# The way in is exit-only; the way out comes up on the moat bank.
	p.respawn_at(inside.global_position + Vector3.UP * 0.1)
	await ticks(10)
	inp.tap(&"interact")
	await ticks(60)
	check(p.global_position.y < -40.0, "the arrival pipe doesn't lead back")
	var out := lvl.pipes[&"bonus_out"]
	p.respawn_at(out.global_position + Vector3.UP * 0.1)
	await ticks(10)
	inp.tap(&"interact")
	await ticks(90)
	check(p.global_position.distance_to(lvl.pipes[&"bank"].global_position) < 4.0, "the way out comes up on the moat bank")
	await _free(lvl)


func test_bricks_give_seeds_and_crumble() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var seed_brick: BonkBrick = null
	var crumbly: BonkBrick = null
	for n in lvl.find_children("*", "BonkBrick", true, false):
		var b := n as BonkBrick
		if b.global_position.z == 86.0 and b.kind == BonkBrick.Kind.SEED:
			seed_brick = b
		elif b.global_position.z == 86.0 and b.kind == BonkBrick.Kind.BREAK and crumbly == null:
			crumbly = b
	check(seed_brick != null and crumbly != null, "the meadow row has a seed brick and crumbly ones")
	if seed_brick == null or crumbly == null:
		await _free(lvl)
		return
	await _hop_under(p, inp, Vector3(seed_brick.global_position.x, 0.0, 86.0))
	check(seed_brick.used, "bonking the glinting brick empties it")
	# The seed popped out on top: stand on the brick and it's yours.
	p.respawn_at(seed_brick.global_position + Vector3.UP * 0.1)
	await ticks(40)
	check(Progress.has_seed(&"w8_seed_brick_meadow"), "the brick's Glimmer Seed is collected")
	var where := crumbly.global_position
	await _hop_under(p, inp, Vector3(where.x, 0.0, 86.0))
	check(not is_instance_valid(crumbly), "a crumbly brick bursts when bonked")
	await _free(lvl)


func test_sun_and_moon_steps_swap() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var fb := lvl.flips
	var steps := fb.find_children("*", "GhostPlatform", true, false)
	check_eq(steps.size(), 3, "three sun and moon steps")
	var moon: GhostPlatform = null
	for s in steps:
		if (s as GhostPlatform).color_name == &"roof_blue":
			moon = s as GhostPlatform
	check(moon != null and not moon.solid, "the moon step starts as a ghost")
	var sw := fb.find_children("*", "BonkBrick", true, false)[0] as BonkBrick
	await _hop_under(p, inp, Vector3(sw.global_position.x, 0.0, sw.global_position.z))
	check(not fb.sun, "bonking the ground flip brick swaps to moon")
	check(moon.solid, "and the moon step turns solid")
	await _free(lvl)


func test_star_bricks_only_fall_to_a_star_rush() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var walls := lvl.find_children("*", "RushWall", true, false)
	check_eq(walls.size(), 1, "one star-brick wall")
	var wall := walls[0] as RushWall
	var front := wall.global_position + wall.global_basis.z * 4.0 + Vector3.UP * 0.05
	p.respawn_at(front, -wall.global_basis.z)
	await ticks(4)
	inp.tap(&"attack")
	await ticks(30)
	check(is_instance_valid(wall), "a sword just clanks off it")
	p.abilities_override = [&"rush"]
	p.respawn_at(front, -wall.global_basis.z)
	await ticks(4)
	inp.tap(&"ability_8")
	await ticks(40)
	check(not is_instance_valid(wall), "a Star Rush bowls straight through")
	await _free(lvl)


func test_cannons_tell_then_fire_and_a_ball_stings() -> void:
	floor_block(Vector3.ZERO, Vector3(40.0, 2.0, 40.0))
	var c := BrickCannon.new()
	c.interval = 2.0
	c.lane = 20.0
	c.position = Vector3(0.0, 0.0, 8.0)
	add_child(c)
	var p := spawn_player(Vector3(0.0, 0.05, -2.0))
	await ticks(4)
	var hp := p.hp
	var told := false
	for i in 320:
		await ticks(1)
		if c.get("_telling") == true and c.fired == 0:
			told = true
		if p.hp < hp:
			break
	check(told, "the barrel glows and shakes before it fires")
	check_eq(c.fired, 1, "then it fires")
	check_eq(p.hp, hp - 1, "a cannonball costs half a heart")


## The gated stars sit more than a triple jump (with a little to spare) above anything you can
## stand on nearby that isn't the puzzle that gets you there.
func test_gated_stars_cannot_be_triple_jumped() -> void:
	var lvl := await _load()
	await ticks(30)
	var space := lvl.get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for n in lvl.balance.find_children("*", "CollisionObject3D", true, false):
		exclude.append((n as CollisionObject3D).get_rid())
	var targets: Dictionary[String, Vector3] = {
		"Counting Court plinth": Brickbloom.COURT + Vector3(0.0, Brickbloom.COURT_TOP, 0.0),
		"Brass Balance crown": Brickbloom.BALANCE + Vector3(0.0, Brickbloom.BALANCE_TRAVEL + 3.0, 0.0),
		"Star Turret": Vector3(0.0, Brickbloom.STAR_TOP, 0.0),
	}
	for label: String in targets:
		var t := targets[label]
		var highest := -INF
		var at := Vector3.ZERO
		for ix in range(-22, 23):
			for iz in range(-22, 23):
				var off := Vector2(ix, iz)
				if off.length() > 22.0 or off.length() < 3.2:
					continue
				var from := t + Vector3(ix, 40.0, iz)
				var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 120.0, Layers.WORLD)
				q.exclude = exclude
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					continue
				var y := (hit["position"] as Vector3).y
				if y > highest:
					highest = y
					at = hit["position"] as Vector3
		check(t.y - highest > 10.2, "%s (%.1f m) is out of triple-jump reach of the highest nearby perch (%.1f m at %s)" % [label, t.y, highest, str(at.snapped(Vector3.ONE * 0.1))])
	await _free(lvl)


func test_grand_star_clears_brickbloom_and_teaches_star_rush() -> void:
	var lvl := await _load()
	var p := lvl.player
	var inp := _scripted(p)
	var steps := lvl.stair
	check_eq(steps.size(), 5, "five stair blocks wait round the Star Turret")
	for s in steps:
		check(not s.solid, "they start as ghosts")
	var learned: Array[StringName] = []
	var on_learn := func(a: StringName) -> void: learned.append(a)
	Events.ability_learned.connect(on_learn)
	for sid in Progress.world_def(W8).shard_ids:
		Progress.collect_shard(sid)
	await ticks(90)
	for s in steps:
		check(s.solid, "with the stars in, the stair blocks turn solid")
	# Climb from the keep roof up the stair, block by block, then onto the turret's star.
	var prev := Brickbloom.KEEP_TOP
	for s in steps:
		check(s.global_position.y - prev <= 3.0, "each stair block is a short hop")
		prev = s.global_position.y
	check(Brickbloom.STAR_TOP - prev <= 3.0, "the turret top is a short hop from the last block")
	var last := steps[steps.size() - 1]
	p.respawn_at(last.global_position + Vector3.UP * 0.1)
	await ticks(6)
	await _hop_to(p, inp, Vector3(0.0, Brickbloom.STAR_TOP, 0.0))
	check(Progress.is_world_complete(W8), "touching the Grand Star clears Brickbloom Heights")
	check(&"rush" in learned, "and with all six stars in, it teaches Star Rush")
	check(p.has_ability(&"rush"), "the hero can now Star Rush")
	Events.ability_learned.disconnect(on_learn)
	await _free(lvl)
