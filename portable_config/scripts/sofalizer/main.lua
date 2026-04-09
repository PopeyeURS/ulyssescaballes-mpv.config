local mp = require "mp"
local utils = require "mp.utils"

-- ======
-- Created for MPV by Ulysses RS Caballes. The ULTIMATE - Gold Standard - Version 4.5 (7.1 Speaker Array + Dynamic Spatial + Sub + Concert Air Enhancer)
-- ======

-- ======
-- CONFIG
-- ======
local KEMAR_SOFA = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/KEMAR_HRTF.sofa"
local SADIE_BRIR = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"

-- ======
-- HELPERS
-- ======
local function show(msg,duration)
    mp.osd_message(msg,duration or 3)
end

local function file_exists(path)
    return utils.file_info(path) ~= nil
end

local function apply_filters(filters)
    mp.commandv("af","set",table.concat(filters,","))
end

local function add_filters(target, source)
    for _,f in ipairs(source) do table.insert(target,f) end
end

local function is_stereo()
    local ch = mp.get_property_number("audio-params/channel-count",0)
    return ch == 0 or ch <= 2
end

local function channel_count()
    return mp.get_property_number("audio-params/channel-count",0)
end

-- ======
-- SPATIAL BUILDING BLOCKS
-- ======
local function headroom() return "volume=0.95" end

local function micro_head_motion()
    return {
        "haas=left_delay=0.45:right_delay=0.65:left_gain=0.985:right_gain=0.985",
        "stereotools=delay=0.35:phase=0.93"
    }
end

local function room_reflections()
    return "haas=left_delay=2.0:right_delay=2.2:left_gain=0.96:right_gain=0.96"
end

local function hall_reflections()
    return "haas=left_delay=3.2:right_delay=3.9:left_gain=0.94:right_gain=0.94"
end

local function hrtf(radius,gain)
    local speakers = is_stereo() and "FL+30*FR-30" or "FL+30*FR-30*FC+0*SL+100*SR-100*BL+150*BR-150"
    return "sofalizer=sofa="..string.format("%q", KEMAR_SOFA)..
           ":type=hrtf:interpolate=3:normalize=1:radius="..radius..":gain="..gain..
           ":speakers="..speakers
end

local function crossfeed() return "bs2b=profile=jmeier:fcut=700:feed=50" end
local function compressor() return "acompressor=threshold=-18dB:ratio=1.8:attack=8:release=120" end
local function limiter() return "alimiter=limit=0.95:level_out=0.98" end
local function resampler() return "aresample=resampler=soxr:precision=33:cheby=1" end

local function concert_air()
    return {
        "stereotools=width=1.75:phase=0.98",
        "aecho=0.015:0.018:0.2:0.15",
        "reverb=50:50:0.3:0.25"
    }
end

-- ======
-- MODE BUILDER
-- ======
local function build_mode(filters_table)
    local filters = { headroom(), resampler() }
    add_filters(filters, filters_table)
    apply_filters(filters)
end

-- ======
-- MODES
-- ======
local function set_headset_audio()
    local mode_filters = {}
    add_filters(mode_filters, micro_head_motion())
    table.insert(mode_filters, room_reflections())
    table.insert(mode_filters, hrtf(1.85,1.05))
    table.insert(mode_filters, crossfeed())
    add_filters(mode_filters,{
        "firequalizer=gain_entry='entry(25,2);entry(40,1.8);entry(60,1.5);entry(120,1)'",
        "equalizer=f=2500:t=q:w=0.9:g=1.6",
        "equalizer=f=4500:t=q:w=0.9:g=1.5",
        "equalizer=f=10000:t=q:w=0.8:g=1.2",
        "stereotools=width=1.8:phase=0.97",
        compressor(),
        limiter()
    })
    build_mode(mode_filters)
    show("🎧 Enhanced Headset Mode Activated", 5)
end

local function set_cinema_mode()
    local mode_filters = {}
    if is_stereo() then
        table.insert(mode_filters,"surround=chl_in=stereo:chl_out=7.1")
    end
    add_filters(mode_filters, micro_head_motion())
    table.insert(mode_filters, room_reflections())
    table.insert(mode_filters,"afir=file="..string.format("%q", SADIE_BRIR))
    table.insert(mode_filters, hrtf(2.2,1.07))
    table.insert(mode_filters, crossfeed())
    add_filters(mode_filters,{
        "firequalizer=gain_entry='entry(30,2);entry(60,2);entry(90,1.2)'",
        "equalizer=f=2000:t=q:w=1.0:g=1.1",
        "equalizer=f=3200:t=q:w=1.0:g=1.2",
        "stereotools=width=1.8:phase=0.95"
    })
    add_filters(mode_filters, concert_air())
    table.insert(mode_filters, compressor())
    table.insert(mode_filters, limiter())
    build_mode(mode_filters)
    show("🎬 Enhanced Cinema Mode Activated", 5)
end

local function set_music_mode_()
    local mode_filters = {}
    if is_stereo() then
        table.insert(mode_filters, "surround=chl_in=stereo:chl_out=7.1")
    end
    add_filters(mode_filters, micro_head_motion())
    table.insert(mode_filters, hall_reflections())
    table.insert(mode_filters,"afir=file="..string.format("%q", SADIE_BRIR))
    table.insert(mode_filters, hrtf(1.95,1.05))
    table.insert(mode_filters, crossfeed())
    add_filters(mode_filters,{
        "firequalizer=gain_entry='entry(25,1.8);entry(40,2);entry(80,1.6);entry(120,1)'",
        "equalizer=f=250:t=q:w=0.9:g=1.0",
        "equalizer=f=1800:t=q:w=0.9:g=1.2",
        "equalizer=f=3500:t=q:w=0.8:g=1.5",
        "equalizer=f=7000:t=q:w=0.7:g=1.4",
        "equalizer=f=12000:t=q:w=0.6:g=1.6",
        "stereotools=width=1.8:phase=0.96"
    })
    add_filters(mode_filters, concert_air())
    table.insert(mode_filters,"dynaaudnorm=f=200:g=4:p=0.9")
    table.insert(mode_filters, limiter())
    build_mode(mode_filters)
    show("🎼 Music Mode Plus Activated", 5)
end

-- ======
-- RESET
-- ======
local function clear_filters()
    mp.commandv("af","clr")
    show("🔄 Filters Cleared", 5)
end

-- ======
-- FILE CHECKS
-- ======
local function verify_files()
    if not file_exists(KEMAR_SOFA) then show("❌ Missing KEMAR HRTF file!",5) end
    if not file_exists(SADIE_BRIR) then show("❌ Missing SADIE BRIR file!",5) end
end

verify_files()

-- ======
-- INFO MESSAGE
-- ======
mp.register_event("file-loaded",function()
    verify_files()
    local ch = channel_count()
    mp.osd_message(ch <= 2 and "🎧 Stereo audio detected" or "🎬 Surround audio detected", 5)
end)

-- ======
-- KEYBINDS
-- ======
mp.add_forced_key_binding("F9","headset_mode_key",set_headset_audio)
mp.add_forced_key_binding("F10","cinema_mode_key",set_cinema_mode)
mp.add_forced_key_binding("F11","music_mode_key",set_music_mode_)
mp.add_forced_key_binding("F12","reset_filters_key",clear_filters)
