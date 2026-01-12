//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak 2383 Film Curve (simple)

// Simple Kodak-style curve: light warmth + contrast
vec3 kodak_curve(vec3 c) {
    // Gentle shadow lift
    c = pow(c, vec3(0.96));
    // Mild contrast
    c = mix(c, c * 1.04, 0.5);
    // Subtle warmth
    c.r *= 1.02;
    c.g *= 0.99;
    c.b *= 0.98;
    return clamp(c, 0.0, 1.0);
}

vec4 hook() {
    vec4 src = HOOKED_tex(HOOKED_pos);
    return vec4(kodak_curve(src.rgb), src.a);
}
