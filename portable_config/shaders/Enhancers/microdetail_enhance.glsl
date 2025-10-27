//!HOOK MAIN
//!BIND HOOKED
//!DESC Micro Detail Enhancer
//!PARAM strength
//!PARAM threshold 0.5
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

uniform float strength;    // how much micro detail to add
uniform float threshold;   // minimum contrast to enhance

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec3 c = texture(HOOKED, HOOKED_pos).rgb;

    // 8‑neighbor high-pass
    vec3 sum = vec3(0.0);
    sum += texture(HOOKED, HOOKED_pos + vec2(texel.x, 0.0)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(-texel.x, 0.0)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(0.0, texel.y)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(0.0, -texel.y)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(texel.x, texel.y)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(texel.x, -texel.y)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(-texel.x, texel.y)).rgb;
    sum += texture(HOOKED, HOOKED_pos + vec2(-texel.x, -texel.y)).rgb;

    vec3 mean = sum / 8.0;
    vec3 high = c - mean;

    // Convert to luminance weight — boost high where contrast is high
    float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float w = smoothstep(threshold, 1.0, lum);

    vec3 enhanced = c + high * strength * w;
    enhanced = clamp(enhanced, 0.0, 1.0);

    return vec4(enhanced, 1.0);
}
