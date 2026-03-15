local mp = require "mp"
local utils = require "mp.utils"

-- "Refined/Enhanced/Improved by UlyssesRSCaballes. The ULTIMATE ver.3.1 (for 7.1 Speaker Array + Dynamic Spatial + Subwoofer + Concert Air Enhancer)"

-- ======
-- CONFIG
-- ======

local KEMAR_SOFA = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/KEMAR_HRTF.sofa"
local SADIE_BRIR = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"

-- =======
-- HELPERS
-- =======

local function show(msg,duration)
    mp.osd_message(msg,duration or 3)
end

local function file_exists(path)
    return utils.file_info(path) ~= nil
end

local function apply_filters(filters)
    mp.commandv("af","set",table.concat(filters,","))
end

local function is_stereo()
    local ch = mp.get_property_number("audio-params/channel-count", 2)
    return ch ~= nil and ch <= 2
end

local function channel_count()
    return mp.get_property_number("audio-params/channel-count",2)
end

-- =========================
-- SPATIAL BUILDING BLOCKS
-- =========================

local function headroom()
    return "volume=0.92"
end

-- Micro head movement simulation
local function micro_head_motion()
    return {
        "haas=left_delay=0.45:right_delay=0.65:left_gain=0.985:right_gain=0.985",
        "stereotools=delay=0.35:phase=0.93"
    }
end

local function room_reflections()
    return "haas=left_delay=2.0:right_delay=2.5:left_gain=0.96:right_gain=0.96"
end

local function hall_reflections()
    return "haas=left_delay=3.2:right_delay=3.9:left_gain=0.94:right_gain=0.94"
end

-- =======
-- TRUE 7.1 HRTF
-- =======

local function hrtf(radius,gain)
    local speakers
    if is_stereo() then
        speakers = "FL+30*FR-30"
    else
        speakers = "FL+30*FR-30*FC+0*SL+100*SR-100*BL+150*BR-150"
    end
    return "sofalizer=sofa='"..KEMAR_SOFA..
           "':type=hrtf:interpolate=3:normalize=1"..
           ":radius="..radius..
           ":gain="..gain..
           ":speakers="..speakers
end

-- ==========
-- CROSSFEED
-- ==========
local function crossfeed()
    return "bs2b=profile=jmeier:fcut=700:feed=50"
end

-- ==========
-- DYNAMICS
-- ==========
local function compressor()
    return "acompressor=threshold=-20dB:ratio=1.6:attack=10:release=120"
end

local function limiter()
    return "alimiter=limit=0.92:level_out=0.98"
end

-- ==========
-- RESAMPLER
-- ==========
local function resampler()
    return "aresample=resampler=soxr:precision=33:cheby=1"
end

-- ==========
-- SUBTLE HALL AIR EFFECTS
-- ==========
local function concert_air()
    return {
        "stereotools=width=1.05:phase=0.98",   -- Slight stereo expansion
        "aecho=0.015:0.018:0.2:0.15",         -- Short, subtle room echo
        "reverb=50:50:0.3:0.25"                -- Soft, safe hall reverb
    }
end

-- =====================
-- HEADSET MODE
-- =====================
local function set_headset_audio()
    local filters = { headroom() }
    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end
    table.insert(filters, room_reflections())
    table.insert(filters, hrtf(1.7,1.02))
    table.insert(filters, crossfeed())
    table.insert(filters,"firequalizer=gain_entry='entry(30,2);entry(60,1.5);entry(120,1)'")
    table.insert(filters,"equalizer=f=2500:t=q:w=0.9:g=1.6")
    table.insert(filters,"equalizer=f=4500:t=q:w=0.9:g=1.5")
    table.insert(filters,"equalizer=f=10000:t=q:w=0.8:g=1.2")
    table.insert(filters,"stereotools=width=1.45:phase=0.96")
    table.insert(filters, compressor())
    table.insert(filters, limiter())
    table.insert(filters, resampler())
    mp.commandv("af","clr")
apply_filters(filters)
    show("🎧 Headset Reference Mode Activated")
end

-- =====================
-- CINEMA MODE (7.1 + Air)
-- =====================
local function set_cinema_mode()
    local filters = { headroom() }
    if is_stereo() then
        table.insert(filters,"surround=chl_in=stereo:chl_out=7.1")
    end
    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end
    table.insert(filters, room_reflections())
    table.insert(filters,"afir=file='"..SADIE_BRIR.."'")
    table.insert(filters, hrtf(2.2,1.07))
    table.insert(filters, crossfeed())
    table.insert(filters,"firequalizer=gain_entry='entry(30,2);entry(60,2);entry(90,1)'")
    table.insert(filters,"equalizer=f=2000:t=q:w=1.0:g=1.1")
    table.insert(filters,"equalizer=f=3200:t=q:w=1.0:g=1.2")
    table.insert(filters,"stereotools=width=1.65:phase=0.95")
    for _,f in ipairs(concert_air()) do table.insert(filters,f) end
    table.insert(filters, compressor())
    table.insert(filters, limiter())
    table.insert(filters, resampler())
    mp.commandv("af","clr")
apply_filters(filters)
    show("🎬 Cinema Mode (7.1 + Concert Air) Activated")
end

-- =====================
-- MUSIC HALL MODE (Enhanced Concert Spatial)
-- =====================
local function set_music_hall_mode()
    local filters = { headroom() }
    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end
    table.insert(filters, hall_reflections())
    table.insert(filters,"afir=file='"..SADIE_BRIR.."'")
    table.insert(filters, hrtf(1.9,1.05))
    table.insert(filters, crossfeed())
    table.insert(filters,"firequalizer=gain_entry='entry(25,1);entry(40,2);entry(80,1.6);entry(120,1)'")
    table.insert(filters,"equalizer=f=250:t=q:w=0.9:g=1.0")
    table.insert(filters,"equalizer=f=1800:t=q:w=0.9:g=1.2")
    table.insert(filters,"equalizer=f=3500:t=q:w=0.8:g=1.5")
    table.insert(filters,"equalizer=f=7000:t=q:w=0.7:g=1.4")
    table.insert(filters,"equalizer=f=12000:t=q:w=0.6:g=1.6")
    table.insert(filters,"stereotools=width=1.55:phase=0.96")
    for _,f in ipairs(concert_air()) do table.insert(filters,f) end
    table.insert(filters,"dynaaudnorm=f=200:g=4:p=0.9")
    table.insert(filters, limiter())
    table.insert(filters, resampler())
    mp.commandv("af","clr")
apply_filters(filters)
    show("🎼 Music Hall Mode (Concert Spatial + Air) Activated")
end

-- =====
-- RESET
-- =====
local function clear_filters()
    mp.commandv("af","clr")
    show("🔄 Filters Cleared")
end

-- ===========
-- FILE CHECKS
-- ===========
if not file_exists(KEMAR_SOFA) then
    show("❌ Missing KEMAR HRTF file!",5)
end
if not file_exists(SADIE_BRIR) then
    show("❌ Missing SADIE BRIR file!",5)
end

-- ============
-- INFO MESSAGE
-- ============
mp.register_event("file-loaded",function()
    local ch = channel_count()
    if ch <= 2 then
        mp.osd_message("🎧 Stereo audio detected")
    else
        mp.osd_message("🎬 Surround audio detected")
    end
end)

-- ========
-- KEYBINDS
-- ========
mp.add_forced_key_binding("F9","headset_audio_key",set_headset_audio)
mp.add_forced_key_binding("F10","cinema_mode_key",set_cinema_mode)
mp.add_forced_key_binding("F11","music_hall_key",set_music_hall_mode)
mp.add_forced_key_binding("F12","reset_filters_key",clear_filters)
