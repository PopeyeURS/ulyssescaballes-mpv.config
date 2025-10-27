//!HOOK MAIN
//!BIND HOOKED
//!DESC Simple Super-Resolution Shader
//!WIDTH NATIVE
//!HEIGHT NATIVE

vec4 hook() {
    vec2 texel = HOOKED_texel;
    vec2 size = HOOKED_size;

    // Sample surrounding pixels
    vec4 center = HOOKED_tex(texel);
    vec4 north  = HOOKED_tex(texel + vec2(0.0, -1.0) / size);
    vec4 south  = HOOKED_tex(texel + vec2(0.0,  1.0) / size);
    vec4 east   = HOOKED_tex(texel + vec2( 1.0, 0.0) / size);
    vec4 west   = HOOKED_tex(texel + vec2(-1.0, 0.0) / size);

    // Edge-aware blend
    vec4 edge_enhanced = center + 0.25 * (center - 0.25 * (north + south + east + west));

    // Soft boost
    return mix(center, edge_enhanced, 0.6);
}