class_name WarpPipe
extends Node3D
## World 8 (Brickbloom Heights): a warp pipe. Plunge into its mouth, or stand on top and press E,
## and you whoosh through to its partner and pop out of that pipe's top. Pipes under water
## (`auto`) take you as soon as you swim into the mouth; exit-only pipes have a grate over them.
## `position` is the centre of the mouth (the pipe's top); the body runs down `height` metres.

signal warped(to: Vector3)

const KK := "res://assets/models/kk_platformer/"

var height: float = 2.4
## KayKit colour folder: green, red, yellow, blue.
var colour: String = "green"
var radius: float = 1.5
## Where you come out: the mouth of the partner pipe (world).
var target: Vector3 = Vector3.ZERO
var target_facing: Vector3 = Vector3.FORWARD
var enterable: bool = true
var auto: bool = false
var label_text: String = ""
var _busy: bool = false
var _last_id: int = -1


## Two pipes that lead to each other (either may be exit-only). Call once both are in the tree.
static func pair(a: WarpPipe, b: WarpPipe) -> void:
	a.target = b.global_position
	b.target = a.global_position
	var d := b.global_position - a.global_position
	d.y = 0.0
	if d.length() > 0.1:
		b.target_facing = -d.normalized()
		a.target_facing = d.normalized()


func _ready() -> void:
	add_to_group(&"warp_pipe")
	if enterable and not auto:
		add_to_group(&"interactable")
		set_meta(&"prompt", "Enter pipe")
	var body := Kit.static_body(self, Vector3(0.0, -height * 0.5, 0.0), Layers.WORLD)
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = height
	Kit.add_shape(body, cs)
	var rim := radius / 1.2
	var c := colour
	Models.fit(self, "%s%s/pipe_straight_A_%s.gltf" % [KK, c, c], Vector3(0.0, -rim * 0.9, 0.0), Vector3(radius * 1.66, maxf(height - rim * 0.9, 0.2), radius * 1.66))
	Models.fit(self, "%s%s/pipe_end_%s.gltf" % [KK, c, c], Vector3.ZERO, Vector3(radius * 2.0, rim, radius * 2.0))
	var mouth := CylinderMesh.new()
	mouth.top_radius = radius * 0.72
	mouth.bottom_radius = radius * 0.72
	mouth.height = 0.04
	Kit.mesh_instance(self, mouth, Kit.mat(&"ink_navy"), Vector3(0.0, -0.12, 0.0))
	if not enterable:
		for k in 3:
			Kit.mesh_instance(self, RoundMesh.box(Vector3(radius * 1.5, 0.12, 0.16), 0.04), Kit.mat(&"stone_dark"), Vector3(0.0, -0.05, (k - 1) * radius * 0.45))
	if label_text != "":
		Kit.label(self, Vector3(0.0, 2.2, 0.0), label_text, 26)
	if enterable:
		# Plunge into it: the Plunge checks bounce surfaces, so the mouth is one.
		var a := Area3D.new()
		a.collision_layer = Layers.BOUNCE
		a.collision_mask = 0
		a.monitoring = false
		a.set_meta(&"actor", self)
		var s := CylinderShape3D.new()
		s.radius = radius
		s.height = 1.4
		Kit.add_shape(a, s, Vector3(0.0, 0.5, 0.0))
		add_child(a)
	if auto:
		var sw := Area3D.new()
		sw.collision_layer = 0
		sw.collision_mask = Layers.PLAYER_BODY
		var s2 := CylinderShape3D.new()
		s2.radius = radius * 0.9
		s2.height = 1.8
		Kit.add_shape(sw, s2, Vector3(0.0, 0.6, 0.0))
		add_child(sw)
		sw.body_entered.connect(func(b: Node3D) -> void:
			if b is Player:
				warp(b as Player))


func interact(p: Player) -> void:
	var d := p.global_position - global_position
	if Vector2(d.x, d.z).length() < radius + 0.9 and d.y > -1.0:
		warp(p)


func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	if StringName(str(atk.get("kind", ""))) != &"plunge":
		return {}
	var id := int(atk.get("id", -1))
	if id == _last_id:
		return {}
	_last_id = id
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p != null:
		warp(p)
	return {}


## Down the pipe, through, and up out of the partner.
func warp(p: Player) -> void:
	if _busy or not enterable or p.state in [Player.State.DEAD, Player.State.FROZEN]:
		return
	_busy = true
	p.set_talking(true)
	p.velocity = Vector3.ZERO
	AudioDirector.play(&"warp", -2.0)
	Fx.burst(get_parent(), global_position + Vector3.UP * 0.4, Palette.color(&"cloth_cream"), 12, 3.0, 0.12, 0.0, 0.5)
	Telemetry.log_event("warp_pipe", {"from": global_position, "to": target})
	await get_tree().create_timer(0.3, true, true).timeout
	_busy = false
	if not is_instance_valid(p) or not p.is_inside_tree() or p.state == Player.State.DEAD:
		return
	p.respawn_at(target + Vector3.UP * 0.3, target_facing)
	p.invuln_left = maxf(p.invuln_left, 0.6)
	p.bounce(2.8, false)
	Fx.burst(get_parent(), target + Vector3.UP * 0.6, Palette.color(&"gold"), 14, 4.0, 0.1, -2.0, 0.6)
	warped.emit(target)
