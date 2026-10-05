// Leaf-swirl wipe for scene transitions (canvas). progress 0 = clear, 1 = covered.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 col_a : source_color = vec3(0.184, 0.49, 0.227);
uniform vec3 col_b : source_color = vec3(0.365, 0.702, 0.231);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= 1.78;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float leaves = sin(a * 7.0 + r * 14.0) * 0.06;
	float edge = (1.0 - progress) * 1.25 - 0.1;
	float cover = step(edge, r + leaves);
	vec3 c = mix(col_a, col_b, step(0.0, sin(a * 7.0 + r * 14.0)));
	COLOR = vec4(c, cover * step(0.001, progress));
}
