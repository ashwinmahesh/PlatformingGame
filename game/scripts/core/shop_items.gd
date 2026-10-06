class_name ShopItems
extends RefCounted
## Build 7 Glimmer Seed shop in Mossbrook (Ashwin: "exchange Glimmer Seeds for rewards at the hub:
## better swords, magic abilities, etc"). Upgrades only, never a downgrade, plus one bonus ability
## (Seed Sense). World abilities are never sold. Prices: the seeds from Worlds 1-6 buy a good share;
## the rest needs the new worlds. Data only.

## id -> [name, price, description, needs (id bought first, or "")]
const ITEMS: Dictionary[StringName, Array] = {
	&"blade_1": ["Thornedge Blade", 15, "Your sword reaches 25% further and sweeps wider.", ""],
	&"blade_2": ["Bloomsteel Blade", 45, "Reaches further still, and every slash hits harder.", "blade_1"],
	&"heart_1": ["Heart Seedling", 10, "One more heart.", ""],
	&"heart_2": ["Heart Sapling", 25, "One more heart.", "heart_1"],
	&"heart_3": ["Heart Oak", 45, "One more heart.", "heart_2"],
	&"fireball_big": ["Blaze Charm", 20, "Fireballs grow bigger and hit harder.", ""],
	&"dash_long": ["Gale Feather", 15, "Air Dash carries you half as far again.", ""],
	&"vine_quick": ["Quickvine Seed", 15, "Vinelash reaches further and recovers twice as fast.", ""],
	&"magnet": ["Seed Magnet", 12, "Pickups drift to you from much further away.", ""],
	&"seed_sense": ["Seed Sense (0)", 30, "Bonus magic: press 0 and a beam points to the nearest seed you haven't found.", ""],
	&"hat_party": ["Party Hat", 5, "A paper party hat. Purely for fun.", ""],
	&"hat_crown": ["Little Crown", 60, "A golden crown for the hero who has everything.", ""],
}

const ORDER: Array[StringName] = [&"blade_1", &"blade_2", &"heart_1", &"heart_2", &"heart_3", &"fireball_big", &"dash_long", &"vine_quick", &"magnet", &"seed_sense", &"hat_party", &"hat_crown"]


static func price(id: StringName) -> int:
	return int((ITEMS.get(id, ["", 999]) as Array)[1])


static func needs(id: StringName) -> StringName:
	return StringName(str((ITEMS.get(id, ["", 0, "", ""]) as Array)[3]))
