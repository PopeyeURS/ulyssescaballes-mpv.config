local mp = require 'mp'
local msg_duration = 3
local current_mode = "none"

-- ======
-- Version 35.0 - PREMIUM PLATINUM AUDIO BUILD - IMMERSIVE SURROUND EDITION
-- 🔊 ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 20260907 221106LT
-- ======
-- Features:
-- Pure Mode: Filter-bypass for reference playback
-- Cinema Mode: IMAX-grade clarity + spatial depth + pseudo-surround
-- Music Mode: Live concert realism + energetic impact + pseudo-surround
-- Safe filter application + OSD feedback
-- ======

-- ======
-- SAFE FILTER APPLIER
-- ======
local function apply_audio_filters(filters, message)
    mp.set_property_native("af", {})

    for _, filter in ipairs(filters) do
        local ok, err = pcall(function()
            mp.commandv("af", "add", filter)
        end)

        if not ok then
            mp.msg.error("Failed filter: " .. filter .. " | " .. tostring(err))
            mp.osd_message("⚠️ Failed filter: " .. filter, 2)
        end
    end

    current_mode = message
    mp.osd_message(message, msg_duration)
end

-- ======
-- 🎧 PURE MODE
-- Filter-bypass playback for pure headset reference
-- ======
local pure_filters = {}

-- ======
-- 🌌 CINEMA MODE
-- IMAX-inspired: Wide soundstage, deep bass, crystalline highs, pseudo-surround
-- ======

local cinema_filters = {
    "aresample=resampler=soxr:precision=33",
    "extrastereo=0.9",
    "highpass=f=22",
    "bass=g=6:f=70:width_type=o:width=1.0",
    "equalizer=f=40:g=1.2:width_type=o:width=1.0",
    "equalizer=f=250:g=-1.2:width_type=o:width=1.0",
    "equalizer=f=1800:g=1.5:width_type=o:width=1.0",
    "equalizer=f=3200:g=1.0:width_type=o:width=1.0",
    "equalizer=f=8500:g=1.0:width_type=o:width=1.0",
    "equalizer=f=10000:g=1.2:width_type=o:width=1.0",
    "equalizer=f=12000:g=0.8:width_type=o:width=1.0",
    "pan=7.1|FL=1.0|FR=1.0|FC=0.7|LFE=0.8|BL=0.8|BR=0.8|SL=0.7|SR=0.7",
    "adelay=12|12",
    "acompressor=threshold=-14dB:ratio=1.6:attack=5:release=250",
    "volume=+1.5dB"
}

-- ======
-- 🎼 MUSIC MODE
-- Live Concert: Expansive stereo, natural balance, crowd ambience, pseudo-surround
-- ======

local music_filters = {
    "aresample=resampler=soxr:precision=33",
    "extrastereo=0.78",
    "highpass=f=22",
    "bass=g=3.3:f=65:width_type=o:width=1.3",
    "equalizer=f=50:g=1.1:width_type=o:width=1.0",
    "equalizer=f=250:g=-0.3:width_type=o:width=1.0",
    "equalizer=f=2200:g=0.35:width_type=o:width=1.0",
    "equalizer=f=4800:g=0.25:width_type=o:width=1.0",
    "equalizer=f=6000:g=-0.3:width_type=o:width=0.7",
    "equalizer=f=9500:g=0.35:width_type=o:width=0.9",
    "equalizer=f=12000:g=0.5:width_type=o:width=0.9",
    "pan=7.1|FL=1.0|FR=1.0|FC=0.6|LFE=0.7|BL=0.7|BR=0.7|SL=0.7|SR=0.7",
    "adelay=15|15",
    "acompressor=threshold=-18dB:ratio=1.25:attack=10:release=300",
    "volume=+1.2dB"
}

-- ======
-- KEY BINDINGS
-- ======

mp.add_key_binding("F9", "pure-mode", function()
    apply_audio_filters(pure_filters, "🎧 Pure Headset Reference Playback")
end)

mp.add_key_binding("F10", "cinema-mode", function()
    apply_audio_filters(cinema_filters, "🎬 Cinema IMAX-inspired SenseSurround Mode")
end)

mp.add_key_binding("F11", "music-mode", function()
    apply_audio_filters(music_filters, "🎵 Music Live Concert Mode")
end)

mp.add_key_binding("F12", "reset-filters", function()
    mp.set_property_native("af", {})
    current_mode = "none"
    mp.osd_message("♻️ Filters Cleared", msg_duration)
end)

-- ======
-- AUTO SOURCE DETECTION
-- ======
mp.register_event("file-loaded", function()
    local ch = mp.get_property("audio-channels")

    if ch == "mono" or ch == "stereo" then
        mp.osd_message("🎧 Stereo Source Loaded", msg_duration)
    else
        mp.osd_message("🎬 Multichannel Source Loaded", msg_duration)
    end
end)
