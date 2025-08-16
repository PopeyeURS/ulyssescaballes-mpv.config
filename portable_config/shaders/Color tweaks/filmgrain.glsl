//!HOOK MAIN
//!BIND MAIN
//!DESC Subtle Film Grain
vec4 hook() {
    vec4 color = texel(MAIN, pos);
    float grain = fract(sin(dot(pos.xy ,vec2(12.9898,78.233))) * 43758.5453);
    color.rgb += (grain - 0.5) * 0.02; // Gentle noise
    return clamp(color, 0.0, 1.0);
}