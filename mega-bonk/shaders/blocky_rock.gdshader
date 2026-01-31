shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

varying vec3 v_world_pos;
varying vec3 v_world_nrm;

uniform sampler2D noise_top : repeat_enable, filter_linear;
uniform sampler2D noise_wall : repeat_enable, filter_linear;
uniform sampler2D noise_ramp : repeat_enable, filter_linear;

uniform float disp_strength_top = 0.35;
uniform float disp_strength_wall = 0.2;
uniform float disp_strength_ramp = 0.25;

uniform float disp_scale_top = 0.06;
uniform float disp_scale_wall = 0.08;
uniform float disp_scale_ramp = 0.06;

uniform sampler2D albedo_top : repeat_enable, filter_linear;
uniform sampler2D albedo_wall : repeat_enable, filter_linear;
uniform sampler2D albedo_ramp : repeat_enable, filter_linear;

uniform sampler2D normal_top : repeat_enable, filter_linear;
uniform sampler2D normal_wall : repeat_enable, filter_linear;
uniform sampler2D normal_ramp : repeat_enable, filter_linear;

uniform float tex_scale = 0.1;
uniform float tex_strength = 1.0;
uniform float seam_lock_width = 0.1;
uniform float seam_lock_soft = 0.03;

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
	float kind = COLOR.a;

	float is_box = step(0.12, kind) * (1.0 - step(0.45, kind));
	float is_ramp = step(0.45, kind) * (1.0 - step(0.75, kind));
	float is_wall = step(0.75, kind);
	float is_top = 1.0 - is_box - is_ramp - is_wall;

	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	float nt = triplanar_sample(noise_top, v_world_pos, v_world_nrm, disp_scale_top).r;
	float nw = triplanar_sample(noise_wall, v_world_pos, v_world_nrm, disp_scale_wall).r;
	float nr = triplanar_sample(noise_ramp, v_world_pos, v_world_nrm, disp_scale_ramp).r;

	float n = nt * is_top + nr * is_ramp + nw * is_wall;
	float strength = disp_strength_top * is_top
		+ disp_strength_ramp * is_ramp
		+ disp_strength_wall * is_wall;

	float edge_dist = min(
		min(UV2.x, 1.0 - UV2.x),
		min(UV2.y, 1.0 - UV2.y)
	);
	float seam_mask = smoothstep(seam_lock_width, seam_lock_width + seam_lock_soft, edge_dist);
	float disp = (n * 2.0 - 1.0) * strength * (1.0 - is_box) * seam_mask;
	VERTEX.y += disp;
}

void fragment() {
	float kind = COLOR.a;
	float is_box = step(0.12, kind) * (1.0 - step(0.45, kind));
	float is_ramp = step(0.45, kind) * (1.0 - step(0.75, kind));
	float is_wall = step(0.75, kind);
	float is_top = 1.0 - is_box - is_ramp - is_wall;

	vec3 p = v_world_pos;
	vec3 nrm = normalize(v_world_nrm);

	vec3 base = COLOR.rgb;

	vec3 at = triplanar_sample(albedo_top, p, nrm, tex_scale).rgb;
	vec3 aw = triplanar_sample(albedo_wall, p, nrm, tex_scale).rgb;
	vec3 ar = triplanar_sample(albedo_ramp, p, nrm, tex_scale).rgb;

	vec3 albedo = at * is_top + ar * is_ramp + aw * is_wall;
	vec3 mixed = base * mix(vec3(1.0), albedo, tex_strength);

	ALBEDO = mix(base, mixed, 1.0 - is_box);

	vec3 nt = triplanar_sample(normal_top, p, nrm, tex_scale).xyz * 2.0 - 1.0;
	vec3 nw = triplanar_sample(normal_wall, p, nrm, tex_scale).xyz * 2.0 - 1.0;
	vec3 nr = triplanar_sample(normal_ramp, p, nrm, tex_scale).xyz * 2.0 - 1.0;

	vec3 tn = nt * is_top + nr * is_ramp + nw * is_wall;
	NORMAL_MAP = normalize(tn);
	NORMAL_MAP_DEPTH = 1.0;
}
