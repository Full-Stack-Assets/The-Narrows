# The Narrows

*The Narrows — South Coast · Now* is an original open-world crime drama set on
the real Massachusetts South Coast in the present day (2026). It uses real
New Bedford and Fall River geography with original characters, factions,
missions, and businesses.

“Mount Hope” and “Project QUAHOG” are retired working titles. Mount Hope Bay
remains an in-world geographic name. See
[`plans/the-narrows.md`](plans/the-narrows.md) and
[`docs/product/source-of-truth.md`](docs/product/source-of-truth.md).

## Product hierarchy

| Track | Role |
|---|---|
| `QUAHOG_GODOT1/` | **Ship target** — Godot 4.6, GL Compatibility, Web/mobile |
| `QUAHOG_Web/` | Behavior/content reference and independently deployed comparison build |
| `MountHope_Unreal/` | Separate premium PC/console research track |
| `QUAHOG_Unity/`, `QUAHOG_Godot/`, `QUAHOG_Unreal/` | Legacy/reference |

Only the Godot ship target may make completion claims for the main product.
Web and Unreal status must be labeled with their track.

## Run and verify the ship target

Install Godot 4.6 stable, then:

```bash
cd QUAHOG_GODOT1
godot --editor --path .
```

The strict verification entry point is introduced by the active completion
plan:

```bash
cd QUAHOG_GODOT1
GODOT_BIN=godot bash scripts/verify.sh
```

Current Godot Web deployment: <https://quahog.vercel.app/>

Reference web deployment: <https://projectsouthcoast.vercel.app/>

Neither URL is considered current unless its displayed commit SHA matches the
source SHA being evaluated.

## Shared map and design data

- `quahog-project-files/mapdata/` — OpenStreetMap extraction and slice pipeline.
- `quahog-project-files/CHARACTERS_AND_MISSIONS.md` — current story canon.
- `quahog-project-files/STYLE_GUIDE.md` — present-day Coastal Noir art direction.
- `plans/mount-hope.md` — historical master checklist and running log, now
  reconciled to The Narrows/Godot hierarchy.
- `docs/superpowers/plans/2026-07-29-the-narrows-godot-completion.md` — active
  completion plan.

## Legal

This is original work and is not affiliated with or endorsed by Rockstar Games
or Take-Two Interactive. GTA titles are tonal/mechanical references only.
Map data © OpenStreetMap contributors, ODbL. Ship fictionalized brands rather
than real vehicle or weapon trademarks.
