// Every surface in the game: palette colour x baked COLOR.rgb tint, toon light, optional flash and
// dither fade (for things blocking the camera). Plan §10.3. Build 5: terrain (anything with a top
// colour) gets soft painted patches on its upward faces, so big lawns and plateaus aren't flat.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D palette_tex : source_color, filter_nearest;
uniform vec2 cell = vec2(0.0);
// Optional second colour on upward-facing surfaces (grassy tops on rounded plateaus).
uniform vec2 top_cell = vec2(0.0);
uniform float top_amount = 0.0;
uniform float variation = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float fade = 0.0;

#include "res://shaders/toon_light.gdshaderinc"

varying vec3 world_pos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 grid = vec2(8.0, 6.0);
	vec3 base = texture(palette_tex, (cell + vec2(0.5)) / grid).rgb;
	if (top_amount > 0.0) {
		vec3 top = texture(palette_tex, (top_cell + vec2(0.5)) / grid).rgb;
		float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
		float k = smoothstep(0.45, 0.7, up);
		if (variation > 0.0) {
			float n = vnoise(world_pos.xz * 0.045) * 0.6 + vnoise(world_pos.xz * 0.17 + 7.3) * 0.4;
			float patch = smoothstep(0.38, 0.62, n);
			// Sunny yellow-green patches and deeper cool patches, like a painted lawn.
			// Pale tops (snow, sand) get cool blue-white patches instead of lawn tints.
			float sat = max(top.r, max(top.g, top.b)) - min(top.r, min(top.g, top.b));
			float pale = smoothstep(0.2, 0.06, sat);
			vec3 dark = mix(vec3(0.74, 0.86, 0.84), vec3(0.84, 0.9, 1.0), pale);
			vec3 light = mix(vec3(1.1, 1.08, 0.82), vec3(1.03, 1.03, 1.0), pale);
			top *= mix(dark, light, patch);
		}
		if (variation > 0.0) {
			// Wavy rock layers on cliff sides.
			float layer = fract(world_pos.y / 2.4 + vnoise(world_pos.xz * 0.08) * 0.8);
			base *= mix(0.9, 1.04, smoothstep(0.42, 0.5, layer));
		}
		base = mix(base, top, k * top_amount);
	}
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
