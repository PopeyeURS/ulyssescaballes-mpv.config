-- main_cinema.lua
-- Cinema-grade speaker audio chain for mpv
-- Reads parameters from script-opts/main_cinema.conf

local mp = require 'mp'
local options = require 'mp.options'

-- Default values (overridden by main_cinema.conf)
local o = {
    sofa_path = "sofa/hrtf_M_normal_pinna_resolution_0.5_deg.sofa",
    brir_path = "sofa/ClubFritz12.sofa",
    ir_path   = "sofa/theatre_ir.wav",
    sample_rate = 48000,
    channel_layout_speakers = "5.1",
    speaker_eq_profile = "cinema",
    loudnorm_speaker = "yes",   -- use yes/no instead of true/false
    loudnorm_I = -24,
    loudnorm_TP = -2,
    loudnorm_LRA = 8,
    normalize_fir = "yes",      -- corrected boolean syntax
    dynamic_enabled = "yes",    -- corrected boolean syntax
}

options.read_options(o, "main_cinema")

------------------------------------------------------------
-- Functions
------------------------------------------------------------
local function speaker_best()
    local filters = string.format("aformat=sample_rates=%d:channel_layout=%s,", 
        o.sample_rate, o.channel_layout_speakers)

    if o.loudnorm_speaker == "yes" then
        filters = filters .. string.format("loudnorm=I=%d:TP=%f:LRA=%d,", 
            o.loudnorm_I, o.loudnorm_TP, o.loudnorm_LRA)
    end

    filters = filters ..
        string.format("afir=%s:dry=0.92:wet=0.12,", o.ir_path) ..
        "equalizer=f=60:t=q:w=1:g=2," ..
        "equalizer=f=250:t=q:w=1:g=1," ..
        "equalizer=f=4000:t=q:w=1:g=1.5," ..
        "equalizer=f=8000:t=q:w=1:g=1," ..
        "equalizer=f=12000:t=q:w=0.7:g=-0.5," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625"

    mp.commandv("af", "set", "lavfi=[" .. filters .. "]")
    mp.osd_message("🎬 Speaker Best chain active")
end

local function reset_filters()
    mp.commandv("af", "clr")
    mp.osd_message("♻️ Filters cleared")
end

local function inspect_filters()
    mp.osd_message("🔍 Current filters: " .. (mp.get_property("af") or ""), 3)
end

------------------------------------------------------------
-- Script Messages
------------------------------------------------------------
mp.register_script_message("speaker_best", speaker_best)
mp.register_script_message("reset_filters", reset_filters)
mp.register_script_message("inspect_filters", inspect_filters)

mp.osd_message("🎬 Cinema module loaded")
