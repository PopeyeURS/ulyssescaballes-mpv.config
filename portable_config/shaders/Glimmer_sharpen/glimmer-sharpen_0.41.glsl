//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.41 — UlyssesCaballes' Microscopic Depth Edition (fixed best values)

uniform float HOOKED_time;   // playback time in seconds, provided by mpv/libplacebo

const float strength        = 0.88;   // edge crispness
const float glint_boost     = 0.80;   // sparkle intensity
const float glint_threshold = 0.55;   // luma threshold for glimmer
const float softness        = 0.12;   // blend with base for natural look
const float noise_intensity = 0.025;  // subtle micro-noise
const float reflection_mix  = 0.18;   // gentle refraction shimmer
const float micro_detail    = 1.08;   // fine texture enhancement
const float depth_factor    = 0.55;   // depth blur strength
const vec3  tint_color      = vec3(1.03, 1.00, 0.97); // slight warm tint
const float tint_strength   = 0.09;   // tint blend
const bool  enable_depth    = true;   // always on
const bool  debug_mode      = false;  // off

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 edgeDetect(vec2 texel, vec2 uv) {
    vec3 c  = HOOKED_tex(uv).rgb;
    vec3 n  = HOOKED_tex(uv + vec2(0.0, -texel.y)).rgb;
    vec3 s  = HOOKED_tex(uv + vec2(0.0,  texel.y)).rgb;
    vec3 e  = HOOKED_tex(uv + vec2( texel.x, 0.0)).rgb;
    vec3 w  = HOOKED_tex(uv + vec2(-texel.x, 0.0)).rgb;

    vec3 edge = c * (4.0 + strength) - (n + s + e + w);
    float edge_strength = smoothstep(0.0, 0.3, length(edge));
    return edge * 0.35 * edge_strength;
}

vec3 applyDepthEffect(vec3 color, vec3 base, float depth) {
    float blur_factor = smoothstep(0.0, 1.0, depth * depth_factor);
    return mix(color, base, blur_factor * 0.8);
}

vec3 applyGlimmer(vec3 color, vec2 uv, vec3 base) {
    float luma = dot(base, vec3(0.299, 0.587, 0.114));
    color = applyDepthEffect(color, base, luma * rand(uv));
    float glint_factor = smoothstep(glint_threshold, 1.0, luma);

    float n1 = rand(uv * vec2(103.1, 97.7));
    float n2 = rand(uv.yx * vec2(89.3, 111.7));
    float sparkle = smoothstep(0.2, 0.6, n1) * smoothstep(0.2, 0.6, n2) * (0.9 + 0.1*sin(HOOKED_time*0.5));

    float edge_fade = 1.0 - smoothstep(0.4, 0.9, length(uv - 0.5));
    vec3 glimmer = vec3(1.0) * glint_factor * glint_boost * sparkle * 0.5 * edge_fade;

    return color + glimmer;
}

vec3 addNoise(vec3 color, vec2 uv, vec3 base) {
    float luma = dot(base, vec3(0.299, 0.587, 0.114));
    float n = rand(uv * vec2(103.1, 97.7)) * noise_intensity * micro_detail * (1.0 - luma);
    return color + vec3(n);
}

vec3 applyRefraction(vec3 color, vec2 uv, float edge_strength) {
    vec2 offset = vec2(rand(uv), rand(uv.yx)) * 0.002 * (1.0 - depth_factor * 0.5) * (1.0 + edge_strength);
    vec3 refracted = HOOKED_tex(uv + offset).rgb;
    return mix(color, refracted, reflection_mix);
}

vec3 applyTint(vec3 color) {
    vec3 tinted = mix(color, tint_color, tint_strength);
    tinted = pow(tinted, vec3(1.0 / 1.08)); // subtle filmic lift
    return mix(tinted, color, 0.95);
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec2 uv    = HOOKED_pos;

    vec3 base  = HOOKED_tex(uv).rgb;
    vec3 color = base;

    vec3 edge  = edgeDetect(texel, uv);
    float edge_strength = length(edge);
    if (debug_mode) return vec4(edge, 1.0);

    color += strength * edge * (1.0 - softness);
    color  = applyGlimmer(color, uv, base);
    color  = addNoise(color, uv, base);
    color  = applyRefraction(color, uv, edge_strength);

    if (enable_depth) {
        color = applyDepthEffect(color, base, rand(uv) * 0.5);
    }

    color = applyTint(color);

    // Perceptual contrast pop
    color = mix(color, pow(max(color, 0.0), vec3(1.05)), 0.10);

    vec3 finalColor = mix(color, base, softness);
    finalColor = clamp(finalColor, 0.0, 1.0);

    return vec4(finalColor, 1.0);
}
