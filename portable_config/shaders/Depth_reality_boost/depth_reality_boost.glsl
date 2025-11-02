//!HOOK RGB
//!BIND HOOKED
//!DESC Depth Reality Boost (Microscopic HDR Realism)
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

const float base_strength = 0.85;
const float radius = 0.95;
const float warmth = 0.12;
const float glow_intensity = 0.12;
const float chroma_offset = 0.6;
const float grain_strength = 0.012;

vec3 filmic_hdr_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec4 hook() {
    vec2 texel = HOOKED_pt;
    vec3 center = HOOKED_tex(HOOKED_pos).rgb;

    // HDR-aware blur
    vec3 blur = vec3(0.0);
    float total = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texel * radius;
            float weight = exp(-dot(offset, offset) * 18.0);
            blur += HOOKED_tex(HOOKED_pos + offset).rgb * weight;
            total += weight;
        }
    }
    blur /= total;

    // Micro-contrast sharpening
    float micro_contrast = length(center - blur);
    float micro_strength = mix(0.7, 1.2, smoothstep(0.03, 0.25, micro_contrast));
    vec3 sharpen = center * (1.0 + micro_strength) - blur * 0.45;

    // HDR bloom (refined)
    vec3 bloom = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(i, j) * texel * 1.2; // tighter radius
            bloom += HOOKED_tex(HOOKED_pos + offset).rgb;
        }
    }
    bloom /= 25.0;
    vec3 glow = bloom * glow_intensity + sharpen * (1.0 - glow_intensity);

    // Cinematic grading
    vec3 graded = glow;
    graded.r += warmth * 0.05;
    graded.b -= warmth * 0.05;
    graded = mix(graded, vec3(graded.r * 1.08, graded.g * 0.97, graded.b * 0.94), 0.35);

    // Depth cue via luma falloff
    float luma = dot(center, vec3(0.299, 0.587, 0.114));
    float depth_boost = smoothstep(0.2, 0.8, luma);
    graded *= mix(1.0, 1.05, depth_boost);
    graded *= mix(1.0, 0.9, smoothstep(0.0, 0.5, luma));

    // Chromatic aberration
    vec2 ca_offset = texel * chroma_offset;
    vec3 ca = vec3(
        HOOKED_tex(HOOKED_pos + ca_offset).r,
        center.g,
        HOOKED_tex(HOOKED_pos - ca_offset).b
    );
    graded = mix(graded, ca, 0.035);

    // HDR tone mapping
    graded = filmic_hdr_tonecurve(graded);
    graded = pow(graded, vec3(1.08));

    // Vignette
    vec2 uv = HOOKED_pos - 0.5;
    float vignette = smoothstep(0.7, 0.95, length(uv));
    graded *= mix(1.0, 0.72, vignette);

    // Soft diffusion
    graded = mix(graded, blur, 0.04);

    // Temporal grain with spatial variation
    float grain = fract(sin(dot(HOOKED_pos.xy + vec2(frame * 0.5), vec2(15.123, 45.321))) * 12345.6789);
    graded += (grain - 0.5) * grain_strength * 0.8;

    // Color fidelity boost
    graded = mix(graded, graded * vec3(1.02, 1.01, 1.015), 0.05);

    // Final mix
    vec3 final_output = mix(graded, sharpen, 0.12);

    return vec4(final_output, 1.0);
}
