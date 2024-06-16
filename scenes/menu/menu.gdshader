shader_type canvas_item;


uniform sampler2D noise : repeat_enable;

float sample_noise(vec2 p) {
	return texture(noise, p).r;
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 sample(vec2 p) {
	float v = sample_noise(p + vec2(0.0, 5.7) * (TIME + 100.0) * 0.01);
	float noise1 = sample_noise(p + vec2(-0.02, -0.045) * (TIME + 133.0) + vec2(v * 0.1, 0.0));
	float noise2 = sample_noise(p + vec2(-0.07, 0.033) * (TIME + 77.0) + vec2(-v * 0.1 + 0.37, 0.7));
	float noise3 = sample_noise(p + vec2(0.0, 0.01) * (TIME + 4444.0) + vec2(v * 0.2 + 0.13, v * 0.2 - 0.13));
	float n = noise1 + cos(noise2) * 2.0 + 200.0;
	n = n * 0.3 * cos(noise3 * 0.33) * 0.3;
	return hsv2rgb(vec3(n, 0.7, 0.2));
}

vec2 downsample(vec2 p, float size) {
	return floor(p / size) * size;
}


void fragment() {
	vec3 color = vec3(0.0);
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	uv.y = uv.y * aspect;
	uv = downsample(uv, 0.008);
	color = vec3(sample(uv));

	COLOR = vec4(color, 1.0);
}
