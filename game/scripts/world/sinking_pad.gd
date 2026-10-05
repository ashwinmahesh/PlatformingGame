class_name SinkingPad
extends AnimatableBody3D
## Lily pad that sinks 1 s after you land on it, then resurfaces (plan §5.3 section 4).

const SINK_DELAY := 1.0
const RESURFACE := 2.5

var radius: float = 1.3
var _origin: Vector3
var _timer: float = -1.0
var _sunk: float = 0.0
var _mi: MeshInstance3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = Layers.WORLD
	_origin = position
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.3
	Kit.add_shape(self, shape, Vector3(0.0, -0.15, 0.0))
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 0.95
	cm.height = 0.12
	cm.radial_segments = 16
	_mi = Kit.mesh_instance(self, cm, Kit.unique_mat(&"grass_light", 0.02), Vector3(0.0, -0.06, 0.0))
	var flower := SphereMesh.new()
	flower.radius = 0.18
	flower.height = 0.2
	Kit.mesh_instance(self, flower, Kit.mat(&"gloop_pink"), Vector3(radius * 0.5, 0.05, radius * 0.3))


func _physics_process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if _timer < 0.0 and _sunk <= 0.0 and p != null and p.is_on_floor():
		var flat := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z)
		if flat.length() < radius + 0.2 and absf(p.global_position.y - global_position.y) < 0.5:
			_timer = SINK_DELAY
	if _timer >= 0.0:
		_timer -= delta
		var wobble := sin(_timer * 30.0) * 0.03
		position = _origin + Vector3(0.0, wobble - (SINK_DELAY - _timer) * 0.08, 0.0)
		if _timer < 0.0:
			_sunk = RESURFACE
			AudioDirector.play(&"splash", -10.0)
	elif _sunk > 0.0:
		_sunk -= delta
		position = _origin + Vector3(0.0, -2.0, 0.0)
		if _sunk <= 0.0:
			position = _origin
