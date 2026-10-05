extends Level
## World 1, Glimmerbrook Wilds, slice cut (plan §5.3, §13.1): Stump Ring -> Fernway (Springcap
## teaches the Plunge) -> Sunny Clearing (Gloplets, Bouncer) -> River Crossing (stones, drifting
## logs, sinking lily pads) -> Lily Gate -> Gloop Lake (Mother Gloop). The route runs toward -Z.
## Sections 5-7 (Bonk Grove, Waterfall Climb, Ridge Run) are P4 work.

const WORLD := &"world_01"
const GLOPLET := preload("res://data/enemies/gloplet.tres")
const BOUNCER := preload("res://data/enemies/bouncer.tres")
const ARENA_CENTER := Vector3(0.0, 11.0, -163.0)
const ARENA_RADIUS := 15.0
## Section boundaries along -Z for the event log (plan §7.3).
const SECTIONS: Array[Array] = [
	["s1_stump_ring", 10.0], ["s2_fernway", -14.0], ["s3_sunny_clearing", -48.0],
	["s4_river_crossing", -84.0], ["s8_lily_gate", -116.0], ["s9_gloop_lake", -147.5],
]

var boss: MotherGloop
var gate: VineGate
var return_arch: Portal
var fight_started: bool = false
var _section: String = ""
var _victory_running: bool = false


func build() -> void:
	scene_id = WORLD
	default_spawn = &"w1_entrance"
	music = &"glimmerbrook"
	kill_y = -6.0
	Kit.water(self, Vector3(0.0, -1.5, -80.0), Vector2(260.0, 360.0))
	_stump_ring()
	_fernway()
	_sunny_clearing()
	_river()
	_lily_gate()
	_arena()
	_scenery()
	Events.boss_defeated.connect(_on_boss_defeated)


func _sign(pos: Vector3, text: String) -> void:
	var post := CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.08
	post.height = 1.1
	Kit.mesh_instance(self, post, Kit.mat(&"bark_dark"), pos + Vector3(0.0, 0.55, 0.0))
	var board := BoxMesh.new()
	board.size = Vector3(1.2, 0.6, 0.1)
	Kit.mesh_instance(self, board, Kit.mat(&"wood_plank", 0.02), pos + Vector3(0.0, 1.2, 0.0))
	var l := Kit.label(self, pos + Vector3(0.0, 2.2, 0.0), text, 30)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func _checkpoint(id: StringName, pos: Vector3, look: Vector3 = Vector3.FORWARD) -> void:
	var cp := Checkpoint.new()
	cp.checkpoint_id = id
	cp.world_id = WORLD
	cp.position = pos + Vector3(2.5, 0.0, 0.0)
	add_child(cp)
	add_spawn(id, pos, look)


func _seed(id: StringName, pos: Vector3) -> void:
	Pickup.spawn_seed(self, pos, id)


func _heart_bush(pos: Vector3) -> void:
	Kit.blob(self, pos + Vector3(0.0, 0.4, 0.0), 0.8, &"leaf_dark")
	Kit.blob(self, pos + Vector3(0.5, 0.3, 0.3), 0.55, &"grass_mid")
	Pickup.spawn_heart(self, pos + Vector3(0.0, 1.2, 0.0))


# --- Section 1: Stump Ring ---------------------------------------------------------------------

func _stump_ring() -> void:
	Kit.block(self, Vector3(0.0, 0.0, 0.0), Vector3(20.0, 6.0, 20.0), &"bark_mid")
	add_spawn(&"w1_entrance", Vector3(0.0, 0.0, 2.5))
	var exit := Portal.new()
	exit.look = Portal.Look.STUMP_RING
	exit.target_scene = Progress.HUB_SCENE
	exit.target_spawn = &"hub_rootway_exit"
	exit.label_text = "To Mossbrook"
	exit.position = Vector3(0.0, 0.0, 7.5)
	add_child(exit)
	_checkpoint(&"w1_cp_stump", Vector3(-5.0, 0.0, -3.0))
	_sign(Vector3(3.5, 0.0, 0.5), "Jump: Space / A\nPress again in the air: double, then triple jump!")
	# Mushroom steps up to the Fernway (J1 and J2 refresher).
	Kit.pillar(self, Vector3(-2.0, 1.3, -6.5), 1.3, 7.3, &"cloth_cream", &"roof_teal")
	Kit.pillar(self, Vector3(1.0, 2.4, -10.0), 1.3, 8.4, &"cloth_cream", &"roof_teal")
	add_capture_point("s1_overview", Vector3(9.0, 7.0, 12.0), Vector3(0.0, 1.0, -8.0))


# --- Section 2: Fernway ------------------------------------------------------------------------

func _fernway() -> void:
	Kit.block(self, Vector3(0.0, 3.0, -31.0), Vector3(14.0, 9.0, 34.0), &"bark_mid")
	Kit.block(self, Vector3(-8.5, 9.0, -31.0), Vector3(3.0, 15.0, 34.0), &"stone_dark")
	# Mossy logs across the path.
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.45
	log_mesh.bottom_radius = 0.45
	log_mesh.height = 7.0
	var lb := Kit.static_body(self, Vector3(-1.5, 3.45, -19.5))
	lb.rotation.y = PI * 0.5
	var lshape := CylinderShape3D.new()
	lshape.radius = 0.45
	lshape.height = 7.0
	var lcs := Kit.add_shape(lb, lshape)
	lcs.rotation.x = PI * 0.5
	var lmi := Kit.mesh_instance(lb, log_mesh, Kit.mat(&"bark_light", 0.02))
	lmi.rotation.x = PI * 0.5
	# The Gloplet on the path, with a log-beam bypass on the right.
	var zone := EncounterZone.new()
	zone.zone_id = &"w1_fernway"
	zone.radius = 6.0
	zone.bypass_note = "log beam along the right edge"
	zone.position = Vector3(-1.0, 3.0, -30.0)
	zone.add_spawn(Vector3.ZERO, GLOPLET)
	add_child(zone)
	Kit.block(self, Vector3(5.6, 4.0, -30.0), Vector3(1.4, 1.0, 14.0), &"bark_light")
	_sign(Vector3(3.5, 3.0, -16.0), "Attack: Left mouse / J / X\nThree presses for a combo!")
	# Optional shelf mushrooms (J3) to a seed, far from the cliff so they can't skip the Springcap.
	Kit.pillar(self, Vector3(-5.6, 5.2, -24.0), 1.2, 3.0, &"cloth_cream", &"roof_teal")
	Kit.pillar(self, Vector3(-5.6, 7.3, -27.6), 1.1, 5.0, &"cloth_cream", &"roof_teal")
	Kit.pillar(self, Vector3(-5.4, 9.4, -31.2), 1.1, 7.0, &"cloth_cream", &"roof_teal")
	_seed(&"w1_seed_fernway", Vector3(-5.4, 9.4, -31.2))
	# The Springcap: required Plunge lesson up an 8 m cliff.
	var cap := Springcap.new()
	cap.position = Vector3(0.0, 3.0, -45.2)
	add_child(cap)
	_sign(Vector3(-3.2, 3.0, -42.5), "Spotted mushrooms bounce!\nJump, then PLUNGE onto it:\nShift / K / B")
	add_capture_point("s2_springcap", Vector3(6.0, 8.0, -34.0), Vector3(0.0, 5.0, -46.0))


# --- Section 3: Sunny Clearing -----------------------------------------------------------------

func _sunny_clearing() -> void:
	Kit.block(self, Vector3(0.0, 11.0, -66.0), Vector3(30.0, 17.0, 36.0), &"bark_mid")
	_checkpoint(&"w1_cp_clearing", Vector3(0.0, 11.0, -52.5))
	var zone := EncounterZone.new()
	zone.zone_id = &"w1_clearing"
	zone.radius = 10.0
	zone.bypass_note = "right-hand meadow edge"
	zone.position = Vector3(-4.0, 11.0, -67.0)
	zone.add_spawn(Vector3(-3.0, 0.0, 2.0), GLOPLET)
	zone.add_spawn(Vector3(2.5, 0.0, -1.0), GLOPLET)
	zone.add_spawn(Vector3(-1.0, 0.0, -5.0), GLOPLET)
	zone.add_spawn(Vector3(11.0, 0.0, -2.5), BOUNCER)
	add_child(zone)
	# Seed ledge: out of triple-jump reach from the ground; pogo off the blue Bouncer.
	Kit.block(self, Vector3(10.5, 17.8, -74.0), Vector3(3.2, 1.0, 3.2), &"stone_light")
	_seed(&"w1_seed_clearing", Vector3(10.5, 17.8, -74.0))
	_sign(Vector3(4.5, 11.0, -63.0), "Blue slimes go flat after a lunge.\nLand on one to bounce sky-high!")
	_heart_bush(Vector3(-11.0, 11.0, -56.0))
	_heart_bush(Vector3(12.0, 11.0, -81.0))
	add_capture_point("s3_clearing", Vector3(-12.0, 18.0, -50.0), Vector3(0.0, 11.0, -70.0))


# --- Section 4: River Crossing -----------------------------------------------------------------

func _river() -> void:
	Kit.water(self, Vector3(0.0, 10.0, -100.0), Vector2(34.0, 32.0))
	# Riverbed walls so the river reads as a channel.
	Kit.block(self, Vector3(-16.5, 11.0, -100.0), Vector3(3.0, 17.0, 32.0), &"stone_dark")
	Kit.block(self, Vector3(16.5, 11.0, -100.0), Vector3(3.0, 17.0, 32.0), &"stone_dark")
	for spec: Array in [[0.0, -87.4], [1.6, -91.0], [-0.4, -94.6]]:
		Kit.pillar(self, Vector3(spec[0] as float, 10.8, spec[1] as float), 1.05, 6.0, &"stone_light", &"moss")
	for spec: Array in [[-99.0, 0.0], [-103.5, 0.5]]:
		var log_p := MovingPlatform.new()
		log_p.size = Vector3(3.4, 1.4, 1.4)
		log_p.travel = Vector3(5.0, 0.0, 0.0)
		log_p.period = 4.5
		log_p.phase = spec[1] as float
		log_p.position = Vector3(0.0, 10.3, spec[0] as float)
		log_p.rotation.y = PI * 0.5
		add_child(log_p)
	for z: float in [-107.4, -110.8, -114.2]:
		var pad := SinkingPad.new()
		pad.position = Vector3(0.0 if z != -110.8 else -1.2, 10.6, z)
		add_child(pad)
	# Optional seed island off the drifting logs.
	Kit.pillar(self, Vector3(8.5, 11.6, -101.0), 1.1, 4.0, &"stone_light", &"moss")
	_seed(&"w1_seed_river", Vector3(8.5, 11.6, -101.0))
	_sign(Vector3(-4.0, 11.0, -82.5), "Lily pads sink a moment\nafter you land. Keep hopping!")
	add_capture_point("s4_river", Vector3(10.0, 16.0, -82.0), Vector3(0.0, 10.0, -102.0))


# --- Section 8: Lily Gate -----------------------------------------------------------------------

func _lily_gate() -> void:
	Kit.block(self, Vector3(0.0, 11.0, -131.5), Vector3(30.0, 17.0, 31.0), &"bark_mid")
	_checkpoint(&"w1_cp_far_bank", Vector3(0.0, 11.0, -119.0))
	_checkpoint(&"w1_cp_lily_gate", Vector3(0.0, 11.0, -140.0))
	_heart_bush(Vector3(-6.0, 11.0, -132.0))
	_heart_bush(Vector3(6.0, 11.0, -128.0))
	_sign(Vector3(-4.0, 11.0, -143.0), "Mother Gloop's lake ahead.\nHer core opens after each attack!")
	add_capture_point("s8_lily_gate", Vector3(8.0, 15.0, -118.0), Vector3(0.0, 11.0, -146.0))


# --- Section 9: Gloop Lake (boss arena) ---------------------------------------------------------

func _arena() -> void:
	Kit.water(self, Vector3(0.0, 10.0, -165.0), Vector2(60.0, 40.0))
	Kit.pillar(self, ARENA_CENTER, ARENA_RADIUS + 0.5, 17.0, &"bark_mid", &"grass_mid")
	Kit.block(self, Vector3(0.0, 11.0, -146.5), Vector3(7.0, 17.0, 3.0), &"bark_mid")
	var stump_positions: Array[Vector3] = []
	for i in 4:
		var a := PI * 0.25 + i * PI * 0.5
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * 8.0
		Kit.pillar(self, p + Vector3(0.0, 2.5, 0.0), 1.0, 2.5, &"bark_light", &"moss")
		stump_positions.append(p)
	# Bank rocks back up the knockback ledge guard.
	for i in 28:
		var a := float(i) / 28.0 * TAU
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.28:
			continue
		var p := ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * (ARENA_RADIUS + 0.2)
		var rock := Kit.pillar(self, p + Vector3(0.0, 0.9, 0.0), 0.75, 1.5, &"stone_light")
		rock.rotation.y = a
	for i in 6:
		var a := float(i) / 6.0 * TAU + 0.4
		var lily := CylinderMesh.new()
		lily.top_radius = 1.4
		lily.bottom_radius = 1.4
		lily.height = 0.1
		Kit.mesh_instance(self, lily, Kit.mat(&"grass_light"), ARENA_CENTER + Vector3(cos(a) * 22.0, -0.95, sin(a) * 18.0))
	gate = VineGate.new()
	gate.width = 7.0
	gate.position = Vector3(0.0, 11.0, -146.0)
	add_child(gate)
	add_spawn(&"w1_arena_exit", ARENA_CENTER + Vector3(0.0, 0.0, 9.0), Vector3.FORWARD)
	_spawn_boss(stump_positions)
	add_capture_point("s9_arena", ARENA_CENTER + Vector3(14.0, 12.0, 18.0), ARENA_CENTER)


func _spawn_boss(stump_positions: Array[Vector3] = []) -> void:
	if stump_positions.is_empty():
		for i in 4:
			var a := PI * 0.25 + i * PI * 0.5
			stump_positions.append(ARENA_CENTER + Vector3(cos(a), 0.0, sin(a)) * 8.0)
	boss = MotherGloop.new()
	boss.arena_center = ARENA_CENTER
	boss.arena_radius = ARENA_RADIUS
	boss.stumps = stump_positions
	boss.rng.seed = 1234
	boss.position = ARENA_CENTER + Vector3(0.0, 0.0, -4.0)
	add_child(boss)


func _scenery() -> void:
	var i := 0
	for spec: Array in [
		[-9.0, 0.0, 6.0], [9.0, 0.0, -6.0], [-8.5, 0.0, -8.5], [7.5, 0.0, 8.0],
		[6.6, 3.0, -20.0], [6.6, 3.0, -40.0], [-12.5, 11.0, -50.0], [13.0, 11.0, -55.0],
		[-13.0, 11.0, -78.0], [13.5, 11.0, -68.0], [-12.0, 11.0, -122.0], [12.0, 11.0, -136.0],
		[-13.0, 11.0, -144.0], [12.5, 11.0, -118.0],
	]:
		Kit.tree(self, Vector3(spec[0] as float, spec[1] as float, spec[2] as float), 6.0 + float(i % 3), &"leaf_dark" if i % 2 == 0 else &"leaf_teal", i)
		i += 1
	for spec: Array in [[-5.0, 0.0, 6.5], [6.0, 3.0, -27.0], [-9.0, 11.0, -60.0], [9.0, 11.0, -126.0]]:
		Kit.blob(self, Vector3(spec[0] as float, (spec[1] as float) + 0.3, spec[2] as float), 0.7, &"grass_mid")
	# Landmark: the waterfall above Gloop Lake, visible from the very first spot.
	Kit.block(self, Vector3(0.0, 38.0, -192.0), Vector3(40.0, 50.0, 10.0), &"stone_dark")
	var fall := BoxMesh.new()
	fall.size = Vector3(9.0, 30.0, 0.5)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	wm.set_shader_parameter(&"flow", Vector2(0.0, 2.5))
	wm.set_shader_parameter(&"vertical", true)
	Kit.mesh_instance(self, fall, wm, Vector3(0.0, 24.0, -186.6))
	for x: float in [-40.0, 40.0]:
		Kit.block(self, Vector3(x, 22.0, -120.0), Vector3(20.0, 30.0, 160.0), &"leaf_dark", 0)


func after_spawn(spawn_id: StringName) -> void:
	# Continuing from the arena exit after a win: the boss is gone and the return arch is open.
	if spawn_id == &"w1_arena_exit" and Progress.is_world_complete(WORLD):
		if boss != null:
			boss.queue_free()
			boss = null
		_open_return_arch(false)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null:
		return
	var z := player.global_position.z
	var current := ""
	for s in SECTIONS:
		if z <= float(s[1]):
			current = str(s[0])
	if current != _section:
		if _section != "":
			Telemetry.log_event("section_left", {"section": _section})
		_section = current
		Telemetry.log_event("section_entered", {"section": current})
	if not fight_started and boss != null and z < -150.0 and player.global_position.y > 9.0:
		fight_started = true
		gate.set_closed(true)
		boss.start_fight()
		AudioDirector.play_music(&"boss")
	if boss != null and hud != null:
		hud.set_boss(boss.hp, MotherGloop.MAX_HP, fight_started and boss.state != MotherGloop.S.GONE)


## The victory commit happens before any presentation (plan §9.8).
func _on_boss_defeated(world_id: StringName) -> void:
	if world_id != WORLD or _victory_running:
		return
	_victory_running = true
	var first_clear := Progress.commit_victory(WORLD)
	Telemetry.log_event("boss_defeated", {"first_clear": first_clear})
	for m in get_tree().get_nodes_in_group(&"boss_minion"):
		m.queue_free()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	AudioDirector.play_music(&"victory", 0.3)
	hud.show_banner("Mother Gloop popped!", 2.0)
	player.refill()
	await get_tree().create_timer(2.8).timeout
	if not is_inside_tree():
		return
	if first_clear:
		hud.show_banner("New heart!  Glimmer Crest found!", 2.5)
		AudioDirector.play(&"seed")
	gate.set_closed(false)
	_open_return_arch(true)


func _open_return_arch(animate: bool) -> void:
	if return_arch != null:
		return
	return_arch = Portal.new()
	return_arch.target_scene = Progress.HUB_SCENE
	return_arch.target_spawn = &"hub_rootway_exit"
	return_arch.cleared = true
	return_arch.label_text = "Home to Mossbrook"
	return_arch.position = ARENA_CENTER + Vector3(0.0, 0.0, -3.0)
	add_child(return_arch)
	if animate:
		return_arch.scale = Vector3.ONE * 0.05
		create_tween().tween_property(return_arch, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC)
		Fx.burst(self, return_arch.global_position + Vector3.UP, Palette.color(&"portal_teal"), 24, 5.0)


## Dying resets the fight: her HP and scale, minions, goo and rings; you start at the checkpoint.
func on_player_respawned() -> void:
	if boss == null or boss.defeated_count > 0:
		return
	for n in get_children():
		if n is GooPuddle or n is Shockwave or (n is Gloplet and n.is_in_group(&"boss_minion")):
			n.queue_free()
	boss.queue_free()
	_spawn_boss()
	fight_started = false
	gate.set_closed(false)
	AudioDirector.play_music(&"glimmerbrook")
