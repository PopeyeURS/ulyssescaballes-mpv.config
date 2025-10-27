-- Adaptive shader toggling based on dropped frames
local drop_threshold = 10        -- disable shaders if dropped frames ≥ this
local recovery_threshold = 2     -- re-enable shaders if dropped frames ≤ this
local check_interval = 5         -- seconds between checks
local shader_disabled = false

local function check_performance()
    local dropped = mp.get_property_number("vo-drop-frame-count", 0)

    if dropped >= drop_threshold and not shader_disabled then
        mp.command("glsl-shader-clear")
        shader_disabled = true
        mp.osd_message("Shaders disabled: dropped frames exceeded", 3)
    elseif dropped <= recovery_threshold and shader_disabled then
        -- Re-apply your default shader stack
        mp.commandv("glsl-shader-append", "~~/shaders/FSRCNNX/FSRCNNX_x2_16-0-4-1_enhanced.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/SSim/SSimSuperRes.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/SSim/SSimDownscaler.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/depth_reality_boost.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/glimmer-sharpen_0.35.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/fine-sharpen_0.35.glsl")
        mp.commandv("glsl-shader-append", "~~/shaders/film-grain.glsl:intensity=0.03")
        shader_disabled = false
        mp.osd_message("Shaders re-enabled: performance recovered", 3)
    end
end

mp.register_event("file-loaded", function()
    shader_disabled = false
    mp.add_timeout(check_interval, function()
        mp.add_periodic_timer(check_interval, check_performance)
    end)
end)