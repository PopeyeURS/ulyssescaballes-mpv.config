# Ulysses Caballes’ MPV Configuration  

A hand‑crafted cinema engine built for ultimate IMAX‑grade immersion. Designed with SOFAlizer HRTF, bespoke impulse responses, and a finely tuned EQ/convolution chain, it envelops you in spatially rich audio with uncompromising fidelity. Fully adaptable to headphones and multi-speaker arrays, it pairs pristine sound with high-fidelity video playback—featuring true 3D depth, precise color reproduction, exceptional detail, and fluid motion.    

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
- [Keyboard Function Shortcuts](#keyboard-function-shortcuts)  
- [Menu & Utility Shortcuts](#menu--utility-shortcuts)  
- [Script Suite](#script-suite)  
- [Datasets](#datasets)  
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
   * Uses the `Kemar_HRTF_sofa.sofa` dataset for binaural rendering.  
   * Provides Atmos/IMAX‑style immersion on headphones for both film and music.  
   * Gain and normalization tuned for clarity without distortion, ensuring musical detail remains intact.  

2. **Cinema & Music EQ Chain**  
   * Bass reinforcement for sub‑rumble and fullness in cinematic effects and musical low‑end.  
   * Midrange cleanup to reduce muddiness, enhancing dialogue and instrumental separation.  
   * Treble sparkle and air for dialogue clarity and high‑frequency detail in vocals and instruments.  
   * Subharmonic enhancement for added depth, enriching both soundtracks and music playback.  

3. **Dynamics Control**  
   * Loudness normalization for consistent playback across movies and music tracks.  
   * Musical compression to smooth peaks while preserving expressive dynamics.  
   * Final limiter ensures safety against clipping, keeping both cinematic and musical experiences distortion‑free.

### Mode Switching

| Key  | Mode             | Description                                                   |
|------|------------------|---------------------------------------------------------------|
| F9   | Headset Profile  | SOFAlizer + EQ for immersive binaural audio                   |
| F10  | Cinema Profile   | Compression/limiter for consistent playback                   |
| F11  | Music Mode       | Balanced EQ + stereo field: instrument, vocals, and live feel |
| F12  | Reset Filters    | Clears all audio filters                                      |
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
## Datasets
This configuration relies on external datasets for binaural rendering and theatre ambience.  
Place all datasets in: %APPDATA%\Roaming\mpv\scripts\sofalizer\

### External download required
- [`Kemar_HRTF_sofa.sofa`](https://sofacoustics.org/data/database/aachen%20%28high-resolution%20kemar%29/Kemar_HRTF_sofa.sofa)  
  KEMAR HRTF dataset (open research license, safe to redistribute with attribution).  

---

### Audio Chain Note
- **Enhanced Headset (F9), Enhanced Cinema (F10) & Music Mode Plus (F11)** uses:  
  - `Kemar_HRTF_sofa.sofa`  

## Installation
1. Download or clone this repository.  
2. Place the folders into your MPV directory: eg. "C:/Users/<user_name>/AppData/Roaming/mpv/portable_config/scripts/sofalizer/Kemar_HRTF_sofa.sofa"  
```
%APPDATA%\mpv\portable_config\
│
├── mpv.conf
├── input.conf
├── profiles.conf
├── script-opts\
├── scripts\
│   └── sofalizer\
│       └── Kemar_HRTF_sofa.sofa
│           └── main.lua
└── shaders\
    ├── FSRCNNX\
    ├── SSim\
    ├── Adaptive_sharpen\
    ├── Glimmer_sharpen\
    ├── Depth_reality_boost\
    └── FilmEmulation_Kodak\
```

3. Ensure your GPU is set to **Vulkan** mode:

```
gpu-api=vulkan
```

4. Launch MPV — the configuration activates automatically.

---

### Usage Note

- **F9** → Enhanced Headset  
- **F10** → Enhanced Cinema  
- **F11** → Music Mode Plus  
- **F12** → Reset Filters  
- **Profiles** (Anime, Realism, Sports, 8K) via CLI **  
- **Utility menus** via **O, Y, H, K, V, A, S, P**  

---

### Common Toggles & Beginner Notes

| Option                | Setting            | Effect                                                                 |
|-----------------------|--------------------|------------------------------------------------------------------------|
| **Idle Behavior**     | `idle=yes`         | MPV stays open even with no file loaded (useful for drag‑and‑drop).    |
|                       | `idle=no`          | MPV closes automatically after playback (traditional media player feel).|
| **On‑Screen Controller (OSC)** | `osc=no`  | Disables the control bar for a cleaner, cinema‑style look.             |
|                       | `osc=yes`          | Enables the familiar UI with playback controls.                        |
| **Window Border**     | `border=no`        | Removes title bar for a cinema‑style presentation.                     |
|                       | `border=yes`       | Restores standard window controls.                                     |
| **Volume Max**        | `volume-max=200`   | Allows boosting volume beyond 100% (use with care to avoid distortion).|

---

### Optional Add-ons

| Add-on              | Purpose/Benefit                          |
|---------------------|------------------------------------------|
| **Anime4K**         | Stylized upscaling for animation content |
| **FSRCNNX**         | Neural network–based upscaling           |
| **RAVU**            | High‑precision scaling                   |
| **SVP / Motion Interpolation** | Smoother playback for sports and fast motion |
| **External LUTs**   | Custom color grading for cinematic tone  |

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

### Repo Hygiene

| Practice                  | Description                                                   |
|---------------------------|---------------------------------------------------------------|
| **No cache files**        | Repository excludes temporary or auto‑generated cache files.  |
| **No platform clutter**   | Avoids OS‑specific junk (e.g., `.DS_Store`, `Thumbs.db`).     |
| **Clean folder structure**| Organized directories for configs, shaders, and scripts.      |
| **Human‑readable configs**| Config files are concise, documented, and easy to understand. |
| **Commented shader chains**| Each GLSL filter is annotated for clarity and maintainability.|
| **Versioned updates**     | Clear changelogs accompany every update for transparency.     |
| **Commit intent**         | Every commit message documents purpose — no silent changes.   |

---

## Final Word  
Playback perfection isn’t measured in numbers alone, it’s defined by how it feels. This hand‑crafted cinema engine reflects my journey toward that feeling. If it helps you step closer to your own, then it has fulfilled its purpose.  

**Ulysses RS Caballes [PopeyeURS]**  
*Crafting cinema in pixels, one shader at a time.*

---

## License  
**License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)**  
This project is licensed under the GNU General Public License v3.0. Feel free to fork, adapt, and share.

See the [LICENSE](LICENSE) file for details.
