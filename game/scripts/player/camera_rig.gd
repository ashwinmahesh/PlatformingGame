class_name CameraRig
extends Node3D
## CameraRig -> yaw -> pitch -> SpringArm3D -> Camera3D (plan §3.5).
## Mario vertical framing: height follows the last ground, tracking up only 3 m above it.

const ARM_LENGTH := 10.5
const LOOK_AHEAD := 1.5
const FOCUS_HEIGHT := 1.5
const PITCH_MIN := deg_to_rad(-62.0)
const PITCH_MAX := deg_to_rad(28.0)
const VERTICAL_SLACK := 3.0

var player: Player
var yaw: float = 0.0
var pitch: float = deg_to_rad(-20.0)
var camera: Camera3D
var _yaw_node: Node3D
var _pitch_node: Node3D
var _arm: SpringArm3D
var _focus: Vector3 = Vector3.ZERO
var _ground_ref: float = 0.0
var _look_ahead: Vector3 = Vector3.ZERO
var _idle_input_time: float = 0.0
var _trauma: float = 0.0
var _recenter_tween: Tween


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_yaw_node = Node3D.new()
	add_child(_yaw_node)
	_pitch_node = Node3D.new()
	_yaw_node.add_child(_pitch_node)
	_arm = SpringArm3D.new()
	_arm.spring_length = ARM_LENGTH
	_arm.collision_mask = Layers.CAMERA_BLOCKER
	_arm.margin = 0.25
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	_arm.shape = sphere
	_pitch_node.add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 62.0
	camera.far = 600.0
	_arm.add_child(camera)
	camera.current = true
	add_outline_pass(camera)


## Full-screen ink outline pass (shaders/edge_outline.gdshader) in front of `cam`.
static func add_outline_pass(cam: Camera3D) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/edge_outline.gdshader")
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.extra_cull_margin = 16384.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0.0, 0.0, -1.0)
	cam.add_child(mi)


func attach(p: Player) -> void:
	player = p
	player.camera_rig = self
	_arm.add_excluded_object(player.get_rid())
	yaw = atan2(-player.facing.x, -player.facing.z)
	snap()


func snap() -> void:
	if player == null:
		return
	_ground_ref = player.global_position.y
	_focus = player.global_position + Vector3.UP * FOCUS_HEIGHT
	_look_ahead = Vector3.ZERO
	_apply()


func recenter() -> void:
	if player == null:
		return
	var target := atan2(-player.facing.x, -player.facing.z)
	var diff := wrapf(target - yaw, -PI, PI)
	if _recenter_tween != null:
		_recenter_tween.kill()
	_recenter_tween = create_tween()
	_recenter_tween.tween_property(self, "yaw", yaw + diff, 0.25).set_trans(Tween.TRANS_SINE)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Look input.
	var sx := -1.0 if Settings.invert_x else 1.0
	var sy := -1.0 if Settings.invert_y else 1.0
	# Arrow keys or the right stick turn the camera (Build 2: no mouse look).
	var stick := Input.get_vector(&"cam_left", &"cam_right", &"cam_up", &"cam_down")
	var look := stick * Settings.stick_sensitivity * delta
	yaw -= look.x * sx
	pitch = clampf(pitch - look.y * sy, PITCH_MIN, PITCH_MAX)
	if look.length() > 0.0001:
		_idle_input_time = 0.0
		if _recenter_tween != null:
			_recenter_tween.kill()
	else:
		_idle_input_time += delta
	var p := player.get_global_transform_interpolated().origin
	var vel := player.velocity
	var h_vel := Vector3(vel.x, 0.0, vel.z)
	# Lock-on frames the midpoint and swings behind the hero.
	var locked := player.lock_target != null and is_instance_valid(player.lock_target)
	if locked:
		var to := player.lock_target.global_position - p
		var want := atan2(-to.x, -to.z)
		yaw = lerp_angle(yaw, want, 1.0 - exp(-5.0 * delta))
	elif _idle_input_time > 0.6 and h_vel.length() > 1.0 and Settings.auto_follow > 0.0:
		# Auto-follow: drift toward the direction of travel, weighted by sideways motion.
		var cam_right := Basis(Vector3.UP, yaw) * Vector3.RIGHT
		var lateral := h_vel.normalized().dot(cam_right)
		yaw -= lateral * Settings.auto_follow * 1.1 * delta
	# Vertical framing (Mario rule).
	if player.is_grounded():
		_ground_ref = p.y
	var fy := _ground_ref
	if p.y > _ground_ref + VERTICAL_SLACK:
		fy = p.y - VERTICAL_SLACK
	elif p.y < _ground_ref:
		fy = p.y
	var ahead_target := h_vel.normalized() * LOOK_AHEAD * clampf(h_vel.length() / 7.0, 0.0, 1.0) if h_vel.length() > 0.5 else Vector3.ZERO
	_look_ahead = _look_ahead.lerp(ahead_target, 1.0 - exp(-2.5 * delta))
	var goal := Vector3(p.x, fy + FOCUS_HEIGHT, p.z) + _look_ahead
	if locked:
		var mid := (p + player.lock_target.global_position) * 0.5
		goal = Vector3(mid.x, goal.y, mid.z)
	var k_h := 1.0 - exp(-10.0 * delta)
	var k_v := 1.0 - exp(-5.0 * delta)
	_focus = Vector3(lerpf(_focus.x, goal.x, k_h), lerpf(_focus.y, goal.y, k_v), lerpf(_focus.z, goal.z, k_h))
	# Never let a fast launch or drop carry the hero out of frame.
	_focus.y = clampf(_focus.y, p.y - 1.2, p.y + FOCUS_HEIGHT + 2.5)
	player.camera_yaw = yaw
	_trauma = maxf(_trauma - delta * 1.6, 0.0)
	_apply()


func _apply() -> void:
	global_position = _focus
	_yaw_node.rotation = Vector3(0.0, yaw, 0.0)
	_pitch_node.rotation = Vector3(pitch, 0.0, 0.0)
	var shake := _trauma * _trauma * Settings.screen_shake
	if camera != null:
		camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.35
		camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.35
