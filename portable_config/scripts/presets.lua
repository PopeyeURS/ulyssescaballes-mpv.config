-- presets.lua
-- Handles profile switching via script-message
-- Works with input.conf bindings:
--   Ctrl+1 script-message switch_clear
--   Ctrl+2 script-message switch_anime
--   Ctrl+3 script-message switch_realism
--   Ctrl+4 script-message switch_sports
--   Ctrl+5 script-message switch_debug

-- Utility: clear audio filters before switching
local function clear_filters()
    mp.command("af set \"\"")
end

-- Reset to baseline/default
mp.register_script_message("switch_clear", function()
    clear_filters()
    mp.command("apply-profile default")
    mp.osd_message("▶ Cleared to default")
end)

-- Anime HDR preset
mp.register_script_message("switch_anime", function()
    clear_filters()
    mp.command("apply-profile anime-hdr")
    mp.osd_message("▶ Anime HDR preset active")
end)

-- Realism preset
mp.register_script_message("switch_realism", function()
    clear_filters()
    mp.command("apply-profile realism")
    mp.osd_message("▶ Realism preset active")
end)

-- Sports preset
mp.register_script_message("switch_sports", function()
    clear_filters()
    mp.command("apply-profile sports")
    mp.osd_message("▶ Sports preset active")
end)

-- Debug mode
mp.register_script_message("switch_debug", function()
    clear_filters()
    mp.command("script-binding stats/display-stats-toggle")
    mp.osd_message("▶ Debug mode active")
end)