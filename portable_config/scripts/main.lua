local mp = require 'mp'
local msg_duration = 3
local current_mode = "none"

-- ======
-- Version 39.0 - REFINED IMMERSIVE AUDIO BUILD - 🔊 ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 20260909 103848LT
-- ======
-- Description:
-- Refined for absolute artifact-free micro-detail clarity
-- ======

-- ======
-- SAFE FILTER APPLIER
-- ======
local function apply_audio_filters(filters, message)
    mp.commandv("af", "clr", "")

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
-- IMAX Ultra-Spatial & Transient Enhanced
-- ======
local cinema_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=18",
    "bass=g=5.0:f=52:width_type=o:width=1.25",
    "equalizer=f=90:g=1.2:width_type=o:width=1.0",
    "equalizer=f=2800:g=0.8:width_type=o:width=0.9",
    "equalizer=f=4500:g=0.25:width_type=o:width=1.0",
    "equalizer=f=8500:g=0.0:width_type=o:width=1.0",
    "acompressor=threshold=-19dB:ratio=1.7:attack=6:release=180:makeup=1.8",
    "volume=-0.8dB",
    "adelay=10|10|18|7|13|13|13|13",
    "stereotools=base=0.18:slev=1.12:phase=0.06",
    "crystalizer=i=0.12"
}

-- ======
-- 🎼 MUSIC MODE
-- Live Concert Acoustic Hall Envelopment
-- ======
local music_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=22",
    "bass=g=4.5:f=68:width_type=o:width=1.25",
    "equalizer=f=115:g=1.5:width_type=o:width=1.0",
    "equalizer=f=240:g=1.3:width_type=o:width=1.1",
    "equalizer=f=3000:g=0.6:width_type=o:width=1.0",
    "equalizer=f=5200:g=0.3:width_type=o:width=1.0",
    "equalizer=f=8500:g=0.2:width_type=o:width=1.0",
    "equalizer=f=12000:g=0.10:width_type=o:width=1.0",
    "acompressor=threshold=-22dB:ratio=1.25:attack=10:release=280:makeup=1.8",
    "volume=-0.8dB",
    "adelay=7|7|14|5|10|10|10|10",
    "stereotools=base=0.25:slev=1.18:mlev=0.98:phase=0.04",
    "crystalizer=i=0.12"
}

-- ======
-- KEY BINDINGS
-- ======
mp.add_key_binding("F9", "pure-mode", function()
    apply_audio_filters(pure_filters, "🎧 Pure Headset Reference Playback")
end)

mp.add_key_binding("F10", "cinema-mode", function()
    apply_audio_filters(cinema_filters, "🎬 Cinema IMAX Ultra-Spatial Mode")
end)

mp.add_key_binding("F11", "music-mode", function()
    apply_audio_filters(music_filters, "🎵 Music Live Concert Envelopment Mode")
end)

mp.add_key_binding("F12", "reset-filters", function()
    mp.commandv("af", "clr", "")
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
