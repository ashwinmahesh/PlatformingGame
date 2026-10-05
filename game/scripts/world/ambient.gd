class_name Ambient
extends RefCounted
## Life for the worlds (Build 4: "denser and more alive"): thick grass and flowers as swaying
## MultiMeshes, plus butterflies, birds, fireflies and drifting motes.

const GRASS_SHADER := preload("res://shaders/toon_grass.gdshader")
const FLOWERS: Array[String] = ["flower_redA", "flower_yellowA", "flower_purpleA", "flower_redB", "flower_yellowB"]

static var _meshes: Dictionary[String, Mesh] = {}


static func clear_cache() -> void:
	_meshes.clear()


## The first mesh in a Kenney model, smooth-shaded, with each surface given a swaying toon material.
static func _plant_mesh(model: String, colors: Array[StringName]) -> Mesh:
	var key := model + str(colors)
	if _meshes.has(key):
		return _meshes[key]
	var scene := (load("res://assets/models/kenney_nature/%s.glb" % model) as PackedScene).instantiate()
	var src := (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var mesh := RoundMesh.smoothed(src).duplicate() as ArrayMesh
	for s in mesh.get_surface_count():
		var src_mat := src.surface_get_material(s)
		var name := src_mat.resource_name if src_mat != null else ""
		var col: StringName = colors[mini(s, colors.size() - 1)]
		if name == "grass":
			col = &"grass_mid"
		elif Toon.KENNEY_PALETTE_MAP.has(name) and name != "grass":
			col = Toon.KENNEY_PALETTE_MAP[name]
		var m := ShaderMaterial.new()
		m.shader = GRASS_SHADER
		m.set_shader_parameter(&"albedo_color", Palette.color(col))
		mesh.surface_set_material(s, m)
	scene.free()
	_meshes[key] = mesh
	return mesh


static func _multimesh(parent: Node, mesh: Mesh, points: Array[Transform3D]) -> void:
	if points.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, points[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


static func grass(parent: Node, points: Array[Transform3D], color: StringName = &"grass_light") -> void:
	var a: Array[Transform3D] = []
	var b: Array[Transform3D] = []
	for i in points.size():
		(a if i % 2 == 0 else b).append(points[i])
	_multimesh(parent, _plant_mesh("grass_large", [color]), a)
	_multimesh(parent, _plant_mesh("grass", [color]), b)


static func flowers(parent: Node, points: Array[Transform3D]) -> void:
	var groups: Array[Array] = [[], [], [], [], []]
	for i in points.size():
		groups[i % FLOWERS.size()].append(points[i])
	for g in FLOWERS.size():
		var typed: Array[Transform3D] = []
		typed.assign(groups[g])
		_multimesh(parent, _plant_mesh(FLOWERS[g], [&"grass_mid"]), typed)


static func butterflies(parent: Node, center: Vector3, radius: float, count: int) -> void:
	for i in count:
		var b := Butterfly.new()
		b.center = center
		b.radius = radius
		b.seed_value = i * 7 + int(center.x * 13.0)
		parent.add_child(b)


static func birds(parent: Node, center: Vector3, radius: float, height: float, count: int) -> void:
	for i in count:
		var b := Bird.new()
		b.center = center + Vector3.UP * height
		b.radius = radius * (0.7 + 0.1 * i)
		b.speed = 0.25 + 0.04 * i
		b.phase = float(i) / count * TAU
		parent.add_child(b)


static func fireflies(parent: Node, center: Vector3, radius: float, count: int) -> void:
	var p := CPUParticles3D.new()
	p.amount = count
	p.lifetime = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.gravity = Vector3(0.0, 0.15, 0.0)
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.6
	p.spread = 180.0
	var dot := SphereMesh.new()
	dot.radius = 0.06
	dot.height = 0.12
	p.mesh = dot
	p.material_override = Fx.fx_mat(Color(1.0, 0.95, 0.55))
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(0.7, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	p.position = center + Vector3.UP * 1.5
	parent.add_child(p)


static func motes(parent: Node, center: Vector3, size: Vector3, color: Color = Color(1.0, 1.0, 0.9, 0.7)) -> void:
	var p := CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 8.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = size * 0.5
	p.gravity = Vector3(0.3, 0.05, 0.1)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	p.spread = 180.0
	var dot := SphereMesh.new()
	dot.radius = 0.04
	dot.height = 0.08
	p.mesh = dot
	p.material_override = Fx.fx_mat(color)
	p.position = center
	parent.add_child(p)


## A fluttering butterfly on a wandering loop.
class Butterfly:
	extends Node3D
	var center: Vector3
	var radius: float = 8.0
	var seed_value: int = 0
	var _t: float = 0.0
	var _wings: Array[Node3D] = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		_t = rng.randf() * 100.0
		var col: StringName = [&"gold", &"portal_magenta", &"cloth_cream", &"roof_blue", &"gloop_pink"][seed_value % 5]
		for side: float in [-1.0, 1.0]:
			var w := Node3D.new()
			add_child(w)
			var q := QuadMesh.new()
			q.size = Vector2(0.28, 0.22)
			var m := Kit.mesh_instance(w, q, Fx.fx_mat(Palette.color(col)), Vector3(0.15 * side, 0.0, 0.0))
			m.rotation.x = -PI * 0.5
			_wings.append(w)

	func _process(delta: float) -> void:
		_t += delta
		var a := _t * 0.35 + seed_value
		position = center + Vector3(cos(a) * radius * (0.6 + 0.4 * sin(a * 0.7)), 1.2 + sin(_t * 1.7) * 0.6, sin(a * 1.3) * radius * 0.8)
		var flap := sin(_t * 22.0) * 1.1
		_wings[0].rotation.z = flap
		_wings[1].rotation.z = -flap
		rotation.y = -a


## A bird circling high overhead.
class Bird:
	extends Node3D
	var center: Vector3
	var radius: float = 30.0
	var speed: float = 0.3
	var phase: float = 0.0
	var _t: float = 0.0
	var _wings: Array[Node3D] = []

	func _ready() -> void:
		var body := SphereMesh.new()
		body.radius = 0.35
		body.height = 0.9
		var b := Kit.mesh_instance(self, body, Kit.mat(&"cloth_cream", 0.03))
		b.rotation.x = PI * 0.5
		for side: float in [-1.0, 1.0]:
			var w := Node3D.new()
			add_child(w)
			var wing := BoxMesh.new()
			wing.size = Vector3(1.3, 0.06, 0.45)
			Kit.mesh_instance(w, wing, Kit.mat(&"foam", 0.02), Vector3(0.65 * side, 0.0, 0.0))
			_wings.append(w)

	func _process(delta: float) -> void:
		_t += delta
		var a := phase + _t * speed
		position = center + Vector3(cos(a) * radius, sin(_t * 0.7 + phase) * 2.0, sin(a) * radius)
		look_at(center + Vector3(cos(a + 0.1) * radius, position.y - center.y, sin(a + 0.1) * radius) + Vector3(0.0, center.y, 0.0) * 0.0, Vector3.UP)
		var flap := sin(_t * 6.0) * 0.6
		_wings[0].rotation.z = flap
		_wings[1].rotation.z = -flap
