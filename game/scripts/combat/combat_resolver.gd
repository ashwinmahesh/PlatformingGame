class_name CombatResolver
extends Node
## One resolver per level (plan §4.1). Hitboxes and hurtboxes only report overlaps; this node
## processes them once per tick, after every actor has moved, in a fixed order:
## 1. player attacks (incl. bounces)  2. reflections  3. enemy attacks on the player  4. pickups.
## Ties go to the player: contact damage from an enemy hit/bounced/killed this tick is dropped.

var player: Player
var feet_shape: SphereShape3D
## Enemies the player hit this tick (instance ids). Exposed for tests.
var hit_this_tick: Dictionary[int, bool] = {}
## Actors the current Thunderclap already hit (one hit per clap, whatever the actor).
var _clap_seen: int = -1
var _clap_hit: Dictionary[int, bool] = {}


func _ready() -> void:
	process_physics_priority = 100
	feet_shape = SphereShape3D.new()
	feet_shape.radius = 0.38


func _physics_process(_delta: float) -> void:
	hit_this_tick.clear()
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return
	if player.state in [Player.State.DEAD, Player.State.FROZEN]:
		return
	_player_attacks()
	_magic_attacks()
	_land_bounces()
	_enemy_attacks()


func _query(shape: Shape3D, xform: Transform3D, mask: int) -> Array[Area3D]:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = xform
	q.collision_mask = mask
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var out: Array[Area3D] = []
	for r in player.get_world_3d().direct_space_state.intersect_shape(q, 32):
		var a := r["collider"] as Area3D
		if a != null and a.has_meta(&"actor") and not a in out:
			out.append(a)
	return out


static func actor_of(area: Area3D) -> Node:
	var actor: Variant = area.get_meta(&"actor")
	return actor as Node if actor is Node and is_instance_valid(actor) else null


func _player_attacks() -> void:
	if player.hitstop_ticks > 0:
		return
	if player.is_sword_active():
		player.sword_shape.radius = player.attack.radius
		var atk := player.current_attack_dict()
		for area in _query(player.sword_shape, player.sword_transform(), Layers.ENEMY_HURTBOX | Layers.REFLECTABLE):
			var actor := actor_of(area)
			if actor == null or not actor.has_method(&"receive_player_attack"):
				continue
			var res: Dictionary = actor.call(&"receive_player_attack", atk, area)
			if bool(res.get("blocked", false)):
				# Shields push you back instead of taking the hit (Armorling).
				hit_this_tick[actor.get_instance_id()] = true
				player.recoil((actor as Node3D).global_position)
			elif bool(res.get("hit", false)):
				hit_this_tick[actor.get_instance_id()] = true
				_impact(actor, area, int(atk["hitstop"]))
	elif player.is_plunge_active():
		var atk := player.current_attack_dict()
		var best_bounce := 0.0
		for area in _query(player.plunge_shape, player.plunge_transform(), Layers.ENEMY_HURTBOX | Layers.BOUNCE):
			var actor := actor_of(area)
			if actor == null or not actor.has_method(&"receive_player_attack"):
				continue
			# The bounce is resolved from the contact before the defeat is processed.
			var res: Dictionary = actor.call(&"receive_player_attack", atk, area)
			best_bounce = maxf(best_bounce, float(res.get("bounce", 0.0)))
			if bool(res.get("hit", false)):
				hit_this_tick[actor.get_instance_id()] = true
				_impact(actor, area, int(atk["hitstop"]))
		if best_bounce > 0.0:
			player.bounce(best_bounce, true)


## Build 5 magic: Fireballs (one hit, then they pop) and the Thunderclap ring.
func _magic_attacks() -> void:
	for n in get_tree().get_nodes_in_group(&"player_projectile"):
		var fb := n as Fireball
		if fb == null or fb.done:
			continue
		var atk := fb.attack_dict()
		for area in _query(fb.shape, Transform3D(Basis(), fb.global_position), Layers.ENEMY_HURTBOX | Layers.REFLECTABLE):
			var actor := actor_of(area)
			if actor == null or not actor.has_method(&"receive_player_attack"):
				continue
			var res: Dictionary = actor.call(&"receive_player_attack", atk, area)
			if bool(res.get("hit", false)) or bool(res.get("blocked", false)):
				hit_this_tick[actor.get_instance_id()] = true
				if bool(res.get("hit", false)) and not bool(res.get("blocked", false)):
					AudioDirector.play(&"hit", -4.0)
				fb.pop()
				break
	if player.clap_active():
		if player.clap_id != _clap_seen:
			_clap_seen = player.clap_id
			_clap_hit.clear()
		var atk := player.clap_attack_dict()
		var s := SphereShape3D.new()
		s.radius = Player.CLAP_RADIUS
		for area in _query(s, Transform3D(Basis(), player.global_position + Vector3.UP * 0.6), Layers.ENEMY_HURTBOX | Layers.REFLECTABLE):
			var actor := actor_of(area)
			if actor == null or not actor.has_method(&"receive_player_attack") or _clap_hit.has(actor.get_instance_id()):
				continue
			_clap_hit[actor.get_instance_id()] = true
			var res: Dictionary = actor.call(&"receive_player_attack", atk, area)
			if bool(res.get("hit", false)):
				hit_this_tick[actor.get_instance_id()] = true


func _impact(actor: Node, area: Area3D, hitstop: int) -> void:
	player.add_hitstop(hitstop)
	if actor.has_method(&"add_hitstop"):
		actor.call(&"add_hitstop", hitstop)
	AudioDirector.play(&"hit", -2.0)
	Fx.burst(get_parent(), area.global_position + Vector3.UP * 0.3, Palette.color(&"gold"), 8, 4.5, 0.08, -4.0, 0.3)
	if player.camera_rig != null and player.camera_rig.has_method(&"add_trauma"):
		player.camera_rig.call(&"add_trauma", 0.18)


## Landing on a permanent bounce surface (Springcap) or a flattened Bouncer without plunging.
func _land_bounces() -> void:
	if player.state not in [Player.State.NORMAL, Player.State.ATTACK] or player.velocity.y > 0.5:
		return
	var xf := Transform3D(Basis(), player.global_position + Vector3.UP * 0.15)
	for area in _query(feet_shape, xf, Layers.BOUNCE):
		var actor := actor_of(area)
		if actor != null and actor.has_method(&"on_player_land"):
			var h := float(actor.call(&"on_player_land", player))
			if h > 0.0:
				player.bounce(h, false)
				return


func _enemy_attacks() -> void:
	if player.invuln_left > 0.0:
		return
	var worst: Dictionary = {}
	for n in get_tree().get_nodes_in_group(&"enemy_attacker"):
		if hit_this_tick.has(n.get_instance_id()) or not n.has_method(&"damage_to_player"):
			continue
		var d: Dictionary = n.call(&"damage_to_player", player)
		if int(d.get("halves", 0)) > int(worst.get("halves", 0)):
			worst = d
	if not worst.is_empty():
		player.take_damage(int(worst["halves"]), worst.get("from", player.global_position) as Vector3, bool(worst.get("heavy", false)), str(worst.get("cause", "enemy")))
