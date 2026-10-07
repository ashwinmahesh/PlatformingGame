class_name Cannonball
extends Node3D
## A BrickCannon's iron ball: flies flat and slow along its lane, then puffs away. Half a heart
## on contact; any hit (sword, Fireball, Star Rush...) pops it.

const RADIUS := 0.6

var dir: Vector3 = Vector3.FORWARD
var speed: float = 8.0
var life: float = 4.0
var _done: bool = false


func _ready() -> void:
	add_to_group(&"enemy_attacker")
	var s := SphereMesh.new()
	s.radius = RADIUS
	s.height = RADIUS * 2.0
	Kit.mesh_instance(self, s, Kit.mat(&"ink_navy", 0.04))
	var band := TorusMesh.new()
	band.inner_radius = RADIUS * 0.92
	band.outer_radius = RADIUS * 1.05
	Kit.mesh_instance(self, band, Kit.mat(&"gold")).basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	var sh := SphereShape3D.new()
	sh.radius = RADIUS + 0.2
	Kit.add_shape(a, sh)
	add_child(a)


func _physics_process(delta: float) -> void:
	if _done:
		return
	global_position += dir * speed * delta
	rotate(dir.cross(Vector3.UP).normalized(), -speed * delta / RADIUS)
	life -= delta
	if life <= 0.0:
		pop()


func damage_to_player(p: Player) -> Dictionary:
	if _done:
		return {}
	# The hero's body is a capsule: test against its spine.
	var y := clampf(global_position.y, p.global_position.y + 0.35, p.global_position.y + 0.85)
	var spine := Vector3(p.global_position.x, y, p.global_position.z)
	if spine.distance_to(global_position) < RADIUS + 0.35:
		return {"halves": 1, "from": global_position - dir * 2.0, "cause": "cannonball"}
	return {}


func receive_player_attack(_atk: Dictionary, _area: Area3D) -> Dictionary:
	if _done:
		return {}
	pop()
	return {"hit": true}


func pop() -> void:
	if _done:
		return
	_done = true
	Fx.burst(get_parent(), global_position, Palette.color(&"stone_light"), 10, 3.0, 0.18, 0.0, 0.5)
	AudioDirector.play(&"poof", -6.0, 1.2)
	queue_free()
