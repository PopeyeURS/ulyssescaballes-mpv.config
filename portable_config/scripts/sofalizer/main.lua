local mp = require "mp"

-- Path to SOFA file (escape colon for lavfi)
local SOFA_PATH = "C\\:/Users/user/AppData/Roaming/mpv/portable_config/scripts/sofalizer/Kemar_HRTF_sofa.sofa"

-- Enhanced Headset profile
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

-- Enhanced Cinema profile
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

-- Music mode profile (Plus: enhanced clarity, separation, and wider stage)
local function set_music_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf," ..
        "loudnorm=I=-23:TP=-2:LRA=8," ..
        "acompressor=threshold=-20dB:ratio=2.2:attack=8:release=90," ..
        "equalizer=f=50:t=q:w=1.2:g=2," ..       -- bass foundation
        "equalizer=f=250:t=q:w=1:g=-1.5," ..    -- reduce muddiness
        "equalizer=f=1000:t=q:w=0.8:g=2," ..    -- vocal clarity (narrower Q for precision)
        "equalizer=f=3000:t=q:w=0.8:g=2.5," ..  -- instrument separation
        "equalizer=f=5000:t=q:w=0.8:g=2.5," ..  -- presence boost (cymbals, snare, brass)
        "equalizer=f=8000:t=q:w=0.7:g=1.5," ..  -- upper presence (guitar strings, piano harmonics)
        "equalizer=f=12000:t=q:w=0.7:g=2," ..   -- treble shimmer
        "equalizer=f=16000:t=q:w=0.7:g=1.5," .. -- air & sparkle
        "stereotools=mlev=1.08:slev=1.08:phase=1:width=1.35," .. -- wider stereo field
        "alimiter=level_in=1:level_out=0.985:limit=0.0625," ..
        "aresample=48000]"
    )
    mp.osd_message("🎵 Music Mode Plus", 4000)
    mp.add_timeout(4, function() mp.osd_message("") end)
end

-- Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    mp.osd_message("🔄 Filters cleared", 3000)
    mp.add_timeout(3, function() mp.osd_message("") end)
end

-- Inspector
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
mp.add_forced_key_binding("F9", "headset_best_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_best_key", set_cinema_audio)
mp.add_forced_key_binding("F12", "music_best_key", set_music_audio)
mp.add_forced_key_binding("F11", "reset_filters_key", clear_filters)
