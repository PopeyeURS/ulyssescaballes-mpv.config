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
    sofa_opts = "normalize=yes:interpolate=yes:freq_range=full:delay_compensation=yes:phase=wgd",
    sofa_file = "scripts/sofalizer/Kemar_HRTF_sofa.sofa",
    label = "sofalizer_kemar",
    force_stereo_output = false,
    log = true
}

local mp = mp
local msg = require "mp.msg"

local function log_info(s) if CONFIG.log then msg.info("[SOFAlizer] " .. s) end end
local function log_warn(s) if CONFIG.log then msg.warn("[SOFAlizer] " .. s) end end

local function expand_config_path(rel)
    local base = mp.command_native({ "expand-path", "~~/" })
    return base .. "/" .. rel
end

local function build_filter_string()
    local sofa_path = expand_config_path(CONFIG.sofa_file)
    local parts = {
        'sofalizer=',
        'sofa="' .. sofa_path .. '"',
        ':gain=' .. tostring(CONFIG.sofa_gain),
        ":" .. CONFIG.sofa_opts,
        ":label=" .. CONFIG.label
    }
    if CONFIG.force_stereo_output then
        table.insert(parts, ":out=stereo")
    end
    return table.concat(parts)
end

local function is_filter_present()
    local af = mp.get_property("af") or ""
    return af:find("label=" .. CONFIG.label, 1, true) ~= nil
end

local function add_filter()
    if is_filter_present() then return end
    mp.commandv("no-osd", "af", "add", build_filter_string())
end

local function remove_filter()
    if not is_filter_present() then return end
    mp.commandv("no-osd", "af", "remove", CONFIG.label)
end

local function should_enable(channels)
    return type(channels) == "number"
        and channels >= CONFIG.sofa_min_channels
        and channels <= CONFIG.sofa_max_channels
end

local function on_channels(_, channels)
    if should_enable(channels) then add_filter() else remove_filter() end
end

local function reset_observers()
    mp.unobserve_property(on_channels)
end

local function on_file_loaded()
    log_info("File loaded")
    reset_observers()
    mp.observe_property("audio-params/channel-count", "number", on_channels)
    on_channels(nil, mp.get_property_native("audio-params/channel-count"))

    -- Loudness normalization
    mp.commandv("af", "add", "loudnorm=I=-23:TP=-2:LRA=7")

    -- Bass foundation
    mp.commandv("af", "add", "equalizer=f=60:t=l:w=1.2:g=4")
    mp.commandv("af", "add", "equalizer=f=120:t=l:w=1.0:g=1.8")
    mp.commandv("af", "add", "equalizer=f=200:t=l:w=1.0:g=1.2")

    -- Ocean-wave / waterfall / wind fullness
    mp.commandv("af", "add", "equalizer=f=500:t=l:w=1.0:g=1.5")

    -- Bass Enhancements (Subwoofer Mode)
    mp.commandv("af", "add", "equalizer=f=35:t=l:w=1.0:g=4")   -- Deep sub-bass rumble
    mp.commandv("af", "add", "equalizer=f=70:t=l:w=1.2:g=3")   -- Sub-bass body
    mp.commandv("af", "add", "equalizer=f=150:t=l:w=1.0:g=2")  -- Bass punch

    -- Gunshot impact body
    mp.commandv("af", "add", "equalizer=f=140:t=l:w=1.0:g=2")

    -- Gunshot crack
    mp.commandv("af", "add", "equalizer=f=2200:t=h:w=1.0:g=2.5")

    -- Gunshot metallic snap
    mp.commandv("af", "add", "equalizer=f=6500:t=h:w=1.0:g=3")

    -- Subharmonic generator (bass expansion)
    mp.commandv("af", "add", "superequalizer=1b=1.2")

    -- Bass tilt
    mp.commandv("af", "add", "stereotools=basstilt=0.25")

    -- Optimized transient enhancer
    mp.commandv("af", "add", "afir=length=24")

    -- Midrange shaping
    mp.commandv("af", "add", "acompressor=threshold=-50dB:ratio=1.2:attack=5:release=50")
    mp.commandv("af", "add", "equalizer=f=2700:t=h:w=1.0:g=-1.5")
    mp.commandv("af", "add", "equalizer=f=4500:t=h:w=1.0:g=5")
    mp.commandv("af", "add", "equalizer=f=8000:t=h:w=1.3:g=3.5")
    mp.commandv("af", "add", "equalizer=f=12000:t=h:w=1.5:g=4")
    mp.commandv("af", "add", "equalizer=f=9500:t=h:w=2.0:g=-1.2")

    -- High-end FIR exciter for micro-texture
    mp.commandv("af", "add", "afir=length=48")

    -- Sparkling metal enhancer
    mp.commandv("af", "add", "afir=length=32:dry=0.7")

    -- Punch compressor
    mp.commandv("af", "add", "acompressor=threshold=-15dB:ratio=3:attack=2:release=120")

    -- Spatial widening and diffusion
    mp.commandv("af", "add", "stereotools=surround=0.35")
    mp.commandv("af", "add", "stereotools=delay=0.25")
    mp.commandv("af", "add", "stereotools=softclip=0.0:crossfeed=0.12")

    -- Ambient echo
    mp.commandv("af", "add", "aecho=0.6:0.4:60|120:0.15|0.1")

    -- Final limiter
    mp.commandv("af", "add", "alimiter=level_in=1:level_out=0.98:limit=0.0")

    log_info("IMAX Theater + Bass Mode processing chain applied")
end

local function on_file_ended()
    log_info("End of file")
    reset_observers()
    remove_filter()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_file_ended)

mp.add_timeout(0.1, function()
    if is_filter_present() then remove_filter() end
end)
