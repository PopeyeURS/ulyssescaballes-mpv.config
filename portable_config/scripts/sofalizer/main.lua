local mp = require "mp"
local utils = require "mp.utils"

-- ======
-- 🔊 Version 13.0 – PREMIUM PLATINUM REFERENCE BUILD - ⚠️DO NOT MODIFY⚠️ 🔊
-- Created for MPV by Ulysses RS Caballes
-- 7.1 Speaker Array + Dynamic Spatial Imaging
-- Philharmonic Concert Mode + Hyper-Cinema Mode
-- 20260505 162218LT
-- ======
-- Description:
-- This script transforms any audio playback into a premium, immersive 
-- experience akin to an IMAX theater: ultra-wide spatial sound, 
-- enveloping sub-bass, cinematic presence, and concert-hall realism.
-- Tailored for stereo and multi-channel audio, optimized for headphones 
-- or full surround setups.
-- ======

-- ======
-- CONFIG
-- ======
local BASE = "C:/Users/user_name/AppData/Roaming/mpv/portable_config/scripts/sofalizer/"

local KEMAR_SOFA   = BASE .. "KEMAR_HRTF_sofa.sofa"
local SADIE_BRIR   = BASE .. "SADIE_KEMAR_DFC_256_order_fir_48000.sofa"
local FOAIR_HEADSET= BASE .. "C2m.wav"
local FOAIR_CINEMA = BASE .. "C6m.wav"
local FOAIR_CONCERT= BASE .. "LW8m.wav"
local FOAIR_AIRTAIL= BASE .. "terrys_typing_b_format.wav"

-- ======
-- HELPERS
-- ======
local function show(msg, duration) mp.osd_message(msg, duration or 3) end
local function file_exists(path) return utils.file_info(path) ~= nil end
local function apply_filters(filters) mp.commandv("af", "set", table.concat(filters, ",")) end
local function add_filters(target, source) for _, f in ipairs(source) do table.insert(target, f) end end
local function channel_count() return mp.get_property_number("audio-params/channel-count", 0) end
local function is_stereo() return channel_count() <= 2 end

-- ======
-- BUILDING BLOCKS
-- ======
local function resampler()
    return "aresample=resampler=soxr:precision=33:cheby=1"
end

local function hrtf(radius, gain)
    radius = tonumber(radius) or 1.0
    gain   = tonumber(gain) or 1.0

    if not file_exists(KEMAR_SOFA) then
        error("SOFA file not found: " .. tostring(KEMAR_SOFA))
    end

    local speakers
    if is_stereo() then
        speakers = "speakers=FL 30 FR -30"
    else
        speakers = "speakers=FL 30 FR -30 FC 0 SL 120 SR -120 BL 170 BR -170"
    end

    local filter = table.concat({
        "sofalizer=sofa=" .. string.format("%q", KEMAR_SOFA),
        "type=hrtf",
        "interpolate=3",
        "normalize=1",
        "radius=" .. radius,
        "gain=" .. gain,
        speakers
    }, ":")

    return filter
end

local function crossfeed() return "bs2b=profile=jmeier:fcut=700:feed=50" end
local function punchy_compression() return "acompressor=threshold=-18dB:ratio=2.2:attack=8:release=60:makeup=1.5" end

-- Sub-bass (safe but powerful)
local function sub_bass()
    return {
        "highpass=f=30",
        "equalizer=f=65:t=q:w=0.9:g=3.0",
        "equalizer=f=100:t=q:w=0.8:g=1.5",
        "equalizer=f=200:t=q:w=0.7:g=-1.5"
    }
end

-- EQ presets
local function headset_eq()
    return {
        "equalizer=f=2500:t=q:w=0.9:g=1.6",
        "equalizer=f=4500:t=q:w=0.9:g=1.5",
        "equalizer=f=10000:t=q:w=0.8:g=1.2"
    }
end

local function transient_eq()
    return {
        "equalizer=f=70:t=q:w=1.0:g=1.5",
        "equalizer=f=3000:t=q:w=0.7:g=2.0",
        "equalizer=f=3500:t=q:w=1.2:g=-0.8",
        "equalizer=f=4500:t=q:w=0.6:g=1.5",
        "equalizer=f=12000:t=q:w=0.7:g=1.3"
    }
end

local function orchestra_eq()
    return {
        "equalizer=f=60:t=q:w=1.0:g=1.8",
        "equalizer=f=180:t=q:w=1.0:g=0.8",
        "equalizer=f=250:t=q:w=0.9:g=1.0",
        "equalizer=f=3500:t=q:w=0.8:g=1.5",
        "equalizer=f=7000:t=q:w=0.7:g=1.4",
        "equalizer=f=12000:t=q:w=0.6:g=1.6"
    }
end

-- ======
-- AUDIO REALISM BLOCK
-- ======
local function add_realism_filters(mode_filters)
    table.insert(mode_filters, "alimiter=limit=0.95:level_out=0.98")
end

-- ======
-- AIR TAIL BLOCK
-- ======
local function add_air_tail(mode_filters)
    table.insert(mode_filters, "afir=file=" .. string.format("%q", FOAIR_AIRTAIL) .. ":gain=-25dB")
    table.insert(mode_filters, "highpass=f=200")
    table.insert(mode_filters, "equalizer=f=6000:t=q:w=0.7:g=1.2")
    table.insert(mode_filters, "equalizer=f=12000:t=q:w=0.6:g=1.5")
end

-- ======
-- MODE BUILDER
-- ======
local function build_mode(filters_table)
    local filters = { resampler() }
    add_filters(filters, filters_table)
    apply_filters(filters)
end

-- ======
-- CINEMATIC MODES
-- ======
local function set_headset_mode()
    local mode_filters = {}
    add_filters(mode_filters, {
        "adelay=45|65",
        "stereotools=width=1.25:phase=0.97"
    })
    table.insert(mode_filters, crossfeed())
    add_filters(mode_filters, headset_eq())
    add_filters(mode_filters, transient_eq())
    add_filters(mode_filters, sub_bass())
    table.insert(mode_filters, hrtf(2.0, 1.05))
    table.insert(mode_filters, "afir=file=" .. string.format("%q", FOAIR_HEADSET))
    table.insert(mode_filters, "aecho=0.6:0.5:120:0.08")
    table.insert(mode_filters, punchy_compression())
    add_realism_filters(mode_filters)
    build_mode(mode_filters)
    show("🎧 Headset Mode Activated", 5)
end

local function set_cinema_mode()
    local mode_filters = {}
    if is_stereo() then
        table.insert(mode_filters, "surround=chl_in=stereo:chl_out=7.1")
    end
    table.insert(mode_filters, "afir=file="..string.format("%q", SADIE_BRIR))
    table.insert(mode_filters, "stereotools=width=1.30:phase=0.98")
    table.insert(mode_filters, "pan=7.1|c0=c0|c1=c1|c2=1.3*c2|c3=c3|c4=c4|c5=c5|c6=c6|c7=c7")
    add_filters(mode_filters, {
        "highpass=f=28",
        "equalizer=f=60:t=q:w=1.0:g=2.5",
        "equalizer=f=120:t=q:w=1.0:g=1.2",
        "equalizer=f=250:t=q:w=1.0:g=-1.5",
        "equalizer=f=3000:t=q:w=0.8:g=1.8",
        "equalizer=f=8000:t=q:w=0.7:g=1.5",
        "equalizer=f=14000:t=q:w=0.6:g=1.2"
    })

    table.insert(mode_filters, hrtf(3.8, 1.08))
    table.insert(mode_filters, "afir=file=" .. string.format("%q", FOAIR_CINEMA))
    table.insert(mode_filters,
        "aecho=0.5:0.4:40|70|110:0.08|0.06|0.05"
    )
    table.insert(mode_filters,
        "acompressor=threshold=-20dB:ratio=1.6:attack=15:release=120"
    )
    table.insert(mode_filters, "extrastereo=m=1.05")
    add_realism_filters(mode_filters)
    build_mode(mode_filters)
    show("🌌 Cinema Mode: IMAX SenseSurround Activated", 5)
end

local function set_music_mode()
    local mode_filters = {}
    if is_stereo() then
        table.insert(mode_filters, "surround=chl_in=stereo:chl_out=7.1:matrix_encoding=none")
    end
    table.insert(mode_filters, "afir=file="..string.format("%q", SADIE_BRIR))
    table.insert(mode_filters, "stereotools=width=1.35:phase=0.98")
    table.insert(mode_filters, crossfeed())
    add_filters(mode_filters, orchestra_eq())
    add_filters(mode_filters, transient_eq())
    add_filters(mode_filters, sub_bass())
    table.insert(mode_filters, hrtf(3.0, 1.05))
    table.insert(mode_filters, "afir=file=" .. string.format("%q", FOAIR_CONCERT))
    table.insert(mode_filters, "aecho=0.7:0.6:250|600:0.12|0.10")
    table.insert(mode_filters, punchy_compression())
    add_air_tail(mode_filters)
    add_realism_filters(mode_filters)
    build_mode(mode_filters)
    show("🎼 Live Concert Music Mode Activated", 5)
end

-- ======
-- RESET
-- ======
local function clear_filters(show_osd)
    mp.commandv("af", "clr")
    if show_osd then
        show("🔄 Filters Cleared", 5)
    end
end

-- ======
-- FILE CHECKS
-- ======
local function verify_files()
    if not file_exists(KEMAR_SOFA) then show("❌ Missing KEMAR HRTF file!", 5) end
    if not file_exists(SADIE_BRIR) then show("❌ Missing SADIE BRIR file!", 5) end
    if not file_exists(FOAIR_HEADSET) then show("❌ Missing FOAIR_HEADSET file!", 5) end
    if not file_exists(FOAIR_CINEMA) then show("❌ Missing FOAIR_CINEMA file!", 5) end
    if not file_exists(FOAIR_CONCERT) then show("❌ Missing FOAIR_CONCERT file!", 5) end
    if not file_exists(FOAIR_AIRTAIL) then show("❌ Missing FOAIR_AIRTAIL file!", 5) end
end
verify_files()

-- ======
-- INFO MESSAGE
-- ======
mp.register_event("file-loaded", function()
    verify_files()
    local ch = channel_count()
    mp.osd_message(ch <= 2 and "🎧 Stereo audio detected" or "🎬 Surround audio detected", 5)
end)

-- ======
-- KEYBINDS
-- ======
mp.add_forced_key_binding("F9", "headset_mode_key", set_headset_mode)
mp.add_forced_key_binding("F10", "cinema_mode_key", set_cinema_mode)
mp.add_forced_key_binding("F11", "music_mode_key", set_music_mode)
mp.add_forced_key_binding("F12", "reset_filters_key", function()
    clear_filters(true)   -- show OSD message
end)
