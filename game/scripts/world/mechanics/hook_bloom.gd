class_name HookBloom
extends Node3D
## Build 7 (Ashwin: "replace gliding power with something else"): a glowing hook flower the
## Vinelash catches. Shoot a vine at it (G) and you zip up to it, then pop up over the top.
## Placed through every world to open extra routes up; never required for shards or the goal.

const RANGE := 24.0

var color_name: StringName = &"leaf_teal"
var _bud: Node3D
var _t: float = 0.0


func _ready() -> void:
	add_to_group(&"hook_bloom")
	_bud = Node3D.new()
	add_child(_bud)
	var stalk := Kit.mesh_instance(_bud, RoundMesh.box(Vector3(0.18, 1.4, 0.18), 0.05), Kit.mat(&"leaf_dark"), Vector3(0.0, 0.7, 0.0))
	stalk.name = "Stalk"
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var petal := SphereMesh.new()
		petal.radius = 0.32
		petal.height = 0.3
		var mi := Kit.mesh_instance(_bud, petal, Kit.mat(&"candy_pink" if i % 2 == 0 else &"gold", 0.02), Vector3(cos(a) * 0.45, 1.5, sin(a) * 0.45))
		mi.rotation = Vector3(0.0, -a, 0.5)
	var core := SphereMesh.new()
	core.radius = 0.32
	core.height = 0.64
	var m := Kit.unique_mat(color_name)
	m.set_shader_parameter(&"flash", 0.6)
	m.set_shader_parameter(&"flash_color", Palette.color(color_name))
	Kit.mesh_instance(_bud, core, m, Vector3(0.0, 1.5, 0.0))
	var light := OmniLight3D.new()
	light.light_color = Palette.color(color_name)
	light.omni_range = 4.0
	light.light_energy = 0.8
	light.position.y = 1.5
	add_child(light)


## The point the vine catches.
func anchor() -> Vector3:
	return global_position + Vector3.UP * 1.5


func _process(delta: float) -> void:
	_t += delta
	_bud.rotation.y = sin(_t * 0.8) * 0.3
	_bud.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.04)
