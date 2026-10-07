class_name BalanceLift
extends WeightScale
## World 8 puzzle (the weight scale): the Great Brass Balance. The near pan (pan 1) carries a
## one-pip sandbag, so it rests on the ground and the far pan (pan 0) hangs high under a hopper
## holding a big three-pip weight. Bonk the brick over the near pan and the weight drops onto the
## far pan: three pips beat the sandbag and a hero, so whoever is standing on the near pan rides
## it right up to the crown on top of the pivot. Left alone for a few seconds, the weight is
## winched back up into the hopper and the brick slides back over the near pan.

signal weight_dropped
signal reset_done

## Fixed weight on each pan (the sandbag on the near pan).
var extra: Array[int] = [0, 1]
var hopper_weight: int = 3
var tilt_speed: float = 0.3
var reset_after: float = 3.5
var brick: BonkBrick
var loaded: bool = true
var _dropping: bool = false
var _idle: float = 0.0
var _brick_home: Vector3
var _brick_away: bool = false
var _iron: Node3D
var _chains: Array[MeshInstance3D] = []


func _ready() -> void:
	super._ready()
	# The sandbag rides the near pan, tucked in a corner.
	var bag := Node3D.new()
	bag.position = Vector3(pan_size.x * 0.5 - 0.9, 0.0, -pan_size.y * 0.5 + 0.9)
	_pans[1].add_child(bag)
	Kit.mesh_instance(bag, RoundMesh.box(Vector3(1.2, 1.0, 1.2), 0.35), Kit.mat(&"wood_plank", 0.03), Vector3(0.0, 0.5, 0.0))
	Kit.mesh_instance(bag, PipBlock.pip_mesh(Vector3(1.2, 1.0, 1.2), 1, 0.16), Kit.mat(&"bark_dark"), Vector3(0.0, 1.0, 0.0))
	# The hopper: a brass cradle high over the far pan, and the big weight in it.
	var hx := -spacing * 0.5
	for side: float in [-1.0, 1.0]:
		Kit.mesh_instance(self, RoundMesh.box(Vector3(0.3, 3.0, pan_size.y * 0.8), 0.1), Kit.mat(&"gold", 0.03), Vector3(hx + side * 1.8, _hopper_y() + 1.0, 0.0))
	Kit.mesh_instance(self, RoundMesh.box(Vector3(0.3, 0.3, pan_size.y * 0.8), 0.1), Kit.mat(&"gold", 0.03), Vector3(hx, _hopper_y() + 2.6, 0.0))
	_iron = Node3D.new()
	add_child(_iron)
	var ws := Vector3(2.6, 2.0, 2.6)
	Kit.mesh_instance(_iron, RoundMesh.box(ws, 0.4), Kit.mat(&"stone_dark", 0.04), Vector3(0.0, 1.0, 0.0))
	Kit.mesh_instance(_iron, PipBlock.pip_mesh(ws, hopper_weight, 0.26), Kit.mat(&"gold"), Vector3(0.0, 2.0, 0.0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.55
	Kit.mesh_instance(_iron, ring, Kit.mat(&"gold", 0.03), Vector3(0.0, 2.4, 0.0)).rotation.x = PI * 0.5
	_iron.position = Vector3(hx, _hopper_y(), 0.0)
	# Chains from the beam ends down to each pan.
	for i in 2:
		var c := Kit.mesh_instance(self, RoundMesh.box(Vector3(0.16, 1.0, 0.16), 0.05), Kit.mat(&"bark_dark"))
		_chains.append(c)
	# The brick over the near pan.
	brick = BonkBrick.new()
	brick.kind = BonkBrick.Kind.SWITCH
	brick.color_name = &"sunset_orange"
	_brick_home = Vector3(spacing * 0.5, 6.0, 0.0)
	brick.position = _brick_home
	add_child(brick)
	brick.bonked.connect(drop)
	_tilt = _target()
	_apply()


func _hopper_y() -> float:
	return travel + 1.6


func _weight(i: int) -> int:
	return super._weight(i) + extra[i]


func _target() -> float:
	return clampf(float(_weight(0) - _weight(1)), -1.0, 1.0)


func rider_on(i: int) -> bool:
	for b in _zones[i].get_overlapping_bodies():
		if b is Player:
			return true
	return false


## Is a hero standing under pan `i` (where it would come down on them)?
func _under(i: int) -> bool:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return false
	var lp := to_local(p.global_position)
	var pan := _pans[i].position
	return absf(lp.x - pan.x) < pan_size.x * 0.5 + 0.5 and absf(lp.z - pan.z) < pan_size.y * 0.5 + 0.5 and lp.y < pan.y - 0.6 and lp.y > pan.y - 3.2


## Pan 1's top, local to the scale.
func near_pan_top() -> float:
	return _pans[1].position.y


func far_pan_top() -> float:
	return _pans[0].position.y


func _apply() -> void:
	_pans[0].position.y = travel * 0.5 - _tilt * travel * 0.5
	_pans[1].position.y = travel * 0.5 + _tilt * travel * 0.5
	for i in 2:
		var top := travel + 2.1
		var pan_y := _pans[i].position.y + 0.1
		var c := _chains[i]
		var h := maxf(top - pan_y, 0.2)
		c.scale = Vector3(1.0, h, 1.0)
		c.position = Vector3(_pans[i].position.x, pan_y + h * 0.5, 0.0)


func _physics_process(delta: float) -> void:
	# A pan never comes down on a hero standing underneath it: the balance waits.
	var next := move_toward(_tilt, _target(), delta * tilt_speed)
	if not (next > _tilt and _under(0)) and not (next < _tilt and _under(1)):
		_tilt = next
	_apply()
	if not loaded and not _dropping:
		_iron.position = Vector3(-spacing * 0.5, far_pan_top(), 0.0)
	if not loaded:
		if rider_on(1):
			_idle = 0.0
		else:
			_idle += delta
			if _idle > reset_after:
				reset()
	if _brick_away and loaded and not _dropping and _tilt <= -0.97:
		_brick_away = false
		var t := brick.create_tween()
		t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		t.tween_property(brick, "position", _brick_home, 0.8).set_trans(Tween.TRANS_SINE)


## The brick zips aside and the big weight drops onto the far pan.
func drop() -> void:
	if not loaded or _dropping:
		return
	_dropping = true
	loaded = false
	_brick_away = true
	_idle = 0.0
	var bt := brick.create_tween()
	bt.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	bt.tween_property(brick, "position", _brick_home + Vector3(0.0, 0.0, pan_size.y * 0.5 + 3.0), 0.35).set_trans(Tween.TRANS_SINE)
	AudioDirector.play(&"gate", -2.0, 1.2)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(_iron, "position:y", far_pan_top(), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		_dropping = false
		extra[0] = hopper_weight
		AudioDirector.play(&"boss_slam", -4.0, 1.4)
		Fx.burst(get_parent(), _iron.global_position + Vector3.UP * 0.3, Palette.color(&"gold"), 16, 4.0, 0.12, -6.0, 0.5)
		weight_dropped.emit())


## Winch the weight back up into the hopper.
func reset() -> void:
	if loaded:
		return
	loaded = true
	_idle = 0.0
	extra[0] = 0
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(_iron, "position:y", _hopper_y(), 1.4).set_trans(Tween.TRANS_SINE)
	AudioDirector.play(&"gate", -4.0, 0.7)
	reset_done.emit()
