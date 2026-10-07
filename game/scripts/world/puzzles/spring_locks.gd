class_name SpringLocks
extends Node3D
## Build 9 puzzle (Dinodew Jungle, water levels): two locks fed by one spring. Whacking a lock's
## wheel sends the spring into that lock and drains the other, so only one is ever full. A big
## striped float rides the upper lock's water and hauls a gate open while that lock is full.
## Read it from the scene: a spout pours into whichever lock is filling, and the float's rope
## runs down to the gate. Burble the lock-keeper says it in one line.

signal changed(full: int)

var locks: Array[SpringLock] = []
## Which lock holds the spring.
var full: int = 0
## The gate the float pulls, the lock it floats in, and the surface height that opens it.
var gate: VineGate
var float_lock: int = 1
var gate_open_above: float = INF
## The gate won't drop on the hero: while they're inside this box (world) it stays up.
var keep_open_box: AABB = AABB()
var _float: Node3D
## The float's rope runs up to this pulley (world) and on down to the gate.
var rope_anchor: Vector3 = Vector3.INF
var _rope: MeshInstance3D
var _gate_open: bool = false
var _spouts: Array[MeshInstance3D] = []


## Adds a lock (already placed and configured) with its wheel at `wheel_at` (world). The first
## lock added starts full.
func add_lock(lock: SpringLock, wheel_at: Vector3, spout_at: Vector3 = Vector3.INF) -> WaterWheelCrank:
	var i := locks.size()
	locks.append(lock)
	if lock.is_inside_tree():
		lock.set_index(1 if i == full else 0, 0.0)
	else:
		lock.index = 1 if i == full else 0
	var w := WaterWheelCrank.new()
	add_child(w)
	w.global_position = wheel_at
	w.turned.connect(func() -> void: fill(i))
	if spout_at != Vector3.INF:
		var fall := BoxMesh.new()
		fall.size = Vector3(2.6, 6.0, 0.4)
		var wm := ShaderMaterial.new()
		wm.shader = preload("res://shaders/water.gdshader")
		wm.set_shader_parameter(&"vertical", true)
		wm.set_shader_parameter(&"flow", Vector2(0.0, 0.6))
		var mi := Kit.mesh_instance(self, fall, wm)
		mi.global_position = spout_at + Vector3.DOWN * 3.0
		mi.visible = i == full
		_spouts.append(mi)
	return w


## Sends the spring into lock i (the other drains).
func fill(i: int) -> void:
	if i == full or i < 0 or i >= locks.size():
		AudioDirector.play(&"splash", -10.0, 1.4)
		return
	full = i
	for k in locks.size():
		locks[k].set_index(1 if k == i else 0)
	for k in _spouts.size():
		_spouts[k].visible = k == i
	AudioDirector.play(&"splash", -1.0, 0.6)
	changed.emit(i)


## The striped float, chained to `gate`.
func add_float(size: float = 2.4) -> Node3D:
	_float = Node3D.new()
	add_child(_float)
	var log := CylinderMesh.new()
	log.top_radius = size * 0.5
	log.bottom_radius = size * 0.5
	log.height = size * 2.2
	var body := Kit.mesh_instance(_float, log, Kit.mat(&"roof_red", 0.03))
	body.rotation.z = PI * 0.5
	for x: float in [-size * 0.6, 0.0, size * 0.6]:
		var band := CylinderMesh.new()
		band.top_radius = size * 0.52
		band.bottom_radius = size * 0.52
		band.height = size * 0.3
		var b := Kit.mesh_instance(_float, band, Kit.mat(&"cloth_cream", 0.02), Vector3(x, 0.0, 0.0))
		b.rotation.z = PI * 0.5
	var ring := TorusMesh.new()
	ring.inner_radius = 0.25
	ring.outer_radius = 0.4
	Kit.mesh_instance(_float, ring, Kit.mat(&"gold", 0.02), Vector3(0.0, size * 0.55, 0.0))
	_rope = Kit.mesh_instance(self, RoundMesh.box(Vector3(0.12, 1.0, 0.12), 0.04), Kit.mat(&"wood_warm"))
	_rope.top_level = true
	_rope.visible = false
	return _float


func float_position() -> Vector3:
	return _float.global_position if _float != null else Vector3.ZERO


func gate_is_open() -> bool:
	return _gate_open


func _physics_process(_delta: float) -> void:
	if locks.is_empty():
		return
	var lock := locks[float_lock]
	if _float != null:
		var p := lock.global_position
		_float.global_position = Vector3(p.x, lock.surface() + 0.4, p.z) + (_float.get_meta(&"offset", Vector3.ZERO) as Vector3)
		_float.rotation.z = sin(Time.get_ticks_msec() * 0.0015) * 0.05
		if rope_anchor != Vector3.INF:
			var from := _float.global_position + Vector3.UP * 1.4
			var span := rope_anchor - from
			_rope.visible = span.length() > 0.2
			if _rope.visible:
				var up := span.normalized()
				var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
				_rope.global_transform = Transform3D(Basis(side, up, side.cross(up)).scaled(Vector3(1.0, span.length(), 1.0)), from + span * 0.5)
	if gate == null:
		return
	var want := lock.surface() >= gate_open_above
	if want == _gate_open:
		return
	if not want:
		var p := get_tree().get_first_node_in_group(&"player") as Player
		if p != null and keep_open_box.has_volume() and keep_open_box.has_point(p.global_position):
			return
	_gate_open = want
	gate.set_closed(not want)
	if want:
		var hud := get_tree().get_first_node_in_group(&"hud") as Hud
		if hud != null:
			hud.show_banner("The float hauls the Hatchery gate open!", 2.2)
