// Storybook sky (Build 5, "like Dragon Quest"): deep blue overhead fading to a pale horizon, a
// warm glow round the sun, and big puffy toon clouds with crisp edges and lilac undersides.
// Static (no TIME), so the sky-lit ambient is computed once.
shader_type sky;

uniform vec3 top_col : source_color = vec3(0.16, 0.5, 0.98);
uniform vec3 horizon_col : source_color = vec3(0.78, 0.92, 1.0);
uniform vec3 bottom_col : source_color = vec3(0.86, 0.93, 1.0);
uniform vec3 cloud_col : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade : source_color = vec3(0.76, 0.78, 0.98);
uniform float cloud_cover = 0.42;
uniform vec3 sun_glow : source_color = vec3(1.0, 0.85, 0.55);

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	float y = EYEDIR.y;
	vec3 c = mix(horizon_col, top_col, pow(smoothstep(-0.02, 0.7, y), 0.75));
	c = mix(c, bottom_col, smoothstep(0.0, -0.25, y));
	float sun = dot(EYEDIR, LIGHT0_DIRECTION);
	c += sun_glow * pow(max(sun, 0.0), 18.0) * 0.3;
	c = mix(c, vec3(1.0, 0.98, 0.9), smoothstep(0.9975, 0.999, sun));
	if (y > 0.0) {
		vec2 uv = EYEDIR.xz / (y + 0.15) * 0.9;
		float n = fbm(uv);
		float lit = fbm(uv + LIGHT0_DIRECTION.xz * 0.08);
		float edge = 1.0 - cloud_cover;
		float m = smoothstep(edge, edge + 0.035, n);
		vec3 cc = mix(cloud_shade, cloud_col, smoothstep(-0.02, 0.04, n - lit + 0.02));
		float fade = smoothstep(0.0, 0.1, y);
		c = mix(c, cc, m * fade);
	}
	COLOR = c;
}
