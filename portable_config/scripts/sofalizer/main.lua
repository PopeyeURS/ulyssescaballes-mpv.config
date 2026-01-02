-- main.lua
-- Tailored IMAX-style immersive audio for mpv
-- Tuned for Sony WH-1000XM5 (headphones) and Realtek High Definition Audio (speakers)
-- Portable: place main.lua in mpv/scripts/ and optional assets in mpv/scripts/sofalizer/
-- Keys: F9 toggle chain, F10 toggle dynamic, F11 toggle universal mode

local mp = mp
local msg = require "mp.msg"
local utils = require "mp.utils"

-- ===== CONFIG =====
local CONFIG = {
    -- Candidate repo-relative filenames (put these in sofalizer/ next to main.lua)
    SOFA_CANDIDATES = {
        "sofalizer/hrtf_M_normal_pinna_resolution_0.5_deg.sofa",
        "sofalizer/hrtf_M_normal_pinna.sofa",
        "sofalizer/hrtf_generic.sofa"
    },
    IR_CANDIDATES = {
        "sofalizer/ir_theatre_short_48k.wav",
        "sofalizer/theatre_ir_stereo_48k.wav"
    },

    -- Optional absolute overrides (leave empty for portable behavior)
    local_sofa_path = "",
    local_ir_path   = "",

    sofa_min_channels = 2,
    sofa_max_channels = 9,
    sofa_gain = 16,

    -- Device-specific heuristics (case-insensitive substrings)
    headphone_device_keywords = { "wh-1000xm5", "xm5", "sony" },
    speaker_device_keywords = { "realtek", "hdmi", "speaker" },

    -- HRTF gains tuned for WH-1000XM5 and speakers
    sofa_gain_wh1000xm5 = 14,   -- slightly wide but natural for XM5
    sofa_gain_speakers = 10,    -- conservative if applied to speakers
    sofa_gain_default = 12,

    -- IR wet/dry
    ambience_dry = 0.92,
    ambience_wet_speakers = 0.12,
    ambience_wet_universal = 0.06,

    -- EQ: base firequalizer curve (conservative, cinematic)
    eq_mode = "firequalizer",
    base_curve = {
        "entry(20,1.2)",
        "entry(30,0.8)",
        "entry(40,0.0)",
        "entry(60,-1.2)",
        "entry(120,-0.8)",
        "entry(250,-0.4)",
        "entry(500,0.9)",
        "entry(1000,1.0)",
        "entry(2200,2.0)",
        "entry(4500,2.8)",
        "entry(6500,3.0)",
        "entry(9000,1.6)",
        "entry(12000,1.0)",
        "entry(16000,0.8)"
    },

    -- Additional headphone-specific air/presence for WH-1000XM5
    xm5_extra = { "entry(7000,1.2)", "entry(10000,1.6)", "entry(14000,0.8)" },

    -- Performance and resampling
    prefer_resampler = "soxr",
    prefer_high_precision_resample = true,
    audio_buffer_ms = 300,
    max_early_resample_rate = 96000,

    -- Dynamic processing (optional)
    enable_dynamic_by_default = false,
    dynamic_params = { f = 100, g = 14, p = 0.95 },

    -- Universal mode: apply conservative HRTF+IR for mixed outputs
    universal_mode = false,

    -- Keys and toggles
    enable_by_default = true,
    toggle_chain_key = "F9",
    toggle_dynamic_key = "F10",
    toggle_universal_key = "F11",

    log = true
}

-- ===== Utilities =====
local function log_info(s) if CONFIG.log then msg.info("[IMAX] " .. tostring(s)) end end
local function log_warn(s) if CONFIG.log then msg.warn("[IMAX] " .. tostring(s)) end end
local function osd(s) mp.osd_message(tostring(s), 1.6) end

local function script_path()
    local info = debug.getinfo(1, "S")
    local source = info and info.source or ""
    return source:match("@?(.*[/\\])") or ""
end

local function q(s) return string.format("%q", s) end
local function file_exists(path) return path and path ~= "" and utils.file_info(path) ~= nil end
local function clamp(v, lo, hi) v = tonumber(v) or 0 if lo then v = math.max(v, lo) end if hi then v = math.min(v, hi) end return v end

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
    local p = CONFIG.dynamic_params
    return string.format("dynaudnorm=f=%d:g=%d:p=%.2f", p.f or 100, p.g or 14, p.p or 0.95)
    -- If you want to accept non-integer f/g, consider:
    -- return string.format("dynaudnorm=f=%g:g=%g:p=%.2f", p.f or 100, p.g or 14, p.p or 0.95)
end

-- ===== Chain management =====
local state = {
    active = false,
    universal_mode = CONFIG.universal_mode,
    dynamic_active = CONFIG.enable_dynamic_by_default
}

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
    -- fallback: check common substrings
    local d = string.lower(dev)
    if d:find("head") or d:find("headset") then return "headphones" end
    if d:find("hdmi") or d:find("speaker") or d:find("realtek") then return "speakers" end
    return "unknown"
end

local function cpu_overloaded()
    return false
end

local function apply_chain()
    log_info("Applying universal tuned chain (WH-1000XM5 / Realtek)")
    clear_af()

    -- performance hints
    if CONFIG.prefer_resampler and CONFIG.prefer_resampler ~= "" then
        pcall(function() mp.set_property("audio-resampler", CONFIG.prefer_resampler) end)
        log_info("Requested resampler: " .. tostring(CONFIG.prefer_resampler))
    end
    if CONFIG.audio_buffer_ms and tonumber(CONFIG.audio_buffer_ms) then
        pcall(function() mp.set_property("audio-buffer", tostring(CONFIG.audio_buffer_ms)) end)
        log_info("Requested audio buffer (ms): " .. tostring(CONFIG.audio_buffer_ms))
    end

    -- input params
    local in_ch = mp.get_property_native("audio-params/channel-count") or 0
    local in_rate = mp.get_property_native("audio-params/sample-rate") or 0
    local device_rate = tonumber(mp.get_property("audio-samplerate")) or in_rate

    -- early downmix
    if in_ch > 2 then
        local pan = build_safe_downmix()
        if pan then add_filter_safe(pan); log_info("Downmixed to stereo (was " .. tostring(in_ch) .. " channels)") end
    end

    -- early resample
    local target_rate = in_rate
    if device_rate and device_rate > 0 then target_rate = device_rate end
    target_rate = math.min(target_rate, CONFIG.max_early_resample_rate)
    if in_rate > 0 and in_rate ~= target_rate then
        local s32 = CONFIG.prefer_high_precision_resample and ":osf=s32" or ""
        add_filter_safe("aresample=" .. tostring(target_rate) .. s32)
        log_info("Resampled early to " .. tostring(target_rate) .. " Hz")
    end

    -- subsonic cleanup
    add_filter_safe("highpass=f=18")

    -- loudness normalization
    add_filter_safe("loudnorm=I=-18:TP=-1.5:LRA=7:print_format=none")

    -- detect output
    local out_type = detect_output_type()
    log_info("Detected output type: " .. tostring(out_type))

    -- resolve assets
    local sofa_path = resolve_sofa()
    local ir_path = resolve_ir()

    -- Apply HRTF and IR according to detection and universal_mode
    if state.universal_mode then
        -- conservative HRTF + low-wet IR so same chain is safe for both outputs
        if sofa_path then
            local sf = build_sofalizer_filter(sofa_path, CONFIG.sofa_gain_speakers)
            if sf then add_filter_safe(sf); log_info("SOFAlizer applied (universal conservative)") end
        end
        if ir_path then
            local irf = build_ir_filter(ir_path, CONFIG.ambience_dry, CONFIG.ambience_wet_universal)
            if irf then add_filter_safe(irf); log_info("IR applied (universal conservative)") end
        end
    else
        if out_type == "headphones" then
            -- WH-1000XM5 specific tuning
            local is_xm5 = device_name_matches({ "wh-1000xm5", "xm5" }, mp.get_property("audio-device") or "")
            local gain = is_xm5 and CONFIG.sofa_gain_wh1000xm5 or CONFIG.sofa_gain_default
            if sofa_path then
                local sf = build_sofalizer_filter(sofa_path, gain)
                if sf then add_filter_safe(sf); log_info("SOFAlizer enabled (gain=" .. tostring(gain) .. ")") end
            else
                log_info("No SOFA found; HRTF skipped")
            end
            log_info("IR skipped for headphones")
        elseif out_type == "speakers" then
            -- Realtek speakers: apply short IR and conservative HRTF disabled
            if ir_path then
                local irf = build_ir_filter(ir_path, CONFIG.ambience_dry, CONFIG.ambience_wet_speakers)
                if irf then add_filter_safe(irf); log_info("IR convolution applied for speakers (wet=" .. tostring(CONFIG.ambience_wet_speakers) .. ")") end
            else
                log_info("No IR found; speaker IR skipped")
            end
            log_info("HRTF skipped for speakers by default")
        else
            -- unknown: prefer safe behavior (headphone-style HRTF with moderate gain)
            if sofa_path then
                local sf = build_sofalizer_filter(sofa_path, CONFIG.sofa_gain_default)
                if sf then add_filter_safe(sf); log_info("SOFAlizer applied (fallback)") end
            end
        end
    end

    -- EQ: apply XM5-specific extra air if WH-1000XM5 detected
    local is_xm5_device = device_name_matches({ "wh-1000xm5", "xm5" }, mp.get_property("audio-device") or "")
    local eqs = build_eq_filters(is_xm5_device)
    for _, f in ipairs(eqs) do add_filter_safe(f) end

    -- Optional dynamic processor
    if state.dynamic_active and not cpu_overloaded() then
        local dyn = build_dynamic_filter()
        if dyn then add_filter_safe(dyn); log_info("Dynamic processor enabled: " .. dyn); osd("Dynamic: ON") end
    else
        log_info("Dynamic processor disabled or CPU overloaded")
    end

    -- Transient enhancer / punch (gentle)
    add_filter_safe("acompressor=threshold=-36dB:ratio=1.6:attack=0.8:release=50:makeup=1")

    -- Final limiter
    add_filter_safe("alimiter=level_in=1:level_out=0.985:limit=0.0625")

    state.active = true
    osd("Universal IMAX: ON" .. (state.universal_mode and " (universal)" or ""))
    log_info("Universal IMAX chain applied")
end

local function remove_chain()
    log_info("Removing universal IMAX chain")
    clear_af()
    state.active = false
    osd("Universal IMAX: OFF")
end

local function toggle_chain()
    if state.active then remove_chain() else apply_chain() end
end

local function toggle_universal()
    state.universal_mode = not state.universal_mode
    osd("Universal mode: " .. (state.universal_mode and "ON" or "OFF"))
    log_info("Universal mode toggled: " .. tostring(state.universal_mode))
    if state.active then mp.add_timeout(0.05, apply_chain) end
end

local function toggle_dynamic()
    state.dynamic_active = not state.dynamic_active
    osd("Dynamic: " .. (state.dynamic_active and "ON" or "OFF"))
    log_info("Dynamic toggled: " .. tostring(state.dynamic_active))
    if state.active then mp.add_timeout(0.05, apply_chain) end
end

-- ===== mpv hooks & keybindings =====
local function on_file_loaded()
    log_info("file-loaded")
    state.active = false
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
