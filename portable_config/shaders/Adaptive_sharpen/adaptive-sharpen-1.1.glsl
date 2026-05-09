//!DESC Adaptive Sharpen 1.1 — The Ultimate - Platinum Reference Standard - Version 6.0
// 20260509 225403LT — Synced with Depth Reality Boost
// Created for MPV by Ulysses RS Caballes

//!HOOK OUTPUT
//!BIND HOOKED

// Settings
#define curve_height    1.30
#define overshoot_ctrl  true

#define curveslope      0.44
#define L_compr_low     0.11
#define L_compr_high    0.30
#define D_compr_low     0.18
#define D_compr_high    0.46
#define scale_lim       0.07
#define scale_cs        0.08
#define pm_p            1.0

#define sat(x)          ( clamp(x, 0.0, 1.0) )
#define dxdy(val)       ( length(fwidth(val)) )
#define soft_lim(v,s)   ( sat(abs(v/s)*(27.0 + pow(v/s, 2.0))/(27.0 + 9.0*pow(v/s, 2.0)))*s )
#define wpmean(a,b,w)   ( pow(w*pow(abs(a), pm_p) + abs(1.0-w)*pow(abs(b), pm_p), (1.0/pm_p)) )
#define get(x,y)        ( HOOKED_texOff(vec2(x, y)).rgb )

#ifdef LUMA_tex
#define CtL(RGB)        RGB.x
#else
#define CtL(RGB)        ( sqrt(dot(sat(RGB)*sat(RGB), vec3(0.2126, 0.7152, 0.0722))) )
#endif

vec4 hook() {
    vec3 c[25] = vec3[](get(0,0), get(-1,-1), get(0,-1), get(1,-1), get(-1,0),
                        get(1,0), get(-1,1), get(0,1), get(1,1), get(0,-2),
                        get(-2,0), get(2,0), get(0,2), get(0,3), get(1,2),
                        get(-1,2), get(3,0), get(2,1), get(2,-1), get(-3,0),
                        get(-2,1), get(-2,-1), get(0,-3), get(1,-2), get(-1,-2));

    float e[13]; for (int i=0;i<13;i++) e[i] = dxdy(c[i]);
    float luma[25]; for (int i=0;i<25;i++) luma[i] = CtL(c[i]);

    // Edge weights refinement
    float weights[12]; for (int i=0;i<12;i++) weights[i] = 1.0;
    weights[0] = (max(max((weights[8]+weights[9])/4.0,weights[0]),0.25)+weights[0])/2.0;
    weights[2] = (max(max((weights[8]+weights[10])/4.0,weights[2]),0.25)+weights[2])/2.0;
    weights[5] = (max(max((weights[9]+weights[11])/4.0,weights[5]),0.25)+weights[5])/2.0;
    weights[7] = (max(max((weights[10]+weights[11])/4.0,weights[7]),0.25)+weights[7])/2.0;

    // Negative Laplace kernel
    float lowthrsum=0.0, weightsum=0.0, neg_laplace=0.0;
    for (int pix=0;pix<12;++pix){
        float lowthr = sat((20.*4.5*e[pix+1]-0.221));
        neg_laplace += luma[pix+1]*luma[pix+1]*weights[pix]*lowthr;
        weightsum   += weights[pix]*lowthr;
        lowthrsum   += lowthr/12.0;
    }
    neg_laplace = sqrt(neg_laplace/weightsum);

    float edge = e[0];
    float sharpen_val = curve_height/(curve_height*curveslope*edge+0.625);

    float c0_Y = luma[0];
    float sharpdiff = (c0_Y-neg_laplace)*(lowthrsum*sharpen_val+0.01);

    // Local min/max sort
    float temp;
    for (int i1=0;i1<24;i1+=2){ temp=luma[i1]; luma[i1]=min(luma[i1],luma[i1+1]); luma[i1+1]=max(temp,luma[i1+1]); }
    for (int i2=24;i2>0;i2-=2){ temp=luma[0]; luma[0]=min(luma[0],luma[i2]); luma[i2]=max(temp,luma[i2]); temp=luma[24]; luma[24]=max(luma[24],luma[i2-1]); luma[i2-1]=min(temp,luma[i2-1]); }

    float min_dist=min(abs(luma[24]-c0_Y),abs(c0_Y-luma[0]));
    min_dist=min(min_dist,scale_lim*(1.0-scale_cs)+min_dist*scale_cs);

    // Anti-ringing compression
    sharpdiff = wpmean(max(sharpdiff,0.0),soft_lim(max(sharpdiff,0.0),min_dist),L_compr_low)
              - wpmean(min(sharpdiff,0.0),soft_lim(min(sharpdiff,0.0),min_dist),D_compr_low);

    float sharpdiff_lim = sat(c0_Y+sharpdiff)-c0_Y;

    vec3 res = sharpdiff_lim + c[0];

    // Micro-contrast polish (stronger highlights & wrinkles)
    res = mix(res,res*1.085,0.23);

    // Adaptive saturation boost (faces, sweat, tears, sparkle)
    float local_contrast = clamp(edge*14.0,0.0,1.0);
    vec3 gray = vec3(dot(res,vec3(0.2627,0.6780,0.0593)));
    float lum = clamp(gray.r,0.0,1.0);
    float midtone_boost = smoothstep(0.25,0.65,c0_Y);
    float highlight_boost = smoothstep(0.55,0.85,c0_Y);
    float texture_boost = smoothstep(0.18,0.40,c0_Y);
    res = mix(gray,res,1.20*(1.0-lum*0.18)*(0.9+0.1*local_contrast+0.08*midtone_boost+0.07*highlight_boost+0.05*texture_boost));

    // Gentle gamma compensation
    res = pow(res,vec3(0.982));

    // Warmth bias for skin tones
    res.r *= 1.02;
    res.g *= 1.01;

    return vec4(clamp(res,0.0,1.0),HOOKED_texOff(0).a);
}
