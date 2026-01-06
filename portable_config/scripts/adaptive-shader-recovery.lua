-- Adaptive shader toggling based on dropped frames
local drop_threshold = 10        -- disable shaders if dropped frames ≥ this
local recovery_threshold = 2     -- re-enable shaders if dropped frames ≤ this
local check_interval = 5         -- seconds between checks
local shader_disabled = false

-- Define your default shader stack here
local default_shaders = {
    "~~/shaders/FSRCNNX/FSRCNNX_x2_16-0-4-1_enhanced.glsl",
    "~~/shaders/SSim/SSimSuperRes.glsl",
    "~~/shaders/SSim/SSimDownscaler.glsl",
    "~~/shaders/depth_reality_boost.glsl",
    "~~/shaders/glimmer-sharpen_0.35.glsl",
    "~~/shaders/fine-sharpen_0.35.glsl",
    "~~/shaders/film-grain.glsl:intensity=0.03"
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
