extends CanvasLayer
## Scene transitions with the leaf-swirl wipe and background loading (plan §9.2, §5.2).
## Only one transition runs at a time; a failed load returns to the hub with a message.

signal transition_finished

var busy: bool = false
var pending_spawn: StringName = &""
var current_scene_id: StringName = &""

var _wipe: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wipe = ColorRect.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/transition.gdshader")
	_wipe.material = _mat
	add_child(_wipe)
	_set_progress(0.0)


func _set_progress(v: float) -> void:
	_mat.set_shader_parameter(&"progress", v)


func go_to(scene_id: StringName, spawn_id: StringName) -> void:
	if busy:
		return
	busy = true
	AudioDirector.play(&"warp")
	var t := create_tween()
	t.tween_method(_set_progress, 0.0, 1.0, 0.45)
	await t.finished
	var path := Progress.scene_path(scene_id)
	var packed: PackedScene = null
	if path != "" and ResourceLoader.load_threaded_request(path) == OK:
		while true:
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				packed = ResourceLoader.load_threaded_get(path) as PackedScene
				break
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			await get_tree().process_frame
	if packed == null:
		push_warning("Router: failed to load %s, returning to the hub" % path)
		Events.notice.emit("Couldn't open that place. Back to Mossbrook!")
		scene_id = Progress.HUB_SCENE
		spawn_id = &"hub_arrival"
		packed = load(Progress.HUB_PATH) as PackedScene
	pending_spawn = spawn_id
	current_scene_id = scene_id
	get_tree().paused = false
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_method(_set_progress, 1.0, 0.0, 0.45)
	await t2.finished
	busy = false
	transition_finished.emit()


## Plain scene change for menus (no world/spawn bookkeeping).
func go_to_path(path: String) -> void:
	if busy:
		return
	busy = true
	var t := create_tween()
	t.tween_method(_set_progress, 0.0, 1.0, 0.35)
	await t.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_method(_set_progress, 1.0, 0.0, 0.35)
	await t2.finished
	busy = false
