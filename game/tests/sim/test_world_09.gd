extends TestCase
## World 9, Dinodew Jungle, on the real physics loop: riding Trundle round the lake, Mossback's
## neck bridge after breakfast, Snoozer's gong lift, the Spring Locks and the Hatchery gate, the
## Tar Crater's turning log, and Chomposaurus Rex's crest (follows his body, only hops you).

var lvl: Dinodew
var p: Player
var inp: ScriptedInput


func before_each() -> void:
	Progress.new_game()


func _load(spawn: StringName = &"w9_entrance") -> void:
	var w := Progress.world_def(&"world_09")
	Router.pending_spawn = spawn
	lvl = (load(w.scene_path) as PackedScene).instantiate() as Dinodew
	add_child(lvl)
	await ticks(3)
	p = lvl.player
	inp = ScriptedInput.new()
	p.input_source = inp
	p.invuln_left = 9999.0


func _done() -> void:
	lvl.queue_free()
	await ticks(3)


## Walk toward `to` (flat) for up to n ticks, steering by camera-relative input.
func _walk_to(to: Vector3, n: int = 240, near: float = 0.7) -> void:
	for i in n:
		p.invuln_left = 9999.0
		var d := to - p.global_position
		d.y = 0.0
		if d.length() < near:
			break
		var local := Basis(Vector3.UP, -p.camera_yaw) * d.normalized()
		inp.move = Vector2(local.x, -local.z)
		await ticks(1)
	inp.move = Vector2.ZERO


## Jump toward `to` (flat), holding the direction until landing (max n ticks).
func _jump_to(to: Vector3, presses: int = 1, n: int = 120) -> void:
	inp.tap(&"jump")
	var pressed := 1
	for i in n:
		p.invuln_left = 9999.0
		var d := to - p.global_position
		d.y = 0.0
		var local := Basis(Vector3.UP, -p.camera_yaw) * (d.normalized() if d.length() > 0.3 else Vector3.ZERO)
		inp.move = Vector2(local.x, -local.z)
		await ticks(1)
		if pressed < presses and p.velocity.y < 1.0 and i > 6:
			inp.tap(&"jump")
			pressed += 1
		if i > 8 and p.is_on_floor():
			break
	inp.move = Vector2.ZERO


func test_trundle_carries_the_hero_round_the_lake_to_lookout_rock() -> void:
	await _load(&"w9_cp_lake")
	var t := lvl.trundle
	var saddle := t.find_child("TrundleSaddle", true, false) as AnimatableBody3D
	check(saddle != null, "Trundle has a saddle")
	# He waits at the station: climb the station steps and walk up his tail to the saddle.
	for i in 60:
		await ticks(1)
		if t.waiting == 0:
			break
	check_eq(t.waiting, 0, "Trundle starts waiting at the station")
	var tail: Array[AnimatableBody3D] = []
	for piece in t.pieces():
		if piece.name.begins_with("Ride_Tail") or piece.name.begins_with("Ride_Back"):
			tail.append(piece)
	tail.sort_custom(func(a: AnimatableBody3D, b: AnimatableBody3D) -> bool: return t.to_local(a.global_position).z < t.to_local(b.global_position).z)
	var foot := tail[0].global_transform * Vector3(0.0, 0.2, -1.0)
	p.respawn_at(foot + Vector3.UP * 0.6)
	await until_grounded(p)
	for piece in tail:
		await _walk_to(piece.global_position, 90, 0.6)
	await _jump_to(saddle.global_position, 1, 90)
	await _walk_to(saddle.global_position, 60, 0.4)
	await ticks(5)
	var rel0 := saddle.global_transform.affine_inverse() * p.global_position
	check(absf(rel0.x) < 1.7 and absf(rel0.z) < 2.6 and rel0.y > 0.0 and rel0.y < 1.0, "walked up his tail onto the saddle while he waited (rel %s)" % str(rel0.snapped(Vector3.ONE * 0.1)))
	var off := 0
	var reached_rock := false
	for i in 2400:
		await ticks(1)
		p.invuln_left = 9999.0
		var rel := saddle.global_transform.affine_inverse() * p.global_position
		if absf(rel.x) > 1.7 or absf(rel.z) > 2.6 or rel.y < 0.0 or rel.y > 1.0:
			off += 1
		if t.waiting == 1:
			reached_rock = true
			break
	check_eq(off, 0, "the hero rides the walking triceratops without sliding off")
	check(reached_rock, "Trundle wades the stepping-path and stops beside Lookout Rock")
	check(p.global_position.y > Dinodew.CAUSEWAY_Y + 8.5, "the saddle is high above the lake (y %.1f)" % p.global_position.y)
	# From the saddle, one hop up onto the rock.
	await _jump_to(Dinodew.ROCK + Vector3(0.0, Dinodew.ROCK_TOP, 0.0), 2, 150)
	await _walk_to(Dinodew.ROCK + Vector3(0.0, Dinodew.ROCK_TOP, 0.0), 120)
	await ticks(30)
	check(Progress.has_shard(&"w9_shard_lookout"), "hopping across from the saddle reaches the Lookout Rock shard (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


func test_mossback_eats_then_her_neck_is_a_bridge_up_the_great_cliff() -> void:
	await _load(&"w9_cp_fernfloor")
	var m := lvl.mossback
	check(m.state == HungryLongneck.S.HUNGRY, "Mossback starts hungry, head held high")
	var head_hungry := m.head_piece.global_position
	# Knock a melon off the cycad: it rolls into her trough and she eats.
	var melon: Area3D = null
	for n in lvl.get_children():
		if n is Area3D and n.has_meta(&"melon"):
			melon = n as Area3D
	check(melon != null, "a melon hangs on the cycad")
	m.receive_player_attack({"id": 77, "kind": &"slash_1"}, melon)
	for i in 720:
		await ticks(1)
		if m.is_resting():
			break
	check(m.is_resting(), "she bends down, eats, and rests her chin on the cliff")
	check(m.head_piece.global_position.y < head_hungry.y - 5.0, "her head came down (from %.1f to %.1f)" % [head_hungry.y, m.head_piece.global_position.y])
	# Walk it: up the tail from the mounting stone, along her back, up her neck, onto the cliff.
	var route: Array[Vector3] = []
	var pieces := m.dino.pieces()
	pieces.sort_custom(func(a: AnimatableBody3D, b: AnimatableBody3D) -> bool: return m.to_local(a.global_position).z < m.to_local(b.global_position).z)
	for piece in pieces:
		route.append(piece.global_position)
	p.respawn_at(Dinodew.MOSSBACK + Vector3(-1.7, 1.4, 31.0))
	await until_grounded(p)
	var lowest_on_neck := INF
	for wp in route:
		await _walk_to(wp, 200, 0.9)
		if m.to_local(p.global_position).z > 6.0:
			lowest_on_neck = minf(lowest_on_neck, p.global_position.y)
	await _walk_to(Vector3(m.head_piece.global_position.x, Dinodew.T2, -27.0), 120)
	await ticks(20)
	check(p.is_on_floor() and p.global_position.y > Dinodew.T2 - 0.2, "walked tail, back and neck up onto the Great Cliff (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	check(lowest_on_neck > 7.0, "never fell off her neck (lowest %.1f)" % lowest_on_neck)
	await _done()


func test_snoozer_wakes_at_the_gong_and_lifts_the_hero_to_the_nest() -> void:
	await _load(&"w9_cp_village")
	var s := lvl.snoozer
	check(s.state == SleepyDino.S.ASLEEP, "Snoozer starts asleep")
	# Climb his back-plate caps from the haystack.
	p.respawn_at(s.to_global(Vector3(0.0, SleepyDino.BALE_TOP + 0.1, -10.0)))
	await until_grounded(p)
	for pad in s.pads:
		await _jump_to(pad.global_position, 1, 90)
	await _jump_to(s.deck.global_position, 1, 90)
	await _walk_to(s.deck.global_position, 60, 0.5)
	await ticks(10)
	var asleep_y := p.global_position.y
	check(absf(asleep_y - (s.deck.global_position.y + 0.18)) < 0.3, "climbed the back-plate staircase onto his saddle (y %.1f)" % asleep_y)
	# Ring the gong: he stands up with the hero aboard.
	s.receive_player_attack({"id": 501, "kind": &"slash_1"}, null)
	var off := 0
	for i in 240:
		await ticks(1)
		p.invuln_left = 9999.0
		var rel := s.deck.global_transform.affine_inverse() * p.global_position
		if absf(rel.y) > 0.6:
			off += 1
	check(s.is_awake(), "the gong wakes him and he stands")
	check_eq(off, 0, "the hero rides the saddle up")
	check(p.global_position.y > asleep_y + SleepyDino.SINK - 0.4, "lifted %.1f m" % (p.global_position.y - asleep_y))
	check(lvl.nest_deck_top - p.global_position.y < 3.0, "the nest is one hop above the raised saddle")
	var nest := Vector3(s.deck.global_position.x, lvl.nest_deck_top, s.deck.global_position.z - 8.0)
	await _jump_to(nest, 2, 150)
	await _walk_to(nest + Vector3(0.0, 0.0, -0.8), 90, 0.5)
	await ticks(30)
	check(Progress.has_shard(&"w9_shard_snoozer"), "the nest shard is collected (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


func test_spring_locks_share_one_spring_and_the_float_opens_the_hatchery() -> void:
	await _load(&"w9_cp_locks")
	var sl := lvl.locks
	var lower := sl.locks[0]
	var upper := sl.locks[1]
	check(lower.is_full() and not upper.is_full(), "the lower lock starts full, the upper drained")
	check(lvl.hatch_gate.collision_layer != 0, "the Hatchery gate starts shut")
	# Float up the lower lock and over the divider into the upper one.
	p.respawn_at(Vector3(68.0, 2.0, -36.0))
	for i in 120:
		await ticks(1)
	check(p.global_position.y > 4.0, "the hero floats up the full lower lock (y %.1f)" % p.global_position.y)
	# Whack the upper lock's wheel: it fills, the lower drains, and the float hauls the gate up.
	var wheels := sl.find_children("*", "WaterWheelCrank", true, false)
	p.respawn_at(Vector3(61.0, 5.5, -50.0))
	await ticks(2)
	(wheels[1] as WaterWheelCrank).receive_player_attack({"id": 901}, null)
	var top := 0.0
	for i in 200:
		await ticks(1)
		p.invuln_left = 9999.0
		top = maxf(top, p.global_position.y)
	check(upper.is_full() and not lower.is_full(), "one spring: the upper fills as the lower drains")
	check(upper.surface() > Dinodew.T2 - 1.0, "the upper lock is brim full (%.1f)" % upper.surface())
	check(lower.surface() < -3.0, "the lower lock is drained (%.1f)" % lower.surface())
	check(top > Dinodew.T2 - 1.6, "the hero rode the rising water up (peak %.1f)" % top)
	check(sl.gate_is_open() and lvl.hatch_gate.collision_layer == 0, "the float hauled the Hatchery gate open")
	# Walk across the drained lock bed through the gate into the Hatchery.
	p.respawn_at(Vector3(68.0, -3.9, -36.0))
	await until_grounded(p)
	await _walk_to(Vector3(52.0, -3.9, -36.0), 240)
	check(p.global_position.x < 56.0, "walked through the open gate into the Hatchery (x %.1f)" % p.global_position.x)
	# Whacking the lower wheel now (from outside) would drop the gate; it waits while you're in.
	(wheels[0] as WaterWheelCrank).receive_player_attack({"id": 902}, null)
	await ticks(150)
	check(sl.gate_is_open(), "the gate stays up while the hero is inside")
	await _done()


func test_the_tar_crater_log_turns_with_the_hero_riding_it() -> void:
	await _load(&"w9_cp_crater")
	var tb := lvl.turn_bridge
	check_eq(tb.index, 0, "the log starts east-west")
	p.respawn_at(Dinodew.TAR + Vector3(-1.8, 0.6, 0.0))
	await until_grounded(p)
	await ticks(10)
	var lever := tb.find_children("*", "WaterWheelCrank", true, false)[0] as WaterWheelCrank
	lever.receive_player_attack({"id": 703}, null)
	var lowest := INF
	for i in 140:
		await ticks(1)
		p.invuln_left = 9999.0
		lowest = minf(lowest, p.global_position.y)
	check_eq(tb.index, 1, "the wheel swings it north-south")
	check(lowest > Dinodew.T2 - 0.3, "the hero rode it round without falling in (lowest %.1f)" % lowest)
	var to_hero := p.global_position - Dinodew.TAR
	check(absf(to_hero.x) < 1.2 and absf(to_hero.z) > 1.0, "carried round a quarter turn (offset %s)" % str(to_hero.snapped(Vector3.ONE * 0.1)))
	# Now it reaches the north nook: walk over and pick up Grandpa's spectacles.
	await _walk_to(Dinodew.TAR + Vector3(0.0, 0.0, -Dinodew.TAR_HALF - 6.0), 300)
	await _walk_to(Dinodew.TAR + Vector3(-2.0, 0.0, -Dinodew.TAR_HALF - 9.0), 120)
	await ticks(10)
	check(Progress.has_flag(&"w9_found_spectacles"), "the log leads to the spectacles in the pterosaur's nest")
	# Back in the village, Grandpa Gingko trades them for a Star Shard.
	for n in lvl.find_children("*", "Npc", true, false):
		if (n as Npc).npc_id == "gingko":
			(n as Npc).interact(p)
	await ticks(2)
	check(Progress.has_shard(&"w9_shard_errand"), "Grandpa Gingko's errand pays a Star Shard")
	await _done()


func test_rex_crest_follows_his_body_and_only_hops_you() -> void:
	await _load(&"w9_cp_gate")
	for sid in Progress.world_def(&"world_09").shard_ids:
		Progress.collect_shard(sid)
	p.respawn_at(lvl.arena_center + Vector3(0.0, 0.05, -6.0))
	await ticks(3)
	var rex := lvl.boss as ChompoRex
	check(lvl.fight_started, "walking in wakes Chomposaurus Rex")
	var far := 0.0
	for i in 400:
		await ticks(1)
		p.invuln_left = 9999.0
		var weak := (rex.get("_weak_area") as Area3D).global_position
		far = maxf(far, weak.distance_to(rex.crest_position()))
	check(far < 0.05, "the weak spot sits on the crest as he moves (max gap %.2f)" % far)
	rex.open_weak_spot()
	rex.set_state(ChompoRex.S.WINDED)
	await ticks(30)
	var crest := rex.crest_position()
	var hp := rex.hp
	p.respawn_at(crest + Vector3(0.0, 3.0, 0.0))
	p.invuln_left = 9999.0
	await ticks(2)
	inp.tap(&"plunge")
	var peak := -INF
	for i in 90:
		await ticks(1)
		p.invuln_left = 9999.0
		peak = maxf(peak, p.global_position.y)
	check_eq(rex.hp, hp - 1, "a Plunge onto the glowing crest hurts him")
	check(peak < crest.y + 6.0, "and the hop off is small (peak %.1f m, crest at %.1f m)" % [peak, crest.y])
	await _done()


## What you stand on is what you see: every moss strip on Mossback and Trundle lies on the skin
## drawn under it (nothing pokes through, no gap you could see daylight through), at rest and
## while Trundle walks.
func test_dino_carpets_lie_on_their_skin() -> void:
	await _load(&"w9_cp_lake")
	lvl.mossback.state = HungryLongneck.S.EATING
	lvl.mossback.set("_t", 7.4)
	await ticks(30)
	check(lvl.mossback.is_resting(), "Mossback resting")
	for round_i in 3:
		for d: Dino in [lvl.mossback.dino, lvl.trundle]:
			var skin := d.skin_points()
			var world := PackedVector3Array()
			for q in skin:
				world.append(d.global_transform * q)
			var strips := 0
			for piece in d.pieces():
				if not (piece.name.begins_with("Ride_Tail") or piece.name.begins_with("Ride_Back") or piece.name.begins_with("Ride_Neck") or piece.name.begins_with("Ride_Shoulders") or piece.name.begins_with("Ride_Hips") or (piece.name.begins_with("Ride_Torso") and d == lvl.mossback.dino)):
					continue
				strips += 1
				var size := ((piece.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
				var inv := piece.global_transform.affine_inverse()
				var poke := -INF
				var gap := INF
				for q in world:
					var l := inv * q
					if absf(l.z) > size.z * 0.4 or absf(l.x) > size.x * 0.4:
						continue
					poke = maxf(poke, l.y + size.y * 0.5)
					if absf(l.x) < 0.5:
						gap = minf(gap, -size.y * 0.5 - l.y)
				check(poke < 0.12, "%s %s: no skin pokes through (%.2f m)" % [d.species, piece.name, poke])
				check(gap < 0.75, "%s %s: it lies on the skin (gap %.2f m)" % [d.species, piece.name, gap])
			check(strips >= 4, "%s has moss strips (%d)" % [d.species, strips])
		await ticks(53)
	await _done()


## The Hatchery's shard is a climb inside, once the float has the gate up.
func test_hatchery_climb_reaches_the_shard() -> void:
	await _load(&"w9_cp_locks")
	lvl.locks.fill(1)
	for i in 160:
		await ticks(1)
	check(lvl.locks.gate_is_open(), "gate open")
	var room := Transform3D(Basis(Vector3.UP, PI * 0.5), Dinodew.HATCH)
	p.respawn_at(room * Vector3(0.0, 0.4, 5.0))
	await until_grounded(p)
	for spot: Vector3 in [Vector3(-4.5, 1.2, -3.0), Vector3(-1.0, 3.2, -4.0), Vector3(3.0, 5.0, -2.5), Vector3(5.0, 7.0, 1.5)]:
		await _walk_to(room * Vector3(spot.x, 0.0, spot.z), 30, 2.6)
		await _jump_to(room * spot, 2, 120)
	await ticks(20)
	check(Progress.has_shard(&"w9_shard_hatchery"), "the Hatchery shard is collected (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


## Regression: StaticMerge used to free a merged mesh together with the collision it carried
## (giant mushroom caps, tree trunks), so the capstool seed's cap was air.
func test_mushroom_caps_stay_solid_after_merging() -> void:
	await _load(&"w9_cp_fernfloor")
	var q := PhysicsRayQueryParameters3D.create(Vector3(30.0, 14.0, -8.0), Vector3(30.0, 0.5, -8.0), Layers.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	check(not hit.is_empty() and (hit["position"] as Vector3).y > 9.0, "the giant mushroom cap under the seed is solid (%s)" % str(hit.get("position", "none")))
	await _done()


## Regression: a coconut monkey with no encounter zone never ticked its own attack director, so its
## second throw waited forever (watchdog error). The one on the Fern Floor's caps keeps throwing.
func test_cap_monkey_keeps_throwing() -> void:
	await _load(&"w9_cp_fernfloor")
	var monkey := lvl.find_children("*", "BonkMonkey", true, false)[0] as BonkMonkey
	p.respawn_at(monkey.global_position + Vector3(6.0, -monkey.global_position.y + 0.05, 6.0))
	var throws := 0
	var last: Coconut = null
	for i in 600:
		await ticks(1)
		p.invuln_left = 9999.0
		if monkey.last_coconut != null and monkey.last_coconut != last:
			last = monkey.last_coconut
			throws += 1
	check(throws >= 3, "it keeps throwing coconuts (%d)" % throws)
	check_eq(monkey.watchdog_trips, 0, "no watchdog trips")
	await _done()


## The hidden lava tube behind Ember Cone: crack the rock, ride the steam up, climb to the shard.
func test_lava_tube_is_hidden_behind_a_crack_with_a_steam_climb() -> void:
	await _load(&"w9_cp_crater")
	var room := Transform3D(Basis(), Vector3(Dinodew.VOLCANO.x, Dinodew.T2, -144.0))
	var wall: BreakableWall = null
	for n in lvl.find_children("*", "BreakableWall", true, false):
		if (n as Node3D).global_position.distance_to(room * Vector3(0.0, 0.0, 6.0)) < 1.0:
			wall = n as BreakableWall
	check(wall != null, "a cracked rock seals the lava tube")
	p.respawn_at(room * Vector3(0.0, 0.1, 9.0))
	await until_grounded(p)
	await _walk_to(room * Vector3(0.0, 0.0, 6.2), 60, 0.4)
	check(p.global_position.z > room.origin.z + 6.4, "the crack blocks the way in")
	for k in 3:
		wall.receive_player_attack({"id": 800 + k, "kind": &"slash_1", "damage": 1}, null)
	await ticks(10)
	await _walk_to(room * Vector3(-0.5, 0.0, -1.0), 120, 0.5)
	check(p.global_position.z < room.origin.z + 4.0, "three whacks open it (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	# Jump into the steam, ride it up, and drift onto the first high ledge.
	await _walk_to(room * Vector3(-0.5, 0.0, -2.0), 60, 0.3)
	await ticks(20)
	inp.tap(&"jump")
	var ledge := room * Vector3(3.5, 7.0, -3.5)
	var column := room * Vector3(-0.5, 0.0, -2.0)
	for i in 200:
		await ticks(1)
		var target := ledge if p.global_position.y > ledge.y + 0.8 else column
		var d := target - p.global_position
		d.y = 0.0
		if d.length() > 0.3:
			var local := Basis(Vector3.UP, -p.camera_yaw) * d.normalized()
			inp.move = Vector2(local.x, -local.z) * (1.0 if target == ledge else 0.4)
		else:
			inp.move = Vector2.ZERO
		if i > 30 and p.is_on_floor():
			break
	inp.move = Vector2.ZERO
	check(p.global_position.y > ledge.y - 0.3, "the steam lifts the hero to the first ledge (y %.1f)" % p.global_position.y)
	for spot: Vector3 in [Vector3(4.0, 9.6, 1.0), Vector3(0.0, 12.0, 3.0), Vector3(-4.0, 14.4, 0.0)]:
		await _jump_to(room * spot, 2, 120)
	await ticks(20)
	check(Progress.has_shard(&"w9_shard_lavatube"), "the climb ends at the lava tube shard (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


## The Mighty Roar (this world's prize) has a route here too: a roar from the haystack wakes
## Snoozer without ringing his gong.
func test_a_mighty_roar_wakes_snoozer() -> void:
	await _load(&"w9_cp_village")
	var s := lvl.snoozer
	p.abilities_override = [&"roar"]
	p.respawn_at(s.to_global(Vector3(0.0, SleepyDino.BALE_TOP + 0.1, -9.0)))
	await until_grounded(p)
	inp.tap(&"ability_9")
	for i in 30:
		await ticks(1)
	check(s.state == SleepyDino.S.WAKING or s.is_awake(), "the roar reaches his gong and he gets up")
	await _done()


## The Skyfern: shelf fungi spiral up the trunk to the crown shard, no Vinelash needed.
func test_skyfern_shelves_climb_to_the_crown() -> void:
	await _load(&"w9_cp_crater")
	var c := Dinodew.SKYFERN
	p.respawn_at(c + Vector3(13.0, 0.1, 0.0))
	await until_grounded(p)
	var mover: MovingPlatform = null
	for n in lvl.find_children("*", "MovingPlatform", true, false):
		if (n as Node3D).global_position.distance_to(c + Vector3(Dinodew.SKYFERN_SHELF, 15.0, 0.0)) < 3.0:
			mover = n as MovingPlatform
	for i in 6:
		var a := i * PI * 0.5
		var r := Dinodew.SKYFERN_LAST_SHELF if i == 5 else Dinodew.SKYFERN_SHELF
		var spot := c + Vector3(cos(a) * (r + 1.0), 3.0 * (i + 1), sin(a) * (r + 1.0))
		if i == 4 and mover != null:
			spot = mover.global_position + Vector3(1.0, 0.3, 0.0)
		await _jump_to(spot, 3 if i == 5 else 2, 150)
		await _walk_to(spot, 30, 0.5)
	await _jump_to(c + Vector3(2.4, 21.0, 0.0), 2, 120)
	await _walk_to(c + Vector3(2.4, 21.0, 0.0), 40, 0.5)
	await ticks(20)
	check(Progress.has_shard(&"w9_shard_crown"), "the shelves lead to the Skyfern's crown shard (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


## Ember Cone is a walk: ramps wind up round every tier to the crater rim and the summit seed.
func test_ember_cone_ramps_walk_to_the_summit() -> void:
	await _load(&"w9_cp_crater")
	var radii: Array[float] = [26.0, 21.0, 16.5, 12.5, 8.5]
	var v := Dinodew.VOLCANO
	var first := true
	for i in range(-1, radii.size() - 1):
		var top := 3.0 * (i + 1)
		var lane := radii[i + 1] + Dinodew.VOLCANO_LANE
		var a0 := i * PI * 0.5 + 0.4
		var da := 9.4 / lane
		var a := v + Vector3(cos(a0), 0.0, sin(a0)) * lane + Vector3(0.0, top, 0.0)
		var b := v + Vector3(cos(a0 + da), 0.0, sin(a0 + da)) * lane + Vector3(0.0, top + 3.0, 0.0)
		if first:
			p.respawn_at(a + (a - b).normalized() * 2.0 + Vector3.UP * 0.2)
			await until_grounded(p)
			first = false
		await _walk_to(a, 200, 0.6)
		await _walk_to(b, 200, 0.6)
		await ticks(15)
		# Step in off the ramp's top onto the tier.
		var inward := (v - b) * Vector3(1.0, 0.0, 1.0)
		await _walk_to(b + inward.normalized() * 3.0, 60, 0.5)
		check(p.global_position.y > v.y + top + 2.6, "ramp %d climbs onto tier %d (y %.1f)" % [i, i + 1, p.global_position.y])
	await _jump_to(v + Vector3(5.4, 16.6, 0.0), 1, 90)
	await ticks(20)
	check(Progress.has_seed(&"w9_seed_summit"), "the summit seed sits on the crater rim (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()


## The log starts east-west: from the west landing it runs straight to the east nook's seed.
func test_the_log_from_the_west_reaches_the_east_nook_seed() -> void:
	await _load(&"w9_cp_crater")
	var t := Dinodew.TAR
	p.respawn_at(t + Vector3(-Dinodew.TAR_HALF - 3.0, 0.1, 0.0))
	await until_grounded(p)
	# Round the wheel post in the middle of the log.
	for wp: Vector3 in [Vector3(-3.0, 0.0, 1.1), Vector3(3.0, 0.0, 1.1), Vector3(Dinodew.TAR_HALF + 10.0, 0.0, 0.0)]:
		await _walk_to(t + wp, 300, 0.5)
	await ticks(20)
	check(Progress.has_seed(&"w9_seed_tar_nook"), "walked the log across the tar to the east nook seed (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	check(p.global_position.y > Dinodew.T2 - 0.3, "and never fell in")
	await _done()


## The Roost's last treehouse: up its ladder, then shelf fungi round the trunk to the crow's nest.
func test_roost_ladder_and_fungus_steps_reach_the_crows_nest() -> void:
	await _load(&"w9_cp_roost")
	var h := Vector3(-96.0, Dinodew.T2, -62.0)
	p.respawn_at(h + Vector3(0.0, 0.1, 7.5))
	await until_grounded(p)
	await _walk_to(h + Vector3(0.0, 0.0, 5.5), 120, 0.3)
	inp.move = Vector2(0.0, 1.0)
	for i in 240:
		await ticks(1)
		if p.global_position.y > h.y + 9.0 and p.is_on_floor():
			break
	inp.move = Vector2.ZERO
	await _walk_to(h + Vector3(2.5, 0.0, 3.0), 60, 0.5)
	check(p.global_position.y > h.y + 8.8, "climbed the ladder onto the treehouse deck (y %.1f)" % p.global_position.y)
	for spot: Vector3 in [Vector3(3.4, 11.4, 0.0), Vector3(0.0, 13.8, 3.4), Vector3(-3.4, 16.2, 0.0)]:
		await _jump_to(h + spot, 2, 120)
		await _walk_to(h + spot, 20, 0.5)
	await ticks(20)
	check(Progress.has_seed(&"w9_seed_roost_top"), "the crow's nest seed (hero at %s)" % str(p.global_position.snapped(Vector3.ONE * 0.1)))
	await _done()
