//!HOOK MAIN
//!BIND MAIN
//!DESC Saturation Boost
vec4 hook() {
    vec4 color = texel(MAIN, pos);
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(gray), color.rgb, 1.2); // 1.2 = saturation factor
    return color;
}