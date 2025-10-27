local options = {
    style_profiles = "",
    style_color_profiles = "",
    style_fonts = "",
    include_default_style_profile = true,
    default_style_profile_name = "Default",
    include_custom_style_profile = true
}

require("mp.options").read_options(options)
local utils = require("mp.utils")

local properties = {
    extra = {"sub-delay", "sub-ass-override", "blend-subtitles", "sub-fix-timing"},
    style = {"sub-color", "sub-back-color", "sub-font", "sub-font-size", "sub-blur", "sub-bold", "sub-italic",
             "sub-outline-color", "sub-outline-size", "sub-border-style", "sub-scale", "sub-pos", "secondary-sub-pos",
             "sub-margin-x", "sub-margin-y", "sub-align-x", "sub-align-y", "sub-use-margins", "sub-spacing",
             "sub-shadow-offset"}
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
        if property == "sub-delay" and tonumber(current_property[property]) == 0 then
            return "Off"
        elseif property == "sub-spacing" and tonumber(current_property[property]) == 0 then
            return "Off"
        elseif property == "sub-outline-size" and tonumber(current_property[property]) == 0 then
            return "Off"
        elseif property == "sub-shadow-offset" and tonumber(current_property[property]) == 0 then
            return "Off"
        elseif property == "sub-blur" and tonumber(current_property[property]) == 0 then
            return "Off"
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

-- Style
local positions = {
    A = {1, 2},
    R = {3, 4},
    G = {5, 6},
    B = {7, 8}
}

local function get_hex_component(hex, component)
    hex = hex:gsub("#", "")
    local pos = positions[component:upper()]
    return hex:sub(pos[1], pos[2])
end

mp.register_script_message("adjust-color-property-number", function(property, component, increment, new_value)
    local hex = current_property[property]:gsub("#", "")
    local pos = positions[component:upper()]

    if increment ~= "nil" then
        new_value = tonumber(hex:sub(pos[1], pos[2]), 16) + increment
        if new_value > 255 then
            new_value = 255
        elseif new_value < 0 then
            new_value = 0
        end
        new_value = string.format("%02X", new_value)
    end

    local new_hex = hex:sub(1, pos[1] - 1) .. new_value .. hex:sub(pos[2] + 1)
    mp.set_property(property, "#" .. new_hex)
end)

local function create_color_property_number_adjustment(name, property, increment)
    local function create_adjustment_actions(component)
        return {{
            name = command("adjust-color-property-number", property, component, -increment),
            icon = "remove",
            label = "Decrease (ctrl+left)"
        }, {
            name = command("adjust-color-property-number", property, component, increment),
            icon = "add",
            label = "Increase (ctrl+right)"
        }, {
            name = command("adjust-color-property-number", property, component, "nil",
                get_hex_component(cached_property[property], component)),
            icon = "cached",
            label = "Reset (del)"
        }}
    end

    local function create_bind_values(component)
        return {
            ["ctrl+left"] = command("adjust-color-property-number", property, component, -increment),
            ["ctrl+right"] = command("adjust-color-property-number", property, component, increment),
            ["del"] = command("adjust-color-property-number", property, component, "nil",
                get_hex_component(cached_property[property], component))
        }
    end

    local color_items = {}

    local style_color_options = {}
    for style_color_profile in options.style_color_profiles:gmatch("([^,]+)") do
        local color_name, color = style_color_profile:match("([^:]+):([^:]+)")
        if color_name and color then
            color = "#" .. color:gsub("#", "")
            table.insert(style_color_options, {
                name = color_name,
                value = color
            })
        end
    end

    local color_selection = create_property_selection("", property, style_color_options, cached_property[property],
        false, true)

    for _, item in ipairs(color_selection.items) do
        table.insert(color_items, item)
    end

    if #color_items > 0 then
        color_items[#color_items].separator = true
    end

    for _, component in ipairs({"Alpha", "Red", "Green", "Blue"}) do
        local component_letter = component:sub(1, 1)
        table.insert(color_items, {
            title = component,
            hint = tostring(tonumber(get_hex_component(current_property[property], component_letter), 16)),
            value = create_bind_values(component_letter),
            actions = create_adjustment_actions(component_letter)
        })
    end

    return {
        title = name,
        hint = current_property[property],
        items = color_items,
        item_actions_place = "outside"
    }
end

mp.register_script_message("clear-style", function(profile_options)
    for _, prop in ipairs(properties.style) do
        local name = get_property_info(prop)
        mp.set_property(name, default_property[name])
    end
end)

mp.register_script_message("apply-style-profile", function(profile_options)
    for _, prop in ipairs(properties.style) do
        local name = get_property_info(prop)

        local option_checked = false
        for option in profile_options:gmatch("([^,]+)") do
            local option, value = option:match("([^=]+)=(.+)")
            if option and value and option == name then
                option_checked = true
                mp.set_property(name, tonum_ifnum(value))
            end
        end

        if not option_checked then
            mp.set_property(name, default_property[name])
        end
    end
end)

local sub_border_style_options = {{
    name = "Outline & shadow",
    value = "outline-and-shadow"
}, {
    name = "Opaque box",
    value = "opaque-box"
}, {
    name = "Background box",
    value = "background-box"
}}

local sub_align_x_options = {{
    name = "Left",
    value = "left"
}, {
    name = "Center",
    value = "center"
}, {
    name = "Right",
    value = "right"
}}

local sub_align_y_options = {{
    name = "Top",
    value = "top"
}, {
    name = "Center",
    value = "center"
}, {
    name = "Bottom",
    value = "bottom"
}}

local function create_style_menu()
    local style_items = {}

    local style_hint
    local profile_match = false
    local function create_style_profile_item(name, profile_options)
        local is_active = true

        for _, prop in ipairs(properties.style) do
            local name = get_property_info(prop)

            local option_checked = false
            for option in profile_options:gmatch("([^,]+)") do
                local option, value = option:match("([^=]+)=(.+)")
                if option and value and option == name then
                    option_checked = true
                    if tonum_ifnum(value) ~= tonum_ifnum(current_property[name]) then
                        is_active = false
                    end
                end
            end

            if not option_checked and tonum_ifnum(default_property[name]) ~= tonum_ifnum(current_property[name]) then
                is_active = false
            end
        end

        if is_active then
            profile_match = true
            style_hint = name
            for _, prop in ipairs(properties.style) do
                local name = get_property_info(prop)
                for option in profile_options:gmatch("([^,]+)") do
                    local option, value = option:match("([^=]+)=(.+)")
                    if option and value and option == name then
                        cached_property[name] = current_property[name]
                    end
                end
            end
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("clear-style", profile_options) or
                command("apply-style-profile", profile_options)
        }
    end

    local default_profile_override = false
    for style_profile in options.style_profiles:gmatch("([^;]+)") do
        local profile_name, profile_options = style_profile:match("([^:]+):?(.*)")

        local is_default = true
        if profile_options and profile_options ~= "" then
            for _, prop in ipairs(properties.style) do
                local name = get_property_info(prop)

                local option_checked = false
                for option in profile_options:gmatch("([^,]+)") do
                    local option, value = option:match("([^=]+)=(.+)")
                    if option and value and option == name then
                        option_checked = true
                        if tonum_ifnum(value) ~= tonum_ifnum(default_property[name]) then
                            is_default = false
                        end
                    end
                end

                if not option_checked and tonum_ifnum(default_property[name]) ~= tonum_ifnum(current_property[name]) then
                    is_default = false
                end
            end

            if is_default then
                default_profile_override = true
            end

            table.insert(style_items, create_style_profile_item(profile_name, profile_options))
        end
    end

    if not default_profile_override and options.include_default_style_profile then
        local default_options = ""
        for _, prop in ipairs(properties.style) do
            local name = get_property_info(prop)
            default_options = default_options .. name .. "=" .. default_property[name] .. ","
        end
        table.insert(style_items, 1, create_style_profile_item(options.default_style_profile_name, default_options))
    end

    if options.include_custom_style_profile then
        if not profile_match then
            style_hint = "Custom"
        end

        table.insert(style_items, {
            title = "Custom",
            active = not profile_match,
            selectable = not profile_match,
            muted = profile_match,
            value = command("clear-style")
        })
    end

    if #style_items > 0 then
        style_items[#style_items].separator = true
    end

    local sub_font_options = {}
    for style_font in options.style_fonts:gmatch("([^,]+)") do
        local font_name, font = style_font:match("([^:]+):([^:]+)")
        if font_name and font then
            table.insert(sub_font_options, {
                name = font_name,
                value = font
            })
        end
    end

    for _, item in ipairs({{
        title = "Placement",
        items = {create_property_selection("Align (x)", "sub-align-x", sub_align_x_options),
                 create_property_selection("Align (y)", "sub-align-y", sub_align_y_options),
                 create_property_toggle("Use margins", "sub-use-margins"),
                 create_property_number_adjustment("Position (primary)", "sub-pos", 0.05, 0, 100),
                 create_property_number_adjustment("Position (secondary)", "secondary-sub-pos", 0.05, 0, 100),
                 create_property_number_adjustment("Margin (x)", "sub-margin-x", 1, 0),
                 create_property_number_adjustment("Margin (y)", "sub-margin-y", 1, 0)}
    }, create_property_selection("Font", "sub-font", sub_font_options, "sans-serif", true, true),
                           create_color_property_number_adjustment("Color", "sub-color", "1"),
                           create_color_property_number_adjustment("Outline color", "sub-outline-color", "1"),
                           create_color_property_number_adjustment("Shadow color", "sub-back-color", "1"),
                           create_property_selection("Border style", "sub-border-style", sub_border_style_options),
                           create_property_toggle("Bold", "sub-bold"), create_property_toggle("Italic", "sub-italic"),
                           create_property_number_adjustment("Scale", "sub-scale", 0.005, 0, 100),
                           create_property_number_adjustment("Font size", "sub-font-size", 1, 1),
                           create_property_number_adjustment("Outline size", "sub-outline-size", 0.05, 0),
                           create_property_number_adjustment("Shadow offset", "sub-shadow-offset", 0.05, 0),
                           create_property_number_adjustment("Spacing", "sub-spacing", 0.005),
                           create_property_number_adjustment("Blur", "sub-blur", 0.005, 0, 20)}) do
        table.insert(style_items, item)
    end

    return {
        title = "Style",
        hint = style_hint or nil,
        items = style_items
    }
end

-- ASS override
local ass_override_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Scale",
    value = "scale"
}, {
    name = "Force",
    value = "force"
}, {
    name = "Strip",
    value = "strip"
}}

-- Blend
local blend_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Video",
    value = "video"
}}

local menu_data
local function create_menu_data()
    local menu_items = {create_style_menu(),
                        create_property_selection("ASS override", "sub-ass-override", ass_override_options),
                        create_property_selection("Blend", "blend-subtitles", blend_options),
                        create_property_toggle("Fix timing", "sub-fix-timing"),
                        create_property_number_adjustment("Delay", "sub-delay", 0.05)}

    return {
        type = "subtitle_settings",
        title = "Subtitle settings",
        items = menu_items,
        search_submenus = true,
        callback = {mp.get_script_name(), 'menu-event'}
    }
end

local debounce_timer = nil
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
    end
end)

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", menu_data)
end)
