class_name PlayerInput
extends RefCounted
## One tick of normalised input: button edges and stick axes (plan §3.3 step 1).

var move: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false
var attack_pressed: bool = false
var plunge_pressed: bool = false
var plunge_held: bool = false
var interact_pressed: bool = false
var lock_pressed: bool = false
var lock_held: bool = false
var lock_released: bool = false
var switch_target_pressed: bool = false
