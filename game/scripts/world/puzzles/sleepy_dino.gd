class_name SleepyDino
extends Node3D
## Build 9 puzzle (Dinodew Jungle; creatures that react to the hero): Snoozer, a stegosaurus who
## naps sunk deep in his haystack. Golden caps on his back-plates make a staircase up to the
## saddle on his back, and an alarm gong hangs on the saddle. Ring it (sword, Fireball,
## Thunderclap, or a Mighty Roar from nearby): he yawns, stands up on the haystack and lifts the
## saddle high, stays up a while, then settles back down for another nap.
## The node's +Z is the way he faces; local y 0 is the ground the haystack stands on.

signal woke

enum S { ASLEEP, WAKING, AWAKE, SETTLING }

const SCALE := 0.9
const BALE_TOP := 3.0
const SINK := 4.4
const RISE_TIME := 3.0
const AWAKE_TIME := 14.0
const SETTLE_TIME := 4.0
const SPINE: Array[String] = ["Tail3", "Tail2", "Tail1", "Back", "Hips", "Torso", "Shoulders"]

var state: S = S.ASLEEP
var dino: Dino
var deck: AnimatableBody3D
var pads: Array[AnimatableBody3D] = []
var _t: float = 0.0
var _zzz: Label3D
var _gong: Node3D
var _last_hit: int = -1


func _ready() -> void:
	_build_haystack()
	dino = Dino.new()
	dino.species = &"stego"
	dino.model_scale = SCALE
	dino.clip = &""
	dino.calm = 0.3
	dino.colours = {"DarkBrown": &"roof_blue", "Brown": &"gloop_pink", "LightBrown": &"cloth_cream"}
	dino.position = Vector3(0.0, BALE_TOP - SINK, 0.0)
	add_child(dino)
	var skin := dino.skin_points()
	# A golden cap on each plate tip, rising tail to shoulders: the back-plate staircase.
	for zt: float in [-8.6, -6.8, -5.6, -3.9]:
		var tip := Vector3(0.0, -INF, zt)
		for q in skin:
			if absf(q.z - zt) < 0.45 and q.y > tip.y:
				tip = q
		pads.append(dino.add_piece(dino.nearest_bone(tip, SPINE), Transform3D(Basis(), tip + Vector3.UP * 0.13), Vector3(1.8, 0.26, 1.8), &"pad", &"gold"))
	# The saddle sits on the tallest plates.
	var top := -INF
	for q in skin:
		if q.z > -2.6 and q.z < 2.8 and absf(q.x) < 2.3:
			top = maxf(top, q.y)
	var deck_c := Vector3(0.0, top + 0.08 + 0.18, 0.1)
	deck = dino.add_piece("Body", Transform3D(Basis(), deck_c), Vector3(4.6, 0.36, 5.2), &"saddle")
	for side: float in [-1.0, 1.0]:
		var rail := dino.add_piece("Body", Transform3D(Basis(), deck_c + Vector3(side * 2.2, 0.55, 0.0)), Vector3(0.2, 0.75, 5.2), &"saddle")
		rail.name = "Rail"
	var front := dino.add_piece("Body", Transform3D(Basis(), deck_c + Vector3(0.0, 0.55, 2.5)), Vector3(4.6, 0.75, 0.2), &"saddle")
	front.name = "Rail"
	_build_gong()
	_zzz = Kit.label(self, Vector3(0.0, 6.5, 6.0), "z Z z", 64)
	_zzz.modulate = Palette.color(&"crystal_violet")


func _build_haystack() -> void:
	var bale := Kit.pillar(self, Vector3(0.0, BALE_TOP, -3.0), 7.5, BALE_TOP, &"thatch", &"wood_plank")
	bale.name = "Haystack"
	for i in 14:
		var a := float(i) / 14.0 * TAU
		Kit.blob(self, Vector3(cos(a) * 7.4, BALE_TOP - 0.2, -3.0 + sin(a) * 7.4), 0.7, &"thatch" if i % 2 == 0 else &"wood_plank")
	# Hay-bale steps up onto the stack (behind him, where his tail lies).
	Kit.block(self, Vector3(-4.0, 1.5, -11.6), Vector3(3.2, 1.5, 3.2), &"thatch", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")
	Kit.block(self, Vector3(4.6, 1.5, -10.6), Vector3(3.2, 1.5, 3.2), &"thatch", Layers.WORLD | Layers.CAMERA_BLOCKER, &"wood_plank")


func _build_gong() -> void:
	_gong = Node3D.new()
	deck.add_child(_gong)
	_gong.position = Vector3(0.0, 0.18, 1.8)
	for side: float in [-1.0, 1.0]:
		Kit.mesh_instance(_gong, RoundMesh.box(Vector3(0.18, 2.2, 0.18), 0.05), Kit.mat(&"bark_dark"), Vector3(side * 1.0, 1.1, 0.0))
	Kit.mesh_instance(_gong, RoundMesh.box(Vector3(2.3, 0.18, 0.18), 0.05), Kit.mat(&"bark_dark"), Vector3(0.0, 2.2, 0.0))
	var disc := CylinderMesh.new()
	disc.top_radius = 0.75
	disc.bottom_radius = 0.75
	disc.height = 0.12
	var d := Kit.mesh_instance(_gong, disc, Kit.mat(&"gold", 0.03), Vector3(0.0, 1.35, 0.0))
	d.rotation.x = PI * 0.5
	var a := Area3D.new()
	a.collision_layer = Layers.REFLECTABLE
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta(&"actor", self)
	var s := SphereShape3D.new()
	s.radius = 1.3
	Kit.add_shape(a, s, Vector3(0.0, 1.35, 0.0))
	_gong.add_child(a)


## Any hit on the gong (or a roar that reaches it) wakes him.
func receive_player_attack(atk: Dictionary, _area: Area3D) -> Dictionary:
	var id := int(atk.get("id", -1))
	if id == _last_hit:
		return {}
	_last_hit = id
	AudioDirector.play(&"gate", 0.0, 1.6)
	create_tween().tween_property(_gong, "rotation:x", 0.0, 0.5).from(0.35)
	wake()
	return {"hit": true}


func wake() -> void:
	if state != S.ASLEEP:
		if state == S.AWAKE:
			_t = 0.0
		return
	state = S.WAKING
	_t = 0.0
	dino.play(&"Idle", 0.5, 0.8)
	AudioDirector.play(&"boss_roar", -8.0, 1.5)
	woke.emit()


func is_awake() -> bool:
	return state == S.AWAKE


## Height of the saddle's top above this node, asleep and awake.
func deck_top_local() -> float:
	return to_local(deck.global_position).y + 0.18


func _physics_process(delta: float) -> void:
	_t += delta
	var low := BALE_TOP - SINK
	match state:
		S.ASLEEP:
			dino.position.y = low + sin(_t * 1.3) * 0.04
			_zzz.visible = true
			_zzz.position.y = 3.2 + fmod(_t * 0.6, 1.5)
		S.WAKING:
			_zzz.visible = false
			dino.position.y = lerpf(low, BALE_TOP, smoothstep(0.0, RISE_TIME, _t))
			if _t >= RISE_TIME:
				state = S.AWAKE
				_t = 0.0
				AudioDirector.play(&"land", 0.0, 0.5)
		S.AWAKE:
			dino.position.y = BALE_TOP
			if _t >= AWAKE_TIME:
				state = S.SETTLING
				_t = 0.0
				AudioDirector.play(&"boss_roar", -12.0, 1.8)
		S.SETTLING:
			dino.position.y = lerpf(BALE_TOP, low, smoothstep(0.0, SETTLE_TIME, _t))
			if _t >= SETTLE_TIME:
				state = S.ASLEEP
				_t = 0.0
				dino.play(&"")
