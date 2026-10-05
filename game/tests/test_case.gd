class_name TestCase
extends Node3D
## Base for tests. Sim tests run the real movement loop in a physics scene (never a mocked
## floor flag). Use `await ticks(n)` to advance physics ticks.

var failures: Array[String] = []
var current_test: String = ""


func before_each() -> void:
	pass


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("%s: %s" % [current_test, msg])


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s: %s (got %s, expected %s)" % [current_test, msg, str(a), str(b)])


func check_near(a: float, b: float, eps: float, msg: String) -> void:
	if absf(a - b) > eps:
		failures.append("%s: %s (got %.4f, expected %.4f ± %.4f)" % [current_test, msg, a, b, eps])


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# --- Scene helpers ---------------------------------------------------------------------------

func floor_block(top_center: Vector3, size: Vector3) -> StaticBody3D:
	return Kit.block(self, top_center, size, &"grass_mid", Layers.WORLD)


func spawn_player(pos: Vector3, with_resolver: bool = true) -> Player:
	var p := Player.new()
	p.use_dev_settings = false
	p.settings = (preload("res://data/movement/hero_movement.tres") as MovementSettings).duplicate() as MovementSettings
	p.input_source = ScriptedInput.new()
	p.position = pos
	add_child(p)
	if with_resolver:
		var r := CombatResolver.new()
		add_child(r)
		r.player = p
	return p


func input_of(p: Player) -> ScriptedInput:
	return p.input_source as ScriptedInput


## Advance until the player is grounded (max n ticks). Returns ticks waited or -1.
func until_grounded(p: Player, n: int = 300) -> int:
	for i in n:
		await get_tree().physics_frame
		if p.is_on_floor():
			return i
	return -1
