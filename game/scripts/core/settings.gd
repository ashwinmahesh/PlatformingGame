extends Node
## Video, audio, controls and accessibility, stored in user://settings.cfg (plan §9.2).

const PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.25
var stick_sensitivity: float = 2.4
var invert_x: bool = false
var invert_y: bool = false
var auto_follow: float = 0.5
var screen_shake: float = 0.6
## Camera distance from the hero in metres (Build 3: closer by default, adjustable).
var camera_distance: float = 8.5
const CAMERA_DISTANCE_MIN := 5.0
const CAMERA_DISTANCE_MAX := 14.0
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var last_device_gamepad: bool = false
## Ashwin: "player can switch a setting to instead use arrow keys for controls and WASD for camera".
var arrows_move: bool = false


func _ready() -> void:
	load_settings()
	InputSetup.register()


## Swap which keys move the hero and which turn the camera; applies at once and is saved.
func set_arrows_move(on: bool) -> void:
	arrows_move = on
	InputSetup.register()
	save_settings()


## One line of keyboard help for the current layout.
func controls_hint() -> String:
	return ("Arrow keys move  ·  WASD camera" if arrows_move else "WASD move  ·  Arrow keys camera")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var m := event as InputEventJoypadMotion
		if m == null or absf(m.axis_value) > 0.3:
			last_device_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		last_device_gamepad = false


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = float(cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity))
	stick_sensitivity = float(cfg.get_value("controls", "stick_sensitivity", stick_sensitivity))
	invert_x = bool(cfg.get_value("controls", "invert_x", invert_x))
	invert_y = bool(cfg.get_value("controls", "invert_y", invert_y))
	auto_follow = float(cfg.get_value("camera", "auto_follow", auto_follow))
	screen_shake = float(cfg.get_value("camera", "screen_shake", screen_shake))
	camera_distance = clampf(float(cfg.get_value("camera", "distance", camera_distance)), CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)
	music_volume = float(cfg.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))
	arrows_move = bool(cfg.get_value("controls", "arrows_move", arrows_move))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "stick_sensitivity", stick_sensitivity)
	cfg.set_value("controls", "invert_x", invert_x)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("controls", "arrows_move", arrows_move)
	cfg.set_value("camera", "auto_follow", auto_follow)
	cfg.set_value("camera", "screen_shake", screen_shake)
	cfg.set_value("camera", "distance", camera_distance)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(PATH)
