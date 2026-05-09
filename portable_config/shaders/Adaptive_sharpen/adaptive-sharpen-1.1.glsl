//!DESC Adaptive Sharpen 1.1 — The Ultimate - Platinum Reference Standard - Version 5.0
// 20260509 162620LT — Synced with Depth Reality Boost
// Created for MPV by Ulysses RS Caballes

//!HOOK OUTPUT
//!BIND HOOKED

// === SETTINGS ===
#define curve_height    1.22
#define overshoot_ctrl  true

#define curveslope      0.48
#define L_compr_low     0.11
#define L_compr_high    0.28
#define D_compr_low     0.17
#define D_compr_high    0.44
#define scale_lim       0.085
#define scale_cs        0.085
#define pm_p            1.0

#define strength        1.08
#define micro_detail    0.30
#define edge_softness   0.58
#define halo_limit      0.70

//--------------------------------------------------------------------------

#define max4(a,b,c,d)   ( max(max(a, b), max(c, d)) )
#define sat(x)          ( clamp(x, 0.0, 1.0) )
#define get(x,y)        ( HOOKED_texOff(vec2(x, y)).rgb )

#ifdef LUMA_tex
#define CtL(RGB)        RGB.x
#else
#define CtL(RGB)        ( dot(RGB, vec3(0.2627, 0.6780, 0.0593)) )
#endif

// EDGE DETECTION (stabilized)
float edge_metric(vec3 c[9]) {
    float gx = CtL(c[5]) - CtL(c[4]);
    float gy = CtL(c[7]) - CtL(c[2]);
    float edge = sqrt(gx*gx + gy*gy) + 0.45 * abs(gx * gy);

    float diag = (CtL(c[1]) + CtL(c[3]) + CtL(c[6]) + CtL(c[8])) * 0.25 - CtL(c[0]);
    edge = mix(edge, abs(diag), 0.22);

    return edge;
}

// MAIN
vec4 hook() {
    vec3 c[9] = vec3[](
        get( 0, 0), get(-1,-1), get( 0,-1), get( 1,-1),
        get(-1, 0),             get( 1, 0),
        get(-1, 1), get( 0, 1), get( 1, 1)
    );

    float luma[9];
    for (int i = 0; i < 9; i++) luma[i] = CtL(c[i]);

    float c0_Y = luma[0];
    float edge = edge_metric(c);

    float lap = (luma[2] + luma[4] + luma[5] + luma[7]) * 0.25 - c0_Y;
    float sharpdiff = -lap * (curve_height / (curveslope * edge + 0.65));

    float hf = c0_Y - (luma[2] + luma[4] + luma[5] + luma[7]) * 0.25;
    sharpdiff += hf * micro_detail;

    float diag = (luma[1] + luma[3] + luma[6] + luma[8]) * 0.25 - c0_Y;
    sharpdiff += diag * 0.14;

    // Local min/max
    float minL = luma[0], maxL = luma[0];
    for (int i = 1; i < 9; i++) {
        minL = min(minL, luma[i]);
        maxL = max(maxL, luma[i]);
    }
    float range = maxL - minL;

    // Midtone boost (synced with depth reality boost)
    float midtone = smoothstep(0.14, 0.76, c0_Y);
    sharpdiff *= mix(0.98, 1.12, midtone);

    // Clamp sharpness
    float limit = max(range * (halo_limit + 0.14 * edge), 0.02);
    sharpdiff = clamp(sharpdiff, -limit, limit);

    // Final application
    vec3 res = c[0] + vec3(sharpdiff * strength);

    // Micro contrast polish
    res = mix(res, res * 1.035, 0.16);

    // Vivid color enhancement (HDR-safe sync)
    float sat_factor = 1.09;
    float sat_boost = 1.05 + 0.09 * range;
    vec3 gray = vec3(dot(res, vec3(0.2627, 0.6780, 0.0593)));
    float lum = clamp(gray.r, 0.0, 1.0);
    res = mix(gray, res, sat_factor * (1.0 - lum*0.26));

    // Perceptual midtone contrast
    float mid = smoothstep(0.14, 0.84, c0_Y);
    res = mix(res, pow(res, vec3(0.95 + mid * 0.1)), 0.085);

    // Ultra-subtle micro-sharpen nudge
    vec3 lap2 = c[0] - 0.25*(c[2]+c[4]+c[5]+c[7]);
    res += lap2 * 0.0075;

    return vec4(clamp(res, 0.0, 1.0), HOOKED_texOff(0).a);
}
