class_name EnemyDef
extends Resource
## Every enemy number, in physics ticks (plan §8, §9.7).

@export var id: StringName = &"gloplet"
@export var hp: int = 2
@export var color: StringName = &"slime_green"
@export var is_bouncer: bool = false
@export var sight_radius: float = 9.0
@export var fov_deg: float = 140.0
@export var hearing_radius: float = 6.0
@export var leash_radius: float = 8.0
@export var lost_sight_ticks: int = 180
@export var idle_ticks: int = 90
@export var notice_ticks: int = 24
@export var hop_interval_ticks: int = 36
@export var hop_distance: float = 1.4
@export var hop_air_ticks: int = 22
@export var hop_height: float = 0.6
@export var lunge_range: float = 3.6
@export var windup_ticks: int = 30
@export var lunge_air_ticks: int = 26
@export var lunge_height: float = 0.35
@export var recover_ticks: int = 60
@export var hurt_ticks: int = 18
@export var contact_damage: int = 1
@export var lunge_damage: int = 2
@export var heart_drop_chance: float = 0.25
@export var bounce_height: float = 4.0
@export var respawn_ticks: int = 360
@export var max_state_ticks: int = 600
