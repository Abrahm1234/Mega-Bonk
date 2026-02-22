shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 debug_floor_color : source_color = vec4(0.10, 1.00, 0.10, 1.0);
uniform vec4 debug_wall_color  : source_color = vec4(0.20, 0.55, 1.00, 1.0);
uniform vec4 debug_ramp_color  : source_color = vec4(1.00, 0.20, 0.20, 1.0);
uniform vec4 debug_box_color   : source_color = vec4(0.25, 0.25, 0.25, 1.0);
uniform float debug_tag_emission = 0.0;

const float TAG_TOP  = 0.00;
const float TAG_WALL = 0.55;
const float TAG_RAMP = 0.80;
const float TAG_BOX  = 1.00;

float decode_is(float tag, float target) {
	return 1.0 - step(0.12, abs(tag - target));
}

void fragment() {
	float tag = COLOR.a;
	float is_floor = decode_is(tag, TAG_TOP);
	float is_wall = decode_is(tag, TAG_WALL);
	float is_ramp = decode_is(tag, TAG_RAMP);
	float is_box = decode_is(tag, TAG_BOX);

	vec3 c =
		debug_floor_color.rgb * is_floor +
		debug_wall_color.rgb * is_wall +
		debug_ramp_color.rgb * is_ramp;
	c = mix(c, debug_box_color.rgb, is_box);

	ALBEDO = c;
	EMISSION = c * debug_tag_emission;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}