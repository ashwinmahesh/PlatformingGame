extends Node
## Small cross-scene signal bus (plan §9.2). Keep it small.

signal boss_defeated(world_id: StringName)
signal checkpoint_reached(checkpoint_id: StringName)
signal seed_collected(seed_id: StringName)
signal notice(text: String)
