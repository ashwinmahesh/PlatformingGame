extends TestCase
## Saving and loading (plan §9.8): validation, backup recovery, derived rewards, victory commit.

var _saved_data: Dictionary


func before_each() -> void:
	_saved_data = Progress.data.duplicate(true)
	for f in DirAccess.get_files_at(Progress.save_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.save_dir.path_join(f)))
	Progress.data = Progress.fresh_data()


func _exit_tree() -> void:
	Progress.data = _saved_data


func test_roundtrip() -> void:
	Progress.new_game()
	Progress.collect_seed(&"w1_seed_fernway")
	Progress.set_flag(&"met_fern")
	Progress.set_checkpoint(&"world_01", &"w1_cp_far_bank")
	Progress.data = Progress.fresh_data()
	check(Progress.load_save(), "loaded")
	check(Progress.has_seed(&"w1_seed_fernway"), "seed kept")
	check(Progress.has_flag(&"met_fern"), "flag kept")
	check_eq(Progress.resume_target(), [&"world_01", &"w1_cp_far_bank"] as Array[StringName], "resume at the checkpoint")


func test_corrupt_main_recovers_from_backup() -> void:
	Progress.new_game()
	Progress.collect_seed(&"w1_seed_river")
	Progress.set_flag(&"met_pip")
	var f := FileAccess.open(Progress.main_path(), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	Progress.data = Progress.fresh_data()
	check(Progress.load_save(), "loaded from backup")
	check(Progress.has_seed(&"w1_seed_river"), "backup has the seed")


func test_both_corrupt_starts_fresh_and_quarantines() -> void:
	for suffix: String in ["", ".bak"]:
		var f := FileAccess.open(Progress.main_path() + suffix, FileAccess.WRITE)
		f.store_string("garbage")
		f.close()
	check(not Progress.load_save(), "fresh start")
	var quarantined := 0
	for name in DirAccess.get_files_at(Progress.save_dir):
		if name.contains(".corrupt-"):
			quarantined += 1
	check_eq(quarantined, 2, "both files renamed *.corrupt-<time>")


func test_unknown_ids_are_dropped() -> void:
	var d := Progress.fresh_data()
	d["seeds"] = ["w1_seed_fernway", "w9_seed_from_the_future"]
	d["flags"] = ["met_fern", "unknown_flag"]
	var f := FileAccess.open(Progress.main_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	check(Progress.load_save(), "loaded")
	check_eq(Progress.seed_count(), 1, "unknown seed dropped")
	check(Progress.has_flag(&"met_fern") and not Progress.has_flag(&"unknown_flag"), "unknown flag dropped")


func test_validation_rejects_bad_data() -> void:
	var d := Progress.fresh_data()
	d["seeds"] = ["w1_seed_fernway", "w1_seed_fernway"]
	check(not Progress.validate(d), "duplicates rejected")
	d = Progress.fresh_data()
	d["resume"] = {"scene_id": "hub", "spawn_id": "nowhere"}
	check(not Progress.validate(d), "resume must point somewhere real")
	d = Progress.fresh_data()
	d["schema_version"] = 99
	check(not Progress.validate(d), "unknown schema rejected")


func test_victory_commit_and_derived_rewards() -> void:
	Progress.new_game()
	check_eq(Progress.max_halves(), 6, "3 hearts to start")
	check(Progress.commit_victory(&"world_01"), "first clear")
	check_eq(Progress.max_halves(), 8, "a heart container is derived from completion")
	check(not Progress.commit_victory(&"world_01"), "beating her twice is not a first clear")
	check_eq((Progress.data["completed_worlds"] as Array).size(), 1, "completion recorded once")
	Progress.data = Progress.fresh_data()
	Progress.load_save()
	check(Progress.is_world_complete(&"world_01"), "completion survived a reload")
	check_eq(Progress.resume_target(), [&"world_01", &"w1_arena_exit"] as Array[StringName], "resume at the arena exit")


func test_missing_spawn_falls_back_to_entrance() -> void:
	Progress.new_game()
	Progress.data["resume"] = {"scene_id": "world_01", "spawn_id": "w1_removed_checkpoint"}
	check_eq(Progress.resume_target(), [&"world_01", &"w1_entrance"] as Array[StringName], "falls back to the entrance")
