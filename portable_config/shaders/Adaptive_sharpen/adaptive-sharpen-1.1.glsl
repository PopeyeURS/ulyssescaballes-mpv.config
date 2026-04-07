// Adaptive Sharpen 1.1 - Paramount Vision Edition
// Refined for cinematic quality and robust HDR stability 
// 20260408 - Created by Ulysses RS Caballes for MPV
// Copyright (C) 2026 Ulysses RS Caballes

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC adaptive-sharpen-1.1.glsl — edge-accurate HDR-safe version

// Settings
#define curve_height    1.20
#define overshoot_ctrl  true

#define curveslope      0.50
#define L_compr_low     0.10
#define L_compr_high    0.30
#define D_compr_low     0.18
#define D_compr_high    0.45
#define scale_lim       0.08
#define scale_cs        0.08
#define pm_p            1.0

#define strength        1.06
#define micro_detail    0.27
#define edge_softness   0.60
#define halo_limit      0.72

//--------------------------------------------------------------------------

#define max4(a,b,c,d)   ( max(max(a, b), max(c, d)) )
#define sat(x)          ( clamp(x, 0.0, 1.0) )
#define get(x,y)        ( HOOKED_texOff(vec2(x, y)).rgb )

#ifdef LUMA_tex
#define CtL(RGB)        RGB.x
#else
#define CtL(RGB)        ( dot(RGB, vec3(0.2627, 0.6780, 0.0593)) )
#endif

// EDGE DETECTION (smoothed for stability)
float edge_metric(vec3 c[9]) {
    float gx = CtL(c[5]) - CtL(c[4]);
    float gy = CtL(c[7]) - CtL(c[2]);
    float edge = sqrt(gx*gx + gy*gy) + 0.5 * abs(gx * gy);

    // Spatial smoothing
    float diag = (CtL(c[1]) + CtL(c[3]) + CtL(c[6]) + CtL(c[8])) * 0.25 - CtL(c[0]);
    edge = mix(edge, abs(diag), 0.25);

    return edge;
}

// MAIN
vec4 hook() {
    vec3 c[9] = vec3[](
        get( 0, 0), get(-1,-1), get( 0,-1), get( 1,-1),
        get(-1, 0),             get( 1, 0),
        get(-1, 1), get( 0, 1), get( 1, 1)
    );

    float luma[9] = float[](
        CtL(c[0]), CtL(c[1]), CtL(c[2]), CtL(c[3]),
        CtL(c[4]), CtL(c[5]), CtL(c[6]), CtL(c[7]), CtL(c[8])
    );

    float c0_Y = luma[0];

    float edge = edge_metric(c);

    float lap = (luma[2] + luma[4] + luma[5] + luma[7]) * 0.25 - c0_Y;
    float sharpdiff = -lap * (curve_height / (curveslope * edge + 0.65));

    float hf = c0_Y - (luma[2] + luma[4] + luma[5] + luma[7]) * 0.25;
    sharpdiff += hf * micro_detail;

    float diag = (luma[1] + luma[3] + luma[6] + luma[8]) * 0.25 - c0_Y;
    sharpdiff += diag * 0.15;

    // Local min/max
    float minL = luma[0], maxL = luma[0];
    for (int i = 1; i < 9; i++) {
        minL = min(minL, luma[i]);
        maxL = max(maxL, luma[i]);
    }
    float range = maxL - minL;

    // Midtone boost (slightly reduced for stability)
    float midtone = smoothstep(0.15, 0.75, c0_Y);
    sharpdiff *= mix(0.97, 1.10, midtone);

    // Clamp sharpness (prevents pulsing)
    float limit = max(range * (halo_limit + 0.15 * edge), 0.02);
    sharpdiff = clamp(sharpdiff, -limit, limit);

    // Final application (HDR SAFE)
    vec3 res = c[0] + vec3(sharpdiff * strength);

    // Micro contrast polish
    res = mix(res, res * 1.03, 0.15);

    // Vivid color enhancement (HDR-safe)
    float sat_factor = 1.08;
    float sat_boost = 1.05 + 0.10 * range;
    vec3 gray = vec3(dot(res, vec3(0.2627, 0.6780, 0.0593)));
    float lum = clamp(gray.r, 0.0, 1.0);
    res = mix(gray, res, sat_factor * (1.0 - lum*0.25));

    // Perceptual midtone contrast
    float mid = smoothstep(0.15, 0.85, c0_Y);
    res = mix(res, pow(res, vec3(0.95 + mid * 0.1)), 0.08);

    // Ultra-subtle micro-sharpen nudge
    vec3 lap2 = c[0] - 0.25*(c[2]+c[4]+c[5]+c[7]);
    res += lap2 * 0.007;

    // Clamp and output
    return vec4(clamp(res, 0.0, 1.0), HOOKED_texOff(0).a);
}