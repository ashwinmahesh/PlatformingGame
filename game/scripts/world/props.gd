class_name Props
extends RefCounted
## Sourced-model registry (docs/assets/LICENSES.md lists every source). Each entry: path, the scale
## that brings it to game size, and the collision it gets. Logic and collision live here, in
## the wrapper, never in the imported scene (plan §7.6).

const K := "res://assets/models/kenney_nature/"
const M := "res://assets/models/kaykit_medieval/"

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


static func clear_cache() -> void:
	_scenes.clear()


static func exists(id: StringName) -> bool:
	return TABLE.has(id)


## Spawn a prop with its base at `pos`. scale_mul multiplies the table scale.
static func spawn(parent: Node, id: StringName, pos: Vector3, yaw: float = 0.0, scale_mul: float = 1.0, collide: bool = true, leaf: StringName = &"") -> Node3D:
	assert(TABLE.has(id), "Unknown prop %s" % id)
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
	if id not in KEEP_FACETS:
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
