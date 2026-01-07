-- main.lua (SOFA-based headset + cinema profiles, clear OSD notices)
-- F9 -> headset_best (immersive headset profile)
-- F10 -> cinema_best (immersive cinema speaker profile)
-- F11 -> reset_filters
-- Shift+F11 -> show current filter chain

local mp = require "mp"

-- Path to SOFA file (escape colon for lavfi)
local SOFA_PATH = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/hrtf_M_normal_pinna_resolution_0.5_deg.sofa"

-- Headset profile (immersive bubble, punchy clarity)
local function set_headset_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf," ..
        "loudnorm=I=-23:TP=-2:LRA=7," ..
        "acompressor=threshold=-19dB:ratio=2.3:attack=10:release=100," ..
        "equalizer=f=70:t=q:w=1.2:g=3," ..
        "equalizer=f=150:t=q:w=1:g=-1," ..
        "equalizer=f=2500:t=q:w=1:g=2.2," ..
        "equalizer=f=4500:t=q:w=1:g=2.2," ..
        "equalizer=f=11000:t=q:w=0.7:g=1.6," ..
        "stereotools=mlev=1.22:slev=1.22:phase=1," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625," ..
        "aresample=48000]"
    )
    mp.osd_message("🎧 Headset", 3000)
end

-- Cinema profile (SOFA-based, tuned for speakers)
local function set_cinema_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf," ..
        "loudnorm=I=-24:TP=-2:LRA=9," ..
        "acompressor=threshold=-18dB:ratio=2.0:attack=12:release=120," ..
        "equalizer=f=60:t=q:w=1.2:g=4," ..
        "equalizer=f=2000:t=q:w=1:g=4," ..
        "equalizer=f=3500:t=q:w=1:g=4," ..
        "equalizer=f=11000:t=q:w=0.7:g=1.8," ..
        "stereotools=mlev=1.08:slev=1.08:phase=1," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625," ..
        "aresample=48000]"
    )
    mp.osd_message("🏛️ Cinema", 3000)
end

-- Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    mp.osd_message("🔄 Filters cleared", 3000)
end

-- Inspector: show current filter chain
local function show_filters()
    local filters = mp.get_property("af")
    mp.osd_message("🔍 Active filters", 3000)
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
