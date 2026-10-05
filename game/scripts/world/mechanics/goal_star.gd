class_name GoalStar
extends Area3D
## The Grand Star at the end of a platforming world (Build 4). Touching it completes the world:
## the victory commit runs first (plan §9.8), then a celebration, then home to Mossbrook.

var world_id: StringName
var _visual: Node3D
var _taken: bool = false
var _t: float = 0.0


static func star_mesh(outer: float = 1.0, inner: float = 0.45, depth: float = 0.35) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var ring: Array[Vector3] = []
	for i in 10:
		var a := float(i) / 10.0 * TAU + PI * 0.5
		var r := outer if i % 2 == 0 else inner
		ring.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	for side: float in [1.0, -1.0]:
		var apex := Vector3(0.0, 0.0, depth * side)
		for i in 10:
			var a := ring[i]
			var b := ring[(i + 1) % 10]
			var n := (b - a).cross(apex - a).normalized() * side
			if side > 0.0:
				verts.append_array([apex, b, a])
			else:
				verts.append_array([apex, a, b])
			norms.append_array([n, n, n])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER_BODY
	var s := SphereShape3D.new()
	s.radius = 1.6
	Kit.add_shape(self, s, Vector3(0.0, 1.6, 0.0))
	_visual = Node3D.new()
	_visual.position.y = 1.8
	add_child(_visual)
	var mi := Kit.mesh_instance(_visual, star_mesh(1.3, 0.6, 0.45), Kit.mat(&"gold", 0.05))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var light := OmniLight3D.new()
	light.light_color = Palette.color(&"gold")
	light.light_energy = 2.5
	light.omni_range = 9.0
	light.position.y = 1.8
	add_child(light)
	var sparkles := CPUParticles3D.new()
	sparkles.amount = 20
	sparkles.lifetime = 1.2
	sparkles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkles.emission_sphere_radius = 1.6
	sparkles.gravity = Vector3(0.0, 0.6, 0.0)
	var dot := SphereMesh.new()
	dot.radius = 0.07
	dot.height = 0.14
	sparkles.mesh = dot
	sparkles.material_override = Fx.fx_mat(Palette.color(&"gold"))
	sparkles.position.y = 1.8
	add_child(sparkles)
	Kit.label(self, Vector3(0.0, 4.0, 0.0), "Grand Star", 40)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = 1.8 + sin(_t * 2.0) * 0.2


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p == null or _taken or p.state == Player.State.DEAD:
		return
	_taken = true
	var first := Progress.commit_victory(world_id)
	Telemetry.log_event("star", {"world": String(world_id), "first_clear": first})
	p.set_talking(true)
	p.refill()
	p.cheer()
	AudioDirector.play_music(&"victory", 0.2)
	AudioDirector.play(&"seed")
	Fx.confetti(get_parent(), global_position + Vector3.UP * 2.0)
	var hud := get_tree().get_first_node_in_group(&"hud") as Hud
	if hud != null:
		hud.show_banner("Grand Star!" + ("   New heart!" if first else ""), 2.5)
	create_tween().tween_property(_visual, "scale", Vector3.ONE * 2.2, 0.8).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(3.4).timeout
	if is_inside_tree():
		Router.go_to(Progress.HUB_SCENE, &"hub_rootway_exit")
