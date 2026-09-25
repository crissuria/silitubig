# Credits and Asset Attribution

**Sili-Tubig Clash** — F.I.R.E.S DEV
University of La Salette, Inc. — College of Information Technology
CODE & CONQUER Cagayan Valley: E-Sports Game Dev Challenge (RSTW 2026, DOST Region 2)

This file is the authoritative list of everything in this repository that the
team did not author.

---

## Team

| Name | Role |
|---|---|
| Janelle Ann F. Castillo ([nncast](https://github.com/nncast)) | Team Leader / Developer |
| Stefane B. Cerezo ([cerezostefaneballad-hash](https://github.com/cerezostefaneballad-hash) / [stfcrz11](https://github.com/stfcrz11)) | Developer |
| Romar D. De Asis ([marmearaimang](https://github.com/marmearaimang)) | QA / Dev Support |
| Hazel B. Sebastian ([Sebastian-Zee](https://github.com/Sebastian-Zee)) | Game Designer / Artist |
| Cristian P. Sudaria ([crissuria](https://github.com/crissuria)) | Game Artist / Dev Support |

Faculty Coach: [Jayson S. Nacorda, MIT](https://github.com/ULSJaysonNacorda)

---

## Engine

| Component | Author |
|---|---|
| Godot Engine 4.x | Godot Engine contributors |

---

## Third-party assets

### Graphics

| Asset | Files | Author |
|---|---|---|
| [Modern Exteriors](https://limezu.itch.io/modernexteriors) | `assets/tilemap/*_16x16.png` (Terrains and Fences, City Terrains, City Props, Villas, Additional Houses, Vehicles, Camping, Beach, Godot Autotiles) | [LimeZu](https://limezu.itch.io/) |
| [Character Templates Pack](https://erisesra.itch.io/character-templates-pack) | `assets/sprites/16x16 Sili.png`, `assets/sprites/16x16 Tubig.png` | [EsriEsra](https://erisesra.itch.io/) |
| [Beries Adventure Seaside](https://crusenho.itch.io/beriesadventureseaside)| `assets/ui/UI_Flat_*.png`, `assets/ui/Hud_Menu/UI_Flat_*.png` | [Crusenho](https://crusenho.itch.io/) |

### Fonts

| Asset | Files | Author |
|---|---|---|
| [BoldPixels](https://yukipixels.itch.io/boldpixels) | `assets/fonts/BoldPixels.ttf` | [Yūki](https://yukipixels.itch.io/) ([@YukiPixels](https://www.instagram.com/yukipixels)) |

CC BY-SA 4.0 requires attribution. The author's requested credit line is:

> BoldPixels Font by [[Yūki](https://yukipixels.itch.io/)] ([@YukiPixels](https://www.instagram.com/yukipixels))


### Audio

| Asset | Files | Author |
|---|---|---|
| [Music Loop Bundle](https://tallbeard.itch.io/music-loop-bundle) | `assets/audio/music/Music_Title.ogg`, `Music_Ingame.ogg` | [Tallbeard Studios](https://tallbeard.itch.io/) |
| [Tactical Soundtracks: Game Music Pack](https://rgb-teamblue.itch.io/operation-soundtrack-music-for-high-stakes-scenarios) | `assets/audio/music/*` (danger/tension cues — confirm exact files) | [RGB_DanniBear](https://x.com/DannibearBlue) |
| [Universal UI/Menu Soundpack](https://cyrex-studios.itch.io/universal-ui-soundpack) | `assets/audio/ui/ui_click.wav`, `ui_hover.wav` | [CyrexStudios](https://cyrex-studios.itch.io/) |
| [Ocean ambience loop](https://nox-sound-design.itch.io/essentials-series-sfx-nox-sound) | `assets/audio/ambiance/Ambiance_Ocean_Praia_dos_Moinhos_Loop_Stereo_02.wav` | [Nox_Sound](https://nox-sound-design.itch.io/) |

---

## Original work by the team

Everything below was authored by F.I.R.E.S DEV and is owned by the team.

### Source code

All GDScript in `autoloads/`, `entities/`, `levels/`, `ui/`, and `tools/`.
No code was copied from tutorials, templates, open-source projects, or other
developers. AI assistance was used during development and is disclosed in the
section below.

### Audio

Every footstep sample and every gameplay sound effect is **synthesised from
scratch** by `tools/generate_audio.py`, a numpy/scipy script written by the
team. Nothing was sampled, recorded from a library, or downloaded.

- `assets/audio/footsteps/{sand,grass,road,stairs,water}/{walk,run}_NN.wav` — 40 files
- `assets/audio/sfx/*.wav` — 11 files

The generator is committed to the repository and is deterministic (fixed random
seed), so any judge can reproduce every one of these files byte-for-byte by
running:
