class_name Layers
extends RefCounted
## Collision layers (docs/contracts/collision.md). Code refers to layers only through these.

const WORLD := 1 << 0
const PLAYER_BODY := 1 << 1
const ENEMY_BODY := 1 << 2
const PLAYER_HURTBOX := 1 << 3
const ENEMY_HURTBOX := 1 << 4
const PLAYER_ATTACK := 1 << 5
const ENEMY_ATTACK := 1 << 6
const INTERACT := 1 << 7
const HAZARD := 1 << 8
const CAMERA_BLOCKER := 1 << 9
const PICKUP := 1 << 10
const BOUNCE := 1 << 11
const REFLECTABLE := 1 << 12
