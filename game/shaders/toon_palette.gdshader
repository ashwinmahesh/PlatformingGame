// Every surface in the game: palette colour x baked COLOR.rgb tint, toon light, optional flash and
// dither fade (for things blocking the camera). Plan §10.3.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D palette_tex : source_color, filter_nearest;
uniform vec2 cell = vec2(0.0);
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float fade = 0.0;

#include "res://shaders/toon_light.gdshaderinc"

void fragment() {
	vec3 base = texture(palette_tex, (cell + vec2(0.5)) / vec2(8.0, 4.0)).rgb;
	ALBEDO = base * COLOR.rgb;
	EMISSION = flash_color * flash;
	if (fade > 0.0) {
		vec2 p = floor(FRAGCOORD.xy);
		float threshold = fract(dot(p, vec2(0.5, 0.25)) + 0.25 * mod(p.y, 2.0));
		if (threshold < fade) {
			discard;
		}
	}
}
