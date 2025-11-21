// Anime4K_Upscale_Denoise_B.glsl
// Replacement draft for missing Anime4K shader
// Author: Ulysses RS Caballes
// Purpose: Upscale by 2x and apply bilateral denoise tuned for anime content

//!DESC Anime4K-Upscale-Denoise-B
//!HOOK MAIN
//!BIND HOOKED
//!SAVE OUT
//!WIDTH MAIN.w 2 *
//!HEIGHT MAIN.h 2 *

// Parameters
#define UPSCALE_FACTOR 2.0
#define SIGMA_SPATIAL 2.0   // spatial radius
#define SIGMA_RANGE   0.08  // intensity sensitivity

vec4 hook() {
    // Upscale coordinates
    vec2 uv = HOOKED_pos / 2.0;

    vec3 center = HOOKED_tex(uv).rgb;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;

    // Bilateral filter kernel
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(x, y) / HOOKED_size;
            vec3 sample = HOOKED_tex(uv + offset).rgb;

            float spatialWeight = exp(-dot(offset, offset) / (2.0 * SIGMA_SPATIAL * SIGMA_SPATIAL));
            float rangeWeight   = exp(-dot(sample - center, sample - center) / (2.0 * SIGMA_RANGE * SIGMA_RANGE));
            float weight = spatialWeight * rangeWeight;

            sum += sample * weight;
            wsum += weight;
        }
    }

    vec3 denoised = sum / wsum;
    return vec4(denoised, 1.0);
}
