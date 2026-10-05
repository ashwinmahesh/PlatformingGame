class_name Abilities
extends RefCounted
## Build 5 magic abilities (Ashwin: "unlock magic abilities throughout the game, some combat,
## some movement"). One per world cleared, alternating combat and movement. Data only.

const ORDER: Array[StringName] = [&"fireball", &"glide", &"thunderclap", &"dash"]

## id -> [name, key hint, how to use, what it's for, colour]
const INFO: Dictionary[StringName, Array] = {
	&"fireball": ["Fireball", "R", "Press R (or RT) to throw a ball of fire.", "Lights lanterns, burns brambles, melts ice.", &"sunset_orange"],
	&"glide": ["Glide", "Hold Space", "Hold Space while falling to float under a flower.", "Cross wide gaps; ride the wind higher.", &"candy_pink"],
	&"thunderclap": ["Thunderclap", "C", "Press C (or LB) for a ring of thunder.", "Stuns every monster around you, even shielded ones.", &"gold"],
	&"dash": ["Air Dash", "V", "Press V (or RB) to dash, once per jump.", "Zip across gaps too wide to jump.", &"water_light"],
}


static func display_name(id: StringName) -> String:
	return str((INFO.get(id, ["?"]) as Array)[0])
