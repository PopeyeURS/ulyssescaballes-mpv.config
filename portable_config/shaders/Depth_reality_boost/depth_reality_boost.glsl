//!HOOK RGB
//!BIND HOOKED
//!DESC Depth Reality Boost (Cinematic Realism Variant)
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height
//!DEFAULT strength 0.83
//!DEFAULT radius 0.99
//!DEFAULT warmth 0.15

uniform float strength;
uniform float radius;
uniform float warmth;

vec3 filmic_tonecurve(vec3 x) {
    x = max(vec3(0.0), x - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

vec4 hook() {
    vec2 texel = HOOKED_pt;
    vec3 center = HOOKED_tex(HOOKED_pos).rgb;

    // Base sharpen
    vec3 blur = vec3(0.0);
    float total = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * texel * radius;
            float weight = exp(-dot(offset, offset) * 18.0);
            blur += HOOKED_tex(HOOKED_pos + offset).rgb * weight;
            total += weight;
        }
    }
    blur /= total;
    vec3 sharpen = center * (1.0 + strength) - blur * 0.5;
    sharpen = clamp(sharpen, 0.0, 1.0);

    // Lens bloom
    float glow_intensity = 0.09;
    vec3 bloom = vec3(0.0);
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 offset = vec2(i, j) * texel * 1.5;
            bloom += HOOKED_tex(HOOKED_pos + offset).rgb;
        }
    }
    bloom /= 25.0;
    vec3 glow = bloom * glow_intensity + sharpen * (1.0 - glow_intensity);

    // Cinematic grading
    vec3 graded = glow;
    graded.r += warmth * 0.05;
    graded.b -= warmth * 0.05;
    graded = mix(graded, vec3(graded.r * 1.05, graded.g * 0.98, graded.b * 0.95), 0.3);

    // Tone curve & contrast
    graded = filmic_tonecurve(graded);
    graded = pow(graded, vec3(1.05));

    // Vignette
    vec2 uv = HOOKED_pos - 0.5;
    float vignette = smoothstep(0.7, 0.95, length(uv));
    graded *= mix(1.0, 0.75, vignette);

    // Soft diffusion
    graded = mix(graded, blur, 0.05);

    // Film grain
    float grain = fract(sin(dot(HOOKED_pos.xy, vec2(12.9898, 78.233))) * 43758.5453);
    graded += (grain - 0.5) * 0.015;

    // Final mix
    vec3 final_output = mix(graded, sharpen, 0.15);

    return vec4(clamp(final_output, 0.0, 1.0), 1.0);
}
