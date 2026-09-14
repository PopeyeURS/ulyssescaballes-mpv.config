local mp = require 'mp'
local msg_duration = 3
local current_mode = "none"

-- ======
-- Version 44.0 - ULTIMATE PREMIUM PLATINUM REFERENCE BUILD - 🔊 ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 20260914 113535LT
-- ======

-- ======
-- SAFE FILTER APPLIER
-- ======
local function apply_audio_filters(filters, message)
    mp.commandv("af", "clr", "")

    local failed = {}
    for _, filter in ipairs(filters) do
        local ok, err = pcall(function()
            mp.commandv("af", "add", filter)
        end)
        if not ok then
            mp.msg.error("Failed filter: " .. filter .. " | " .. tostring(err))
            table.insert(failed, filter)
        end
    end

    current_mode = message
    if #failed > 0 then
        mp.osd_message(message .. " (" .. #failed .. " filter(s) failed, see console)", msg_duration + 2)
    else
        mp.osd_message(message, msg_duration)
    end
end

-- ======
-- 🎧 PURE MODE - filter-bypass, reference playback
-- ======
local pure_filters = {}

-- ======
-- 🌌 CINEMA MODE
-- ======
local cinema_filters = {
    "aresample=resampler=soxr:precision=28:cheby=1",
    "highpass=f=20",
    "bass=g=5.0:f=75:width_type=o:width=1.15",
    "equalizer=f=90:g=1.2:width_type=o:width=1.0",
    "equalizer=f=120:g=0.8:width_type=o:width=1.0",
    "equalizer=f=2800:g=0.8:width_type=o:width=0.9",
    "equalizer=f=4500:g=0.25:width_type=o:width=1.0",
    "equalizer=f=8500:g=0.0:width_type=o:width=1.0",
    "acompressor=threshold=-19dB:ratio=1.7:attack=6:release=180:makeup=1.8",
    "volume=-1.0dB",
    "adelay=10|10|18|7|13|13|13|13",
    "crossfeed=strength=0.15:range=0.4",
    "stereotools=base=0.18:slev=1.12:phase=25",
    "crystalizer=i=0.12"

}

-- ======
-- 🎼 MUSIC MODE
-- Live Concert Acoustic Hall Envelopment
-- ======
local music_filters = {
    "aresample=resampler=soxr:precision=28:cheby=1",
    "highpass=f=22",
    "bass=g=5.0:f=75:width_type=o:width=1.15",
    "equalizer=f=115:g=1.5:width_type=o:width=1.0",
    "equalizer=f=240:g=1.3:width_type=o:width=1.1",
    "equalizer=f=3500:g=2.2:width_type=o:width=0.8",
    "equalizer=f=6000:g=1.5:width_type=o:width=1.0",
    "equalizer=f=10000:g=1.4:width_type=o:width=1.0",
    "equalizer=f=12000:g=0.10:width_type=o:width=1.0",
    "acompressor=threshold=-22dB:ratio=1.25:attack=10:release=280:makeup=1.8",
    "volume=-1.2dB",
    "adelay=7|7|14|5|10|10|10|10",
    "crossfeed=strength=0.15:range=0.4",
    "stereotools=base=0.25:slev=1.18:mlev=0.98:phase=15",
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
    local count = mp.get_property_number("audio-params/channel-count")
    local layout = mp.get_property("audio-params/channels") or "unknown"

    if count == nil then
        mp.osd_message("🔈 Audio layout: " .. layout, msg_duration)
    elseif count <= 2 then
        mp.osd_message("🎧 Stereo Source Loaded (" .. layout .. ")", msg_duration)
    else
        mp.osd_message("🎬 Multichannel Source Loaded (" .. layout .. ")", msg_duration)
    end
end)
