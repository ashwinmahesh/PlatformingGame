class_name Honker
extends Dino
## World 9 (Dinodew Jungle): a parasaurolophus who ambles round a little loop near the village.
## Come close and it notices you: it stops, honks through its crest and hops for joy, then
## wanders on. Friendly; its body is solid, so you walk round it rather than through it.

const NOTICE := 7.0
const COOLDOWN := 6.0

var _cool: float = 0.0
var _hop_left: float = 0.0


func _init() -> void:
	species = &"honker"
	speed = 1.3
	calm = 0.6
	walk_clip = &"Walk"
	stop_clip = &"Idle"


func _ready() -> void:
	super._ready()
	tick(0.0)
	var torso := bone_local("Torso").origin
	add_piece("Torso", Transform3D(Basis(), torso), Vector3(2.0, 2.2, 4.4) * model_scale, &"skin")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_cool = maxf(_cool - delta, 0.0)
	if _hop_left > 0.0:
		_hop_left -= delta
		if _hop_left <= 0.0:
			paused = false
			play(walk_clip, 0.4)
		return
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	if p == null or _cool > 0.0:
		return
	if p.global_position.distance_to(global_position) < NOTICE * model_scale:
		_cool = COOLDOWN
		_hop_left = 1.4
		paused = true
		play(&"Jump", 0.15)
		AudioDirector.play(&"boss_roar", -10.0, 2.2)
		Fx.burst(get_parent(), bone_point("Head") + Vector3.UP * 0.8, Palette.color(&"candy_pink"), 8, 2.5, 0.15, -2.0, 0.8)
