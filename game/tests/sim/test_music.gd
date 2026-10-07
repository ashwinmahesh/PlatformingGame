extends TestCase
## Build 7 music (Ashwin: "find some suitable background music"): every cue the game plays has a
## CC0 recording that loads, and Clover's shop plays its own tune, then hands the level's back.

const CUES: Array[StringName] = [&"title", &"mossbrook", &"shop", &"boss", &"victory", &"glimmerbrook", &"cloudtop", &"canyon", &"reef", &"frostfang", &"lanternwick", &"world_07", &"world_08", &"world_09"]


func test_every_cue_has_a_track() -> void:
	for cue in CUES:
		var found := false
		for ext: String in [".ogg", ".mp3", ".wav"]:
			var path := AudioDirector.MUSIC_DIR + String(cue) + ext
			if ResourceLoader.exists(path):
				var st := load(path) as AudioStream
				found = st != null and st.get_length() > 1.0
				break
		check(found, "%s has a track" % cue)


func test_shop_plays_its_own_tune() -> void:
	floor_block(Vector3.ZERO, Vector3(20.0, 2.0, 20.0))
	var p := spawn_player(Vector3(0.0, 0.05, 0.0))
	await ticks(3)
	AudioDirector.play_music(&"mossbrook", 0.05)
	var panel := ShopPanel.open(p)
	await ticks(3)
	check_eq(AudioDirector.current_music(), &"shop", "the shop plays its tune")
	panel.close()
	await ticks(3)
	check_eq(AudioDirector.current_music(), &"mossbrook", "closing it brings the level's music back")
