--[[ 
Unified Audio Engine for mpv
Headphones = KEMAR SOFAlizer (cinema-grade binaural)
Speakers   = Maximum Safe Cinematic EQ Chain (no HRTF)
]]

----------------------------------
-- User configuration
----------------------------------
local CONFIG = {
    -- SOFAlizer activation range (headphones = stereo only)
    sofa_min_channels = 2,
    sofa_max_channels = 2,

    -- SOFAlizer gain
    sofa_gain = 16,

    -- High-quality SOFAlizer options
    sofa_opts = "normalize=yes:interpolate=yes:freq_range=full:delay_compensation=yes:phase=wgd",

    -- Path to KEMAR SOFA file
    sofa_file = "scripts/sofalizer/Kemar_HRTF_sofa.sofa",

    -- Label for SOFAlizer
    label = "sofalizer_kemar",

    -- Logging
    log = true
}

----------------------------------
-- Internals
----------------------------------
local mp = mp
local msg = require "mp.msg"

local function log(s) if CONFIG.log then msg.info("[AUDIO] " .. s) end end

local function expand(rel)
    local base = mp.command_native({ "expand-path", "~~/" })
    return base .. "/" .. rel
end

local function build_sofa()
    local path = expand(CONFIG.sofa_file)
    return table.concat({
        "sofalizer=",
        'sofa="' .. path .. '"',
        ":gain=" .. CONFIG.sofa_gain,
        ":" .. CONFIG.sofa_opts,
        ":label=" .. CONFIG.label
    })
end

local function sofa_present()
    local af = mp.get_property("af") or ""
    return af:find("label=" .. CONFIG.label, 1, true) ~= nil
end

local function add_sofa()
    if sofa_present() then return end
    local f = build_sofa()
    mp.commandv("no-osd", "af", "add", f)
    log("SOFAlizer enabled")
end

local function remove_sofa()
    if not sofa_present() then return end
    mp.commandv("no-osd", "af", "remove", CONFIG.label)
    log("SOFAlizer disabled")
end

----------------------------------
-- Speaker processing (MAX CINEMA)
----------------------------------
local function apply_speaker_filters(ch)
    log("Applying MAX CINEMA speaker filters for " .. ch .. " channels")

    -- Clear previous filters
    mp.commandv("af", "clr")

    -- Loudness normalization (cinema standard)
    mp.commandv("af", "add", "loudnorm=I=-23:TP=-2:LRA=7")

    -- Treble clarity boost (max safe)
    mp.commandv("af", "add", "equalizer=f=8000:t=h:w=1.3:g=4")

    -- Bass impact boost (max safe)
    mp.commandv("af", "add", "equalizer=f=120:t=l:w=1:g=4")

    -- Blockbuster sub‑bass boost (safe)
    mp.commandv("af", "add", "equalizer=f=70:t=l:w=1:g=3")

    -- Stronger cinema compressor (max safe)
    mp.commandv("af", "add", "acompressor=ratio=2.0:threshold=-12")

    -- Stereo widening for 2.0 speakers only
    if ch == 2 then
        mp.commandv("af", "add", "stereotools=surround=0.40")
    end
end

----------------------------------
-- Headphone processing (SOFAlizer)
----------------------------------
local function apply_headphone_filters()
    log("Applying headphone (SOFAlizer) filters")

    mp.commandv("af", "clr")

    -- Pre-normalization
    mp.commandv("af", "add", "loudnorm=I=-23:TP=-2:LRA=7")

    -- SOFAlizer
    add_sofa()

    -- Enhancements
    mp.commandv("af", "add", "equalizer=f=8000:t=h:w=1.3:g=3.5")
    mp.commandv("af", "add", "equalizer=f=120:t=l:w=1:g=1.8")
    mp.commandv("af", "add", "stereotools=surround=0.35")
end

----------------------------------
-- Auto-switching logic
----------------------------------
local function on_channels(_, ch)
    if type(ch) ~= "number" then return end

    if ch >= CONFIG.sofa_min_channels and ch <= CONFIG.sofa_max_channels then
        -- Headphones (stereo)
        apply_headphone_filters()
    else
        -- Speakers (2.1, soundbar, 5.1, 7.1, Atmos)
        remove_sofa()
        apply_speaker_filters(ch)
    end
end

local function on_file_loaded()
    log("File loaded")
    mp.observe_property("audio-params/channel-count", "number", on_channels)
    local ch = mp.get_property_native("audio-params/channel-count")
    on_channels(nil, ch)
end

local function on_file_ended()
    log("File ended")
    remove_sofa()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_file_ended)

mp.add_timeout(0.1, function()
    if sofa_present() then
        remove_sofa()
    end
end)
