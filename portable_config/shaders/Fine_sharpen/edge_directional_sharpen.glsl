//!HOOK MAIN
//!BIND HOOKED
//!DESC Directional Edge Sharpen
//!PARAM strength 0.2
//!WIDTH HOOKED.width
//!HEIGHT HOOKED.height

uniform float strength;

vec4 hook() {
    vec2 texel = vec2(1.0 / HOOKED_size.x, 1.0 / HOOKED_size.y);
    vec3 c = texture(HOOKED, HOOKED_pos).rgb;

    // Sobel 3x3 horizontal & vertical
    float hx = 0.0;
    float hy = 0.0;

    // Sample luminance for direction computation
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));

    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            vec3 s = texture(HOOKED, HOOKED_pos + vec2(dx, dy) * texel).rgb;
            float ls = dot(s, vec3(0.2126, 0.7152, 0.0722));
            int wx = dx == 0 ? 0 : dx > 0 ? 1 : -1;
            int wy = dy == 0 ? 0 : dy > 0 ? 1 : -1;
            // Simple Sobel weights
            hx += ls * float(wx) * 1.0;
            hy += ls * float(wy) * 1.0;
        }
    }

    float mag = sqrt(hx*hx + hy*hy);
    vec3 sharpen = c + (c - texture(HOOKED, HOOKED_pos + vec2(hx, hy) * texel)) * strength * mag;

    sharpen = clamp(sharpen, 0.0, 1.0);
    return vec4(sharpen, 1.0);
}
