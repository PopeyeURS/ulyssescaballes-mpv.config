--[[
    Copyright (C) 2023  kevincs
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
    https://www.gnu.org/licenses/gpl-2.0.html
--]]

-- Lua script for mpv to enable sofalizer, with sofa file inside of mpv's ~~/
-- For more info :
-- https://old.reddit.com/r/mpv/comments/11cr5u9/is_it_possible_to_use_the_headphone_filter/
-- https://github.com/flathub/io.mpv.Mpv/issues/125

-- Audio must have at least this many channels to enable sofalizer.
local sofa_min_channels = 3

-- Audio must have at most this many channels to enable sofalizer.
local sofa_max_channels = 9

-- Amount of gain to add to sofalizer
local sofa_gain = 12

-- Extra options to add to sofalizer
-- Example: "interpolate=1:framesize=8192"
local sofa_opts = "interpolate=1"

-- Sofa file name (optional subdirectory)
local sofa_file = "scripts/sofalizer/ClubFritz6.sofa"

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
function main(name, channels)
    local af_add = "sofalizer=sofa=\"" .. mp.command_native({"expand-path", "~~/"}) .. "/" .. sofa_file .. "\":gain=" .. sofa_gain
    if (sofa_opts ~= "") then
        af_add = af_add .. ":" .. sofa_opts
    end
    if (channels == nil or channels < sofa_min_channels or channels > sofa_max_channels) then
        mp.command("no-osd af remove '" .. af_add .. "'")
        return
    end
    local af = mp.get_property("af")
    if (string.find(af, "sofalizer")) then
        return
    end
    print("Current --af=" .. af)
    if (af == "") then
        print("New     --af=" .. af_add)
    else
        print("New     --af=" .. af .. ";" .. af_add)
    end
    mp.command("no-osd af add '" .. af_add .. "'")
end

-- This is here so both changing files and changing audio id (if channel count changes) should retrigger main.
function file_ended()
    mp.unregister_event(file_ended)
    mp.unobserve_property(main)
    mp.register_event("file-loaded", file_loaded)
end

function file_loaded()
    mp.unregister_event(file_loaded)
    mp.register_event("end-file", file_ended)
    mp.observe_property("audio-params/channel-count", "number", main)
end

mp.register_event("file-loaded", file_loaded)