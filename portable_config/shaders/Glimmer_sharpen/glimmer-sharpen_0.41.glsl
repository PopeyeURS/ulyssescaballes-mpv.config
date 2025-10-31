//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.41 — Depth-Restored Edition
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

layout(std140, binding = 0) uniform Params {
    float strength;           // Sharpening intensity
    float glint_boost;        // Glimmer effect intensity
    float glint_threshold;    // Minimum luminance for glimmer effect
    float softness;           // Blend factor for smoothness
    float noise_intensity;    // Intensity of noise for details
    float reflection_mix;     // Mix between reflection and refraction
    float micro_detail;       // Strength of microdetails
    float depth_factor;       // Depth effect strength
    vec3 tint_color;          // Optional color tint
    float tint_strength;      // Tint blend factor
    bool enable_depth;        // Toggle depth blur
    bool debug_mode;          // Toggle debug visualization
};

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 edgeDetect(vec2 texel, vec2 uv) {
    vec3 center = HOOKED_tex(uv).rgb;
    vec3 north = HOOKED_tex(uv + vec2(0.0, -texel.y)).rgb;
    vec3 south = HOOKED_tex(uv + vec2(0.0, texel.y)).rgb;
    vec3 east  = HOOKED_tex(uv + vec2(texel.x, 0.0)).rgb;
    vec3 west  = HOOKED_tex(uv + vec2(-texel.x, 0.0)).rgb;
    vec3 edge = center * (4.0 + strength) - (north + south + east + west);
    return edge * 0.35; // subtle sharpness boost
}

vec3 applyDepthEffect(vec3 color, vec3 base, float depth) {
    float blur_factor = smoothstep(0.0, 1.0, depth * depth_factor);
    return mix(color, base, blur_factor * 0.8); // bias toward base to preserve depth
}

vec3 applyGlimmer(vec3 color, vec2 uv) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float glint_factor = smoothstep(glint_threshold, 1.0, luma);

    float n1 = rand(uv * 1000.0);
    float n2 = rand(uv.yx * 750.0);
    float sparkle = smoothstep(0.2, 0.6, n1) * smoothstep(0.2, 0.6, n2);

    vec3 glimmer = vec3(1.0) * glint_factor * glint_boost * sparkle * 0.5;
    return color + glimmer;
}

vec3 addNoise(vec3 color, vec2 uv) {
    float n = rand(uv * 1000.0) * noise_intensity * micro_detail;
    return color + vec3(n);
}

vec3 applyRefraction(vec3 color, vec2 uv) {
    vec2 offset = vec2(rand(uv), rand(uv.yx)) * 0.002;
    vec3 refracted = HOOKED_tex(uv + offset).rgb;
    return mix(color, refracted, reflection_mix);
}

vec3 applyTint(vec3 color) {
    vec3 tinted = mix(color, tint_color, tint_strength);
    tinted = pow(tinted, vec3(1.0 / 1.1));         // gentler gamma lift
    return mix(tinted, color, 0.95);               // restore 95% original color
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec2 uv = HOOKED_pos;

    vec3 base = HOOKED_tex(uv).rgb;
    vec3 color = base;

    vec3 edge = edgeDetect(texel, uv);
    if (debug_mode) return vec4(edge, 1.0); // visualize edge map

    color += strength * edge;
    color = applyGlimmer(color, uv);
    color = addNoise(color, uv);
    color = applyRefraction(color, uv);

    if (enable_depth) {
        color = applyDepthEffect(color, base, rand(uv) * 0.5);
    }

    color = applyTint(color);

    // Optional: perceptual contrast pop
    color = mix(color, pow(color, vec3(1.05)), 0.1);

    vec3 finalColor = mix(color, base, softness);
    finalColor = clamp(finalColor, 0.0, 1.0);

    return vec4(finalColor, 1.0);
}
