class_name WaterLock
extends Node3D
## Build 7 puzzle: a pool whose level a crank wheel raises and lowers through `levels` (local
## heights of the surface). Swim up to ledges, or drain it to walk the floor. Hit the wheel to
## turn it to the next level; `level_changed` fires with the new index.

signal level_changed(index: int)

var size: Vector2 = Vector2(12.0, 12.0)
var depth: float = 10.0
var levels: Array[float] = [-6.0, -3.0, 0.0]
var index: int = 0
var _area: Area3D
var _plane: MeshInstance3D
var _shape: BoxShape3D


func _ready() -> void:
	var pm := PlaneMesh.new()
	pm.size = size
	var wm := ShaderMaterial.new()
	wm.shader = preload("res://shaders/water.gdshader")
	_plane = Kit.mesh_instance(self, pm, wm)
	_area = Area3D.new()
	_area.collision_layer = Layers.HAZARD
	_area.collision_mask = Layers.PLAYER_BODY | Layers.ENEMY_BODY
	_area.monitorable = true
	_area.set_meta(&"kind", &"water")
	_area.add_to_group(&"hazard")
	_shape = BoxShape3D.new()
	Kit.add_shape(_area, _shape)
	add_child(_area)
	_apply(levels[index])


## The crank wheel (put it beside the pool).
func add_wheel(at: Vector3) -> Node3D:
	var w := WaterWheelCrank.new()
	w.position = at
	add_child(w)
	w.turned.connect(func() -> void:
		index = (index + 1) % levels.size()
		var from := _plane.position.y
		create_tween().tween_method(_apply, from, levels[index], 1.4)
		AudioDirector.play(&"splash", -2.0, 0.7)
		level_changed.emit(index))
	return w


func _apply(y: float) -> void:
	_plane.position.y = y
	var bottom := -depth
	var h := maxf(y - bottom, 0.2)
	_shape.size = Vector3(size.x, h, size.y)
	_area.position = Vector3(0.0, bottom + h * 0.5 - 0.05, 0.0)
	_area.set_meta(&"surface", global_position.y + y if is_inside_tree() else y)
	_plane.visible = h > 0.25


func surface() -> float:
	return global_position.y + _plane.position.y
