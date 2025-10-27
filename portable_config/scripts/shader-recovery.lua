-- shader-recovery.lua
-- Re-applies shader stack if missing or corrupted during playback

local mp = require 'mp'

local shader_stack = {
  "~~/shaders/KrigBilateral.glsl",
  "~~/shaders/SSimSuperRes.glsl",
  "~~/shaders/AdaptiveSharpen.glsl"
}

local function recover_shaders()
  mp.command("vf clr") -- Clear existing video filters
  for _, shader in ipairs(shader_stack) do
    mp.commandv("vf", "add", "glsl-shader=" .. shader)
  end
  mp.osd_message("Shader Stack Recovered ✨")
end

mp.add_key_binding("r", "recover_shaders", recover_shaders)