-- scripts/sofalizer/main.lua
local mp = require 'mp'

-- Load your modular audio scripts
dofile(mp.find_config_file("scripts/main_cinema.lua"))
dofile(mp.find_config_file("scripts/main_headset.lua"))

-- Startup confirmation
mp.register_event("start-file", function()
    mp.osd_message("🎶 IMAX audio bindings loaded (F9/F10/F11)", 4)
    mp.msg.info("Sofalizer main.lua: Cinema + Headset modules initialized")
end)
