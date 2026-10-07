class_name FlipBlocks
extends Node3D
## World 8, platforms set in sequence (second form): sun blocks and moon blocks. Bonk a flip
## brick and the two sets swap: the gold sun steps fade to ghosts while the blue moon steps turn
## solid, and back again. Climb by flipping at the right moments. The flip bricks show the set
## that is solid now.

signal flipped(sun: bool)

var sun: bool = true
var _sun: Array[GhostPlatform] = []
var _moon: Array[GhostPlatform] = []
var _switches: Array[BonkBrick] = []


## A step whose top centre is `top` (world), solid while its set is.
func add_step(top: Vector3, size: Vector3, is_sun: bool) -> GhostPlatform:
	var g := GhostPlatform.new()
	g.size = size
	g.color_name = &"gold" if is_sun else &"roof_blue"
	g.solid = is_sun == sun
	add_child(g)
	g.global_position = top
	(_sun if is_sun else _moon).append(g)
	return g


func add_switch(top: Vector3) -> BonkBrick:
	var b := BonkBrick.new()
	b.kind = BonkBrick.Kind.SWITCH
	b.size = Vector3(2.6, 2.2, 2.6)
	b.color_name = &"gold" if sun else &"roof_blue"
	add_child(b)
	b.global_position = top
	b.bonked.connect(flip)
	_switches.append(b)
	return b


func flip() -> void:
	sun = not sun
	for g in _sun:
		g.set_solid(sun)
	for g in _moon:
		g.set_solid(not sun)
	for b in _switches:
		b.set_color(&"gold" if sun else &"roof_blue")
	AudioDirector.play(&"ui_blip", -2.0, 1.4 if sun else 0.8)
	flipped.emit(sun)
