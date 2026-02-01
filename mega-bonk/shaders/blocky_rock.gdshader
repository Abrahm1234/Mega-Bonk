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
uniform float seam_lock_width = 0.18;
uniform float seam_lock_soft = 0.06;
uniform float cell_size = 1.0;
uniform float debug_vertex_colors = 0.0;
const float SURF_TOP = 0.0;
const float SURF_WALL = 0.55;
const float SURF_RAMP = 0.8;
const float SURF_BOX = 1.0;

vec2 wrap_uv(vec2 uv) {
	return fract(uv);
}

vec4 triplanar_sample(sampler2D tex, vec3 p, vec3 n, float scale) {
	vec3 an = abs(n);
	vec3 w = pow(an, vec3(10.0));
	w /= (w.x + w.y + w.z + 1e-6);

	vec2 uvx = wrap_uv(p.zy * scale);
	vec2 uvy = wrap_uv(p.xz * scale);
	vec2 uvz = wrap_uv(p.xy * scale);

	vec4 cx = texture(tex, uvx);
	vec4 cy = texture(tex, uvy);
	vec4 cz = texture(tex, uvz);
	return cx * w.x + cy * w.y + cz * w.z;
}

float fbm_triplanar(sampler2D tex, vec3 p, vec3 n, float base_scale) {
	float sum = 0.0;
	float amp = 0.6;
	float sc = base_scale;
	for (int i = 0; i < 3; i++) {
		sum += triplanar_sample(tex, p, n, sc).r * amp;
		sc *= 2.0;
		amp *= 0.5;
	}
	return sum;
}

float ridged(float x) {
	x = abs(x * 2.0 - 1.0);
	return 1.0 - x;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 surf_flags(float a) {
	float d_top = abs(a - SURF_TOP);
	float d_wall = abs(a - SURF_WALL);
	float d_ramp = abs(a - SURF_RAMP);
	float d_box = abs(a - SURF_BOX);
	vec4 flags = vec4(1.0, 0.0, 0.0, 0.0);
	float min_d = d_top;
	if (d_wall < min_d) {
		min_d = d_wall;
		flags = vec4(0.0, 1.0, 0.0, 0.0);
	}
	if (d_ramp < min_d) {
		min_d = d_ramp;
		flags = vec4(0.0, 0.0, 1.0, 0.0);
	}
	if (d_box < min_d) {
		flags = vec4(0.0, 0.0, 0.0, 1.0);
	}
	return flags;
}

void vertex() {
	vec4 flags = surf_flags(COLOR.a);
	float is_top = flags.x;
	float is_wall = flags.y;
	float is_ramp = flags.z;
	float is_box = flags.w;

	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	vec2 cell = floor(v_world_pos.xz / max(cell_size, 1e-3));
	float rnd = hash21(cell);
	vec3 pvar = v_world_pos + vec3(rnd * 7.31, rnd * 3.17, rnd * 5.83);

	float nt = fbm_triplanar(noise_top, pvar, v_world_nrm, disp_scale_top);
	float nw = fbm_triplanar(noise_wall, pvar, v_world_nrm, disp_scale_wall);
	float nr = fbm_triplanar(noise_ramp, pvar, v_world_nrm, disp_scale_ramp);
	nt = ridged(nt);
	nw = ridged(nw);
	nr = ridged(nr);

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
	vec3 dir_top = vec3(0.0, 1.0, 0.0);
	vec3 dir_wall = normalize(vec3(NORMAL.x, NORMAL.y * 0.15, NORMAL.z));
	vec3 dir_ramp = normalize(mix(dir_top, normalize(NORMAL), 0.65));
	vec3 dir = dir_top * is_top + dir_ramp * is_ramp + dir_wall * is_wall;
	VERTEX += dir * disp;
}

void fragment() {
	vec4 flags = surf_flags(COLOR.a);
	float is_top = flags.x;
	float is_wall = flags.y;
	float is_ramp = flags.z;
	float is_box = flags.w;

	vec3 p = v_world_pos;
	vec3 nrm = normalize(v_world_nrm);

	vec3 at = triplanar_sample(albedo_top, p, nrm, tex_scale).rgb;
	vec3 aw = triplanar_sample(albedo_wall, p, nrm, tex_scale).rgb;
	vec3 ar = triplanar_sample(albedo_ramp, p, nrm, tex_scale).rgb;

	vec3 albedo_tex = at * is_top + ar * is_ramp + aw * is_wall;
	vec3 surf_albedo = mix(vec3(1.0), albedo_tex, tex_strength);
	surf_albedo = mix(surf_albedo, COLOR.rgb, debug_vertex_colors);
	ALBEDO = mix(surf_albedo, COLOR.rgb, is_box);

	vec3 nt = triplanar_sample(normal_top, p, nrm, tex_scale).xyz * 2.0 - 1.0;
	vec3 nw = triplanar_sample(normal_wall, p, nrm, tex_scale).xyz * 2.0 - 1.0;
	vec3 nr = triplanar_sample(normal_ramp, p, nrm, tex_scale).xyz * 2.0 - 1.0;

	vec3 tn = nt * is_top + nr * is_ramp + nw * is_wall;
	NORMAL_MAP = normalize(tn);
	NORMAL_MAP_DEPTH = 1.0;
}