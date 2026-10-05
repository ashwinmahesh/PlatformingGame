class_name Springcap
extends Node3D
## A permanent bounce mushroom (plan §5.3). Landing gives a small bounce; a Plunge launches high.
## Only permanent bounce surfaces like this one may be on the required path.

enum Look { MUSHROOM, CLOUD, GLOWCAP, JELLY }

var look: Look = Look.MUSHROOM
## 0 = use the hero's MovementSettings values.
var land_height: float = 0.0
var plunge_height: float = 0.0
var _cap: Node3D
var _squash: float = 0.0


func _ready() -> void:
	if look == Look.JELLY:
		# Build 5 (Bubbleton Reef): a big friendly jellyfish resting on a coral stump.
		var stem := Kit.pillar(self, Vector3(0.0, 0.7, 0.0), 0.45, 0.7, &"coral_orange")
		stem.collision_layer = Layers.WORLD
	elif look != Look.CLOUD:
		var stem := Kit.pillar(self, Vector3(0.0, 0.7, 0.0), 0.35, 0.7, &"cloth_cream")
		stem.collision_layer = Layers.WORLD
	_cap = Node3D.new()
	_cap.position.y = 0.7
	add_child(_cap)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CylinderShape3D.new()
	shape.radius = 1.1
	shape.height = 0.5
	Kit.add_shape(body, shape, Vector3(0.0, 0.25, 0.0))
	_cap.add_child(body)
	var dome := SphereMesh.new()
	dome.radius = 1.15
	dome.height = 1.0
	dome.is_hemisphere = true
	if look == Look.CLOUD:
		# Bouncy cloud (Cloudtop Steps): fluffy blobs instead of a cap.
		for i in 6:
			var a := float(i) / 6.0 * TAU
			Kit.blob(_cap, Vector3(cos(a) * 0.8, 0.2, sin(a) * 0.8), 0.7, &"foam")
		Kit.blob(_cap, Vector3(0.0, 0.45, 0.0), 0.9, &"cloth_cream")
	else:
		_build_cap(dome)
	var area := Area3D.new()
	area.collision_layer = Layers.BOUNCE
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta(&"actor", self)
	var as_shape := CylinderShape3D.new()
	as_shape.radius = 1.15
	as_shape.height = 0.7
	Kit.add_shape(area, as_shape, Vector3(0.0, 0.75, 0.0))
	_cap.add_child(area)


func _build_cap(dome: SphereMesh) -> void:
	if look == Look.JELLY:
		Kit.mesh_instance(_cap, dome, Kit.slime_mat(&"candy_pink", 0.03), Vector3.ZERO)
		var inner := SphereMesh.new()
		inner.radius = 0.6
		inner.height = 0.6
		inner.is_hemisphere = true
		Kit.mesh_instance(_cap, inner, Kit.mat(&"coral_pink"), Vector3(0.0, 0.02, 0.0))
		for i in 8:
			var a := float(i) / 8.0 * TAU
			var t := CapsuleMesh.new()
			t.radius = 0.07
			t.height = 0.9
			var tm := Kit.mesh_instance(_cap, t, Kit.mat(&"gloop_pink"), Vector3(cos(a) * 0.95, -0.2, sin(a) * 0.95))
			tm.rotation = Vector3(sin(a) * 0.3, 0.0, -cos(a) * 0.3)
		for side: float in [-1.0, 1.0]:
			var eye := SphereMesh.new()
			eye.radius = 0.09
			eye.height = 0.18
			Kit.mesh_instance(_cap, eye, Kit.mat(&"ink_navy"), Vector3(0.28 * side, 0.32, 0.95))
		return
	Kit.mesh_instance(_cap, dome, Kit.mat(&"roof_red" if look == Look.MUSHROOM else &"portal_teal", 0.03), Vector3(0.0, 0.0, 0.0))
	if look == Look.GLOWCAP:
		var glow := OmniLight3D.new()
		glow.light_color = Palette.color(&"portal_teal")
		glow.light_energy = 1.2
		glow.omni_range = 6.0
		glow.position.y = 0.6
		_cap.add_child(glow)
	for i in 6:
		var spot := SphereMesh.new()
		spot.radius = 0.16
		spot.height = 0.12
		var a := i * TAU / 6.0
		var dome_y := 0.5 * sqrt(1.0 - pow(0.7 / 1.15, 2.0))
		var sm := Kit.mesh_instance(_cap, spot, Kit.mat(&"cloth_cream"), Vector3(cos(a) * 0.7, dome_y, sin(a) * 0.7))
		sm.rotation = Vector3(sin(a) * 0.6, 0.0, -cos(a) * 0.6)
	var top_spot := SphereMesh.new()
	top_spot.radius = 0.22
	top_spot.height = 0.12
	Kit.mesh_instance(_cap, top_spot, Kit.mat(&"cloth_cream"), Vector3(0.0, 0.53, 0.0))


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if StringName(str(atk.get("kind", ""))) != &"plunge":
		return {}
	_boing()
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if plunge_height > 0.0:
		return {"bounce": plunge_height}
	return {"bounce": p.settings.springcap_plunge_height if p != null else 8.5}


func on_player_land(p: Player) -> float:
	_boing()
	return land_height if land_height > 0.0 else p.settings.springcap_height


func _boing() -> void:
	_squash = 1.0


func _process(delta: float) -> void:
	_squash = maxf(_squash - delta * 3.0, 0.0)
	var k := sin(_squash * PI * 3.0) * _squash * 0.25
	_cap.scale = Vector3(1.0 + k, 1.0 - k, 1.0 + k)
