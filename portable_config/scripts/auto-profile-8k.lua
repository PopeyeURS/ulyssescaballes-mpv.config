-- Auto-trigger the [8k] profile for high-res or high-fps content
mp.register_event("file-loaded", function()
    local width = mp.get_property_number("width", 0)
    local height = mp.get_property_number("height", 0)
    local fps = mp.get_property_number("fps", 0)

    local is_8k = width >= 7680 and height >= 4320
    local is_high_fps = fps >= 60

    if is_8k or is_high_fps then
        mp.commandv("apply-profile", "8k")
        mp.osd_message("8K profile activated", 2)
    end
end)