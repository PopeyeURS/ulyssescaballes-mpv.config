--[[
SOFAlizer (KEMAR) for mpv - IMAX-theater-grade headphone virtualization
Place this file in:
  Windows:  %AppData%\mpv\scripts\main.lua
  Linux/macOS:  ~/.config/mpv/scripts/main.lua
]]

local CONFIG = {
    sofa_min_channels = 2,
    sofa_max_channels = 9,
    sofa_gain = 16,
    sofa_file = "scripts/sofalizer/Kemar_HRTF_sofa.sofa",

    enable_by_default = true,
    bind_toggle_key   = "F9",

    log = true
}

local mp  = mp
local msg = require "mp.msg"

-- Internal state: purely for UX/logs, not for logic correctness
local state = {
    active = false
}

local function log_info(s)
    if CONFIG.log then
        msg.info("[AUDIO] " .. s)
    end
end

local function log_warn(s)
    if CONFIG.log then
        msg.warn("[AUDIO] " .. s)
    end
end

local function osd(text)
    mp.osd_message(text, 2.0)
end

local function expand(rel)
    local base = mp.command_native({ "expand-path", "~~/" })
    return base .. "/" .. rel
end

local function build_sofa()
    local path = expand(CONFIG.sofa_file)
    return "sofalizer=sofa=\"" .. path .. "\":gain=" ..
           CONFIG.sofa_gain .. ":normalize=yes:interpolate=yes"
end

local function clear_af()
    mp.set_property("af", "")
end

local function apply_chain()
    log_info("Applying IMAX + SOFAlizer chain")

    -- Start from a known-clean graph
    clear_af()

    -- Loudness normalization
    mp.commandv("no-osd", "af", "add",
        "loudnorm=I=-23:TP=-2:LRA=7:print_format=none")

    -- SOFAlizer (only when channel-count is valid)
    local ch = mp.get_property_native("audio-params/channel-count")
    if type(ch) == "number" then
        if ch >= CONFIG.sofa_min_channels and ch <= CONFIG.sofa_max_channels then
            mp.commandv("no-osd", "af", "add", build_sofa())
            log_info("SOFAlizer applied (channels = " .. tostring(ch) .. ")")
        else
            log_warn("Skipping SOFAlizer (channel count = " .. tostring(ch) .. ")")
        end
    else
        log_warn("Skipping SOFAlizer (channel count unavailable)")
    end

    -- Low end / bass foundation
    mp.commandv("no-osd", "af", "add", "equalizer=f=35:t='l':w=1.0:g=3")
    mp.commandv("no-osd", "af", "add", "equalizer=f=60:t='l':w=1.2:g=2.5")
    mp.commandv("no-osd", "af", "add", "equalizer=f=120:t='l':w=1.0:g=1.5")
    mp.commandv("no-osd", "af", "add", "equalizer=f=200:t='l':w=1.0:g=1.0")
    mp.commandv("no-osd", "af", "add", "equalizer=f=500:t='l':w=1.0:g=0.8")

    -- Impact body
    mp.commandv("no-osd", "af", "add", "equalizer=f=140:t='l':w=1.0:g=1.5")

    -- Presence / crack / air
    mp.commandv("no-osd", "af", "add", "equalizer=f=2200:t='h':w=1.0:g=2.0")
    mp.commandv("no-osd", "af", "add", "equalizer=f=4500:t='h':w=1.0:g=2.5")
    mp.commandv("no-osd", "af", "add", "equalizer=f=6500:t='h':w=1.0:g=2.5")
    mp.commandv("no-osd", "af", "add", "equalizer=f=8000:t='h':w=1.3:g=2.5")
    mp.commandv("no-osd", "af", "add", "equalizer=f=9500:t='h':w=2.0:g=-1.0")
    mp.commandv("no-osd", "af", "add", "equalizer=f=12000:t='h':w=1.5:g=2.0")

    -- Subharmonic, light enhancement
    mp.commandv("no-osd", "af", "add", "superequalizer=1b=1.15")

    -- Light, musical compression
    mp.commandv("no-osd", "af", "add",
        "acompressor=threshold=-50dB:ratio=1.2:attack=5:release=50")

    -- Subtle ambience
    mp.commandv("no-osd", "af", "add",
        "aecho=0.6:0.35:60|120:0.12|0.08")

    -- Safety limiter
    mp.commandv("no-osd", "af", "add",
        "alimiter=level_in=1:level_out=0.97:limit=0.0625")

    state.active = true
    log_info("IMAX chain applied")
    osd("IMAX + SOFAlizer: ON")
end

local function remove_chain()
    log_info("Removing IMAX chain")
    clear_af()
    state.active = false
    osd("IMAX + SOFAlizer: OFF")
end

local function toggle()
    local af = mp.get_property("af") or ""
    if af == "" then
        apply_chain()
    else
        remove_chain()
    end
end

local function on_loaded()
    log_info("File loaded")
    state.active = false
    if CONFIG.enable_by_default then
        apply_chain()
    end
end

local function on_end()
    log_info("End of file")
    remove_chain()
end

mp.register_event("file-loaded", on_loaded)
mp.register_event("end-file", on_end)

if CONFIG.bind_toggle_key ~= "" then
    mp.add_key_binding(CONFIG.bind_toggle_key, "toggle_imax_chain", toggle)
    log_info("Toggle key bound: " .. CONFIG.bind_toggle_key)
end
