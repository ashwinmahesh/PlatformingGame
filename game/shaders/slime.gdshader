// Slimes: toon light, a vertex wobble driven by script, a bright specular blob and a
// lighter shadow band that fakes a jelly glow. No skeleton (plan §10.3, §8.3).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D palette_tex : source_color, filter_nearest;
uniform vec2 cell = vec2(5.0, 3.0);
uniform float wobble = 0.03;
uniform float wobble_speed = 5.0;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float jelly_glow = 0.25;

#include "res://shaders/toon_light.gdshaderinc"

void vertex() {
	float w = sin(TIME * wobble_speed + VERTEX.y * 6.0 + VERTEX.x * 3.0);
	VERTEX += NORMAL * w * wobble;
}

void fragment() {
	vec3 base = texture(palette_tex, (cell + vec2(0.5)) / vec2(8.0, 4.0)).rgb;
	ALBEDO = base;
	EMISSION = base * jelly_glow * 0.35 + flash_color * flash;
	float spec = pow(clamp(dot(NORMAL, normalize(vec3(-0.3, 0.6, 0.75))), 0.0, 1.0), 40.0);
	EMISSION += vec3(spec) * 0.9;
}
