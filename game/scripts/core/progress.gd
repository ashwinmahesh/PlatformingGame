extends Node
## Save data, the victory commit and derived rewards (plan §9.8).
## Completion is the source of truth: max hearts and trophies are derived from completed_worlds.

const SCHEMA_VERSION := 1
const BASE_HALVES := 6
const HUB_SCENE := &"hub"
const HUB_SPAWNS: Array[StringName] = [&"hub_arrival", &"hub_rootway_exit"]
const HUB_PATH := "res://scenes/hub/mossbrook.tscn"
const KNOWN_FLAGS: Array[StringName] = [&"w3_found_goggles", &"w2_found_compass", &"w1_found_musicbox", &"w6_found_hook", &"w6_found_pin", &"w5_found_globe", &"w4_found_comb", &"w3_found_sundial", &"w2_found_chime", &"w1_found_lantern", &"seeds_quest_started", &"met_fern", &"met_pip", &"met_bramble", &"w4_found_hat", &"w3_found_book", &"w1_found_charm", &"w2_found_kite", &"w5_found_carrot"]
const WORLD_DEFS: Array[WorldDef] = [
	preload("res://data/worlds/world_01.tres"),
	preload("res://data/worlds/world_02.tres"),
	preload("res://data/worlds/world_03.tres"),
	preload("res://data/worlds/world_04.tres"),
	preload("res://data/worlds/world_05.tres"),
	preload("res://data/worlds/world_06.tres"),
]
const RETRY_SECONDS := 30.0

## Build 6: only the real game (started from the title screen) uses the player's save in user://.
## Dev tools, captures and scenes started directly write to user://dev_saves/ instead, so they
## can never overwrite real progress. The test runner points this at user://test_saves/.
var save_dir: String = "user://dev_saves/"
const PLAYER_SAVE_DIR := "user://"
var data: Dictionary = {}
## Set by tests/dev to quit the process between victory steps (plan §9.8 interruption test).
var debug_kill_at_step: int = -1

var _pending_retry: bool = false
var _retry_left: float = 0.0


func _ready() -> void:
	data = fresh_data()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kill-at-victory-step="):
			debug_kill_at_step = int(arg.get_slice("=", 1))


func _process(delta: float) -> void:
	if _pending_retry:
		_retry_left -= delta
		if _retry_left <= 0.0:
			save()


## Called on quit: one more try for a save that failed earlier (plan §9.8).
func flush() -> void:
	if _pending_retry:
		save()


# --- Registries -----------------------------------------------------------------------------

func world_def(world_id: StringName) -> WorldDef:
	for w in WORLD_DEFS:
		if w.id == world_id:
			return w
	return null


func scene_path(scene_id: StringName) -> String:
	if scene_id == HUB_SCENE:
		return HUB_PATH
	var w := world_def(scene_id)
	return w.scene_path if w != null else ""


func spawn_exists(scene_id: StringName, spawn_id: StringName) -> bool:
	if scene_id == HUB_SCENE:
		return spawn_id in HUB_SPAWNS
	var w := world_def(scene_id)
	return w != null and spawn_id in w.spawn_ids


func all_seed_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for w in WORLD_DEFS:
		out.append_array(w.seed_ids)
	return out


# --- State ------------------------------------------------------------------------------------

func fresh_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"completed_worlds": [],
		"seeds": [],
		"shards": [],
		"flags": [],
		"best_times": {},
		"world_progress": {},
		"purchases": [],
		"abilities": [],
		"resume": {"scene_id": String(HUB_SCENE), "spawn_id": "hub_arrival"},
	}


func new_game() -> void:
	data = fresh_data()
	save()


func is_world_complete(world_id: StringName) -> bool:
	return String(world_id) in (data["completed_worlds"] as Array)


## Build 5 magic abilities: learned by clearing the world that teaches them (derived from
## completion, never stored). Dev builds can grant them all with F3 for playtesting.
var dev_all_abilities: bool = false


## Build 7 (Ashwin: 6 stars per world; "each level should give some kind of ability after
## collecting all the stars and finishing"): learned abilities are stored. A world teaches its
## ability once it is finished AND all its Star Shards are in, whichever comes last.
func has_ability(ability: StringName) -> bool:
	if dev_all_abilities:
		return true
	return String(ability) in (data.get("abilities", []) as Array)


func _try_learn(world_id: StringName) -> void:
	var w := world_def(world_id)
	if w == null or w.ability == &"" or has_ability(w.ability):
		return
	if not is_world_complete(world_id) or world_shard_count(world_id) < w.shard_ids.size():
		return
	if not data.has("abilities"):
		data["abilities"] = []
	(data["abilities"] as Array).append(String(w.ability))
	save()
	Events.ability_learned.emit(w.ability)


func completed_count() -> int:
	return (data["completed_worlds"] as Array).size()


## Derived, never stored: 3 hearts plus each completed world's heart containers.
func max_halves() -> int:
	var halves := BASE_HALVES
	for w_id: Variant in data["completed_worlds"]:
		var w := world_def(StringName(str(w_id)))
		if w != null:
			halves += 2 * w.first_clear_heart_containers
	for h: StringName in [&"heart_1", &"heart_2", &"heart_3"]:
		if has_upgrade(h):
			halves += 2
	return halves


# --- Build 7 Glimmer Seed shop ---------------------------------------------------------------------

func has_upgrade(id: StringName) -> bool:
	return String(id) in (data.get("purchases", []) as Array)


## Seeds you can still spend: every seed found, less what the shop has had.
func seeds_to_spend() -> int:
	var spent := 0
	for id: Variant in data.get("purchases", []):
		spent += ShopItems.price(StringName(str(id)))
	return seed_count() - spent


func can_buy(id: StringName) -> bool:
	if not ShopItems.ITEMS.has(id) or has_upgrade(id):
		return false
	var need := ShopItems.needs(id)
	if need != &"" and not has_upgrade(need):
		return false
	return seeds_to_spend() >= ShopItems.price(id)


func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	if not data.has("purchases"):
		data["purchases"] = []
	(data["purchases"] as Array).append(String(id))
	save()
	return true


func has_seed(seed_id: StringName) -> bool:
	return String(seed_id) in (data["seeds"] as Array)


func seed_count() -> int:
	return (data["seeds"] as Array).size()


func collect_seed(seed_id: StringName) -> void:
	if has_seed(seed_id):
		return
	(data["seeds"] as Array).append(String(seed_id))
	Events.seed_collected.emit(seed_id)
	save()


func all_shard_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for w in WORLD_DEFS:
		out.append_array(w.shard_ids)
	return out


func has_shard(shard_id: StringName) -> bool:
	return String(shard_id) in (data.get("shards", []) as Array)


func collect_shard(shard_id: StringName) -> void:
	if has_shard(shard_id):
		return
	if not data.has("shards"):
		data["shards"] = []
	(data["shards"] as Array).append(String(shard_id))
	Events.shard_collected.emit(shard_id)
	save()
	for w in WORLD_DEFS:
		if shard_id in w.shard_ids:
			_try_learn(w.id)


func world_shard_count(world_id: StringName) -> int:
	var w := world_def(world_id)
	if w == null:
		return 0
	var n := 0
	for s in w.shard_ids:
		if has_shard(s):
			n += 1
	return n


func world_seed_count(world_id: StringName) -> int:
	var w := world_def(world_id)
	if w == null:
		return 0
	var n := 0
	for s in w.seed_ids:
		if has_seed(s):
			n += 1
	return n


func has_flag(flag: StringName) -> bool:
	return String(flag) in (data["flags"] as Array)


func set_flag(flag: StringName) -> void:
	if has_flag(flag):
		return
	(data["flags"] as Array).append(String(flag))
	save()


func best_time(course: String) -> float:
	return float((data["best_times"] as Dictionary).get(course, 0.0))


func record_time(course: String, seconds: float) -> bool:
	var prev := best_time(course)
	if prev > 0.0 and prev <= seconds:
		return false
	(data["best_times"] as Dictionary)[course] = snappedf(seconds, 0.01)
	save()
	return true


func set_checkpoint(world_id: StringName, checkpoint_id: StringName) -> void:
	var wp := data["world_progress"] as Dictionary
	wp[String(world_id)] = {"checkpoint_id": String(checkpoint_id)}
	data["resume"] = {"scene_id": String(world_id), "spawn_id": String(checkpoint_id)}
	save()


func checkpoint_for(world_id: StringName) -> StringName:
	var wp := data["world_progress"] as Dictionary
	var entry: Dictionary = wp.get(String(world_id), {})
	return StringName(str(entry.get("checkpoint_id", "")))


func set_resume(scene_id: StringName, spawn_id: StringName) -> void:
	data["resume"] = {"scene_id": String(scene_id), "spawn_id": String(spawn_id)}
	save()


## Where Continue goes. Falls back to a world's entrance, then to the hub (plan §9.8).
func resume_target() -> Array[StringName]:
	var r := data["resume"] as Dictionary
	var scene_id := StringName(str(r.get("scene_id", "hub")))
	var spawn_id := StringName(str(r.get("spawn_id", "hub_arrival")))
	if scene_path(scene_id) == "":
		return [HUB_SCENE, &"hub_arrival"]
	if not spawn_exists(scene_id, spawn_id):
		var w := world_def(scene_id)
		spawn_id = w.entrance_spawn if w != null else &"hub_arrival"
	return [scene_id, spawn_id]


## The victory commit (plan §9.8). Returns true when this was a first clear.
## Steps: note first clear -> build new state -> write -> (caller plays presentation).
func commit_victory(world_id: StringName) -> bool:
	_debug_kill(1)
	var first_clear := not is_world_complete(world_id)
	var next := data.duplicate(true)
	if first_clear:
		(next["completed_worlds"] as Array).append(String(world_id))
	var w := world_def(world_id)
	next["resume"] = {"scene_id": String(world_id), "spawn_id": String(w.arena_exit_spawn if w != null else &"")}
	_debug_kill(2)
	data = next
	save()
	_debug_kill(3)
	_try_learn(world_id)
	return first_clear


func _debug_kill(step: int) -> void:
	if debug_kill_at_step == step:
		push_warning("Progress: debug kill at victory step %d" % step)
		get_tree().quit(3)


# --- Disk -------------------------------------------------------------------------------------

func main_path() -> String:
	return save_dir.path_join("save_0.json")


func has_save() -> bool:
	return FileAccess.file_exists(main_path()) or FileAccess.file_exists(main_path() + ".bak")


## Write tmp -> read back and validate -> keep previous as .bak -> rename over main.
func save() -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var tmp := main_path() + ".tmp"
	var text := JSON.stringify(data, "\t")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return _save_failed()
	f.store_string(text)
	f.close()
	var back := _read_json(tmp)
	if back.is_empty() or not validate(back):
		return _save_failed()
	var main_abs := ProjectSettings.globalize_path(main_path())
	if FileAccess.file_exists(main_path()):
		DirAccess.copy_absolute(main_abs, main_abs + ".bak")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), main_abs) != OK:
		return _save_failed()
	_pending_retry = false
	return true


func _save_failed() -> bool:
	if not _pending_retry:
		Events.notice.emit("Couldn't save, retrying")
	_pending_retry = true
	_retry_left = RETRY_SECONDS
	return false


## Load main, else backup, else quarantine both and start fresh. Returns false if fresh.
func load_save() -> bool:
	for path: String in [main_path(), main_path() + ".bak"]:
		var d := _read_json(path)
		if not d.is_empty():
			d = sanitize(d)
			if validate(d):
				data = d
				if path != main_path():
					Events.notice.emit("Save restored from backup")
					save()
				return true
	if has_save():
		var stamp := str(int(Time.get_unix_time_from_system()))
		for path: String in [main_path(), main_path() + ".bak"]:
			if FileAccess.file_exists(path):
				var abs_path := ProjectSettings.globalize_path(path)
				DirAccess.rename_absolute(abs_path, abs_path + ".corrupt-" + stamp)
		Events.notice.emit("Save file was damaged, starting fresh")
	data = fresh_data()
	return false


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


## Drop IDs this build doesn't know (with a warning) instead of failing the whole load.
func sanitize(d: Dictionary) -> Dictionary:
	var out := fresh_data()
	out["schema_version"] = d.get("schema_version", -1)
	var known_worlds: Array[String] = []
	for w in WORLD_DEFS:
		known_worlds.append(String(w.id))
	var known_seeds: Array[String] = []
	for s in all_seed_ids():
		known_seeds.append(String(s))
	var known_flags: Array[String] = []
	for fl in KNOWN_FLAGS:
		known_flags.append(String(fl))
	out["completed_worlds"] = _filter_known(d.get("completed_worlds", []), known_worlds, "world")
	out["seeds"] = _filter_known(d.get("seeds", []), known_seeds, "seed")
	var known_shards: Array[String] = []
	for s in all_shard_ids():
		known_shards.append(String(s))
	out["shards"] = _filter_known(d.get("shards", []), known_shards, "shard")
	out["flags"] = _filter_known(d.get("flags", []), known_flags, "flag")
	if d.get("best_times") is Dictionary:
		out["best_times"] = d["best_times"]
	if d.get("world_progress") is Dictionary:
		var wp := {}
		for key: Variant in (d["world_progress"] as Dictionary):
			if str(key) in known_worlds:
				wp[str(key)] = (d["world_progress"] as Dictionary)[key]
		out["world_progress"] = wp
	if d.get("resume") is Dictionary:
		out["resume"] = d["resume"]
	var known_items: Array[String] = []
	for k: StringName in ShopItems.ITEMS:
		known_items.append(String(k))
	out["purchases"] = _filter_known(d.get("purchases", []), known_items, "purchase")
	# Abilities: saves from before Build 7 earned them by finishing a world, so they keep those.
	var known_abilities: Array[String] = []
	for w in WORLD_DEFS:
		if w.ability != &"":
			known_abilities.append(String(w.ability))
	if d.has("abilities"):
		out["abilities"] = _filter_known(d["abilities"], known_abilities, "ability")
	else:
		var legacy: Array = []
		for w in WORLD_DEFS:
			if w.ability != &"" and String(w.id) in (out["completed_worlds"] as Array):
				legacy.append(String(w.ability))
		out["abilities"] = legacy
	return out


func _filter_known(values: Variant, known: Array[String], kind: String) -> Array:
	var out: Array = []
	if not values is Array:
		return out
	for v: Variant in values:
		var s := str(v)
		if s in known:
			if not s in out:
				out.append(s)
		else:
			push_warning("Progress: dropping unknown %s id '%s'" % [kind, s])
	return out


func validate(d: Dictionary) -> bool:
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION:
		return false
	if not d.has("shards"):
		d["shards"] = []
	for key: String in ["completed_worlds", "seeds", "shards", "flags"]:
		var arr: Variant = d.get(key)
		if not arr is Array:
			return false
		var seen := {}
		for v: Variant in arr:
			if seen.has(str(v)):
				return false
			seen[str(v)] = true
	for w_id: Variant in d["completed_worlds"]:
		if world_def(StringName(str(w_id))) == null:
			return false
	var seeds := all_seed_ids()
	for s: Variant in d["seeds"]:
		if not StringName(str(s)) in seeds:
			return false
	if not d.get("resume") is Dictionary:
		return false
	var r := d["resume"] as Dictionary
	var scene_id := StringName(str(r.get("scene_id", "")))
	return scene_path(scene_id) != "" and spawn_exists(scene_id, StringName(str(r.get("spawn_id", ""))))
