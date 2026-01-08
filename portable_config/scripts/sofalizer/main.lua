local mp = require "mp"

-- Path to SOFA file (escape colon for lavfi)
local SOFA_PATH = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/hrtf_M_normal_pinna_resolution_0.5_deg.sofa"

-- Enhanced Headset profile (immersive bubble, refined clarity)
local function set_headset_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf," ..
        "loudnorm=I=-23:TP=-2:LRA=7," ..
        "acompressor=threshold=-19dB:ratio=2.3:attack=10:release=100," ..
        "equalizer=f=40:t=q:w=1.2:g=2," ..
        "equalizer=f=150:t=q:w=1:g=-1," ..
        "equalizer=f=2500:t=q:w=1:g=2.5," ..
        "equalizer=f=4500:t=q:w=1:g=2.5," ..
        "equalizer=f=11000:t=q:w=0.7:g=2," ..
        "equalizer=f=15000:t=q:w=0.7:g=1," ..
        "stereotools=mlev=1.22:slev=1.22:phase=1," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625," ..
        "aresample=48000]"
    )
    mp.osd_message("🎧 Enhanced Headset", 3000)
    mp.add_timeout(3, function() mp.osd_message("") end)
end

-- Enhanced Cinema profile (SOFA-based, tuned for speakers)
local function set_cinema_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf," ..
        "loudnorm=I=-24:TP=-2:LRA=9," ..
        "acompressor=threshold=-18dB:ratio=2.0:attack=12:release=120," ..
        "equalizer=f=40:t=q:w=1.2:g=2," ..
        "equalizer=f=500:t=q:w=1:g=-1," ..
        "equalizer=f=2000:t=q:w=1:g=3.5," ..
        "equalizer=f=3500:t=q:w=1:g=3.5," ..
        "equalizer=f=11000:t=q:w=0.7:g=2," ..
        "equalizer=f=15000:t=q:w=0.7:g=1," ..
        "stereotools=mlev=1.08:slev=1.08:phase=1," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625," ..
        "aresample=48000]"
    )
    mp.osd_message("🏛️ Enhanced Cinema", 3000)
    mp.add_timeout(3, function() mp.osd_message("") end)
end

-- Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    mp.osd_message("🔄 Filters cleared", 3000)
    mp.add_timeout(3, function() mp.osd_message("") end)
end

-- Inspector: show current filter chain
local function show_filters()
    local filters = mp.get_property("af")
    if filters == "" then
        mp.osd_message("🔍 No active filters", 3000)
    else
        local formatted = filters:gsub(",", "\n")
        mp.osd_message("🔍 Active filters:\n" .. formatted, 4000)
    end
    mp.add_timeout(4, function() mp.osd_message("") end)
end

-- Bindings
mp.add_key_binding(nil, "headset_best", set_headset_audio)
mp.add_key_binding(nil, "cinema_best", set_cinema_audio)
mp.add_key_binding(nil, "reset_filters", clear_filters)
mp.add_key_binding(nil, "show_filters", show_filters)

mp.add_forced_key_binding("F9", "headset_best_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_best_key", set_cinema_audio)
mp.add_forced_key_binding("F11", "reset_filters_key", clear_filters)
mp.add_forced_key_binding("Shift+F11", "show_filters_key", show_filters)
