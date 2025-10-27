//!HOOK MAIN
//!BIND HOOKED
//!DESC Fine Sharpen Tuned for 4K/8K
//!PARAM strength 0.20
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

uniform float strength;

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec3 north = texture(HOOKED, HOOKED_pos + vec2(0.0, -texel.y)).rgb;
    vec3 south = texture(HOOKED, HOOKED_pos + vec2(0.0,  texel.y)).rgb;
    vec3 east  = texture(HOOKED, HOOKED_pos + vec2( texel.x, 0.0)).rgb;
    vec3 west  = texture(HOOKED, HOOKED_pos + vec2(-texel.x, 0.0)).rgb;
    vec3 center = texture(HOOKED, HOOKED_pos).rgb;
    vec3 edge = (north + south + east + west - 4.0 * center);
    vec3 sharpened = clamp(center + strength * edge, 0.0, 1.0);
    return vec4(sharpened, 1.0);
}
