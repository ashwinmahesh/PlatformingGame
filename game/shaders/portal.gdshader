// Dream Pool membrane: twisted polar UVs blending teal and magenta with sparkles (plan §10.3).
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 col_a : source_color = vec3(0.302, 0.941, 0.824);
uniform vec3 col_b : source_color = vec3(0.878, 0.353, 0.839);
uniform vec3 col_gold : source_color = vec3(1.0, 0.784, 0.239);
uniform float dormant = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float swirl = sin(a * 3.0 + r * 8.0 - TIME * 2.2) * 0.5 + 0.5;
	vec3 c = mix(col_a, col_b, swirl);
	float sparkle = step(0.985, fract(sin(dot(floor(uv * 24.0 + vec2(TIME * 2.0, 0.0)), vec2(12.9898, 78.233))) * 43758.5453));
	c = mix(c, col_gold, sparkle);
	c = mix(c, vec3(0.45, 0.42, 0.48), dormant);
	ALBEDO = c;
	ALPHA = 1.0 - smoothstep(0.92, 1.0, r);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
