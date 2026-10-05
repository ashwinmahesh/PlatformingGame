class_name TownHouse
extends RefCounted
## Build 6 (World 6, Lanternwick): an old-English townhouse from the Quaternius Medieval Village
## kit. Brick ground floor with a round door on the street side, timber-framed plaster upper floors
## that jut out over the street one step per storey, a tiled roof you can run along (its slope is
## kept under 35 degrees) and a chimney. Collision is a few plain boxes and a roof prism; the kit
## pieces themselves go into a ModuleBatch.

const S := 1.6
const MOD := 2.0 * S
const FLOOR := 3.12 * S
const JETTY := 0.7
const V := "res://assets/models/q_village/"

const GROUND: Array[String] = ["Wall_UnevenBrick_Straight", "Wall_UnevenBrick_Window_Wide_Round", "Wall_UnevenBrick_Window_Thin_Round"]
const UPPER: Array[String] = ["Wall_Plaster_WoodGrid", "Wall_Plaster_Window_Wide_Round", "Wall_Plaster_Window_Thin_Round", "Wall_Plaster_Straight"]


## Builds a house whose street front faces local +Z after `yaw`, centred on `base` (ground level).
## w and d are in 3.2 m modules. roof: &"pitched" (ridge along the width), &"flat" (a walkable
## terrace with a low parapet). jetty=false keeps the front flush (for narrow alleys). Returns {"eave": y, "ridge": y, "front": street-door point}.
static func build(parent: Node3D, batch: ModuleBatch, base: Vector3, yaw: float, w: int, d: int, floors: int, roof: StringName = &"pitched", variant: int = 0, jetty: bool = true) -> Dictionary:
	var j_step := JETTY if jetty else 0.0
	var basis := Basis(Vector3.UP, yaw)
	var hw := w * MOD * 0.5
	var hd := d * MOD * 0.5
	var eave := floors * FLOOR
	var body := Kit.static_body(parent, base)
	body.rotation.y = yaw
	body.name = "House"
	# Collision: the ground floor, then one box per upper floor stepping out over the street.
	var ground := BoxShape3D.new()
	ground.size = Vector3(w * MOD, FLOOR, d * MOD)
	Kit.add_shape(body, ground, Vector3(0.0, FLOOR * 0.5, 0.0))
	for f in range(1, floors):
		var jut := j_step * f
		var b := BoxShape3D.new()
		b.size = Vector3(w * MOD, FLOOR, d * MOD + jut)
		Kit.add_shape(body, b, Vector3(0.0, FLOOR * (f + 0.5), jut * 0.5))
	var front_jut := j_step * (floors - 1)
	# A dark interior so the open windows and doorways read as rooms, not hollow shells.
	var dark := Kit.mesh_instance(body, BoxMesh.new(), Kit.mat(&"bark_dark"), Vector3(0.0, eave * 0.5, 0.0))
	(dark.mesh as BoxMesh).size = Vector3(w * MOD - 0.9, eave - 0.2, d * MOD - 0.9)
	dark.name = "Interior"
	# Wall panels on all four sides of every floor.
	for f in floors:
		var y := f * FLOOR
		var jut := j_step * f
		var names := GROUND if f == 0 else UPPER
		for i in w:
			var x := -hw + (i + 0.5) * MOD
			var front_name := names[(i + f + variant) % names.size()]
			if f == 0 and i == w / 2:
				front_name = "Wall_UnevenBrick_Door_Round"
			_panel(batch, base, basis, front_name, Vector3(x, y, hd + jut), 0.0)
			_panel(batch, base, basis, names[(i + f + variant + 1) % names.size()], Vector3(x, y, -hd), PI)
		# Side panels stretch a little on jettied floors so they meet the overhanging front.
		var step := (d * MOD + jut) / d
		for j in d:
			var z := -hd + (j + 0.5) * step
			var side_name := names[(j + f + variant + 2) % names.size()]
			var stretch := Vector3(S * step / MOD, S, S)
			_panel(batch, base, basis, side_name, Vector3(hw, y, z), PI * 0.5, stretch)
			_panel(batch, base, basis, side_name, Vector3(-hw, y, z), -PI * 0.5, stretch)
	var top := eave
	var depth := d * MOD + front_jut
	var zc := front_jut * 0.5
	if roof == &"flat":
		var slab := BoxShape3D.new()
		slab.size = Vector3(w * MOD + 0.4, 0.4, depth + 0.4)
		Kit.add_shape(body, slab, Vector3(0.0, eave + 0.2, zc))
		var slab_mesh := Kit.mesh_instance(body, RoundMesh.box(slab.size, 0.1), Kit.mat(&"wood_plank"), Vector3(0.0, eave + 0.2, zc))
		slab_mesh.name = "Terrace"
		for i in w:
			batch.place(V + "Prop_ExteriorBorder_Straight1.gltf", base + basis * Vector3(-hw + (i + 0.5) * MOD, eave + 0.4, zc + depth * 0.5), yaw, Vector3.ONE * S)
		top = eave + 0.4
	else:
		# A prism the width of the house with its ridge along X; rise = 0.6 x half-depth (31 deg).
		var rise := depth * 0.5 * 0.6
		var pts := PackedVector3Array()
		for sx: float in [-1.0, 1.0]:
			var x := sx * (hw + 0.3)
			pts.append(Vector3(x, eave, zc - depth * 0.5 - 0.3))
			pts.append(Vector3(x, eave, zc + depth * 0.5 + 0.3))
			pts.append(Vector3(x, eave + rise, zc))
		var prism := ConvexPolygonShape3D.new()
		prism.points = pts
		var cs := CollisionShape3D.new()
		cs.shape = prism
		body.add_child(cs)
		var roof_name := "Roof_RoundTiles_8x8" if w >= 3 else "Roof_RoundTiles_6x8"
		var rb := Models.model_bounds(V + roof_name + ".gltf")
		# The kit's roofs have their ridge along Z; turn a quarter so it runs along the width.
		var sc := Vector3((depth + 0.8) / rb.size.x, (rise + 0.9) / rb.size.y, (w * MOD + 0.8) / rb.size.z)
		var rxf := Transform3D(basis * Basis(Vector3.UP, PI * 0.5) * Basis.from_scale(sc), Vector3.ZERO)
		var roof_base := base + basis * Vector3(0.0, eave - 0.2, zc)
		var off := rxf.basis * -Vector3(rb.get_center().x, rb.position.y, rb.get_center().z)
		batch.add(V + roof_name + ".gltf", Transform3D(rxf.basis, roof_base + off))
		top = eave + rise
		var chimney_x := hw * (0.55 if variant % 2 == 0 else -0.55)
		batch.place(V + ("Prop_Chimney.gltf" if variant % 3 != 1 else "Prop_Chimney2.gltf"), base + basis * Vector3(chimney_x, eave + rise * 0.45, zc - depth * 0.2), yaw, Vector3.ONE * S)
		var ch := BoxShape3D.new()
		ch.size = Vector3(1.4, 3.6, 1.4)
		Kit.add_shape(body, ch, Vector3(chimney_x, eave + rise * 0.45 + 1.8, zc - depth * 0.2))
	return {"eave": base.y + eave, "ridge": base.y + top, "front": base + basis * Vector3(0.0, 0.0, hd + 0.5), "depth": depth, "jut": front_jut}


static func _panel(batch: ModuleBatch, base: Vector3, basis: Basis, name: String, local: Vector3, turn: float, s: Vector3 = Vector3.ONE * S) -> void:
	var path := V + name + ".gltf"
	var b := Basis(basis * Basis(Vector3.UP, turn))
	var origin := base + basis * local
	batch.add(path, Transform3D(b * Basis.from_scale(s), origin))
