-- main_cinema.lua
-- Hybrid IMAX-style immersive audio script for mpv
-- Combines adaptive realism (SOFAlizer + IR convolution) with configurable presets and safe rollback
--
-- Keybindings (default):
--   F9  = Headset IMAX (HRTF + clarity EQ)
--   F10 = Speaker Cinema (IR + loudnorm + EQ)
--   F11 = Reset filters (clear chain)
--   F12 = Inspect current filter chain (OSD + log)
-- Optional:
--   Ctrl+F9  = Headset Gaming (HRTF + mild loudnorm + presence EQ)
--   Ctrl+F10 = Speaker Flat (no loudnorm, minimal EQ)

local mp = require 'mp'
local options = require 'mp.options'

------------------------------------------------------------
-- Configuration (defaults; override via script-opts/main.conf)
------------------------------------------------------------
local cfg = {
    sofa_path = "sofalizer/hrtf_M_normal_pinna_resolution_0.5_deg.sofa",
    ir_path   = "sofalizer/theatre_ir_stereo_48k.wav",
    sample_rate = 48000,
    headset_eq_profile = "imax",   -- imax | gaming
    speaker_eq_profile = "cinema", -- cinema | flat
    loudnorm_headset = false,
    loudnorm_speaker = true,
    loudnorm_I = -23,
    loudnorm_TP = -2,
    loudnorm_LRA = 7,
    normalize_fir = true,
    channel_layout_speakers = "5.1",
    channel_layout_headset = "stereo",
    dynamic_enabled = true,
}
options.read_options(cfg, "main")

------------------------------------------------------------
-- Utilities
------------------------------------------------------------
local function notify(msg, secs)
    mp.osd_message(msg, secs or 2)
    mp.msg.info(msg)
end

local function join_filters(filters)
    return "lavfi=[" .. table.concat(filters, ", ") .. "]"
end

local function append(t, s)
    if s and s ~= "" then t[#t+1] = s end
end

local function loudnorm(enabled)
    if not enabled then return nil end
    return string.format("loudnorm=I=%d:TP=%d:LRA=%d", cfg.loudnorm_I, cfg.loudnorm_TP, cfg.loudnorm_LRA)
end

------------------------------------------------------------
-- EQ Profiles
------------------------------------------------------------
local function eq_headset_imax()
    return {
        "equalizer=f=60:t=q:w=1:g=-3",
        "equalizer=f=250:t=q:w=1:g=1",
        "equalizer=f=4000:t=q:w=1:g=2",
        "equalizer=f=8000:t=q:w=1:g=1",
    }
end

local function eq_headset_gaming()
    return {
        "equalizer=f=80:t=q:w=1:g=2",
        "equalizer=f=1000:t=q:w=1:g=1",
        "equalizer=f=4000:t=q:w=1:g=1",
        "equalizer=f=10000:t=q:w=0.8:g=1",
    }
end

local function eq_speaker_cinema()
    return {
        "equalizer=f=60:t=q:w=1:g=2",
        "equalizer=f=250:t=q:w=1:g=1",
        "equalizer=f=4000:t=q:w=1:g=1",
        "equalizer=f=12000:t=q:w=0.7:g=-1",
    }
end

local function eq_speaker_flat()
    return { "equalizer=f=40:t=q:w=1:g=-1" }
end

------------------------------------------------------------
-- Chains
------------------------------------------------------------
-- Headset (IMAX/Gaming)
local function build_headset_chain(profile)
    local filters = {}
    append(filters, string.format("aformat=sample_rates=%d:channel_layout=%s", cfg.sample_rate, cfg.channel_layout_headset))
    append(filters, "aresample=matrix_encoding=dplii")
    append(filters, string.format("sofalizer=sofa=%s:gain=12:normalize=yes:interpolate=yes", cfg.sofa_path))
    append(filters, loudnorm(cfg.loudnorm_headset))
    for _, band in ipairs(profile == "gaming" and eq_headset_gaming() or eq_headset_imax()) do append(filters, band) end
    if cfg.dynamic_enabled then append(filters, "dynaudnorm=f=100:g=14:p=0.95") end
    append(filters, "acompressor=threshold=-36dB:ratio=1.6:attack=0.8:release=50:makeup=1")
    append(filters, "alimiter=level_in=1:level_out=0.985:limit=0.0625")
    return join_filters(filters)
end

-- Speakers (Cinema/Flat)
local function build_speaker_chain(profile)
    local filters = {}
    append(filters, string.format("aformat=sample_rates=%d:channel_layout=%s", cfg.sample_rate, cfg.channel_layout_speakers))
    append(filters, loudnorm(cfg.loudnorm_speaker))
    if profile == "cinema" then
        append(filters, string.format("afir=%s:dry=0.92:wet=0.12", cfg.ir_path))
        for _, band in ipairs(eq_speaker_cinema()) do append(filters, band) end
    else
        for _, band in ipairs(eq_speaker_flat()) do append(filters, band) end
    end
    append(filters, "alimiter=level_in=1:level_out=0.985:limit=0.0625")
    return join_filters(filters)
end

------------------------------------------------------------
-- Preset Functions
------------------------------------------------------------
local function headset_imax()
    mp.commandv("af", "set", build_headset_chain("imax"))
    notify("🎧 Headset IMAX active")
end

local function headset_gaming()
    mp.commandv("af", "set", build_headset_chain("gaming"))
    notify("🎮 Headset Gaming active")
end

local function speaker_cinema()
    mp.commandv("af", "set", build_speaker_chain("cinema"))
    notify("🎬 Cinema chain active")
end

local function speaker_flat()
    mp.commandv("af", "set", build_speaker_chain("flat"))
    notify("🔊 Speaker Flat chain active")
end

local function reset_filters()
    mp.commandv("af", "clr")
    notify("♻️ Filters cleared")
end

local function inspect_filters()
    notify("🔍 Current filters: " .. (mp.get_property("af") or ""), 3)
end

------------------------------------------------------------
-- Script Messages (for input.conf)
------------------------------------------------------------
mp.register_script_message("headset_imax", headset_imax)
mp.register_script_message("headset_gaming", headset_gaming)
mp.register_script_message("speaker_cinema", speaker_cinema)
mp.register_script_message("speaker_flat", speaker_flat)
mp.register_script_message("reset_filters", reset_filters)
mp.register_script_message("inspect_filters", inspect_filters)

------------------------------------------------------------
-- Load confirmation
------------------------------------------------------------
notify("🎬 Cinema script loaded")