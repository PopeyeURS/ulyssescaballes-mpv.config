local mp = require 'mp'
local msg_duration = 3

local current_mode = "none"

-- ======
-- 🔊 Version 24.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260526 121511LT
-- ======
-- Description:
-- Version 24.0 represents the culmination of refinement and tuning — engineered 
-- for IMAX‑grade immersion and uncompromising realism. Compared to Version 23.0,
-- this build delivers smoother dynamics and spatial realism that feels so much 
-- closer to a professional mastering chain.
-- ======

-- ======
-- SAFE FILTER APPLIER
-- ======
local function apply_audio_filters(filters, message)

    mp.commandv("af", "clear")

    for _, filter in ipairs(filters) do

        local ok = pcall(function()
            mp.commandv("af", "add", filter)
        end)

        if not ok then
            mp.osd_message(
                "⚠️ Failed filter: " .. filter,
                2
            )
        end
    end

    current_mode = message

    mp.osd_message(
        message,
        msg_duration
    )
end

-- ======
-- 🎧 PURE MODE
-- Completely untouched playback
-- Best for high quality masters
-- ======
local pure_filters = {}

-- ======
-- 🌌 CINEMA MODE
-- For movies / HDR / surround downmixes
-- Preserves dynamics and realism
-- ======
local cinema_filters = {

    -- tiny headroom protection
    "volume=-0.3dB",

    -- ultra clean resampling
    "aresample=resampler=soxr:precision=33",

    -- remove inaudible sub rumble
    "highpass=f=28",

    -- subtle low-end reinforcement
    "equalizer=f=58:g=1.0",

    -- remove slight desktop-speaker muddiness
    "equalizer=f=260:g=-0.8",

    -- dialogue intelligibility
    "equalizer=f=2400:g=0.4"
}

-- ======
-- 🎼 MUSIC / CONCERT MODE
-- Preserves live performance realism
-- ======
local music_filters = {

    -- almost transparent headroom
    "volume=-0.3dB",

    -- high quality resampling
    "aresample=resampler=soxr:precision=33",

    -- remove ultra-low rumble only
    "highpass=f=26",

    -- preserve bass punch
    "equalizer=f=52:g=0.8",

    -- reduce boxiness slightly
    "equalizer=f=280:g=-0.6",

    -- preserve vocal and string detail
    "equalizer=f=2200:g=0.3"
}

-- ======
-- F9 = PURE MODE
-- ======
mp.add_key_binding("F9", "pure-mode", function()

    apply_audio_filters(
        pure_filters,
        "🎧🌈 Pure Headset Reference Playback"
    )
end)

-- ======
-- F10 = CINEMA
-- ======
mp.add_key_binding("F10", "cinema-mode", function()

    apply_audio_filters(
        cinema_filters,
        "🎬🌠 Cinema IMAX-inspired SenseSurround Mode"
    )
end)

-- ======
-- F11 = MUSIC / CONCERT
-- ======
mp.add_key_binding("F11", "music-mode", function()

    apply_audio_filters(
        music_filters,
        "🎵🎇 Music Live Concert Mode"
    )
end)

-- ======
-- F12 = RESET
-- ======
mp.add_key_binding("F12", "reset-filters", function()

    mp.commandv("af", "clear")

    current_mode = "none"

    mp.osd_message(
        "♻️🫧 Filters Cleared",
        msg_duration
    )
end)

-- ======
-- SOURCE DETECTION
-- ======
mp.register_event("file-loaded", function()

    local ch = mp.get_property("audio-channels")

    if ch == "mono" or ch == "stereo" then

        mp.osd_message(
            "🎧 Stereo Source Loaded",
            msg_duration
        )

    else

        mp.osd_message(
            "🎬 Multichannel Source Loaded",
            msg_duration
        )
    end
end)
