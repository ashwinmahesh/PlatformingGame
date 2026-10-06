class_name Abilities
extends RefCounted
## Magic abilities (Ashwin: "unlock magic abilities throughout the game, some combat, some
## movement"; Build 7: "each level should give some kind of ability"). One per world, learned
## when its 3 Star Shards are in and the world is finished, alternating combat and movement.
## ORDER is also the number-key slot (1-9). Data only.

const ORDER: Array[StringName] = [&"fireball", &"vine", &"thunderclap", &"dash", &"frost", &"boots", &"orb", &"rush", &"roar"]

## id -> [name, key hint, how to use, what it's for, colour]
const INFO: Dictionary[StringName, Array] = {
	&"fireball": ["Fireball", "1 / R", "Press 1 or R (or pick it and RT) to throw a ball of fire.", "Lights torches, burns brambles, melts ice.", &"sunset_orange"],
	&"vine": ["Vinelash", "2 / G", "Press 2 or G near a glowing hook flower to zip up to it.", "Reach high places; with no flower near, it lashes a monster.", &"leaf_teal"],
	&"thunderclap": ["Thunderclap", "3 / C", "Press 3 or C (or LB) for a ring of thunder.", "Stuns every monster around you, even shielded ones; powers machines.", &"gold"],
	&"dash": ["Air Dash", "4 / V", "Press 4 or V (or RB) to dash, once per jump.", "Zip across gaps too wide to jump.", &"water_light"],
	&"frost": ["Frost Burst", "5", "Press 5 for a burst of frost.", "Freezes monsters solid and water into floes you can stand on.", &"foam"],
	&"boots": ["Spring Boots", "6", "Press 6 for a huge spring, once more in the air.", "Bound onto rooftops; kicks away whatever's beside you.", &"candy_pink"],
	&"orb": ["Gravity Orb", "7", "Press 7 to throw a gravity orb.", "Drags monsters into a vortex, then pops.", &"crystal_violet"],
	&"rush": ["Star Rush", "8", "Press 8 to sprint, untouchable, steering as you go.", "Bowl through monsters and blocks.", &"gold"],
	&"roar": ["Mighty Roar", "9", "Press 9 to roar.", "Stuns every monster far around, knocks shields away, drops flyers.", &"roof_red"],
}


static func display_name(id: StringName) -> String:
	return str((INFO.get(id, ["?"]) as Array)[0])
