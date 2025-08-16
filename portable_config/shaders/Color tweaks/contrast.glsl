//!HOOK MAIN
//!BIND MAIN
//!DESC Contrast Boost
vec4 hook() {
    vec4 color = texel(MAIN, pos);
    color.rgb = (color.rgb - 0.5) * 1.1 + 0.5; // 1.1 = contrast factor
    return color;
}