class_name BellSequence
extends Node
## Ring the bells (any CrystalSwitch) in the order shown on a sign (Build 6 world puzzles). A wrong
## bell resets them all with a buzz; the right order emits `solved` once.

signal solved

var bells: Array[CrystalSwitch] = []
var order: Array[int] = []
var done: bool = false
var _next: int = 0


func add(b: CrystalSwitch) -> void:
	var idx := bells.size()
	bells.append(b)
	b.lit_changed.connect(func(on: bool) -> void:
		if on:
			_rang(idx))


func _rang(idx: int) -> void:
	if done:
		return
	if order[_next] == idx:
		_next += 1
		AudioDirector.play(&"checkpoint", -4.0, 1.0 + _next * 0.12)
		if _next >= order.size():
			done = true
			AudioDirector.play(&"seed")
			solved.emit()
		return
	_next = 0
	AudioDirector.play(&"hit", -2.0, 0.5)
	for b in bells:
		b.call_deferred(&"set_lit", false)
