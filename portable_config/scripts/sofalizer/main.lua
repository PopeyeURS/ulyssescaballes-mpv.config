local mp = require "mp"

-- "Delicately Fine Tuned by UlyssesRSCaballes. The ULTIMATE version."

-- Paths to SOFA files
local KEMAR_SOFA = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/KEMAR_HRTF.sofa"
local SADIE_BRIR = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"

-- OSD helper
local function show(msg, duration)
    mp.osd_message(msg, duration or 3)
end

-- 🎧 HEADSET REFERENCE MODE

local function set_headset_audio()

    mp.commandv("af", "set",

        -- Crossfeed (speaker-like presentation)
        "bs2b=profile=cmoy," ..

        -- Spatial HRTF
        "sofalizer=sofa='" .. KEMAR_SOFA ..
        "':type=hrtf:interpolate=1:normalize=1:radius=1.5:gain=1.02," ..

        -- Bass control
        "firequalizer=gain_entry='entry(30,3);entry(50,2);entry(80,1)'," ..

        -- Clarity EQ
        "equalizer=f=2500:t=q:w=1.0:g=2.2," ..
        "equalizer=f=4500:t=q:w=1.0:g=2.0," ..
        "equalizer=f=10000:t=q:w=0.8:g=1.8," ..

        -- Stereo depth
        "stereotools=mlev=1.15:slev=1.15:phase=0.9:width=1.55," ..

        -- Gentle dynamics
        "acompressor=threshold=-20dB:ratio=1.6:attack=12:release=120," ..

        -- Limiter
        "alimiter=limit=0.09:level_out=0.985," ..

        -- High quality resampling
        "aresample=resampler=soxr:precision=33:sample_rate=96000:dither_method=shibata"
    )

    show("🎧 Headset Reference Mode Activated", 3)
end

-- 🎬 ULTIMATE CINEMA MODE

local function set_cinema_mode()

    mp.commandv("af", "set",

        -- Upmix stereo → 5.1 before virtualization
        "surround=chl_in=stereo:chl_out=5.1," ..

        -- Crossfeed for speaker realism
        "bs2b=profile=cmoy," ..

        -- Main HRTF spatialization
        "sofalizer=sofa='" .. KEMAR_SOFA ..
        "':type=hrtf:interpolate=1:normalize=1:radius=1.95:gain=1.08," ..

        -- Psychoacoustic early reflections
        "haas=left_delay=2.5:right_delay=3.1:left_gain=0.95:right_gain=0.95," ..

        -- Room impulse (large theater simulation)
        "afir=file='" .. SADIE_BRIR .. "'," ..

        -- Subwoofer style bass management
        "firequalizer=gain_entry='entry(25,4);entry(40,3);entry(60,2)'," ..

        -- Cinematic EQ
        "equalizer=f=900:t=q:w=1.0:g=1.0," ..
        "equalizer=f=1800:t=q:w=1.0:g=1.6," ..
        "equalizer=f=2200:t=q:w=1.0:g=1.2," ..
        "equalizer=f=3000:t=q:w=1.0:g=2.4," ..
        "equalizer=f=6000:t=q:w=0.8:g=2.2," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.6," ..
        "equalizer=f=16000:t=q:w=0.6:g=2.0," ..

        -- Early reflections for depth
        "aecho=0.6:0.5:30:0.15," ..

        -- Surround perception enhancement
        "stereotools=mlev=1.18:slev=1.18:phase=0.8:width=1.55:mode=lr>lr," ..

        -- Gentle cinema compression
        "acompressor=threshold=-18dB:ratio=1.4:attack=18:release=180," ..

        -- Safety limiter
        "alimiter=limit=0.07:level_out=0.97," ..

        -- High-precision resampling
        "aresample=resampler=soxr:precision=33:sample_rate=96000:dither_method=shibata"
    )

    show("🎬 Ultimate Cinema Mode Activated", 4)
end

-- 🎼 MUSIC HALL MODE

local function set_music_hall_mode()

    mp.commandv("af", "set",

        -- Crossfeed
        "bs2b=profile=cmoy," ..

        -- HRTF
        "sofalizer=sofa='" .. KEMAR_SOFA ..
        "':type=hrtf:interpolate=1:normalize=1:radius=1.6:gain=1.05," ..

        -- Concert hall BRIR
        "afir=file='" .. SADIE_BRIR .. "'," ..

        -- Smooth orchestral bass
        "firequalizer=gain_entry='entry(35,2);entry(60,1.8);entry(120,1)'," ..

        -- Musical EQ balance
        "equalizer=f=250:t=q:w=1.0:g=1.2," ..
        "equalizer=f=500:t=q:w=1.0:g=1.0," ..
        "equalizer=f=1800:t=q:w=0.9:g=1.4," ..
        "equalizer=f=3200:t=q:w=0.8:g=2.0," ..
        "equalizer=f=7000:t=q:w=0.8:g=1.8," ..
        "equalizer=f=12000:t=q:w=0.7:g=2.2," ..

        -- Concert hall reflections
        "aecho=0.8:0.7:45:0.28," ..

        -- Natural stereo width
        "stereotools=mlev=1.12:slev=1.12:phase=0.82:width=1.55," ..

        -- Very light dynamics
        "dynaaudnorm=f=250:g=6:p=0.9," ..

        -- limiter
        "alimiter=limit=0.08:level_out=0.985," ..

        -- High resolution audio
        "aresample=sample_rate=96000"
    )

    show("🎼 Music Hall Mode Activated", 4)
end

-- 🔄 CLEAR FILTERS

local function clear_filters()
    mp.commandv("af", "clr")
    show("🔄 Filters Cleared", 3)
end

-- Script message registration

mp.register_script_message("headset-mode", set_headset_audio)
mp.register_script_message("cinema-mode", set_cinema_mode)
mp.register_script_message("music-mode", set_music_hall_mode)
mp.register_script_message("reset-filters", clear_filters)

-- Key bindings

mp.add_forced_key_binding("F9",  "headset_audio_key", set_headset_audio)
mp.add_forced_key_binding("F10", "cinema_mode_key", set_cinema_mode)
mp.add_forced_key_binding("F11", "music_hall_key",  set_music_hall_mode)
mp.add_forced_key_binding("F12", "reset_filters_key", clear_filters)
