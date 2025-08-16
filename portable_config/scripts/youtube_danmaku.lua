local options = {
    live_chat_directory = "~~/live_chat",
    yt_dlp_path = 'yt-dlp',
    autoload = true,
    danmaku_visibility = true,

    fontname = "sans-serif",
    fontsize = 40,
    bold = false,
    transparency = 25, -- 0-255 (0 = opaque, 255 = transparent)
    outline = 1,
    shadow = 0,
    duration = 10, -- May be innacurate (about third/half of a second) and more so for longer messages
    lane_spacing = 1, -- Multiplied by fontsize
    displayarea = 0.5
}

local function format_options(unformatted_options)
    if unformatted_options["live_chat_directory"] then
        options.live_chat_directory = mp.command_native({"expand-path", options.live_chat_directory})
    end
end

format_options({
    live_chat_directory = true
})

require("mp.options").read_options(options, nil, format_options)
local utils = require("mp.utils")
local filename
local update_messages_timer
local last_position
local download_finished = false
local messages = {}
local active_messages = {}
local messages_pos
local overlay = mp.create_osd_overlay('ass-events')
local width, height = 1920, 1080
local osd_width, osd_height = 0, 0
local render_timer

local function render_loop()
    if not options.danmaku_visibility or #messages == 0 then
        overlay:remove()
        return
    end

    local pos = mp.get_property_number('time-pos')
    local ass_events = {}

    for i = #active_messages, 1, -1 do
        local comment = active_messages[i]
        local message_width = comment.text:len() * options.fontsize
        local elapsed = pos - comment.time
        local total_distance = width + message_width
        local speed = total_distance / options.duration
        local distance_traveled = elapsed * speed

        if distance_traveled > total_distance then
            table.remove(active_messages, i)
        else
            local current_x = width - distance_traveled
            local ass_text = comment.text and
                                 string.format(
                    "{\\rDefault\\an7\\q2\\pos(%.1f,%.1f)\\fn%s\\fs%d\\c&HFFFFFF&\\alpha&H%x\\bord%s\\shad%s\\b%s}%s",
                    current_x, comment.y, options.fontname, options.fontsize, options.transparency, options.outline,
                    options.shadow, options.bold and 1 or 0, comment.text)
            table.insert(ass_events, ass_text)
        end
    end

    overlay.res_x = width
    overlay.res_y = height
    overlay.data = table.concat(ass_events, '\n')
    overlay:update()
end

local function add_message(new_message)
    if not new_message.text or string.match(new_message.text, "^:.*:$") then
        return
    end
    local pos = mp.get_property_number('time-pos')

    local selected_y
    local min_selected_y
    local min_overlap = math.huge
    for lane = 1, math.floor((height * options.displayarea) / (options.lane_spacing * options.fontsize)) do
        local y = (lane - 1) * (options.lane_spacing * options.fontsize)

        local latest_lane_message
        for _, active_message in ipairs(active_messages) do
            if active_message.y == y then
                if not latest_lane_message or active_message.time > latest_lane_message.time then
                    latest_lane_message = active_message
                end
            end
        end

        if latest_lane_message then
            local time_elapsed = pos - latest_lane_message.time
            local time_left = math.max(0, options.duration - time_elapsed)
            local new_message_total_distance = width + (new_message.text:len() * options.fontsize)
            local new_message_speed = new_message_total_distance / options.duration
            if not selected_y and new_message_speed * time_left < width then
                selected_y = y
            end

            local overlap = (new_message_speed * time_left) - width
            if overlap < min_overlap then
                min_overlap = overlap
                min_selected_y = y
            end
        elseif not selected_y then
            selected_y = y
        end
    end

    if selected_y then
        new_message.y = selected_y
    else
        new_message.y = min_selected_y
    end

    table.insert(active_messages, new_message)
end

mp.observe_property('time-pos', 'number', function(_, pos)
    if pos and messages[messages_pos] then
        while messages_pos <= #messages and messages[messages_pos].time <= pos do
            add_message(messages[messages_pos])
            messages_pos = messages_pos + 1
        end
    end
end)

mp.register_event("playback-restart", function()
    local function update_messages_pos()
        local pos = mp.get_property_number('time-pos')
        if #messages == 0 or pos > messages[#messages].time then
            return
        elseif pos <= messages[1].time then
            return 1
        else
            local left = 1
            local right = #messages
            local result
            while left <= right do
                local mid = math.floor((left + right) / 2)

                if messages[mid].time == pos then
                    return mid
                elseif messages[mid].time < pos then
                    left = mid + 1
                else
                    result = mid
                    right = mid - 1
                end
            end

            return result
        end
    end

    messages_pos = update_messages_pos()
    active_messages = {}
end)

local function parse_message_runs(runs)
    local message = ""
    for _, data in ipairs(runs) do
        if data.text then
            message = message .. data.text
        elseif data.emoji then
            if data.emoji.isCustomEmoji then
                message = message .. data.emoji.shortcuts[1]
            else
                message = message .. data.emoji.emojiId
            end
        end
    end
    return message
end

local function parse_text_message(renderer)
    local function string_to_color(str)
        local hash = 5381
        for i = 1, str:len() do
            hash = (33 * hash + str:byte(i)) % 16777216
        end
        return hash
    end

    local id = renderer.authorExternalChannelId
    local color = string_to_color(id)
    local author = renderer.authorName and renderer.authorName.simpleText or '-'
    local message = parse_message_runs(renderer.message.runs)

    return {
        type = 0,
        author = author,
        author_color = color,
        text = message,
        time = nil -- Will be set by caller
    }
end

local function parse_superchat_message(renderer)
    local border_color = renderer.bodyBackgroundColor - 0xff000000
    local text_color = renderer.bodyTextColor - 0xff000000
    local money = renderer.purchaseAmountText.simpleText
    local author = renderer.authorName and renderer.authorName.simpleText or '-'
    local message
    if renderer.message then
        message = parse_message_runs(renderer.message.runs)
    end

    return {
        type = 1,
        author = author,
        money = money,
        border_color = border_color,
        text_color = text_color,
        text = message,
        time = nil -- Will be set by caller
    }
end

local function parse_chat_action(action, time)
    if not action.addChatItemAction then
        return
    end

    local message
    local item = action.addChatItemAction.item
    if item.liveChatTextMessageRenderer then
        message = parse_text_message(item.liveChatTextMessageRenderer)
    elseif item.liveChatPaidMessageRenderer then
        message = parse_superchat_message(item.liveChatPaidMessageRenderer)
    end

    if message then
        message.time = time
    end
    return message
end

local function get_parsed_messages(live_chat_json)
    local parsed_messages = {}
    for line in io.lines(live_chat_json) do
        local entry = utils.parse_json(line)
        if entry.replayChatItemAction then
            local time = tonumber(entry.videoOffsetTimeMsec or entry.replayChatItemAction.videoOffsetTimeMsec) / 1000
            for _, action in ipairs(entry.replayChatItemAction.actions) do
                local parsed_message = parse_chat_action(action, time)
                if parsed_message then
                    table.insert(parsed_messages, parsed_message)
                end
            end
        end
    end
    return parsed_messages
end

local function get_new_parsed_messages(filename)
    local file = io.open(filename, "r")
    if not file then
        return
    end

    if not last_position then
        for line in file:lines() do
            last_position = file:seek()
        end
    else
        file:seek("set", last_position)
    end

    local entries = {}
    local latest_entry_time
    for line in file:lines() do
        last_position = file:seek()
        local entry = utils.parse_json(line)
        if entry and entry.replayChatItemAction then
            latest_entry_time = tonumber(entry.videoOffsetTimeMsec or entry.replayChatItemAction.videoOffsetTimeMsec) /
                                    1000
            table.insert(entries, entry)
        end
    end
    file:close()

    local parsed_messages = {}
    if #entries > 0 then
        local live_offset = latest_entry_time - mp.get_property_native("duration")
        for _, entry in ipairs(entries) do
            local time = tonumber(entry.videoOffsetTimeMsec or entry.replayChatItemAction.videoOffsetTimeMsec) / 1000
            for _, action in ipairs(entry.replayChatItemAction.actions) do
                local parsed_message = parse_chat_action(action, entry.isLive and (time - live_offset) or time)
                if parsed_message then
                    table.insert(parsed_messages, parsed_message)
                end
            end
        end
    end

    return parsed_messages
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

local function update_messages()
    local function merge_sorted_arrays(a, b)
        local merged = {}
        local i, j = 1, 1

        while i <= #a and j <= #b do
            if a[i].time < b[j].time then
                table.insert(merged, a[i])
                i = i + 1
            else
                table.insert(merged, b[j])
                j = j + 1
            end
        end

        return table.move(b, j, #b, #merged + 1, table.move(a, i, #a, #merged + 1, merged))
    end

    if filename and not download_finished then
        if file_exists(filename .. ".part") then
            local parsed_messages = get_new_parsed_messages(filename .. ".part")
            if parsed_messages then
                table.sort(parsed_messages, function(a, b)
                    return a.time < b.time
                end)
                messages = merge_sorted_arrays(messages, parsed_messages)
            end
        elseif file_exists(filename) then
            download_finished = true
            local parsed_messages = get_parsed_messages(filename)
            if parsed_messages then
                messages = {}
                table.sort(parsed_messages, function(a, b)
                    return a.time < b.time
                end)
                messages = parsed_messages
            end
        end
    end
end
update_messages_timer = mp.add_periodic_timer(.1, update_messages)

local function reset()
    filename = nil
    last_position = nil
    download_finished = false
    messages = {}
end

local function load_live_chat()
    reset()

    local function download_live_chat(url)
        mp.command_native_async({
            name = "subprocess",
            args = {'yt-dlp', '--skip-download', '--sub-langs=live_chat', url, '--write-sub', '-o', '%(id)s', '-P',
                    options.live_chat_directory}
        })
    end

    local function live_chat_exists_remote(url)
        local result = mp.command_native({
            name = "subprocess",
            capture_stdout = true,
            args = {'yt-dlp', url, '--list-subs', '--quiet'}
        })
        if result.status == 0 then
            return string.find(result.stdout, "live_chat")
        end
        return false
    end

    local path = mp.get_property_native('path')
    local is_network = path:find('^http://') or path:find('^https://')
    if is_network then
        local id = path:gsub("^.*\\?v=", ""):gsub("&.*", "")
        filename = string.format("%s/%s.live_chat.json", options.live_chat_directory, id)
        if not file_exists(filename) and live_chat_exists_remote(path) then
            download_live_chat(path, filename)
        end
    else
        local base_path = path:match('(.+)%..+$') or path
        filename = base_path .. '.live_chat.json'
    end
end

mp.register_event("file-loaded", function()
    if options.autoload then
        load_live_chat()
    end
end)

mp.add_hook("on_unload", 50, function()
    reset()
end)

mp.observe_property('osd-width', 'number', function(_, value)
    osd_width = value or osd_width
end)
mp.observe_property('osd-height', 'number', function(_, value)
    osd_height = value or osd_height
end)
mp.observe_property('display-fps', 'number', function(_, value)
    if value then
        local interval = 1 / value
        if render_timer then
            render_timer:kill()
        end
        render_timer = mp.add_periodic_timer(interval, render_loop)
    end
end)

mp.add_key_binding(nil, "load-live-chat", load_live_chat)

mp.add_key_binding(nil, "toggle-danmaku", function()
    options.danmaku_visibility = not options.danmaku_visibility
end)
