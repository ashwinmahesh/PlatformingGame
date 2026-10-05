// River water: colour bands, scrolling foam lines, small vertex waves. Visually opaque, no refraction.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 light_col : source_color = vec3(0.498, 0.878, 0.941);
uniform vec3 mid_col : source_color = vec3(0.224, 0.663, 0.859);
uniform vec3 deep_col : source_color = vec3(0.165, 0.435, 0.69);
uniform vec3 foam_col : source_color = vec3(0.957, 0.984, 1.0);
uniform vec2 flow = vec2(0.0, 0.6);
uniform bool vertical = false;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 0.8 + TIME * 1.5) * 0.04 + cos(world_pos.z * 0.6 + TIME * 1.1) * 0.04;
}

void fragment() {
	vec2 p = (vertical ? world_pos.xy : world_pos.xz) * 0.35 + flow * TIME;
	float n = sin(p.x * 2.1 + sin(p.y * 1.3)) * 0.5 + 0.5;
	n = n * 0.6 + (sin(p.y * 3.7 + p.x * 0.7) * 0.5 + 0.5) * 0.4;
	vec3 c = mix(deep_col, mid_col, step(0.35, n));
	c = mix(c, light_col, step(0.72, n));
	float foam = step(0.94, sin(p.y * 6.0 + sin(p.x * 2.0) * 1.5) * 0.5 + 0.5);
	ALBEDO = mix(c, foam_col, foam * 0.85);
}
