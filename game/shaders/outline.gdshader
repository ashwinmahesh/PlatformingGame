// Ink outline, added as next_pass on characters and key props (plan §10.3).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec3 ink : source_color = vec3(0.169, 0.133, 0.22);
uniform float width = 0.03;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = ink;
}
