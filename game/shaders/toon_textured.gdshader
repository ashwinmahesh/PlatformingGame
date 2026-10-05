// Sourced models whose colour lives in a texture (KayKit, Quaternius). Same toon light, violet
// shadows and rim as toon_palette, so mixed sources read as one game (plan §10.3). Build 6: a
// per-world tint (Toon.world_tint) and alpha cut-outs for leaves and petals.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float saturation = 1.3;
uniform vec3 warm_tint = vec3(1.03, 1.0, 0.97);
uniform float alpha_cut = 0.0;
uniform float use_vertex_color = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);

#include "res://shaders/toon_light.gdshaderinc"

void fragment() {
	vec4 t = texture(albedo_tex, UV);
	vec3 c = t.rgb * albedo_color.rgb * mix(vec3(1.0), COLOR.rgb, use_vertex_color);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l), c, saturation) * warm_tint;
	EMISSION = flash_color * flash;
	if (alpha_cut > 0.0) {
		ALPHA = t.a;
		ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	}
}
