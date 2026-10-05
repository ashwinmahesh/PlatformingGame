class_name AttackDirector
extends RefCounted
## Hands out attack tokens per encounter (plan §8.2): at most 2 melee and 1 thrower at once,
## at least 0.4 s between attack starts. While the boss winds up or her core is open, no minion
## may start an attack; the boss waits for minion attacks already in progress.

const MAX_MELEE := 2
const MAX_THROWERS := 1
const MIN_GAP_TICKS := 24

var boss_lock: bool = false
var _melee: Array[Object] = []
var _throwers: Array[Object] = []
var _active: Array[Object] = []
var _last_start_tick: int = -1000
var _tick: int = 0


func advance() -> void:
	_tick += 1
	_prune(_melee)
	_prune(_throwers)
	_prune(_active)


## Drop holders that were freed (defeated enemies).
static func _prune(list: Array[Object]) -> void:
	for i in range(list.size() - 1, -1, -1):
		if not is_instance_valid(list[i]):
			list.remove_at(i)


func request(who: Object, thrower: bool = false) -> bool:
	if boss_lock:
		return false
	if who in _melee or who in _throwers:
		return true
	var pool := _throwers if thrower else _melee
	if pool.size() >= (MAX_THROWERS if thrower else MAX_MELEE):
		return false
	pool.append(who)
	return true


func holds(who: Object) -> bool:
	return who in _melee or who in _throwers


func release(who: Object) -> void:
	_melee.erase(who)
	_throwers.erase(who)
	_active.erase(who)


## Called when the windup ends and the attack really starts.
func can_start(who: Object) -> bool:
	return holds(who) and not boss_lock and _tick - _last_start_tick >= MIN_GAP_TICKS


func mark_started(who: Object) -> void:
	_last_start_tick = _tick
	if not who in _active:
		_active.append(who)


func mark_finished(who: Object) -> void:
	_active.erase(who)


func any_active_attack() -> bool:
	return not _active.is_empty()


func melee_count() -> int:
	return _melee.size()
