//!HOOK MAIN
//!BIND HOOKED
//!DESC Subtle Film Grain
//!PARAM intensity 0.02
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

uniform float intensity;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 hook() {
    vec4 color = texture(HOOKED, HOOKED_pos);
    float grain = rand(HOOKED_pos.xy * 1000.0) - 0.5;
    color.rgb += intensity * grain;
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    return color;
}
