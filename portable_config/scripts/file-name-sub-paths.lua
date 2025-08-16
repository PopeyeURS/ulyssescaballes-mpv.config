-- Assumes sub-file-paths is not changed during runtime
local default_sub_file_paths = mp.get_property_native("sub-file-paths")
mp.add_hook('on_load', 50, function()
    local new_sub_file_paths = {}
    for _, sub_file_path in ipairs(default_sub_file_paths) do
        table.insert(new_sub_file_paths, sub_file_path)
        table.insert(new_sub_file_paths, sub_file_path .. '/' .. mp.get_property('filename/no-ext'))
    end
    mp.set_property_native('sub-file-paths', new_sub_file_paths)
end)