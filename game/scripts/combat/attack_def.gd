class_name AttackDef
extends Resource
## One attack in physics ticks (plan §4.1). Animation is cosmetic and retimed to these numbers.

@export var id: StringName
@export var startup: int = 5
@export var active: int = 4
@export var recovery: int = 12
@export var damage: int = 1
@export var lunge: float = 0.0
## Recovery tick on which a stored press starts `next`. -1 means no combo.
@export var combo_open: int = -1
@export var next: AttackDef
@export var hitstop: int = 3
@export var knockback: float = 1.0
@export var radius: float = 0.9
@export var reach: float = 0.9
## Extra side-to-side span of the slash (Ashwin: "expand the horizontal space the sword slash
## can hit"). The hitbox is a capsule lying across the hero's facing: total width = width + 2r.
@export var width: float = 2.6
@export var is_air: bool = false
@export var sfx: StringName = &"slash"

enum Phase { STARTUP, ACTIVE, RECOVERY, DONE }


func total() -> int:
	return startup + active + recovery


func phase_at(tick: int) -> Phase:
	if tick < startup:
		return Phase.STARTUP
	if tick < startup + active:
		return Phase.ACTIVE
	if tick < total():
		return Phase.RECOVERY
	return Phase.DONE
