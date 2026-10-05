class_name DialogueData
extends RefCounted
## Dialogue is data in data/dialogue/*.json (plan §8.7). A unit test checks every flag exists.

const DIR := "res://data/dialogue/"


static func load_npc(npc_id: String) -> Dictionary:
	var path := DIR + npc_id + ".json"
	if not FileAccess.file_exists(path):
		push_error("Dialogue: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Conditions: "flag", "!flag", "world_01_complete", "seeds>=N"; joined with "&".
static func condition_holds(cond: String) -> bool:
	if cond.strip_edges() == "":
		return true
	for part in cond.split("&"):
		var c := part.strip_edges()
		var negate := c.begins_with("!")
		if negate:
			c = c.substr(1)
		var value := false
		if c.begins_with("seeds>="):
			value = Progress.seed_count() >= int(c.get_slice(">=", 1))
		elif c.ends_with("_complete"):
			value = Progress.is_world_complete(StringName(c.trim_suffix("_complete")))
		else:
			value = Progress.has_flag(StringName(c))
		if value == negate:
			return false
	return true


## Every flag a dialogue condition or "set" refers to (for the validation test).
static func referenced_flags(data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for conv: Variant in data.get("conversations", []):
		var cd := conv as Dictionary
		for part in str(cd.get("when", "")).split("&"):
			var c := part.strip_edges().trim_prefix("!")
			if c != "" and not c.begins_with("seeds>=") and not c.ends_with("_complete"):
				out.append(c)
		for line: Variant in cd.get("lines", []):
			var s := str((line as Dictionary).get("set", ""))
			if s != "":
				out.append(s)
	return out


static func pick_lines(data: Dictionary) -> Array:
	for conv: Variant in data.get("conversations", []):
		var cd := conv as Dictionary
		if condition_holds(str(cd.get("when", ""))):
			return cd.get("lines", []) as Array
	return []
