// Unshaded effect particles and flashes. Colour comes from a palette value times vertex colour.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = tint.a * COLOR.a;
}
