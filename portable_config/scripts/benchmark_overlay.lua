local mp = require 'mp'

local function update_overlay()
    local stats = mp.get_property_native("stats")
    local video_fps = mp.get_property("fps")
    local dropped_frames = stats["frame-drop-count"]
    local frame_time = stats["present-speed"]
    local resolution = mp.get_property("width") .. "x" .. mp.get_property("height")
    local shader_debug = mp.get_property("gpu-debug") or "off"

    local text = string.format(
        "Benchmark Overlay\nResolution: %s\nFPS: %s\nFrame Time: %.2f ms\nDropped Frames: %d\nShader Debug: %s",
        resolution, video_fps, frame_time * 1000, dropped_frames, shader_debug
    )

    mp.osd_message(text, 2)
end

mp.add_key_binding("b", "toggle_benchmark_overlay", update_overlay)