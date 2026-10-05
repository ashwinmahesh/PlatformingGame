class_name HeartsDisplay
extends Control
## Heart row: full, half and empty hearts drawn as shapes (no textures needed).

const SIZE := 52.0
const GAP := 10.0

var hp: int = 6
var max_hp: int = 6
var _pulse: float = 0.0


func set_hp(h: int, m: int) -> void:
	if h < hp:
		_pulse = 1.0
	hp = h
	max_hp = m
	custom_minimum_size = Vector2((SIZE + GAP) * ceili(m / 2.0), SIZE)
	queue_redraw()


func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 3.0, 0.0)
		queue_redraw()


func _heart_points(center: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var t := float(i) / 40.0 * TAU
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(center + Vector2(x, y) * s / 34.0)
	return pts


func _draw() -> void:
	var hearts := ceili(max_hp / 2.0)
	for i in hearts:
		var c := Vector2(i * (SIZE + GAP) + SIZE * 0.5, SIZE * 0.5)
		var scale_k := 1.0 + (_pulse * 0.25 if i == hp / 2 else 0.0)
		var outline := _heart_points(c, SIZE * 1.12 * scale_k)
		draw_colored_polygon(outline, Palette.INK)
		var inner := _heart_points(c, SIZE * scale_k)
		draw_colored_polygon(inner, Palette.color(&"stone_dark"))
		var filled := clampi(hp - i * 2, 0, 2)
		if filled == 2:
			draw_colored_polygon(inner, Palette.color(&"roof_red"))
		elif filled == 1:
			var half := PackedVector2Array()
			for p in inner:
				half.append(Vector2(minf(p.x, c.x), p.y))
			draw_colored_polygon(half, Palette.color(&"roof_red"))
