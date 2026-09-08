local mp = require 'mp'
local msg_duration = 3
local current_mode = "none"

-- ======
-- Version 36.0 - ULTIMATE MASTER AUDIO BUILD - IMMERSIVE IMAX CINEMA EDITION
-- 🔊 ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 20260908 094845LT
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
    "highpass=f=20",
    "bass=g=5.0:f=60:width_type=o:width=1.2",
    "equalizer=f=45:g=1.0:width_type=o:width=1.0",
    "equalizer=f=1000:g=0.7:width_type=o:width=1.0",
    "equalizer=f=4000:g=1.1:width_type=o:width=1.0",
    "equalizer=f=10000:g=0.9:width_type=o:width=1.0",
    "pan=7.1|FL=1.0|FR=1.0|FC=0.65|LFE=0.9|BL=0.75|BR=0.75|SL=0.65|SR=0.65",
    "adelay=10|10|20|5|15|15|15|15",
    "acompressor=threshold=-16dB:ratio=1.8:attack=5:release=200:makeup=1.5",
    "surround=level_in=1:level_out=1",
    "volume=-0.8dB"
}

-- ======
-- 🎼 MUSIC MODE
-- Live Concert Acoustic Hall Envelopment
-- ======
local music_filters = {
    "aresample=resampler=soxr:precision=33:cheby=1",
    "highpass=f=25",
    "bass=g=2.8:f=70:width_type=o:width=1.4",
    "equalizer=f=120:g=-0.4:width_type=o:width=1.0",
    "equalizer=f=2500:g=0.4:width_type=o:width=1.0",
    "equalizer=f=8000:g=0.3:width_type=o:width=1.0",
    "pan=7.1|FL=1.0|FR=1.0|FC=0.6|LFE=0.7|BL=0.7|BR=0.7|SL=0.6|SR=0.6",
    "adelay=15|15|25|10|20|20|20|20",
    "acompressor=threshold=-18dB:ratio=1.4:attack=10:release=250:makeup=1.2",
    "surround",
    "volume=-0.8dB"
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
