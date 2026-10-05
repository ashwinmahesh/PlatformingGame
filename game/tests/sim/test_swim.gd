extends TestCase
## Swimming (Build 3): water is swimmable, not an instant loss.

var p: Player
var inp: ScriptedInput
const SURFACE := 0.0


func before_each() -> void:
	# A pool 6 m deep with a bank 1 m above the water on one side.
	floor_block(Vector3(0.0, -6.0, 0.0), Vector3(30.0, 2.0, 30.0))
	floor_block(Vector3(0.0, 1.0, -16.0), Vector3(30.0, 10.0, 6.0))
	Kit.water(self, Vector3(0.0, SURFACE, 0.0), Vector2(30.0, 26.0), 6.0)
	p = spawn_player(Vector3(0.0, 3.0, 0.0))
	inp = input_of(p)
	await ticks(2)


func test_falling_in_starts_swimming_and_floats() -> void:
	var hp := p.hp
	for i in 120:
		await ticks(1)
	check(p.is_swimming(), "swimming after falling in")
	check_eq(p.hp, hp, "no damage for falling in water")
	check_near(p.global_position.y, SURFACE - 1.05, 0.25, "floating with the head above water")
	check(not p.head_underwater(), "head above the surface")


func test_hop_out_onto_the_bank() -> void:
	await ticks(120)
	inp.move = Vector2(0.0, 1.0)
	await ticks(180)
	check(p.global_position.z < -11.5, "swam up to the bank")
	inp.tap(&"jump")
	var landed := false
	for i in 90:
		await ticks(1)
		if p.is_on_floor() and p.global_position.y > 0.9 and not p.is_swimming():
			landed = true
			break
	check(landed, "hopped out and landed on the bank 1 m above the water")


func test_dive_uses_breath_then_hurts() -> void:
	await ticks(120)
	inp.press(&"plunge")
	await ticks(90)
	check(p.head_underwater(), "dived under")
	check(p.breath < Player.BREATH_MAX, "breath goes down underwater")
	var hp := p.hp
	await ticks(int(Player.BREATH_MAX * 60.0) + 120)
	check(p.hp < hp, "out of air costs hearts")
	inp.release(&"plunge")
	await ticks(240)
	check(not p.head_underwater(), "floats back up when Shift is released")
	check(p.breath > 1.0, "breath refills at the surface")
