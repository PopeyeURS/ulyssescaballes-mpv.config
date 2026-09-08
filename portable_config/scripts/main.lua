local mp = require 'mp'
local msg_duration = 3
local current_mode = "none"

-- ======
-- Version 37.0 - ULTIMATE MASTER AUDIO BUILD - IMMERSIVE IMAX CINEMA EDITION
-- 🔊 ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 20260908 162309LT
-- ======
-- Description:
-- Pure truth. Cinematic thunder. Concert‑hall fire.
-- An ultimate audio build delivering reference transparency,
-- IMAX‑grade immersion, and live‑stage energy - all at the tap of a key.
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
    "bass=g=6.0:f=55:width_type=o:width=1.3",
    "equalizer=f=80:g=1.2:width_type=o:width=1.0",
    "equalizer=f=300:g=0.8:width_type=o:width=1.0",
    "equalizer=f=2500:g=1.0:width_type=o:width=1.0",
    "equalizer=f=6000:g=1.2:width_type=o:width=1.0",
    "equalizer=f=12000:g=1.0:width_type=o:width=1.0",
    "acompressor=threshold=-20dB:ratio=2.2:attack=3:release=180:makeup=3.0",
    "volume=+0.5dB",
    "adelay=12|12|22|8|18|18|18|18",
    "stereotools=width=1.6:phase=0.25:surround=0.35",
    "crystalizer=amount=0.3"
}

-- ======
-- 🎼 MUSIC MODE
-- Live Concert Acoustic Hall Envelopment
-- ======
local music_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=22",
    "bass=g=4.0:f=65:width_type=o:width=1.3",
    "equalizer=f=120:g=0.5:width_type=o:width=1.0",
    "equalizer=f=500:g=0.8:width_type=o:width=1.0",
    "equalizer=f=2500:g=1.2:width_type=o:width=1.0",
    "equalizer=f=8000:g=1.0:width_type=o:width=1.0",
    "equalizer=f=14000:g=0.8:width_type=o:width=1.0",
    "acompressor=threshold=-22dB:ratio=1.6:attack=8:release=220:makeup=2.5",
    "volume=+0.7dB",
    "adelay=18|18|28|12|22|22|22|22",
    "stereotools=width=1.4:phase=0.15:surround=0.25",
    "crystalizer=amount=0.25"
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
