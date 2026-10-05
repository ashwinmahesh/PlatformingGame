class_name TownTest
extends OpenWorld
## Dev-only: a few Lanternwick townhouses for checking the kit pieces' orientation in captures.


func build() -> void:
	scene_id = &"town_test"
	default_spawn = &"start"
	floor_y = -6.0
	disc(Vector3.ZERO, 40.0, &"stone_light", &"stone_light", 0)
	add_spawn(&"start", Vector3(0.0, 0.0, 30.0))
	var batch := ModuleBatch.new()
	TownHouse.build(self, batch, Vector3(-12.0, 0.0, 0.0), 0.0, 3, 2, 3, &"pitched", 0)
	TownHouse.build(self, batch, Vector3(2.0, 0.0, 0.0), 0.0, 2, 3, 2, &"flat", 1)
	TownHouse.build(self, batch, Vector3(16.0, 0.0, 0.0), PI * 0.5, 2, 2, 4, &"pitched", 2)
	batch.build(self)
	add_capture_point("front", Vector3(0.0, 8.0, 26.0), Vector3(0.0, 6.0, 0.0))
	add_capture_point("back", Vector3(-6.0, 12.0, -24.0), Vector3(0.0, 6.0, 0.0))
