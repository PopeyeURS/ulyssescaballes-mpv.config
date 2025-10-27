-- midrange-boost.lua
-- Applies a midrange EQ boost for vocal clarity and cinematic warmth

local mp = require 'mp'

local function apply_midrange_boost()
  mp.commandv("af", "add", "equalizer=f=1000:t=q:w=1:g=3")
  mp.commandv("af", "add", "equalizer=f=3000:t=q:w=1:g=2")
  mp.osd_message("Midrange Boost Applied 🎧")
end

mp.add_key_binding("b", "midrange_boost", apply_midrange_boost)