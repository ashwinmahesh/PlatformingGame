extends Node
## Music crossfades, ducking during dialogue, the bus layout, and pooled one-shot SFX (plan §9.2, §12).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 14

var _sfx: Dictionary[StringName, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music: StringName = &""
var _duck: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name: String in ["Music", "SFX", "UI", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_load_sfx()
	apply_volumes()


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _load_sfx() -> void:
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if base.ends_with(".wav") and not _sfx.has(StringName(base.get_basename())):
			var stream := load(SFX_DIR + base) as AudioStream
			if stream != null:
				_sfx[StringName(base.get_basename())] = stream


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(maxf(Settings.music_volume, 0.0001)) - _duck)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"UI"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))


## Play a one-shot with ±5% pitch variation (the shared randomiser, plan §12).
func play(sfx_name: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _sfx.get(sfx_name)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()


func play_music(track: StringName, fade: float = 1.2) -> void:
	if track == _current_music:
		return
	_current_music = track
	var path := MUSIC_DIR + String(track) + ".wav"
	var incoming := _music_b if _music_a.playing else _music_a
	var outgoing := _music_a if incoming == _music_b else _music_b
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStreamWAV
		if stream != null:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			incoming.stream = stream
			incoming.volume_db = -40.0
			incoming.play()
			create_tween().tween_property(incoming, "volume_db", 0.0, fade)
	if outgoing.playing:
		var t := create_tween()
		t.tween_property(outgoing, "volume_db", -60.0, fade)
		t.tween_callback(outgoing.stop)


func set_ducked(ducked: bool) -> void:
	_duck = 9.0 if ducked else 0.0
	apply_volumes()


## Stop everything and drop stream references (clean exit, no leaked playbacks).
func shutdown() -> void:
	for p in _pool:
		p.stop()
		p.stream = null
	for m: AudioStreamPlayer in [_music_a, _music_b]:
		m.stop()
		m.stream = null
	_sfx.clear()
	_current_music = &""


func _exit_tree() -> void:
	shutdown()
