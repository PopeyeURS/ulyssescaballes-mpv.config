//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak 2383 Procedural Film Curve + Microtexture + Grain + Bloom + Adaptive Midtone Lift

// --- Kodak-style curve - Polished to perfection by UlyssesCaballes ---
vec3 kodak_curve(vec3 c) {
    c = pow(c, vec3(0.945));                          // Gentle shadow lift
    c = mix(c, c * 1.04, 0.5);                        // Mild contrast preserved
    c *= 1.012;                                       // Tiny global brightness lift
    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    float factor = smoothstep(0.2, 0.8, luma);
    c *= 1.0 + 0.01 * factor;                         // Adaptive midtone lift
    c = mix(c, c * 1.015, factor * 0.3);              // Depth-weighted contrast boost
    c = pow(c, vec3(0.97));                           // Micro-shadow reinforcement
    c.r *= 1.015; c.g *= 0.995; c.b *= 0.99;          // Subtle warmth balance
    return clamp(c, 0.0, 1.0);
}

// --- Microtexture enhancement ---
vec3 microtexture(vec2 uv, vec3 color) {
    vec3 north = HOOKED_tex(uv + vec2(0.0, -0.001)).rgb;
    vec3 south = HOOKED_tex(uv + vec2(0.0,  0.001)).rgb;
    vec3 east  = HOOKED_tex(uv + vec2(0.001, 0.0)).rgb;
    vec3 west  = HOOKED_tex(uv + vec2(-0.001, 0.0)).rgb;
    vec3 detail = color - 0.25 * (north + south + east + west);
    return color + detail * 0.02; // 2% micro-boost
}

// --- Procedural grain (breathes with luminance) ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453);
}
vec3 film_grain(vec2 uv, vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float grain_strength = 0.015 * smoothstep(0.2, 1.0, luma); // stronger in highlights
    float noise = hash(uv * vec2(1920.0,1080.0) + vec2(float(gl_FragCoord.x), float(gl_FragCoord.y)));
    return color + (noise - 0.5) * grain_strength;
}

// --- Adaptive highlight bloom ---
vec3 highlight_bloom(vec2 uv, vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float bloom_mask = smoothstep(0.75, 1.0, luma); // only strong highlights
    vec3 blur = 0.5 * HOOKED_tex(uv + vec2(0.001,0.001)).rgb +
                0.5 * HOOKED_tex(uv + vec2(-0.001,-0.001)).rgb;
    return color + bloom_mask * (blur - color) * 0.05; // subtle glow
}

// --- Adaptive midtone lift (final polish) ---
vec3 adaptive_midtone(vec3 color) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float lift = smoothstep(0.25, 0.65, luma);       // focus on mids
    return color * (1.0 + 0.007 * lift);             // +0.7% gentle gain
}

vec4 hook() {
    vec2 uv = HOOKED_pos;
    vec4 src = HOOKED_tex(uv);

    vec3 base     = kodak_curve(src.rgb);
    vec3 textured = microtexture(uv, base);
    vec3 grained  = film_grain(uv, textured);
    vec3 bloomed  = highlight_bloom(uv, grained);
    vec3 lifted   = adaptive_midtone(bloomed);       // final adaptive polish

    return vec4(clamp(lifted,0.0,1.0), src.a);
}
