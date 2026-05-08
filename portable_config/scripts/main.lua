-- ======
-- 🔊 Version 14.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260508 171304LT
-- ======
-- Description:
-- This script transforms any audio playback into a premium, immersive 
-- experience akin to an IMAX theater: ultra-wide spatial sound, 
-- enveloping sub-bass, cinematic presence, and concert-hall realism.
-- Tailored for stereo and multi-channel audio, optimized for headphones 
-- or full surround setups.
-- ======

local msg_duration = 3

-- ====== 
-- AUDIO MODE
-- ======
local function apply_audio_filters(filters, message)
    mp.commandv("af", "clear") -- always clear first
    for _, filter in ipairs(filters) do
        mp.commandv("af", "add", filter)
    end
    mp.osd_message(message, msg_duration)
end

-- ======
-- EQ / FILTERS
-- ======
local headset_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "bs2b=profile=jmeier:fcut=700:feed=45",
    "highpass=f=28",
    "equalizer=f=60:t=q:w=1.00:g=2.00",
    "equalizer=f=120:t=q:w=1.00:g=1.00",
    "equalizer=f=250:t=q:w=1.00:g=-1.20",
    "equalizer=f=3500:t=q:w=0.80:g=1.00",
    "equalizer=f=9000:t=q:w=0.70:g=1.00",
    "equalizer=f=14000:t=q:w=0.60:g=0.80",
    "equalizer=f=16000:t=q:w=0.5:g=0.7",
    "equalizer=f=19000:t=q:w=0.5:g=0.5",
    "acompressor=threshold=-20dB:ratio=1.4:attack=20:release=150",
    "extrastereo=m=1.08",
    "alimiter=limit=0.98:level_out=0.98"
}

local cinema_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=20",
    "extrastereo=m=1.15",
    "equalizer=f=18000:t=q:w=0.5:g=0.8",
    "equalizer=f=19000:t=q:w=0.5:g=0.5",
    "acompressor=threshold=-18dB:ratio=1.5:attack=10:release=150",
    "alimiter=limit=0.98:level_out=0.98"
}

local music_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "extrastereo=m=1.05",
    "equalizer=f=60:t=q:w=1.0:g=3.0",
    "equalizer=f=120:t=q:w=1.0:g=2.0",
    "equalizer=f=3500:t=q:w=0.8:g=1.0",
    "acompressor=threshold=-22dB:ratio=1.3:attack=15:release=120",
    "equalizer=f=16000:t=q:w=0.5:g=0.7",
    "equalizer=f=18000:t=q:w=0.5:g=0.8",
    "equalizer=f=19000:t=q:w=0.5:g=0.5",
    "alimiter=limit=0.97:level_out=0.98"
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
    local ch = mp.get_property_number("audio-channels", 2)
    mp.osd_message(ch <= 2 and "🎧 Stereo audio detected" or "🎬 Surround audio detected", msg_duration)
end)
