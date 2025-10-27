//!HOOK MAIN
//!BIND HOOKED
//!DESC Retinex-inspired Local Contrast Enhancement

vec4 hook() {
    vec2 tex_size = vec2(textureSize(HOOKED, 0));
    vec2 uv = gl_FragCoord.xy / tex_size;

    // Sample original color
    vec3 color = texture(HOOKED, uv).rgb;

    // Gaussian blur for local average
    float radius = 2.5;
    vec3 avg = vec3(0.0);
    float total_weight = 0.0;

    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(x, y) * radius / tex_size;
            float weight = exp(-(x*x + y*y) / (2.0 * radius * radius));
            avg += texture(HOOKED, uv + offset).rgb * weight;
            total_weight += weight;
        }
    }

    avg /= total_weight;

    // Retinex-style enhancement: log ratio
    vec3 enhanced = log(1.0 + color) - log(1.0 + avg);

    // Normalize and boost
    float strength = 0.8;
    vec3 result = color + enhanced * strength;

    // Clamp to avoid clipping
    return vec4(clamp(result, 0.0, 1.0), 1.0);
}