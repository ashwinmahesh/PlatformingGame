// Screen-space ink outlines (Build 2 feedback: "harder borders, cartoonish"). Draws dark-plum
// lines wherever depth or surface direction jumps between neighbouring pixels, so every model,
// sourced or built, gets the same bold border. Runs on a full-screen quad in front of the camera.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform vec3 ink : source_color = vec3(0.169, 0.133, 0.22);
uniform float thickness = 2.0;
uniform float depth_threshold = 0.06;
uniform float normal_threshold = 0.55;
uniform float fade_start = 70.0;
uniform float fade_end = 160.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float view_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_tex, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float dc = view_depth(uv, INV_PROJECTION_MATRIX);
	vec3 nc = view_normal(uv);
	float edge = 0.0;
	vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	for (int i = 0; i < 4; i++) {
		vec2 suv = uv + offs[i];
		float ds = view_depth(suv, INV_PROJECTION_MATRIX);
		// Only the nearer pixel draws the line, so borders hug the object in front.
		float dd = (ds - dc) / max(dc, 0.001);
		edge = max(edge, step(depth_threshold, dd));
		float nd = 1.0 - dot(nc, view_normal(suv));
		edge = max(edge, step(normal_threshold, nd) * step(-0.02, dd));
	}
	float fade = 1.0 - smoothstep(fade_start, fade_end, dc);
	ALBEDO = ink;
	ALPHA = edge * fade;
}
