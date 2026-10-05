// Three-colour gradient sky with a sun disc and soft cloud bands (plan §10.3).
shader_type sky;

uniform vec3 top_col : source_color = vec3(0.431, 0.776, 1.0);
uniform vec3 horizon_col : source_color = vec3(0.749, 0.902, 1.0);
uniform vec3 bottom_col : source_color = vec3(0.62, 0.84, 0.92);

void sky() {
	float y = EYEDIR.y;
	vec3 c = mix(horizon_col, top_col, smoothstep(0.0, 0.55, y));
	c = mix(c, bottom_col, smoothstep(0.0, -0.3, y));
	float sun = dot(EYEDIR, LIGHT0_DIRECTION);
	c = mix(c, vec3(1.0, 0.97, 0.88), smoothstep(0.9975, 0.999, sun));
	vec2 cp = EYEDIR.xz / max(EYEDIR.y + 0.25, 0.05);
	float cloud = sin(cp.x * 0.9 + TIME * 0.02) * sin(cp.y * 1.3 + 1.7) + sin(cp.x * 2.3 - cp.y * 1.1) * 0.35;
	float mask = smoothstep(0.02, 0.35, y) * (1.0 - smoothstep(0.55, 0.8, y));
	c = mix(c, vec3(1.0), smoothstep(0.55, 0.62, cloud) * mask * 0.85);
	COLOR = c;
}
