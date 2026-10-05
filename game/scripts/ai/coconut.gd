class_name Coconut
extends Node3D
## A lobbed coconut (plan §8.4): a ring appears where it will land as soon as it's thrown; it
## deals ½ heart, breaks on impact and leaves nothing behind. Slashing it during your active
## frames sends it homing back to the monkey that threw it.

const RADIUS := 0.32
const RETURN_TIME := 0.45

var thrower: BonkMonkey
var reflected: bool = false
var _from: Vector3
var _to: Vector3
var _flight: float = 0.9
var _t: float = 0.0
var _arc: float = 4.0
var _ring: MeshInstance3D
var _reflect_area: Area3D
var _spin: float = 0.0
var _done: bool = false


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	var nut := SphereMesh.new()
	nut.radius = RADIUS
	nut.height = RADIUS * 2.0
	nut.radial_segments = 10
	nut.rings = 6
	Kit.mesh_instance(self, nut, Kit.mat(&"bark_mid", 0.03))
	# Reflectable collider (layer 13): only the sword detects it.
	_reflect_area = Area3D.new()
	_reflect_area.collision_layer = Layers.REFLECTABLE
	_reflect_area.collision_mask = 0
	_reflect_area.monitoring = false
	_reflect_area.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = RADIUS * 2.0
	Kit.add_shape(_reflect_area, s)
	add_child(_reflect_area)
	get_tree().create_timer(4.0).timeout.connect(_break)


func launch(from: Vector3, to: Vector3, flight: float) -> void:
	_from = from
	_to = to
	_flight = flight
	_t = 0.0
	global_position = from
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.75
	tm.outer_radius = 0.95
	tm.rings = 24
	tm.ring_segments = 4
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
	_spin += delta * 12.0
	rotation = Vector3(_spin, _spin * 0.6, 0.0)
	if reflected:
		var target := thrower.global_position + Vector3.UP * 1.0 if is_instance_valid(thrower) else _to
		var k := clampf(_t / RETURN_TIME, 0.0, 1.0)
		global_position = _from.lerp(target, k) + Vector3.UP * sin(k * PI) * 1.0
		if k >= 1.0:
			if is_instance_valid(thrower):
				thrower.hit_by_coconut()
			_break()
		return
	var k := clampf(_t / _flight, 0.0, 1.0)
	global_position = _from.lerp(_to, k) + Vector3.UP * (_arc * 4.0 * k * (1.0 - k))
	if _ring != null:
		_ring.scale = Vector3.ONE * lerpf(1.0, 0.6, k) * Vector3(1.0, 0.25, 1.0)
	if k >= 1.0:
		_break()


## Sword hit during active frames: switch sides and home back to the thrower.
func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if reflected or _done or StringName(str(atk.get("kind", ""))) == &"plunge":
		return {}
	reflected = true
	_from = global_position
	_t = 0.0
	if _ring != null:
		_ring.queue_free()
		_ring = null
	AudioDirector.play(&"hit", 0.0, 1.3)
	Fx.burst(get_parent(), global_position, Palette.color(&"gold"), 8, 3.0, 0.08)
	return {"hit": true}


func damage_to_player(p: Player) -> Dictionary:
	if reflected or _done:
		return {}
	var d := p.global_position + Vector3.UP * 0.6 - global_position
	if Vector2(d.x, d.z).length() > RADIUS + 0.38 or absf(d.y) > RADIUS + 0.6:
		return {}
	_break.call_deferred()
	return {"halves": 1, "from": global_position, "cause": "coconut"}


func _break() -> void:
	if _done:
		return
	_done = true
	AudioDirector.play(&"coconut_break", -4.0)
	if is_inside_tree():
		Fx.burst(get_parent(), global_position, Palette.color(&"cloth_cream"), 10, 3.5, 0.1)
	queue_free()
