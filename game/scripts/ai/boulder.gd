class_name Boulder
extends Node3D
## A thrown boulder (Rumble Golem): a red ring marks where it lands. Slash it during your active
## frames to send it back; it hits the thrower and knocks it down, opening its weak spot.

const RETURN_TIME := 0.5

var thrower: Node3D
var radius: float = 0.8
var reflected: bool = false
var _from: Vector3
var _to: Vector3
var _flight: float = 1.1
var _t: float = 0.0
var _arc: float = 6.0
var _ring: MeshInstance3D
var _done: bool = false


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	var mi := Kit.mesh_instance(self, s, Kit.mat(&"stone_dark", 0.04))
	mi.mesh = RoundMesh.smoothed(s)
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var sh := SphereShape3D.new()
	sh.radius = radius * 1.8
	Kit.add_shape(a, sh)
	add_child(a)


func launch(from: Vector3, to: Vector3, flight: float, arc: float = 6.0) -> void:
	_from = from
	_to = to
	_flight = flight
	_arc = arc
	global_position = from
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 1.4
	tm.outer_radius = radius * 1.7
	_ring.mesh = tm
	_ring.material_override = Fx.fx_mat(Color(Palette.color(&"roof_red"), 0.85))
	_ring.top_level = true
	_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_ring)
	_ring.global_position = to + Vector3.UP * 0.08
	_ring.scale = Vector3(1.0, 0.25, 1.0)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	rotation += Vector3(delta * 5.0, delta * 3.0, 0.0)
	if reflected:
		var target := thrower.global_position + Vector3.UP * 3.0 if is_instance_valid(thrower) else _to
		var k := clampf(_t / RETURN_TIME, 0.0, 1.0)
		global_position = _from.lerp(target, k) + Vector3.UP * sin(k * PI) * 2.0
		if k >= 1.0:
			if is_instance_valid(thrower) and thrower.has_method(&"hit_by_boulder"):
				thrower.call(&"hit_by_boulder")
			_break()
		return
	var k := clampf(_t / _flight, 0.0, 1.0)
	global_position = _from.lerp(_to, k) + Vector3.UP * (_arc * 4.0 * k * (1.0 - k))
	if k >= 1.0:
		_break()


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if reflected or _done or StringName(str(atk.get("kind", ""))) == &"plunge":
		return {}
	reflected = true
	_from = global_position
	_t = 0.0
	if _ring != null:
		_ring.queue_free()
		_ring = null
	AudioDirector.play(&"hit", 0.0, 0.8)
	Fx.burst(get_parent(), global_position, Palette.color(&"gold"), 10, 3.0, 0.1)
	return {"hit": true}


func damage_to_player(p: Player) -> Dictionary:
	if reflected or _done:
		return {}
	var d := p.global_position + Vector3.UP * 0.6 - global_position
	if d.length() > radius + 0.6:
		return {}
	_break.call_deferred()
	return {"halves": 2, "from": global_position, "heavy": true, "cause": "boulder"}


func _break() -> void:
	if _done:
		return
	_done = true
	AudioDirector.play(&"coconut_break", -2.0, 0.7)
	if is_inside_tree():
		Fx.burst(get_parent(), global_position, Palette.color(&"stone_light"), 14, 4.0, 0.18)
	queue_free()
