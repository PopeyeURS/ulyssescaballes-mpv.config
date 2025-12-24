-- exit_fullscreen.lua
mp.register_event("end-file", function()
    mp.set_property("fullscreen", "no")
end)