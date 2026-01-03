-- main.lua
-- IMAX-style immersive audio for mpv
-- Features:
--  - Nonblocking async filter adds
--  - Apply-heavy-filters once per file
--  - Chain reapply guard to avoid unnecessary reinit
--  - Device-aware unified presets for headphones and speakers
--  - OSD confirmations and F12 on-screen filter display
-- Place this file in mpv/scripts/sofalizer/ alongside your SOFA/IR assets.

local mp = mp
local msg = require "mp.msg"
local utils = require "mp.utils"

-- ===== CONFIG and PRESETS (unified, with subtle punch) =====
local CONFIG = {
    -- Asset candidates (relative to script folder)
    SOFA_CANDIDATES = {
        "sofalizer/hrtf_M_normal_pinna_resolution_0.5_deg.sofa",
        "sofalizer/hrtf_M_normal_pinna.sofa",
        "sofalizer/hrtf_generic.sofa"
    },
    IR_CANDIDATES = {
        "sofalizer/ir_theatre_short_48k.wav",
        "sofalizer/theatre_ir_stereo_48k.wav"
    },

    -- Optional absolute overrides
    local_sofa_path = "",
    local_ir_path   = "",

    -- Generic defaults (safe, device-aware presets will override)
    prefer_resampler = "soxr",
    prefer_high_precision_resample = false,
    audio_buffer_ms = 300,
    max_early_resample_rate = 48000,

    -- EQ and dynamic defaults (base curve used for both)
    eq_mode = "firequalizer",
    base_curve = {
        "entry(20,1.2)","entry(30,0.8)","entry(40,0.0)","entry(60,-1.2)",
        "entry(80,1.8)","entry(120,-0.8)","entry(250,-0.4)","entry(500,0.9)",
        "entry(1000,1.0)","entry(2200,2.2)","entry(4500,2.8)","entry(6500,3.0)",
        "entry(9000,1.6)","entry(12000,1.0)","entry(16000,0.8)"
    },

    -- small extra air entries (applied for XM5 / headphone mode)
    xm5_extra = { "entry(7000,1.0)", "entry(10000,1.6)", "entry(14000,0.8)" },

    -- Device heuristics
    headphone_device_keywords = { "wh-1000xm5", "xm5", "sony", "headphone", "headset" },
    speaker_device_keywords = { "realtek", "hdmi", "speaker", "stereo" },

    -- Preset behavior
    apply_presets_automatically = true,

    -- UI / toggles
    enable_by_default = true,
    toggle_chain_key = "F9",
    toggle_dynamic_key = "F10",
    toggle_universal_key = "F11",

    -- Logging
    log = true
}

local PRESETS = {
    -- Headphones preset: high precision, gentle IR, extra air, gentle dynamics
    headphones = {
        prefer_high_precision_resample = true,
        max_early_resample_rate = 96000,
        sofa_gain_wh1000xm5 = 13.5,
        sofa_gain_default = 13,
        ambience_dry = 0.96,
        ambience_wet_universal = 0.03,   -- very subtle room for depth
        ambience_wet_speakers = 0.10,
        enable_dynamic_by_default = true,
        dynamic_params = { f = 120, g = 10, p = 0.96 }, -- gentle normalization
        xm5_extra = { "entry(7000,1.0)", "entry(10000,1.6)", "entry(14000,0.8)" }
    },

    -- Speakers preset: conservative resample, short theatre IR, modest wet
    speakers = {
        prefer_high_precision_resample = false,
        max_early_resample_rate = 48000,
        sofa_gain_speakers = 9.5,
        sofa_gain_default = 11,
        ambience_dry = 0.92,
        ambience_wet_speakers = 0.12,
        ambience_wet_universal = 0.06,
        enable_dynamic_by_default = false,
        dynamic_params = { f = 100, g = 14, p = 0.95 },
        xm5_extra = {}
    }
}

-- ===== Utilities =====
local function log_info(s) if CONFIG.log then msg.info("[IMAX] " .. tostring(s)) end end
local function log_warn(s) if CONFIG.log then msg.warn("[IMAX] " .. tostring(s)) end end
local function osd(s, t) mp.osd_message(tostring(s), t or 1.6) end

local function script_path()
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""
    return source:match("@?(.*[/\\])") or ""
end

local function q(s) return string.format("%q", s) end
local function file_exists(path) return path and path ~= "" and utils.file_info(path) ~= nil end
local function clamp(v, lo, hi) v = tonumber(v) or 0 if lo then v = math.max(v, lo) end if hi then v = math.min(v, hi) end return v end

-- Helper to derive a stable key for a filter string (used for duplicate detection)
local function filter_key(filter)
    if not filter or filter == "" then return "" end
    return filter:match("^([^=:%s]+)") or filter
end

local function apply_preset(p)
    if not p then return end
    for k, v in pairs(p) do CONFIG[k] = v end
end

-- ===== Asset resolution (portable) =====
local function find_first_existing(candidates)
    local base = script_path()
    for _, rel in ipairs(candidates) do
        local p = base .. rel
        if utils.file_info(p) then
            log_info("Found asset: " .. p)
            return p
        end
    end
    return nil
end

local function resolve_sofa()
    if CONFIG.local_sofa_path and CONFIG.local_sofa_path ~= "" and file_exists(CONFIG.local_sofa_path) then
        log_info("Using local SOFA override: " .. CONFIG.local_sofa_path)
        return CONFIG.local_sofa_path
    end
    return find_first_existing(CONFIG.SOFA_CANDIDATES)
end

local function resolve_ir()
    if CONFIG.local_ir_path and CONFIG.local_ir_path ~= "" and file_exists(CONFIG.local_ir_path) then
        log_info("Using local IR override: " .. CONFIG.local_ir_path)
        return CONFIG.local_ir_path
    end
    return find_first_existing(CONFIG.IR_CANDIDATES)
end

-- ===== Filter builders =====
local function build_sofalizer_filter(sofa_path, gain)
    if not sofa_path then return nil end
    return "sofalizer=sofa=" .. q(sofa_path) .. ":gain=" .. tostring(gain) .. ":normalize=yes:interpolate=yes"
end

local function build_ir_filter(ir_path, dry, wet)
    if not ir_path then return nil end
    dry = clamp(dry, 0, 1)
    wet = clamp(wet, 0, 1)
    return "afir=ir=" .. q(ir_path) .. ":dry=" .. tostring(dry) .. ":wet=" .. tostring(wet)
end

local function build_firequalizer_curve(extra_entries)
    local curve = {}
    for _, e in ipairs(CONFIG.base_curve) do table.insert(curve, e) end
    if extra_entries then
        for _, e in ipairs(extra_entries) do table.insert(curve, e) end
    end
    return "firequalizer=gain_entry='" .. table.concat(curve, ";") .. "'"
end

local function build_eq_filters(is_xm5)
    if CONFIG.eq_mode ~= "firequalizer" then
        return {
            "equalizer=f=60:t='l':w=1.2:g=-1.0",
            "equalizer=f=500:t='l':w=1.0:g=0.8",
            "equalizer=f=2200:t='h':w=1.0:g=2.2",
            "equalizer=f=4500:t='h':w=1.0:g=3.0"
        }
    end
    if is_xm5 then
        return { build_firequalizer_curve(CONFIG.xm5_extra) }
    else
        return { build_firequalizer_curve() }
    end
end

local function build_dynamic_filter()
    if not CONFIG.enable_dynamic_by_default then return nil end
    local p = CONFIG.dynamic_params or { f = 100, g = 14, p = 0.95 }
    return string.format("dynaudnorm=f=%d:g=%d:p=%.2f", p.f or 100, p.g or 14, p.p or 0.95)
end

-- ===== Chain management =====
local state = {
    active = false,
    universal_mode = false,
    dynamic_active = false
}

local last_chain_signature = nil
local sofa_applied = false

local function chain_signature()
    local dev = mp.get_property("audio-device") or ""
    local sig = table.concat({
        tostring(state.universal_mode),
        tostring(state.dynamic_active),
        tostring(dev),
        tostring(mp.get_property("audio-samplerate") or "")
    }, "|")
    return sig
end

local function get_audio_filters()
    local ok, af = pcall(function() return mp.get_property_native("audio-filters") end)
    if not ok or not af then return {} end
    return af
end

local function audio_filter_exists(sub)
    if not sub or sub == "" then return false end
    local af = get_audio_filters()
    for _, f in ipairs(af) do
        if string.find(f, sub, 1, true) then
            return true
        end
    end
    return false
end

-- Clear audio filters (nonblocking) - prefer "clear" then fallback to "clr"
local function clear_af()
    local cmd = { name = "af", args = {"clear"} }
    mp.command_native_async(cmd, function(success, result, err)
        if not success then
            local cmd2 = { name = "af", args = {"clr"} }
            mp.command_native_async(cmd2, function(s2) if not s2 then log_warn("Failed to clear af") end end)
        else
            log_info("Audio filters cleared")
        end
    end)
end

-- Add filter safely: avoid duplicates by checking existing filters first (nonblocking)
local function add_filter_safe(filter)
    if not filter or filter == "" then return false end
    local unique_sub = filter_key(filter)
    if audio_filter_exists(unique_sub) then
        log_info("Filter already present, skipping add: " .. tostring(unique_sub))
        return false
    end

    local cmd = { name = "af", args = {"add", filter} }
    mp.command_native_async(cmd, function(success, result, err)
        if not success then
            log_warn("Failed to add filter (async): " .. tostring(filter) .. " (" .. tostring(err) .. ")")
        else
            log_info("Filter applied (async): " .. tostring(unique_sub))
        end
    end)
    return true
end

local function build_safe_downmix()
    local ch = mp.get_property_native("audio-params/channel-count") or 0
    if ch <= 2 then return nil end
    local left_terms, right_terms = {}, {}
    for i = 0, ch - 1 do
        table.insert(left_terms, ("c%d"):format(i))
        table.insert(right_terms, ("c%d"):format(i))
    end
    local left_expr = table.concat(left_terms, "+")
    local right_expr = table.concat(right_terms, "+")
    local div = tostring(ch)
    return ("pan=stereo|c0=%s/%s|c1=%s/%s"):format(left_expr, div, right_expr, div)
end

local function device_name_matches(keywords, devname)
    if not devname or devname == "" then return false end
    local d = string.lower(devname)
    for _, k in ipairs(keywords) do
        if d:find(string.lower(k), 1, true) then return true end
    end
    return false
end

local function detect_output_type()
    local dev = mp.get_property("audio-device") or ""
    if device_name_matches(CONFIG.headphone_device_keywords, dev) then
        return "headphones"
    end
    if device_name_matches(CONFIG.speaker_device_keywords, dev) then
        return "speakers"
    end
    local d = string.lower(dev)
    if d:find("head") or d:find("headset") then return "headphones" end
    if d:find("hdmi") or d:find("speaker") or d:find("realtek") then return "speakers" end
    return "unknown"
end

-- Simple CPU overload stub (keeps dynamic enabled by default). Replace with a real heuristic if desired.
local function cpu_overloaded()
    return false
end

local function apply_device_preset_if_needed()
    if not CONFIG.apply_presets_automatically then return end
    local out_type = detect_output_type()
    if out_type == "headphones" then
        apply_preset(PRESETS.headphones)
        state.dynamic_active = CONFIG.enable_dynamic_by_default
        log_info("Applied headphones preset")
    elseif out_type == "speakers" then
        apply_preset(PRESETS.speakers)
        state.dynamic_active = CONFIG.enable_dynamic_by_default
        log_info("Applied speakers preset")
    else
        log_info("No device-specific preset applied (unknown device)")
    end
end

-- ===== apply_chain / remove_chain / toggles (with OSD confirmations) =====
local function apply_chain()
    apply_device_preset_if_needed()

    local sig = chain_signature()
    if sig == last_chain_signature then
        log_info("Chain unchanged, skipping reapply")
        osd("Chain: unchanged", 1.2)
        return
    end
    last_chain_signature = sig

    log_info("Applying IMAX-style audio chain")
    clear_af()
    sofa_applied = false

    if CONFIG.audio_buffer_ms and tonumber(CONFIG.audio_buffer_ms) then
        pcall(function() mp.set_property("audio-buffer", tostring(CONFIG.audio_buffer_ms)) end)
        log_info("Requested audio buffer (ms): " .. tostring(CONFIG.audio_buffer_ms))
    end

    local in_ch = mp.get_property_native("audio-params/channel-count") or 0
    local in_rate = mp.get_property_native("audio-params/sample-rate") or 0
    local device_rate = tonumber(mp.get_property("audio-samplerate")) or in_rate

    if in_ch > 2 then
        local pan = build_safe_downmix()
        if pan then add_filter_safe(pan); log_info("Downmixed to stereo (was " .. tostring(in_ch) .. " channels)") end
    end

    local target_rate = in_rate
    if device_rate and device_rate > 0 then target_rate = device_rate end
    target_rate = math.min(target_rate, CONFIG.max_early_resample_rate or 48000)
    if in_rate > 0 and in_rate ~= target_rate then
        local s32 = CONFIG.prefer_high_precision_resample and ":osf=s32" or ""
        add_filter_safe("aresample=" .. tostring(target_rate) .. s32)
        log_info("Resampled early to " .. tostring(target_rate) .. " Hz")
    end

    add_filter_safe("highpass=f=18")
    add_filter_safe("loudnorm=I=-18:TP=-1.5:LRA=7:print_format=none")

    local out_type = detect_output_type()
    log_info("Detected output type: " .. tostring(out_type))
    local sofa_path = resolve_sofa()
    local ir_path = resolve_ir()

    if state.universal_mode then
        if sofa_path and not sofa_applied then
            local sf = build_sofalizer_filter(sofa_path, CONFIG.sofa_gain_speakers or CONFIG.sofa_gain_default)
            if sf then add_filter_safe(sf); log_info("SOFAlizer applied (universal conservative)"); sofa_applied = true end
        end
        if ir_path and not sofa_applied then
            local irf = build_ir_filter(ir_path, CONFIG.ambience_dry or 0.92, CONFIG.ambience_wet_universal or 0.06)
            if irf then add_filter_safe(irf); log_info("IR applied (universal conservative)"); sofa_applied = true end
        end
    else
        if out_type == "headphones" then
            local is_xm5 = device_name_matches({ "wh-1000xm5", "xm5" }, mp.get_property("audio-device") or "")
            local gain = is_xm5 and (CONFIG.sofa_gain_wh1000xm5 or 14) or (CONFIG.sofa_gain_default or 13)
            if sofa_path and not sofa_applied then
                local sf = build_sofalizer_filter(sofa_path, gain)
                if sf then add_filter_safe(sf); log_info("SOFAlizer enabled (gain=" .. tostring(gain) .. ")"); sofa_applied = true end
            else
                log_info("No SOFA found; HRTF skipped")
            end
            log_info("IR skipped for headphones by default")
        elseif out_type == "speakers" then
            if ir_path and not sofa_applied then
                local irf = build_ir_filter(ir_path, CONFIG.ambience_dry or 0.92, CONFIG.ambience_wet_speakers or 0.12)
                if irf then add_filter_safe(irf); log_info("IR convolution applied for speakers (wet=" .. tostring(CONFIG.ambience_wet_speakers) .. ")"); sofa_applied = true end
            else
                log_info("No IR found; speaker IR skipped")
            end
            log_info("HRTF skipped for speakers by default")
        else
            if sofa_path and not sofa_applied then
                local sf = build_sofalizer_filter(sofa_path, CONFIG.sofa_gain_default or 12)
                if sf then add_filter_safe(sf); log_info("SOFAlizer applied (fallback)"); sofa_applied = true end
            end
        end
    end

    local is_xm5_device = device_name_matches({ "wh-1000xm5", "xm5" }, mp.get_property("audio-device") or "")
    local eqs = build_eq_filters(is_xm5_device)
    for _, f in ipairs(eqs) do add_filter_safe(f) end

    if state.dynamic_active and not cpu_overloaded() then
        local dyn = build_dynamic_filter()
        if dyn then add_filter_safe(dyn); log_info("Dynamic processor enabled: " .. dyn); osd("Dynamic: ON", 1.2) end
    else
        log_info("Dynamic processor disabled or CPU overloaded")
    end

    -- transient enhancer / punch (gentle but punchier)
    add_filter_safe("acompressor=threshold=-30dB:ratio=2.2:attack=0.6:release=40:makeup=1.6")

    add_filter_safe("alimiter=level_in=1:level_out=0.985:limit=0.0625")

    state.active = true
    osd("Universal IMAX: ON" .. (state.universal_mode and " (universal)" or ""), 1.6)
    log_info("IMAX-style chain applied")
end

local function remove_chain()
    log_info("Removing IMAX-style chain")
    clear_af()
    sofa_applied = false
    state.active = false
    osd("Universal IMAX: OFF", 1.2)
    log_info("IMAX-style chain removed")
end

local function toggle_chain()
    if state.active then
        remove_chain()
        osd("Chain: OFF", 1.0)
    else
        apply_chain()
        osd("Chain: ON", 1.0)
    end
end

local function toggle_universal()
    state.universal_mode = not state.universal_mode
    osd("Universal mode: " .. (state.universal_mode and "ON" or "OFF"), 1.2)
    log_info("Universal mode toggled: " .. tostring(state.universal_mode))
    if state.active then mp.add_timeout(0.25, apply_chain) end
end

local function toggle_dynamic()
    state.dynamic_active = not state.dynamic_active
    osd("Dynamic: " .. (state.dynamic_active and "ON" or "OFF"), 1.2)
    log_info("Dynamic toggled: " .. tostring(state.dynamic_active))
    if state.active then mp.add_timeout(0.05, apply_chain) end
end

-- ===== mpv hooks & keybindings =====
local function on_file_loaded()
    log_info("file-loaded")
    state.active = false
    sofa_applied = false
    last_chain_signature = nil
    apply_device_preset_if_needed()
    state.dynamic_active = CONFIG.enable_dynamic_by_default or false
    if CONFIG.enable_by_default then mp.add_timeout(0.05, apply_chain) end
end

local function on_end_file()
    log_info("end-file")
    remove_chain()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_end_file)

if CONFIG.toggle_chain_key and CONFIG.toggle_chain_key ~= "" then
    mp.add_key_binding(CONFIG.toggle_chain_key, "toggle_universal_chain", toggle_chain)
    log_info("Toggle chain key bound: " .. tostring(CONFIG.toggle_chain_key))
end
if CONFIG.toggle_universal_key and CONFIG.toggle_universal_key ~= "" then
    mp.add_key_binding(CONFIG.toggle_universal_key, "toggle_universal_mode", toggle_universal)
    log_info("Toggle universal key bound: " .. tostring(CONFIG.toggle_universal_key))
end
if CONFIG.toggle_dynamic_key and CONFIG.toggle_dynamic_key ~= "" then
    mp.add_key_binding(CONFIG.toggle_dynamic_key, "toggle_universal_dynamic", toggle_dynamic)
    log_info("Toggle dynamic key bound: " .. tostring(CONFIG.toggle_dynamic_key))
end

-- Show active audio filters on screen (press F12)
mp.add_key_binding("F12", "show_audio_filters", function()
    local af = mp.get_property_native("audio-filters") or {}
    -- longer OSD duration to allow reading long filter lists
    mp.osd_message(table.concat(af, "; "), 6)
end)
