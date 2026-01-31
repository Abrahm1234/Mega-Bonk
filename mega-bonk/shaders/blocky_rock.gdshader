shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D disp_noise : repeat_enable, filter_linear;
uniform float disp_strength = 0.5;
uniform float disp_scale = 0.03;

uniform sampler2D rock_albedo : repeat_enable, filter_linear;
uniform sampler2D rock_normal : repeat_enable, filter_linear;
uniform float tex_scale = 0.08;
uniform float tex_strength = 1.0;

vec4 triplanar_sample(sampler2D tex, vec3 p, vec3 n, float scale) {
	vec3 an = abs(n);
	vec3 w = pow(an, vec3(8.0));
	w /= (w.x + w.y + w.z + 1e-6);

	vec2 uvx = p.zy * scale;
	vec2 uvy = p.xz * scale;
	vec2 uvz = p.xy * scale;

	vec4 cx = texture(tex, uvx);
	vec4 cy = texture(tex, uvy);
	vec4 cz = texture(tex, uvz);
	return cx * w.x + cy * w.y + cz * w.z;
}

void vertex() {
	vec3 p = VERTEX;
	float n = texture(disp_noise, p.xz * disp_scale).r;
	float disp = (n * 2.0 - 1.0) * disp_strength;
	VERTEX.y += disp;
}

void fragment() {
	vec3 nrm = normalize(NORMAL);
	vec3 p = VERTEX;
	vec3 base = COLOR.rgb;

	vec3 rock = triplanar_sample(rock_albedo, p, nrm, tex_scale).rgb;
	vec3 mixed = base * mix(vec3(1.0), rock, tex_strength);

	ALBEDO = mixed;

	vec3 tn = triplanar_sample(rock_normal, p, nrm, tex_scale).xyz * 2.0 - 1.0;
	NORMAL_MAP = normalize(tn);
	NORMAL_MAP_DEPTH = 1.0;
}
