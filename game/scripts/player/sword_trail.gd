class_name SwordTrail
extends MeshInstance3D
## Ribbon trail sampled from the blade's base and tip each frame (plan §9.3 SwordTrail).

const MAX_SAMPLES := 14
const LIFETIME := 0.16

var blade: Node3D
var base_local: Vector3 = Vector3(0.0, 0.3, 0.0)
var tip_local: Vector3 = Vector3(0.0, 1.4, 0.0)
var emitting: bool = false
var color: Color = Color(1.0, 1.0, 1.0, 0.8)
var _samples: Array[Array] = []
var _imm: ImmediateMesh


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_imm = ImmediateMesh.new()
	mesh = _imm
	material_override = Fx.fx_mat(Color.WHITE)
	global_transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	for s in _samples:
		s[2] = float(s[2]) + delta
	while not _samples.is_empty() and float(_samples[0][2]) > LIFETIME:
		_samples.pop_front()
	if emitting and blade != null and is_instance_valid(blade) and blade.is_visible_in_tree():
		var xf := blade.global_transform
		_samples.append([xf * base_local, xf * tip_local, 0.0])
		if _samples.size() > MAX_SAMPLES:
			_samples.pop_front()
	_imm.clear_surfaces()
	if _samples.size() < 2:
		return
	_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for s in _samples:
		var a := clampf(1.0 - float(s[2]) / LIFETIME, 0.0, 1.0)
		_imm.surface_set_color(Color(color, color.a * a * 0.6))
		_imm.surface_add_vertex(s[0] as Vector3)
		_imm.surface_set_color(Color(color, color.a * a))
		_imm.surface_add_vertex(s[1] as Vector3)
	_imm.surface_end()
