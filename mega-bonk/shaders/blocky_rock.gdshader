shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D noise_top  : repeat_enable;
uniform sampler2D noise_wall : repeat_enable;
uniform sampler2D noise_ramp : repeat_enable;

uniform sampler2D albedo_top  : repeat_disable;
uniform sampler2D albedo_wall : repeat_disable;
uniform sampler2D albedo_ramp : repeat_disable;

uniform sampler2D normal_top  : repeat_disable;
uniform sampler2D normal_wall : repeat_disable;
uniform sampler2D normal_ramp : repeat_disable;
uniform float normal_strength = 0.85;

uniform float cell_size = 1.0;
uniform float disp_strength_top  = 0.40;
uniform float disp_strength_wall = 0.35;
uniform float disp_strength_ramp = 0.40;

uniform float disp_scale_top  = 0.06;
uniform float disp_scale_wall = 0.08;
uniform float disp_scale_ramp = 0.06;

uniform float seam_lock_width = 0.06;
uniform float seam_lock_soft  = 0.02;
uniform bool seam_lock_use_world_cell = false;
uniform vec2 grid_origin_xz = vec2(0.0, 0.0);
uniform bool clamp_to_cell = true;
uniform float cell_margin_m = 0.02;
uniform bool snap_y_to_height_step = false;
uniform float height_step = 1.0;
uniform float snap_y_strength = 1.0;
uniform float grid_y_min = -100000.0;
uniform float grid_y_max = 100000.0;

uniform bool debug_disable_side_disp = false;
uniform bool debug_show_vertex_color = false;

const float TAG_TOP  = 0.00;
const float TAG_WALL = 0.55;
const float TAG_RAMP = 0.80;
const float TAG_BOX  = 1.00;

varying vec3 v_world_pos;
varying float v_tag;

float seam_lock_mask(vec2 uv2) {
	float edge_dist = min(min(uv2.x, 1.0 - uv2.x), min(uv2.y, 1.0 - uv2.y));
	float w0 = seam_lock_width;
	float w1 = seam_lock_width + seam_lock_soft;
	return smoothstep(w0, w1, edge_dist);
}

float seam_lock_mask_local(vec2 local_xz) {
	vec2 in_cell = fract((local_xz - grid_origin_xz) / max(cell_size, 1e-5));
	float edge_dist = min(min(in_cell.x, 1.0 - in_cell.x), min(in_cell.y, 1.0 - in_cell.y));
	float w0 = seam_lock_width;
	float w1 = seam_lock_width + seam_lock_soft;
	return smoothstep(w0, w1, edge_dist);
}

float decode_is(float tag, float target) {
	return 1.0 - step(0.08, abs(tag - target));
}

vec2 wrap_uv(vec2 uv) {
	return fract(uv);
}

float triplanar_noise(sampler2D tex, vec3 p, vec3 n, float scale) {
	vec3 an = abs(n);
	vec3 w = an / max(an.x + an.y + an.z, 1e-5);

	vec2 uvx = wrap_uv(p.zy * scale);
	vec2 uvy = wrap_uv(p.xz * scale);
	vec2 uvz = wrap_uv(p.xy * scale);

	float nx = texture(tex, uvx).r;
	float ny = texture(tex, uvy).r;
	float nz = texture(tex, uvz).r;

	return nx * w.x + ny * w.y + nz * w.z;
}

float fbm_noise(sampler2D tex, vec3 p, vec3 n, float base_scale) {
	float sum = 0.0;
	float amp = 0.55;
	float sc  = base_scale;

	for (int i = 0; i < 5; i++) {
		sum += triplanar_noise(tex, p, n, sc) * amp;
		sc  *= 2.0;
		amp *= 0.5;
	}
	return sum;
}

void vertex() {
	v_tag = COLOR.a;

	float is_top  = decode_is(v_tag, TAG_TOP);
	float is_wall = decode_is(v_tag, TAG_WALL);
	float is_ramp = decode_is(v_tag, TAG_RAMP);
	float is_box  = decode_is(v_tag, TAG_BOX);

	if (debug_disable_side_disp) {
		is_wall = 0.0;
		is_ramp = 0.0;
	}

	float disp_strength = disp_strength_top * is_top
	                    + disp_strength_wall * is_wall
	                    + disp_strength_ramp * is_ramp;

	float disp_scale = disp_scale_top * is_top
	                 + disp_scale_wall * is_wall
	                 + disp_scale_ramp * is_ramp;

	vec3 local_p0 = VERTEX;
	vec3 world_p0 = (MODEL_MATRIX * vec4(local_p0, 1.0)).xyz;
	vec3 world_n0 = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	vec2 cell = floor((local_p0.xz - grid_origin_xz) / max(cell_size, 1e-5));
	vec2 cell_min = grid_origin_xz + cell * cell_size;
	vec2 cell_max = cell_min + vec2(cell_size);
	float rnd = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 p = world_p0 + vec3(rnd * 19.0, rnd * 7.0, rnd * 23.0);

	float n_top = fbm_noise(noise_top, p, world_n0, disp_scale);
	float n_wall = fbm_noise(noise_wall, p, world_n0, disp_scale);
	float n_ramp = fbm_noise(noise_ramp, p, world_n0, disp_scale);
	float n = n_top * is_top + n_wall * is_wall + n_ramp * is_ramp;

	float disp = (n * 2.0 - 1.0) * disp_strength;

	float seam_uv2 = seam_lock_mask(UV2);
	float seam_local = seam_lock_mask_local(local_p0.xz);
	float seam = seam_lock_use_world_cell ? seam_uv2 : seam_local;
	disp *= seam * (1.0 - is_box);

	if (is_top > 0.5 || is_ramp > 0.5) {
		disp = -abs(disp);
	}

	vec2 cell_center_xz = (cell_min + cell_max) * 0.5;
	vec2 to_center_xz = cell_center_xz - local_p0.xz;
	vec3 dir_top = vec3(0.0, -1.0, 0.0);
	vec3 dir_wall = normalize(vec3(to_center_xz.x, 0.0, to_center_xz.y) + vec3(1e-6, 0.0, 1e-6));
	vec3 dir_ramp = normalize(mix(normalize(NORMAL), dir_top, 0.65));
	vec3 local_dir = dir_top * is_top + dir_wall * is_wall + dir_ramp * is_ramp;
	local_dir = normalize(local_dir + vec3(1e-6));

	VERTEX += local_dir * disp;

	if (clamp_to_cell) {
		float m = max(cell_margin_m, 0.0);
		float min_x = cell_min.x + m;
		float max_x = cell_max.x - m;
		float min_z = cell_min.y + m;
		float max_z = cell_max.y - m;
		if (min_x > max_x) {
			float cx = (cell_min.x + cell_max.x) * 0.5;
			min_x = cx;
			max_x = cx;
		}
		if (min_z > max_z) {
			float cz = (cell_min.y + cell_max.y) * 0.5;
			min_z = cz;
			max_z = cz;
		}
		VERTEX.x = clamp(VERTEX.x, min_x, max_x);
		VERTEX.z = clamp(VERTEX.z, min_z, max_z);
	}

	VERTEX.y = min(VERTEX.y, local_p0.y);
	VERTEX.y = clamp(VERTEX.y, grid_y_min, grid_y_max);

	if (snap_y_to_height_step) {
		float hs = max(height_step, 1e-5);
		float y_snap = round((VERTEX.y - grid_y_min) / hs) * hs + grid_y_min;
		VERTEX.y = mix(VERTEX.y, y_snap, clamp(snap_y_strength, 0.0, 1.0));
		VERTEX.y = clamp(VERTEX.y, grid_y_min, grid_y_max);
		VERTEX.y = min(VERTEX.y, local_p0.y);
	}

	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (debug_show_vertex_color) {
		ALBEDO = COLOR.rgb;
		METALLIC = 0.0;
		ROUGHNESS = 1.0;
	} else {
		float is_top  = decode_is(v_tag, TAG_TOP);
		float is_wall = decode_is(v_tag, TAG_WALL);
		float is_ramp = decode_is(v_tag, TAG_RAMP);
		float is_box  = decode_is(v_tag, TAG_BOX);

		vec3 a_top  = texture(albedo_top,  UV).rgb;
		vec3 a_wall = texture(albedo_wall, UV).rgb;
		vec3 a_ramp = texture(albedo_ramp, UV).rgb;

		vec3 albedo = a_top * is_top + a_wall * is_wall + a_ramp * is_ramp;
		ALBEDO = mix(albedo, vec3(0.08), is_box);

		vec3 P = (VIEW_MATRIX * vec4(v_world_pos, 1.0)).xyz;
		vec3 dpx = dFdx(P);
		vec3 dpy = dFdy(P);
		vec3 n_view = normalize(cross(dpx, dpy));
		NORMAL = n_view;

		if (normal_strength > 0.001) {
			vec3 nt = (texture(normal_top,  UV).rgb * 2.0 - 1.0) * is_top;
			vec3 nw = (texture(normal_wall, UV).rgb * 2.0 - 1.0) * is_wall;
			vec3 nr = (texture(normal_ramp, UV).rgb * 2.0 - 1.0) * is_ramp;
			vec3 nm = normalize(nt + nw + nr);

			NORMAL = normalize(mix(NORMAL, normalize(NORMAL + nm * 0.35), normal_strength));
		}
	}
}