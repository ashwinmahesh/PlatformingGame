// Shared toon lighting (plan §10.3, Build 5 "vibrant and whimsical"): one sun-facing band with a
// soft edge, saturated violet shadows that keep colours bright, and a golden fresnel rim on the
// lit side. Ambient comes from the sky (blue from above), so shadows read cool and colourful.
uniform vec3 shadow_tint : source_color = vec3(0.455, 0.4, 0.769);
uniform float shadow_strength = 0.62;
uniform vec3 rim_color : source_color = vec3(1.0, 0.9, 0.62);
uniform float rim_amount = 0.32;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float shadow_band = smoothstep(0.3, 0.7, ATTENUATION);
	float band = smoothstep(0.0, 0.06, ndl) * shadow_band;
	vec3 light_col = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += light_col * mix(shadow_tint * shadow_strength, vec3(1.0), band);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * band;
	SPECULAR_LIGHT += light_col * rim_color * rim * rim_amount;
}
