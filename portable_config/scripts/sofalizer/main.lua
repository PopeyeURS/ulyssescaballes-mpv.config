-- scripts/sofalizer/main.lua
local mp = require 'mp'

-- Load your modular audio scripts
dofile(mp.find_config_file("scripts/main_cinema.lua"))
dofile(mp.find_config_file("scripts/main_headset.lua"))
