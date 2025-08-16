//!HOOK MAIN
//!BIND HOOKED
//!DESC Depth Reality Boost (Adaptive Contrast + Retinex)

vec3 adaptive_contrast(vec3 color, vec2 uv) {
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float contrast = smoothstep(0.2, 0.8, lum);
    return mix(color * 0.9, color * 1.1, contrast);
}

vec3 retinex(vec3 color) {
    vec3 log_color = log(1.0 + color);
    vec3 white_balance = vec3(1.0, 1.0, 1.0);
    vec3 balanced = log_color * white_balance;
    return exp(balanced) - 1.0;
}

vec4 hook() {
    vec2 uv = HOOKED_pos;
    vec3 color = HOOKED_tex(uv).rgb;

    color = adaptive_contrast(color, uv);
    color = retinex(color);

    return vec4(clamp(color, 0.0, 1.0), 1.0);
}