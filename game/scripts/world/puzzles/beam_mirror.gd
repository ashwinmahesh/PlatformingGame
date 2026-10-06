class_name BeamMirror
extends Node3D
## A mirror on a post for BeamPuzzle; any hit flips it between "/" and "\".

signal flipped

var slash: bool = true
var _pane: Node3D
var _last_id: int = -1


func _ready() -> void:
	Kit.pillar(self, Vector3(0.0, 0.8, 0.0), 0.25, 0.8, &"bark_dark", &"")
	_pane = Node3D.new()
	_pane.position.y = BeamPuzzle.HEIGHT
	add_child(_pane)
	Kit.mesh_instance(_pane, RoundMesh.box(Vector3(1.4, 1.2, 0.12), 0.05), Kit.mat(&"water_light", 0.03))
	_pane.rotation.y = PI * 0.25 if slash else -PI * 0.25
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 0.9
	Kit.add_shape(a, s, Vector3(0.0, BeamPuzzle.HEIGHT, 0.0))
	add_child(a)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	flip()
	return {"hit": true}


func flip() -> void:
	slash = not slash
	create_tween().tween_property(_pane, "rotation:y", PI * 0.25 if slash else -PI * 0.25, 0.2)
	AudioDirector.play(&"ui_blip", -4.0, 1.4)
	flipped.emit()
