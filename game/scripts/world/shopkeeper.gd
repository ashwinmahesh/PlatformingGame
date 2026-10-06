class_name Shopkeeper
extends Npc
## Build 7: Bramble & Bloom's keeper in Mossbrook. Talking opens the Glimmer Seed shop.


func interact(p: Player) -> void:
	if get_tree().root.find_children("*", "ShopPanel", false, false).is_empty():
		ShopPanel.open(p)
