//!HOOK MAIN
//!BIND MAIN
//!DESC Microcontrast Boost
vec4 hook() {
    vec4 color = texel(MAIN, pos);
    color.rgb = pow(color.rgb, vec3(1.05)); // Slight gamma lift
    return color;
}