class_name ColourLock
extends Node3D
## Build 7 puzzle: three paint crystals (red, yellow, blue) each toggle on a hit. The door's orb
## shows the colour to mix (purple = red + blue, green = yellow + blue, orange = red + yellow,
## or one primary on its own). Get exactly that mix lit and `solved` fires.

signal solved

const NAMES: Array[StringName] = [&"roof_red", &"gold", &"slime_blue"]
## Which crystals must be lit: [red, yellow, blue].
var want: Array[bool] = [true, false, true]
var done: bool = false
var _lit: Array[bool] = [false, false, false]
var _gems: Array[MeshInstance3D] = []


func _ready() -> void:
	var mix := Color.BLACK
	var count := 0
	for i in 3:
		if want[i]:
			mix += Palette.color(NAMES[i])
			count += 1
	var orb := SphereMesh.new()
	orb.radius = 0.7
	orb.height = 1.4
	var om := Kit.unique_mat(&"foam")
	om.set_shader_parameter(&"flash", 1.0)
	om.set_shader_parameter(&"flash_color", mix / maxf(count, 1.0))
	Kit.pillar(self, Vector3(0.0, 1.6, 0.0), 0.4, 1.6, &"stone_dark", &"")
	Kit.mesh_instance(self, orb, om, Vector3(0.0, 2.4, 0.0))


func add_crystal(at: Vector3, which: int) -> void:
	var holder := Node3D.new()
	holder.position = at
	add_child(holder)
	Kit.pillar(holder, Vector3(0.0, 0.6, 0.0), 0.45, 0.6, &"stone_dark", &"")
	var gem := PrismMesh.new()
	gem.size = Vector3(0.7, 1.3, 0.7)
	var mi := Kit.mesh_instance(holder, gem, Kit.unique_mat(NAMES[which], 0.04), Vector3(0.0, 1.35, 0.0))
	_gems.append(mi)
	var hit := ColourCrystalHit.new()
	hit.on_hit = func() -> void: _toggle(which, mi)
	holder.add_child(hit)


func _toggle(which: int, mi: MeshInstance3D) -> void:
	if done:
		return
	_lit[which] = not _lit[which]
	var m := mi.material_override as ShaderMaterial
	m.set_shader_parameter(&"flash", 0.9 if _lit[which] else 0.0)
	m.set_shader_parameter(&"flash_color", Palette.color(NAMES[which]))
	AudioDirector.play(&"ui_blip", -4.0, 1.0 + which * 0.2)
	if _lit == want:
		done = true
		AudioDirector.play(&"seed")
		solved.emit()
