//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Kodak Vision3 2383 — Procedural film tone & contrast (libplacebo-safe)

// Parameters (typed for libplacebo; uniforms auto-generated)
 //!PARAM lut_strength:float=0.80          // blend into film curve
 //!PARAM gamma_lift:float=1.00            // pre-LUT gamma adjustment
 //!PARAM shadow_softness:float=0.50       // gentle shadow compression
 //!PARAM highlight_rolloff:float=0.40     // highlight shoulder strength
 //!PARAM saturation:float=1.00            // global saturation
 //!PARAM print_tint:vec3=(1.00,0.98,0.95) // subtle print stock tint (R,G,B)

// Utility
vec3 to_luma_coeffs() { return vec3(0.2126, 0.7152, 0.0722); }
float luma(vec3 c)    { return dot(c, to_luma_coeffs()); }

// Simple saturation control in linear domain
vec3 apply_saturation(vec3 c, float sat) {
    float Y = luma(c);
    return mix(vec3(Y), c, sat);
}

// Kodak-like film curve: gentle toe, mid contrast, soft shoulder
vec3 kodak_tone(vec3 c, float gamma_lift, float lut_strength) {
    // Pre-gamma lift (neutral at 1.0 by default)
    c = pow(max(c, vec3(0.0)), vec3(1.0 / max(gamma_lift, 1e-6)));

    // Procedural film response:
    vec3 toe      = vec3(1.0) - exp(-c * 1.35);   // lifts shadows smoothly
    vec3 mid      = c / (c + vec3(0.35));         // gentle S-curve
    vec3 shoulder = pow(c, vec3(0.85));           // soft highlight shoulder

    // Blend components to emulate print density behavior
    vec3 film = mix(c, toe,      0.40);
         film = mix(film, mid,   0.35);
         film = mix(film, shoulder, 0.25);

    // Global film blend
    film = mix(c, film, clamp(lut_strength, 0.0, 1.0));

    return clamp(film, 0.0, 1.0);
}

// Shadow softening—compresses deep tones without crushing
vec3 soften_shadows(vec3 c, float shadow_softness) {
    float Y = luma(c);
    float mask = smoothstep(0.00, 0.30, Y);   // only affects low luma
    vec3  soft = c * 0.85;                    // mild compression
    return mix(c, soft, mask * clamp(shadow_softness, 0.0, 1.0));
}

// Highlight rolloff—adds shoulder without flattening mids
vec3 rolloff_highlights(vec3 c, float highlight_rolloff) {
    float peak = max(c.r, max(c.g, c.b));
    float mask = smoothstep(0.70, 1.00, peak); // only affects high luma
    vec3  roll = pow(c, vec3(0.90));           // gentle shoulder
    return mix(c, roll, mask * clamp(highlight_rolloff, 0.0, 1.0));
}

// Subtle print stock tint—applied after tone mapping
vec3 apply_print_tint(vec3 c, vec3 print_tint) {
    return clamp(c * print_tint, 0.0, 1.0);
}

vec4 hook() {
    vec4 src  = HOOKED_tex(HOOKED_pos);
    vec3 base = src.rgb;

    // Optional saturation control (linear domain)
    vec3 sat_base = apply_saturation(base, saturation);

    // Film tone curve
    vec3 film = kodak_tone(sat_base, gamma_lift, lut_strength);

    // Shadow & highlight shaping
    film = soften_shadows(film, shadow_softness);
    film = rolloff_highlights(film, highlight_rolloff);

    // Print tint
    film = apply_print_tint(film, print_tint);

    // Preserve alpha from source
    return vec4(film, src.a);
}
