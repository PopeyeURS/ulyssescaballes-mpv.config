local mp = require "mp"

-- "Delicately Fine Tuned by UlyssesCaballes."

-- Path to SOFA file (escape colon for lavfi)
local SOFA_PATH = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/Kemar_HRTF_sofa.sofa"

-- OSD helper (duration in seconds)
local function show(msg, duration)
    mp.osd_message(msg, duration or 3)
end

-- 🎧 Enhanced Headset profile
local function set_headset_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-23:TP=-2:LRA=7," ..
        "acompressor=threshold=-19dB:ratio=2.3:attack=10:release=100," ..
        "equalizer=f=40:t=q:w=1.2:g=2," ..
        "equalizer=f=150:t=q:w=1:g=-1," ..
        "equalizer=f=2500:t=q:w=1:g=2.5," ..
        "equalizer=f=4500:t=q:w=1:g=2.5," ..
        "equalizer=f=11000:t=q:w=0.7:g=2," ..
        "equalizer=f=15000:t=q:w=0.7:g=1," ..
        "stereotools=mlev=1.22:slev=1.22:phase=0.9," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.08," ..
        "aresample=48000]"
    )
    show("🎧 Enhanced Headset", 3)
end

-- 🏛️ Enhanced Cinema profile
local function set_cinema_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-24:TP=-2:LRA=9," ..
        "acompressor=threshold=-18dB:ratio=2.0:attack=12:release=120," ..
        "equalizer=f=40:t=q:w=1.2:g=2," ..
        "equalizer=f=500:t=q:w=1:g=-1," ..
        "equalizer=f=2000:t=q:w=1:g=3.5," ..
        "equalizer=f=3500:t=q:w=1:g=3.5," ..
        "equalizer=f=11000:t=q:w=0.7:g=2," ..
        "equalizer=f=15000:t=q:w=0.7:g=1," ..
        "stereotools=mlev=1.08:slev=1.08:phase=0.85," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.085," ..
        "aresample=48000]"
    )
    show("🏛️ Enhanced Cinema", 3)
end

-- 🎵 Music Mode Plus profile
local function set_music_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH .. "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-23:TP=-2:LRA=8," ..
        "acompressor=threshold=-15dB:ratio=2.4:attack=8:release=95," ..
        "equalizer=f=50:t=q:w=1.2:g=2.0," ..
        "equalizer=f=65:t=q:w=1.2:g=1.2," ..
        "equalizer=f=80:t=q:w=1.0:g=2.5," ..
        "equalizer=f=95:t=q:w=1.0:g=1.0," ..
        "equalizer=f=100:t=q:w=1.0:g=2.0," ..
        "equalizer=f=120:t=q:w=1.0:g=-0.5," ..
        "equalizer=f=145:t=q:w=1.0:g=0.7," ..
        "equalizer=f=200:t=q:w=1.0:g=1.8," ..
        "equalizer=f=250:t=q:w=1:g=-1.5," ..
        "equalizer=f=350:t=q:w=1.0:g=1.2," ..
        "equalizer=f=400:t=q:w=1.0:g=1.5," ..
        "equalizer=f=500:t=q:w=1.0:g=0.5," ..
        "equalizer=f=600:t=q:w=1.0:g=1.2," ..
        "equalizer=f=1000:t=q:w=0.8:g=2.0," ..
        "equalizer=f=1800:t=q:w=0.8:g=1.5," ..
        "equalizer=f=2000:t=q:w=0.8:g=0.9," ..
        "equalizer=f=2500:t=q:w=0.9:g=1.5," ..
        "equalizer=f=3000:t=q:w=0.8:g=2.5," ..
        "equalizer=f=3500:t=q:w=0.8:g=2.0," ..
        "equalizer=f=4000:t=q:w=0.8:g=0.7," ..
        "equalizer=f=5000:t=q:w=0.8:g=2.5," ..
        "equalizer=f=7000:t=q:w=0.8:g=2.5," ..
        "equalizer=f=8000:t=q:w=0.7:g=1.9," ..
        "equalizer=f=9000:t=q:w=0.7:g=2.0," ..
        "equalizer=f=10000:t=q:w=0.7:g=3.0," ..
        "equalizer=f=12000:t=q:w=0.7:g=3.5," ..
        "equalizer=f=14000:t=q:w=0.7:g=3.0," ..
        "equalizer=f=16000:t=q:w=0.7:g=2.5," ..
        "stereotools=mlev=1.08:slev=1.08:phase=0.85:width=1.43," ..
        "aecho=0.8:0.9:30:0.25," ..
        "alimiter=level_in=1:level_out=0.99:limit=0.16," ..
        "aresample=48000]"
    )
    show("🎵 Music Mode Plus", 4)
end

-- 🔄 Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    show("🔄 Filters cleared", 3)
end

-- Key bindings
mp.add_forced_key_binding("F9",  "headset_best_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_best_key",  set_cinema_audio)
mp.add_forced_key_binding("F11", "music_best_key",   set_music_audio)
mp.add_forced_key_binding("F12", "reset_filters_key",clear_filters)
