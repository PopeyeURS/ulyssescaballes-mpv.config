//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak 2383 Film Curve (stable 3D boost + tender brightness)

// Kodak-style curve with subtle brightness + depth-weighted dimensionality
vec3 kodak_curve(vec3 c) {
    // Gentle shadow lift
    c = pow(c, vec3(0.945));

    // Mild contrast preserved
    c = mix(c, c * 1.04, 0.5);

    // Tiny global brightness lift (soft polish)
    c *= 1.012;  // just a 1.2% lift

    // Adaptive midtone lift
    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    float factor = smoothstep(0.2, 0.8, luma);
    c *= 1.0 + 0.01 * factor;

    // Depth-weighted contrast boost (adds subtle contouring)
    c = mix(c, c * 1.015, factor * 0.3);

    // Micro-shadow reinforcement (slightly deeper shadows for dimensionality)
    c = pow(c, vec3(0.97));

    // Subtle warmth balance
    c.r *= 1.015;
    c.g *= 0.995;
    c.b *= 0.99;

    return clamp(c, 0.0, 1.0);
}

vec4 hook() {
    vec4 src = HOOKED_tex(HOOKED_pos);
    return vec4(kodak_curve(src.rgb), src.a);
}
