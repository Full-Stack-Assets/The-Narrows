# The Narrows Product Source of Truth

## Locked product decisions

| Topic | Decision |
|---|---|
| Product | The Narrows |
| Subtitle | South Coast · Now |
| Setting | Massachusetts South Coast, present day (2026) |
| Ship target | `QUAHOG_GODOT1/` |
| Engine | Godot 4.6 stable, GL Compatibility |
| Current platforms | Web and mobile browser |
| Reference implementation | `QUAHOG_Web/` |
| Premium research track | `MountHope_Unreal/` |
| Legacy tracks | `QUAHOG_Unity/`, `QUAHOG_Godot/`, `QUAHOG_Unreal/` |

“Project QUAHOG” and “Mount Hope” are retired product titles. Mount Hope Bay
may appear as geography.

## Canon hierarchy

1. This file controls product, era, and engine role.
2. `plans/the-narrows.md` controls title language and present-day brand.
3. `quahog-project-files/CHARACTERS_AND_MISSIONS.md` controls current story and
   character canon.
4. `quahog-project-files/STYLE_GUIDE.md` controls visual direction when it
   agrees with the present-day brand.
5. `plans/mount-hope.md` is the historical feature inventory/running log.
6. Legacy GDDs and 1986 atlases are inspiration only.

When two sources conflict, the earlier item in this list wins.

## Track responsibilities

### `QUAHOG_GODOT1/`

The only track that can satisfy the main-product completion definition.

Required release evidence:

- strict Godot import;
- automated Godot tests;
- release Web export;
- browser/device release matrix;
- exact in-game commit SHA matching the deployed source;
- save compatibility record.

Production URL: <https://quahog.vercel.app/>

### `QUAHOG_Web/`

Behavior/content reference and independent comparison deployment. Use it to
understand intended systems, not to prove Godot completion.

Reference URL: <https://projectsouthcoast.vercel.app/>

### `MountHope_Unreal/`

Separate premium PC/console research track. It requires real Unreal Engine 5.8
compile and editor evidence and does not replace the current ship target.

## Naming and content rules

- New player-facing copy uses The Narrows.
- New era references use present-day language; do not add 1986-only props as a
  governing requirement.
- GTA and other commercial games are tonal/mechanical references only.
- Vehicle, weapon, business, radio, and faction brands ship as original
  fictionalized content.
- Google 3D Tiles, ElevenLabs, and other hosted services remain optional; the
  core game must work without their keys.

## Development and release rules

- Work on a feature branch and merge through review.
- Do not fast-forward and push directly to `main` as the ordinary loop.
- Keep import, tests, and export green at every completed task.
- Do not mark a campaign beat complete from a title and reach marker alone.
- Do not expand regions before the opening New Bedford release gate passes.
- Every deployment record includes track, URL, commit SHA, build date,
  verification date, and verifier.
