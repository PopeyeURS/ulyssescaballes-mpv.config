-- switch_profiles.lua
-- Helper script for profile switching hotkeys
-- Created for MPV by: Ulysses RS Caballes
-- 20260530 163536LT

local mp = require 'mp'

-- Reset to baseline
mp.register_script_message("switch_clear", function()
    mp.command("af clear")
    mp.command("vf clear")
    mp.command("apply-profile default")
    mp.osd_message("▶ Reset to baseline", 1.2)
end)

-- Anime HDR tweaks applied inline
mp.register_script_message("switch_anime", function()
    mp.command("af clear")
    mp.command("vf clear")
    mp.command('set tone-mapping bt.2446a')
    mp.command('set tone-mapping-param 1.35')
    mp.command('set hdr-contrast-recovery 0.88')
    mp.command('set tscale-blur 0.35')
    mp.command('glsl-shader "~~/shaders/Anime4K/Restore/Anime4K_Restore_CNN_M.glsl"')
    mp.command('glsl-shader "~~/shaders/Anime4K/Restore/Anime4K_Clamp_Highlights.glsl"')
    mp.osd_message("▶ Anime HDR tweaks applied", 1.2)
end)

-- Realism tweaks inline
mp.register_script_message("switch_realism", function()
    mp.command("set gamma 1.05")
    mp.command("set contrast 1.18")
    mp.command("set tone-mapping bt.2390")
    mp.command("set tone-mapping-param 1.20")
    mp.osd_message("▶ Realism tweaks applied", 1.2)
end)

-- Sports tweaks applied inline
mp.register_script_message("switch_sports", function()
    mp.command("af clear")
    mp.command("vf clear")
    mp.command("set interpolation yes")
    mp.command("set video-sync display-resample")
    mp.command("set tscale-window blackman")
    mp.command("set tscale-blur 0.45")
    mp.command("set tscale-radius 1.0")
    mp.command("set framedrop decoder")
    mp.osd_message("▶ Sports mode applied", 1.2)
end)

-- Debug overlays
mp.register_script_message("switch_debug", function()
    mp.command("script-binding stats/display-stats-toggle")
    mp.osd_message("▶ Debug overlays toggled", 1.2)
end)
