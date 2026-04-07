//!HOOK RGB
//!BIND HOOKED
//!DESC Depth Reality Boost — Ulysses RS Caballes' Pristine Detail Ultra Edition v4.0 ELITE
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

// === TUNING ===
const float base_strength     = 1.10;
const float radius            = 0.75;
const float warmth            = 0.25;
const float glow_intensity    = 0.08;
const float chroma_offset     = 0.30;
const float vignette_strength = 0.22;
const float sharpen_mix       = 0.40;

// === FILMIC TONE ===
vec3 filmic_hdr_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.004);
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
            float w = exp(-dot(offset, offset) * 18.0);
            blur += HOOKED_tex(uv + offset).rgb * w;
            blur_total += w;
        }
    }

    blur /= max(blur_total, 1e-6);

    // === EDGE-AWARE SHARPEN (FINAL PIECE) ===
    float l_center = dot(center, lumaCoeffs());
    float l_blur   = dot(blur, lumaCoeffs());

    float edge = abs(l_center - l_blur);

    float edge_mask = smoothstep(0.02, 0.12, edge);
    float dark_mask = smoothstep(0.08, 0.25, l_center);

    float micro_strength = edge_mask * dark_mask;

    vec3 sharpen = center * (1.0 + micro_strength * base_strength) - blur * 0.45;

    // === HIGH-QUALITY GAUSSIAN BLOOM ===
    vec3 bloom = vec3(0.0);
    float bloom_total = 0.0;

    float weights[7] = float[](0.196482, 0.176032, 0.120981, 0.064759, 0.027995, 0.0093, 0.0024);

    for (int i = -6; i <= 6; i++) {
        vec2 offset = texel * float(i) * 1.2;

        vec3 sampleH = HOOKED_tex(uv + vec2(offset.x, 0.0)).rgb;
        vec3 sampleV = HOOKED_tex(uv + vec2(0.0, offset.x)).rgb;

        float lH = dot(sampleH, lumaCoeffs());
        float lV = dot(sampleV, lumaCoeffs());

        float hH = smoothstep(0.65, 1.0, lH);
        float hV = smoothstep(0.65, 1.0, lV);

        float w = weights[abs(i)];

        bloom += sampleH * w * hH;
        bloom += sampleV * w * hV;

        bloom_total += w * hH;
        bloom_total += w * hV;
    }

    bloom /= max(bloom_total, 1e-6);

    vec3 glow = mix(sharpen, bloom, glow_intensity);

    // === COLOR GRADING ===
    vec3 graded = glow;

    graded.r += warmth * 0.05;
    graded.b -= warmth * 0.05;

    graded = mix(graded, vec3(graded.r * 1.08, graded.g * 0.99, graded.b * 0.95), 0.30);
    graded *= vec3(1.02);

    // === DEPTH ===
    float luma = dot(center, lumaCoeffs());
    float depth_boost = smoothstep(0.20, 0.80, luma);

    graded *= mix(1.0, 1.06, depth_boost);
    graded *= mix(1.0, 0.94, smoothstep(0.0, 0.5, luma));

    // === CHROMATIC ABERRATION (DISABLED) ===
    vec2 ca = texel * chroma_offset;
    vec3 ca_mix = vec3(
        HOOKED_tex(uv + ca).r,
        center.g,
        HOOKED_tex(uv - ca).b
    );

    float ca_strength = 0.0;
    graded = mix(graded, ca_mix, ca_strength);

    // === TONE MAP ===
    graded = filmic_hdr_tonecurve(graded);
    graded = pow(max(graded, 0.0), vec3(0.985));

    // === CLEAN SPARKLE (MERGED) ===
    float highlight = smoothstep(0.92, 1.0, luma);
    float midboost  = smoothstep(0.25, 0.75, luma);

    vec3 sparkle = graded 
        + highlight * vec3(0.06, 0.06, 0.065)
        + midboost  * vec3(0.025, 0.025, 0.03);

    graded = mix(graded, sparkle, 0.6);

    // === VIGNETTE ===
    vec2 d = uv - 0.5;
    float vignette = smoothstep(0.70, 0.95, length(d));
    graded *= mix(1.0, 1.0 - vignette_strength, vignette);

    // === SOFT DIFFUSION ===
    graded = mix(graded, blur, 0.04);

    // === FINAL SHARPEN MIX ===
    float detail_mask = edge_mask * dark_mask;
    vec3 final_output = mix(graded, sharpen, sharpen_mix * detail_mask);

    return vec4(clamp(final_output, 0.0, 1.0), 1.0);
}
