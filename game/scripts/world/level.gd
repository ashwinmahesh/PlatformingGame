class_name Level
extends Node3D
## Base for every playable scene: environment, hero, camera, HUD, combat resolver, spawns,
## hazards and death/respawn (plan §9.8). Subclasses build their geometry in build().

const SKY_SHADER := preload("res://shaders/sky.gdshader")

var scene_id: StringName = &""
var default_spawn: StringName = &""
var music: StringName = &""
var kill_y: float = -30.0
var player: Player
var rig: CameraRig
var hud: Hud
var resolver: CombatResolver
var sun: DirectionalLight3D
var spawns: Dictionary[StringName, Array] = {}


func _ready() -> void:
	_build_environment()
	build()
	resolver = CombatResolver.new()
	resolver.name = "CombatResolver"
	add_child(resolver)
	player = Player.new()
	player.name = "Player"
	var spawn_id := Router.pending_spawn if spawns.has(Router.pending_spawn) else default_spawn
	var sp: Array = spawns.get(spawn_id, [Vector3.ZERO, Vector3.FORWARD])
	player.position = sp[0] as Vector3
	player.facing = sp[1] as Vector3
	add_child(player)
	player.safe_position = player.global_position
	resolver.player = player
	rig = CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.attach(player)
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.bind_player(player)
	hud.world_id = scene_id
	player.died.connect(_on_player_died)
	if DevTools.enabled:
		add_child(HitboxDebug.new())
	for area in get_tree().get_nodes_in_group(&"hazard"):
		var a := area as Area3D
		a.body_entered.connect(_on_hazard_body.bind(StringName(str(a.get_meta(&"kind", "water")))))
	Router.current_scene_id = scene_id
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if music != &"":
		AudioDirector.play_music(music)
	Telemetry.log_event("scene_enter", {"scene": String(scene_id), "spawn": String(spawn_id)})
	after_spawn(spawn_id)


## Override: build geometry, spawns, NPCs, enemies.
func build() -> void:
	pass


## Override: react once the hero is placed (e.g. victory state on the arena exit).
func after_spawn(_spawn_id: StringName) -> void:
	pass


## Override: reset bosses and the like when the hero respawns at a checkpoint.
func on_player_respawned() -> void:
	pass


func add_spawn(id: StringName, pos: Vector3, look: Vector3 = Vector3.FORWARD) -> void:
	spawns[id] = [pos, look]


func add_capture_point(point_name: String, pos: Vector3, look_target: Vector3) -> void:
	var m := Marker3D.new()
	m.name = point_name
	add_child(m)
	m.global_position = pos
	m.look_at(look_target, Vector3.UP)
	m.add_to_group(&"capture_point")


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Palette.FOG
	env.ambient_light_energy = 0.36
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Palette.FOG
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 220.0
	env.fog_density = 0.4
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("#FFE2B5")
	sun.light_energy = 0.95
	sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-35.0), 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_bias = 0.04
	add_child(sun)


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y < kill_y and player.state not in [Player.State.FROZEN, Player.State.DEAD]:
		player.on_hazard(&"pit")


func _on_hazard_body(body: Node3D, kind: StringName) -> void:
	if body is Player:
		# Water is swimmable (Build 3); only pits and the kill plane send the hero back.
		if kind != &"water":
			(body as Player).on_hazard(kind)
	elif body is Gloplet:
		body.call_deferred(&"_defeat", false)


## Death: back to the last checkpoint with full hearts; that zone's encounters reset.
func _on_player_died() -> void:
	var cp := Progress.checkpoint_for(scene_id)
	var sp: Array = spawns.get(cp, spawns.get(default_spawn, [Vector3.ZERO, Vector3.FORWARD]))
	player.refill()
	player.respawn_at(sp[0] as Vector3, sp[1] as Vector3)
	player.invuln_left = 1.0
	for z in get_tree().get_nodes_in_group(&"encounter_zone"):
		(z as EncounterZone).reset()
	on_player_respawned()
	Telemetry.log_event("respawn", {"checkpoint": String(cp)})
