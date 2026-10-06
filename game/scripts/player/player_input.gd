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
## Build 5 magic.
var fireball_pressed: bool = false
var clap_pressed: bool = false
var dash_pressed: bool = false
## Build 7: the Vinelash, number keys 1-9 (ability slots), and the gamepad's pick-and-cast.
var vine_pressed: bool = false
var cast_slot: int = -1
var cast_selected_pressed: bool = false
var select_step: int = 0
## Shop bonus magic: Seed Sense (key 0).
var sense_pressed: bool = false
