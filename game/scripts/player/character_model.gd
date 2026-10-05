class_name CharacterModel
extends Node3D
## Wrapper around a sourced, rigged KayKit character (plan §11.4): toon materials, ink hull,
## facing -Z, looping flags, and attach points. The imported scene itself is never edited.

const LOOPING: Array[StringName] = [&"Idle", &"Running_A", &"Running_B", &"Walking_A", &"Walking_B", &"Jump_Idle", &"Unarmed_Idle", &"2H_Melee_Idle", &"Sit_Floor_Idle", &"Blocking", &"Spellcasting", &"Cheer"]

var model: Node3D
var anim: AnimationPlayer
var skeleton: Skeleton3D
var current: StringName = &""


static func create(path: String, model_scale: float, hidden_parts: Array[String], outline_width: float) -> CharacterModel:
	var cm := CharacterModel.new()
	cm.model = (load(path) as PackedScene).instantiate() as Node3D
	cm.model.scale = Vector3.ONE * model_scale
	cm.model.rotation.y = PI
	cm.add_child(cm.model)
	for part in hidden_parts:
		var n := cm.model.find_child(part, true, false) as Node3D
		if n != null:
			n.visible = false
	Toon.apply(cm.model, outline_width)
	var players := cm.model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		cm.anim = players[0] as AnimationPlayer
		for a in LOOPING:
			if cm.anim.has_animation(a):
				cm.anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	var skels := cm.model.find_children("*", "Skeleton3D", true, false)
	if not skels.is_empty():
		cm.skeleton = skels[0] as Skeleton3D
	return cm


## Cross-fade to an animation. restart replays it even if it's already the current one.
func play(anim_name: StringName, blend: float = 0.12, speed: float = 1.0, restart: bool = false) -> void:
	if anim == null or not anim.has_animation(anim_name):
		return
	if anim_name == current and not restart:
		anim.speed_scale = speed
		return
	current = anim_name
	anim.speed_scale = speed
	anim.play(anim_name, blend)
	if restart:
		anim.seek(0.0, true)


func clip_length(anim_name: StringName) -> float:
	if anim == null or not anim.has_animation(anim_name):
		return 1.0
	return anim.get_animation(anim_name).length


func find_part(part: String) -> Node3D:
	return model.find_child(part, true, false) as Node3D


## A node that follows `bone`, positioned at the top of `mesh_part` (e.g. the head's crown).
func attach_on_top(bone: String, mesh_part: String) -> Node3D:
	if skeleton == null:
		return null
	var idx := skeleton.find_bone(bone)
	if idx < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	var holder := Node3D.new()
	ba.add_child(holder)
	var mi := find_part(mesh_part) as MeshInstance3D
	if mi != null:
		var box := mi.get_aabb()
		var top := mi.transform * Vector3(box.get_center().x, box.end.y, box.get_center().z)
		holder.position = skeleton.get_bone_global_rest(idx).affine_inverse() * top
	return holder
