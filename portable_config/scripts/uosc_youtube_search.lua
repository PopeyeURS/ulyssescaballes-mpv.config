-- uosc version of https://github.com/CogentRedTester/mpv-scripts/blob/master/youtube-search.lua

local options = {
    api_key = "",
    api_path = "https://www.googleapis.com/youtube/v3/",
    fallback_api_path = "",
    frontend = "https://www.youtube.com",
    max_results = 25,
    reset_on_close = false
}

local function format_options(unformatted_options)
    local function format_api_path(api_path)
        return api_path:sub(-1) ~= "/" and api_path .. "/" or api_path
    end
    if unformatted_options["api_path"] then
        options.api_path = format_api_path(options.api_path)
    end
    if unformatted_options["fallback_api_path"] then
        options.fallback_api_path = format_api_path(options.fallback_api_path)
    end
    if unformatted_options["frontend"] then
        options.frontend = options.frontend:sub(-1) == "/" and options.frontend:sub(1, -2) or options.frontend
    end
end

format_options({
    api_path = true,
    fallback_api_path = true,
    frontend = true
})

require("mp.options").read_options(options, nil, format_options)
local utils = require("mp.utils")

local menu_data = {
    type = "youtube_search",
    title = "YouTube search",
    items = {{
        title = "",
        selectable = false
    }},
    item_actions = {},
    item_actions_place = "outside",
    search_style = "palette",
    search_debounce = "submit",
    on_search = "callback",
    callback = {mp.get_script_name(), 'menu-event'}
}

local function update_menu()
    mp.commandv("script-message-to", "uosc", "update-menu", utils.format_json(menu_data))
end

local function close_menu()
    mp.commandv('script-message-to', 'uosc', 'close-menu', menu_data.type)
end

local function reset_menu()
    menu_data.items = {{
        title = "",
        selectable = false
    }}
    menu_data.item_actions = {}
end

local function render_loading()
    menu_data.items = {{
        title = "Loading...",
        muted = true,
        icon = 'spinner',
        selectable = false
    }}
    menu_data.item_actions = {}
    update_menu()
end

local function render_menu(results)
    menu_data.items = {}
    for _, item in ipairs(results) do
        if item.type == "video" then
            table.insert(menu_data.items, {
                title = item.title,
                hint = (item.channel_title ~= "" and item.channel_title .. " | " or "") .. "Video",
                value = ("%s/watch?v=%s"):format(options.frontend, item.id)
            })
        elseif item.type == "playlist" then
            table.insert(menu_data.items, {
                title = item.title,
                hint = (item.channel_title ~= "" and item.channel_title .. " | " or "") .. "Playlist",
                italic = true,
                value = ("%s/playlist?list=%s"):format(options.frontend, item.id)
            })
        elseif item.type == "channel" then
            table.insert(menu_data.items, {
                title = item.title,
                hint = "Channel",
                bold = true,
                value = ("%s/channel/%s"):format(options.frontend, item.id)
            })
        end
    end

    menu_data.item_actions = {{
        name = "playlist_add",
        icon = "playlist_add",
        label = "Add to playlist (shift+enter/click)"
    }}

    update_menu()
end

local function format_youtube_results(response)
    local function html_decode(str)
        if type(str) ~= "string" then
            return str
        end
        return str:gsub("&(#?)(%w-);", function(is_ascii, code)
            if is_ascii == "#" then
                return string.char(tonumber(code))
            end
            if code == "amp" then
                return "&"
            end
            if code == "quot" then
                return '"'
            end
            if code == "apos" then
                return "'"
            end
            if code == "lt" then
                return "<"
            end
            if code == "gt" then
                return ">"
            end
            return
        end)
    end

    if not response or not response.items then
        return
    end

    local results = {}
    for _, item in ipairs(response.items) do
        local t = {}
        table.insert(results, t)
        t.title = html_decode(item.snippet.title)
        t.channel_title = html_decode(item.snippet.channelTitle)
        if item.id.kind == "youtube#video" then
            t.type = "video"
            t.id = item.id.videoId
        elseif item.id.kind == "youtube#playlist" then
            t.type = "playlist"
            t.id = item.id.playlistId
        elseif item.id.kind == "youtube#channel" then
            t.type = "channel"
            t.id = item.id.channelId
        end
    end

    return results
end

local function search_request(queries, api_path)
    local function encode_string(str)
        if type(str) ~= "string" then
            return str
        end
        local output, t = str:gsub("[^%w]", function(char)
            return string.format("%%%X", string.byte(char))
        end)
        return output
    end

    local url = api_path .. "search?"
    for key, value in pairs(queries) do
        url = url .. "&" .. key .. "=" .. encode_string(value)
    end

    local request = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = {"curl", url}
    })

    local response = utils.parse_json(request.stdout)
    if request.status ~= 0 or not response or response.error then
        response = nil
    end

    local results = format_youtube_results(response)
    if not results then
        return
    end

    return results
end

local function submit_query(query)
    local function get_search_queries()
        return {
            key = options.api_key,
            q = query,
            part = "id,snippet",
            maxResults = options.max_results
        }
    end

    render_loading()

    local results = search_request(get_search_queries(), options.api_path)
    if not results and options.fallback_api_path ~= "/" then
        results = search_request(get_search_queries(), options.fallback_api_path)
    end

    if not results then
        reset_menu()
        update_menu()
        return
    end

    render_menu(results)
end

mp.register_script_message("menu-event", function(json)
    local event = utils.parse_json(json)
    if event.type == "activate" and event.value then
        if event.action == "playlist_add" or event.shift then
            mp.commandv("loadfile", event.value, "append")
        else
            mp.commandv("loadfile", event.value, "replace")
            close_menu()
        end
    elseif event.type == "search" and event.query ~= "" then
        submit_query(event.query)
    elseif event.type == "close" and options.reset_on_close then
        reset_menu()
    end
end)

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(menu_data))
end)
