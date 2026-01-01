-- main.lua
-- Corrected IMAX-style SOFAlizer script for mpv
-- Place in: %AppData%\mpv\scripts\main.lua  or  ~/.config/mpv/scripts/main.lua

local mp = mp
local msg = require "mp.msg"
local utils = require "mp.utils"

-- ===== CONFIG =====
local CONFIG = {
    -- repo-relative fallback (relative to this script file)
    sofa_repo_rel = "sofalizer/hrtf_M_normal pinna resolution 0.5 deg.sofa",
    ir_repo_rel   = "sofalizer/ir/theatre_ir_stereo_48k.wav",

    -- optional local absolute overrides (set locally only)
    local_sofa_path = ""
    local_ir_path   = "",

    sofa_min_channels = 2,
    sofa_max_channels = 9,
    sofa_gain = 16,

    -- ambience
    ambience_dry = 0.85,
    ambience_wet = 0.25,

    -- EQ mode: "firequalizer" (single filter, lower CPU) or "multi_eq"
    eq_mode = "firequalizer",

    -- IR usage (disable by default to avoid CPU spikes)
    use_ir_by_default = false,

    enable_by_default = true,
    toggle_key = "F9",

    -- performance hints
    prefer_resampler = "soxr",
    audio_buffer_ms = 300,

    log = true
}

-- ===== Utilities =====
local function log_info(s) if CONFIG.log then msg.info("[IMAX] " .. tostring(s)) end end
local function log_warn(s) if CONFIG.log then msg.warn("[IMAX] " .. tostring(s)) end end
local function osd(s) mp.osd_message(tostring(s), 2.0) end

local function script_path()
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""
    return source:match("@?(.*[/\\])") or ""
end

local function relpath(rel)
    if not rel or rel == "" then return "" end
    return script_path() .. rel
end

local function q(s) return string.format("%q", s) end

local function file_exists(path)
    if not path or path == "" then return false end
    return utils.file_info(path) ~= nil
end

local function clamp(v, lo, hi)
    v = tonumber(v) or 0
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ===== Asset resolution =====
local function resolve_sofa()
    if CONFIG.local_sofa_path and CONFIG.local_sofa_path ~= "" then
        if file_exists(CONFIG.local_sofa_path) then
            log_info("Using local SOFA override: " .. CONFIG.local_sofa_path)
            return CONFIG.local_sofa_path
        else
            log_warn("local_sofa_path not found: " .. CONFIG.local_sofa_path)
        end
    end
    local repo = relpath(CONFIG.sofa_repo_rel)
    if file_exists(repo) then
        log_info("Using repo SOFA: " .. repo)
        return repo
    end
    log_warn("No SOFA found (local override and repo tried).")
    return nil
end

local function resolve_ir()
    if CONFIG.local_ir_path and CONFIG.local_ir_path ~= "" then
        if file_exists(CONFIG.local_ir_path) then
            log_info("Using local IR override: " .. CONFIG.local_ir_path)
            return CONFIG.local_ir_path
        else
            log_warn("local_ir_path not found: " .. CONFIG.local_ir_path)
        end
    end
    local repo = relpath(CONFIG.ir_repo_rel)
    if file_exists(repo) then
        log_info("Using repo IR: " .. repo)
        return repo
    end
    log_warn("No IR found (local override and repo tried).")
    return nil
end

-- ===== Filter builders =====
local function build_sofalizer_filter(sofa_path)
    if not sofa_path then return nil end
    return "sofalizer=sofa=" .. q(sofa_path) .. ":gain=" .. tostring(CONFIG.sofa_gain) .. ":normalize=yes:interpolate=yes"
end

local function build_ir_filter(ir_path)
    if not ir_path then return nil end
    local dry = clamp(CONFIG.ambience_dry, 0, 1)
    local wet = clamp(CONFIG.ambience_wet, 0, 1)
    return "afir=ir=" .. q(ir_path) .. ":dry=" .. tostring(dry) .. ":wet=" .. tostring(wet)
end

local function build_eq_filters()
    if CONFIG.eq_mode == "firequalizer" then
        local curve = table.concat({
            "entry(30,3.5)",
            "entry(40,3.0)",
            "entry(60,2.5)",
            "entry(120,1.5)",
            "entry(200,1.5)",
            "entry(500,0.8)",
            "entry(2200,2.0)",
            "entry(4500,2.5)",
            "entry(6500,2.5)",
            "entry(8000,2.5)",
            "entry(9500,-1.0)",
            "entry(12000,2.0)"
        }, ";")
        return { "firequalizer=gain_entry='" .. curve .. "'" }
    else
        return {
            "equalizer=f=35:t='l':w=1.0:g=3.0",
            "equalizer=f=60:t='l':w=1.2:g=2.5",
            "equalizer=f=120:t='l':w=1.0:g=1.5",
            "equalizer=f=200:t='l':w=0.8:g=1.5",
            "equalizer=f=500:t='l':w=1.0:g=0.8",
            "equalizer=f=2200:t='h':w=1.0:g=2.0",
            "equalizer=f=4500:t='h':w=1.0:g=2.5",
            "equalizer=f=6500:t='h':w=1.0:g=2.5",
            "equalizer=f=8000:t='h':w=1.3:g=2.5",
            "equalizer=f=9500:t='h':w=2.0:g=-1.0",
            "equalizer=f=12000:t='h':w=1.5:g=2.0"
        }
    end
end

-- ===== Audio chain management =====
local state = { active = false }

local function clear_af()
    local ok, err = pcall(function() mp.commandv("no-osd", "af", "clr") end)
    if not ok then log_warn("Failed to clear af: " .. tostring(err)) end
end

local function add_filter_safe(filter)
    if not filter or filter == "" then return false end
    local ok, err = pcall(function() mp.commandv("no-osd", "af", "add", filter) end)
    if not ok then
        log_warn("Failed to add filter: " .. tostring(filter) .. " (" .. tostring(err) .. ")")
        return false
    end
    return true
end

local function apply_chain()
    log_info("Applying IMAX audio chain")
    clear_af()

    -- Performance hints (best-effort)
    if CONFIG.prefer_resampler and CONFIG.prefer_resampler ~= "" then
        pcall(function() mp.set_property("audio-resampler", CONFIG.prefer_resampler) end)
        log_info("Requested resampler: " .. tostring(CONFIG.prefer_resampler))
    end
    if CONFIG.audio_buffer_ms and tonumber(CONFIG.audio_buffer_ms) then
        pcall(function() mp.set_property("audio-buffer", tostring(CONFIG.audio_buffer_ms)) end)
        log_info("Requested audio buffer (ms): " .. tostring(CONFIG.audio_buffer_ms))
    end

    -- 0) Early downmix/resample when needed to avoid huge CPU load (safe default)
    local in_ch = mp.get_property_native("audio-params/channel-count") or 0
    local in_rate = mp.get_property_native("audio-params/sample-rate") or 0
    if in_ch > 2 then
        add_filter_safe("pan=stereo|c0=0|c1=1")
        log_info("Downmixed to stereo (was " .. tostring(in_ch) .. " channels)")
    end
    if in_rate > 48000 then
        add_filter_safe("aresample=48000")
        log_info("Resampled early to 48000 Hz (was " .. tostring(in_rate) .. " Hz)")
    end

    -- 1) Loudness normalization
    add_filter_safe("loudnorm=I=-23:TP=-2:LRA=7:print_format=none")

    -- 2) SOFAlizer HRTF (single instance)
    local ch = mp.get_property_native("audio-params/channel-count") or 0
    if ch >= CONFIG.sofa_min_channels and ch <= CONFIG.sofa_max_channels then
        local sofa_path = resolve_sofa()
        local sofa_filter = build_sofalizer_filter(sofa_path)
        if sofa_filter then
            add_filter_safe(sofa_filter)
            log_info("SOFAlizer enabled (channels=" .. tostring(ch) .. ")")
        else
            log_warn("SOFAlizer skipped (no sofa available)")
        end
    else
        log_warn("SOFAlizer skipped (channel count = " .. tostring(ch) .. ")")
    end

    -- 3) EQ
    local eqs = build_eq_filters()
    for _, f in ipairs(eqs) do add_filter_safe(f) end

    -- 4) Gentle musical compression
    add_filter_safe("acompressor=threshold=-50dB:ratio=1.2:attack=5:release=50")

    -- 5) IR convolution (optional)
    if CONFIG.use_ir_by_default then
        local ir_path = resolve_ir()
        local ir_filter = build_ir_filter(ir_path)
        if ir_filter then
            add_filter_safe(ir_filter)
            log_info("IR convolution applied")
        else
            log_warn("IR convolution skipped (no IR available)")
        end
    else
        log_info("IR disabled by default")
    end

    -- 6) Safety limiter
    add_filter_safe("alimiter=level_in=1:level_out=0.97:limit=0.0625")

    state.active = true
    osd("IMAX Audio: ON")
    log_info("IMAX audio chain applied")
end

local function remove_chain()
    log_info("Removing IMAX audio chain")
    clear_af()
    state.active = false
    osd("IMAX Audio: OFF")
end

local function toggle()
    if state.active then remove_chain() else apply_chain() end
end

-- ===== mpv hooks =====
local function on_file_loaded()
    log_info("file-loaded")
    state.active = false
    if CONFIG.enable_by_default then
        mp.add_timeout(0.05, apply_chain)
    end
end

local function on_end_file()
    log_info("end-file")
    remove_chain()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_end_file)

if CONFIG.toggle_key and CONFIG.toggle_key ~= "" then
    mp.add_key_binding(CONFIG.toggle_key, "toggle_imax_audio", toggle)
    log_info("Toggle key bound: " .. tostring(CONFIG.toggle_key))
end
