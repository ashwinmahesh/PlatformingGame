class_name Portal
extends Area3D
## A Dream Pool / stump-ring / return arch (plan §5.2). Walk in to travel. A trigger has to be
## left before it can fire again, and only one transition runs at a time.

enum Look { ARCH, STUMP_RING }

var target_scene: StringName
var target_spawn: StringName
var look: Look = Look.ARCH
var dormant: bool = false
var cleared: bool = false
var label_text: String = ""
var _armed: bool = false
var _pool_mat: ShaderMaterial


func _ready() -> void:
	collision_layer = Layers.INTERACT
	collision_mask = Layers.PLAYER_BODY
	var s := BoxShape3D.new()
	s.size = Vector3(2.4, 3.0, 1.2) if look == Look.ARCH else Vector3(2.6, 2.0, 2.6)
	Kit.add_shape(self, s, Vector3(0.0, 1.5, 0.0))
	_pool_mat = ShaderMaterial.new()
	_pool_mat.shader = preload("res://shaders/portal.gdshader")
	_pool_mat.set_shader_parameter(&"dormant", 1.0 if dormant else 0.0)
	if look == Look.ARCH:
		_build_arch()
	else:
		_build_ring()
	if label_text != "":
		Kit.label(self, Vector3(0.0, 5.8 if look == Look.ARCH else 3.2, 0.0), label_text, 30)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	# Arrive outside every trigger: arm once the player is clear.
	_armed = false
	get_tree().create_timer(0.3).timeout.connect(_check_clear)


func _check_clear() -> void:
	if not is_inside_tree():
		return
	var inside := false
	for b in get_overlapping_bodies():
		if b is Player:
			inside = true
	_armed = not inside


func _build_arch() -> void:
	for side: float in [-1.0, 1.0]:
		var root := Kit.pillar(self, Vector3(1.45 * side, 3.4, 0.0), 0.32, 3.4, &"bark_mid")
		root.rotation.z = 0.08 * side
	var top := TorusMesh.new()
	top.inner_radius = 1.25
	top.outer_radius = 1.75
	top.rings = 16
	var arch := Kit.mesh_instance(self, top, Kit.mat(&"bark_mid", 0.03), Vector3(0.0, 3.3, 0.0))
	arch.rotation.x = PI * 0.5
	var crest := CylinderMesh.new()
	crest.top_radius = 0.4
	crest.bottom_radius = 0.4
	crest.height = 0.12
	var c := Kit.mesh_instance(self, crest, Kit.mat(&"gold" if cleared else (&"stone_dark" if dormant else &"leaf_teal"), 0.02), Vector3(0.0, 5.05, 0.0))
	c.rotation.x = PI * 0.5
	var pool := QuadMesh.new()
	pool.size = Vector2(2.6, 3.3)
	Kit.mesh_instance(self, pool, _pool_mat, Vector3(0.0, 1.75, 0.0))
	if cleared:
		for i in 7:
			Kit.blob(self, Vector3(-1.6 + i * 0.53, 4.4 + sin(i) * 0.35, 0.25), 0.2, &"gloop_pink" if i % 2 == 0 else &"thatch")


func _build_ring() -> void:
	var stump := CylinderMesh.new()
	stump.top_radius = 1.6
	stump.bottom_radius = 1.8
	stump.height = 0.5
	Kit.mesh_instance(self, stump, Kit.mat(&"bark_light", 0.02), Vector3(0.0, 0.25, 0.0))
	var disc := CylinderMesh.new()
	disc.top_radius = 1.3
	disc.bottom_radius = 1.3
	disc.height = 0.04
	var pool := QuadMesh.new()
	pool.size = Vector2(2.6, 2.6)
	var pm := Kit.mesh_instance(self, pool, _pool_mat, Vector3(0.0, 0.53, 0.0))
	pm.rotation.x = -PI * 0.5
	for i in 6:
		var a := i * TAU / 6.0
		var r := Kit.pillar(self, Vector3(cos(a) * 1.9, 1.3, sin(a) * 1.9), 0.16, 1.3, &"bark_mid")
		r.rotation.z = cos(a) * 0.25
		r.rotation.x = -sin(a) * 0.25


func _on_enter(body: Node3D) -> void:
	if not body is Player or dormant or not _armed or Router.busy:
		return
	var p := body as Player
	p.set_talking(true)
	Telemetry.log_event("portal", {"to": String(target_scene)})
	Router.go_to(target_scene, target_spawn)


func _on_exit(body: Node3D) -> void:
	if body is Player:
		_armed = true
