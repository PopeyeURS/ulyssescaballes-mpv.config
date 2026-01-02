# Ulysses Caballes’ MPV Configuration  

A hand‑crafted cinema engine delivering cinema‑grade, IMAX‑inspired immersion via SOFAlizer HRTF, impulse responses, and a tuned EQ/convolution chain. Works on headphones and multi‑speaker systems while preserving clarity, dynamics, and spatial detail.  

## Core Components  

![License](https://img.shields.io/badge/License-GPLv3-blue)  
![GPU](https://img.shields.io/badge/GPU-Vulkan%20Optimized-orange)  
![Config](https://img.shields.io/badge/config-remixable-green)  
![MPV](https://img.shields.io/badge/MPV-v0.40%2B-blue)  
![Platform](https://img.shields.io/badge/Platform-Windows%2011-lightgrey)  
![GLSL](https://img.shields.io/badge/GLSL-Custom%20Pipeline-purple)  
![Playback](https://img.shields.io/badge/Playback-Cinematic%20HDR%208K-critical)  
![Profiles](https://img.shields.io/badge/Profiles-Anime%2C%20Realism%2C%208K%2C%20Sports-green)  

---

## Table of Contents
- [Overview](#overview)  
- [Features](#features)  
- [Requirements](#requirements)  
- [Demo Clip](#demo-clip)  
- [Screenshots](#screenshots)  
- [Shader Pipeline](#shader-pipeline)  
- [Audio Pipeline](#audio-pipeline)  
- [Profiles](#profiles)  
- [Profile Switching](#profile-switching)  
- [Keyboard Function Shortcuts](#keyboard-function-shortcuts)  
- [Script Suite](#script-suite)  
- [Installation](#installation)  
- [Usage Note](#usage-note)  
- [Common Toggles & Beginner Notes](#common-toggles--beginner-notes)  
- [Optional Add-ons](#optional-add-ons)  
- [Philosophy](#philosophy)  
- [Repo Hygiene](#repo-hygiene)  
- [Final Word](#final-word)  
- [License](#license)  

---

## Overview
This MPV configuration is engineered for viewers who demand cinematic fidelity, artifact‑free rendering, and adaptive precision across all content types — anime, films, sports, and 8K HDR.

Every component is tuned for clarity, depth, and realism, powered by a custom shader pipeline and a suite of Lua automation scripts.

---

## Features
- Fade‑aware debanding with fruit dithering  
- BT.2390 tone mapping with contrast recovery  
- Custom GLSL pipeline for super‑resolution, sharpening, depth, and film emulation  
- Vulkan‑optimized GPU context  
- Modular profiles for anime, realism, sports, and 8K  
- Lua automation for adaptive playback and shader recovery  
- Clean, cache‑free, remixable structure  

---

## Requirements
- **MPV v0.40+**  
- **Vulkan‑capable GPU**  
- **Windows 11** (recommended)

Download MPV (Shinchiro builds):  
https://github.com/shinchiro/mpv-winbuild-cmake/releases

---

## Demo Clip

[Download the 8K MPV Demo Clip](video/ulyssescaballes-8k_video_demo.mkv)

This clip was rendered and played using my MPV config with HEVC Main 10, tone mapping, and shader fidelity. Open it in MPV to experience the full effect.

---

## Screenshots

![Screenshot 1](images/screenshot1.png)  
*Debanding and tone mapping — smooth gradients, lifelike contrast.*

![Screenshot 2](images/screenshot2.png)  
*Styled subtitles and shader stack delivering cinematic realism.*

---

## Shader Pipeline
The heart of this configuration is a carefully sequenced GLSL pipeline designed for clarity, depth, and cinematic texture — without introducing artifacts or unnecessary GPU load.

### Pipeline Overview
Each shader is placed with intent, forming a cohesive chain:

1. **Debanding (fade‑aware, fruit dithering)**  
   Eliminates banding in gradients, skies, shadows, and anime backgrounds while preserving fine detail.

2. **Tone Mapping (BT.2390 with contrast recovery)**  
   Converts HDR → SDR or SDR → HDR with natural highlight roll‑off and shadow depth.

3. **Super‑Resolution & Sharpening**  
   Enhances micro‑detail without halos or overshoot, ideal for anime linework and live‑action textures.

4. **Depth & Local Contrast Enhancement**  
   Adds dimensionality and presence without artificial edge glow.

5. **Film Emulation Layer**  
   A subtle grain and color‑response pass that restores organic texture.

---

## Audio Pipeline
While the shader chain delivers uncompromising visual fidelity, this configuration also integrates a cinema‑grade audio pipeline designed for both headphone and speaker playback.

### Pipeline Overview
1. **SOFAlizer (HRTF Virtualization)**  
   * Uses the `hrtf_M_normal_pinna_0.5deg.sofa` dataset for binaural rendering.  
   * Provides Atmos/IMAX‑style immersion on headphones.  
   * Gain and normalization tuned for clarity without distortion.  

2. **Cinema EQ Chain**  
   * Bass reinforcement for sub‑rumble and fullness.  
   * Midrange cleanup to reduce muddiness.  
   * Treble sparkle and air for dialogue clarity and high‑frequency detail.  
   * Subharmonic enhancement for added depth.  

3. **Impulse Response Convolution (IR)**  
   * Authentic theatre ambience via `theatre_ir_stereo_48k.wav`.  
   * Dry/wet mix balanced for subtle spaciousness without overwhelming the direct signal.  
   * Replaces synthetic echo with real hall reflections.  

4. **Dynamics Control**  
   * Loudness normalization for consistent playback.  
   * Musical compression to smooth peaks while preserving dynamics.  
   * Final limiter ensures safety against clipping.  

### Mode Switching
- **Default Mode** → Raw audio, no filters.  
- **Headphone Atmos Mode** → SOFAlizer + EQ + IR for immersive binaural playback.  
- **Stereo Cinema Mode** → EQ + IR convolution for theatre‑like sound on plain stereo speakers.  
- Toggle with **F9** — OSD messages confirm active mode.

---

*Optimized for headphone immersion, but equally enhances clarity and depth on speaker systems.*  

---

## Profiles
This configuration includes multiple playback profiles tailored for different content types. Each profile adjusts shaders, scaling, tone mapping, and enhancement strength.

### Anime Profile
- Line‑art‑safe sharpening  
- High‑quality debanding  
- Gentle color vibrancy  
- Lightweight grain for texture  

### Realism / Live‑Action Profile
- Balanced sharpening  
- Depth‑enhancing local contrast  
- Filmic grain  
- Natural color response  

### Sports Profile
- Motion‑clarity‑oriented sharpening  
- Reduced grain  
- High visibility in highlights  
- Clean gradients for broadcast content  

### 8K / High‑Resolution Profile
- Super‑resolution tuned for large displays  
- Minimal grain  
- Precision tone mapping  
- GPU‑efficient scaling  

---

## Profile Switching

### Method 1 — Command Line
```
mpv --profile=anime video.mkv
mpv --profile=realism video.mkv
mpv --profile=sports video.mkv
mpv --profile=8k video.mkv
```

### Method 2 — Keyboard Shortcuts (Optional)
If you enable the included keybinds:

- **F1** → Anime  
- **F2** → Realism  
- **F3** → Sports  
- **F4** → 8K  

---

## Keyboard Function Shortcuts
These optional function bindings provide rapid access to internal presets and debugging utilities. Each shortcut triggers a specific mode designed to streamline testing, profile switching, and visual experimentation.

### Menu & Utility Shortcuts

| Key | Action |
|-----|--------|
| O | Open File |
| Y | YouTube Search |
| H | Playback History |
| K | Keybinds Menu |
| V | Video Settings |
| A | Audio Device Selector |
| S | Subtitle Settings |
| P | Screenshot Menu |

### Function Overview

| Shortcut | Function Name | Description |
|---------|----------------|-------------|
| Ctrl + 1 | clear_default | Resets MPV to the baseline configuration. Ideal for clearing active shaders, profiles, or overrides during testing. |
| Ctrl + 2 | anime_hdr | Activates the Anime HDR preset — tuned for stylized line art, vibrant color response, and high‑contrast anime rendering. |
| Ctrl + 3 | realism | Switches to the Realism preset, emphasizing natural contrast, filmic grain, and lifelike texture. |
| Ctrl + 4 | sports | Enables the Sports preset, optimized for clarity in motion, highlight visibility, and clean gradients. |
| Ctrl + 5 | debug | Opens the debugging mode, revealing internal states, shader activity, and diagnostic overlays. |

## Script Suite
A set of Lua scripts enhances automation, stability, and playback intelligence.

### Included Scripts
- **shader-recover.lua**  
  Automatically reloads shaders if MPV encounters a pipeline error.

- **profile-auto.lua**  
  Detects resolution, framerate, and content type to select the best profile.

- **stats-overlay.lua**  
  Displays GPU load, tone mapping state, and active shaders.

- **subtitle-style.lua**  
  Applies cinematic subtitle styling with outline, blur, and color control.

---

## Installation
1. Download or clone this repository.  
2. Place the folders into your MPV directory:

```
mpv/
├── mpv.conf
├── input.conf
├── scripts/
├── shaders/
└── script-opts/
```

3. Ensure your GPU is set to **Vulkan** mode:

```
gpu-api=vulkan
```


4. Launch MPV — the configuration activates automatically.

---

### Usage Note
This audio pipeline delivers cinema‑grade, IMAX‑inspired immersion across headphones and multi‑speaker setups by combining SOFAlizer HRTF virtualization, impulse responses, and a tuned EQ/convolution chain. On headphones it creates a wide, natural surround image; on speakers it adds theatre‑style depth while preserving clarity and dynamics. Quick start: place [main.lua] in [mpv/scripts/] and optional [SOFA/IR] assets in [mpv/scripts/sofalizer/]; press [F9] to toggle the chain, [F10] to toggle dynamic processing, and [F11] to switch universal mode. Note: results vary by device—A/B with the script enabled to find the preferred wet/dry balance and watch for added latency on live monitoring. 

---

## Common Toggles & Beginner Notes

Some options in `mpv.conf` are set for convenience but may feel unusual if you’re new to mpv.  
Here are the most common ones you might want to adjust:

- **Idle Behavior**
  - `idle=yes` → mpv stays open even with no file loaded. Useful for drag‑and‑drop of YouTube links or files.
  - `idle=no` → mpv closes automatically after playback. Feels more like a traditional media player.

- **On‑Screen Controller (OSC)**
  - `osc=no` disables the default control bar for a cleaner look.
  - Beginners may prefer `osc=yes` to keep the familiar UI.

- **Window Border**
  - `border=no` removes the title bar for a cinema‑style presentation.
  - Set `border=yes` if you want standard window controls.

These are stylistic defaults chosen for cinematic presentation. Feel free to adjust them to match your workflow.

---

## Optional Add-ons
These are not required but enhance the experience:

- **Anime4K** (for stylized upscaling)  
- **FSRCNNX** (neural upscaling)  
- **RAVU** (high‑precision scaling)  
- **SVP / Motion Interpolation** (for sports content)  
- **External LUTs** (for color grading)

---

## Philosophy
This configuration is built on three principles:

### Precision  
Every shader, value, and filter is chosen with intent — no bloat, no placebo settings.

### Cinematic Realism  
The goal is not “sharper” or “brighter,” but **truer** — depth, texture, and natural contrast.

### Modularity  
Everything is remixable.  
Every file is documented.  
Every profile is optional.  

You can adopt the entire system or extract only the parts you love.

---

## Repo Hygiene
- No cache files  
- No platform‑specific clutter  
- Clean folder structure  
- Human‑readable configs  
- Commented shader chains  
- Versioned updates with clear changelogs  

---

## Final Word  
Playback perfection isn’t measured in numbers alone—it’s defined by how it feels. This hand‑crafted cinema engine reflects my journey toward that feeling. If it helps you step closer to your own, then it has fulfilled its purpose.  

**Ulysses RS Caballes [PopeyeURS]**  
*Crafting cinema in pixels, one shader at a time.*

---

## License  
**License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)**  
This project is licensed under the GNU General Public License v3.0. Feel free to fork, adapt, and share.

See the [LICENSE](LICENSE) file for details.
