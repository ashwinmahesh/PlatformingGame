class_name Toon
extends RefCounted
## Applies the one toon look to sourced models (plan §10.1: one shader, one palette, everything).
## Flat-colour materials map to palette entries by material name; atlas-textured materials keep
## their texture under the same toon light. Results are cached per source material.

const TEXTURED := preload("res://shaders/toon_textured.gdshader")
const COLORED := preload("res://shaders/toon_color.gdshader")

## Kenney Nature Kit material name -> palette colour (the pack's palette_map, plan §10.2).
const KENNEY_PALETTE_MAP: Dictionary[String, StringName] = {
	"woodBark": &"bark_mid", "woodBarkDark": &"bark_dark", "woodInner": &"thatch",
	"wood": &"wood_plank", "woodDark": &"wood_warm", "leafsGreen": &"grass_mid",
	"leafsDark": &"leaf_dark", "grass": &"grass_light", "dirt": &"bark_light",
	"stone": &"stone_light", "stoneDark": &"stone_dark", "colorRed": &"roof_red",
	"colorRedDark": &"roof_red", "colorYellow": &"gold", "colorPurple": &"portal_magenta",
	"colorTan": &"thatch", "_defaultMat": &"cloth_cream", "leafsFall": &"wood_warm",
	"leafsGreenLight": &"grass_light",
}

static var _cache: Dictionary[int, Material] = {}


static func clear_cache() -> void:
	_cache.clear()


## Replace every material under root. outline_width > 0 adds the ink hull (characters).
static func apply(root: Node, outline_width: float = 0.0, leaf_override: StringName = &"") -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var src := mi.get_active_material(s)
			mi.set_surface_override_material(s, to_toon(src, outline_width, leaf_override))


static func to_toon(src: Material, outline_width: float = 0.0, leaf_override: StringName = &"") -> Material:
	var key := (src.get_instance_id() if src != null else 0) ^ hash(outline_width) ^ hash(leaf_override)
	if _cache.has(key):
		return _cache[key]
	var out := ShaderMaterial.new()
	var bm := src as BaseMaterial3D
	if bm != null and bm.albedo_texture != null:
		out.shader = TEXTURED
		out.set_shader_parameter(&"albedo_tex", bm.albedo_texture)
		out.set_shader_parameter(&"albedo_color", bm.albedo_color)
	else:
		out.shader = COLORED
		var name := src.resource_name if src != null else ""
		var pal: StringName = KENNEY_PALETTE_MAP.get(name, &"")
		if leaf_override != &"" and name.begins_with("leafs"):
			pal = leaf_override
		var c: Color = Palette.color(pal) if pal != &"" else (bm.albedo_color if bm != null else Color.WHITE)
		out.set_shader_parameter(&"albedo_color", c)
	if outline_width > 0.0:
		out.next_pass = Kit.outline(outline_width)
	_cache[key] = out
	return out
