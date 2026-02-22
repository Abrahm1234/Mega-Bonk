shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha;

uniform sampler2D flipbook : source_color;
uniform int hframes = 5;
uniform int vframes = 5;
uniform float fps = 24.0;

uniform float fade_start = 0.75; // start fading at 75% of the animation
uniform float fade_end   = 1.00; // fully transparent at the end
uniform float soft_alpha = 0.12; // edge softness

void fragment() {
    int total = hframes * vframes;

    float frame_f = TIME * fps;
    float f0 = floor(frame_f);
    float t  = fract(frame_f);

    int i0 = int(mod(f0, float(total)));
    int i1 = (i0 + 1) % total;

    vec2 cell = vec2(1.0 / float(hframes), 1.0 / float(vframes));

    vec2 base0 = vec2(float(i0 % hframes), float(i0 / hframes)) * cell;
    vec2 base1 = vec2(float(i1 % hframes), float(i1 / hframes)) * cell;

    vec4 c0 = texture(flipbook, base0 + UV * cell);
    vec4 c1 = texture(flipbook, base1 + UV * cell);
    vec4 c  = mix(c0, c1, t);

    // soft edge alpha
    float a = smoothstep(0.0, soft_alpha, c.a);

    // normalized progress through animation (0..1)
    float prog = (float(i0) + t) / max(1.0, float(total - 1));

    // fade to transparent near the end
    float fade = 1.0 - smoothstep(fade_start, fade_end, prog);

    ALBEDO = c.rgb;
    ALPHA  = a * fade;
}
