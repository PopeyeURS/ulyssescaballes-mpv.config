//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak 2383 Film Curve (refined)

// Refined Kodak-style curve with subtle S-contrast and color richness
vec3 kodak_curve(vec3 c) {
    // Gentle shadow lift
    c = pow(c, vec3(0.93));

    // Add an S-curve for contrast separation
    c = smoothstep(0.02, 0.98, c);

    // Slight midtone warmth and richness
    c.r *= 1.035;   // red lift
    c.g *= 0.985;   // green balance
    c.b *= 0.975;   // blue softening

    // Subtle saturation boost
    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(luma), c, 1.06);

    return clamp(c, 0.0, 1.0);
}

vec4 hook() {
    vec4 src = HOOKED_tex(HOOKED_pos);
    return vec4(kodak_curve(src.rgb), src.a);
}
