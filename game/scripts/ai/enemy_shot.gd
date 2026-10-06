class_name EnemyShot
extends Node3D
## Build 6 roster: a small thing a monster fires. Two kinds:
## - SPORE: a Puffcap's spore ball, lobbed in an arc with a ring where it lands; it bursts into
##   a SporeCloud. Slash it in the air to pop it harmlessly.
## - NEEDLE: one of a Pricklepot's fan of needles, flying flat and straight; slash or glide
##   over them.
## - HEX (Build 7): a Hexwizard's slow homing orb; slash it, or outrun it.

enum Kind { SPORE, NEEDLE, HEX }

var kind: Kind = Kind.SPORE
var color_name: StringName = &"portal_magenta"
var _from: Vector3
var _to: Vector3
var _dir: Vector3
var _flight: float = 1.0
var _range: float = 12.0
var _t: float = 0.0
var _arc: float = 4.0
var _ring: MeshInstance3D
var _done: bool = false


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	var mi: MeshInstance3D
	if kind == Kind.SPORE:
		var s := SphereMesh.new()
		s.radius = 0.32
		s.height = 0.64
		mi = Kit.mesh_instance(self, s, Kit.mat(color_name, 0.03))
		for i in 4:
			var dot := SphereMesh.new()
			dot.radius = 0.08
			dot.height = 0.16
			var a := float(i) / 4.0 * TAU
			Kit.mesh_instance(self, dot, Kit.mat(&"cloth_cream"), Vector3(cos(a) * 0.26, 0.12, sin(a) * 0.26))
	elif kind == Kind.HEX:
		var s := SphereMesh.new()
		s.radius = 0.35
		s.height = 0.7
		var hm := Kit.unique_mat(color_name)
		hm.set_shader_parameter(&"flash", 1.0)
		hm.set_shader_parameter(&"flash_color", Palette.color(color_name))
		mi = Kit.mesh_instance(self, s, hm)
	else:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.07
		c.height = 0.6
		mi = Kit.mesh_instance(self, c, Kit.mat(&"cloth_cream", 0.015))
		mi.rotation.x = -PI * 0.5
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	var sh := SphereShape3D.new()
	sh.radius = 0.6
	Kit.add_shape(a, sh)
	add_child(a)


## Lob a spore ball from `from` to land at `to`.
func lob(from: Vector3, to: Vector3, flight: float = 1.0, arc: float = 4.0) -> void:
	kind = Kind.SPORE
	_from = from
	_to = to
	_flight = flight
	_arc = arc
	global_position = from
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.3
	tm.outer_radius = 1.6
	_ring.mesh = tm
	_ring.material_override = Fx.fx_mat(Color(Palette.color(color_name), 0.8))
	_ring.top_level = true
	_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_ring)
	_ring.global_position = to + Vector3.UP * 0.08
	_ring.scale = Vector3(1.0, 0.25, 1.0)


## Fire a needle flat along `dir`.
func shoot(from: Vector3, dir: Vector3, travel: float = 12.0) -> void:
	kind = Kind.NEEDLE
	_from = from
	_dir = dir.normalized()
	_range = travel
	global_position = from
	if _dir.length() > 0.01:
		look_at(from + _dir, Vector3.UP)


## A slow homing hex orb (Hexwizard): it turns gently toward the hero for a few seconds.
func home_in(from: Vector3, dir: Vector3) -> void:
	kind = Kind.HEX
	_from = from
	_dir = dir.normalized()
	global_position = from


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if kind == Kind.HEX:
		var p := get_tree().get_first_node_in_group(&"player") as Node3D
		if p != null:
			var want := (p.global_position + Vector3.UP * 0.8 - global_position).normalized()
			_dir = _dir.slerp(want, minf(delta * 1.6, 1.0)).normalized()
		global_position += _dir * 6.0 * delta
		if _t > 4.0:
			_finish()
		return
	if kind == Kind.SPORE:
		var k := clampf(_t / _flight, 0.0, 1.0)
		global_position = _from.lerp(_to, k) + Vector3.UP * (_arc * 4.0 * k * (1.0 - k))
		rotation.y += delta * 4.0
		if k >= 1.0:
			var cloud := SporeCloud.new()
			cloud.radius = 2.0
			get_parent().add_child(cloud)
			cloud.global_position = _to
			_finish()
	else:
		global_position = _from + _dir * 13.0 * _t
		if 13.0 * _t > _range:
			_finish()


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if _done or StringName(str(atk.get("kind", ""))) == &"plunge":
		return {}
	Fx.burst(get_parent(), global_position, Palette.color(color_name), 8, 3.0, 0.08)
	AudioDirector.play(&"hit", -6.0, 1.6)
	_finish()
	return {"hit": true}


func damage_to_player(p: Player) -> Dictionary:
	if _done:
		return {}
	var d := p.global_position + Vector3.UP * 0.6 - global_position
	if d.length() > 0.75:
		return {}
	_finish.call_deferred()
	return {"halves": 1, "from": global_position - (_dir if kind != Kind.SPORE else Vector3.ZERO), "cause": ["spore_ball", "needle", "hex_orb"][kind]}


func _finish() -> void:
	if _done:
		return
	_done = true
	queue_free()
