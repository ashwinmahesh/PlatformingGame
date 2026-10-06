class_name Brazier
extends Node3D
## A stone brazier a Fireball lights (any other hit just clanks).

signal lit_changed(on: bool)

var lit: bool = false
var _flame: MeshInstance3D
var _light: OmniLight3D
var _smoke_t: float = 0.0


func _ready() -> void:
	Kit.pillar(self, Vector3(0.0, 1.0, 0.0), 0.35, 1.0, &"stone_dark", &"")
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.75
	bowl.bottom_radius = 0.4
	bowl.height = 0.5
	Kit.mesh_instance(self, bowl, Kit.mat(&"stone_light", 0.03), Vector3(0.0, 1.25, 0.0))
	var f := PrismMesh.new()
	f.size = Vector3(0.7, 1.0, 0.7)
	_flame = Kit.mesh_instance(self, f, Fx.fx_mat(Color(Palette.color(&"sunset_orange") * 1.5, 0.85)), Vector3(0.0, 1.95, 0.0))
	_flame.visible = false
	_light = OmniLight3D.new()
	_light.light_color = Palette.color(&"sunset_orange")
	_light.omni_range = 6.0
	_light.light_energy = 0.0
	_light.position.y = 2.0
	add_child(_light)
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 0.9
	Kit.add_shape(a, s, Vector3(0.0, 1.5, 0.0))
	add_child(a)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var kind := StringName(str(atk.get("kind", "")))
	if kind == &"fireball" and not lit:
		set_lit(true)
		return {"hit": true}
	if kind == &"frost" and lit:
		set_lit(false)
		return {"hit": true}
	return {}


func set_lit(on: bool) -> void:
	lit = on
	_flame.visible = on
	_light.light_energy = 2.0 if on else 0.0
	AudioDirector.play(&"fire_pop" if on else &"poof", -2.0)
	lit_changed.emit(on)


func _process(delta: float) -> void:
	if lit:
		_flame.scale = Vector3(1.0, 0.85 + sin(Time.get_ticks_msec() * 0.012) * 0.15, 1.0)
		return
	_smoke_t += delta
	if _smoke_t > 1.2:
		_smoke_t = 0.0
		Fx.burst(get_parent(), global_position + Vector3.UP * 1.6, Palette.color(&"stone_light"), 2, 0.4, 0.14, 1.5, 1.2)
