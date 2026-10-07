class_name SpringLock
extends WaterLock
## Build 9 (Dinodew Jungle): a WaterLock whose level is set from outside, so SpringLocks can
## share one spring between two of them (levels: [drained, full]).


## Moves the water to levels[i] over `seconds` (0 = at once).
func set_index(i: int, seconds: float = 1.8) -> void:
	if i == index:
		return
	index = i
	if seconds <= 0.0 or not is_inside_tree():
		_apply(levels[index])
	else:
		create_tween().tween_method(_apply, surface() - global_position.y, levels[index], seconds).set_trans(Tween.TRANS_SINE)
	level_changed.emit(index)


func is_full() -> bool:
	return index == levels.size() - 1
