extends Node
## Loads every script under res://scripts and res://tests so parse errors surface even for code
## no scene uses yet. Exits non-zero on any failure. `make check-scripts`.


func _ready() -> void:
	var bad := 0
	var count := 0
	for root: String in ["res://scripts", "res://tests", "res://tools"]:
		for path in _walk(root):
			count += 1
			var s := load(path) as GDScript
			if s == null or not s.can_instantiate():
				bad += 1
				print("BROKEN ", path)
	print("check-scripts: %d scripts, %d broken" % [count, bad])
	get_tree().quit(1 if bad > 0 else 0)


func _walk(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		out.append_array(_walk(dir_path.path_join(d)))
	return out
