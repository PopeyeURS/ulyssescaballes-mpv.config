//!HOOK RGB
//!BIND HOOKED
//!DESC Depth Reality Boost — Created for MPV by Ulysses RS Caballes
20260509 162852LT - The ULTIMATE - Platinum Reference Standard - Version 5.0 ELITE
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

// === TUNING ===
const float base_strength     = 1.18;
const float radius            = 0.70;
const float warmth            = 0.28;
const float glow_intensity    = 0.07;
const float chroma_offset     = 0.25;
const float vignette_strength = 0.20;
const float sharpen_mix       = 0.45;

// === FILMIC TONE ===
vec3 filmic_hdr_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.0035);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec3 lumaCoeffs() { return vec3(0.299, 0.587, 0.114); }

vec4 hook() {
    vec2 texel  = HOOKED_pt;
    vec2 uv     = HOOKED_pos;
    vec3 center = HOOKED_tex(uv).rgb;

    // === BLUR (for sharpening base) ===
    vec3 blur = vec3(0.0);
    float blur_total = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texel * radius;
            float w = exp(-dot(offset, offset) * 20.0); // tighter falloff
            blur += HOOKED_tex(uv + offset).rgb * w;
            blur_total += w;
        }
    }
    blur /= max(blur_total, 1e-6);

    // === EDGE-AWARE SHARPEN ===
    float l_center = dot(center, lumaCoeffs());
    float l_blur   = dot(blur, lumaCoeffs());

    float edge     = abs(l_center - l_blur);

    float edge_mask = smoothstep(0.018, 0.11, edge);
    float dark_mask = smoothstep(0.07, 0.23, l_center);

    float micro_strength = edge_mask * dark_mask;

    vec3 sharpen = center * (1.0 + micro_strength * base_strength) - blur * 0.40;

    // === BLOOM / SPARKLE ===
    vec3 bloom = vec3(0.0);
    float bloom_total = 0.0;

    float weights[5] = float[](0.24, 0.18, 0.10, 0.04, 0.01);

    for (int i = -4; i <= 4; i++) {
        vec2 offset = texel * float(i) * 1.1;

        vec3 sample = HOOKED_tex(uv + offset).rgb;

        float l = dot(sample, lumaCoeffs());
        float h = smoothstep(0.70, 1.0, l);
        float w = weights[abs(i)];

        bloom += sample * w * h;
        bloom_total += w * h;
    }
    bloom /= max(bloom_total, 1e-6);

    vec3 glow = mix(sharpen, bloom, glow_intensity);

    // === COLOR GRADING ===
    vec3 graded = glow;

    graded.r += warmth * 0.05;
    graded.b -= warmth * 0.04;

    graded = mix(graded, vec3(graded.r * 1.07, graded.g * 0.995, graded.b * 0.96), 0.28);
    graded *= vec3(1.02);

    // === DEPTH BOOST ===
    float luma = dot(center, lumaCoeffs());
    float depth_boost = smoothstep(0.18, 0.82, luma);
    graded *= mix(1.0, 1.07, depth_boost);

    // === TONE MAP ===
    graded = filmic_hdr_tonecurve(graded);
    graded = pow(max(graded, 0.0), vec3(0.98));

    // === SPARKLE ENHANCEMENT ===
    float highlight = smoothstep(0.91, 1.0, luma);
    float midboost  = smoothstep(0.22, 0.78, luma);

    vec3 sparkle = graded 
        + highlight * vec3(0.065, 0.065, 0.07)
        + midboost  * vec3(0.03, 0.03, 0.035);

    graded = mix(graded, sparkle, 0.65);

    // === VIGNETTE ===
    vec2 d = uv - 0.5;
    float vignette = smoothstep(0.72, 0.95, length(d));
    graded *= mix(1.0, 1.0 - vignette_strength, vignette);

    // === SOFT DIFFUSION ===
    graded = mix(graded, blur, 0.035);

    // === FINAL SHARPEN MIX ===
    float detail_mask = edge_mask * dark_mask;
    vec3 final_output = mix(graded, sharpen, sharpen_mix * detail_mask);

    return vec4(clamp(final_output, 0.0, 1.0), 1.0);
}
