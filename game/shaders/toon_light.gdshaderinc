// Shared toon lighting (plan §10.3): one sun-facing band with a soft 0.03 edge,
// lilac shadows at 45%, and a warm fresnel^3 rim on the lit side.
uniform vec3 shadow_tint : source_color = vec3(0.549, 0.416, 0.549);
uniform float shadow_strength = 0.5;
uniform vec3 rim_color : source_color = vec3(1.0, 0.86, 0.62);
uniform float rim_amount = 0.22;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float shadow_band = smoothstep(0.3, 0.7, ATTENUATION);
	float band = smoothstep(0.0, 0.03, ndl) * shadow_band;
	vec3 light_col = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += light_col * mix(shadow_tint * shadow_strength, vec3(1.0), band);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * band;
	SPECULAR_LIGHT += light_col * rim_color * rim * rim_amount;
}
