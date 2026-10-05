extends TestCase
## Every flag a dialogue line refers to exists (plan §8.7), and every NPC has something to say.


func test_flags_exist_and_lines_pick() -> void:
	var saved := Progress.data.duplicate(true)
	Progress.data = Progress.fresh_data()
	for npc: String in ["elder_fern", "pip", "old_bramble"]:
		var data := DialogueData.load_npc(npc)
		check(not data.is_empty(), "%s loads" % npc)
		for flag in DialogueData.referenced_flags(data):
			check(StringName(flag) in Progress.KNOWN_FLAGS, "%s: flag '%s' is registered" % [npc, flag])
		check(not DialogueData.pick_lines(data).is_empty(), "%s has lines for a new game" % npc)
	Progress.data = saved
