class_name HitboxDebug
extends MeshInstance3D
## F2 view of every hitbox and hurtbox as wireframes (Build 2: "hit boxes are off"). Enemy
## hurtboxes are orange, bounce surfaces teal, reflectables gold, the hero's hurtbox blue and the
## sword / Plunge hitboxes white while they're active.

var _imm: ImmediateMesh


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_imm = ImmediateMesh.new()
	mesh = _imm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = true
	material_override = m


func _process(_delta: float) -> void:
	_imm.clear_surfaces()
	if not DevTools.ai_debug:
		return
	_imm.surface_begin(Mesh.PRIMITIVE_LINES)
	for n in get_tree().root.find_children("*", "Area3D", true, false):
		var a := n as Area3D
		if not a.has_meta(&"actor") or not a.monitorable or not a.is_visible_in_tree():
			continue
		var c := Color.ORANGE
		if a.collision_layer & Layers.BOUNCE and not a.collision_layer & Layers.ENEMY_HURTBOX:
			c = Color.AQUAMARINE
		elif a.collision_layer & Layers.REFLECTABLE:
			c = Color.GOLD
		for cs in a.get_children():
			if cs is CollisionShape3D:
				_shape((cs as CollisionShape3D).shape, (cs as CollisionShape3D).global_transform, c)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p != null:
		_shape(p.hurt_shape, p.hurtbox.global_transform.translated_local(Vector3(0.0, 0.6, 0.0)), Color.DODGER_BLUE)
		if p.is_sword_active():
			_shape(p.sword_shape, p.sword_transform(), Color.WHITE)
		if p.is_plunge_active():
			_shape(p.plunge_shape, p.plunge_transform(), Color.WHITE)
	_imm.surface_end()


func _shape(s: Shape3D, xf: Transform3D, c: Color) -> void:
	if s is SphereShape3D:
		var r := (s as SphereShape3D).radius
		_ellipse(xf, Vector3.RIGHT * r, Vector3.UP * r, c)
		_ellipse(xf, Vector3.RIGHT * r, Vector3.BACK * r, c)
		_ellipse(xf, Vector3.UP * r, Vector3.BACK * r, c)
	elif s is CylinderShape3D:
		var cy := s as CylinderShape3D
		for y: float in [-cy.height * 0.5, cy.height * 0.5]:
			_ellipse(xf.translated_local(Vector3(0.0, y, 0.0)), Vector3.RIGHT * cy.radius, Vector3.BACK * cy.radius, c)
		for a in 4:
			var d := Vector3(cos(a * PI * 0.5), 0.0, sin(a * PI * 0.5)) * cy.radius
			_line(xf * (d + Vector3.DOWN * cy.height * 0.5), xf * (d + Vector3.UP * cy.height * 0.5), c)
	elif s is CapsuleShape3D:
		var cp := s as CapsuleShape3D
		var half := cp.height * 0.5 - cp.radius
		for y: float in [-half, half]:
			var t := xf.translated_local(Vector3(0.0, y, 0.0))
			_ellipse(t, Vector3.RIGHT * cp.radius, Vector3.BACK * cp.radius, c)
			_ellipse(t, Vector3.RIGHT * cp.radius, Vector3.UP * cp.radius, c)
		for a in 4:
			var d := Vector3(cos(a * PI * 0.5), 0.0, sin(a * PI * 0.5)) * cp.radius
			_line(xf * (d + Vector3.DOWN * half), xf * (d + Vector3.UP * half), c)
	elif s is BoxShape3D:
		var e := (s as BoxShape3D).size * 0.5
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				_line(xf * Vector3(sx * e.x, sy * e.y, -e.z), xf * Vector3(sx * e.x, sy * e.y, e.z), c)
				_line(xf * Vector3(sx * e.x, -e.y, sy * e.z), xf * Vector3(sx * e.x, e.y, sy * e.z), c)
				_line(xf * Vector3(-e.x, sx * e.y, sy * e.z), xf * Vector3(e.x, sx * e.y, sy * e.z), c)


func _ellipse(xf: Transform3D, a: Vector3, b: Vector3, c: Color) -> void:
	var prev := xf * a
	for i in range(1, 25):
		var t := float(i) / 24.0 * TAU
		var pt := xf * (a * cos(t) + b * sin(t))
		_line(prev, pt, c)
		prev = pt


func _line(a: Vector3, b: Vector3, c: Color) -> void:
	_imm.surface_set_color(c)
	_imm.surface_add_vertex(a)
	_imm.surface_set_color(c)
	_imm.surface_add_vertex(b)
