//!HOOK MAIN
//!BIND MAIN
//!DESC Specular Highlight Pop
vec4 hook() {
    vec4 color = texel(MAIN, pos);
    color.rgb += smoothstep(0.8, 1.0, color.rgb) * 0.05; // Boost bright spots
    return color;
}