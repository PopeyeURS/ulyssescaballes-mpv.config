# Ulysses' MPV Configuration  
**Artifact-free. Vivid. Cinematic. Adaptive.**

![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue)  
![GPU: Vulkan Optimized](https://img.shields.io/badge/GPU-Vulkan%20Optimized-orange)  
![Config: Remixable](https://img.shields.io/badge/config-remixable-green)  
![MPV Compatible](https://img.shields.io/badge/MPV-v0.40%2B-blue)  
![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2011-lightgrey)  
![Shader Stack](https://img.shields.io/badge/GLSL-Custom%20Pipeline-purple)  
![Playback Fidelity](https://img.shields.io/badge/Playback-Cinematic%20HDR%208K-critical)  
![Profiles](https://img.shields.io/badge/Profiles-Anime%2C%20Realism%2C%208K%2C%20Sports-green)  
[![Repo Hygiene](https://img.shields.io/badge/Repo-Clean%20%26%20Cache-Free)](#repo-hygiene)  

This is my personal MPV config, refined through countless iterations to achieve playback that’s both technically precise and aesthetically faithful. Every frame is tuned for realism, depth, and clarity—without compromise.

---

## Table of Contents  
- [Features](#features)  
- [Configuration Overview](#configuration-overview) 
- [System Requirements](#system-requirements)  
- [Download MPV](#download-mpv)  
- [Screenshots](#screenshots)  
- [Philosophy](#philosophy)  
- [Shader Pipeline](#shader-pipeline)  
- [Profiles & Automation](#profiles--automation)
- [Profile Switching](#profile-switching-via-inputconf)  
- [Script Suite](#script-suite)  
- [Lua Scripts](#lua-scripts)  
- [Quick Start](#quick-start)  
- [Installation](#installation)  
- [Optional Add-ons](#optional-add-ons)  
- [Inspiration](#inspiration)
- [Sharing the Philosophy](#sharing-the-philosophy)  
- [Repo Hygiene](#repo-hygiene)  
- [License](#license)

---

## Features  
- Artifact-free playback with fade-aware debanding and fruit dithering  
- Cinematic tone mapping (BT.2390) with contrast recovery and zimg precision  
- Custom GLSL shader stack for realism, depth, and analog texture  
- Sharp video playback with tuned scaling and interpolation  
- Styled subtitles for legibility and harmony  
- Modular profiles for anime, realism, 8K HDR60, and sports  
- Vulkan-tuned GPU context with async compute and queue optimization  
- Clean window geometry and cursor behavior for immersive viewing  
- Lua automation for adaptive playback and shader recovery  
- Disk-conscious cache and watch_later management

---


## Configuration Overview  
This configuration is built around modular precision and adaptive fidelity. At its core is `mpv.conf`, a Vulkan-optimized playback blueprint that loads `profiles.conf` to dynamically tailor playback for different content types—anime, realism, 8K HDR, and sports.

Each profile adjusts tone mapping, shader stacks, scaling algorithms, and interpolation settings to suit the source material. Lua scripts extend this adaptivity by responding to resolution, framerate, and performance conditions in real time.

Key components include:  
- **`mpv.conf`** – The main configuration file, tuned for cinematic realism, artifact-free playback, and Vulkan acceleration.  
- **`profiles.conf`** – Modular profile definitions for genre-specific tuning and resolution-aware playback.  
- **GLSL Shader Stack** – A curated pipeline of super-resolution, sharpening, depth enhancement, and analog texture shaders.  
- **Lua Scripts** – Runtime automation for profile switching, shader recovery, and vocal EQ enhancement.  
- **Optional Add-ons** – Genre-specific `.conf` files and utility scripts that extend functionality without clutter.

This setup is designed to be remixable, cache-free, and performance-conscious—whether you're watching anime at 1080p or HDR cinema at 8K60.

---

## System Requirements  
- MPV v0.40 or newer  
- Vulkan-capable GPU (NVIDIA recommended)  
- Windows 11 or Linux/macOS with Vulkan support

## Download MPV  
[![Download MPV](https://img.shields.io/badge/Download-MPV%20%28Shinchiro%29-blue)](https://github.com/shinchiro/mpv-winbuild-cmake/releases)

To run this configuration, you'll need a recent build of [MPV for Windows](https://github.com/shinchiro/mpv-winbuild-cmake/releases) by Shinchiro.

These builds are:
- Actively maintained
- Compatible with Vulkan and GPU-next
- Ideal for modular configs like this one

Just download the latest `.7z` or `.zip` release, extract it, and drop in your `portable_config` folder.

---

## Demo Clip

[Download the 8K MPV Demo Clip](video/ulyssescaballes-8k_video_demo.mkv)

This clip was rendered and played using my MPV config with HEVC Main 10, tone mapping, and shader fidelity. Open it in MPV to experience the full effect.

---

## Screenshots

Here’s how the config performs in real-world playback:

![Screenshot 1](images/screenshot1.png)  
*Debanding and tone mapping in action — smooth gradients, lifelike contrast.*

![Screenshot 2](images/screenshot2.png)  
*Styled subtitles and shader stack delivering cinematic realism.*

---

## Philosophy  
This config isn’t just about suppressing artifacts—it’s about honoring the source. It reflects a balance between technical rigor and visual sensitivity:

- **Tone Mapping**: BT.2390 with contrast recovery and zimg mode for natural highlight roll-off and lifelike skin tones  
- **Sharpening**: Controlled, halo-free sharpening that enhances detail without edge ringing  
- **Debanding & Dithering**: Fade-aware debanding and fruit dithering for smooth gradients and cinematic fades  
- **GPU API**: Tuned for Vulkan, with fallback stability on D3D11  
- **Subtitles**: Styled for legibility and visual harmony  
- **Adaptivity**: Lua scripts respond to resolution, framerate, and dropped frames to maintain fidelity without stutter

---

## Shader Pipeline  
[Input Frame]  
↓  
FSRCNNX_x2_16-0-4-1_enhanced.glsl       # Super-resolution  
↓  
SSimSuperRes.glsl                       # Perceptual sharpening  
↓  
Adaptive-sharpen-0.30.glsl              # Very subtle sharpening  
↓  
Glimmer_sharpen_0.41.glsl		            # Edge clarity  
↓  
Depth_reality_boost.glsl                # Enhanced depth  
↓  
Kodak_2383_Procedural.glsl              # Film Emulation  
↓  
[Final Output]  

---

## Profiles & Automation

### Profiles (via `profiles.conf`)
- `8k`: Optimized for ultra-high-res HDR60 playback  
- `realism`: Cinematic tone mapping and full shader stack for 1080p–4K content  
- `anime`: Genre-specific enhancements for line art and upscaling  
- `sports`: High-motion clarity for fast-paced content  
- `webtorrent-entries`: Disables memo script for WebTorrent playback

To use a profile:
```bash
mpv --profile=realism video.mkv
```

### Profile Switching (via `input.conf`)

Switch between playback profiles in real time using function keys. These keybinds trigger `auto_profiles.lua` to apply the corresponding profile instantly:

| Key  | Profile         | Description                                      |
|------|------------------|--------------------------------------------------|
| `F1` | `anime-hdr`      | HDR anime stack with glow, depth, and line-art clarity |
| `F2` | `realism`        | Cinematic tone mapping and full shader stack    |
| `F3` | `sports`         | High-motion clarity for fast-paced content      |
| `F4` | `classic-film`   | Warm tone mapping and subtle grain for vintage cinema |
| `F5` | `8k`             | Optimized for ultra-high-res HDR60 playback     |

To enable OSD feedback when switching, append `; show-text "Profile: [name]"` to each keybind in `input.conf`.

Example:
```ini
F2 script-message-to auto_profiles apply-profile realism ; show-text "Profile: Realism"
```
### Script Suite

## Lua Script Reference

These scripts extend MPV’s playback fidelity, automation, and user experience. Each is modular, keybind-triggered, and designed for remixability.

| Script Name               | Purpose / Behavior                                             | Keybind (if any) | Config File        | Status     |
|---------------------------|----------------------------------------------------------------|------------------|--------------------|------------|
| `auto_profiles.lua`       | Applies profiles based on resolution/framerate or manual keybind | `F1–F5`          | —                  | ✅ Active  |
| `auto-profile-anime.lua`  | Applies anime-specific profile for stylized content            | —                | —                  | ✅ Active  |
| `auto-profile-8k.lua`     | Applies 8K profile for ultra-high-res content                  | —                | —                  | ✅ Active  |
| `midrange-boost.lua`      | Applies realism profile for 720p–1080p content                 | `b`              | —                  | ✅ Active  |
| `shader-recovery.lua`     | Reapplies shaders if dropped frames are detected               | `r`              | —                  | ✅ Active  |
| `memo.lua`                | Persistent playback memory across sessions                     | —                | —                  | ✅ Active  |
| `celebi.lua`              | Experimental profile routing and diagnostics                   | —                | —                  | ✅ Active  |
| `commands.lua`            | Custom command dispatcher for script messaging                 | —                | —                  | ✅ Active  |
| `select.lua`              | Track selection logic for audio/subs                          | —                | `select.conf` (optional) | ✅ Active  |
| `positioning.lua`         | Window geometry and placement automation                       | —                | `positioning.conf` (optional) | ✅ Active  |
| `console.lua`             | In-player command console                                      | `~`              | —                  | ✅ Active  |
| `stats.lua`               | On-screen playback stats                                       | `` ` ``          | —                  | ✅ Active  |
| `benchmark_overlay.lua`   | Performance overlay for benchmarking                           | —                | —                  | ✅ Active  |
| `thumbfast.lua`           | Fast thumbnail previews                                        | —                | —                  | ✅ Active  |
| `sofalizer/main.lua`      | Spatial audio simulation                                       | —                | —                  | ✅ Active  |
| `youtube_danmaku.lua`     | Danmaku overlay for YouTube videos                             | —                | —                  | ✅ Active  |
| `uosc_subtitle_settings.lua` | Subtitle styling menu via UOSC                            | —                | —                  | ✅ Active  |
| `uosc_video_settings.lua` | Video settings menu via UOSC                                   | —                | —                  | ✅ Active  |

### How to Extend

To add your own Lua scripts:

1. Drop them into `portable_config/scripts/`
2. Bind them via `input.conf`
3. Optionally configure via `script-opts/*.conf`

Each script is modular—use only what enhances your workflow. Playback remains yours to shape.

## Lua Scripts  
These automation scripts dynamically adapt playback based on content and performance:

- `auto-profile.lua`: Triggers the appropriate profile based on resolution or framerate  
- `midrange-boost.lua`: Activates the `realism` profile for mid-range content (720p–1080p)  
- `shader-recovery.lua`: Disables and re-enables shaders based on dropped frames to maintain smooth playback

Together, these scripts ensure cinematic fidelity without stutter or compromise.

## Quick Start  
Get up and running in three steps:

1. Clone or download this repository  
2. Place the config files in your MPV directory  
3. Launch MPV and enjoy cinematic, artifact-free playback

## Installation  
Place the following files in your MPV config directory:

- `mpv.conf` and `profiles.conf`  
- Optional Lua scripts and shader files

**Paths**:  
- Windows: `%APPDATA%\mpv\`  
- Linux/macOS: `~/.config/mpv/`

If using modular profiles (e.g., `anime.conf`, `realism.conf`), include them in the same directory and load them via command-line or profile switching.

### Optional Add-ons  
This config supports modular enhancements that elevate playback fidelity, automation, and aesthetic control. These addons are **not bundled** in the repo—they’re opt-in components you can integrate manually.

Each one is designed to complement the core config without clutter, preserving your setup’s elegance and precision.

#### Addon Highlights  
- `anime.conf` – Genre-specific tuning for line art, upscaling, and stylized motion  
- `vulkan-tweaks.conf` – Vulkan overrides for async compute and queue optimization  
- `sub-style.conf` – Subtitle styling presets for visual harmony across genres  
- `watch_later.lua` – Persistent playback state for seamless session recovery  
- `frame-capture.lua` – Capture styled frames for documentation or archival  
- `auto-profile.lua` – Lua automation that adapts profiles to resolution and framerate in real time  

#### How to Use  
1. Download the addon file (`.conf` or `.lua`) from the linked source or community repo  
2. Place it in your `portable_config` directory (`scripts` or root, depending on type)  
3. Activate via `mpv.conf`, `profiles.conf`, or command-line flags  

These addons are modular by design—use only what enhances your workflow. Playback remains yours to shape.

---

## Inspiration  
This configuration was originally inspired by [itsmeipg-mpv.config](https://github.com/itsmeipg/mpv-config/), whose modular design and shader philosophy laid the groundwork for my own playback journey. Its influence remains deeply appreciated.

---

## Sharing the Philosophy  
This config is meant to be shared, forked, and adapted. Whether you're chasing artifact-free playback or building your own modular stack, feel free to use this as a foundation.

I welcome feedback, questions, and collaboration. Let’s refine playback together.

---

## Final Word  
Playback perfection isn’t just about numbers—it’s about how it feels. This config reflects my journey toward that feeling. If it helps you get closer to yours, then it’s done its job.

— **Ulysses RS Caballes [PopeyeURS]**

---

## Repo Hygiene  
This config is cache-free, modular, and actively maintained. No leftover artifacts, no broken links—just playback precision.

---

## License
  
**License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)**  
This project is licensed under the GNU General Public License v3.0. Feel free to fork, adapt, and share.

I believe in modular, artifact-free playback and open collaboration. If you improve or remix this config, I’d love to hear about it!

### Third-Party Components

This repository includes components from [uosc](https://github.com/tomasklaen/uosc), a user interface script for MPV licensed under the MIT License. While this configuration is licensed under GPLv3, the inclusion of MIT-licensed code is permitted and compatible.
MIT-licensed files retain their original license notices and are used respectfully under the terms of the GPLv3 umbrella.

See the [LICENSE](LICENSE) file for details.
