--[[
SOFAlizer (KEMAR) for mpv - cinema-grade headphone virtualization
Place this file in:
  Windows:  %AppData%\mpv\scripts\main.lua
  Linux/macOS:  ~/.config/mpv/scripts/main.lua
]]

----------------------------------
-- User configuration
----------------------------------
local CONFIG = {
    -- Enable SOFAlizer within this input channel range (stereo up to 7.1 by default)
    sofa_min_channels = 2,
    sofa_max_channels = 9,

    -- Preserve dynamics; adjust via mpv volume instead of gain when possible
    sofa_gain = 16,

    -- High-quality movie playback options for natural imaging
    -- normalize=yes            : Stable loudness across HRTF processing
    -- interpolate=yes          : Smooth spatial interpolation
    -- freq_range=full          : Full-band processing
    -- delay_compensation=yes   : Aligns temporal cues
    -- phase=wgd                : Weighted group delay for natural phase
    sofa_opts = "normalize=yes:interpolate=yes:freq_range=full:delay_compensation=yes:phase=wgd",

    -- Path to your KEMAR SOFA file, relative to mpv config dir (~~/)
    -- Example: copy Kemar_HRTF_sofa.sofa to scripts/sofalizer/
    sofa_file = "scripts/sofalizer/Kemar_HRTF_sofa.sofa",

    -- Unique label for clean management
    label = "sofalizer_kemar",

    -- Force stereo output if your pipeline or device requires it (usually false)
    force_stereo_output = false,

    -- Optional logging
    log = true
}

----------------------------------
-- Internals (do not edit)
----------------------------------
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
    if is_filter_present() then
        log_info("Filter already present; skipping add")
        return
    end
    local f = build_filter_string()
    mp.commandv("no-osd", "af", "add", f)
    log_info("Added filter: " .. f)
end

local function remove_filter()
    if not is_filter_present() then return end
    mp.commandv("no-osd", "af", "remove", CONFIG.label)
    log_info("Removed filter (label=" .. CONFIG.label .. ")")
end

local function should_enable(channels)
    return (type(channels) == "number"
        and channels >= CONFIG.sofa_min_channels
        and channels <= CONFIG.sofa_max_channels)
end

local function on_channels(_, channels)
    if should_enable(channels) then
        add_filter()
    else
        remove_filter()
    end
end

local function reset_observers()
    mp.unobserve_property(on_channels)
end

local function on_file_loaded()
    log_info("File loaded")
    reset_observers()
    mp.observe_property("audio-params/channel-count", "number", on_channels)
    local channels = mp.get_property_native("audio-params/channel-count")
    on_channels(nil, channels)
-- Pre-normalization for cleaner HRTF processing
mp.commandv("af", "add", "loudnorm=I=-23:TP=-2:LRA=7")

-- Treble clarity boost (even sharper gunshots)
mp.commandv("af", "add", "equalizer=f=8000:t=h:w=1.3:g=3.5")

-- Bass impact boost (slightly stronger)
mp.commandv("af", "add", "equalizer=f=120:t=l:w=1:g=1.8")

-- Wider cinematic soundstage
mp.commandv("af", "add", "stereotools=surround=0.35")
end

local function on_file_ended()
    log_info("End of file")
    reset_observers()
    remove_filter()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_file_ended)

-- Safety: clean any stray filter on startup
mp.add_timeout(0.1, function()
    if is_filter_present() then
        log_warn("Stray filter found on startup; removing")
        remove_filter()
    end
end)
