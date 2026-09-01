local mp = require 'mp'
local msg_duration = 3

local current_mode = "none"

-- ======
-- 🔊 Version 29.0 – PREMIUM PLATINUM AUDIO BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260901 100703LT
-- ======
-- Description:
-- Version 29.0 expands spatial depth, dynamic punch, and live clarity.
-- Bass reinforcement now precedes compression for natural realism.
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
-- Dialogue clarity + controlled dynamics
-- ======
local cinema_filters = {
    "volume=-3dB",
    "aresample=resampler=soxr:precision=33",
    "highpass=f=20",

    "equalizer=f=58:g=1.0",
    "equalizer=f=260:g=-0.8",

    "equalizer=f=1800:g=2.0",
    "equalizer=f=2400:g=0.8",
    "equalizer=f=2800:g=1.5",
    "equalizer=f=4500:g=-0.5",
    "bass=g=3:f=80",
    "acompressor=threshold=-10dB:ratio=1.2:attack=8:release=400",
    "equalizer=f=8500:g=0.5",
    "equalizer=f=12000:g=0.4"
}

-- ======
-- 🎼 CONCERT MODE
-- Live energy + wide stage
-- ======
local music_filters = {
    "volume=-5dB",
    "aresample=resampler=soxr:precision=33",
    "highpass=f=20",
    "equalizer=f=52:g=1.5",
    "equalizer=f=280:g=-0.6",
    "equalizer=f=2200:g=1.0",
    "extrastereo=level=0.8",
    "bass=g=6:f=80",
    "equalizer=f=40:g=1.0",
    "equalizer=f=8500:g=1.0",
    "equalizer=f=12000:g=0.4"
}

-- ======
-- KEY BINDINGS
-- ======

mp.add_key_binding("F9", "pure-mode", function()
    apply_audio_filters(
        pure_filters,
        "🎧🌈 Pure Headset Reference Playback"
    )
end)

mp.add_key_binding("F10", "cinema-mode", function()
    apply_audio_filters(
        cinema_filters,
        "🎬🌠 Cinema IMAX-inspired SenseSurround Mode"
    )
end)

mp.add_key_binding("F11", "music-mode", function()
    apply_audio_filters(
        music_filters,
        "🎵🎇 Music Live Concert Mode"
    )
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
