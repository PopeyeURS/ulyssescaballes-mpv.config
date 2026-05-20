local mp = require 'mp'
local msg_duration = 3

local current_mode = "none"

-- ======
-- 🔊 Version 22.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260520 171915LT
-- ======
-- Description:
-- Version 22.0 represents the culmination of refinement and tuning — engineered 
-- for IMAX‑grade immersion and uncompromising realism. Compared to Version 21.0,
-- this build delivers smoother dynamics and spatial realism that feels closer
-- to a professional mastering chain.
-- ======

-- ======
-- FILTER APPLIER
-- ======
local function apply_audio_filters(filters, message)
    mp.commandv("af", "clear")

    for _, filter in ipairs(filters) do
        local success = pcall(function()
            mp.commandv("af", "add", filter)
        end)

        if not success then
            mp.msg.error("Failed to apply filter: " .. filter)
            mp.osd_message("⚠️ Filter failed: " .. filter, 2)
        end
    end

    mp.osd_message(message, msg_duration)
end

-- ======
-- 🌌 CINEMA MODE
-- Stereo speakers phantom surround
-- ======
local cinema_filters = {

    -- Headroom
    "volume=-5dB",

    -- High quality resampling
    "aresample=resampler=soxr:precision=33:cheby=1",

    -- Remove low rumble
    "highpass=f=28",

    -- Haas effect for phantom expansion
    "adelay=1|3",

    -- Mild widening
    "extrastereo=m=1.05",

    -- Mid/side enhancement
    "stereotools=mlev=0.97:slev=1.04",

    -- Cinema room ambience
    "aecho=0.65:0.80:12:0.10",

    -- Bass impact
    "equalizer=f=60:g=2.5",
    "equalizer=f=110:g=1.2",

    -- Reduce boxiness
    "equalizer=f=320:g=-1.2",

    -- Slight cinematic depth
    "equalizer=f=900:g=-0.5",

    -- Dialogue clarity
    "equalizer=f=1800:g=0.8",
    "equalizer=f=3200:g=1.3",

    -- Spatial detail
    "equalizer=f=7000:g=0.7",

    -- Air
    "equalizer=f=14000:g=0.5",

    -- Smooth extreme highs
    "lowpass=f=18500",

    -- Gentle glue compression
    "acompressor=threshold=-18dB:ratio=1.18:attack=10:release=100",

    -- Final safety
    "alimiter=limit=0.96:level_out=0.96"
}

-- ======
-- 🎼 MUSIC / CONCERT MODE
-- Live venue spaciousness
-- ======
local music_filters = {

    -- Headroom
    "volume=-4dB",

    -- High quality resampling
    "aresample=resampler=soxr:precision=33:cheby=1",

    -- Remove sub rumble
    "highpass=f=30",

    -- Tiny stage-width Haas delay
    "adelay=1|2",

    -- Mild stereo enhancement
    "extrastereo=m=1.05",

    -- Simulated venue ambience
    "stereotools=mlev=0.96:slev=1.05",
    "aecho=0.70:0.78:18:0.08",

    -- Deep concert bass
    "equalizer=f=45:g=2.8",
    "equalizer=f=60:g=3.0",
    "equalizer=f=95:g=1.8",
    "equalizer=f=140:g=0.8",

    -- Reduce mud
    "equalizer=f=260:g=-1.2",

    -- Vocal presence
    "equalizer=f=1800:g=0.5",

    -- Instrument clarity
    "equalizer=f=3200:g=1.4",
    "equalizer=f=5200:g=0.5",

    -- Cymbal sparkle
    "equalizer=f=9000:g=0.6",

    -- Air
    "equalizer=f=14000:g=0.5",

    -- Smooth extreme highs
    "lowpass=f=18500",

    -- Very gentle compression
    "acompressor=threshold=-22dB:ratio=1.12:attack=8:release=140",

    -- Safety limiter
    "alimiter=limit=0.97:level_out=0.97"
}

-- ======
-- KEYBINDS
-- ======

mp.add_key_binding("F10", "cinema-mode", function()

    if current_mode == "cinema" then
        mp.osd_message("🌌 Cinema Mode already active", 1.5)
        return
    end

    apply_audio_filters(
        cinema_filters,
        "🌌 Cinema Mode • IMAX SenseSurround Activated"
    )

    current_mode = "cinema"
end)

mp.add_key_binding("F11", "music-mode", function()

    if current_mode == "music" then
        mp.osd_message("🎼 Music Mode already active", 1.5)
        return
    end

    apply_audio_filters(
        music_filters,
        "🎼 Music Mode • Live Concert Spatial Audio Enabled"
    )

    current_mode = "music"
end)

mp.add_key_binding("F12", "reset-filters", function()
    mp.commandv("af", "clear")
    current_mode = "none"
    mp.osd_message("🔄 Audio Filters Cleared", msg_duration)
end)

-- ======
-- AUDIO CHANNEL DETECTION
-- ======

mp.register_event("file-loaded", function()

    local ch = mp.get_property("audio-channels")

    if ch == "mono" or ch == "stereo" then
        mp.osd_message(
            "🎧 Stereo source detected",
            msg_duration
        )
    else
        mp.osd_message(
            "🎬 Multichannel surround source detected",
            msg_duration
        )
    end
end)
