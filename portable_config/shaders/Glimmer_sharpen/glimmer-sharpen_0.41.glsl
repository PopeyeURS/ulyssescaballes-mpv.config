// Patch for libplacebo macro expansions that cause stray vec2 errors
#undef MAINPRESUB_map
#undef HOOKED_map

//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.41 — UlyssesRSCaballes' Microscopic Depth Edition (Vulkan-safe, static glimmer)

layout(std140, set=0, binding=0) uniform Params {
    float HOOKED_time;   // retained for Vulkan layout, but unused
    vec3  _padding;
    vec2  HOOKED_pos;
    vec2  HOOKED_size;
};

layout(set=0, binding=1) uniform sampler2D HOOKED_tex;

const float strength        = 0.88;
const float glint_boost     = 0.80;
const float glint_threshold = 0.55;
const float softness        = 0.12;
const float noise_intensity = 0.025;
const float reflection_mix  = 0.18;
const float micro_detail    = 1.08;
const float depth_factor    = 0.55;
const vec3  tint_color      = vec3(1.03, 1.00, 0.97);
const float tint_strength   = 0.09;
const bool  enable_depth    = true;
const bool  debug_mode      = false;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 edgeDetect(vec2 texel, vec2 uv) {
    vec3 c  = texture(HOOKED_tex, uv).rgb;
    vec3 n  = texture(HOOKED_tex, uv + vec2(0.0, -texel.y)).rgb;
    vec3 s  = texture(HOOKED_tex, uv + vec2(0.0,  texel.y)).rgb;
    vec3 e  = texture(HOOKED_tex, uv + vec2( texel.x, 0.0)).rgb;
    vec3 w  = texture(HOOKED_tex, uv + vec2(-texel.x, 0.0)).rgb;

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
    float sparkle = smoothstep(0.2, 0.6, n1) * smoothstep(0.2, 0.6, n2);

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
    vec2 offset = vec2(sin(uv.x), sin(uv.y)) * 0.0015 * (1.0 + edge_strength);
    vec2 safe_uv = clamp(uv + offset, vec2(0.0), vec2(1.0));
    vec3 refracted = texture(HOOKED_tex, safe_uv).rgb;
    return mix(color, refracted, reflection_mix);
}

vec3 applyTint(vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 tinted = mix(color, tint_color, tint_strength * luma);
    tinted = pow(abs(tinted) + vec3(1e-6), vec3(1.0 / 1.08));
    return mix(tinted, color, 0.95);
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec2 uv = HOOKED_pos;

    vec3 base  = texture(HOOKED_tex, uv).rgb;
    vec3 color = base;

    vec3 edge  = edgeDetect(texel, uv);
    float edge_strength = clamp(length(edge), 0.0, 1.0);

    if (debug_mode)
        return vec4(clamp(edge * 2.0 + 0.5, 0.0, 1.0), 1.0);

    color  = applyGlimmer(color, uv, base);
    color  = addNoise(color, uv, base);
    color  = applyRefraction(color, uv, edge_strength);

    color = applyTint(color);

    vec3 safeColor = abs(color) + vec3(1e-6);
    color = mix(color, pow(safeColor, vec3(1.05)), 0.10);

    vec3 finalColor = mix(color, base, softness);

    return vec4(finalColor, 1.0);
}
