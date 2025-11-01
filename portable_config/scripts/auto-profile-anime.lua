-- Auto-profile for anime content
local mp = require 'mp'

local anime_keywords = {
    "anime", "OVA", "OAD", "Ghibli", "Makoto Shinkai", "Kyoto Animation",
    "Naruto", "Bleach", "One Piece", "Attack on Titan", "Demon Slayer",
    "Jujutsu Kaisen", "Studio Trigger", "Evangelion", "Dragon Ball"
}

local function is_anime(filename)
    filename = filename:lower()
    for _, keyword in ipairs(anime_keywords) do
        if filename:find(keyword:lower()) then
            return true
        end
    end
    return false
end

mp.register_event("file-loaded", function()
    local path = mp.get_property("path", "")
    if is_anime(path) then
        mp.commandv("apply-profile", "anime")
        mp.osd_message("🎌 Anime Profile Activated")
    end
end)
