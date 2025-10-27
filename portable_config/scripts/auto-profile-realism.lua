-- Auto-trigger the [realism] profile for 1080p–4K content under 60fps
mp.register_event("file-loaded", function()
    local width = mp.get_property_number("width", 0)
    local height = mp.get_property_number("height", 0)
    local fps = mp.get_property_number("fps", 0)

    local is_realism_res = width >= 1920 and width <= 3840 and height >= 1080 and height <= 2160
    local is_low_fps = fps > 0 and fps < 60

    if is_realism_res and is_low_fps then
        mp.commandv("apply-profile", "realism")
        mp.osd_message("Realism profile activated", 2)
    end
end)