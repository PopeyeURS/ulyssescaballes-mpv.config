local mp = require "mp"

-- "Delicately Fine Tuned by UlyssesRSCaballes. The ULTIMATE version."

-- Paths to files
local KEMAR_SOFA = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/KEMAR_HRTF.sofa"
local SADIE_BRIR = "C\\:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"

-- OSD helper
local function show(msg, duration)
    mp.osd_message(msg, duration or 3)
end

-- 🎧 Headset Audio Mode (original personal audio set)
local function set_headset_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. KEMAR_SOFA ..
        "':gain=1.0:type=hrtf:normalize=1:interpolate=1," ..
        "loudnorm=I=-23:TP=-2:LRA=7," ..
        "acompressor=threshold=-19dB:ratio=2.3:attack=10:release=100," ..
        "equalizer=f=60:t=q:w=1.2:g=2.0," ..
        "equalizer=f=120:t=q:w=1.0:g=1.0," ..
        "equalizer=f=2500:t=q:w=1.0:g=2.5," ..
        "equalizer=f=4500:t=q:w=1.0:g=2.5," ..
        "equalizer=f=10000:t=q:w=0.7:g=2.0," ..
        "equalizer=f=14000:t=q:w=0.7:g=1.5," ..
        "stereotools=mlev=1.20:slev=1.20:phase=0.9," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.08," ..
        "aresample=96000]"
    )
    show("🎧 Headset Audio Mode Activated", 3)
end

-- 🎬 Ultimate Cinema Mode
local function set_cinema_mode()
    mp.commandv("af", "set",
        "lavfi=[aid]" ..
        "sofalizer=sofa='" .. KEMAR_SOFA .. "':gain=1.08:type=hrtf:normalize=1:interpolate=1:radius=1.7," ..
        "afir=file='" .. SADIE_BRIR .. "'," ..
        "loudnorm=I=-24:TP=-2:LRA=13," ..
        "acompressor=threshold=-16dB:ratio=1.7:attack=18:release=180:makeup=1," ..
        "equalizer=f=30:t=q:w=1.4:g=3.2," ..
        "equalizer=f=50:t=q:w=1.2:g=2.8," ..
        "equalizer=f=900:t=q:w=1.0:g=1.2," ..
        "equalizer=f=1800:t=q:w=0.9:g=1.8," ..
        "equalizer=f=3500:t=q:w=0.9:g=3.2," ..
        "equalizer=f=7000:t=q:w=0.8:g=2.6," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.8," ..
        "equalizer=f=16000:t=q:w=0.6:g=2.2," ..
        "stereotools=mlev=1.18:slev=1.18:phase=0.78:width=1.95:mode=lr>lr," ..
        "alimiter=level_in=1:level_out=0.97:limit=0.10," ..
        "aresample=96000"
    )
    show("🎬 Ultimate Cinema Mode Activated", 4)
end

-- 🎼 Music Hall Mode
local function set_music_hall_mode()
    mp.commandv("af", "set",
        "lavfi=[aid]" ..
        "sofalizer=sofa='" .. KEMAR_SOFA .. "':gain=1.05:type=hrtf:normalize=1:interpolate=1:radius=1.5," ..
        "afir=file='" .. SADIE_BRIR .. "'," ..
        "dynaaudnorm=f=250:g=8:p=0.9," ..
        "equalizer=f=35:t=q:w=1.3:g=2.0," ..
        "equalizer=f=60:t=q:w=1.2:g=1.8," ..
        "equalizer=f=250:t=q:w=1.0:g=1.2," ..
        "equalizer=f=500:t=q:w=1.0:g=1.0," ..
        "equalizer=f=1800:t=q:w=0.9:g=1.4," ..
        "equalizer=f=3200:t=q:w=0.8:g=2.2," ..
        "equalizer=f=7000:t=q:w=0.8:g=2.0," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.4," ..
        "equalizer=f=16000:t=q:w=0.6:g=1.8," ..
        "stereotools=mlev=1.12:slev=1.12:phase=0.82:width=1.65:mode=lr>lr," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.08," ..
        "aresample=96000"
    )
    show("🎼 Music Hall Mode Activated", 4)
end

-- 🔄 Clear filters
local function clear_filters()
    mp.commandv("af", "clr")
    show("🔄 Filters cleared", 3)
end

-- Register script messages
mp.register_script_message("headset-mode", set_headset_audio)
mp.register_script_message("cinema-mode", set_cinema_mode)
mp.register_script_message("music-mode", set_music_hall_mode)
mp.register_script_message("reset-filters", clear_filters)

-- Key bindings: restore original F9-F12
mp.add_forced_key_binding("F9",  "headset_audio_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_mode_key", set_cinema_mode)
mp.add_forced_key_binding("F11", "music_hall_key",  set_music_hall_mode)
mp.add_forced_key_binding("F12", "reset_filters_key", clear_filters)
