-- shader-recovery.lua
-- Modular shader stack recovery with conditional profiles
-- Corrected version: mirrors mpv.conf baseline stack, clears before reapply

local mp = require 'mp'

-- Define named shader profiles
local shader_profiles = {
    ["cinema_default"] = {
        "~~/shaders/FSRCNNX/FSRCNNX_x2_16-0-4-1_enhanced.glsl",
        "~~/shaders/SSim/SSimSuperRes.glsl",
        "~~/shaders/Adaptive_sharpen/adaptive-sharpen-1.0.glsl",
        "~~/shaders/Glimmer_sharpen/glimmer-sharpen_0.41.glsl",
        "~~/shaders/Depth_reality_boost/depth_reality_boost.glsl",
        "~~/shaders/FilmEmulation_Kodak/Kodak_2383_Procedural.glsl"
    },
    ["8k_performance"] = {
        "~~/shaders/SSim/SSimSuperRes.glsl"
    },
    ["anime_soft"] = {
        "~~/shaders/Anime4K.glsl",
        "~~/shaders/Retinex.glsl"
    }
}

-- Profile selection logic
local function select_profile()
    local width = mp.get_property_number("dwidth", 0)
    local height = mp.get_property_number("dheight", 0)
    local path = mp.get_property("path", "")

    if width >= 7680 or height >= 4320 then
        return "8k_performance"
    elseif path:match("[Aa]nime") then
        return "anime_soft"
    else
        return "cinema_default"
    end
end

-- Apply a named shader profile safely
local function apply_shader_profile(profile_name)
    local stack = shader_profiles[profile_name]
    if not stack then
        mp.msg.warn("Shader profile not found: " .. profile_name)
        return
    end

    -- Always clear before reapply to prevent duplication
    mp.command("glsl-shader-clear")

    for _, shader in ipairs(stack) do
        mp.commandv("glsl-shader-append", shader)
    end

    mp.osd_message("Shader profile applied: " .. profile_name, 3)
end

-- Manual recovery trigger
local function recover_shaders()
    local profile = select_profile()
    apply_shader_profile(profile)
end

-- Auto-recover if no shaders are active
local function auto_recover()
    local active = mp.get_property_native("glsl-shaders")
    if not active or #active == 0 then
        mp.msg.info("No active shaders detected. Recovering...")
        recover_shaders()
    end
end

-- Bindings
mp.add_key_binding("r", "recover_shaders", recover_shaders)
mp.register_script_message("recover_shaders", recover_shaders)
mp.register_event("file-loaded", auto_recover)
