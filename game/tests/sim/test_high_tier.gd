extends TestCase
## Build 6 upper tiers: the pieces every world uses to get up there are walks, not jumps. The
## hero walks the whole spiral ramp tower and a sloped bridge on the real controller.

var p: Player
var inp: ScriptedInput


func before_each() -> void:
	floor_block(Vector3(0.0, 0.0, 0.0), Vector3(80.0, 2.0, 80.0))


## Walk toward `to` (flat) for up to n ticks.
func _walk_to(to: Vector3, n: int = 200) -> void:
	for i in n:
		var d := to - p.global_position
		d.y = 0.0
		if d.length() < 0.8:
			break
		d = d.normalized()
		inp.move = Vector2(d.x, -d.z)
		await ticks(1)
	inp.move = Vector2.ZERO


func test_ramp_tower_is_a_walk_to_the_top() -> void:
	await _climb_tower(0.0)


## Towers that start on a plateau (Mesa Town's Sun Tower starts at 12 m).
func test_ramp_tower_on_a_plateau() -> void:
	floor_block(Vector3(0.0, 12.0, 0.0), Vector3(40.0, 12.0, 40.0))
	await _climb_tower(12.0)


func _climb_tower(base: float) -> void:
	var c := Vector3(0.0, base, 0.0)
	HighTier.ramp_tower(self, c, base, base + 16.0)
	p = spawn_player(Vector3(-6.0, base + 0.4, 6.0))
	inp = input_of(p)
	await ticks(10)
	var h := 4.0 + 2.0
	var corners: Array[Vector3] = [Vector3(-h, 0.0, h), Vector3(h, 0.0, h), Vector3(h, 0.0, -h), Vector3(-h, 0.0, -h)]
	var n := int(ceil(16.0 / (8.0 * tan(deg_to_rad(20.0)))))
	for k in range(1, n + 1):
		await _walk_to(c + corners[k % 4])
	check(p.global_position.y > base + 15.5, "walked up to the top landing")
	await _walk_to(c + (corners[n % 4] + corners[(n + 1) % 4]) * 0.5)
	await _walk_to(c)
	await ticks(10)
	check(p.global_position.y > base + 15.5 and p.is_on_floor(), "and onto the tower's flat top")


func test_sloped_bridge_walks_up() -> void:
	Kit.block(self, Vector3(0.0, 0.0, -20.0), Vector3(8.0, 1.0, 8.0), &"stone_light")
	Kit.block(self, Vector3(0.0, 6.0, -42.0), Vector3(8.0, 1.0, 8.0), &"stone_light")
	HighTier.bridge(self, Vector3(0.0, 0.0, -24.0), Vector3(0.0, 6.0, -38.0))
	p = spawn_player(Vector3(0.0, 0.1, -18.0))
	inp = input_of(p)
	await ticks(10)
	await _walk_to(Vector3(0.0, 0.0, -42.0), 240)
	check(p.global_position.y > 5.5, "walked up the bridge onto the high deck (y %.1f)" % p.global_position.y)
