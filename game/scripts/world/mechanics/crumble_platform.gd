class_name CrumblePlatform
extends StaticBody3D
## A platform that shakes and vanishes a moment after you land on it, then comes back (Build 4).
## Cloud puffs in Cloudtop Steps, rock slabs in Glowcap Caverns.

enum Look { CLOUD, ROCK, ICE }

var size: Vector3 = Vector3(3.5, 0.8, 3.5)
var look: Look = Look.CLOUD
var delay: float = 0.7
var gone_time: float = 3.0
var _timer: float = -1.0
var _gone: float = 0.0
var _visual: Node3D
var _shape: CollisionShape3D
var _origin: Vector3


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_origin = position
	var b := BoxShape3D.new()
	b.size = size
	_shape = Kit.add_shape(self, b, Vector3(0.0, -size.y * 0.5, 0.0))
	_visual = Node3D.new()
	add_child(_visual)
	match look:
		Look.CLOUD:
			for i in 5:
				var a := float(i) / 5.0 * TAU
				var blob := Kit.blob(_visual, Vector3(cos(a) * size.x * 0.28, -size.y * 0.4, sin(a) * size.z * 0.28), size.x * 0.32, &"foam")
				blob.scale.y = 0.7
			var top := Kit.blob(_visual, Vector3(0.0, -size.y * 0.25, 0.0), size.x * 0.38, &"cloth_cream")
			top.scale.y = 0.6
		Look.ROCK:
			Kit.mesh_instance(_visual, RoundMesh.box(size, 0.25), Kit.mat(&"stone_light", 0.0, &"moss"), Vector3(0.0, -size.y * 0.5, 0.0))
		Look.ICE:
			Kit.mesh_instance(_visual, RoundMesh.box(size, 0.3), Kit.mat(&"water_light"), Vector3(0.0, -size.y * 0.5, 0.0))


func _physics_process(delta: float) -> void:
	if _gone > 0.0:
		_gone -= delta
		if _gone <= 0.0:
			_shape.set_deferred(&"disabled", false)
			_visual.visible = true
			_visual.scale = Vector3.ONE * 0.2
			create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		return
	if _timer < 0.0:
		var p := get_tree().get_first_node_in_group(&"player") as Player
		if p != null and p.is_on_floor():
			var d := p.global_position - global_position
			if absf(d.x) < size.x * 0.5 + 0.3 and absf(d.z) < size.z * 0.5 + 0.3 and absf(d.y) < 0.6:
				_timer = delay
		return
	_timer -= delta
	_visual.position = Vector3(sin(_timer * 60.0) * 0.06, 0.0, cos(_timer * 50.0) * 0.06)
	if _timer < 0.0:
		_gone = gone_time
		_shape.set_deferred(&"disabled", true)
		_visual.visible = false
		_visual.position = Vector3.ZERO
		AudioDirector.play(&"poof", -6.0)
		Fx.burst(get_parent(), global_position, Palette.color(&"foam") if look == Look.CLOUD else Palette.color(&"stone_light"), 12, 3.0, 0.15)
