local options = {
    shader_path = "~~/shaders",
    shader_profiles = "",
    include_default_shader_profile = true,
    default_shader_profile_name = "Default",
    include_custom_shader_profile = true,
    show_shader_extensions = false,

    deband_profiles = "",
    include_default_deband_profile = true,
    default_deband_profile_name = "Default",
    include_custom_deband_profile = true,

    color_profiles = "",
    include_default_color_profile = true,
    default_color_profile_name = "Default",
    include_custom_color_profile = true,

    aspect_profiles = "16:9,4:3,2.35:1",
    include_default_aspect_profile = true,
    default_aspect_profile_name = "Default",
    include_custom_aspect_profile = true
}

require("mp.options").read_options(options)
local utils = require("mp.utils")

local properties = {
    aspect = {"video-aspect-override"},
    deband = {"deband", "deband-iterations", "deband-threshold", "deband-range", "deband-grain"},
    color = {"brightness", "contrast", "saturation", "gamma", "hue"},
    scale = {"tscale", "tscale-window", "tscale-antiring", "tscale-blur", "tscale-clamp", "tscale-radius",
             "tscale-taper", "scale", "scale-window", "scale-antiring", "scale-blur", "scale-clamp", "scale-radius",
             "scale-taper", "dscale", "dscale-window", "dscale-antiring", "dscale-blur", "dscale-clamp",
             "dscale-radius", "dscale-taper", "cscale", "cscale-window", "cscale-antiring", "cscale-blur",
             "cscale-clamp", "cscale-radius", "cscale-taper", "linear-upscaling", "correct-downscaling",
             "linear-downscaling", "sigmoid-upscaling"},
    dither = {"dither", "error-diffusion", "temporal-dither", "dither-depth", "dither-size-fruit",
              "temporal-dither-period"},
    extra = {"deinterlace", "hwdec", "vo", "video-sync", "interpolation"},
    shaders = {{
        name = "glsl-shaders",
        native = true
    }}
}

local current_property = {}
local default_property = {}
local cached_property = {}

local function get_property_info(prop)
    if type(prop) == "table" then
        return prop.name, prop.native
    else
        return prop, false
    end
end

local function loop_through_properties(callback)
    for _, property_list in pairs(properties) do
        for _, prop in ipairs(property_list) do
            local name, use_native = get_property_info(prop)
            callback(name, use_native)
        end
    end
end

loop_through_properties(function(name, use_native)
    local value = use_native and mp.get_property_native(name) or mp.get_property(name)
    current_property[name] = value
    default_property[name] = value
    cached_property[name] = value
end)

local function tonum_ifnum(string)
    return tonumber(string) or string
end

local function command(...)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = string.format("%q", arg)
    end
    return table.concat(args, " ")
end

mp.register_script_message("toggle-property", function(property)
    mp.set_property(property, current_property[property] == "yes" and "no" or "yes")
end)

mp.register_script_message("set-property", function(property, ...)
    local args = {...}
    if #args == 1 then
        mp.set_property(property, args[1])
    else
        mp.set_property_native(property, args)
    end
end)

mp.register_script_message("adjust-property-number", function(property, increment, min, max)
    min = tonumber(min) or -math.huge
    max = tonumber(max) or math.huge
    increment = tonumber(increment)

    local current = tonumber(current_property[property])
    local new_value

    if property == "video-aspect-override" then
        if current < 0 and increment > 0 then
            new_value = 0 + increment
        elseif current + increment <= 0 then
            new_value = -1
        end
    elseif property == "dither-depth" then
        if current_property[property] == "no" then
            new_value = increment > 0 and 0 or -1
        elseif current_property[property] == "auto" then
            new_value = increment < 0 and -1 or 0 + increment
        elseif current + increment < 0 then
            new_value = 0
        end
    end

    if not new_value then
        new_value = math.max(min, math.min(max, current + increment))
    end

    mp.set_property(property, new_value)
end)

-- Menu templates
local function create_property_toggle(name, property)
    return {
        title = name,
        icon = current_property[property] == "yes" and "check_box" or "check_box_outline_blank",
        value = command("toggle-property", property)
    }
end

local function create_property_selection(name, property, options, off_or_default_option, include_default_item,
    include_custom_item)
    local property_items = {}

    local option_hint
    local option_match = false
    local function create_option_item(name, value)
        local is_active = current_property[property] == value

        if is_active then
            option_hint = name
            option_match = true
        end

        return {
            title = name,
            active = is_active,
            value = is_active and off_or_default_option and command("set-property", property, off_or_default_option) or
                command("set-property", property, value)
        }
    end

    local default_profile_override = false
    for _, option in ipairs(options) do
        if default_property[property] == option.value then
            default_profile_override = true
        end

        table.insert(property_items, create_option_item(option.name, option.value))
    end

    if not default_profile_override and include_default_item then
        table.insert(property_items, 1, create_option_item("Default", default_property[property]))
    end

    if include_custom_item then
        if off_or_default_option ~= current_property[property] and not option_match then
            option_hint = "Custom"
        end
        table.insert(property_items, {
            title = "Custom",
            active = off_or_default_option ~= current_property[property] and not option_match,
            selectable = off_or_default_option ~= current_property[property] and not option_match,
            muted = off_or_default_option == current_property[property] or option_match,
            value = command("set-property", property, off_or_default_option)
        })
    end

    return {
        title = name,
        hint = option_hint,
        items = property_items
    }
end

local function create_property_number_adjustment(name, property, increment, min, max)
    local function create_adjustment_actions()
        return {{
            name = command("adjust-property-number", property, -increment, min, max),
            icon = "remove",
            label = "Decrease (ctrl+left)"
        }, {
            name = command("adjust-property-number", property, increment, min, max),
            icon = "add",
            label = "Increase (ctrl+right)"
        }, {
            name = command("set-property", property, cached_property[property]),
            icon = "cached",
            label = "Reset (del)"
        }}
    end

    local function create_hint()
        if property == "video-aspect-override" then
            if tonumber(current_property[property]) <= 0 then
                return "Off"
            end
        elseif property == "dither-depth" then
            if current_property[property] == "no" then
                return "Off"
            elseif current_property[property] == "auto" then
                return "Auto"
            end
        end

        return tonumber(current_property[property]) and
                   string.format("%.3f", tonumber(current_property[property])):gsub("%.?0*$", "") or
                   current_property[property]
    end

    return {
        title = name,
        hint = create_hint(),
        actions = create_adjustment_actions(),
        value = {
            ["ctrl+left"] = command("adjust-property-number", property, -increment, min, max),
            ["ctrl+right"] = command("adjust-property-number", property, increment, min, max),
            ["del"] = command("set-property", property, cached_property[property])
        },
        actions_place = "outside"
    }
end

-- Aspect override
local function create_aspect_menu()
    local aspect_items = {}
    local aspect_profiles = {}

    local profile_hint
    local profile_match = false
    local function create_aspect_profile_item(name, profile_aspect_value)
        local is_active = math.abs(tonumber(current_property["video-aspect-override"]) - profile_aspect_value) < 0.001

        if is_active then
            profile_hint = name
            profile_match = true
            cached_property["video-aspect-override"] = profile_aspect_value
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("set-property", "video-aspect-override", "-1") or
                command("set-property", "video-aspect-override", tostring(profile_aspect_value))
        }
    end

    local default_profile_override = false
    for aspect_profile in options.aspect_profiles:gmatch("([^,]+)") do
        local profile_width, profile_height = aspect_profile:match("([^:]+):([^:]+)")
        local profile_aspect_value = tonumber(profile_width) / tonumber(profile_height)

        if profile_width and profile_height then
            local is_default = math.abs(tonumber(default_property["video-aspect-override"]) - profile_aspect_value) <
                                   0.001

            if is_default then
                default_profile_override = true
            end

            table.insert(aspect_profiles, create_aspect_profile_item(aspect_profile, profile_aspect_value))
        end
    end

    if not default_profile_override and options.include_default_aspect_profile then
        table.insert(aspect_profiles, 1, create_aspect_profile_item(options.default_aspect_profile_name,
            tonumber(default_property["video-aspect-override"])))
    end

    if not default_profile_override and options.include_custom_aspect_profile then
        local is_original = tonumber(current_property["video-aspect-override"]) == -1
        if not is_original and not profile_match then
            profile_hint = "Custom"
        end
        table.insert(aspect_profiles, {
            title = "Custom",
            active = not is_original and not profile_match,
            selectable = not is_original and not profile_match,
            muted = is_original or profile_match,
            value = command("set-property", "video-aspect-override", "-1")
        })
    end

    for _, profile in ipairs(aspect_profiles) do
        table.insert(aspect_items, profile)
    end

    if #aspect_items > 0 then
        aspect_items[#aspect_items].separator = true
    end

    table.insert(aspect_items,
        create_property_number_adjustment("Video aspect override", "video-aspect-override", 0.05, -1, 10))

    if not profile_hint and tonumber(current_property["video-aspect-override"]) == -1 then
        profile_hint = "Off"
    end

    return {
        title = "Aspect override",
        hint = profile_hint,
        items = aspect_items
    }
end

-- Deband
mp.register_script_message("apply-deband-profile",
    function(profile_iterations, profile_threshold, profile_range, profile_grain)
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", profile_iterations)
        mp.set_property("deband-threshold", profile_threshold)
        mp.set_property("deband-range", profile_range)
        mp.set_property("deband-grain", profile_grain)
    end)

local function create_deband_menu()
    local deband_items = {}
    local deband_profile_items = {}

    local profile_hint
    local profile_match = false
    local function create_deband_profile_item(name, profile_iterations, profile_threshold, profile_range, profile_grain)
        local is_active = (tonumber(profile_iterations) == tonumber(current_property["deband-iterations"]) and
                              tonumber(profile_threshold) == tonumber(current_property["deband-threshold"]) and
                              tonumber(profile_range) == tonumber(current_property["deband-range"]) and
                              tonumber(profile_grain) == tonumber(current_property["deband-grain"]))

        if is_active then
            profile_match = true
            cached_property["deband-iterations"] = profile_iterations
            cached_property["deband-threshold"] = profile_threshold
            cached_property["deband-range"] = profile_range
            cached_property["deband-grain"] = profile_grain
        end

        if current_property["deband"] == "yes" and is_active then
            profile_hint = name
        end

        return {
            title = name,
            active = current_property["deband"] == "yes" and is_active,
            value = is_active and command("toggle-property", "deband") or
                command("apply-deband-profile", profile_iterations, profile_threshold, profile_range, profile_grain)

        }
    end

    local default_profile_override = false
    for deband_profile in options.deband_profiles:gmatch("([^;]+)") do
        local name, settings = deband_profile:match("(.+):(.+)")

        if name and settings then
            local profile_iterations, profile_threshold, profile_range, profile_grain = settings:match(
                "([^,]+),([^,]+),([^,]+),([^,]+)")

            if profile_iterations and profile_threshold and profile_range and profile_grain then
                local is_default = tonumber(profile_iterations) == tonumber(default_property["deband-iterations"]) and
                                       tonumber(profile_threshold) == tonumber(default_property["deband-threshold"]) and
                                       tonumber(profile_range) == tonumber(default_property["deband-range"]) and
                                       tonumber(profile_grain) == tonumber(default_property["deband-grain"])

                if is_default then
                    default_profile_override = true
                end

                table.insert(deband_profile_items, create_deband_profile_item(name, profile_iterations,
                    profile_threshold, profile_range, profile_grain))
            end
        end
    end

    if not default_profile_override and options.include_default_deband_profile then
        table.insert(deband_profile_items, 1,
            create_deband_profile_item(options.default_deband_profile_name, default_property["deband-iterations"],
                default_property["deband-threshold"], default_property["deband-range"], default_property["deband-grain"]))
    end

    if options.include_custom_deband_profile then
        if current_property["deband"] == "yes" and not profile_match then
            profile_hint = "Custom"
        end
        table.insert(deband_profile_items, {
            title = "Custom",
            active = current_property["deband"] == "yes" and not profile_match,
            selectable = not profile_match,
            muted = profile_match,
            value = command("toggle-property", "deband")
        })
    end

    for _, deband_profile_item in ipairs(deband_profile_items) do
        table.insert(deband_items, deband_profile_item)
    end

    if #deband_items > 0 then
        deband_items[#deband_items].separator = true
    end

    for _, item in ipairs({create_property_toggle("Enabled", "deband"),
                           create_property_number_adjustment("Iterations", "deband-iterations", 1, 0, 16),
                           create_property_number_adjustment("Threshold", "deband-threshold", 1, 0, 4096),
                           create_property_number_adjustment("Range", "deband-range", 1, 1, 64),
                           create_property_number_adjustment("Grain", "deband-grain", 1, 0, 4096)}) do
        table.insert(deband_items, item)
    end

    if not profile_hint then
        if current_property["deband"] == "yes" then
            profile_hint = "On"
        elseif current_property["deband"] == "no" then
            profile_hint = "Off"
        end
    end

    return {
        title = "Deband",
        hint = profile_hint,
        items = deband_items
    }
end

-- Color
mp.register_script_message("clear-color", function()
    mp.set_property("brightness", 0)
    mp.set_property("contrast", 0)
    mp.set_property("saturation", 0)
    mp.set_property("gamma", 0)
    mp.set_property("hue", 0)
end)

mp.register_script_message("apply-color-profile",
    function(profile_brightness, profile_contrast, profile_saturation, profile_gamma, profile_hue)
        mp.set_property("brightness", profile_brightness)
        mp.set_property("contrast", profile_contrast)
        mp.set_property("saturation", profile_saturation)
        mp.set_property("gamma", profile_gamma)
        mp.set_property("hue", profile_hue)
    end)

local function create_color_menu()
    local color_items = {}
    local color_profile_items = {}

    local profile_hint
    local profile_match = false
    local function create_color_profile_item(name, profile_brightness, profile_contrast, profile_saturation,
        profile_gamma, profile_hue)
        local is_active = (tonumber(profile_brightness) == tonumber(current_property["brightness"]) and
                              tonumber(profile_contrast) == tonumber(current_property["contrast"]) and
                              tonumber(profile_saturation) == tonumber(current_property["saturation"]) and
                              tonumber(profile_gamma) == tonumber(current_property["gamma"]) and tonumber(profile_hue) ==
                              tonumber(current_property["hue"]))

        if is_active then
            profile_hint = name
            profile_match = true
            cached_property["brightness"] = profile_brightness
            cached_property["contrast"] = profile_contrast
            cached_property["saturation"] = profile_saturation
            cached_property["gamma"] = profile_gamma
            cached_property["hue"] = profile_hue
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("clear-color") or
                command("apply-color-profile", profile_brightness, profile_contrast, profile_saturation, profile_gamma,
                    profile_hue)
        }
    end

    local default_profile_override = false
    for color_profile in options.color_profiles:gmatch("([^;]+)") do
        local name, settings = color_profile:match("(.+):(.+)")
        if name and settings then
            local profile_brightness, profile_contrast, profile_saturation, profile_gamma, profile_hue = settings:match(
                "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

            if profile_brightness and profile_contrast and profile_saturation and profile_gamma and profile_hue then
                local is_default = tonumber(profile_brightness) == tonumber(default_property["brightness"]) and
                                       tonumber(profile_contrast) == tonumber(default_property["contrast"]) and
                                       tonumber(profile_saturation) == tonumber(default_property["saturation"]) and
                                       tonumber(profile_gamma) == tonumber(default_property["gamma"]) and
                                       tonumber(profile_hue) == tonumber(default_property["hue"])

                if is_default then
                    default_profile_override = true
                end

                table.insert(color_profile_items, create_color_profile_item(name, profile_brightness, profile_contrast,
                    profile_saturation, profile_gamma, profile_hue))
            end
        end
    end

    if not default_profile_override and options.include_default_color_profile then
        table.insert(color_profile_items, 1,
            create_color_profile_item(options.default_color_profile_name, default_property["brightness"],
                default_property["contrast"], default_property["saturation"], default_property["gamma"],
                default_property["hue"]))
    end

    if options.include_custom_color_profile then
        local is_original = tonumber(current_property["brightness"]) == 0 and tonumber(current_property["contrast"]) ==
                                0 and tonumber(current_property["saturation"]) == 0 and
                                tonumber(current_property["gamma"]) == 0 and tonumber(current_property["hue"]) == 0
        if not is_original and not profile_match then
            profile_hint = "Custom"
        end
        table.insert(color_profile_items, {
            title = "Custom",
            active = not is_original and not profile_match,
            selectable = not is_original and not profile_match,
            muted = is_original or profile_match,
            value = command("clear-color")
        })
    end

    for _, color_profile_item in ipairs(color_profile_items) do
        table.insert(color_items, color_profile_item)
    end

    if #color_items > 0 then
        color_items[#color_items].separator = true
    end

    for _, prop in ipairs({"brightness", "contrast", "saturation", "gamma", "hue"}) do
        table.insert(color_items,
            create_property_number_adjustment(prop:gsub("^%l", string.upper), prop, 0.25, -100, 100))
    end

    return {
        title = "Color",
        hint = profile_hint,
        items = color_items
    }
end

-- Deinterlace
local deinterlace_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Auto",
    value = "auto"
}}

-- Dither
local dither_options = {{
    name = "Off",
    value = "no"
}, {
    name = "Fruit",
    value = "fruit"
}, {
    name = "Ordered",
    value = "ordered"
}, {
    name = "Error diffusion",
    value = "error-diffusion"
}}

local error_diffusion_options = {{
    name = "Simple",
    value = "simple"
}, {
    name = "False FS",
    value = "false-fs"
}, {
    name = "Sierra (lite)",
    value = "sierra-lite"
}, {
    name = "Floyd-Steinberg",
    value = "floyd-steinberg"
}, {
    name = "Atkinson",
    value = "atkinson"
}, {
    name = "Jarvis judice ninke",
    value = "jarvis-judice-ninke"
}, {
    name = "Stucki",
    value = "stucki"
}, {
    name = "Burkes",
    value = "burkes"
}, {
    name = "Sierra 3",
    value = "sierra-3"
}, {
    name = "Sierra 2",
    value = "sierra-2"
}}

local function create_dither_menu()
    local dither_items = {}
    local dither_selection = create_property_selection("Dither", "dither", dither_options)

    for _, item in ipairs(dither_selection.items) do
        table.insert(dither_items, item)
    end

    dither_items[#dither_items].separator = true

    for _, item in ipairs({create_property_selection("Error diffusion", "error-diffusion", error_diffusion_options),
                           create_property_toggle("Temporal dither", "temporal-dither"),
                           create_property_number_adjustment("Dither depth", "dither-depth", 2, -1, 16),
                           create_property_number_adjustment("Dither size (fruit)", "dither-size-fruit", 1, 2, 8),
                           create_property_number_adjustment("Temporal dither period", "temporal-dither-period", 1, 1,
        128)}) do
        table.insert(dither_items, item)
    end

    return {
        title = "Dither",
        hint = dither_selection.hint,
        items = dither_items
    }
end

-- Hardware decoding
local hwdec_options = {{
    name = "Off",
    value = "no"
}, {
    name = "Auto",
    value = "auto"
}, {
    name = "Auto (safe)",
    value = "auto-safe"
}, {
    name = "Auto (copy)",
    value = "auto-copy"
}, {
    name = "Direct3D11",
    value = "d3d11va"
}, {
    name = "Direct3D11 (copy)",
    value = "d3d11va-copy"
}, {
    name = "Video toolbox",
    value = "videotoolbox"
}, {
    name = "Video toolbox (copy)",
    value = "videotoolbox-copy"
}, {
    name = "VA-API",
    value = "vaapi"
}, {
    name = "VA-API (copy)",
    value = "vaapi-copy"
}, {
    name = "NVDEC",
    value = "nvdec"
}, {
    name = "NVDEC (copy)",
    value = "nvdec-copy"
}, {
    name = "DRM",
    value = "drm"
}, {
    name = "DRM (copy)",
    value = "drm-copy"
}, {
    name = "Vulkan",
    value = "vulkan"
}, {
    name = "Vulkan (copy)",
    value = "vulkan-copy"
}, {
    name = "DX-VA2",
    value = "dxva2"
}, {
    name = "DX-VA2 (copy)",
    value = "dxva2-copy"
}, {
    name = "VDPAU",
    value = "vdpau"
}, {
    name = "VDPAU (copy)",
    value = "vdpau-copy"
}, {
    name = "Media codec",
    value = "mediacodec"
}, {
    name = "Media codec (copy)",
    value = "mediacodec-copy"
}, {
    name = "CUDA",
    value = "cuda"
}, {
    name = "CUDA (copy)",
    value = "cuda-copy"
}, {
    name = "Crystal HD",
    value = "crystalhd"
}, {
    name = "RKMPP",
    value = "rkmpp"
}}

-- Scale
local fixed_scale = {{
    name = "Bilinear",
    value = "bilinear"
}, {
    name = "Bicubic fast",
    value = "bicubic_fast"
}, {
    name = "Oversample",
    value = "oversample"
}}

local non_polar_filter = {{
    name = "Spline16",
    value = "spline16"
}, {
    name = "Spline36",
    value = "spline36"
}, {
    name = "Spline64",
    value = "spline64"
}, {
    name = "Sinc",
    value = "sinc"
}, {
    name = "Lanczos",
    value = "lanczos"
}, {
    name = "Ginseng",
    value = "ginseng"
}, {
    name = "Bicubic",
    value = "bicubic"
}, {
    name = "Hermite",
    value = "hermite"
}, {
    name = "Catmull rom",
    value = "catmull_rom"
}, {
    name = "Mitchell",
    value = "mitchell"
}, {
    name = "Robidoux",
    value = "robidoux"
}, {
    name = "Robidoux sharp",
    value = "robidouxsharp"
}, {
    name = "Box",
    value = "box"
}, {
    name = "Nearest",
    value = "nearest"
}, {
    name = "Triangle",
    value = "triangle"
}, {
    name = "Gaussian",
    value = "gaussian"
}}

local polar_filter = {{
    name = "Jinc",
    value = "jinc"
}, {
    name = "EWA lanczos",
    value = "ewa_lanczos"
}, {
    name = "EWA hanning",
    value = "ewa_hanning"
}, {
    name = "EWA ginseng",
    value = "ewa_ginseng"
}, {
    name = "EWA lanczos sharp",
    value = "ewa_lanczossharp"
}, {
    name = "EWA lanczos 4 sharpest",
    value = "ewa_lanczos4sharpest"
}, {
    name = "EWA lanczos soft",
    value = "ewa_lanczossoft"
}, {
    name = "Haasnsoft",
    value = "haasnsoft"
}, {
    name = "EWA robidoux",
    value = "ewa_robidoux"
}, {
    name = "EWA robidoux sharp",
    value = "ewa_robidouxsharp"
}}

local filter_windows = {{
    name = "Bartlett",
    value = "bartlett"
}, {
    name = "Cosine",
    value = "cosine"
}, {
    name = "Hanning",
    value = "hanning"
}, {
    name = "Tukey",
    value = "tukey"
}, {
    name = "Hamming",
    value = "hamming"
}, {
    name = "Quadric",
    value = "quadric"
}, {
    name = "Welch",
    value = "welch"
}, {
    name = "Kaiser",
    value = "kaiser"
}, {
    name = "Blackman",
    value = "blackman"
}, {
    name = "Sphinx",
    value = "sphinx"
}}

local function get_scale_filters()
    local scale_filters = {}

    for _, list in ipairs({fixed_scale, non_polar_filter, polar_filter, filter_windows}) do
        for _, value in ipairs(list) do
            table.insert(scale_filters, value)
        end
    end

    return scale_filters
end

local function get_tscale_filters()
    local tscale_filters = {}

    table.insert(tscale_filters, {
        name = "Oversample",
        value = "oversample"
    })

    table.insert(tscale_filters, {
        name = "Linear",
        value = "linear"
    })

    for _, list in ipairs({non_polar_filter, filter_windows}) do
        for _, value in ipairs(list) do
            table.insert(tscale_filters, value)
        end
    end

    table.insert(tscale_filters, {
        name = "Jinc",
        value = "jinc"
    })

    return tscale_filters
end

local function get_extended_filter_windows()
    local extended_filter_windows = {}

    for _, value in ipairs(filter_windows) do
        table.insert(extended_filter_windows, value)
    end

    table.insert(extended_filter_windows, {
        name = "Jinc",
        value = "jinc"
    })

    return extended_filter_windows
end

local function create_scale_number_adjustments(property)
    return create_property_number_adjustment("Antiring", property .. "-antiring", .005, 0, 1),
        create_property_number_adjustment("Blur", property .. "-blur", .005),
        create_property_number_adjustment("Clamp", property .. "-clamp", .005, 0, 1),
        create_property_number_adjustment("Radius", property .. "-radius", .005, .5, 16),
        create_property_number_adjustment("Taper", property .. "-taper", .005, 0, 1)
end

local function create_scale_menu()
    local scale_items = {}

    table.insert(scale_items, {
        title = "Upscale",
        items = {create_property_selection("Filters", "scale", get_scale_filters()),
                 create_property_selection("Filters (window)", "scale-window", get_extended_filter_windows(), ""),
                 create_scale_number_adjustments("scale")}
    })

    table.insert(scale_items, {
        title = "Downscale",
        items = {create_property_selection("Filters", "dscale", get_scale_filters(), ""),
                 create_property_selection("Filters (window)", "dscale-window", get_extended_filter_windows(), ""),
                 create_scale_number_adjustments("dscale")}
    })

    table.insert(scale_items, {
        title = "Chromascale",
        items = {create_property_selection("Filters", "cscale", get_scale_filters(), ""),
                 create_property_selection("Filters (window)", "cscale-window", get_extended_filter_windows(), ""),
                 create_scale_number_adjustments("cscale")}
    })
    table.insert(scale_items, {
        title = "Temporalscale",
        items = {create_property_selection("Filters", "tscale", get_tscale_filters()),
                 create_property_selection("Filters (window)", "tscale-window", get_extended_filter_windows(), ""),
                 create_scale_number_adjustments("tscale")}
    })

    for _, item in ipairs({create_property_toggle("Linear upscaling", "linear-upscaling"),
                           create_property_toggle("Correct downscaling", "correct-downscaling"),
                           create_property_toggle("Linear downscaling", "linear-downscaling"),
                           create_property_toggle("Sigmoid upscaling", "sigmoid-upscaling")}) do
        table.insert(scale_items, item)
    end

    return {
        title = "Scale",
        items = scale_items
    }
end

-- Shaders
local function compare_shaders(shaders1, shaders2)
    if #shaders1 ~= #shaders2 then
        return false
    end

    for i, shader in ipairs(shaders1) do
        if shader ~= shaders2[i] then
            return false
        end
    end

    return true
end

local function file_exists(path)
    local file_info = utils.file_info(mp.command_native({"expand-path", path}))

    if file_info and file_info.is_file then
        return true
    end

    return false
end

local function get_active_shaders(shaders)
    local active_shaders = {}

    for i, path in ipairs(shaders) do
        if file_exists(path) then
            table.insert(active_shaders, path)
        end
    end

    setmetatable(active_shaders, {
        __index = function(active_shaders, shader_path)
            for i, active_shader in ipairs(active_shaders) do
                if active_shader == shader_path then
                    return i
                end
            end

            return false
        end
    })

    return active_shaders
end

local function create_shader_adjustment_actions(shader_path, active_shader_group)
    local action_items = {}

    table.insert(action_items, {
        name = command("move-shader", shader_path, "up"),
        icon = "arrow_upward",
        label = active_shader_group and "Move up (ctrl+up/pgup/home)" or "Move up (ctrl+left)",
        filter_hidden = active_shader_group and true
    })

    table.insert(action_items, {
        name = command("move-shader", shader_path, "down"),
        icon = "arrow_downward",
        label = active_shader_group and "Move down (ctrl+down/pgdn/end)" or "Move down (ctrl+right)",
        filter_hidden = active_shader_group and true
    })

    if active_shader_group then
        table.insert(action_items, {
            name = command("toggle-shader", shader_path),
            icon = "delete",
            label = "Remove (del)"
        })
    end

    return action_items
end

local function read_directory(path)
    local directory_items = utils.readdir(path)
    local files, directories = {}, {}

    for _, item in ipairs(directory_items) do
        if file_exists(utils.join_path(path, item)) then
            files[#files + 1] = item
        else
            directories[#directories + 1] = item
        end
    end

    return files, directories
end

local function list_shader_files(path)
    local active_shaders = get_active_shaders(current_property["glsl-shaders"])

    local dir_items = {}

    local dirs_to_process = {{
        path = path,
        parent_item = dir_items
    }}
    while #dirs_to_process > 0 do
        local current_dir = table.remove(dirs_to_process)
        local files, subdirs = read_directory(mp.command_native({"expand-path", current_dir.path}))

        if subdirs then
            for _, subdir in ipairs(subdirs) do
                local subdir_item = {
                    title = subdir,
                    items = {}
                }
                table.insert(current_dir.parent_item, subdir_item)
                table.insert(dirs_to_process, {
                    path = utils.join_path(current_dir.path, subdir),
                    parent_item = subdir_item.items
                })
            end
        end

        if files then
            local shader_file_paths = {}
            for _, shader_file in ipairs(files) do
                table.insert(shader_file_paths, utils.join_path(current_dir.path, shader_file))
            end

            for _, shader_file_path in ipairs(shader_file_paths) do
                local _, shader_name = utils.split_path(shader_file_path)
                table.insert(current_dir.parent_item, {
                    title = not options.show_shader_extensions and shader_name:match("(.+)%.[^.]+$") or shader_name,
                    hint = active_shaders[shader_file_path] and tostring(active_shaders[shader_file_path]),
                    icon = active_shaders[shader_file_path] and "check_box" or "check_box_outline_blank",
                    value = {
                        ["activate"] = command("toggle-shader", shader_file_path),
                        ["ctrl+left"] = command("move-shader", shader_file_path, "up"),
                        ["ctrl+right"] = command("move-shader", shader_file_path, "down")
                    },
                    actions = active_shaders[shader_file_path] and create_shader_adjustment_actions(shader_file_path),
                    actions_place = "outside"
                })
            end
        end
    end

    return dir_items
end

mp.register_script_message("clear-shaders", function()
    mp.set_property_native("glsl-shaders", {})
end)

local function toggle_shader(shader_path)
    if file_exists(shader_path) then
        mp.command_native({"change-list", "glsl-shaders", "toggle", shader_path})
    end
end
mp.register_script_message("toggle-shader", toggle_shader)

local function move_shader(shader, direction_or_index)
    local active_shaders = get_active_shaders(current_property["glsl-shaders"])

    if type(shader) == "number" then
        for i, current_shader in ipairs(current_property["glsl-shaders"]) do
            if active_shaders[shader] == current_shader then
                shader = current_shader
                break
            end
        end
    end

    local target_index
    for i, active_path in ipairs(active_shaders) do
        if active_path == shader then
            target_index = i
            break
        end
    end

    if not target_index then
        return
    end

    table.remove(active_shaders, target_index)
    local new_position = (direction_or_index == "up" and target_index - 1) or
                             (direction_or_index == "down" and target_index + 1) or tonumber(direction_or_index)
    table.insert(active_shaders, math.max(1, math.min(new_position, #active_shaders + 1)), shader)

    local new_shaders = {}
    local active_index = 1
    for i, current_shader in ipairs(current_property["glsl-shaders"]) do
        if active_shaders[current_shader] then
            new_shaders[i] = active_shaders[active_index]
            active_index = active_index + 1
        else
            new_shaders[i] = current_shader
        end
    end

    mp.set_property_native("glsl-shaders", new_shaders)
end
mp.register_script_message("move-shader", move_shader)

local function create_shader_menu()
    local active_shaders = get_active_shaders(current_property["glsl-shaders"])

    local shader_items = {}
    local shader_profile_items = {}

    local profile_hint
    local profile_match = false
    local function create_shader_profile_item(name, profile_shader_list)
        local is_active = compare_shaders(active_shaders, get_active_shaders(profile_shader_list))

        if is_active then
            profile_hint = name
            profile_match = true
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("clear-shaders") or
                command("set-property", "glsl-shaders", table.unpack(profile_shader_list))
        }
    end

    local default_profile_override = false
    for shader_profile in options.shader_profiles:gmatch("([^;]+)") do
        local name, shaders = shader_profile:match("(.+):(.+)")

        if name and shaders then
            local profile_shader_list = {}
            for shader in shaders:gmatch("([^,]+)") do
                table.insert(profile_shader_list, shader)
            end

            local is_default = compare_shaders(get_active_shaders(profile_shader_list),
                get_active_shaders(default_property["glsl-shaders"]))
            if is_default then
                default_profile_override = true
            end

            table.insert(shader_profile_items, create_shader_profile_item(name, profile_shader_list))
        end
    end

    if not default_profile_override and options.include_default_shader_profile then
        table.insert(shader_profile_items, 1,
            create_shader_profile_item(options.default_shader_profile_name, default_property["glsl-shaders"]))
    end

    if options.include_custom_shader_profile then
        if #active_shaders > 0 and not profile_match then
            profile_hint = "Custom"
        end
        table.insert(shader_profile_items, {
            title = "Custom",
            active = #active_shaders > 0 and not profile_match,
            selectable = #active_shaders > 0 and not profile_match,
            muted = #active_shaders == 0 or profile_match,
            value = command("clear-shaders")
        })
    end

    for _, shader_profile_item in ipairs(shader_profile_items) do
        table.insert(shader_items, shader_profile_item)
    end

    if #shader_items > 0 then
        shader_items[#shader_items].separator = true
    end

    local shader_files = list_shader_files(options.shader_path)

    local active_shader_group = {
        title = "Active",
        items = {},
        separator = #shader_files > 0 and true,
        footnote = "Paste path to toggle. ctrl+up/down/pgup/pgdn/home/end to reorder.",
        on_move = "callback",
        on_paste = "callback"
    }

    for i, active_shader in ipairs(active_shaders) do
        local _, shader_name = utils.split_path(active_shader)
        table.insert(active_shader_group.items, {
            title = not options.show_shader_extensions and shader_name:match("(.+)%.[^.]+$") or shader_name,
            hint = tostring(i),
            value = {
                ["del"] = command("toggle-shader", active_shader)
            },
            actions = create_shader_adjustment_actions(active_shader, true)
        })
    end

    table.insert(shader_items, active_shader_group)

    for _, item in ipairs(shader_files) do
        table.insert(shader_items, item)
    end

    return {
        title = "Shaders",
        hint = profile_hint,
        items = shader_items
    }
end

-- Video output
local video_output_options = {{
    name = "GPU",
    value = "gpu"
}, {
    name = "GPU Next",
    value = "gpu-next"
}}

-- Video sync
local video_sync_options = {{
    name = "Audio",
    value = "audio"
}, {
    name = "Display resample",
    value = "display-resample"
}, {
    name = "Display resample (vdrop)",
    value = "display-resample-vdrop"
}, {
    name = "Display resample (desync)",
    value = "display-resample-desync"
}, {
    name = "Display (tempo)",
    value = "display-tempo"
}, {
    name = "Display (vdrop)",
    value = "display-vdrop"
}, {
    name = "Display (adrop)",
    value = "display-adrop"
}, {
    name = "Display (desync)",
    value = "display-desync"
}, {
    name = "Desync",
    value = "desync"
}}

local menu_data
local function create_menu_data()
    local menu_items = {create_aspect_menu(), create_deband_menu(), create_color_menu(), create_shader_menu(),
                        create_property_toggle("Interpolation", "interpolation")}

    local advanced_items = {
        title = "Advanced",
        items = {create_property_selection("Deinterlace", "deinterlace", deinterlace_options), create_dither_menu(),
                 create_property_selection("Hardware decoding", "hwdec", hwdec_options), create_scale_menu(),
                 create_property_selection("Video output", "vo", video_output_options),
                 create_property_selection("Video sync", "video-sync", video_sync_options)}
    }

    if #menu_items > 0 and #advanced_items.items > 0 then
        menu_items[#menu_items].separator = true
        table.insert(menu_items, advanced_items)
    end

    return {
        type = "video_settings",
        title = "Video settings",
        items = menu_items,
        search_submenus = true,
        callback = {mp.get_script_name(), 'menu-event'}
    }
end

local debounce_timer
local function update_menu()
    if debounce_timer then
        debounce_timer:kill()
    end
    debounce_timer = mp.add_timeout(0.001, function()
        menu_data = utils.format_json(create_menu_data())
        mp.commandv("script-message-to", "uosc", "update-menu", menu_data)
        debounce_timer = nil
    end)
end

local function update_property(name, value)
    current_property[name] = value
    update_menu()
end

loop_through_properties(function(name, use_native)
    mp.observe_property(name, use_native and "native" or "string", update_property)
end)

mp.register_script_message("menu-event", function(json)
    local function execute_command(command)
        return mp.command(string.format("%q %q %s", "script-message-to", mp.get_script_name(), command))
    end

    local event = utils.parse_json(json)
    if event.type == "activate" then
        if event.action then
            execute_command(event.action)
        elseif event.value and event.value["activate"] then
            execute_command(event.value["activate"])
        elseif type(event.value) == "string" then
            execute_command(event.value)
        end
    elseif event.type == "key" then
        if event.selected_item.value and event.selected_item.value[event.id] then
            execute_command(event.selected_item.value[event.id])
        end
    elseif event.menu_id == "Shaders > Active" then
        if event.type == "move" then
            move_shader(event.from_index, event.to_index)
        elseif event.type == "paste" then
            toggle_shader(event.value:gsub('^[\'"]', ''):gsub('[\'"]$', ''))
        end
    end
end)

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", menu_data)
end)
