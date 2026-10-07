class_name BloomPad
extends Node3D
## Build 7 (World 7) "alien plants that react": a closed glowing bud. Hit it and it unfurls into a
## broad petal platform for `open_time` seconds, then curls shut again (shake as a warning).

## A closed bud: petals folded up tall and thin, glowing softly so you can spot it.
const CLOSED := Vector3(0.32, 2.8, 0.32)

var open_time: float = 8.0
var radius: float = 2.4
## How far its stem reaches down (to the ground or the water below).
var stalk: float = 3.0
var color_name: StringName = &"candy_pink"
var is_open: bool = false
var _left: float = 0.0
var _petals: Node3D
var _mats: Array[ShaderMaterial] = []
var _t: float = 0.0
var _shape: CollisionShape3D
var _last_id: int = -1


func _ready() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	add_child(body)
	_shape = CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = 0.5
	_shape.shape = c
	_shape.position.y = -0.25
	_shape.disabled = true
	body.add_child(_shape)
	Kit.pillar(self, Vector3(0.0, -0.3, 0.0), 0.25, maxf(stalk - 0.3, 0.5), &"leaf_teal", &"", 0)
	_petals = Node3D.new()
	add_child(_petals)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var holder := Node3D.new()
		holder.rotation.y = a
		_petals.add_child(holder)
		var petal := SphereMesh.new()
		petal.radius = radius * 0.55
		petal.height = 0.35
		var m := Kit.unique_mat(color_name if i % 2 == 0 else &"crystal_violet", 0.03)
		m.set_shader_parameter(&"flash_color", Palette.color(color_name))
		_mats.append(m)
		var mi := Kit.mesh_instance(holder, petal, m, Vector3(radius * 0.5, 0.0, 0.0))
		mi.scale = Vector3(1.0, 1.0, 0.7)
	_petals.scale = CLOSED
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 1.8
	Kit.add_shape(a, s, Vector3(0.0, 0.2, 0.0))
	add_child(a)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	_left = open_time
	if not is_open:
		is_open = true
		_shape.disabled = false
		create_tween().tween_property(_petals, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		AudioDirector.play(&"springcap", -6.0, 1.4)
	return {"hit": true}


func _physics_process(delta: float) -> void:
	_t += delta
	var glow := 0.0 if is_open else 0.25 + 0.2 * sin(_t * 3.0)
	for m in _mats:
		m.set_shader_parameter(&"flash", glow)
	if not is_open:
		return
	_left -= delta
	if _left < 1.5:
		_petals.rotation.y = sin(_left * 30.0) * 0.08
	if _left <= 0.0:
		is_open = false
		_shape.disabled = true
		_petals.rotation.y = 0.0
		create_tween().tween_property(_petals, "scale", CLOSED, 0.4)
