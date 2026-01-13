//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak 2383 Film Curve (brighter, sharp, glittery)

// Adjusted Kodak-style curve: brighter + sparkle-friendly
vec3 kodak_curve(vec3 c) {
    // Slightly stronger shadow lift for brightness
    c = pow(c, vec3(0.94));
    // Mild contrast preserved
    c = mix(c, c * 1.04, 0.5);
    // Global brightness boost
    c *= 1.02;
    // Subtle warmth balance
    c.r *= 1.02;
    c.g *= 0.99;
    c.b *= 0.98;
    return clamp(c, 0.0, 1.0);
}

vec4 hook() {
    vec4 src = HOOKED_tex(HOOKED_pos);
    return vec4(kodak_curve(src.rgb), src.a);
}
