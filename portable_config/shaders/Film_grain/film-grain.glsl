//!HOOK LUMA
//!BIND HOOKED
//!DESC Subtle luminance-weighted film grain
//!PARAM intensity 0.03

uniform float intensity;

float permute(float x) {
    x = (34.0 * x + 1.0) * x;
    return fract(x * (1.0 / 289.0)) * 289.0;
}

float rand(inout float state) {
    state = permute(state);
    return fract(state * (1.0 / 41.0));
}

vec4 hook() {
    vec3 m = vec3(HOOKED_pos, 1.0); // Removed time for static grain
    float state = permute(permute(m.x) + m.y) + m.z;

    const float a0 = 0.151015505647689;
    const float a1 = -0.5303572634357367;
    const float a2 = 1.365020122861334;
    const float b0 = 0.132089632343748;
    const float b1 = -0.7607324991323768;

    float p = 0.95 * rand(state) + 0.025;
    float q = p - 0.5;
    float r = q * q;

    float grain = q * (a2 + (a1 * r + a0) / (r * r + b1 * r + b0));
    grain *= 0.255121822830526; // Normalize to [-1,1)

    vec4 color = texture(HOOKED, HOOKED_pos);
    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float weight = smoothstep(0.3, 0.8, luminance);

    color.rgb += vec3(intensity * grain * weight);
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    return color;
}
