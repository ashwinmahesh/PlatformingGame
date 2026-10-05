// Sourced models with flat-colour materials (Kenney). The colour is a palette entry chosen by
// material name in Toon.KENNEY_PALETTE_MAP, never the pack's own colour.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 albedo_color : source_color = vec3(1.0);

#include "res://shaders/toon_light.gdshaderinc"

void fragment() {
	ALBEDO = albedo_color;
}
