class_name SnowballRoller
extends Node3D
## Rolls snowballs down a slope from `start` to `end` every `interval` seconds (Build 4).
## Jump over them; a hit costs ½ heart and knocks you aside.

var start: Vector3
var end: Vector3
var interval: float = 3.2
var speed: float = 9.0
var radius: float = 1.1
## Build 5: &"snow" or &"urchin" (spiky purple sea urchins, Bubbleton Reef).
var look: StringName = &"snow"
var _t: float = 0.0
var _balls: Array[MeshInstance3D] = []
var _progress: Array[float] = []


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	_t = interval * 0.5


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= interval:
		_t = 0.0
		var s := SphereMesh.new()
		s.radius = radius
		s.height = radius * 2.0
		var mi := Kit.mesh_instance(self, s, Kit.mat(&"mush_purple" if look == &"urchin" else &"foam", 0.04), Vector3.ZERO)
		if look == &"urchin":
			for k in 14:
				var spike := CylinderMesh.new()
				spike.top_radius = 0.0
				spike.bottom_radius = radius * 0.16
				spike.height = radius * 0.9
				var dir := Vector3(sin(k * 2.4) * cos(k * 1.3), cos(k * 2.4), sin(k * 2.4) * sin(k * 1.3)).normalized()
				var sp := Kit.mesh_instance(mi, spike, Kit.mat(&"crystal_violet"), dir * radius * 1.1)
				sp.basis = Basis(Quaternion(Vector3.UP, dir))
		mi.top_level = true
		mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_balls.append(mi)
		_progress.append(0.0)
	var length := start.distance_to(end)
	for i in range(_balls.size() - 1, -1, -1):
		_progress[i] += speed * delta / length
		var k := _progress[i]
		if k >= 1.0:
			Fx.burst(get_parent(), _balls[i].global_position, Palette.color(&"mush_purple" if look == &"urchin" else &"foam"), 10, 3.0, 0.15)
			_balls[i].queue_free()
			_balls.remove_at(i)
			_progress.remove_at(i)
			continue
		var pos := start.lerp(end, k) + Vector3.UP * radius
		_balls[i].global_position = pos
		_balls[i].rotate(start.direction_to(end).cross(Vector3.UP).normalized(), -speed * delta / radius)


func damage_to_player(p: Player) -> Dictionary:
	for b in _balls:
		var d := p.global_position + Vector3.UP * 0.6 - b.global_position
		if d.length() < radius + 0.45:
			return {"halves": 1, "from": b.global_position - start.direction_to(end) * 2.0, "cause": String(look)}
	return {}
