class_name TurnBridge
extends Node3D
## Build 7 puzzle: a long bridge on a pivot. Hit its lever and it swings a quarter turn, linking a
## different pair of islands. `angle` steps through `stops` (radians).

var length: float = 20.0
var width: float = 3.4
var stops: Array[float] = [0.0, PI * 0.5]
var index: int = 0
var _deck: AnimatableBody3D


func _ready() -> void:
	Kit.pillar(self, Vector3(0.0, -0.3, 0.0), 1.6, 3.0, &"stone_dark", &"gold")
	_deck = AnimatableBody3D.new()
	_deck.collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	add_child(_deck)
	var b := BoxShape3D.new()
	b.size = Vector3(width, 0.5, length)
	Kit.add_shape(_deck, b, Vector3(0.0, -0.25, 0.0))
	Kit.mesh_instance(_deck, RoundMesh.box(b.size, 0.15), Kit.mat(&"wood_plank", 0.03), Vector3(0.0, -0.25, 0.0))
	for side: float in [-1.0, 1.0]:
		Kit.mesh_instance(_deck, RoundMesh.box(Vector3(0.2, 0.7, length), 0.05), Kit.mat(&"candy_pink"), Vector3(side * (width * 0.5 - 0.1), 0.35, 0.0))
	_deck.rotation.y = stops[index]


## The lever that turns it (put it on any island the bridge serves).
func add_lever(at: Vector3) -> void:
	var sw := WaterWheelCrank.new()
	sw.position = at
	add_child(sw)
	sw.turned.connect(func() -> void:
		index = (index + 1) % stops.size()
		create_tween().tween_property(_deck, "rotation:y", stops[index], 1.6).set_trans(Tween.TRANS_SINE)
		AudioDirector.play(&"gate", -2.0, 0.8))
