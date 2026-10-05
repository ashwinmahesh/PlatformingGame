class_name BreathDisplay
extends Control
## Air bubbles under the hearts while swimming underwater (Build 3).

const BUBBLES := 8
const SIZE := 26.0

var fraction: float = 1.0
var shown: bool = false


func set_breath(f: float, show_it: bool) -> void:
	if absf(f - fraction) > 0.001 or show_it != shown:
		fraction = f
		shown = show_it
		queue_redraw()


func _draw() -> void:
	if not shown:
		return
	var full := fraction * BUBBLES
	for i in BUBBLES:
		var c := Vector2(i * (SIZE + 6.0) + SIZE * 0.5, SIZE * 0.5)
		var k := clampf(full - i, 0.0, 1.0)
		draw_circle(c, SIZE * 0.5 + 2.0, Palette.INK)
		draw_circle(c, SIZE * 0.5, Palette.color(&"water_deep"))
		if k > 0.0:
			draw_circle(c, SIZE * 0.5 * k, Palette.color(&"water_light"))
			draw_circle(c + Vector2(-4, -4), SIZE * 0.12 * k, Palette.color(&"foam"))
