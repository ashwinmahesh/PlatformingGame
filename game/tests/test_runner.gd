extends Node
## Runs every tests/unit/test_*.gd and tests/sim/test_*.gd. Exits non-zero on any failure.
## Run with: make test   (headless, --fixed-fps 60 so physics runs as fast as possible)

const DIRS := ["res://tests/unit/", "res://tests/sim/"]


func _ready() -> void:
	Progress.save_dir = "user://test_saves/"
	DirAccess.make_dir_recursive_absolute(Progress.save_dir)
	Telemetry.enabled = false
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
	var total := 0
	var failed: Array[String] = []
	for dir_path: String in DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		var files := dir.get_files()
		files.sort()
		for f in files:
			if not f.begins_with("test_") or not f.ends_with(".gd"):
				continue
			var script := load(dir_path + f) as GDScript
			if script == null or not script.can_instantiate():
				total += 1
				failed.append(f)
				print("  FAIL  ", f, ": script failed to load")
				continue
			for m in script.get_script_method_list():
				var method := str(m["name"])
				if not method.begins_with("test_"):
					continue
				if only != "" and not (f + ":" + method).contains(only):
					continue
				total += 1
				var tc := script.new() as TestCase
				tc.current_test = "%s:%s" % [f.get_basename(), method]
				add_child(tc)
				await tc.before_each()
				await tc.call(method)
				if tc.failures.is_empty():
					print("  ok    ", tc.current_test)
				else:
					for fail: String in tc.failures:
						print("  FAIL  ", fail)
					failed.append(tc.current_test)
				tc.queue_free()
				get_tree().paused = false
				await get_tree().physics_frame
				await get_tree().physics_frame
	print("")
	print("%d tests, %d passed, %d failed" % [total, total - failed.size(), failed.size()])
	Kit.clear_cache()
	Toon.clear_cache()
	Props.clear_cache()
	AudioDirector.shutdown()
	for i in 6:
		OS.delay_msec(30)
		await get_tree().process_frame
	get_tree().quit(1 if not failed.is_empty() or total == 0 else 0)
