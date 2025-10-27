//!HOOK MAIN
//!BIND HOOKED
//!DESC Skin Texture Amplifier

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // Amplify mid-frequency contrast
    float detail = smoothstep(0.3, 0.7, luminance) * 0.15;
    vec3 amplified = mix(color.rgb, pow(color.rgb, vec3(0.9)), detail);

    return vec4(clamp(amplified, 0.0, 1.0), color.a);
}