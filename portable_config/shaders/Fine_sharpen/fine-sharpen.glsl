//!HOOK MAIN
//!BIND HOOKED
//!DESC Fine Sharpen

#define STRENGTH 0.25  // Try 0.15–0.35 for subtle shimmer

vec4 hook() {
    vec2 texel = vec2(1.0 / textureSize(HOOKED, 0));
    
    // Sample surrounding pixels
    vec3 north = texture(HOOKED, HOOKED_pos + vec2(0.0, -texel.y)).rgb;
    vec3 south = texture(HOOKED, HOOKED_pos + vec2(0.0,  texel.y)).rgb;
    vec3 east  = texture(HOOKED, HOOKED_pos + vec2( texel.x, 0.0)).rgb;
    vec3 west  = texture(HOOKED, HOOKED_pos + vec2(-texel.x, 0.0)).rgb;
    
    vec3 center = texture(HOOKED, HOOKED_pos).rgb;
    
    // Simple edge detection (high-pass)
    vec3 edge = center * 5.0 - (north + south + east + west);
    
    // Apply sharpening
    vec3 sharpened = center + STRENGTH * edge;
    
    return vec4(sharpened, 1.0);
}