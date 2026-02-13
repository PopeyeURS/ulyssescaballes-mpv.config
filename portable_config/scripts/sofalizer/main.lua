local mp = require "mp"

-- "Delicately Fine Tuned by UlyssesRSCaballes. The FINAL version."

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
        "':gain=1.08:type=hrtf:normalize=1:interpolate=1:radius=1.55:rotation=0," ..

        -- Preserve cinematic dynamics (less compression)
        "loudnorm=I=-24:TP=-2:LRA=13," ..

        "acompressor=threshold=-16dB:ratio=1.7:attack=18:release=180:makeup=1," ..

        -- Subwoofer foundation (physicality illusion)
        "equalizer=f=28:t=q:w=1.4:g=3.2," ..
        "equalizer=f=50:t=q:w=1.2:g=2.8," ..
        "equalizer=f=80:t=q:w=1.0:g=1.8," ..

        -- Dialogue anchor band
        "equalizer=f=900:t=q:w=1.0:g=1.2," ..
        "equalizer=f=1800:t=q:w=0.9:g=1.8," ..

        -- Height & spatial air
        "equalizer=f=3500:t=q:w=0.9:g=3.2," ..
        "equalizer=f=7000:t=q:w=0.8:g=2.6," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.8," ..
        "equalizer=f=16000:t=q:w=0.6:g=2.2," ..

        -- Advanced spatial widening with center protection
        "stereotools=mlev=1.18:slev=1.18:phase=0.78:width=1.95:mode=lr>lr," ..

        -- Micro early reflections (rear wall illusion)
        "aecho=0.55:0.65:12:0.16," ..
        "aecho=0.45:0.55:22:0.12," ..

        -- Very subtle late room bloom (ceiling perception)
        "aecho=0.35:0.45:38:0.08," ..

        -- Light decorrelation for surround separation
        "aphaser=in_gain=0.3:out_gain=0.6:delay=1.2:decay=0.3:speed=0.15," ..

        "alimiter=level_in=1:level_out=0.97:limit=0.10," ..
        "aresample=48000]"
    )
    show("🏛️ Cinema Mode – Maximum 19.1 Immersion", 4)
end

-- 🎵 Music Mode Plus (IMAX Concert Hall)
local function set_music_audio()
    mp.commandv("af", "set",
        "lavfi=[aid]sofalizer=sofa='" .. SOFA_PATH ..
        "':gain=1.05:type=hrtf:normalize=1:interpolate=1:radius=1.45," ..

        -- Gentle dynamic leveling (very transparent)
        "dynaaudnorm=f=250:g=8:p=0.9," ..

        -- Subtle low foundation (hall body)
        "equalizer=f=35:t=q:w=1.3:g=2.0," ..
        "equalizer=f=60:t=q:w=1.2:g=1.8," ..

        -- Warmth (wood & brass body)
        "equalizer=f=250:t=q:w=1.0:g=1.2," ..
        "equalizer=f=500:t=q:w=1.0:g=1.0," ..

        -- Presence (string articulation)
        "equalizer=f=1800:t=q:w=0.9:g=1.4," ..
        "equalizer=f=3200:t=q:w=0.8:g=2.2," ..

        -- Air & height
        "equalizer=f=7000:t=q:w=0.8:g=2.0," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.4," ..
        "equalizer=f=16000:t=q:w=0.6:g=1.8," ..

        -- Natural hall width (less extreme than cinema)
        "stereotools=mlev=1.12:slev=1.12:phase=0.82:width=1.65:mode=lr>lr," ..

        -- Early reflections (stage depth, not echo)
        "aecho=0.5:0.6:14:0.14," ..
        "aecho=0.4:0.5:26:0.10," ..

        -- Very light late bloom (hall ceiling)
        "aecho=0.3:0.4:42:0.06," ..

        -- Subtle decorrelation for section separation
        "aphaser=in_gain=0.25:out_gain=0.55:delay=1.0:decay=0.25:speed=0.1," ..

        "alimiter=level_in=1:level_out=0.985:limit=0.08," ..
        "aresample=48000]"
    )
    show("🎼 Concert Hall Realism Mode", 4)
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
