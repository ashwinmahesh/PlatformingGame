class_name MovementSettings
extends Resource
## Every movement number lives here (plan §3.2). Edited live in the Feel Lab (F1).

@export_group("Ground")
@export var run_speed: float = 7.0
@export var walk_tilt: float = 0.5
@export var walk_speed_scale: float = 0.45
@export var accel_time: float = 0.12
@export var decel_time: float = 0.08
@export var turn_rate_deg: float = 720.0
@export var skid_angle_deg: float = 135.0
@export var attack_move_scale: float = 0.4

@export_group("Air")
@export var air_control: float = 0.55
## Fraction of air acceleration used to slow down when there's no stick input (keeps momentum).
@export var air_drag: float = 0.3
@export var j3_forward_boost: float = 1.5
@export var gravity_up: float = 28.0
@export var gravity_down: float = 45.0
@export var apex_gravity_scale: float = 0.55
@export var apex_threshold: float = 1.5
@export var terminal_fall: float = 22.0

@export_group("Jumps")
@export var jump_heights: PackedFloat32Array = PackedFloat32Array([1.8, 1.5, 2.4])
@export var short_hop_factor: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export var step_height: float = 0.35
@export var max_floor_angle_deg: float = 45.0

@export_group("Plunge and bounces")
@export var plunge_hang_ticks: int = 6
@export var plunge_speed: float = 24.0
@export var plunge_start_speed: float = 10.0
@export var plunge_accel: float = 180.0
@export var plunge_land_ticks: int = 14
@export var plunge_bounce_height: float = 2.2
@export var springcap_height: float = 3.0
@export var springcap_plunge_height: float = 8.5
@export var bouncer_height: float = 4.0

@export_group("Feel Lab toggles")
@export var mario_chain_mode: bool = false
@export var chain_window: float = 0.15
@export var chain_min_speed: float = 0.6
@export var prefer_ground_jump: bool = false
@export var prefer_ground_lookahead: float = 0.08

@export_group("Damage")
@export var invuln_time: float = 1.0
@export var hurt_ticks: int = 12
@export var heavy_hurt_ticks: int = 24
@export var ground_knockback: float = 1.5
@export var air_knockback: float = 0.5
@export var knockback_ticks: int = 12


## Launch speed for jump index 0..2 from its height: v = sqrt(2 * g_up * h).
func jump_velocity(index: int) -> float:
	return sqrt(2.0 * gravity_up * jump_heights[clampi(index, 0, 2)])


func launch_velocity(height: float) -> float:
	return sqrt(2.0 * gravity_up * height)
