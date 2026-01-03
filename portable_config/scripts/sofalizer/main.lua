-- main.lua — IMAX-like audio chain with safe toggles and OSD
-- Place in: mpv/scripts/main.lua
-- Optional config: mpv/script-opts/imax.conf

local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'

-- Script options (edit via script-opts/imax.conf)
local o = {
    enable_on_start = "no",           -- "yes" to auto-enable IMAX chain at start
    universal_default = "no",         -- "yes" to start in universal mode
    sofa_path = "",                   -- Absolute path to your SOFA HRTF, e.g. C:/HRTF/kemar.sofa or /home/you/kemar.sofa
    ir_gain_db = 0.0,                 -- Gain applied to convolution output
    stage_widen_amount = 0.25,        -- 0..1 amount for stereo stage widening (psychoacoustic)
    tilt_db_per_oct = -0.5,           -- Gentle spectral tilt for cinema-like warmth (-0.5 dB/oct default)
    dp_target_i = -20.0,              -- Dynamic processor "speech" loudness target (LUFS-ish), higher = louder
    dp_max_gain_db = 6.0,             -- Max upward gain applied by dynamic processor
    dp_release_ms = 250,              -- Release time for dynamic processor
    device_whitelist = "",            -- Comma list of AOs to allow (e.g., "wasapi,pulse,alsa"); empty = allow all
    write_logs = "yes",               -- "yes" to write inspection logs
}
options.read_options(o, "imax")

-- State
local state = {
    baseline_af = nil,          -- saved baseline af graph
    imax_enabled = false,
    dp_enabled = false,
    universal_mode = (o.universal_default == "yes"),
}

-- Utils
local function osd(text)
    mp.commandv("show-text", text, 2500)
end

local function get_af()
    return mp.get_property_native("af")
end

local function set_af(list)
    mp.set_property_native("af", list or {})
end

local function has_id(list, id)
    for _, f in ipairs(list or {}) do
        if f.label == id then return true end
    end
    return false
end

local function remove_id(list, id)
    local out = {}
    for _, f in ipairs(list or {}) do
        if f.label ~= id then table.insert(out, f) end
    end
    return out
end

local function push_filter(list, id, name, params)
    -- Dedup by label; returns new list
    local out = remove_id(list, id)
    local f = { name = name, label = id }
    if params then f.params = params end
    table.insert(out, f)
    return out
end

local function device_allowed()
    if state.universal_mode then return true end
    if o.device_whitelist == "" then return true end
    local allowed = {}
    for entry in string.gmatch(o.device_whitelist, "([^,]+)") do
        allowed[entry:lower():gsub("%s+", "")] = true
    end
    local ao = (mp.get_property("audio-driver") or ""):lower()
    return allowed[ao] == true
end

local function snapshot_baseline()
    if not state.baseline_af then
        state.baseline_af = get_af() or {}
        msg.info("Baseline AF snapshot captured.")
    end
end

local function restore_baseline()
    if state.baseline_af then
        set_af(state.baseline_af)
        msg.info("Baseline AF restored.")
        osd("Audio filters: baseline restored")
    else
        set_af({})
        msg.warn("No baseline snapshot; cleared AF.")
        osd("Audio filters: cleared")
    end
end

-- Stage builders

-- 1) Convolution HRTF via af=aconv/afir (mpv/libavfilter: 'afir' IR convolution)
local function build_convolution(list)
    if o.sofa_path == nil or o.sofa_path == "" then
        msg.warn("SOFA path not set; skipping convolution.")
        return list
    end
    -- Use 'afir' for stereo convolution. SOFA is usually handled via external preprocessing;
    -- if your mpv build supports SOFA directly, swap to 'sofalizer' with appropriate params.
    -- Here we assume an IR pair extracted from SOFA or a compatible file.
    -- Replace as needed: ir=left.wav:ir_channel=FL and ir=right.wav for BRIR pairs.
    -- For direct SOFA with sofalizer (if available): name='sofalizer' params={ ... }
    local id = "imax.convolution"
    local params = {
        -- Example: file='C:/HRTF/kemar_stereo.wav' channel mapping as needed
        -- If you have sofalizer: use params like 'sofa=C:/HRTF/kemar.sofa azim=0 elev=0'
        -- For generic clarity, we keep afir with gain
        g = tostring(o.ir_gain_db)
    }
    -- Note: 'afir' usually requires 'ir' parameter; keep this as a placeholder until you set it.
    -- If you already have a BRIR file, set f.params.ir below:
    params.ir = o.sofa_path -- repurpose for your IR/BRIR path
    return push_filter(list, id, "afir", params)
end

-- 2) Stage widening (psychoacoustic image spread without phase collapse)
local function build_widen(list)
    local id = "imax.widen"
    -- Simple widening via 'stereowiden' or 'bs2b'/matrix; we use 'stereowiden' if present.
    -- mpv exposes FFmpeg's 'stereowiden' through 'stereotools' depending on build.
    -- Fallback to 'stereotools' with 'level_in/level_out', 'balance', 'softclip'.
    local params = {
        mlev = tostring(o.stage_widen_amount) -- typical control in stereowiden/steretools variants
    }
    -- If your build uses 'stereotools':
    -- return push_filter(list, id, "stereotools", { S="1", M="0", phase = "0.0", softclip="0" })
    return push_filter(list, id, "stereowiden", params)
end

-- 3) Gentle spectral tilt for cinema tone (tilt EQ)
local function build_tilt(list)
    local id = "imax.tilt"
    -- Implement tilt via 'firequalizer' with frequency-dependent slope
    -- Approximate -0.5 dB/oct over 20 Hz–20 kHz
    local slope = o.tilt_db_per_oct
    local eq = string.format(
        "gain='if(f<100, %.2f*(log2(100/f)), if(f>1000, %.2f*(log2(f/1000)), 0))'",
        slope, slope
    )
    return push_filter(list, id, "firequalizer", { gain = eq, zero_phase = "on", accurately = "on" })
end

-- Dynamic processor (transparent)
local function build_dynamic_processor(list)
    local id = "imax.dp"
    -- Use 'acompressor' with gentle settings approximating loudness leveling
    local params = {
        level_in = "1.0",
        threshold = tostring(o.dp_target_i) .. "dB", -- conceptual target; compressor interprets threshold in dBFS
        ratio = "2.0",
        attack = "5",
        release = tostring(o.dp_release_ms),
        makeup = tostring(o.dp_max_gain_db),
        knee = "6",
        link = "average",
    }
    return push_filter(list, id, "acompressor", params)
end

-- Build IMAX chain (order matters)
local function build_imax_chain(current)
    local list = current or {}
    list = build_convolution(list)
    list = build_widen(list)
    list = build_tilt(list)
    return list
end

-- Toggle handlers
local function enable_imax()
    if not device_allowed() then
        osd("IMAX chain blocked by device rule (toggle universal mode with F11)")
        msg.warn("IMAX chain not enabled: device not allowed and universal_mode=off")
        return
    end
    snapshot_baseline()
    local af = get_af() or {}

    -- Apply chain, dedup by labels
    af = build_imax_chain(af)
    set_af(af)
    state.imax_enabled = true
    osd("IMAX chain: enabled")
    msg.info("IMAX chain enabled.")
end

local function disable_imax()
    local af = get_af() or {}
    af = remove_id(af, "imax.convolution")
    af = remove_id(af, "imax.widen")
    af = remove_id(af, "imax.tilt")
    set_af(af)
    state.imax_enabled = false
    osd("IMAX chain: disabled")
    msg.info("IMAX chain disabled.")
end

local function toggle_imax()
    if state.imax_enabled then disable_imax() else enable_imax() end
end

local function enable_dp()
    snapshot_baseline()
    local af = get_af() or {}
    af = build_dynamic_processor(af)
    set_af(af)
    state.dp_enabled = true
    osd("Dynamic processor: enabled")
    msg.info("Dynamic processor enabled.")
end

local function disable_dp()
    local af = get_af() or {}
    af = remove_id(af, "imax.dp")
    set_af(af)
    state.dp_enabled = false
    osd("Dynamic processor: disabled")
    msg.info("Dynamic processor disabled.")
end

local function toggle_dp()
    if state.dp_enabled then disable_dp() else enable_dp() end
end

local function toggle_universal()
    state.universal_mode = not state.universal_mode
    osd("Universal mode: " .. (state.universal_mode and "on" or "off"))
    msg.info("Universal mode is now " .. (state.universal_mode and "ON" or "OFF"))
end

-- Filter inspection and logging
local function describe_af()
    local af = get_af() or {}
    local lines = {}
    table.insert(lines, string.format("IMAX:%s DP:%s UNIV:%s",
        state.imax_enabled and "on" or "off",
        state.dp_enabled and "on" or "off",
        state.universal_mode and "on" or "off"
    ))
    for i, f in ipairs(af) do
        local s = string.format("%02d: name=%s label=%s", i, f.name or "?", f.label or "")
        if f.params then
            local kv = {}
            for k, v in pairs(f.params) do table.insert(kv, k .. "=" .. tostring(v)) end
            s = s .. " params{" .. table.concat(kv, ", ") .. "}"
        end
        table.insert(lines, s)
    end
    local text = table.concat(lines, "\n")
    msg.info("AF graph:\n" .. text)
    osd("AF graph logged to console")

    if o.write_logs == "yes" then
        local dir = mp.find_config_file("scripts") -- best-effort; logs to scripts dir
        local ts = os.date("%Y%m%d-%H%M%S")
        local path = (dir or "") .. "/imax-af-" .. ts .. ".log"
        local fh = io.open(path, "w")
        if fh then
            fh:write(text .. "\n")
            fh:close()
            msg.info("Wrote AF log: " .. path)
        else
            msg.warn("Failed to write AF log.")
        end
    end
end

-- Baseline rollback (explicit)
local function rollback_all()
    disable_dp()
    disable_imax()
    restore_baseline()
end

-- Keybindings
mp.add_key_binding("F9", "imax-toggle", toggle_imax)
mp.add_key_binding("F10", "imax-dp-toggle", toggle_dp)
mp.add_key_binding("F11", "imax-universal-toggle", toggle_universal)
mp.add_key_binding("F12", "imax-inspect", describe_af)

-- Lifecycle
mp.register_event("file-loaded", function()
    msg.info("File loaded; IMAX script active.")
    state.baseline_af = nil -- new file gets new baseline
    if o.enable_on_start == "yes" then
        enable_imax()
    else
        osd("IMAX script ready (F9–F12).")
    end
end)

mp.register_event("end-file", function()
    -- Clean up per-file state; do not auto-restore baseline across files
    msg.info("End of file; state cleared.")
    state.imax_enabled = false
    state.dp_enabled = false
end)

-- Optional command for rollback from console: script-message imax-rollback
mp.register_script_message("imax-rollback", rollback_all)
