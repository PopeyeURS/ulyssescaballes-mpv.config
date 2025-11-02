//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.41 — Microscopic Depth Edition
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

layout(std140, binding = 0) uniform Params {
    float strength;
    float glint_boost;
    float glint_threshold;
    float softness;
    float noise_intensity;
    float reflection_mix;
    float micro_detail;
    float depth_factor;
    vec3 tint_color;
    float tint_strength;
    bool enable_depth;
    bool debug_mode;
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
    float edge_strength = smoothstep(0.0, 0.3, length(edge));
    return edge * 0.35 * edge_strength;
}

vec3 applyDepthEffect(vec3 color, vec3 base, float depth) {
    float blur_factor = smoothstep(0.0, 1.0, depth * depth_factor);
    return mix(color, base, blur_factor * 0.8);
}

vec3 applyGlimmer(vec3 color, vec2 uv) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float glint_factor = smoothstep(glint_threshold, 1.0, luma);

    float n1 = rand(uv * vec2(103.1, 97.7));
    float n2 = rand(uv.yx * vec2(89.3, 111.7));
    float sparkle = smoothstep(0.2, 0.6, n1) * smoothstep(0.2, 0.6, n2);

    float edge_fade = 1.0 - smoothstep(0.4, 0.9, length(uv - 0.5));
    vec3 glimmer = vec3(1.0) * glint_factor * glint_boost * sparkle * 0.5 * edge_fade;

    return color + glimmer;
}

vec3 addNoise(vec3 color, vec2 uv) {
    float n = rand(uv * vec2(103.1, 97.7)) * noise_intensity * micro_detail;
    return color + vec3(n);
}

vec3 applyRefraction(vec3 color, vec2 uv) {
    vec2 offset = vec2(rand(uv), rand(uv.yx)) * 0.002 * (1.0 - depth_factor * 0.5);
    vec3 refracted = HOOKED_tex(uv + offset).rgb;
    return mix(color, refracted, reflection_mix);
}

vec3 applyTint(vec3 color) {
    vec3 tinted = mix(color, tint_color, tint_strength);
    tinted = pow(tinted, vec3(1.0 / 1.08)); // match filmic tone
    return mix(tinted, color, 0.95);
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec2 uv = HOOKED_pos;

    vec3 base = HOOKED_tex(uv).rgb;
    vec3 color = base;

    vec3 edge = edgeDetect(texel, uv);
    if (debug_mode) return vec4(edge, 1.0);

    color += strength * edge;
    color = applyGlimmer(color, uv);
    color = addNoise(color, uv);
    color = applyRefraction(color, uv);

    if (enable_depth) {
        color = applyDepthEffect(color, base, rand(uv) * 0.5);
    }

    color = applyTint(color);

    // Perceptual contrast pop
    color = mix(color, pow(color, vec3(1.05)), 0.1);

    vec3 finalColor = mix(color, base, softness);
    finalColor = clamp(finalColor, 0.0, 1.0);

    return vec4(finalColor, 1.0);
}
