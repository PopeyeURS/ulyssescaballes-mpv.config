-- main_cinema.lua
-- Hybrid IMAX-style immersive audio script for mpv (Speakers)
-- Combines IR convolution, loudnorm, EQ profiles, and rollback safety
--
-- Keybindings (default; set in input.conf):
--   F10      = Speaker Cinema (IR + loudnorm + EQ)
--   F12      = Speaker Cinema+ (enhanced highs/punch)
--   Ctrl+F10 = Speaker Flat (minimal EQ)
--   F11      = Reset filters (clear chain)
--   Shift+F11 = Inspect current filter chain (OSD + log)

local mp = require 'mp'
local options = require 'mp.options'

------------------------------------------------------------
-- Configuration (defaults; override via script-opts/main.conf)
------------------------------------------------------------
local cfg = {
    ir_path   = "sofalizer/theatre_ir_stereo_48k.wav",
    sample_rate = 48000,
    speaker_eq_profile = "cinema", -- cinema | flat | cinema_plus
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
local function eq_speaker_cinema()
    return {
        "equalizer=f=60:t=q:w=1:g=2",       -- bass body
        "equalizer=f=250:t=q:w=1:g=1",      -- warmth
        "equalizer=f=4000:t=q:w=1:g=1",     -- presence
        "equalizer=f=12000:t=q:w=0.7:g=-1", -- soften extreme highs
    }
end

local function eq_speaker_flat()
    return { "equalizer=f=40:t=q:w=1:g=-1" } -- neutral playback
end

local function eq_speaker_cinema_plus()
    return {
        "equalizer=f=60:t=q:w=1:g=2",        -- bass body
        "equalizer=f=250:t=q:w=1:g=1",       -- warmth
        "equalizer=f=4000:t=q:w=1:g=1.5",    -- stronger presence
        "equalizer=f=8000:t=q:w=1:g=1",      -- sparkle
        "equalizer=f=12000:t=q:w=0.7:g=-0.5",-- gentle high cut
    }
end

------------------------------------------------------------
-- Chains
------------------------------------------------------------
local function build_speaker_chain(profile)
    local filters = {}
    append(filters, string.format("aformat=sample_rates=%d:channel_layout=%s", cfg.sample_rate, cfg.channel_layout_speakers))
    append(filters, loudnorm(cfg.loudnorm_speaker))
    if profile == "cinema" then
        append(filters, string.format("afir=%s:dry=0.92:wet=0.12", cfg.ir_path))
        for _, band in ipairs(eq_speaker_cinema()) do append(filters, band) end
    elseif profile == "cinema_plus" then
        append(filters, string.format("afir=%s:dry=0.92:wet=0.12", cfg.ir_path))
        for _, band in ipairs(eq_speaker_cinema_plus()) do append(filters, band) end
    else
        for _, band in ipairs(eq_speaker_flat()) do append(filters, band) end
    end
    append(filters, "alimiter=level_in=1:level_out=0.985:limit=0.0625")
    return join_filters(filters)
end

------------------------------------------------------------
-- Preset Functions
------------------------------------------------------------
local function speaker_cinema()
    mp.commandv("af", "set", build_speaker_chain("cinema"))
    notify("🎬 Speaker Cinema active")
end

local function speaker_cinema_plus()
    mp.commandv("af", "set", build_speaker_chain("cinema_plus"))
    notify("🎬 Speaker Cinema+ active (punchier highs)")
end

local function speaker_flat()
    mp.commandv("af", "set", build_speaker_chain("flat"))
    notify("🔊 Speaker Flat active")
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
mp.register_script_message("speaker_cinema", speaker_cinema)
mp.register_script_message("speaker_cinema_plus", speaker_cinema_plus)
mp.register_script_message("speaker_flat", speaker_flat)
mp.register_script_message("reset_filters", reset_filters)
mp.register_script_message("inspect_filters", inspect_filters)

------------------------------------------------------------
-- Load confirmation
------------------------------------------------------------
notify("🎬 Cinema script loaded")
