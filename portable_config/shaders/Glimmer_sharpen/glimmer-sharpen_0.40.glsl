//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen 0.40 — Adaptive Cinematic Edition
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height
//!FORMAT rgb
//!DEFAULT strength 0.46
//!DEFAULT glint_boost 1.9
//!DEFAULT luma_threshold 0.83
//!DEFAULT softness 0.11
//!DEFAULT noise_intensity 0.016
//!DEFAULT reflection_mix 0.45

uniform float strength;
uniform float glint_boost;
uniform float luma_threshold;
uniform float softness;
uniform float noise_intensity;
uniform float reflection_mix;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec3 center = HOOKED_tex(HOOKED_pos).rgb;

    // Edge detection
    vec3 north = HOOKED_tex(HOOKED_pos + vec2(0.0, -texel.y)).rgb;
    vec3 south = HOOKED_tex(HOOKED_pos + vec2(0.0,  texel.y)).rgb;
    vec3 east  = HOOKED_tex(HOOKED_pos + vec2( texel.x, 0.0)).rgb;
    vec3 west  = HOOKED_tex(HOOKED_pos + vec2(-texel.x, 0.0)).rgb;

    vec3 edge = center * 5.0 - (north + south + east + west);
    vec3 sharpened = center + strength * edge;

    // Adaptive glint boost
    float luma = dot(center, vec3(0.299, 0.587, 0.114));
    float glint_factor = smoothstep(luma_threshold, 1.0, luma);
    sharpened += edge * glint_boost * glint_factor;

    // Simulated reflection/refraction blend
    vec3 reflect_dir = normalize(vec3(0.0, 0.0, 1.0));
    vec3 reflection = reflect(center, reflect_dir);
    vec3 refraction = refract(center, reflect_dir, 1.5);
    vec3 gloss = mix(reflection, refraction, 0.5) * reflection_mix;
    sharpened += gloss;

    // Subtle noise for organic texture
    float n = rand(HOOKED_pos * HOOKED_size.xy) * noise_intensity;
    sharpened += vec3(n);

    // Soft blend with original for stability
    vec3 final = mix(sharpened, center, softness);
    final = clamp(final, 0.0, 1.2);

    return vec4(clamp(final, 0.0, 1.0), 1.0);
}
