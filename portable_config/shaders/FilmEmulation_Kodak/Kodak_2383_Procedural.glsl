//!HOOK RGB
//!BIND HOOKED
//!DESC Kodak Vision3 2383 LUT Shader
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

//!PARAM lut_strength       0.80
//!PARAM gamma_lift         1.00
//!PARAM shadow_softness    0.50
//!PARAM highlight_rolloff  0.40

uniform float lut_strength;
uniform float gamma_lift;
uniform float shadow_softness;
uniform float highlight_rolloff;

vec3 applyKodakLUT(vec3 color) {
    // Simulated Kodak Vision3 tone curve
    color = pow(color, vec3(1.0 / gamma_lift)); // gamma lift
    color = mix(color, vec3(1.0) - exp(-color * 1.5), lut_strength); // filmic contrast
    return clamp(color, 0.0, 1.0);
}

vec3 softenShadows(vec3 color) {
    float shadow = smoothstep(0.0, 0.3, dot(color, vec3(0.299, 0.587, 0.114)));
    return mix(color, color * 0.85, shadow * shadow_softness);
}

vec3 rolloffHighlights(vec3 color) {
    float highlight = smoothstep(0.7, 1.0, max(color.r, max(color.g, color.b)));
    vec3 rolloff = mix(color, pow(color, vec3(0.85)), highlight * highlight_rolloff);
    return rolloff;
}

vec4 hook() {
    vec2 uv = HOOKED_pos;
    vec3 base = HOOKED_tex(uv).rgb;

    vec3 kodak = applyKodakLUT(base);
    kodak = softenShadows(kodak);
    kodak = rolloffHighlights(kodak);

    return vec4(clamp(kodak, 0.0, 1.0), 1.0);
}