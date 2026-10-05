// Grass tufts and flowers drawn as MultiMeshes: toon light plus a gentle wind sway that grows
// with height (Build 4: "denser and more alive").
shader_type spatial;
// Drawn in the transparent pass so the screen-space ink outline ignores the thin blades.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 albedo_color : source_color = vec3(0.66, 0.84, 0.35);
uniform float sway = 0.12;
uniform float tip_lighten = 0.25;

#include "res://shaders/toon_light.gdshaderinc"

varying float height;

void vertex() {
	height = clamp(VERTEX.y * 4.0, 0.0, 1.0);
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float w = sin(TIME * 1.8 + world.x * 0.35 + world.z * 0.27) + 0.4 * sin(TIME * 3.1 + world.z * 0.6);
	VERTEX.x += w * sway * height;
	VERTEX.z += w * sway * 0.6 * height;
}

void fragment() {
	ALBEDO = albedo_color * (1.0 + tip_lighten * height);
	ALPHA = 1.0;
}
