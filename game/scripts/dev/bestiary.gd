class_name Bestiary
extends OpenWorld
## Dev-only line-up of the Build 6 enemy roster, for captures. Not reachable from the game.


func build() -> void:
	scene_id = &"bestiary"
	default_spawn = &"start"
	floor_y = -6.0
	_rng.seed = 6
	disc(Vector3.ZERO, 40.0, &"bark_mid", &"grass_mid", 0)
	add_spawn(&"start", Vector3(0.0, 0.0, 38.0))
	big_gloplet(Vector3(-15.0, 0.5, 0.0))
	place(Puffcap.new(), Vector3(-10.0, 0.5, 0.0))
	batling(Vector3(-6.0, 2.5, 0.0))
	batling(Vector3(-3.0, 2.5, 0.0), false, true)
	critter(Armorling, Vector3(1.0, 0.5, 0.0))
	critter(Mimic, Vector3(5.0, 0.5, 0.0))
	critter(Pricklepot, Vector3(9.0, 0.5, 0.0))
	boulderkin(Vector3(16.0, 0.5, -1.0))
	# Build 7's six.
	critter(Wispghost, Vector3(-15.0, 1.0, 8.0))
	critter(Wyrmling, Vector3(-9.0, 2.5, 8.0))
	critter(Buzzbee, Vector3(-3.0, 2.0, 8.0))
	critter(Whirlwisp, Vector3(3.0, 0.3, 8.0))
	critter(Hopfrog, Vector3(9.0, 0.05, 8.0))
	critter(Hexwizard, Vector3(15.0, 0.05, 8.0))
	for i in 8:
		var a := float(i) / 8.0 * TAU
		Whimsy.hill(self, Vector3(cos(a) * 90.0, floor_y, sin(a) * 90.0), _rng.randf_range(30.0, 45.0))
	add_capture_point("roster", Vector3(0.0, 4.5, -16.0), Vector3(0.0, 1.8, 0.0))
	add_capture_point("roster_two", Vector3(0.0, 4.5, -8.0), Vector3(0.0, 1.8, 8.0))
	add_capture_point("boulderkin_back", Vector3(10.0, 5.0, 8.0), Vector3(16.0, 2.5, -1.0))
