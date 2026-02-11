//!HOOK RGB
//!BIND HOOKED
//!DESC Depth Reality Boost — UlyssesCaballes' Pristine Detail Ultra Edition v3.3
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

// Ultra refinement tuning (constants are Vulkan-safe)
const float base_strength     = 1.15;   // balanced micro-contrast
const float radius            = 0.75;   // tight blur radius
const float warmth            = 0.25;
const float glow_intensity    = 0.14;
const float chroma_offset     = 0.30;
const float grain_strength    = 0.08;    // pure clarity
const float vignette_strength = 0.24;
const float sharpen_mix       = 0.35;   // micro-boosted sharpen blend

// Filmic tone curve
vec3 filmic_hdr_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec3 lumaCoeffs() { return vec3(0.299, 0.587, 0.114); }

vec4 hook() {
    vec2 texel  = HOOKED_pt;
    vec2 uv     = HOOKED_pos;
    vec3 center = HOOKED_tex(uv).rgb;

    // HDR-aware blur
    vec3 blur = vec3(0.0);
    float total = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texel * radius;
            float w = exp(-dot(offset, offset) * 18.0);
            blur += HOOKED_tex(uv + offset).rgb * w;
            total += w;
        }
    }
    blur /= max(total, 1e-6);

    // Micro-contrast sharpen
    float micro_contrast = length(center - blur);
    float micro_strength = mix(0.70, 1.20, smoothstep(0.03, 0.25, micro_contrast));
    vec3 sharpen = center * (1.0 + micro_strength * base_strength) - blur * 0.45;

    // Bloom
    vec3 bloom = vec3(0.0);
    float bsum = 0.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 o = vec2(i, j) * texel * 1.15;
            float w = exp(-dot(o, o) * 10.0);
            vec3 s = HOOKED_tex(uv + o).rgb;
            float l = dot(s, lumaCoeffs());
            float h = smoothstep(0.65, 1.0, l);
            bloom += s * w * h;
            bsum  += w * h;
        }
    }
    bloom = (bsum > 1e-6) ? bloom / bsum : center;

    vec3 glow = mix(sharpen, bloom, glow_intensity);

    // Cinematic grading
    vec3 graded = glow;
    graded.r += warmth * 0.05;
    graded.b -= warmth * 0.05;
    graded = mix(graded, vec3(graded.r * 1.08, graded.g * 0.99, graded.b * 0.95), 0.30);

    // Subtle midtone vibrance/contrast lift for natural skin color
graded = mix(graded, graded * vec3(1.02, 1.02, 1.02), 0.20);

    // Subtle vibrance lift for healthier skin tones
graded *= vec3(1.02, 1.02, 1.02);

    // Depth cues
    float luma = dot(center, lumaCoeffs());
    float depth_boost = smoothstep(0.20, 0.80, luma);
    graded *= mix(1.0, 1.07, depth_boost);
    graded *= mix(1.0, 0.92, smoothstep(0.0, 0.5, luma));

    // Chromatic aberration
    vec2 ca = texel * chroma_offset;
    vec3 ca_mix = vec3(
        HOOKED_tex(uv + ca).r,
        center.g,
        HOOKED_tex(uv - ca).b
    );
    graded = mix(graded, ca_mix, 0.030);

    // Tone mapping with subtle gamma boost
    graded = filmic_hdr_tonecurve(graded);
    graded = pow(max(graded, 0.0), vec3(0.985));

    // Specular sparkle enhancer — maximum vivid sparkle
    float sparkle_mask = smoothstep(0.92, 1.0, luma); // very tight threshold,  only brightest highlights
    vec3 sparkle = graded + sparkle_mask * vec3(0.06, 0.06, 0.065); // stronger  crystalline boost
    graded = mix(graded, sparkle, sparkle_mask);

    float depth_mask = smoothstep(0.25, 0.75, luma);
    vec3 sparkle = graded + depth_mask * vec3(0.025, 0.025, 0.03);
    graded = mix(graded, sparkle, depth_mask * 0.5);

    // Vignett
    vec2 d = uv - 0.5;
    float vignette = smoothstep(0.70, 0.95, length(d));
    graded *= mix(1.0, 1.0 - vignette_strength, vignette);

    // Soft diffusion
    graded = mix(graded, blur, 0.045);

    // Final sharpen mix
    float detail_mask = smoothstep(0.28, 0.72, luma);
    vec3 final_output = mix(graded, sharpen, sharpen_mix * detail_mask);
    final_output = clamp(final_output, 0.0, 1.0);

    return vec4(final_output, 1.0);
}
