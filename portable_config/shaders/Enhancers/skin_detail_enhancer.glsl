//!HOOK MAIN
//!BIND HOOKED
//!DESC Skin Detail Enhancer
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height
//!WHEN OUTPUT

vec4 hook() {
    vec2 uv = HOOKED_pos.xy / HOOKED_size.xy;

    // High-frequency noise for pore simulation
    float noise = fract(sin(dot(uv * 1000.0, vec2(12.9898, 78.233))) * 43758.5453);
    float micrograin = smoothstep(0.4, 0.6, noise);

    // Directional anisotropy for hair strand texture
    vec2 dir = vec2(1.0, 0.5);
    float strand = sin(dot(uv * HOOKED_size.xy, dir) * 0.05) * 0.5 + 0.5;

    // Subtle contrast modulation
    vec3 base = texture(HOOKED, HOOKED_pos).rgb;
    float detail = mix(micrograin, strand, 0.5);
    vec3 enhanced = base + (detail - 0.5) * 0.03; // Adjust strength here

    // Clamp to prevent color blowout
    enhanced = clamp(enhanced, 0.0, 1.0);

    return vec4(enhanced, 1.0);
}
