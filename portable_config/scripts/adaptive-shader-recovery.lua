-- adaptive-shader-recovery.lua
-- Adaptive shader toggling based on dropped frames
-- Corrected version: mirrors mpv.conf baseline stack, clears before reapply

local drop_threshold = 10        -- disable shaders if dropped frames ≥ this
local recovery_threshold = 2     -- re-enable shaders if dropped frames ≤ this
local check_interval = 5         -- seconds between checks
local shader_disabled = false

-- Define your baseline shader stack (mirrors mpv.conf)
local default_shaders = {
    "~~/shaders/FSRCNNX/FSRCNNX_x2_16-0-4-1_enhanced.glsl",
    "~~/shaders/SSim/SSimSuperRes.glsl",
    "~~/shaders/Adaptive_sharpen/adaptive-sharpen-1.0.glsl",
    "~~/shaders/Glimmer_sharpen/glimmer-sharpen_0.41.glsl",
    "~~/shaders/Depth_reality_boost/depth_reality_boost.glsl",
    "~~/shaders/FilmEmulation_Kodak/Kodak_2383_Procedural.glsl"
}

-- Helper to reapply shaders cleanly
local function reapply_shaders()
    mp.command("glsl-shader-clear")
    for _, shader in ipairs(default_shaders) do
        mp.commandv("glsl-shader-append", shader)
    end
end

-- Performance check logic
local function check_performance()
    local dropped = mp.get_property_number("vo-drop-frame-count", 0)

    if dropped >= drop_threshold and not shader_disabled then
        mp.command("glsl-shader-clear")
        shader_disabled = true
        mp.osd_message("Shaders disabled: dropped frames exceeded", 3)

    elseif dropped <= recovery_threshold and shader_disabled then
        reapply_shaders()
        shader_disabled = false
        mp.osd_message("Shaders re-enabled: performance recovered", 3)
    end
end

-- Start periodic monitoring when a file is loaded
mp.register_event("file-loaded", function()
    shader_disabled = false
    mp.add_periodic_timer(check_interval, check_performance)
end)
