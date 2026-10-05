class_name CrystalSwitch
extends Node3D
## Hit it with the sword to light it (Build 4 puzzles). Timed switches go dark again after
## `hold` seconds, so a group has to be lit quickly. Lantern look for Glowcap Caverns.

signal lit_changed(on: bool)

enum Look { CRYSTAL, LANTERN }

var look: Look = Look.CRYSTAL
var hold: float = 0.0
var lit: bool = false
var _left: float = 0.0
var _last_id: int = -1
var _gem: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group(&"lockable")
	var area := Area3D.new()
	area.collision_layer = Layers.ENEMY_HURTBOX
	area.monitoring = false
	area.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 0.9
	Kit.add_shape(area, s, Vector3(0.0, 1.4, 0.0))
	add_child(area)
	Kit.pillar(self, Vector3(0.0, 0.6, 0.0), 0.5, 0.6, &"stone_dark", &"stone_light")
	if look == Look.CRYSTAL:
		var gem := PrismMesh.new()
		gem.size = Vector3(0.7, 1.4, 0.7)
		_gem = Kit.mesh_instance(self, gem, Kit.unique_mat(&"portal_teal", 0.04), Vector3(0.0, 1.4, 0.0))
	else:
		var post := CylinderMesh.new()
		post.top_radius = 0.08
		post.bottom_radius = 0.1
		post.height = 1.0
		Kit.mesh_instance(self, post, Kit.mat(&"bark_dark"), Vector3(0.0, 1.0, 0.0))
		var cage := SphereMesh.new()
		cage.radius = 0.35
		cage.height = 0.7
		_gem = Kit.mesh_instance(self, cage, Kit.unique_mat(&"stone_dark", 0.04), Vector3(0.0, 1.6, 0.0))
	_light = OmniLight3D.new()
	_light.light_color = Palette.color(&"gold")
	_light.omni_range = 7.0
	_light.light_energy = 0.0
	_light.position.y = 1.6
	add_child(_light)


func is_lockable() -> bool:
	return not lit


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	set_lit(true)
	return {"hit": true}


func set_lit(on: bool) -> void:
	if on == lit:
		_left = hold
		return
	lit = on
	_left = hold
	var m := _gem.material_override as ShaderMaterial
	m.set_shader_parameter(&"cell", Vector2(Palette.cell(&"gold" if on else (&"portal_teal" if look == Look.CRYSTAL else &"stone_dark"))))
	m.set_shader_parameter(&"flash", 0.6 if on else 0.0)
	m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
	_light.light_energy = 1.8 if on else 0.0
	AudioDirector.play(&"checkpoint" if on else &"ui_blip", -4.0)
	lit_changed.emit(on)


func _process(delta: float) -> void:
	_gem.rotation.y += delta * (2.5 if lit else 0.6)
	if lit and hold > 0.0:
		_left -= delta
		if _left <= 0.0:
			set_lit(false)
