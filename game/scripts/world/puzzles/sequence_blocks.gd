class_name SequenceBlocks
extends Node3D
## World 8 puzzle, "platforms set in sequence": the Counting Blocks. Toy blocks carry dice pips
## (one to five) and float about a courtyard in a jumble. Bonk them from below (or land on them)
## in counting order: each right one glows and chimes a step higher, a wrong one buzzes and they
## all forget. Count all the way up and `solved` fires, and the blocks fly into a staircase
## (`stair`, world positions of each block's top, in counting order).

signal solved
signal counted(n: int)

var done: bool = false
var blocks: Array[PipBlock] = []
var stair: Array[Vector3] = []
var _next: int = 1


func add_block(at: Vector3, number: int, color_name: StringName) -> PipBlock:
	var b := PipBlock.new()
	b.number = number
	b.color_name = color_name
	b.position = at
	add_child(b)
	blocks.append(b)
	b.touched.connect(_on_touched)
	return b


func _on_touched(b: PipBlock) -> void:
	if done or b.lit:
		return
	if b.number == _next:
		b.set_lit(true)
		AudioDirector.play(&"checkpoint", -4.0, 0.9 + _next * 0.12)
		Fx.burst(self, b.global_position + Vector3.UP * 0.4, Palette.color(&"gold"), 10, 3.0, 0.08, -2.0, 0.5)
		counted.emit(_next)
		_next += 1
		if _next > blocks.size():
			done = true
			AudioDirector.play(&"seed")
			solved.emit()
			raise()
		return
	_next = 1
	AudioDirector.play(&"hit", -2.0, 0.5)
	b.wrong()
	for o in blocks:
		o.set_lit(false)
	counted.emit(0)


## Every block glides to its stair spot, one after another.
func raise() -> void:
	for b in blocks:
		var i := b.number - 1
		if i >= stair.size():
			continue
		b.set_lit(true)
		var t := b.create_tween()
		t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		t.tween_interval(0.25 * i)
		t.tween_property(b, "global_position", stair[i], 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(func() -> void: AudioDirector.play(&"ui_blip", -4.0, 1.0 + i * 0.1))


## Puts the blocks straight onto the stair (a save that already solved it, or tests).
func settle() -> void:
	done = true
	for b in blocks:
		var i := b.number - 1
		b.set_lit(true)
		if i < stair.size():
			b.global_position = stair[i]
