UlyssesCaballes’ MPV Configuration
Artifact‑free. Vivid. Cinematic. Adaptive.
<p align="left"><img src="https://img.shields.io/badge/License-GPLv3-blue"><img src="https://img.shields.io/badge/GPU-Vulkan%20Optimized-orange"><img src="https://img.shields.io/badge/config-remixable-green"><img src="https://img.shields.io/badge/MPV-v0.40%2B-blue"><img src="https://img.shields.io/badge/Platform-Windows%2011-lightgrey"><img src="https://img.shields.io/badge/GLSL-Custom%20Pipeline-purple"><img src="https://img.shields.io/badge/Playback-Cinematic%20HDR%208K-critical"><img src="https://img.shields.io/badge/Profiles-Anime%2C%20Realism%2C%208K%2C%20Sports-green"><a href="#repo-hygiene"><img src="https://img.shields.io/badge/Repo-Clean%20%26%20Cache-Free"></a></p>
A modular, Vulkan‑optimized MPV configuration designed for realism, depth, and clarity.
Every profile, shader, and Lua script works together to deliver cinema‑grade playback across anime, films, sports, and 8K HDR content — without artifacts, without clutter, and without compromise.

Table of Contents
• 	Features
• 	Requirements
• 	Demo Clip
• 	Screenshots
• 	Shader Pipeline
• 	Profiles
• 	Profile Switching
• 	Script Suite
• 	Quick Start
• 	Installation
• 	Optional Add-ons
• 	Philosophy
• 	Repo Hygiene
• 	License

Features
• 	Fade‑aware debanding + fruit dithering
• 	BT.2390 tone mapping with contrast recovery
• 	Custom GLSL pipeline for super‑resolution, sharpening, depth, and film emulation
• 	Tuned scaling, interpolation, and subtitle styling
• 	Modular profiles: anime, realism, sports, 8k
• 	Vulkan‑optimized GPU context
• 	Lua automation for adaptive playback and shader recovery
• 	Clean, cache‑free, remixable structure

Requirements
• 	MPV v0.40+
• 	Vulkan‑capable GPU (NVIDIA recommended)
• 	Windows 11 (or Linux/macOS with Vulkan)
Download MPV (Shinchiro builds):
https://github.com/shinchiro/mpv-winbuild-cmake/releases
Extract MPV → place this repo’s  folder inside the MPV directory.

Demo Clip
Experience the configuration in action:
Download the 8K MPV Demo Clip
Rendered and played using this exact setup (HEVC Main 10, tone mapping, full shader fidelity).

Screenshots
Real‑world playback examples:
Screenshot 1
Debanding and tone mapping — smooth gradients, lifelike contrast.
Screenshot 2
Styled subtitles and shader stack delivering cinematic realism.

Shader Pipeline


Profiles
Defined in :
• 	8k – HDR60, ultra‑high‑res tuning
• 	realism – cinematic tone mapping + full shader stack
• 	anime – line‑art clarity + upscaling
• 	sports – motion‑optimized playback
• 	webtorrent‑entries – disables memo script
Run with:


Profile Switching
Instant profile switching via :

Styled OSD Flash
Profile names appear at the top center with subtitle‑matched styling.
Example:


Script Suite
A modular Lua ecosystem that enhances fidelity, automation, and UX.
Core automation
• 	 – Resolution/framerate‑aware profile switching
• 	 – Anime‑specific tuning
• 	 – Ultra‑high‑res routing
• 	 – Realism for 720p–1080p
• 	 – Reapplies shaders after dropped frames
Utility & UX
• 	 – Persistent playback memory
• 	 – Audio/subtitle track logic
• 	 – Window geometry automation
• 	 /  – In‑player console & stats
• 	 – Performance metrics
• 	 – Fast thumbnails
• 	 – Spatial audio
• 	 – Danmaku overlay
• 	 – UOSC‑based video & subtitle menus
Extend the setup
1. 	Place  files in 
2. 	Add keybinds in 
3. 	Configure via  (optional)

Quick Start
1. 	Download or clone this repository
2. 	Place the config inside your MPV directory
3. 	Launch MPV and enjoy cinematic, artifact‑free playback

Installation
Place these files in your MPV config directory:
• 	, 
• 	Optional shaders and Lua scripts
Paths
• 	Windows: 
• 	Linux/macOS: 
Modular profiles (e.g., , ) can be loaded automatically or via command‑line/profile switching.

Optional Add-ons
Additional  and  modules can extend fidelity, automation, and styling.
Examples:
• 	 – Line‑art and upscaling tuning
• 	 – Async compute & queue optimization
• 	 – Subtitle presets
• 	 – Persistent playback state
• 	 – Styled frame captures
Add‑ons are opt‑in and clutter‑free.

Philosophy
Playback perfection is a feeling — not a spec sheet.
This configuration is built to honor the source, preserve realism, and adapt intelligently to every frame.
If it brings you closer to your ideal cinematic experience, it has done its job.
— Ulysses RS Caballes (PopeyeURS)

Repo Hygiene
Cache‑free, modular, and actively maintained.
No clutter — just precision.

License
Licensed under GPLv3.
MIT‑licensed components (e.g., UOSC) retain their original notices and remain compatible.
