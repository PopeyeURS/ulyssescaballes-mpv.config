//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.41 — Enhanced Detail, Depth, and Sparkle
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
};

uniform sampler2D tex;

vec4 sampleTexture(vec2 uv) {
    return texture(tex, uv);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 edgeDetect(vec2 texel, vec2 uv) {
    vec3 center = sampleTexture(uv).rgb;
    vec3 north = sampleTexture(uv + vec2(0.0, -texel.y)).rgb;
    vec3 south = sampleTexture(uv + vec2(0.0, texel.y)).rgb;
    vec3 east  = sampleTexture(uv + vec2(texel.x, 0.0)).rgb;
    vec3 west  = sampleTexture(uv + vec2(-texel.x, 0.0)).rgb;
    return center * 5.0 - (north + south + east + west);
}

vec3 applyDepthEffect(vec3 color, float depth) {
    float blur_factor = smoothstep(0.0, 1.0, depth * depth_factor);
    return mix(color, vec3(0.0), blur_factor);
}

vec3 applyGlimmer(vec3 color, vec2 uv) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float glint_factor = smoothstep(glint_threshold, 1.0, luma);
    float n = rand(uv * 1000.0);
    vec3 glimmer = vec3(1.0) * glint_factor * glint_boost * n;
    return color + glimmer;
}

vec3 addNoise(vec3 color, vec2 uv) {
    float n = rand(uv * 1000.0) * noise_intensity * micro_detail;
    return color + vec3(n);
}

vec3 applyRefraction(vec3 color, vec2 uv) {
    vec2 offset = vec2(rand(uv), rand(uv.yx)) * 0.002;
    vec3 refracted = sampleTexture(uv + offset).rgb;
    return mix(color, refracted, reflection_mix);
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec2 uv = HOOKED_pos;

    vec3 base = sampleTexture(uv).rgb;
    vec3 color = base;

    vec3 edge = edgeDetect(texel, uv);
    color += strength * edge;

    color = applyGlimmer(color, uv);
    color = addNoise(color, uv);
    color = applyRefraction(color, uv);
    color = applyDepthEffect(color, rand(uv) * 0.5);

    vec3 finalColor = mix(color, base, softness);
    finalColor = clamp(finalColor, 0.0, 1.0);

    return vec4(finalColor, 1.0);
}
