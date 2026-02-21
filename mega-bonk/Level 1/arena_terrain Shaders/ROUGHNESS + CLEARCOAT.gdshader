shader_type spatial;
/*
Next Pass overlay for “crystalline camo”:
- Lit (NOT unshaded) so it can reflect lights/probes.
- Mask gates where the effect appears.
- Noise drives micro “facet” roughness/clearcoat variation.
- Optional screen refraction adds a subtle glassy shimmer.
*/
render_mode blend_mix, depth_draw_never, cull_back;
// For a stronger effect, try this instead:
// render_mode blend_add, depth_draw_never, cull_back;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D glow_mask  : hint_default_black,  repeat_disable, filter_nearest;
uniform sampler2D noise_tex  : hint_default_black; // set Repeat enabled in import if you want tiling

uniform vec4  aura_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);

// Crystal “facet” controls
uniform float noise_scale = 10.0;
uniform vec2  noise_speed = vec2(0.05, 0.12);
uniform float facet_power = 3.0;          // higher = fewer, sharper “facets”

// Reflective layer controls
uniform float roughness_min = 0.02;       // sharp highlights
uniform float roughness_max = 0.25;       // blurrier areas
uniform float clearcoat = 1.0;
uniform float clearcoat_roughness = 0.08;
uniform float specular = 1.0;

// Shimmer + visibility
uniform float fresnel_power = 4.0;
uniform float emission_intensity = 2.0;
uniform float alpha_base = 0.04;
uniform float alpha_edge = 0.20;

// Optional refraction (subtle)
uniform float refract_strength = 0.006;
uniform float refract_noise_strength = 0.003;
uniform float refract_albedo_mix = 0.35; // 0 = no refracted color, 1 = full refracted color

void fragment() {
    float mask = texture(glow_mask, UV).r;
    if (mask <= 0.001) {
        discard;
    }

    // Fresnel (view-dependent)
    float ndv  = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float fres = pow(1.0 - ndv, fresnel_power);

    // Animated noise -> “facets”
    vec2 nuv = UV * noise_scale + TIME * noise_speed;
    float n = texture(noise_tex, nuv).r;
    float facet = pow(clamp(n, 0.0, 1.0), facet_power); // 0..1

    // Lit reflective properties (this is what makes it look “crystalline”)
    ROUGHNESS = mix(roughness_max, roughness_min, facet);
    SPECULAR = specular;
    METALLIC = 0.0;

    CLEARCOAT = clearcoat * (0.4 + 0.6 * facet);
    CLEARCOAT_ROUGHNESS = clamp(clearcoat_roughness * (1.0 - 0.35 * facet), 0.0, 1.0);

    // Optional screen refraction (only noticeable if something detailed is behind the gun)
    vec3 n_view = normalize(mat3(VIEW_MATRIX) * normalize(NORMAL));
    vec2 n_off = n_view.xy;

    float jitter = (n - 0.5) * 2.0; // -1..1
    vec2 offset = n_off * refract_strength + vec2(jitter, -jitter) * refract_noise_strength;

    vec3 refr = texture(screen_tex, SCREEN_UV + offset).rgb;

    // Keep albedo contribution subtle so you don’t “paint over” the base weapon
    ALBEDO = mix(vec3(0.0), refr, refract_albedo_mix);

    // Iridescent emission shimmer (helps sell the “crystal flakes”)
    float phase = TIME * 1.2 + fres * 3.0 + n * 2.0;
    vec3 iri = 0.5 + 0.5 * sin(vec3(0.0, 2.1, 4.2) + phase);

    float strength = mask * (0.25 + 0.75 * fres) * (0.25 + 0.75 * facet);
    EMISSION = (aura_color.rgb * 0.5 + iri * 0.5) * emission_intensity * strength;

    // Overlay visibility (edges show more)
    ALPHA = mask * (alpha_base + alpha_edge * fres);
}
