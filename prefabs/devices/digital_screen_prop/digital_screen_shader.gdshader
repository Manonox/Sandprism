shader_type spatial;
render_mode depth_draw_never, world_vertex_coords, unshaded;

uniform ivec2 resolution;
uniform sampler2D content_texture : source_color, repeat_disable, filter_nearest;
uniform bool transparent;
uniform bool pixelation_enabled;


float sat(float x) {
    return clamp(x, 0., 1.);
}

vec3 sat_v(vec3 v) {
    return vec3(sat(v.x), sat(v.y), sat(v.z));
}

vec3 pow3(vec3 v, float p) {
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
}


void vertex() {
	vec3 dir = normalize(CAMERA_POSITION_WORLD - VERTEX);
	VERTEX = VERTEX + dir * 0.03;
}

void fragment() {
	vec2 res = vec2(resolution);
	vec2 uv = floor(UV * res) / res;
	
	float fidelity = min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y);
	float max_distance = mix(clamp((fidelity - 256.0) / 4096.0, 0.0, 1.0), 2.0, 4.0);
	
	float normal_mul = pow(clamp(1.0 - NORMAL.z, 0.0, 0.8), 0.5);
	max_distance *= 1.0 - normal_mul * 0.1;
	float strength = 1.0 - clamp((length(VERTEX) - 0.25) / max_distance, 0.0, 1.0);
	
	if (!pixelation_enabled) {
		strength = 0.0;
		uv = UV;
	}
	
	strength = pow(strength, 0.5);
	
    //vec2 r = vec2(res.x / res.y, 1.0);
	
	float po = 4.0;
    float x =  cos(UV.x * PI * res.x * 2.0 - 1.0);
    float y =  sin(UV.x * PI * res.x * 2.0 - 1.5);
    float z = -cos(UV.x * PI * res.x * 2.0 - 2.0);
    vec3 grid = pow3(sat_v(pow3(vec3(x, y, z), po)), 0.5);
    float g = pow(abs(sin(UV.y * PI * res.y)), 0.3) * 1.5;
    grid *= g;
	
	vec4 color4 = texture(content_texture, uv);
	vec3 color = color4.rgb;
	
	grid = vec3(1.0) - (vec3(1.0) - grid) * strength;
	
	color *= grid;
	
	if (transparent) {
		ALPHA = color4.a;
	} else {
		color *= color4.a;
	}
	
	//color = clamp(color, 0.0, 1.0);
	
	//ALBEDO = vec3(0.05);
	//EMISSION = color;
	//DEPTH = FRAGCOORD.z;
	
	ALBEDO = color;
	//ALBEDO = texture(content_texture, UV).rgb;
}

