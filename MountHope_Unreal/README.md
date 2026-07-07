# Mount Hope Unreal

Unreal Engine 5 vertical-slice track for **Mount Hope**, a single-player
PC/console open-world crime game set on a fictionalized but OSM-grounded
Massachusetts South Coast.

This branch is separate from the canonical web slice. The web project remains
the playable reference for the current concept, controls, map data, and tone;
the Unreal project is the premium PC/console path.

## Target

- **Genre:** GTA-like third-person open-world crime game.
- **Tone:** grounded adult crime and stylized satire, with a minor New England
  Gothic thread inspired by regional folklore and Lizzie Borden-era history.
- **Visual bar:** UE5 cinematic realism with photoreal materials, lighting,
  vehicles, streets, weather, and characters.
- **Mode:** strictly single-player.
- **First slice:** full vertical slice, not just a tech demo.

## First playable loop

1. Walk the player through an OSM-derived South Coast district.
2. Enter and exit a heavy, cinematic-feeling vehicle.
3. Drive real roads with authored shortcuts and fictionalized adjustments.
4. Meet mission NPCs and trigger a short crime/satire mission.
5. Earn and spend money through a minimal economy.
6. Support short dialogue exchanges for mission setup and world flavor.

## Project layout

| Path | Purpose |
| --- | --- |
| `MountHope.uproject` | UE 5.8 project descriptor with Enhanced Input, Chaos Vehicles, Mass AI/Entity, and Water enabled. |
| `Source/MountHope/` | Hybrid C++ foundation for game mode, player pawn, vehicle pawn, interactions, missions, economy, and OSM world source metadata. |
| `Config/` | Initial maps, renderer, navigation, packaging, and input settings. |
| `Content/` | Empty UE asset root; create maps, Blueprints, materials, vehicles, MetaHumans, and imported OSM meshes here in the editor. |
| `Data/` | Mission and economy JSON consumed at startup by `UMHGameInstance`. |
| `Docs/` | Vertical-slice, OSM migration, and improvement-plan notes. |
| `Scripts/` | Sandbox-safe validation (`validate_scaffold.py`) and local compile helper (`build.sh`). |

## Build & validate

### CI (no Unreal install required)

GitHub Actions runs `Scripts/validate_scaffold.py` on changes under
`MountHope_Unreal/` (see `.github/workflows/unreal-ci.yml`).

```bash
python3 MountHope_Unreal/Scripts/validate_scaffold.py
```

### Local compile (requires Unreal Engine 5.8)

**Windows (PowerShell):**

```powershell
cd MountHope_Unreal
.\Scripts\build.ps1
```

See [`Docs/BUILD_WINDOWS.md`](Docs/BUILD_WINDOWS.md) for Visual Studio prerequisites, Epic Launcher paths, and troubleshooting.

**macOS / Linux:**

```bash
export UE_ROOT="/path/to/UE_5.8"
./MountHope_Unreal/Scripts/build.sh
```

See `Docs/IMPROVEMENT_PLAN.md` for the full roadmap and packaging notes.

**First playable in editor:** `Docs/EDITOR_SETUP.md` (or run
`Scripts/editor_bootstrap_vertical_slice.py` inside the editor).

## Open in Unreal

1. Install Unreal Engine 5.8 via the Epic Games Launcher.
2. Open `MountHope_Unreal/MountHope.uproject`.
3. Let Unreal generate IDE files and compile the `MountHope` module.
4. Create `/Game/Maps/MH_VerticalSlice` as an Open World map.
5. Add Blueprint children for `MHPlayerCharacter` and `MHVehiclePawn`.
6. Import OSM-derived road/water geometry using `Docs/OSM_TO_UNREAL.md`.

## Existing source material

- Web gameplay reference: `../QUAHOG_Web/`
- OSM city data and baked meshes: `../quahog-project-files/mapdata/`
- Current web slice map: `../QUAHOG_Web/public/slice-newbedford.json`

The first Unreal pass should reuse the existing South Coast data while leaving
room to add Brockton or a combined fictionalized map once the OSM acquisition
pipeline is extended.
