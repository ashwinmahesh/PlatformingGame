class_name ThunderDynamo
extends Node3D
## Build 7 puzzle: a copper coil machine. A Thunderclap (or Mighty Roar) charges it and it runs for
## `run_time` seconds: `powered_changed(true)`, then false. Sword hits just spark.

signal powered_changed(on: bool)

var run_time: float = 12.0
var powered: bool = false
var _left: float = 0.0
var _coil: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	Kit.block(self, Vector3(0.0, 0.8, 0.0), Vector3(2.0, 0.8, 2.0), &"stone_dark", Layers.WORLD | Layers.CAMERA_BLOCKER, &"")
	var c := CylinderMesh.new()
	c.top_radius = 0.6
	c.bottom_radius = 0.6
	c.height = 1.6
	_coil = Kit.mesh_instance(self, c, Kit.unique_mat(&"sunset_orange", 0.03), Vector3(0.0, 1.6, 0.0))
	for i in 5:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.58
		ring.outer_radius = 0.72
		Kit.mesh_instance(self, ring, Kit.mat(&"gold"), Vector3(0.0, 0.95 + i * 0.32, 0.0))
	_light = OmniLight3D.new()
	_light.light_color = Palette.color(&"gold")
	_light.omni_range = 8.0
	_light.light_energy = 0.0
	_light.position.y = 2.6
	add_child(_light)
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 1.4
	Kit.add_shape(a, s, Vector3(0.0, 1.6, 0.0))
	add_child(a)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if Critter.shakes(StringName(str(atk.get("kind", "")))):
		_left = run_time
		if not powered:
			powered = true
			AudioDirector.play(&"thunder", -2.0, 1.3)
			powered_changed.emit(true)
		return {"hit": true}
	Fx.burst(get_parent(), global_position + Vector3.UP * 1.8, Palette.color(&"gold"), 4, 2.0, 0.06)
	return {}


func _physics_process(delta: float) -> void:
	var m := _coil.material_override as ShaderMaterial
	if powered:
		_left -= delta
		m.set_shader_parameter(&"flash", 0.5 + 0.3 * sin(_left * 20.0))
		m.set_shader_parameter(&"flash_color", Palette.color(&"gold"))
		_light.light_energy = 2.0
		if _left <= 0.0:
			powered = false
			m.set_shader_parameter(&"flash", 0.0)
			_light.light_energy = 0.0
			powered_changed.emit(false)
