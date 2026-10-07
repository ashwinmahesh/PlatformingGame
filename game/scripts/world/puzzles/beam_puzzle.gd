class_name BeamPuzzle
extends Node3D
## Build 7 puzzle: a light beam from a sun lens bounces off mirrors to a target crystal. Hit a
## mirror (sword, Fireball...) to flip it between "/" and "\". Everything sits on one flat
## level; the beam runs along the X/Z axes. `solved` fires the first time the target is lit.

signal solved

const HEIGHT := 1.4
var source_dir: Vector3 = Vector3.RIGHT
var target: Vector3 = Vector3.ZERO
var done: bool = false
var mirrors: Array[BeamMirror] = []
## How far the beam runs when it hits nothing.
var max_length: float = 60.0
var _segments: Node3D
var _target_mesh: MeshInstance3D


func _ready() -> void:
	var lens := SphereMesh.new()
	lens.radius = 0.5
	lens.height = 1.0
	Kit.pillar(self, Vector3(0.0, HEIGHT - 0.4, 0.0), 0.45, HEIGHT - 0.4, &"stone_dark", &"")
	var lm := Kit.unique_mat(&"gold")
	lm.set_shader_parameter(&"flash", 1.0)
	lm.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	Kit.mesh_instance(self, lens, lm, Vector3(0.0, HEIGHT, 0.0))
	var t := PrismMesh.new()
	t.size = Vector3(0.9, 1.4, 0.9)
	_target_mesh = Kit.mesh_instance(self, t, Kit.unique_mat(&"portal_teal", 0.04), target + Vector3(0.0, HEIGHT, 0.0))
	Kit.pillar(self, target + Vector3(0.0, HEIGHT - 0.7, 0.0), 0.4, HEIGHT - 0.7, &"stone_dark", &"")
	_segments = Node3D.new()
	add_child(_segments)
	trace.call_deferred()


## A mirror at `at` (local to the puzzle), starting as "/" (slash = true) or "\".
func add_mirror(at: Vector3, slash: bool) -> BeamMirror:
	var m := BeamMirror.new()
	m.position = at
	m.slash = slash
	add_child(m)
	mirrors.append(m)
	m.flipped.connect(trace)
	return m


## Follow the beam and redraw it; light the target if the beam reaches it.
func trace() -> void:
	for c in _segments.get_children():
		c.queue_free()
	var p := Vector3.ZERO
	var d := source_dir
	var hit_target := false
	for bounce in 12:
		var best := max_length
		var best_m: BeamMirror = null
		var t_along := (target - p).dot(d)
		var t_off := (target - p - d * t_along)
		t_off.y = 0.0
		var target_t := t_along if t_along > 0.3 and t_off.length() < 0.6 else INF
		for m in mirrors:
			var along := (m.position - p).dot(d)
			var off := m.position - p - d * along
			off.y = 0.0
			if along > 0.3 and off.length() < 0.6 and along < best:
				best = along
				best_m = m
		if target_t < best:
			_segment(p, p + d * target_t)
			hit_target = true
			break
		_segment(p, p + d * best)
		if best_m == null:
			break
		p = best_m.position
		# Reflect off the pane: "/" (turned +45 degrees) sends (x, z) to (-z, -x); "\" to (z, x).
		d = Vector3(-d.z, 0.0, -d.x) if best_m.slash else Vector3(d.z, 0.0, d.x)
	var m := _target_mesh.material_override as ShaderMaterial
	m.set_shader_parameter(&"flash", 0.8 if hit_target else 0.0)
	m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	if hit_target and not done:
		done = true
		AudioDirector.play(&"seed")
		solved.emit()


func _segment(a: Vector3, b: Vector3) -> void:
	var len := a.distance_to(b)
	if len < 0.05:
		return
	var holder := Node3D.new()
	_segments.add_child(holder)
	holder.position = (a + b) * 0.5 + Vector3.UP * HEIGHT
	holder.basis = Basis.looking_at((b - a).normalized(), Vector3.UP)
	var c := BoxMesh.new()
	c.size = Vector3(0.14, 0.14, len)
	var mi := Kit.mesh_instance(holder, c, Fx.fx_mat(Color(Palette.color(&"gold") * 1.4, 0.8)))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
