-- ======
-- 🔊 Version 19.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260510 231304LT
-- ======
-- Description:
-- This script transforms any audio playback into a premium, immersive 
-- experience akin to an IMAX theater: ultra-wide spatial sound, 
-- enveloping sub-bass, cinematic presence, and concert-hall realism.
-- Tailored for stereo and multi-channel audio, optimized for headphones 
-- or full surround setups.
-- ======

local mp = require 'mp'
local msg_duration = 3

-- ====== 
-- AUDIO MODE
-- ======
local function apply_audio_filters(filters, message)
    mp.commandv("af", "clear")
    for _, filter in ipairs(filters) do
        local success = pcall(function()
            mp.commandv("af", "add", filter)
        end)
        if not success then
            mp.msg.error("Failed to apply filter: " .. filter)
        end
    end
    mp.osd_message(message, msg_duration)
end

-- ======
-- EQ / FILTERS
-- ======

-- 🎧 Headset Mode
local headset_filters = {
    "volume=-3dB",
    "aresample=resampler=soxr:precision=33:cheby=1",
    "bs2b=profile=jmeier:fcut=700:feed=45",
    "highpass=f=32",
    "extrastereo=m=1.20",
    "equalizer=f=60:g=2.0",
    "equalizer=f=120:g=1.2",
    "equalizer=f=250:g=-1.0",
    "equalizer=f=600:g=0.5",
    "equalizer=f=1500:g=0.7",
    "equalizer=f=2600:g=0.5",
    "equalizer=f=3500:g=1.0",
    "equalizer=f=9000:g=0.8",
    "equalizer=f=16000:g=0.7",
    "equalizer=f=19000:g=0.5",
    "acompressor=threshold=-20dB:ratio=1.3:attack=15:release=120",
    "alimiter=limit=0.975:level_out=0.975"
}

-- 🌌 Cinema Mode
local cinema_filters = {
    "volume=-4dB",
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=28",
    "extrastereo=m=1.08",
    "adelay=4|6:all=1",
    "equalizer=f=600:g=0.6",
    "equalizer=f=1500:g=0.8",
    "equalizer=f=2600:g=0.5",
    "equalizer=f=60:g=3.0",
    "equalizer=f=120:g=1.2",
    "equalizer=f=200:g=-0.6",
    "equalizer=f=3000:g=0.6",
    "equalizer=f=3500:g=0.4",
    "equalizer=f=9000:g=-1.0",
    "equalizer=f=18000:g=0.4",
    "equalizer=f=19500:g=0.2",
    "acompressor=threshold=-18dB:ratio=1.3:attack=12:release=90",
    "alimiter=limit=0.975:level_out=0.975"
}

-- 🎼 Concert/Music Mode
local music_filters = {
    "volume=-4dB",
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=30",
    "extrastereo=m=1.20",
    "adelay=2|3:all=1",
    "equalizer=f=600:g=0.5",
    "equalizer=f=1500:g=0.7",
    "equalizer=f=2600:g=0.5",
    "equalizer=f=60:g=3.0",
    "equalizer=f=250:g=-0.8",
    "equalizer=f=3000:g=0.4",
    "equalizer=f=3500:g=0.2",
    "equalizer=f=9000:g=-0.4",
    "equalizer=f=16000:g=0.2",
    "equalizer=f=18000:g=0.3",
    "equalizer=f=19500:g=0.2",
    "acompressor=threshold=-22dB:ratio=1.25:attack=8:release=100",
    "alimiter=limit=0.975:level_out=0.975"
}

-- ======
-- KEYBINDS
-- ======
mp.add_key_binding("F9", "headset-mode", function()
    apply_audio_filters(headset_filters, "🎧 Headset Mode Activated")
end)
mp.add_key_binding("F10", "cinema-mode", function()
    apply_audio_filters(cinema_filters, "🌌 Cinema Mode: IMAX SenseSurround Activated")
end)
mp.add_key_binding("F11", "music-mode", function()
    apply_audio_filters(music_filters, "🎼 Live Concert Music Mode Activated")
end)
mp.add_key_binding("F12", "reset-filters", function()
    mp.commandv("af", "clear")
    mp.osd_message("🔄 Filters Cleared", msg_duration)
end)

-- ======
-- AUDIO CHANNEL
-- ======
mp.register_event("file-loaded", function()
   local ch = mp.get_property("audio-channels")

    if ch == "mono" or ch == "stereo" then
        mp.osd_message("🎧 Stereo audio detected", msg_duration)
    else
        mp.osd_message("🎬 Surround audio detected", msg_duration)
    end
end)
