class_name Fx
extends RefCounted
## One-shot effects: dust puffs, sparkle rings, hit sparks, goo splats, confetti (plan §10.4).

const FX_SHADER := preload("res://shaders/fx.gdshader")


static func fx_mat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FX_SHADER
	m.set_shader_parameter(&"tint", c)
	return m


static func burst(parent: Node, pos: Vector3, c: Color, amount: int = 12, speed: float = 3.0, size: float = 0.12, gravity: float = -6.0, lifetime: float = 0.5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0.0, gravity, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	p.material_override = fx_mat(c)
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func ring(parent: Node, pos: Vector3, c: Color, radius: float = 1.2, duration: float = 0.35) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	tm.rings = 16
	tm.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := fx_mat(c)
	mi.material_override = m
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.2
	var t := mi.create_tween().set_parallel(true)
	t.tween_property(mi, "scale", Vector3(radius, radius * 0.5, radius), duration).set_ease(Tween.EASE_OUT)
	t.tween_method(func(a: float) -> void: m.set_shader_parameter(&"tint", Color(c, a)), 1.0, 0.0, duration)
	t.chain().tween_callback(mi.queue_free)


static func confetti(parent: Node, pos: Vector3) -> void:
	for cname: StringName in [&"gloop_pink", &"gold", &"portal_teal", &"slime_green", &"cloth_cream"]:
		burst(parent, pos, Palette.color(cname), 18, 9.0, 0.16, -9.0, 1.4)
