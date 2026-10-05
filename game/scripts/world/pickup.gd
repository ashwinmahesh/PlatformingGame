class_name Pickup
extends Area3D
## Hearts and Glimmer Seeds. They bob and glint so they read as interactive (plan §10.1).

enum Kind { HEART, SEED, SHARD }

var kind: Kind = Kind.HEART
var seed_id: StringName = &""
var _visual: Node3D
var _t: float = 0.0


static func spawn_heart(parent: Node, at: Vector3) -> Pickup:
	var p := Pickup.new()
	p.kind = Kind.HEART
	parent.add_child(p)
	p.global_position = at
	return p


## A Star Shard (Build 4 open worlds): three open the world's goal.
static func spawn_shard(parent: Node, at: Vector3, id: StringName) -> Pickup:
	if Progress.has_shard(id):
		return null
	var p := Pickup.new()
	p.kind = Kind.SHARD
	p.seed_id = id
	p.position = at
	parent.add_child(p)
	return p


static func spawn_seed(parent: Node, at: Vector3, id: StringName) -> Pickup:
	if Progress.has_seed(id):
		return null
	var p := Pickup.new()
	p.kind = Kind.SEED
	p.seed_id = id
	p.position = at
	parent.add_child(p)
	return p


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER_BODY
	var s := SphereShape3D.new()
	s.radius = 0.8 if kind == Kind.SHARD else (0.6 if kind == Kind.SEED else 0.5)
	var cs := CollisionShape3D.new()
	cs.shape = s
	cs.position.y = 0.4
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	if kind == Kind.HEART:
		for side: float in [-1.0, 1.0]:
			var lobe := SphereMesh.new()
			lobe.radius = 0.16
			lobe.height = 0.32
			Kit.mesh_instance(_visual, lobe, Kit.mat(&"roof_red", 0.02), Vector3(0.11 * side, 0.5, 0.0))
		var tip := PrismMesh.new()
		tip.size = Vector3(0.42, 0.3, 0.22)
		var t := Kit.mesh_instance(_visual, tip, Kit.mat(&"roof_red", 0.02), Vector3(0.0, 0.33, 0.0))
		t.rotation.z = PI
	elif kind == Kind.SHARD:
		var star := Kit.mesh_instance(_visual, GoalStar.star_mesh(0.7, 0.32, 0.25), Kit.mat(&"portal_teal", 0.04), Vector3(0.0, 0.9, 0.0))
		star.name = "Star"
		var beam := CylinderMesh.new()
		beam.top_radius = 0.5
		beam.bottom_radius = 0.5
		beam.height = 30.0
		beam.cap_top = false
		beam.cap_bottom = false
		Kit.mesh_instance(self, beam, Fx.fx_mat(Color(Palette.color(&"portal_teal"), 0.18)), Vector3(0.0, 15.0, 0.0))
		var light := OmniLight3D.new()
		light.light_color = Palette.color(&"portal_teal")
		light.omni_range = 6.0
		light.light_energy = 1.5
		light.position.y = 1.0
		add_child(light)
		Kit.label(self, Vector3(0.0, 2.4, 0.0), "Star Shard", 32)
	else:
		var core := SphereMesh.new()
		core.radius = 0.24
		core.height = 0.44
		Kit.mesh_instance(_visual, core, Kit.mat(&"gold", 0.03), Vector3(0.0, 0.45, 0.0))
		for i in 3:
			var petal := SphereMesh.new()
			petal.radius = 0.14
			petal.height = 0.06
			var pm := Kit.mesh_instance(_visual, petal, Kit.mat(&"portal_teal", 0.015), Vector3(0.0, 0.72, 0.0))
			pm.rotation = Vector3(0.6, i * TAU / 3.0, 0.0)
			pm.position += Basis(Vector3.UP, i * TAU / 3.0) * Vector3(0.0, 0.0, 0.12)
		var light := OmniLight3D.new()
		light.light_color = Palette.color(&"gold")
		light.omni_range = 3.0
		light.light_energy = 0.8
		light.position.y = 0.5
		add_child(light)
	body_entered.connect(_on_body_entered)


func _shards_required(world_id: StringName) -> int:
	var w := Progress.world_def(world_id)
	return w.shards_required if w != null else 3


func _process(delta: float) -> void:
	_t += delta
	_visual.position.y = sin(_t * 2.5) * 0.12
	_visual.rotation.y += delta * 1.8


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p == null or p.state == Player.State.DEAD:
		return
	if kind == Kind.HEART:
		if p.hp >= p.max_hp:
			return
		p.heal(2)
		AudioDirector.play(&"heart")
	elif kind == Kind.SHARD:
		Progress.collect_shard(seed_id)
		AudioDirector.play(&"seed")
		Fx.burst(get_parent(), global_position + Vector3.UP, Palette.color(&"portal_teal"), 28, 5.0, 0.12, -3.0, 1.0)
		var level := get_tree().get_first_node_in_group(&"hud") as Hud
		var wid := Router.current_scene_id
		if level != null:
			level.show_banner("Star Shard!  %d / %d" % [Progress.world_shard_count(wid), _shards_required(wid)], 2.0)
		Telemetry.log_event("shard", {"id": String(seed_id)})
	else:
		Progress.collect_seed(seed_id)
		AudioDirector.play(&"seed")
		Fx.burst(get_parent(), global_position + Vector3.UP * 0.5, Palette.color(&"gold"), 20, 4.0, 0.1, -3.0, 0.8)
		Events.notice.emit("Glimmer Seed! (%d)" % Progress.seed_count())
		Telemetry.log_event("seed", {"id": String(seed_id)})
	queue_free()
