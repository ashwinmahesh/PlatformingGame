class_name ColourCrystalHit
extends Area3D
## The hit area of one ColourLock crystal.

var on_hit: Callable
var _last_id: int = -1


func _ready() -> void:
	collision_layer = Layers.REFLECTABLE
	monitoring = false
	set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 0.9
	Kit.add_shape(self, s, Vector3(0.0, 1.35, 0.0))


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	on_hit.call()
	return {"hit": true}
