class_name Models
extends RefCounted
## Sourced glTF models (Build 6 asset swap: Quaternius and KayKit CC0 packs), instanced under the
## one toon look. Scenes are cached; helpers place a model by its base or fit it into a box.

const Q_NATURE := "res://assets/models/q_nature/"
const Q_VILLAGE := "res://assets/models/q_village/"
const Q_PROPS := "res://assets/models/q_props/"
const Q_MONSTERS := "res://assets/models/q_monsters/"
## Build 7 (World 7): Quaternius Ultimate Space Kit (alien plants, domes) and Kenney Space Kit.
const Q_SPACE := "res://assets/models/q_space/"
const KN_SPACE := "res://assets/models/kn_space/"
const KK_PLATFORM := "res://assets/models/kk_platformer/"

static var _scenes: Dictionary[String, PackedScene] = {}
static var _bounds: Dictionary[String, AABB] = {}


static func clear_cache() -> void:
	_scenes.clear()
	_bounds.clear()


static func instance(path: String, outline: float = 0.0) -> Node3D:
	if not _scenes.has(path):
		_scenes[path] = load(path) as PackedScene
	var n := _scenes[path].instantiate() as Node3D
	Toon.apply(n, outline)
	return n


## Local-space bounds of a model at scale 1.
static func model_bounds(path: String) -> AABB:
	if _bounds.has(path):
		return _bounds[path]
	var holder := Node3D.new()
	var n := instance(path)
	holder.add_child(n)
	var b := Props.bounds(n)
	holder.free()
	_bounds[path] = b
	return b


## Places a model with its base centre at `pos`.
static func spawn(parent: Node, path: String, pos: Vector3, yaw: float = 0.0, s: float = 1.0, outline: float = 0.0) -> Node3D:
	var b := model_bounds(path)
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	parent.add_child(root)
	var n := instance(path, outline)
	n.scale = Vector3.ONE * s
	n.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z) * s
	root.add_child(n)
	return root


## Stretches a model to fill a box whose top centre is `top` (local to parent).
static func fit(parent: Node, path: String, top: Vector3, size: Vector3) -> Node3D:
	var b := model_bounds(path)
	var n := instance(path)
	var sc := Vector3(size.x / maxf(b.size.x, 0.01), size.y / maxf(b.size.y, 0.01), size.z / maxf(b.size.z, 0.01))
	n.scale = sc
	n.position = top - Vector3(b.get_center().x * sc.x, b.end.y * sc.y, b.get_center().z * sc.z)
	parent.add_child(n)
	return n


## Plays the first matching clip on a model's AnimationPlayer (looping).
static func play(model: Node, names: Array[StringName], speed: float = 1.0) -> void:
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	for nm in names:
		if ap.has_animation(nm):
			if ap.current_animation != nm:
				var a := ap.get_animation(nm)
				a.loop_mode = Animation.LOOP_LINEAR
				ap.play(nm, 0.15, speed)
			return
