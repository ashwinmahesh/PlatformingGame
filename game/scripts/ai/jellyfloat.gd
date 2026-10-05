class_name Jellyfloat
extends Critter
## A floating jellyfish (inspired by Dragon Quest's Healslime, our own design): drifts toward you
## and stings on touch, but a Plunge onto its dome bounces you high (platforming use).

var _tentacles: Array[Node3D] = []
var _t: float = 0.0


func _init() -> void:
	max_hp = 1
	body_radius = 0.7
	body_half_height = 0.5
	body_center = 0.6
	uses_gravity = false
	color_name = &"water_light"
	drop_heart_chance = 0.15


func build_body() -> void:
	var dome := SphereMesh.new()
	dome.radius = 0.75
	dome.height = 0.9
	dome.is_hemisphere = true
	var m := Kit.slime_mat(&"water_light", 0.04)
	_flash_mats.append(m)
	Kit.mesh_instance(_visual, dome, m, Vector3(0.0, 0.55, 0.0))
	for side: float in [-1.0, 1.0]:
		ball(_visual, 0.08, &"bark_dark", Vector3(0.2 * side, 0.8, -0.6), 0.0)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var t := Node3D.new()
		t.position = Vector3(cos(a) * 0.45, 0.55, sin(a) * 0.45)
		_visual.add_child(t)
		var cap := CapsuleMesh.new()
		cap.radius = 0.06
		cap.height = 0.8
		Kit.mesh_instance(t, cap, Kit.mat(&"portal_magenta"), Vector3(0.0, -0.4, 0.0))
		_tentacles.append(t)


func think(delta: float) -> void:
	_t += delta
	var p := player_ref()
	var goal := home + Vector3(0.0, sin(_t * 1.6) * 0.8, 0.0)
	if p != null and p.global_position.distance_to(home) < 9.0:
		var toward := p.global_position + Vector3.UP * 0.8
		goal = goal.lerp(Vector3(toward.x, goal.y, toward.z), 0.35)
	velocity = (goal - global_position) * 1.5


func on_hit(atk: Dictionary) -> Dictionary:
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	if StringName(str(atk.get("kind", ""))) == &"plunge":
		return {"hit": true, "bounce": 5.5}
	return {"hit": true}


func animate(_delta: float) -> void:
	for i in _tentacles.size():
		_tentacles[i].rotation.x = sin(_t * 4.0 + i) * 0.35
	var pulse := 1.0 + sin(_t * 3.0) * 0.08
	_visual.scale = Vector3(pulse, 2.0 - pulse, pulse)
