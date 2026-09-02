local mp = require 'mp'
local msg_duration = 3

local current_mode = "none"

-- ======
-- 🔊 Version 33.0 - PREMIUM PLATINUM AUDIO BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + IMAX-Cinema Mode
-- 20260902 164743LT
-- ======
-- Description:
-- Version 33.0 unleashes IMAX‑grade 3‑D surround immersion.
-- Expands extrastereo width for panoramic soundstage,
-- drives reinforced sub‑bass slam for explosive impact,
-- adds high‑frequency sparkle for crystalline detail,
-- and applies controlled compression to preserve clarity.
-- Designed for blockbuster action with lifelike spatial depth
-- while avoiding harshness or metallic coloration.
--
-- 🎵 Music Live Concert Mode:
-- Recreates the atmosphere of a grand philharmonic hall,
-- with expansive stereo width for orchestral staging,
-- finely tuned EQ to reveal woodwinds, brass, percussion,
-- keyboards and synths in natural balance,
-- and airy high‑frequency lift for audience claps and hall ambience.
-- Delivers deeply immersive fidelity that makes you feel
-- present at a live performance, surrounded by the energy of the crowd.
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
-- IMAX-inspired cinematic clarity + controlled dynamics
-- ======
local cinema_filters = {
    "aresample=resampler=soxr:precision=33",
    "highpass=f=22",
    "bass=g=6:f=70:width_type=o:width=1.0",
    "equalizer=f=40:g=1.2:width_type=o:width=1.0",
    "equalizer=f=250:g=-1.2:width_type=o:width=1.0",
    "equalizer=f=1800:g=1.5:width_type=o:width=1.0",
    "equalizer=f=3200:g=1.0:width_type=o:width=1.0",
    "equalizer=f=8500:g=1.0:width_type=o:width=1.0",
    "equalizer=f=10000:g=1.2:width_type=o:width=1.0",
    "equalizer=f=12000:g=0.8:width_type=o:width=1.0",
    "extrastereo=0.9",
    "acompressor=threshold=-14dB:ratio=1.6:attack=5:release=250",
    "volume=+2dB"
}

-- ======
-- 🎼 MUSIC MODE
-- Refined Realism + Energetic Live Impact
local music_filters = {
    "aresample=resampler=soxr:precision=33",
    "highpass=f=25",
    "bass=g=2.0:f=70:width_type=o:width=1.2",
    "equalizer=f=60:g=0.8:width_type=o:width=1.0",
    "equalizer=f=250:g=-0.4:width_type=o:width=1.0",
    "equalizer=f=2200:g=0.4:width_type=o:width=1.0",
    "equalizer=f=4800:g=0.3:width_type=o:width=1.0",
    "equalizer=f=8500:g=0.4:width_type=o:width=1.0",
    "equalizer=f=12000:g=0.6:width_type=o:width=1.0",
    "extrastereo=0.95",
    "acompressor=threshold=-16dB:ratio=1.5:attack=8:release=280",
    "volume=+1.5dB"
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
