//!HOOK MAIN
//!BIND HOOKED
//!SAVE HOOKED

vec3 RRTAndODTFit(vec3 v) {
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFitted(vec3 color) {
    // ACES input matrix (sRGB -> ACES AP1 approx)
    const mat3 ACESInputMat = mat3(
        0.59719, 0.35458, 0.04823,
        0.07600, 0.90834, 0.01566,
        0.02840, 0.13383, 0.83777
    );

    // ACES output matrix (ACES AP1 -> sRGB approx)
    const mat3 ACESOutputMat = mat3(
        1.60475, -0.53108, -0.07367,
       -0.10208,  1.10813, -0.00605,
       -0.00327, -0.07276,  1.07602
    );

    color = ACESInputMat * color;
    color = RRTAndODTFit(color);
    color = ACESOutputMat * color;

    return clamp(color, 0.0, 1.0);
}

void main() {
    vec4 c = HOOKED_tex(HOOKED_pos);
    c.rgb = ACESFitted(c.rgb);
    HOOKED_out = c;
}