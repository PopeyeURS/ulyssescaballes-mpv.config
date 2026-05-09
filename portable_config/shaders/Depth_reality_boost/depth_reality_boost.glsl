//!DESC Depth Reality Boost — Created for MPV by Ulysses RS Caballes
// 20260509 232238LT - The ULTIMATE - Platinum Reference Standard - Version 6.0 ELITE

//!HOOK RGB
//!BIND HOOKED
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

// === PARAMETERS ===
#define overshoot_ctrl   true
#define L_compr_low      0.11
#define L_compr_high     0.30
#define D_compr_low      0.18
#define D_compr_high     0.46
#define scale_lim        0.07
#define scale_cs         0.08
#define pm_p             1.0
#define edge_softness    0.48

const float base_strength     = 1.26;
const float radius            = 0.66;
const float warmth            = 0.32;
const float glow_intensity    = 0.09;
const float vignette_strength = 0.16;
const float sharpen_mix       = 0.52;

#define sat(x) clamp(x,0.0,1.0)
vec3 lumaCoeffs() { return vec3(0.2627,0.6780,0.0593); }

vec3 filmic_hdr_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.0035);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec4 hook() {
    vec4 hooked_sample = HOOKED_tex(HOOKED_pos);
    vec3 center = hooked_sample.rgb;
    vec2 texel  = HOOKED_pt;
    vec2 uv     = HOOKED_pos;

    // === BLUR BASE ===
    vec3 blur = vec3(0.0);
    float blur_total = 0.0;
    for (int x=-1;x<=1;x++) {
        for (int y=-1;y<=1;y++) {
            vec2 offset = vec2(x,y)*texel*radius;
            float w = exp(-dot(offset,offset)*22.0);
            blur += HOOKED_tex(uv+offset).rgb*w;
            blur_total += w;
        }
    }
    blur /= max(blur_total,1e-6);

    // === EDGE METRIC ===
    float l_center = dot(center,lumaCoeffs());
    float l_blur   = dot(blur,lumaCoeffs());
    float edge     = abs(l_center-l_blur);

    float edge_mask = smoothstep(0.018,0.11,edge);
    float dark_mask = smoothstep(0.07,0.23,l_center);

    edge_mask = pow(edge_mask,pm_p);
    edge_mask = mix(edge_mask,1.0,edge_softness);

    float micro_strength = edge_mask*dark_mask;

    // === SHARPEN CORE ===
    vec3 sharpen = center*(1.0+micro_strength*base_strength) - blur*0.32;

    if (overshoot_ctrl) {
        float limit = 0.15;
        sharpen = clamp(sharpen,center-limit,center+limit);
    }

    // Compression
    float l_compr = smoothstep(L_compr_low,L_compr_high,l_center);
    float d_compr = smoothstep(D_compr_low,D_compr_high,1.0-l_center);
    sharpen *= mix(1.0,0.93,l_compr);
    sharpen *= mix(1.0,0.95,d_compr);

    // Contrast scale limit
    float contrast_scale = clamp(edge/scale_cs,0.0,1.0);
    sharpen *= mix(1.0,1.0-scale_lim,contrast_scale);

    // === MICRO-CONTRAST POLISH ===
    sharpen = mix(sharpen,sharpen*1.085,0.24);

    // === BLOOM/SPARKLE ===
    vec3 bloom = vec3(0.0);
    float bloom_total = 0.0;
    float weights[5] = float[](0.24,0.18,0.10,0.04,0.01);
    for (int i=-4;i<=4;i++) {
        vec2 offset = texel*float(i)*1.1;
        vec3 sample = HOOKED_tex(uv+offset).rgb;
        float l = dot(sample,lumaCoeffs());
        float h = smoothstep(0.68,1.0,l);
        float w = weights[abs(i)];
        bloom += sample*w*h;
        bloom_total += w*h;
    }
    bloom /= max(bloom_total,1e-6);

    vec3 glow = mix(sharpen,bloom,glow_intensity);

    // === COLOR GRADING ===
    vec3 graded = glow;
    graded.r += warmth*0.05;
    graded.b -= warmth*0.04;
    graded = mix(graded,vec3(graded.r*1.09,graded.g*0.995,graded.b*0.95),0.32);
    graded *= vec3(1.04);

    // === DEPTH BOOST ===
    float depth_boost = smoothstep(0.18,0.82,l_center);
    graded *= mix(1.0,1.09,depth_boost);

    // === TONE MAP ===
    graded = filmic_hdr_tonecurve(graded);
    graded = pow(max(graded,0.0),vec3(0.982));

    // === SPARKLE ENHANCEMENT (microscopic wet-look nudge) ===
    float highlight = smoothstep(0.85,1.0,l_center);
    float midboost  = smoothstep(0.22,0.78,l_center);
    float texture_boost = smoothstep(0.18,0.40,l_center);
    vec3 sparkle = graded
        + highlight*vec3(0.092,0.092,0.097)
        + midboost*vec3(0.04,0.04,0.045)
        + texture_boost*vec3(0.03,0.03,0.035);
    graded = mix(graded,sparkle,0.74);

    // === VIGNETTE ===
    vec2 d = uv-0.5;
    float vignette = smoothstep(0.72,0.95,length(d));
    graded *= mix(1.0,1.0-vignette_strength,vignette);

    // === SOFT DIFFUSION ===
    graded = mix(graded,blur,0.027);

    // === FINAL MIX ===
    float detail_mask = edge_mask*dark_mask;
    vec3 final_output = mix(graded,sharpen,sharpen_mix*detail_mask);

    return vec4(sat(final_output),hooked_sample.a);
}
