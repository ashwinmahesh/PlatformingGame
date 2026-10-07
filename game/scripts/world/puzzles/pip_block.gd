class_name PipBlock
extends AnimatableBody3D
## One Counting Block for SequenceBlocks (World 8): a chunky toy block with dice pips (1-6) on
## its sides and top. Bonking it from below or landing on top of it reports `touched`. It glows
## gold once counted. `position` is the centre of its top face.

signal touched(block: PipBlock)

var number: int = 1
var size: Vector3 = Vector3(3.0, 2.0, 3.0)
var color_name: StringName = &"candy_pink"
var lit: bool = false
var _on_top: bool = false
var _cool: int = 0
var _mat: ShaderMaterial
var _visual: Node3D


## Dice pip spots for 1-6 on a unit face (-1..1).
static func pip_spots(n: int) -> Array[Vector2]:
	match n:
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(-1.0, -1.0), Vector2(1.0, 1.0)]
		3:
			return [Vector2(-1.0, -1.0), Vector2.ZERO, Vector2(1.0, 1.0)]
		4:
			return [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]
		5:
			return [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2.ZERO, Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]
	return [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]


## The pips of `n` on the four sides and the top of a box of size `s` (its top centre at the
## origin), as one mesh.
static func pip_mesh(s: Vector3, n: int, radius: float = 0.24, top: bool = true) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.08
	disc.radial_segments = 12
	disc.rings = 1
	var spread := minf(minf(s.x, s.y), s.z) * 0.27
	for face in 4:
		var turn := Basis(Vector3.UP, face * PI * 0.5)
		var d := (s.z if face % 2 == 0 else s.x) * 0.5 + 0.02
		for p in pip_spots(n):
			var at := turn * Vector3(p.x * spread, -s.y * 0.5 + p.y * spread, d)
			st.append_from(disc, 0, Transform3D(turn * Basis(Vector3.RIGHT, PI * 0.5), at))
	if top:
		for p in pip_spots(n):
			st.append_from(disc, 0, Transform3D(Basis(), Vector3(p.x * spread, 0.02, p.y * spread)))
	return st.commit()


func _ready() -> void:
	collision_layer = Layers.WORLD | Layers.CAMERA_BLOCKER
	collision_mask = 0
	sync_to_physics = false
	var b := BoxShape3D.new()
	b.size = size
	Kit.add_shape(self, b, Vector3(0.0, -size.y * 0.5, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	_mat = Kit.unique_mat(color_name, 0.03)
	Kit.mesh_instance(_visual, RoundMesh.box(size, 0.3), _mat, Vector3(0.0, -size.y * 0.5, 0.0))
	Kit.mesh_instance(_visual, pip_mesh(size, number), Kit.mat(&"cloth_cream"))


func set_lit(on: bool) -> void:
	lit = on
	_mat.set_shader_parameter(&"flash", 0.7 if on else 0.0)
	_mat.set_shader_parameter(&"flash_color", Palette.color(&"gold"))


## A red blink when it was the wrong one.
func wrong() -> void:
	_mat.set_shader_parameter(&"flash", 0.8)
	_mat.set_shader_parameter(&"flash_color", Palette.color(&"roof_red"))
	var t := create_tween()
	t.tween_interval(0.3)
	t.tween_callback(func() -> void: set_lit(lit))


func _physics_process(_delta: float) -> void:
	if _cool > 0:
		_cool -= 1
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	var to := p.global_position - global_position
	if absf(to.x) > size.x + 1.0 or absf(to.z) > size.z + 1.0 or absf(to.y) > size.y + 3.5:
		_on_top = false
		return
	var below := false
	var on := false
	for i in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		if c.get_collider() != self:
			continue
		if c.get_normal().y < -0.5:
			below = true
		elif c.get_normal().y > 0.7:
			on = true
	if below and _cool <= 0:
		_bump()
		touched.emit(self)
	elif on and not _on_top and _cool <= 0:
		touched.emit(self)
	if on or below:
		_cool = maxi(_cool, 12)
	_on_top = on or (_on_top and p.is_on_floor() and absf(to.y) < 0.3)


func _bump() -> void:
	var t := create_tween()
	t.tween_property(_visual, "position:y", 0.3, 0.08).set_trans(Tween.TRANS_SINE)
	t.tween_property(_visual, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE)
	AudioDirector.play(&"boss_bonk", -6.0, 1.7)
