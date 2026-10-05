// Sourced models whose colour lives in a texture atlas (KayKit). Same toon light, lilac
// shadows and rim as toon_palette, so mixed sources read as one game (plan §10.3).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float saturation = 1.15;
uniform vec3 warm_tint : source_color = vec3(1.05, 1.0, 0.9);
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);

#include "res://shaders/toon_light.gdshaderinc"

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb * albedo_color.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l), c, saturation) * warm_tint;
	EMISSION = flash_color * flash;
}
