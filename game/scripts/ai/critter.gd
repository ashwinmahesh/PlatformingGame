class_name Critter
extends CharacterBody3D
## Shared base for the monsters (Build 6 roster: Puffcap, Batling, Shieldknight, Mimic, Boulderkin, Big Gloplet; plus Jellyfloat, Pricklepot, Snapper Crab):
## HP, hit de-duplication, flash, defeat, contact damage against a drawn ellipsoid, and a sleep
## radius so far-away brains don't run. Each monster is a small tick-timed state machine.

signal defeated(critter: Critter)

const WAKE_RADIUS := 45.0

var max_hp: int = 2
var hp: int = 2
var contact_halves: int = 1
## Contact ellipsoid: horizontal radius and half-height, centred body_center above the origin.
var body_radius: float = 0.6
var body_half_height: float = 0.5
var body_center: float = 0.5
var uses_gravity: bool = true
var drop_heart_chance: float = 0.3
var color_name: StringName = &"slime_green"
## Build 6 asset swap: a Quaternius monster model shown instead of the built body
## ([path, height in metres, yaw]); behaviour is unchanged.
var model_spec: Array = []
var _model: Node3D
var home: Vector3
var state: int = 0
var state_ticks: int = 0
var hitstop_ticks: int = 0
var facing: Vector3 = Vector3.FORWARD
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _visual: Node3D
var _flash_mats: Array[ShaderMaterial] = []
var _hurtbox: Area3D
var _debug: Label3D
var _player: Player
var _last_hit_id: int = -1
var _dead: bool = false
## Build 7 magic: Frost Burst freezes, Mighty Roar stuns (ticks left). Frozen or stunned monsters
## don't think, can't hurt you, and take an extra point from every hit.
var frozen_ticks: int = 0
var stunned_ticks: int = 0
var _ice: MeshInstance3D


func _ready() -> void:
	add_to_group(&"enemy")
	add_to_group(&"lockable")
	add_to_group(&"enemy_attacker")
	collision_layer = Layers.ENEMY_BODY
	collision_mask = Layers.WORLD | Layers.ENEMY_BODY
	home = global_position
	rng.seed = hash(home)
	hp = max_hp
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = body_radius * 0.8
	cs.shape = shape
	cs.position.y = body_radius * 0.8
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	build_body()
	if not model_spec.is_empty():
		_use_model()
	_hurtbox = Area3D.new()
	_hurtbox.collision_layer = Layers.ENEMY_HURTBOX
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.set_meta(&"actor", self)
	var hs := SphereShape3D.new()
	hs.radius = maxf(body_radius, body_half_height) + 0.1
	Kit.add_shape(_hurtbox, hs, Vector3(0.0, body_center, 0.0))
	add_child(_hurtbox)
	_debug = Kit.label(self, Vector3(0.0, body_center + body_half_height + 1.2, 0.0), "", 30)


# --- Overridables -----------------------------------------------------------------------------

func build_body() -> void:
	pass


func think(_delta: float) -> void:
	pass


func animate(_delta: float) -> void:
	pass


func state_name() -> String:
	return str(state)


## Return false while the monster is harmless (stunned, flattened, dormant).
func harmful() -> bool:
	return true


## Override to block or react. Default: take the hit.
func on_hit(atk: Dictionary) -> Dictionary:
	take(int(atk.get("damage", 1)), atk.get("from", global_position) as Vector3)
	return {"hit": true}


## Where the model goes (subclasses that move a sub-node, like the Pricklepot's pop-up, override).
func model_parent() -> Node3D:
	return _visual


func _use_model() -> void:
	var parent := model_parent()
	for n in parent.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).visible = false
	var path := Models.Q_MONSTERS + str(model_spec[0]) + ".gltf"
	var h := float(model_spec[1])
	var b := Models.model_bounds(path)
	_model = Models.spawn(parent, path, Vector3.ZERO, float(model_spec[2]) if model_spec.size() > 2 else 0.0, h / maxf(b.size.y, 0.01), 0.03)
	Models.play(_model, [&"Idle", &"Flying_Idle"])
	for n in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m != null:
				m = m.duplicate() as ShaderMaterial
				mi.set_surface_override_material(i, m)
				_flash_mats.append(m)


## Picks walk/idle clips from movement (models only).
func _animate_model() -> void:
	if _model == null:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.6
	if moving:
		Models.play(_model, [&"Run" if Vector2(velocity.x, velocity.z).length() > 5.0 else &"Walk", &"Fast_Flying", &"Walk"])
	else:
		Models.play(_model, [&"Idle", &"Flying_Idle"])


# --- Helpers ----------------------------------------------------------------------------------

func player_ref() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func set_state(s: int) -> void:
	state = s
	state_ticks = 0


func flat_to(target: Vector3) -> Vector3:
	var d := target - global_position
	d.y = 0.0
	return d


func face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.01:
		facing = dir.normalized()


func can_see(p: Player, distance: float) -> bool:
	if p == null or p.state in [Player.State.DEAD, Player.State.FROZEN]:
		return false
	var to := p.global_position - global_position
	if to.length() > distance:
		return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * body_center, p.global_position + Vector3.UP * 0.8, Layers.WORLD)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Track a material so hits can flash it.
func flashy(color: StringName, outline: float = 0.04, slime: bool = false) -> ShaderMaterial:
	var m := Kit.slime_mat(color, outline) if slime else Kit.unique_mat(color, outline)
	_flash_mats.append(m)
	return m


func flash(c: Color = Color.WHITE, amount: float = 1.0) -> void:
	for m in _flash_mats:
		m.set_shader_parameter(&"flash_color", c)
		m.set_shader_parameter(&"flash", amount)


func ball(parent: Node3D, radius: float, color: StringName, pos: Vector3, outline: float = 0.03) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	return Kit.mesh_instance(parent, s, flashy(color, outline), pos)


func take(dmg: int, from: Vector3) -> void:
	if _dead:
		return
	hp -= dmg
	flash(Color.WHITE, 1.0)
	create_tween().tween_method(func(v: float) -> void: flash(Color.WHITE, v), 1.0, 0.0, 0.2)
	var away := flat_to(global_position * 2.0 - from)
	if away.length() > 0.01:
		velocity = away.normalized() * 5.0 + Vector3.UP * (3.0 if uses_gravity else 0.0)
	if hp <= 0:
		defeat()
	else:
		AudioDirector.play(&"slime_hurt", -3.0, 1.2)


func defeat() -> void:
	if _dead:
		return
	_dead = true
	_hurtbox.set_deferred(&"monitorable", false)
	Fx.burst(get_parent(), global_position + Vector3.UP * body_center, Palette.color(color_name), 18, 5.0, 0.13, -9.0, 0.6)
	AudioDirector.play(&"poof")
	Telemetry.log_event("enemy_defeated", {"id": String(name), "pos": global_position})
	if rng.randf() < drop_heart_chance:
		Pickup.spawn_heart(get_parent(), global_position + Vector3.UP * 0.5)
	defeated.emit(self)
	queue_free()


# --- Engine -----------------------------------------------------------------------------------

func is_lockable() -> bool:
	return not _dead and visible


func add_hitstop(ticks: int) -> void:
	hitstop_ticks = maxi(hitstop_ticks, ticks)


func _physics_process(delta: float) -> void:
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		return
	var p := player_ref()
	if p == null or p.global_position.distance_to(global_position) > WAKE_RADIUS:
		return
	if frozen_ticks > 0 or stunned_ticks > 0:
		frozen_ticks = maxi(frozen_ticks - 1, 0)
		stunned_ticks = maxi(stunned_ticks - 1, 0)
		if _ice != null:
			_ice.visible = frozen_ticks > 0
		velocity.x = 0.0
		velocity.z = 0.0
		if uses_gravity and not is_on_floor():
			velocity.y -= 30.0 * delta
		elif not uses_gravity:
			velocity.y = -4.0 if stunned_ticks > 0 else 0.0
		move_and_slide()
		return
	state_ticks += 1
	think(delta)
	if uses_gravity and not is_on_floor():
		velocity.y -= 30.0 * delta
	move_and_slide()
	if global_position.y < home.y - 30.0:
		defeat()
	animate(delta)
	_animate_model()
	_visual.basis = Basis.looking_at(facing, Vector3.UP).scaled(_visual.basis.get_scale())
	_debug.visible = DevTools.ai_debug
	if _debug.visible:
		_debug.text = "%s %d hp%d" % [state_name(), state_ticks, hp]


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if _dead:
		return {}
	var id := int(atk.get("id", -1))
	var plunge := StringName(str(atk.get("kind", ""))) == &"plunge"
	var bounce_h := float(atk.get("bounce", 2.2)) if plunge else 0.0
	if id == _last_hit_id:
		return {"bounce": bounce_h}
	_last_hit_id = id
	var kind := StringName(str(atk.get("kind", "")))
	if frozen_ticks > 0 or stunned_ticks > 0:
		take(int(atk.get("damage", 1)) + 1, atk.get("from", global_position) as Vector3)
		return {"hit": true}
	if kind == &"frost":
		_freeze(180)
	elif kind == &"roar":
		stunned_ticks = 150
		Fx.burst(get_parent(), global_position + Vector3.UP * (body_center + body_half_height + 0.4), Palette.color(&"gold"), 6, 1.5, 0.1, 0.0, 0.6)
	elif kind == &"vine" and float(atk.get("knockback", 0.0)) < 0.0:
		# The vine yanks small monsters toward you.
		var pull := flat_to(atk.get("from", global_position) as Vector3)
		if pull.length() > 2.0 and max_hp <= 3:
			global_position += pull.normalized() * minf(3.0, pull.length() - 1.5)
	var res := on_hit(atk)
	if plunge and not res.has("bounce"):
		res["bounce"] = bounce_h
	return res


func _freeze(ticks: int) -> void:
	frozen_ticks = ticks
	if _ice == null:
		var s := SphereMesh.new()
		s.radius = maxf(body_radius, body_half_height) + 0.25
		s.height = s.radius * 2.0
		_ice = Kit.mesh_instance(self, s, Fx.fx_mat(Color(Palette.color(&"water_light"), 0.45)), Vector3(0.0, body_center, 0.0))
	_ice.visible = true
	AudioDirector.play(&"hit", -2.0, 1.8)


## Shield-breaking magic: Thunderclap and the Mighty Roar.
static func shakes(kind: StringName) -> bool:
	return kind == &"thunder" or kind == &"roar"


func damage_to_player(p: Player) -> Dictionary:
	if frozen_ticks > 0 or stunned_ticks > 0:
		return {}
	if _dead or not harmful():
		return {}
	var rx := body_radius + 0.33
	var ry := body_half_height + 0.6
	var d := p.global_position + Vector3.UP * 0.6 - (global_position + Vector3.UP * body_center)
	if (d.x * d.x + d.z * d.z) / (rx * rx) + (d.y * d.y) / (ry * ry) >= 1.0:
		return {}
	return {"halves": contact_halves, "from": global_position, "cause": String(name)}
