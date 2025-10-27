//!HOOK LUMA
//!BIND HOOKED
//!DESC Film Grain Smooth (TAPS = 2)
//!COMPUTE 32 32

#define INTENSITY 0.1
#define TAPS 2
#define GRAIN_SIZE (32 + 2 * TAPS)

layout(rgba32f, binding = 0) uniform image2D out_image;

const float weights[2 * TAPS + 1] = float[](
    0.05448868454964,
    0.24420134200323,
    0.40261994689424,
    0.24420134200323,
    0.05448868454964
);

shared float grain[GRAIN_SIZE][GRAIN_SIZE];

// Permutation-based PRNG
float permute(float x) {
    x = (34.0 * x + 1.0) * x;
    return fract(x * (1.0 / 289.0)) * 289.0;
}

float seed(uvec2 pos) {
    const float phi = 1.61803398874989;
    vec2 base = fract(phi * vec2(pos));
    float z = float(pos.x + pos.y);
    vec3 m = vec3(base, z) + vec3(1.0);
    return permute(permute(m.x) + m.y) + m.z;
}

float rand(inout float state) {
    state = permute(state);
    return fract(state * (1.0 / 41.0));
}

float rand_gaussian(inout float state) {
    const float a0 = 0.151015505647689;
    const float a1 = -0.5303572634357367;
    const float a2 = 1.365020122861334;
    const float b0 = 0.132089632343748;
    const float b1 = -0.7607324991323768;

    float p = 0.95 * rand(state) + 0.025;
    float q = p - 0.5;
    float r = q * q;

    float g = q * (a2 + (a1 * r + a0) / (r * r + b1 * r + b0));
    g *= 0.255121822830526;
    return g;
}

void hook() {
    const uint row_size = 2 * TAPS + 1;
    const uvec2 isize = gl_WorkGroupSize + uvec2(2 * TAPS);
    uint num_threads = gl_WorkGroupSize.x * gl_WorkGroupSize.y;

    // Generate raw grain
    for (uint i = gl_LocalInvocationIndex; i < isize.y * isize.x; i += num_threads) {
        uvec2 pos = uvec2(i % isize.x, i / isize.x);
        float state = seed(gl_WorkGroupID.xy * gl_WorkGroupSize.xy + pos);
        grain[pos.y][pos.x] = rand_gaussian(state);
    }

    barrier();

    // Horizontal convolution
    for (uint y = gl_LocalInvocationID.y; y < isize.y; y += gl_WorkGroupSize.y) {
        float hsum = 0.0;
        for (uint x = 0; x < row_size; x++) {
            float g = grain[y][gl_LocalInvocationID.x + x];
            hsum += weights[x] * g;
        }
        grain[y][gl_LocalInvocationID.x + TAPS] = hsum;
    }

    barrier();

    // Vertical convolution
    float vsum = 0.0;
    for (uint y = 0; y < row_size; y++) {
        float g = grain[gl_LocalInvocationID.y + y][gl_LocalInvocationID.x + TAPS];
        vsum += weights[y] * g;
    }

    vec4 color = texture(HOOKED, HOOKED_pos);
    color.rgb += vec3(INTENSITY * vsum);
    color.rgb = clamp(color.rgb, 0.0, 1.0);

    imageStore(out_image, ivec2(gl_GlobalInvocationID.xy), color);
}
