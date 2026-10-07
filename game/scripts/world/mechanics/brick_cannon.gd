class_name BrickCannon
extends Node3D
## World 8: a stubby cannon on the battlements, aimed along a lane (local -Z). Every few seconds
## its barrel glows, shakes and puffs smoke (the tell), then it fires a slow iron ball straight
## down the lane. Jump over the ball, slash it to pop it, or Star Rush right through it. A ball
## costs half a heart. You can stand on the cannon.

const TELL := 0.9

var interval: float = 4.0
var phase: float = 0.0
var speed: float = 8.0
var lane: float = 30.0
var fired: int = 0
var _t: float = 0.0
var _telling: bool = false
var _barrel: Node3D
var _mat: ShaderMaterial


func _ready() -> void:
	_t = phase * interval
	Kit.block(self, Vector3(0.0, 0.7, 0.4), Vector3(2.4, 0.7, 2.6), &"roof_red", Layers.WORLD, &"gold")
	_barrel = Node3D.new()
	_barrel.position = Vector3(0.0, 1.15, 0.0)
	add_child(_barrel)
	_mat = Kit.unique_mat(&"ink_navy", 0.04)
	var tube := CylinderMesh.new()
	tube.top_radius = 0.62
	tube.bottom_radius = 0.75
	tube.height = 2.6
	Kit.mesh_instance(_barrel, tube, _mat).rotation.x = PI * 0.5
	var lip := TorusMesh.new()
	lip.inner_radius = 0.5
	lip.outer_radius = 0.8
	Kit.mesh_instance(_barrel, lip, Kit.mat(&"gold", 0.02), Vector3(0.0, 0.0, -1.3)).rotation.x = PI * 0.5
	var hole := CylinderMesh.new()
	hole.top_radius = 0.48
	hole.bottom_radius = 0.48
	hole.height = 0.05
	Kit.mesh_instance(_barrel, hole, Kit.mat(&"bark_dark"), Vector3(0.0, 0.0, -1.32)).rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		var wheel := CylinderMesh.new()
		wheel.top_radius = 0.6
		wheel.bottom_radius = 0.6
		wheel.height = 0.25
		Kit.mesh_instance(self, wheel, Kit.mat(&"wood_warm", 0.03), Vector3(side * 1.3, 0.6, 0.6)).rotation.z = PI * 0.5


func muzzle() -> Vector3:
	return _barrel.global_position - global_basis.z * 1.4


func _physics_process(delta: float) -> void:
	_t += delta
	var to_fire := interval - _t
	if to_fire <= TELL and not _telling:
		_telling = true
		AudioDirector.play(&"boss_roll", -10.0, 1.8)
	if _telling:
		var k := 1.0 - clampf(to_fire / TELL, 0.0, 1.0)
		_mat.set_shader_parameter(&"flash", 0.25 + 0.5 * k)
		_mat.set_shader_parameter(&"flash_color", Palette.color(&"sunset_orange"))
		_barrel.position = Vector3(sin(_t * 70.0) * 0.04 * k, 1.15, 0.0)
		if Engine.get_physics_frames() % 12 == 0:
			Fx.burst(get_parent(), muzzle(), Palette.color(&"stone_light"), 1, 0.6, 0.18, 1.0, 0.6)
	if _t >= interval:
		_t = 0.0
		_telling = false
		_mat.set_shader_parameter(&"flash", 0.0)
		_barrel.position = Vector3(0.0, 1.15, 0.0)
		_fire()


func _fire() -> void:
	fired += 1
	var b := Cannonball.new()
	var d := -global_basis.z
	d.y = 0.0
	b.dir = d.normalized()
	b.speed = speed
	b.life = lane / speed
	get_parent().add_child(b)
	b.global_position = muzzle()
	AudioDirector.play(&"boss_slam", -8.0, 1.8)
	Fx.burst(get_parent(), muzzle(), Palette.color(&"stone_light"), 10, 3.0, 0.2, 1.0, 0.6)
	var t := create_tween()
	t.tween_property(_barrel, "position:z", 0.35, 0.06)
	t.tween_property(_barrel, "position:z", 0.0, 0.3)
