local mp = require "mp"

-- "Delicately Fine Tuned by UlyssesRSCaballes."

-- Path to SOFA file (escape colon for lavfi)
local SOFA_PATH = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/Kemar_HRTF_sofa.sofa"

-- OSD helper (duration in seconds)
local function show(msg, duration)
    mp.osd_message(msg, duration or 3)
end

-- 🎧 Enhanced Headset (clarity + intimacy)
local function set_headset_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH ..
        "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-23:TP=-2:LRA=7," ..
        "acompressor=threshold=-19dB:ratio=2.3:attack=10:release=100," ..
        -- Bass punch
        "equalizer=f=60:t=q:w=1.2:g=2.0," ..
        "equalizer=f=120:t=q:w=1.0:g=1.0," ..
        -- Detail clarity
        "equalizer=f=2500:t=q:w=1.0:g=2.5," ..
        "equalizer=f=4500:t=q:w=1.0:g=2.5," ..
        -- Sparkle
        "equalizer=f=10000:t=q:w=0.7:g=2.0," ..
        "equalizer=f=14000:t=q:w=0.7:g=1.5," ..
        "stereotools=mlev=1.20:slev=1.20:phase=0.9," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.08," ..
        "aresample=48000]"
    )
    show("🎧 Enhanced Headset", 3)
end

-- 🏛️ Enhanced Cinema IMAX Virtual (immersion + realism)
local function set_cinema_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH ..
        "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-24:TP=-2:LRA=10," ..
        "acompressor=threshold=-18dB:ratio=2.2:attack=8:release=100," ..
        -- Low-end rumble
        "equalizer=f=40:t=q:w=1.2:g=3.5," ..
        "equalizer=f=80:t=q:w=1.0:g=2.5," ..
        "equalizer=f=120:t=q:w=1.0:g=1.5," ..
        -- Dialogue clarity
        "equalizer=f=500:t=q:w=1.0:g=1.2," ..
        "equalizer=f=1200:t=q:w=0.9:g=1.8," ..
        "equalizer=f=2000:t=q:w=1.0:g=2.0," ..
        -- Spatial cues
        "equalizer=f=3500:t=q:w=1.0:g=3.0," ..
        "equalizer=f=4500:t=q:w=1.0:g=2.5," ..
        "equalizer=f=7000:t=q:w=0.8:g=2.0," ..
        "equalizer=f=9000:t=q:w=0.7:g=2.0," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.5," ..
        "equalizer=f=16000:t=q:w=0.7:g=2.0," ..
        -- Wide spatialization
        "stereotools=mlev=1.12:slev=1.12:phase=0.88:width=1.70," ..
        -- Hall reflections
        "aecho=0.7:0.8:50:0.30," ..
        "alimiter=level_in=1:level_out=0.99:limit=0.14," ..
        "aresample=48000]"
    )
    show("🏛️ Enhanced Cinema IMAX Virtual", 3)
end

-- 🎵 Music Mode Plus (IMAX Concert Hall)
local function set_music_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH ..
        "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-23:TP=-2:LRA=9," ..
        "dynaaudnorm=f=150:g=15:p=0.95," ..
        -- Bass & percussion
        "equalizer=f=60:t=q:w=1.2:g=2.5," ..
        "equalizer=f=100:t=q:w=1.0:g=1.8," ..
        -- Brass warmth
        "equalizer=f=250:t=q:w=1.0:g=1.5," ..
        "equalizer=f=500:t=q:w=1.0:g=1.2," ..
        -- Woodwinds
        "equalizer=f=1000:t=q:w=0.9:g=1.8," ..
        "equalizer=f=2000:t=q:w=0.9:g=1.5," ..
        -- Strings articulation
        "equalizer=f=3000:t=q:w=0.8:g=2.8," ..
        "equalizer=f=4500:t=q:w=0.8:g=2.8," ..
        -- Cymbals & bells
        "equalizer=f=8000:t=q:w=0.7:g=2.2," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.8," ..
        "equalizer=f=16000:t=q:w=0.7:g=2.2," ..
        -- Wide spatialization
        "stereotools=mlev=1.10:slev=1.10:phase=0.85:width=1.70," ..
        -- Concert hall reflections
        "aecho=0.8:0.9:45:0.28," ..
        "alimiter=level_in=1:level_out=0.99:limit=0.16," ..
        "aresample=48000]"
    )
    show("🎵 Music Mode Plus (IMAX Concert Hall)", 4)
end

-- 🔄 Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    show("🔄 Filters cleared", 3)
end

-- Register script messages
mp.register_script_message("headset-mode", set_headset_audio)
mp.register_script_message("cinema-mode", set_cinema_audio)
mp.register_script_message("music-mode", set_music_audio)
mp.register_script_message("reset-filters", clear_filters)

-- Key bindings
mp.add_forced_key_binding("F9",  "headset_best_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_best_key",  set_cinema_audio)
mp.add_forced_key_binding("F11", "music_best_key",   set_music_audio)
mp.add_forced_key_binding("F12", "reset_filters_key",clear_filters)
