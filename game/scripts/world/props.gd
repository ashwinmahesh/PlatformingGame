class_name Props
extends RefCounted
## Sourced-model registry (docs/assets/LICENSES.md lists every source). Each entry: path, the scale
## that brings it to game size, and the collision it gets. Logic and collision live here, in
## the wrapper, never in the imported scene (plan §7.6).

const K := "res://assets/models/kenney_nature/"
const M := "res://assets/models/kaykit_medieval/"
const Q := "res://assets/models/q_nature/"
const P := "res://assets/models/q_props/"

enum Col { NONE, BOX, TRUNK, CONVEX }

## id -> [path, scale, collision]
const TABLE: Dictionary[StringName, Array] = {
	&"tree_default": [K + "tree_default.glb", 4.2, Col.TRUNK],
	&"tree_oak": [K + "tree_oak.glb", 5.0, Col.TRUNK],
	&"tree_detailed": [K + "tree_detailed.glb", 5.0, Col.TRUNK],
	&"tree_fat": [K + "tree_fat.glb", 5.0, Col.TRUNK],
	&"tree_tall": [K + "tree_tall.glb", 4.5, Col.TRUNK],
	&"tree_pine": [K + "tree_pineRoundA.glb", 5.0, Col.TRUNK],
	&"tree_cone": [K + "tree_cone.glb", 5.0, Col.TRUNK],
	&"tree_simple": [K + "tree_simple.glb", 4.5, Col.TRUNK],
	&"rock_large_a": [K + "rock_largeA.glb", 4.0, Col.CONVEX],
	&"rock_large_b": [K + "rock_largeB.glb", 4.0, Col.CONVEX],
	&"rock_large_c": [K + "rock_largeC.glb", 4.0, Col.CONVEX],
	&"rock_tall_a": [K + "rock_tallA.glb", 3.0, Col.CONVEX],
	&"rock_tall_b": [K + "rock_tallB.glb", 3.0, Col.CONVEX],
	&"rock_small": [K + "rock_smallA.glb", 3.0, Col.NONE],
	&"rock_small_c": [K + "rock_smallC.glb", 3.0, Col.NONE],
	&"stone_tall": [K + "stone_tallA.glb", 3.0, Col.CONVEX],
	&"bush": [K + "plant_bush.glb", 3.5, Col.NONE],
	&"bush_large": [K + "plant_bushLarge.glb", 4.5, Col.NONE],
	&"bush_detailed": [K + "plant_bushDetailed.glb", 3.5, Col.NONE],
	&"bush_small": [K + "plant_bushSmall.glb", 3.0, Col.NONE],
	&"flower_red": [K + "flower_redA.glb", 3.0, Col.NONE],
	&"flower_red_b": [K + "flower_redB.glb", 3.0, Col.NONE],
	&"flower_yellow": [K + "flower_yellowA.glb", 3.0, Col.NONE],
	&"flower_yellow_b": [K + "flower_yellowB.glb", 3.0, Col.NONE],
	&"flower_purple": [K + "flower_purpleA.glb", 3.0, Col.NONE],
	&"grass": [K + "grass.glb", 3.0, Col.NONE],
	&"grass_large": [K + "grass_large.glb", 3.0, Col.NONE],
	&"grass_leafs": [K + "grass_leafs.glb", 3.0, Col.NONE],
	&"mushroom_red": [K + "mushroom_red.glb", 4.0, Col.NONE],
	&"mushroom_red_group": [K + "mushroom_redGroup.glb", 4.0, Col.NONE],
	&"mushroom_tan_group": [K + "mushroom_tanGroup.glb", 4.0, Col.NONE],
	&"mushroom_red_tall": [K + "mushroom_redTall.glb", 4.0, Col.NONE],
	&"log": [K + "log.glb", 4.0, Col.CONVEX],
	&"log_large": [K + "log_large.glb", 4.0, Col.CONVEX],
	&"log_stack": [K + "log_stack.glb", 3.5, Col.CONVEX],
	&"stump": [K + "stump_round.glb", 4.0, Col.CONVEX],
	&"stump_old": [K + "stump_old.glb", 4.0, Col.CONVEX],
	&"lily_large": [K + "lily_large.glb", 6.0, Col.NONE],
	&"lily_small": [K + "lily_small.glb", 6.0, Col.NONE],
	&"fence": [K + "fence_simple.glb", 3.0, Col.BOX],
	&"fence_high": [K + "fence_simpleHigh.glb", 3.0, Col.BOX],
	&"sign": [K + "sign.glb", 3.0, Col.NONE],
	&"campfire": [K + "campfire_logs.glb", 4.0, Col.NONE],
	&"tent_small": [K + "tent_smallOpen.glb", 4.0, Col.BOX],
	&"pot": [K + "pot_large.glb", 3.0, Col.NONE],
	&"obelisk": [K + "statue_obelisk.glb", 3.0, Col.BOX],
	&"column": [K + "statue_column.glb", 3.0, Col.BOX],
	&"hanging_moss": [K + "hanging_moss.glb", 3.0, Col.NONE],
	&"cactus_short": [K + "cactus_short.glb", 4.0, Col.TRUNK],
	&"cactus_tall": [K + "cactus_tall.glb", 4.0, Col.TRUNK],
	&"palm": [K + "tree_palm.glb", 4.5, Col.TRUNK],
	&"palm_tall": [K + "tree_palmTall.glb", 4.5, Col.TRUNK],
	&"palm_bend": [K + "tree_palmBend.glb", 4.5, Col.TRUNK],
	&"palm_detailed": [K + "tree_palmDetailedTall.glb", 4.5, Col.TRUNK],
	&"rock_tall_c": [K + "rock_tallC.glb", 3.0, Col.CONVEX],
	&"rock_tall_d": [K + "rock_tallD.glb", 3.0, Col.CONVEX],
	&"rock_tall_e": [K + "rock_tallE.glb", 3.0, Col.CONVEX],
	&"rock_large_d": [K + "rock_largeD.glb", 4.0, Col.CONVEX],
	&"column_broken": [K + "statue_columnDamaged.glb", 3.0, Col.BOX],
	&"statue_block": [K + "statue_block.glb", 3.0, Col.BOX],
	&"statue_head": [K + "statue_head.glb", 3.0, Col.CONVEX],
	&"statue_ring": [K + "statue_ring.glb", 3.0, Col.NONE],
	&"stone_tall_b": [K + "stone_tallB.glb", 3.0, Col.CONVEX],
	&"stone_tall_c": [K + "stone_tallC.glb", 3.0, Col.CONVEX],
	&"stone_large_b": [K + "stone_largeB.glb", 4.0, Col.CONVEX],
	&"tent_big": [K + "tent_detailedOpen.glb", 4.0, Col.BOX],
	&"campfire_stones": [K + "campfire_stones.glb", 4.0, Col.NONE],
	&"pumpkin": [K + "crop_pumpkin.glb", 4.0, Col.NONE],
	&"pine_tall": [K + "tree_pineTallA.glb", 5.0, Col.TRUNK],
	&"pine_default": [K + "tree_pineDefaultA.glb", 5.0, Col.TRUNK],
	&"pine_small": [K + "tree_pineSmallA.glb", 4.0, Col.TRUNK],
	&"tree_blocks": [K + "tree_blocks.glb", 5.0, Col.TRUNK],
	&"tree_plateau": [K + "tree_plateau.glb", 5.0, Col.TRUNK],
	# Build 6 asset swap: Quaternius Stylized Nature MegaKit and Fantasy Props MegaKit (CC0).
	&"q_bush": [Q + "Bush_Common.gltf", 1.0, Col.NONE],
	&"q_bush_flowers": [Q + "Bush_Common_Flowers.gltf", 1.0, Col.NONE],
	&"q_flowers_3": [Q + "Flower_3_Group.gltf", 1.4, Col.NONE],
	&"q_flowers_4": [Q + "Flower_4_Group.gltf", 1.4, Col.NONE],
	&"q_fern": [Q + "Fern_1.gltf", 1.3, Col.NONE],
	&"q_mushrooms": [Q + "Mushroom_Common.gltf", 1.6, Col.NONE],
	&"q_mushroom_shelf": [Q + "Mushroom_Laetiporus.gltf", 1.6, Col.NONE],
	&"q_pebble": [Q + "Pebble_Round_2.gltf", 1.6, Col.NONE],
	&"q_pebble_square": [Q + "Pebble_Square_3.gltf", 1.6, Col.NONE],
	&"q_rock_1": [Q + "Rock_Medium_1.gltf", 1.2, Col.CONVEX],
	&"q_rock_2": [Q + "Rock_Medium_2.gltf", 1.2, Col.CONVEX],
	&"q_rock_3": [Q + "Rock_Medium_3.gltf", 1.2, Col.CONVEX],
	&"q_plant": [Q + "Plant_1_Big.gltf", 1.2, Col.NONE],
	&"q_clover": [Q + "Clover_1.gltf", 1.5, Col.NONE],
	&"q_tree_1": [Q + "CommonTree_1.gltf", 1.0, Col.TRUNK],
	&"q_tree_2": [Q + "CommonTree_2.gltf", 1.0, Col.TRUNK],
	&"q_tree_3": [Q + "CommonTree_3.gltf", 1.0, Col.TRUNK],
	&"q_tree_4": [Q + "CommonTree_4.gltf", 1.0, Col.TRUNK],
	&"q_tree_5": [Q + "CommonTree_5.gltf", 1.0, Col.TRUNK],
	&"q_pine_1": [Q + "Pine_1.gltf", 1.0, Col.TRUNK],
	&"q_pine_2": [Q + "Pine_2.gltf", 1.0, Col.TRUNK],
	&"q_pine_3": [Q + "Pine_3.gltf", 1.0, Col.TRUNK],
	&"q_twisted_1": [Q + "TwistedTree_1.gltf", 1.0, Col.TRUNK],
	&"q_twisted_2": [Q + "TwistedTree_2.gltf", 1.0, Col.TRUNK],
	&"q_barrel": [P + "Barrel.gltf", 1.0, Col.BOX],
	&"q_barrel_apples": [P + "Barrel_Apples.gltf", 1.0, Col.BOX],
	&"q_crate": [P + "Crate_Wooden.gltf", 1.0, Col.BOX],
	&"q_farm_crate": [P + "FarmCrate_Apple.gltf", 1.0, Col.BOX],
	&"q_cart": [P + "Stall_Cart_Empty.gltf", 1.0, Col.BOX],
	&"q_stall": [P + "Stall_Empty.gltf", 1.0, Col.BOX],
	&"q_bench": [P + "Bench.gltf", 1.0, Col.BOX],
	&"q_cauldron": [P + "Cauldron.gltf", 1.0, Col.BOX],
	&"q_chest": [P + "Chest_Wood.gltf", 1.0, Col.BOX],
	&"q_banner_1": [P + "Banner_1.gltf", 1.0, Col.NONE],
	&"q_banner_2": [P + "Banner_2.gltf", 1.0, Col.NONE],
	&"q_table": [P + "Table_Large.gltf", 1.0, Col.BOX],
	&"q_anvil": [P + "Anvil.gltf", 1.0, Col.BOX],
	&"q_workbench": [P + "Workbench.gltf", 1.0, Col.BOX],
	&"q_bucket": [P + "Bucket_Wooden_1.gltf", 1.0, Col.NONE],
	&"q_torch": [P + "Torch_Metal.gltf", 1.0, Col.NONE],
	&"home_a_blue": [M + "building_home_A_blue.gltf", 6.0, Col.BOX],
	&"home_a_green": [M + "building_home_A_green.gltf", 6.0, Col.BOX],
	&"home_b_red": [M + "building_home_B_red.gltf", 6.0, Col.BOX],
	&"market": [M + "building_market_yellow.gltf", 5.0, Col.BOX],
	&"windmill": [M + "building_windmill_blue.gltf", 6.0, Col.BOX],
	&"well": [M + "building_well_red.gltf", 5.0, Col.BOX],
	&"tower": [M + "building_tower_A_green.gltf", 5.0, Col.BOX],
	&"village_fence": [M + "fence_wood_straight.gltf", 3.0, Col.BOX],
	&"barrel": [M + "barrel.gltf", 6.0, Col.BOX],
	&"crate": [M + "crate_A_big.gltf", 6.0, Col.BOX],
	&"crate_small": [M + "crate_B_small.gltf", 6.0, Col.BOX],
	&"flag": [M + "flag_red.gltf", 6.0, Col.NONE],
	&"tent": [M + "tent.gltf", 6.0, Col.BOX],
	&"target": [M + "target.gltf", 6.0, Col.NONE],
	&"sack": [M + "sack.gltf", 6.0, Col.NONE],
	&"wheelbarrow": [M + "wheelbarrow.gltf", 6.0, Col.NONE],
	&"lumber": [M + "resource_lumber.gltf", 5.0, Col.NONE],
	&"forest_cluster": [M + "trees_A_large.gltf", 9.0, Col.NONE],
	&"forest_cluster_b": [M + "trees_B_large.gltf", 9.0, Col.NONE],
	&"forest_medium": [M + "trees_A_medium.gltf", 9.0, Col.NONE],
	&"hills_trees": [M + "hills_A_trees.gltf", 14.0, Col.NONE],
	&"mountain": [M + "mountain_A_grass_trees.gltf", 22.0, Col.NONE],
	&"cloud_big": [M + "cloud_big.gltf", 7.0, Col.NONE],
	&"cloud_small": [M + "cloud_small.gltf", 7.0, Col.NONE],
	&"waterlily": [M + "waterlily_B.gltf", 9.0, Col.NONE],
	&"waterplant": [M + "waterplant_A.gltf", 6.0, Col.NONE],
}

## Far backdrop pieces never cast shadows (a mountain's shadow would darken the whole level).
const NO_SHADOW: Array[StringName] = [&"mountain", &"hills_trees", &"forest_cluster", &"forest_cluster_b", &"forest_medium", &"cloud_big", &"cloud_small"]

## Built shapes keep their crisp edges; everything natural gets smooth normals (Build 3: rounder).
const KEEP_FACETS: Array[StringName] = [&"column_broken", &"statue_block", &"tent_big", &"home_a_blue", &"home_a_green", &"home_b_red", &"market", &"windmill", &"well", &"tower", &"village_fence", &"barrel", &"crate", &"crate_small", &"flag", &"tent", &"target", &"sack", &"wheelbarrow", &"lumber", &"fence", &"fence_high", &"sign", &"obelisk", &"column", &"tent_small"]

static var _scenes: Dictionary[StringName, PackedScene] = {}

## Build 5 ("vibrant, whimsical, like Dragon Quest"): every Kenney tree is drawn as a Whimsy
## puffball tree or storybook pine instead. 0 = puffball, 1 = pine.
const WHIMSY_TREES: Dictionary[StringName, int] = {
	&"tree_default": 0, &"tree_oak": 0, &"tree_detailed": 0, &"tree_fat": 0, &"tree_tall": 0,
	&"tree_simple": 0, &"tree_blocks": 0, &"tree_plateau": 0,
	&"tree_pine": 1, &"tree_cone": 1, &"pine_tall": 1, &"pine_default": 1, &"pine_small": 1,
}
## Build 6 asset swap: Kenney decoration ids now draw the Quaternius equivalents.
const SWAP: Dictionary[StringName, Array] = {
	&"flower_red": [&"q_flowers_3", 1.0], &"flower_red_b": [&"q_flowers_4", 1.0],
	&"flower_yellow": [&"q_flowers_4", 1.0], &"flower_yellow_b": [&"q_flowers_3", 1.0], &"flower_purple": [&"q_flowers_3", 1.0],
	&"grass_leafs": [&"q_fern", 1.0], &"mushroom_red_group": [&"q_mushrooms", 1.0], &"mushroom_tan_group": [&"q_mushrooms", 0.9],
	&"mushroom_red": [&"q_mushroom_shelf", 1.0], &"rock_small": [&"q_pebble", 1.0], &"rock_small_c": [&"q_pebble_square", 1.0],
	&"rock_large_a": [&"q_rock_1", 1.0], &"rock_large_b": [&"q_rock_2", 1.0], &"rock_large_c": [&"q_rock_3", 1.0],
	&"barrel": [&"q_barrel", 1.0], &"crate": [&"q_crate", 1.0], &"crate_small": [&"q_crate", 0.7], &"wheelbarrow": [&"q_cart", 0.9],
}
const Q_TREES: Array[StringName] = [&"q_tree_1", &"q_tree_2", &"q_tree_3", &"q_tree_4", &"q_tree_5"]
const Q_PINES: Array[StringName] = [&"q_pine_1", &"q_pine_2", &"q_pine_3"]
## Buildings are drawn 25% bigger (Ashwin: "all the buildings should be a little bigger").
const BUILDING_SCALE := 1.25
const BUILDINGS: Array[StringName] = [&"home_a_blue", &"home_a_green", &"home_b_red", &"market", &"windmill", &"well", &"tent_big", &"tent_small", &"tent"]

## Tree colours a level wants (set in its build()); picked per tree by position.
static var tree_kinds: Array[StringName] = [&"green", &"lime", &"green", &"teal", &"blossom", &"green", &"autumn"]
## Leaf overrides map to tree kinds.
const LEAF_KINDS: Dictionary[StringName, StringName] = {&"leaf_dark": &"green", &"leaf_teal": &"teal", &"grass_light": &"lime", &"wood_warm": &"autumn", &"gloop_pink": &"blossom"}


static func clear_cache() -> void:
	_scenes.clear()


static func exists(id: StringName) -> bool:
	return TABLE.has(id)


## Spawn a prop with its base at `pos`. scale_mul multiplies the table scale.
static func spawn(parent: Node, id: StringName, pos: Vector3, yaw: float = 0.0, scale_mul: float = 1.0, collide: bool = true, leaf: StringName = &"") -> Node3D:
	assert(TABLE.has(id), "Unknown prop %s" % id)
	if SWAP.has(id):
		var sw: Array = SWAP[id]
		return spawn(parent, sw[0] as StringName, pos, yaw, scale_mul * float(sw[1]), collide, leaf)
	if id in BUILDINGS:
		scale_mul *= BUILDING_SCALE
	if WHIMSY_TREES.has(id):
		var h := absi(hash(Vector2i(int(pos.x), int(pos.z))))
		var kind: StringName = LEAF_KINDS.get(leaf, tree_kinds[h % tree_kinds.size()])
		# Green trees and pines use the Quaternius models; the colourful kinds stay storybook.
		if kind in [&"green", &"lime"]:
			var qid: StringName = Q_PINES[h % Q_PINES.size()] if WHIMSY_TREES[id] == 1 else Q_TREES[h % Q_TREES.size()]
			return spawn(parent, qid, pos, yaw, scale_mul * 0.95, collide)
		if WHIMSY_TREES[id] == 1:
			return Whimsy.pine(parent, pos, kind, scale_mul * 0.9, collide)
		return Whimsy.tree(parent, pos, kind, scale_mul * 0.85, -1, yaw, collide)
	var spec: Array = TABLE[id]
	if not _scenes.has(id):
		_scenes[id] = load(str(spec[0])) as PackedScene
	var holder := Node3D.new()
	holder.name = String(id)
	holder.position = pos
	holder.rotation.y = yaw
	parent.add_child(holder)
	var model := _scenes[id].instantiate() as Node3D
	var s := float(spec[1]) * scale_mul
	model.scale = Vector3.ONE * s
	holder.add_child(model)
	Toon.apply(model, 0.0, leaf)
	if id not in KEEP_FACETS and not String(id).begins_with("q_"):
		for n in model.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			mi.mesh = RoundMesh.smoothed(mi.mesh)
	for n in model.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if id in NO_SHADOW else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if collide:
		_add_collision(holder, model, int(spec[2]), s)
	return holder


static func _add_collision(holder: Node3D, model: Node3D, kind: int, s: float) -> void:
	if kind == Col.NONE:
		return
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	holder.add_child(body)
	var box := bounds(model)
	match kind:
		Col.BOX:
			var b := BoxShape3D.new()
			b.size = box.size
			Kit.add_shape(body, b, box.get_center())
		Col.TRUNK:
			var c := CylinderShape3D.new()
			c.radius = clampf(minf(box.size.x, box.size.z) * 0.12, 0.25, 0.6)
			c.height = box.size.y * 0.55
			Kit.add_shape(body, c, Vector3(box.get_center().x, c.height * 0.5, box.get_center().z))
		Col.CONVEX:
			for n in model.find_children("*", "MeshInstance3D", true, false):
				var mi := n as MeshInstance3D
				var cs := CollisionShape3D.new()
				cs.shape = mi.mesh.create_convex_shape(true, true)
				body.add_child(cs)
				cs.transform = _to_local(holder, mi)


## Merged AABB of every mesh under root, in root's parent space.
static func bounds(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b := _to_local(root.get_parent() as Node3D, mi) * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


static func _to_local(ancestor: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != ancestor:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
