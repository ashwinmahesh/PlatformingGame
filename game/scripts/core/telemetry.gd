extends Node
## JSONL event log (plan §7.3): jump, land, fall, death, checkpoint, section entered and left.
## On in debug builds; tools/digest.py turns it into a per-section table.

var enabled: bool = OS.is_debug_build()
var path: String = ""
var _file: FileAccess
var _t0: int = 0


func _ready() -> void:
	if not enabled:
		return
	DirAccess.make_dir_recursive_absolute("user://telemetry")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	path = "user://telemetry/session_%s.jsonl" % stamp
	_file = FileAccess.open(path, FileAccess.WRITE)
	_t0 = Time.get_ticks_msec()


func log_event(event: String, fields: Dictionary = {}) -> void:
	if _file == null:
		return
	var rec := {"t": snappedf((Time.get_ticks_msec() - _t0) / 1000.0, 0.001), "ev": event}
	var scene := get_tree().current_scene
	if scene != null:
		rec["scene"] = String(scene.name)
	for k: Variant in fields:
		var v: Variant = fields[k]
		if v is Vector3:
			var p := v as Vector3
			v = [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]
		rec[k] = v
	_file.store_line(JSON.stringify(rec))
	_file.flush()
