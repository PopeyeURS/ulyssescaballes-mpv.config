// Adaptive Sharpen 1.0 — Ultimate Edition
// Copyright (c) 2015-2021, bacondither
// Enhanced and polished for mpv by Ulysses
//!HOOK OUTPUT
//!BIND HOOKED
//!DESC adaptive-sharpen-1.0.glsl — best tuned version

//--------------------------------------- Settings ------------------------------------------------
#define curve_height    1.07   // main sharpening strength (sweet spot: 0.9–1.2)
#define overshoot_ctrl  true   // allow stronger sharpening on consistent edges

// Optimal constants (do not change unless re-engineering)
#define curveslope      0.5
#define L_compr_low     0.13
#define L_compr_high    0.334
#define D_compr_low     0.21
#define D_compr_high    0.500
#define scale_lim       0.075
#define scale_cs        0.08
#define pm_p            1.0
//-------------------------------------------------------------------------------------------------

#define max4(a,b,c,d)   ( max(max(a, b), max(c, d)) )
#define sat(x)          ( clamp(x, 0.0, 1.0) )
#define dxdy(val)       ( length(fwidth(val)) )

// Soft if, fast linear approx
#define soft_if(a,b,c)  ( sat((a + b + c + 0.056/2.5)/(maxedge + 0.03/2.5) - 0.85) )

// Soft limit, modified tanh approx
#define soft_lim(v,s)   ( sat(abs(v/s)*(27.0 + pow(v/s, 2.0))/(27.0 + 9.0*pow(v/s, 2.0)))*s )

// Weighted power mean
#define wpmean(a,b,w)   ( pow(w*pow(abs(a), pm_p) + abs(1.0-w)*pow(abs(b), pm_p), (1.0/pm_p)) )

// Get destination pixel values
#define get(x,y)        ( HOOKED_texOff(vec2(x, y)).rgb )

#ifdef LUMA_tex
#define CtL(RGB)        RGB.x
#else
#define CtL(RGB)        ( sqrt(dot(sat(RGB)*sat(RGB), vec3(0.2126, 0.7152, 0.0722))) )
#endif

#define b_diff(pix)     ( (blur-luma[pix])*(blur-luma[pix]) )

vec4 hook() {
    // Sample 25 neighboring pixels
    vec3 c[25] = vec3[](get( 0, 0), get(-1,-1), get( 0,-1), get( 1,-1), get(-1, 0),
                        get( 1, 0), get(-1, 1), get( 0, 1), get( 1, 1), get( 0,-2),
                        get(-2, 0), get( 2, 0), get( 0, 2), get( 0, 3), get( 1, 2),
                        get(-1, 2), get( 3, 0), get( 2, 1), get( 2,-1), get(-3, 0),
                        get(-2, 1), get(-2,-1), get( 0,-3), get( 1,-2), get(-1,-2));

    float e[13] = float[](dxdy(c[0]), dxdy(c[1]), dxdy(c[2]), dxdy(c[3]), dxdy(c[4]),
                          dxdy(c[5]), dxdy(c[6]), dxdy(c[7]), dxdy(c[8]), dxdy(c[9]),
                          dxdy(c[10]), dxdy(c[11]), dxdy(c[12]));

    // RGB to luma
    float luma[25] = float[](CtL(c[0]), CtL(c[1]), CtL(c[2]), CtL(c[3]), CtL(c[4]), CtL(c[5]), CtL(c[6]),
                             CtL(c[7]), CtL(c[8]), CtL(c[9]), CtL(c[10]), CtL(c[11]), CtL(c[12]),
                             CtL(c[13]), CtL(c[14]), CtL(c[15]), CtL(c[16]), CtL(c[17]), CtL(c[18]),
                             CtL(c[19]), CtL(c[20]), CtL(c[21]), CtL(c[22]), CtL(c[23]), CtL(c[24]));

    // Edge weights refinement
    float weights[12];
    for (int i = 0; i < 12; ++i) weights[i] = 1.0;
    weights[0] = (max(max((weights[8]  + weights[9])/4.0,  weights[0]), 0.25) + weights[0])/2.0;
    weights[2] = (max(max((weights[8]  + weights[10])/4.0, weights[2]), 0.25) + weights[2])/2.0;
    weights[5] = (max(max((weights[9]  + weights[11])/4.0, weights[5]), 0.25) + weights[5])/2.0;
    weights[7] = (max(max((weights[10] + weights[11])/4.0, weights[7]), 0.25) + weights[7])/2.0;

    // Negative Laplace kernel
    float lowthrsum   = 0.0;
    float weightsum   = 0.0;
    float neg_laplace = 0.0;

    for (int pix = 0; pix < 12; ++pix) {
        float lowthr = sat((20.*4.5*e[pix + 1] - 0.221));
        neg_laplace += luma[pix+1] * luma[pix+1] * weights[pix] * lowthr;
        weightsum   += weights[pix] * lowthr;
        lowthrsum   += lowthr / 12.0;
    }
    neg_laplace = sqrt(neg_laplace / weightsum);

    // Sharpening magnitude
    float edge = e[0];
    float sharpen_val = curve_height/(curve_height*curveslope*edge + 0.625);

    // Sharpening diff
    float c0_Y = luma[0];
    float sharpdiff = (c0_Y - neg_laplace)*(lowthrsum*sharpen_val + 0.01);

    // Local min/max sort
    float temp;
    for (int i1 = 0; i1 < 24; i1 += 2) {
        temp = luma[i1];
        luma[i1]   = min(luma[i1], luma[i1+1]);
        luma[i1+1] = max(temp, luma[i1+1]);
    }
    for (int i2 = 24; i2 > 0; i2 -= 2) {
        temp = luma[0];
        luma[0]    = min(luma[0], luma[i2]);
        luma[i2]   = max(temp, luma[i2]);
        temp = luma[24];
        luma[24]   = max(luma[24], luma[i2-1]);
        luma[i2-1] = min(temp, luma[i2-1]);
    }

    float min_dist  = min(abs(luma[24] - c0_Y), abs(c0_Y - luma[0]));
    min_dist = min(min_dist, scale_lim*(1.0 - scale_cs) + min_dist*scale_cs);

    // Anti-ringing compression
    vec2 cs = vec2(L_compr_low, D_compr_low);
    sharpdiff = wpmean(max(sharpdiff, 0.0), soft_lim(max(sharpdiff, 0.0), min_dist), cs.x)
              - wpmean(min(sharpdiff, 0.0), soft_lim(min(sharpdiff, 0.0), min_dist), cs.y);

    float sharpdiff_lim = sat(c0_Y + sharpdiff) - c0_Y;

    // Final sharpened color
    vec3 res = sharpdiff_lim + c[0];
    return vec4(res, HOOKED_texOff(0).a);
}
