-- ======
-- 🔊 Version 15.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260509 163415LT
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
    "aresample=resampler=soxr:precision=33:quality=high:cheby=1",
    "bs2b=profile=jmeier:fcut=700:feed=45",
    "highpass=f=32",
    "extrastereo=m=1.20",
    "equalizer=f=60:t=q:w=1.0:g=2.5",
    "equalizer=f=120:t=q:w=1.0:g=1.5",
    "equalizer=f=250:t=q:w=1.0:g=-1.0",
    "equalizer=f=400:t=q:w=0.9:g=-0.8",
    "equalizer=f=3500:t=q:w=0.8:g=1.1",
    "equalizer=f=9000:t=q:w=0.7:g=1.1",
    "equalizer=f=16000:t=q:w=0.5:g=0.9",
    "equalizer=f=19000:t=q:w=0.5:g=0.6",
    "acompressor=threshold=-20dB:ratio=1.35:attack=15:release=140",
    "alimiter=limit=0.985:level_out=0.985"
}

local cinema_filters = {
    "aresample=resampler=soxr:precision=33:quality=high:cheby=1",
    "highpass=f=28",
    "extrastereo=m=1.22",
    "equalizer=f=60:t=q:w=1.0:g=2.2",
    "equalizer=f=120:t=q:w=1.0:g=1.4",
    "equalizer=f=200:t=q:w=0.9:g=-0.6",
    "equalizer=f=3500:t=q:w=0.8:g=1.0",
    "equalizer=f=18000:t=q:w=0.5:g=0.9",
    "equalizer=f=19500:t=q:w=0.5:g=0.6",
    "acompressor=threshold=-18dB:ratio=1.4:attack=12:release=160",
    "alimiter=limit=0.985:level_out=0.985"
}

local music_filters = {
    "aresample=resampler=soxr:precision=33:quality=high:cheby=1",
    "highpass=f=30",
    "extrastereo=m=1.18",
    "equalizer=f=60:t=q:w=1.0:g=3.2",
    "equalizer=f=120:t=q:w=1.0:g=2.2",
    "equalizer=f=250:t=q:w=1.0:g=-0.8",
    "equalizer=f=3500:t=q:w=0.8:g=1.2",
    "equalizer=f=16000:t=q:w=0.5:g=0.9",
    "equalizer=f=18000:t=q:w=0.5:g=0.9",
    "equalizer=f=19500:t=q:w=0.5:g=0.6",
    "acompressor=threshold=-22dB:ratio=1.25:attack=12:release=130",
    "alimiter=limit=0.985:level_out=0.985"
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
