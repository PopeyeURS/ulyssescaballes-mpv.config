-- main_headset.lua
-- Best-of-the-best headset audio chain for mpv
-- Reads parameters from script-opts/main_headset.conf

local mp = require 'mp'
local options = require 'mp.options'

-- Default values (will be overridden by main_headset.conf)
local o = {
    sofa_path = "sofa/hrtf_M_normal_pinna_resolution_0.5_deg.sofa",
    brir_path = "sofa/ClubFritz12.sofa",
    sample_rate = 48000,
    channel_layout_headset = "stereo",
    headset_eq_profile = "imax",
    loudnorm_headset = false,
    loudnorm_I = -23,
    loudnorm_TP = -2,
    loudnorm_LRA = 7,
    normalize_fir = true,
    dynamic_enabled = true,
}

options.read_options(o, "main_headset")

------------------------------------------------------------
-- Functions
------------------------------------------------------------
local function headset_best()
    mp.commandv("af", "set",
        string.format("lavfi=[sofalizer=sofa=%s:gain=1.0," ..
        "afir=%s:dry=0.90:wet=0.10," ..
        (o.loudnorm_headset and
            string.format("loudnorm=I=%d:TP=%f:LRA=%d,", o.loudnorm_I, o.loudnorm_TP, o.loudnorm_LRA)
            or "") ..
        "equalizer=f=80:t=q:w=1:g=2," ..
        "equalizer=f=300:t=q:w=1:g=1," ..
        "equalizer=f=5000:t=q:w=1:g=1.5," ..
        "equalizer=f=8000:t=q:w=1:g=1," ..
        "equalizer=f=12000:t=q:w=0.7:g=-0.5," ..
        "alimiter=level_in=1:level_out=0.985:limit=0.0625]",
        o.sofa_path, o.brir_path))
    mp.osd_message("🎧 Headset Best chain active")
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
mp.register_script_message("headset_best", headset_best)
mp.register_script_message("reset_filters", reset_filters)
mp.register_script_message("inspect_filters", inspect_filters)

mp.osd_message("🎧 Headset module loaded")
