class_name Showcase
extends OpenWorld
## Dev-only look board (Build 5): every Whimsy set piece on one lawn, for captures while tuning
## the art style. Not reachable from the game.


func build() -> void:
	scene_id = &"showcase"
	default_spawn = &"start"
	floor_y = -6.0
	_rng.seed = 5
	disc(Vector3.ZERO, 40.0, &"bark_mid", &"grass_mid")
	add_spawn(&"start", Vector3(0.0, 0.0, 20.0))
	var kinds: Array[StringName] = [&"green", &"lime", &"teal", &"blossom", &"autumn", &"violet", &"gold"]
	for i in kinds.size():
		Whimsy.tree(self, Vector3(-18.0 + i * 6.0, 0.0, -14.0), kinds[i], 1.0, i % 4)
		Whimsy.pine(self, Vector3(-18.0 + i * 6.0, 0.0, -24.0), kinds[i])
	var mk: Array[StringName] = [&"red", &"purple", &"teal", &"orange", &"pink", &"blue", &"gold"]
	for i in mk.size():
		Whimsy.mushroom(self, Vector3(-24.0 + i * 8.0, 0.0, 2.0), 3.0 + i * 1.0, 2.5 + i * 0.5, mk[i])
	Whimsy.flower(self, Vector3(14.0, 0.0, 14.0), 3.0, 2.0, &"candy_pink")
	Whimsy.flower(self, Vector3(20.0, 0.0, 10.0), 4.0, 2.5, &"gold")
	Whimsy.flower(self, Vector3(8.0, 0.0, 12.0), 2.0, 1.5, &"slime_blue")
	Whimsy.crystal(self, Vector3(-14.0, 0.0, 14.0), &"crystal_violet")
	Whimsy.crystal(self, Vector3(-20.0, 0.0, 12.0), &"portal_teal", 1.3)
	Whimsy.crystal(self, Vector3(-8.0, 0.0, 16.0), &"candy_pink", 0.8)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		Whimsy.hill(self, Vector3(cos(a) * 90.0, floor_y, sin(a) * 90.0), _rng.randf_range(30.0, 45.0))
	for i in 10:
		var a := float(i) / 10.0 * TAU + 0.2
		Whimsy.mountain(self, Vector3(cos(a) * 240.0, floor_y - 10.0, sin(a) * 240.0), _rng.randf_range(50.0, 80.0), _rng.randf_range(70.0, 120.0), i % 3 != 0)
	Whimsy.rainbow(self, Vector3(0.0, -4.0, -120.0), 70.0)
	finish_life()
	butterflies(Vector3.ZERO, 20.0, 10)
	add_capture_point("board", Vector3(0.0, 9.0, 32.0), Vector3(0.0, 3.0, -6.0))
	add_capture_point("mushrooms", Vector3(-4.0, 6.0, 16.0), Vector3(-4.0, 5.0, 0.0))
	add_capture_point("trees", Vector3(-2.0, 5.0, 2.0), Vector3(-2.0, 4.0, -18.0))
	add_capture_point("wide", Vector3(30.0, 18.0, 50.0), Vector3(0.0, 0.0, -20.0))
