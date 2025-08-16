//!HOOK MAIN
//!BIND HOOKED
//!DESC Glimmer Sharpen (Glass & Jewelry)

// Strength of shimmer
#define STRENGTH 0.35
#define GLINT_BOOST 1.8
#define LUMA_THRESHOLD 0.6

vec4 hook() {
    vec2 texel = vec2(1.0 / textureSize(HOOKED, 0));
    
    // Sample surrounding pixels
    vec3 north = texture(HOOKED, HOOKED_pos + vec2(0.0, -texel.y)).rgb;
    vec3 south = texture(HOOKED, HOOKED_pos + vec2(0.0,  texel.y)).rgb;
    vec3 east  = texture(HOOKED, HOOKED_pos + vec2( texel.x, 0.0)).rgb;
    vec3 west  = texture(HOOKED, HOOKED_pos + vec2(-texel.x, 0.0)).rgb;
    vec3 center = texture(HOOKED, HOOKED_pos).rgb;

    // Edge detection
    vec3 edge = center * 5.0 - (north + south + east + west);
    vec3 sharpened = center + STRENGTH * edge;

    // Luminance-based glint boost
    float luma = dot(center, vec3(0.299, 0.587, 0.114));
    if (luma > LUMA_THRESHOLD) {
        vec3 glint = edge * GLINT_BOOST;
        sharpened += glint;
    }

    return vec4(sharpened, 1.0);
}