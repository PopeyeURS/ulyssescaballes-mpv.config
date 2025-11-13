-- shader_recovery.lua
-- Modular shader stack recovery with conditional profiles

local mp = require 'mp'

-- Define named shader profiles
local shader_profiles = {
  ["default"] = {
    "~~/shaders/KrigBilateral.glsl",
    "~~/shaders/SSimSuperRes.glsl",
    "~~/shaders/AdaptiveSharpen.glsl"
  },
  ["8k_performance"] = {
    "~~/shaders/SSimSuperRes.glsl"
  },
  ["anime_soft"] = {
    "~~/shaders/Anime4K.glsl",
    "~~/shaders/Retinex.glsl"
  }
}

-- Profile selection logic
local function select_profile()
  local width = mp.get_property_number("dwidth", 0)
  local height = mp.get_property_number("dheight", 0)
  local path = mp.get_property("path", "")

  if width >= 7680 or height >= 4320 then
    return "8k_performance"
  elseif path:match("[Aa]nime") then
    return "anime_soft"
  else
    return "default"
  end
end

-- Apply a named shader profile
local function apply_shader_profile(profile_name)
  local stack = shader_profiles[profile_name]
  if not stack then
    mp.msg.warn("Shader profile not found: " .. profile_name)
    return
  end

  local shader_list = table.concat(stack, ",")
  mp.set_property("glsl-shaders", shader_list)
  mp.osd_message("Shader profile applied: " .. profile_name)
end

-- Manual recovery trigger
local function recover_shaders()
  local profile = select_profile()
  apply_shader_profile(profile)
end

-- Auto-recover if no shaders are active
local function auto_recover()
  local active = mp.get_property_native("glsl-shaders")
  if not active or #active == 0 then
    mp.msg.info("No active shaders detected. Recovering...")
    recover_shaders()
  end
end

-- Bindings
mp.add_key_binding("r", "recover_shaders", recover_shaders)
mp.register_script_message("recover_shaders", recover_shaders)
mp.register_event("file-loaded", auto_recover)
