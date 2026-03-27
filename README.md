<p align="center" id="top">||||⚓</p>

<p align="center"><b>Ulysses RS Caballes — MPV Cinema Engine</b></p>
<p align="center">A handcrafted cinema engine for MPV — uniting neural upscaling,
HDR tone mapping, and HRTF spatial audio into a single cohesive pipeline.
Built for precision. Tuned for feeling.</p>

---

## Build & Capabilities
<p align="center">
  <img src="https://img.shields.io/badge/License-GPLv3-blue" />
  <img src="https://img.shields.io/badge/MPV-v0.41+-blue" />
  <img src="https://img.shields.io/badge/GPU-Vulkan%20Optimized-orange" />
  <img src="https://img.shields.io/badge/config-remixable-green" />
  <img src="https://img.shields.io/badge/Platform-Windows%2011-lightgrey" />
  <img src="https://img.shields.io/badge/Playback-Cinematic%208K%20HDR-critical" />
  <img src="https://img.shields.io/badge/Shader%20Pipeline-Custom%20GLSL-purple" />
  <img src="https://img.shields.io/badge/Profiles-Anime%20%7C%20Realism%20%7C%20Sports%20%7C%208K-green" />
</p>

---

## What This Configuration Delivers
✓ Cinema-grade HDR tone mapping with contrast fidelity  
✓ Adaptive sharpening with perceptual depth enhancement  
✓ HRTF-based spatial audio virtualization  
✓ Intelligent profile switching based on content type  
✓ A modular system designed for experimentation and control  

---

## Performance Expectations
| GPU Class | Resolution | Expected Performance |
|-----------|-----------|----------------------|
| RTX 4090 / RX 7900 XTX | 8K | Full pipeline |
| RTX 3080 / RX 6800 XT | 4K–8K | Minor shader tuning may help |
| RTX 3060 / RX 6700 XT | 4K | Recommended |
| GTX 1660 / RX 5600 XT | 1080p–1440p | Use lighter profiles |
| Integrated GPUs | 1080p | FSRCNNX recommended |

---

## GPU Compatibility
| Vendor | Status | Notes |
|------|------|------|
| NVIDIA | Excellent | Full Vulkan performance |
| AMD | Excellent | Linux may need lighter CuNNy variants |
| Intel Arc | Good | Best paired with FSRCNNX |
| Intel iGPU | Limited | Use lighter profiles |

**Note:** Verified on GTX 650 — smooth playback with full pipeline (CuNNy), including 2160p source video, using optimized settings.

---

## Table of Contents
- [Overview](#overview)  
- [Features](#features)  
- [Platform Performance Notes](#platform-performance-notes)  
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
- [Audio Chain & Usage Note](#audio-chain--usage-note)  
- [Common Toggles & Beginner Notes](#common-toggles--beginner-notes)  
- [Optional Add-ons](#optional-add-ons)  
- [MPV + YouTube Integration](#mpv--youtube-integration)  
- [Philosophy](#philosophy)  
- [Repo Hygiene](#repo-hygiene)  
- [Final Word](#final-word)  
- [License](#license)  

---

## Overview
This MPV configuration is engineered for viewers who demand cinematic fidelity, artifact‑free rendering, and adaptive precision across all content types — anime, films, sports, and 8K HDR.  

Every component is tuned for clarity, depth, and realism, powered by a custom shader pipeline and a suite of Lua automation scripts that dynamically adapts to content while preserving cinematic intent.  

---

## Features

✓ Custom GLSL pipeline for super-resolution, sharpening, depth, and film emulation  
✓ Vulkan-optimized rendering for high-performance playback  
✓ Content-aware profiles (anime, realism, sports, 8K)  
✓ Lua automation for dynamic shader control and recovery  
✓ Clean, modular, and remixable architecture  

---

## Platform Performance Notes  
The CuNNy-8x32-DS shader profile is optimized for Windows 11 environments and may cause performance issues (lag or dropped frames) on Linux systems with AMD GPUs.  
Recommended for Linux/AMD setups:   
✓ FSRCNNX-x2_16-0-4-1 → lighter, stable, and cross-platform friendly  
✓ CuNNy-4x32 or CuNNy-2x32 → reduced demand with good perceptual quality  
✓ Hybrid stacks (FSRCNNX + Adaptive Sharpen / Depth Reality Boost) → balance between speed and sharpness  
This ensures smoother playback while preserving visual detail and stability.  

---

## Demo Clip

[Download the 8K MPV Demo Clip](video/ulyssescaballes-8k_video_demo.mkv)

This clip was rendered and played using this configuration, showcasing HEVC Main 10 playback, HDR tone mapping, and full shader fidelity.

---

## Screenshots

![Screenshot 1](images/screenshot1.png)  
*Debanding and tone mapping — smooth gradients, lifelike contrast.*

![Screenshot 2](images/screenshot2.png)  
*Styled subtitles and shader stack delivering cinematic realism.*

---

## Visual Improvements

| Without Config | With Ulysses RS Caballes — MPV Cinema Engine | How |
|---------------|------------------------|------------------|
| Flat colors | Cinematic tone mapping | BT.2390 HDR curve + Academy Color Encoding System (ACES) |
| Aliasing artifacts | Neural upscaling | CuNNY-8x32-DS |
| Washed HDR | Contrast recovery | Reinhard + debanding |
| Weak audio stage | Spatial HRTF audio | SOFAlizer + KEMAR |
---

## Shader Pipeline

1. **Debanding (fade‑aware, error diffusion dithering)**  

2. **Tone Mapping (BT.2390 with contrast recovery)**  

3. **Resampling — 26-tap separable kernel**  

4. **Adaptive Sharpen — linear-light, curve height tuned, overshoot control**  

5. **Depth Reality Boost — perceptual depth cues without halos**  

---

## Audio Pipeline

1. **SOFAlizer (HRTF Virtualization) — Kemar dataset, customized via [main.lua]**  

2. **EQ Chain — bass reinforcement, midrange cleanup, treble clarity, and subharmonic depth**  

3. **Dynamics Control — normalization, compression, limiter for safe playback**  

---

## Profiles
This configuration includes multiple playback profiles tailored to different content types. Each profile adjusts shaders, scaling, tone mapping, and enhancement strength.

### Anime  
- Line‑art‑safe sharpen, debanding, gentle vibrancy, light grain  

### Realism  
- Balanced sharpen, depth boost, filmic grain, natural color  

### Sports  
- Motion‑clarity‑oriented sharpen, reduced grain, highlight visibility, clean gradients  

### 8K  
- Super‑resolution, minimal grain, precision tone mapping, GPU-efficient scaling  

---

## Keyboard Function Shortcuts
  
| Shortcut | Function Name | Description |
|---------|----------------|-------------|
| Ctrl + 1 | clear_default | Reset to baseline configuration. |
| Ctrl + 2 | anime_hdr | Anime HDR preset. |
| Ctrl + 3 | realism | Realism preset. |
| Ctrl + 4 | sports | Sports preset. |
| Ctrl + 5 | debug | Debugging overlays. |

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


## Script Suite  
- **shader-recover.lua**  
  Reloads shaders if errors occur.  

- **profile-auto.lua**  
  Auto-selects profile by resolution/framerate.  

- **stats-overlay.lua**  
  GPU load, tone mapping, active shaders.  

- **subtitle-style.lua**  
  Cinematic subtitle styling.  

- **sofalizer/main.lua**  
  Customized HRTF virtualization.  

---
## Datasets
Download and place datasets in: %APPDATA%\Roaming\mpv\scripts\sofalizer\  

✓ [`Kemar_HRTF_sofa.sofa`](https://sofacoustics.org/data/database/aachen%20%28high-resolution%20kemar%29/Kemar_HRTF_sofa.sofa)  
  KEMAR HRTF dataset (open research license, safe to redistribute with attribution).  
✓ [`SADIE_KEMAR_DFC_256_order_fir_48000.sofa`](https://zenodo.org/records/12542676/files/SADIE_KEMAR_DFC_256_order_fir_48000.sofa?download=1)  
  Official SADIE II Dataset (University of York). For personal/research use only.  
  
---

## Installation
Requirements  
✓ **MPV v0.41+**  
✓ **Vulkan‑capable GPU**  
✓ **Windows 11** (recommended)  

Download mpv-x86_64-v3 (Zhongfly builds):  
https://github.com/zhongfly/mpv-winbuild/releases  

1. Open File Explorer  
2. Enable: View → Show → Hidden Items
3. Navigate to %APPDATA%  
4. Create folder:  
MPV  
5. Extract MPV Zhongfly build into this folder  
6. Right click on "Updater.bat", then "Run as administrator"  
7. Press **[Windows + R]**; Type: **[control]**; Press **[Enter]**; Click: **[Programs]**; Click: **[Default Programs]**; Type: **[mpv]** on **[Search apps]**; Click: **[mpv]** and then finally [Set default file types or link types] to mpv  
8. Download or clone this repository to extract the [`portable_config`](https://github.com/PopeyeURS/ulyssescaballes-mpv.config/archive/refs/heads/main.zip) folder  
9. Place the "portable_config" folder here:  
"C:/Users/<user_name>/AppData/Roaming/MPV/portable_config"  
10. Place the Kemar_HRTF_sofa.sofa file here:  "C:/Users/<user_name>/AppData/Roaming/MPV/portable_config/scripts/sofalizer/Kemar_HRTF_sofa.sofa"  
11. Place the SADIE KEMAR BRIR file here:  
"C:/Users/<user_name>/AppData/Roaming/MPV/portable_config/scripts/sofalizer/SADIE_KEMAR_DFC_256_order_fir_48000.sofa"  
12. **VERY IMPORTANT**: Replace the <user_name> with your system username, on sofalizer's "main.lua", otherwise "KEMAR_SOFA" and "SADIE_BRIR" will not be activated.  

```
%APPDATA%\mpv\portable_config\
│
├── mpv.conf
├── input.conf
├── profiles.conf
├── script-opts\
├── scripts\
│   └── sofalizer\
│       ├── Kemar_HRTF_sofa.sofa
│       ├── SADIE_KEMAR_DFC_256_order_fir_48000.sofa
│       └── main.lua
└── shaders\
    ├── CuNNy-8x32-DS.glsl\
    ├── SSim\
    ├── Adaptive_sharpen\
    └── Depth_reality_boost\
```

13. Ensure MPV is configured to use **Vulkan**:  

```
gpu-api=vulkan
```

14. Launch MPV — the configuration activates automatically. You may now double-click any media file on your PC, or run a CD, a DVD or a BluRay disc and MPV plays it with your choice of Enhanced Headset mode [F9] or Ultimate Cinema mode [F10] or Music Hall mode [F11] enabled. Enjoy the experience.  

---

### Audio Chain & Usage Note

- **F9** → Enhanced Headset Mode Activated  
- **F10** → Enhanced Cinema Mode Activated  
- **F11** → Music Mode Plus Activated  
- **F12** → Reset Filters Activated  

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
| **Volume Max**        | `volume-max=130`   | Allows boosting volume beyond 100% (use with care to avoid distortion).|

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

## MPV + YouTube Integration  
Instructions on how to enable MPV to directly open and play YouTube streams from a web browser **(Exclusively applicable only on a Firefox browser or on any Firefox based variant)**:  
1. Download and install Firefox web browser or any of its variant, [`Floorp`](https://floorp.app/download) browser is highly recommended.  
2. Install browser extension: [`ff2mpv (for Windows)`](https://addons.mozilla.org/en-US/firefox/addon/ff2mpv-for-windows/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search) from FireFox Browser ADD-ONS.  
3. Download: [`ff2mpv-master.zip`](https://github.com/eastmarch/ff2mpv/archive/master.zip)  
4. Extract "ff2mpv-master.zip" inside [MPV] folder.  
5. Open "ff2mpv-master" folder, copy "ytdlProtocol.bat" then paste it outside "ff2mpv-master" folder to sit where "mpv.exe" is placed inside [MPV] folder, here:  
"C:/Users/<user_name>/AppData/Roaming/MPV/ytdlProtocol.bat".  
6. Right click "ytdlProtocol.bat", then "Run as Administrator" once.  
7. Reboot your PC.  
8. Open YouTube on your Firefox browser, select and right-click on any video stream available on display, scroll down the context menu and click "Play link in MPV". MPV plays the selected video stream directly from YouTube with maximum audio/video quality playback. Enjoy the experience.  

---

## Philosophy
This configuration is built on three principles:

### Precision  
Every shader, value, and filter is chosen with intent — no bloat, no placebo settings.

### Cinematic Realism  
The goal is not “sharper” or “brighter,” but **truer** — depth, texture, and natural contrast.

### Modularity  
✓ Everything is remixable.  
✓ Every file is documented.  
✓ Every profile is optional.  

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
<hr>

<p align="center">
Playback perfection isn’t measured in numbers alone — it’s defined by how it feels.  
This hand‑crafted cinema engine reflects my journey toward that feeling.  
If it helps you step closer to your own, then it has fulfilled its purpose.
</p>

<p align="center"><b>||||⚓ Ulysses RS Caballes [PopeyeURS]</b></p>
<p align="center"><i>Crafting cinema in pixels, one shader at a time.</i></p>

<hr>

---

## License  
**License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)**  
This project is licensed under the GNU General Public License v3.0. Feel free to fork, adapt, and share.

See the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <a href="#top"><b>⬆️ Back to top</b></a>
</p>

