class_name SwitchGroup
extends Node
## Calls `on_solved` once every switch in the group is lit at the same time (Build 4 puzzles).

signal solved

var switches: Array[CrystalSwitch] = []
var done: bool = false


func add(s: CrystalSwitch) -> void:
	switches.append(s)
	s.lit_changed.connect(func(_on: bool) -> void: _check())


func _check() -> void:
	if done:
		return
	for s in switches:
		if not s.lit:
			return
	done = true
	for s in switches:
		s.hold = 0.0
	AudioDirector.play(&"seed")
	solved.emit()
