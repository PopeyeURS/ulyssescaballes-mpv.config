//!HOOK MAIN
//!BIND HOOKED
//!DESC Gentle Skin Color Boost

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    // Convert to HSV for better saturation control
    float maxc = max(color.r, max(color.g, color.b));
    float minc = min(color.r, min(color.g, color.b));
    float delta = maxc - minc;
    float saturation = (maxc == 0.0) ? 0.0 : delta / maxc;

    // Boost saturation slightly in midtones
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    float boost = smoothstep(0.3, 0.7, luminance) * 0.08;

    // Apply warmth to skin tones (red/yellow bias)
    vec3 warm_shift = vec3(0.02, 0.01, -0.01);
    color.rgb += warm_shift * boost;

    // Apply saturation boost
    color.rgb = mix(color.rgb, normalize(color.rgb) * maxc, boost);

    return clamp(color, 0.0, 1.0);
}