local mp = require "mp"
local utils = require "mp.utils"

-- "Delicately Fine Tuned by UlyssesRSCaballes. The ULTIMATE ver.2.0."

-- CONFIG

local KEMAR_SOFA = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/KEMAR_HRTF.sofa"
local SADIE_BRIR = "C:/Users/ulyss/AppData/Roaming/mpv/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"

-- HELPERS

local function show(msg, duration)
    mp.osd_message(msg, duration or 3)
end

local function file_exists(path)
    return utils.file_info(path) ~= nil
end

local function apply_filters(filters)
    mp.commandv("af", "set", table.concat(filters, ","))
end

local function is_stereo()
    local ch = mp.get_property_number("audio-params/channel-count",2)
    return ch <= 2
end

-- CORE FILTER BLOCKS

local function headroom()
    return "volume=0.90"
end

local function crossfeed()
    return "bs2b=profile=jmeier"
end

local function micro_head_motion()
    return {
        "haas=left_delay=1.8:right_delay=2.1:left_gain=0.97:right_gain=0.97",
        "stereotools=delay=0.15:phase=0.85"
    }
end

local function room_reflections()
    return "haas=left_delay=2.2:right_delay=2.7:left_gain=0.96:right_gain=0.96"
end

local function hall_reflections()
    return "haas=left_delay=3.5:right_delay=4.1:left_gain=0.95:right_gain=0.95"
end

local function hrtf(radius,gain)
    return "sofalizer=sofa='"..KEMAR_SOFA..
    "':type=hrtf:interpolate=3:normalize=1"..
    ":radius="..radius..
    ":gain="..gain..
    ":speakers=FL+30*FR-30*FC+0*LFE+0*SL+110*SR-110"
end

local function binaural_subwoofer()
    return {
        "firequalizer=gain_entry='entry(20,4);entry(30,4);entry(40,3);entry(60,2);entry(90,1)'",
        "acompressor=threshold=-24dB:ratio=1.8:attack=8:release=120",
        "extrastereo=m=1.05"
    }
end

local function impact_enhancer()
    return {
        "acompressor=threshold=-26dB:ratio=2.2:attack=5:release=80",
        "firequalizer=gain_entry='entry(35,2);entry(50,2);entry(70,1.2)'"
    }
end

local function dialogue_enhancer()
    return {
        "equalizer=f=1700:t=q:w=1.2:g=1.4",
        "equalizer=f=3000:t=q:w=1.1:g=2.0"
    }
end

local function surround_width()
    local ch = mp.get_property_number("audio-params/channel-count",2)

    if ch >= 6 then
        return "stereotools=width=1.65:mlev=1.18:slev=1.18:phase=0.8"
    else
        return "stereotools=width=1.45:mlev=1.15:slev=1.15:phase=0.9"
    end
end

local function limiter(limit)
    return "alimiter=limit="..limit..":level_out=0.98"
end

local function resampler()
    return "aresample=resampler=soxr:precision=33:cheby=1:sample_rate=96000:dither_method=shibata"
end

-- HEADSET MODE

local function set_headset_audio()

    local filters = {
        headroom(),
        crossfeed()
    }

    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end

    table.insert(filters, room_reflections())
    table.insert(filters, hrtf(1.7,1.02))

    table.insert(filters,"firequalizer=gain_entry='entry(30,3);entry(50,2);entry(80,1)'")

    table.insert(filters,"equalizer=f=2500:t=q:w=1:g=2.2")
    table.insert(filters,"equalizer=f=4500:t=q:w=1:g=2.0")
    table.insert(filters,"equalizer=f=10000:t=q:w=0.8:g=1.8")

    table.insert(filters,surround_width())

    table.insert(filters,"acompressor=threshold=-20dB:ratio=1.6:attack=12:release=120")

    table.insert(filters,limiter(0.09))
    table.insert(filters,resampler())

    apply_filters(filters)

    show("🎧 Headset Reference Mode Activated")
end

-- CINEMA MODE

local function set_cinema_mode()

    local filters = {
        headroom()
    }

    if is_stereo() then
        table.insert(filters,"surround=chl_in=stereo:chl_out=5.1")
    end

    table.insert(filters,crossfeed())

    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end

    table.insert(filters,room_reflections())

    table.insert(filters,hrtf(2.1,1.08))

    table.insert(filters,"afir=file='"..SADIE_BRIR.."'")

    for _,f in ipairs(binaural_subwoofer()) do table.insert(filters,f) end
    for _,f in ipairs(impact_enhancer()) do table.insert(filters,f) end
    for _,f in ipairs(dialogue_enhancer()) do table.insert(filters,f) end

    table.insert(filters,surround_width())

    table.insert(filters,"acompressor=threshold=-18dB:ratio=1.4:attack=18:release=180")

    table.insert(filters,limiter(0.07))
    table.insert(filters,resampler())

    apply_filters(filters)

    show("🎬 Ultimate Cinema Mode Activated")
end

-- MUSIC MODE

local function set_music_hall_mode()

    local filters = {
        headroom(),
        crossfeed()
    }

    for _,f in ipairs(micro_head_motion()) do table.insert(filters,f) end

    table.insert(filters,hall_reflections())

    table.insert(filters,hrtf(1.8,1.05))

    table.insert(filters,"afir=file='"..SADIE_BRIR.."'")

    table.insert(filters,"firequalizer=gain_entry='entry(35,2);entry(60,1.8);entry(120,1)'")

    table.insert(filters,"equalizer=f=250:t=q:w=1:g=1.2")
    table.insert(filters,"equalizer=f=500:t=q:w=1:g=1.0")
    table.insert(filters,"equalizer=f=1800:t=q:w=0.9:g=1.4")
    table.insert(filters,"equalizer=f=3200:t=q:w=0.8:g=2.0")
    table.insert(filters,"equalizer=f=7000:t=q:w=0.8:g=1.8")
    table.insert(filters,"equalizer=f=12000:t=q:w=0.7:g=2.2")

    table.insert(filters,surround_width())

    table.insert(filters,"dynaaudnorm=f=250:g=6:p=0.9")

    table.insert(filters,limiter(0.08))
    table.insert(filters,resampler())

    apply_filters(filters)

    show("🎼 Music Hall Mode Activated")
end

-- RESET

local function clear_filters()
    mp.commandv("af","clr")
    show("🔄 Filters Cleared")
end

-- =========================
-- FILE CHECK
-- =========================

if not file_exists(KEMAR_SOFA) then
    show("❌ Missing KEMAR HRTF file!",5)
end

-- OPTIONAL INFO MESSAGE

mp.register_event("file-loaded", function()

    local ch = mp.get_property_number("audio-params/channel-count",2)

    if ch <= 2 then
        mp.osd_message("🎧 Stereo audio detected")
    else
        mp.osd_message("🎬 Surround audio detected")
    end

end)

-- KEYBINDS

mp.add_forced_key_binding("F9","headset_audio_key",set_headset_audio)
mp.add_forced_key_binding("F10","cinema_mode_key",set_cinema_mode)
mp.add_forced_key_binding("F11","music_hall_key",set_music_hall_mode)
mp.add_forced_key_binding("F12","reset_filters_key",clear_filters)
