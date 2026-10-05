class_name Kit
extends RefCounted
## Gray-box building helpers. Every surface uses the toon shader and a palette cell (plan §10).

const TOON := preload("res://shaders/toon_palette.gdshader")
const SLIME := preload("res://shaders/slime.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const PALETTE_TEX := preload("res://assets/textures/palette.png")

static var _cache: Dictionary[String, Material] = {}


static func clear_cache() -> void:
	_cache.clear()


## Shared material for a palette colour. outline_width > 0 adds the ink outline pass.
static func mat(color_name: StringName, outline_width: float = 0.0) -> Material:
	var key := "%s|%.3f" % [color_name, outline_width]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter(&"palette_tex", PALETTE_TEX)
	m.set_shader_parameter(&"cell", Vector2(Palette.cell(color_name)))
	if outline_width > 0.0:
		m.next_pass = outline(outline_width)
	_cache[key] = m
	return m


## A material the caller owns (for flashes and fades).
static func unique_mat(color_name: StringName, outline_width: float = 0.0) -> ShaderMaterial:
	var m := (mat(color_name, outline_width) as ShaderMaterial).duplicate() as ShaderMaterial
	return m


static func slime_mat(color_name: StringName, outline_width: float = 0.03) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SLIME
	m.set_shader_parameter(&"palette_tex", PALETTE_TEX)
	m.set_shader_parameter(&"cell", Vector2(Palette.cell(color_name)))
	if outline_width > 0.0:
		m.next_pass = outline(outline_width)
	return m


static func outline(width: float) -> ShaderMaterial:
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter(&"width", width)
	return o


static func mesh_instance(parent: Node, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi


static func static_body(parent: Node, pos: Vector3, layers: int = Layers.WORLD | Layers.CAMERA_BLOCKER) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layers
	body.collision_mask = 0
	body.position = pos
	parent.add_child(body)
	return body


static func add_shape(body: CollisionObject3D, shape: Shape3D, offset: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	body.add_child(cs)
	return cs


## Solid box. pos is the centre of the top face, which is how level layouts are written.
static func block(parent: Node, top_center: Vector3, size: Vector3, color_name: StringName, layers: int = Layers.WORLD | Layers.CAMERA_BLOCKER) -> StaticBody3D:
	var body := static_body(parent, top_center - Vector3(0.0, size.y * 0.5, 0.0), layers)
	var shape := BoxShape3D.new()
	shape.size = size
	add_shape(body, shape)
	var bm := BoxMesh.new()
	bm.size = size
	mesh_instance(body, bm, mat(color_name))
	# Grassy lighter top so safe surfaces read (plan §10.1).
	if color_name in [&"bark_mid", &"bark_dark", &"stone_dark"] and size.x > 1.5 and size.z > 1.5:
		var cap := BoxMesh.new()
		cap.size = Vector3(size.x + 0.04, 0.18, size.z + 0.04)
		mesh_instance(body, cap, mat(&"grass_mid" if color_name != &"stone_dark" else &"moss"), Vector3(0.0, size.y * 0.5 - 0.08, 0.0))
	return body


## Solid cylinder (stumps, stones, mushroom stems). pos is the centre of the top face.
static func pillar(parent: Node, top_center: Vector3, radius: float, height: float, color_name: StringName, top_color: StringName = &"", layers: int = Layers.WORLD | Layers.CAMERA_BLOCKER) -> StaticBody3D:
	var body := static_body(parent, top_center - Vector3(0.0, height * 0.5, 0.0), layers)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	add_shape(body, shape)
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 1.06
	cm.height = height
	cm.radial_segments = 14
	cm.rings = 1
	mesh_instance(body, cm, mat(color_name))
	if top_color != &"":
		var cap := CylinderMesh.new()
		cap.top_radius = radius * 0.98
		cap.bottom_radius = radius * 1.02
		cap.height = 0.14
		cap.radial_segments = 14
		mesh_instance(body, cap, mat(top_color), Vector3(0.0, height * 0.5 - 0.06, 0.0))
	return body


## Ramp: a box rotated about X so it rises toward -Z. start is the low edge's centre.
static func ramp(parent: Node, start: Vector3, width: float, length: float, rise: float, color_name: StringName) -> StaticBody3D:
	var angle := atan2(rise, length)
	var slope_len := sqrt(length * length + rise * rise)
	var thickness := 0.6
	var mid := start + Vector3(0.0, rise * 0.5, -length * 0.5)
	var body := static_body(parent, mid)
	body.rotation.x = angle
	body.position += body.transform.basis.y * -thickness * 0.5
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, thickness, slope_len)
	add_shape(body, shape)
	var bm := BoxMesh.new()
	bm.size = shape.size
	mesh_instance(body, bm, mat(color_name))
	return body


## Decorative tree: trunk collides (camera too), canopy does not (foliage never blocks the camera).
static func tree(parent: Node, base: Vector3, height: float = 6.0, canopy: StringName = &"leaf_dark", seed_value: int = 0) -> Node3D:
	var root := Node3D.new()
	root.position = base
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var trunk_r := 0.35 + height * 0.03
	var body := static_body(root, Vector3(0.0, height * 0.5, 0.0), Layers.WORLD)
	var shape := CylinderShape3D.new()
	shape.radius = trunk_r
	shape.height = height
	add_shape(body, shape)
	var cm := CylinderMesh.new()
	cm.top_radius = trunk_r * 0.7
	cm.bottom_radius = trunk_r * 1.2
	cm.height = height
	cm.radial_segments = 8
	mesh_instance(body, cm, mat(&"bark_mid"))
	for i in 3:
		var sm := SphereMesh.new()
		var r := height * (0.28 - i * 0.04) + rng.randf_range(-0.2, 0.2)
		sm.radius = r
		sm.height = r * 1.7
		sm.radial_segments = 10
		sm.rings = 6
		var off := Vector3(rng.randf_range(-0.6, 0.6), height + i * r * 0.55 - 0.3, rng.randf_range(-0.6, 0.6))
		mesh_instance(root, sm, mat(canopy if i != 1 else &"grass_mid"), off)
	return root


## Low-poly bush / rock decorations (no collision).
static func blob(parent: Node, pos: Vector3, radius: float, color_name: StringName) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 1.4
	sm.radial_segments = 8
	sm.rings = 4
	return mesh_instance(parent, sm, mat(color_name), pos)


## Water surface with a hazard volume underneath (plan §5.3: water is a hazard, no swimming).
static func water(parent: Node, center: Vector3, size: Vector2) -> Area3D:
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = int(size.x / 2.0)
	pm.subdivide_depth = int(size.y / 2.0)
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	mesh_instance(parent, pm, wm, center)
	var area := Area3D.new()
	area.collision_layer = Layers.HAZARD
	area.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	area.position = center + Vector3(0.0, -2.6, 0.0)
	area.monitorable = true
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 5.0, size.y)
	add_shape(area, shape)
	area.add_to_group(&"hazard")
	parent.add_child(area)
	return area


## Hut with a pitched roof you can stand on (rooftop course).
static func hut(parent: Node, base: Vector3, size: Vector3, roof_color: StringName, yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = base
	root.rotation.y = yaw
	parent.add_child(root)
	block(root, Vector3(0.0, size.y, 0.0), size, &"wood_plank")
	var roof_h := size.x * 0.45
	var pm := PrismMesh.new()
	pm.size = Vector3(size.x + 0.8, roof_h, size.z + 0.6)
	var roof := static_body(root, Vector3(0.0, size.y + roof_h * 0.5, 0.0))
	mesh_instance(roof, pm, mat(roof_color, 0.04))
	add_shape(roof, pm.create_convex_shape())
	var door := BoxMesh.new()
	door.size = Vector3(0.9, 1.5, 0.12)
	mesh_instance(root, door, mat(&"bark_dark"), Vector3(0.0, 0.75, size.z * 0.5 + 0.03))
	var win := BoxMesh.new()
	win.size = Vector3(0.6, 0.6, 0.1)
	mesh_instance(root, win, mat(&"thatch"), Vector3(size.x * 0.3, size.y * 0.6, size.z * 0.5 + 0.03))
	return root


static func label(parent: Node, pos: Vector3, text: String, size: int = 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 12
	l.modulate = Palette.color(&"cloth_cream")
	l.outline_modulate = Palette.INK
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.008
	# Hide when the camera is right on top of it, so a sign never fills the screen.
	l.visibility_range_begin = 3.5
	l.position = pos
	parent.add_child(l)
	return l
