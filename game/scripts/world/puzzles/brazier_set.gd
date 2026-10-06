class_name BrazierSet
extends Node3D
## Build 7 puzzle: light every brazier with a Fireball (or a Frost Burst puts one out, so mind
## your aim) and `solved` fires once. Unlit braziers smoke as the hint.

signal solved

var done: bool = false
var _braziers: Array[Brazier] = []


func add(at: Vector3) -> Brazier:
	var b := Brazier.new()
	b.position = at
	add_child(b)
	_braziers.append(b)
	b.lit_changed.connect(func(_on: bool) -> void: _check())
	return b


func _check() -> void:
	if done:
		return
	for b in _braziers:
		if not b.lit:
			return
	done = true
	AudioDirector.play(&"seed")
	solved.emit()
