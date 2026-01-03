local mp = require 'mp'

local function switch_profile(name, label)
    mp.set_property("af", "")
    mp.set_property("vf", "")
    mp.set_property("glsl-shaders", "")
    mp.commandv("apply-profile", name)
    mp.osd_message("Profile: " .. label, 2)
end

mp.register_script_message("switch_clear", function() switch_profile("clear-default", "Clear Default") end)
mp.register_script_message("switch_anime", function() switch_profile("anime-hdr", "Anime-HDR") end)
mp.register_script_message("switch_realism", function() switch_profile("realism", "Realism") end)
mp.register_script_message("switch_sports", function() switch_profile("sports", "Sports") end)
mp.register_script_message("switch_debug", function() switch_profile("debug", "Debug") end)
