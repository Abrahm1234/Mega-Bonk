shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D glow_mask  : hint_default_black,  repeat_disable, filter_nearest;
uniform sampler2D noise_tex  : hint_default_black;

uniform vec4  aura_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float intensity = 2.5;

uniform float noise_scale = 6.0;
uniform vec2  noise_speed = vec2(0.05, 0.12);

uniform float fresnel_power = 4.0;

uniform float refract_strength = 0.006;       // normal-based distortion
uniform float refract_noise_strength = 0.003; // noise-based jitter

uniform float alpha_base = 0.05;
uniform float alpha_edge = 0.25;

void fragment() {
    float mask = texture(glow_mask, UV).r;

    // IMPORTANT: no "return" in Godot 4 spatial fragment. Use a branch instead.
    if (mask <= 0.001) {
        ALPHA = 0.0;
        ALBEDO = vec3(0.0);
        EMISSION = vec3(0.0);
    } else {
        // Fresnel (edge shimmer)
        float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
        float fres = pow(1.0 - ndv, fresnel_power);

        // Animated noise
        vec2 nuv = UV * noise_scale + TIME * noise_speed;
        float n = texture(noise_tex, nuv).r;

        // View-space normal for refraction direction
        vec3 n_view = normalize(mat3(VIEW_MATRIX) * normalize(NORMAL));
        vec2 n_off = n_view.xy;

        float jitter = (n - 0.5) * 2.0; // -1..1
        vec2 offset = n_off * refract_strength
                    + vec2(jitter, -jitter) * refract_noise_strength;

        // Refracted screen sample (translucent "crystal")
        vec3 refr = texture(screen_tex, SCREEN_UV + offset).rgb;

        // Iridescent hue shift
        float phase = TIME * 1.2 + fres * 3.0 + n * 2.0;
        vec3 iri = 0.5 + 0.5 * sin(vec3(0.0, 2.1, 4.2) + phase);

        float strength = mask * (0.35 + 0.65 * n) * (0.25 + 0.75 * fres);

        ALBEDO = refr;
        EMISSION = (aura_color.rgb * 0.5 + iri * 0.5) * intensity * strength;
        ALPHA = mask * (alpha_base + alpha_edge * fres);
    }
}
