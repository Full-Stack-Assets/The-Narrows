# Phase 1 — Editor setup (first playable)

Follow this checklist after compiling the C++ module locally. It turns the
code scaffold into a graybox you can walk and drive in Play-In-Editor (PIE).

**Prerequisites**

- Unreal Engine 5.8 installed
- Project compiled (`./Scripts/build.sh` or editor compile on first open)
- `python3 Scripts/validate_scaffold.py` passes

**Estimated editor time:** one focused session (map, two Blueprints, one vehicle,
PIE smoke test).

---

## Quick path (automated)

Run these scripts in order via **Tools → Execute Python Script…**
(Python Editor Script Plugin required):

| Order | Script | Purpose |
| --- | --- | --- |
| 1 | `editor_bootstrap_vertical_slice.py` | Map, player start, vehicle, Deacon Mealy NPC |
| 2 | `editor_create_enhanced_input.py` | `IMC_Default` + Input Actions |
| 3 | `editor_import_osm.py` | `southcoast.obj` blockout + slice road splines |
| 4 | `editor_import_southcoast_roads.py` | Denser OSM roads near waterfront (optional) |
| 5 | `editor_setup_navmesh.py` | Nav Mesh Bounds Volume + path build |

Then complete manual vehicle mesh/Chaos wheel setup (§4) and press **Play**.

---

## Manual path (step by step)

### 1. Compile and open

```bash
export UE_ROOT="/path/to/UE_5.8"
./MountHope_Unreal/Scripts/build.sh
```

Open `MountHope_Unreal/MountHope.uproject`. Allow C++ compile if the editor
prompts.

Confirm **Output Log** on startup shows:

- `MountHope: Loaded slice '…' (N roads, …)`
- `MountHope: Loaded N missions`
- `MountHope: Loaded N businesses`
- `MountHope: Objective -> Meet Deacon Mealy at Seamen's Bethel`

If slice load fails, check that `../QUAHOG_Web/public/slice-newbedford.json`
exists relative to the project directory.

### 2. Create the vertical-slice map

1. **File → New Level → Open World** (World Partition enabled).
2. **File → Save Current Level As…**
   - Path: `/Game/Maps/MH_VerticalSlice`
3. **Window → World Settings**
   - Game Mode Override: `MHGameModeBase` (or leave project default)
4. **Window → World Partition** → create a grid if prompted (default is fine).

`Config/DefaultEngine.ini` already points startup maps at this path.

### 3. Player character Blueprint

1. **Content Browser → Add → Blueprint Class**
2. Parent: `MHPlayerCharacter` (search “MHPlayerCharacter”).
3. Name: `BP_MHPlayerCharacter` → save under `/Game/Blueprints/`.
4. Open the Blueprint:
   - Add a **Skeletal Mesh** or **Capsule** visual (Mannequin, UE template mesh,
     or placeholder cube on a Scene Component).
   - Confirm **Auto Possess Player** = Player 0 on the placed instance (see §5).
5. **Project Settings → Maps & Modes → Default Pawn Class** → `BP_MHPlayerCharacter`
   (optional; placing a possessed instance in the level is enough for PIE).

### 4. Vehicle Blueprint (Chaos)

1. **Add → Blueprint Class** → parent `MHVehiclePawn` → `BP_MHVehicle`.
2. Open `BP_MHVehicle`:
   - **Mesh**: add a `StaticMesh` or `SkeletalMesh` for the body (sedan-scale).
   - **Chaos Vehicle Movement** component (inherited): configure wheels:
     - Add **Wheel Front Left/Right**, **Wheel Rear Left/Right** scene components
       OR use the Chaos vehicle wizard if available in your UE version.
     - Set wheel class to `ChaosVehicleWheel` Blueprint with radius ~35 cm, suspension
       ~10 cm (tune in PIE).
   - Set **Mass** ~1500 kg, enable **Auto Possess Player** = disabled (player enters via `E`).
3. Place **one** `BP_MHVehicle` in the level near the player start (~10–20 m away).

> Chaos vehicle setup is the slowest step. A bare mesh with four wheel bones/
> sockets is enough for a first drive test.

### 5. Level actors

| Actor | Suggested transform | Notes |
| --- | --- | --- |
| `Player Start` | `(-27200, 0, 200)` | Near first mission target (waterfront). Raise Z after ground exists. |
| `BP_MHPlayerCharacter` | Same as Player Start | Only if not using Player Start alone. |
| `BP_MHVehicle` | `(-27000, 500, 200)` | Within interact range (~350 uu). |
| `Directional Light` | default | Already in Open World template. |
| `Sky Atmosphere` + `Volumetric Cloud` | default | Cinematic baseline from `DefaultEngine.ini`. |
| `Nav Mesh Bounds Volume` | cover play area | Scale to fit graybox; press **P** to visualize nav. |

Save the level.

### 6. Input

**Enhanced Input (recommended)** — run `Scripts/editor_create_enhanced_input.py`
to create `/Game/Input/IMC_Default` and wire actions on `MHPlayerCharacter`.

| Action | Key |
| --- | --- |
| Move | WASD |
| Look | Mouse |
| Sprint | Left Shift |
| Interact / enter vehicle | E |
| Enter/exit vehicle (alt) | F |

**Legacy fallback** — if no Input Actions are assigned, `DefaultInput.ini`
axis/action mappings still work (WASD, mouse, E, F).

### 7. PIE smoke test

1. **Play** (Alt+P).
2. Walk with WASD; mouse look.
3. Approach the vehicle; press **E** or **F** to enter.
4. Drive (Chaos default throttle/brake/steer bindings apply when possessed).
5. Press **E** / **F** to exit.
6. Walk to the first mission trigger (game mode auto-spawns `MHMissionTriggerActor`
   at the “Seamen's Bethel” target). Overlap should log the next objective.

**Pass criteria**

- [ ] Slice JSON loads without errors
- [ ] Player moves on foot (sprint with Left Shift when Enhanced Input is set up)
- [ ] Enter and exit vehicle
- [ ] Talk to Deacon Mealy NPC — press **E** to advance each dialogue line
- [ ] First mission step advances after final dialogue line or trigger overlap
- [ ] Cash increases after rewarded steps

### 8. Dialogue (JSON-driven)

`Data/Dialogue/vertical_slice.json` loads at startup. The bootstrap script places
`MHDialogueNpcActor` at the first mission target with conversation id
`deacon_mealy_harbor_errand`.

- **E** while near NPC: start conversation
- **E** while conversation active: advance lines (on-screen cyan subtitles in PIE)
- Final line with `completeObjective: true` advances the current mission step

Blueprint a custom layout with `Scripts/editor_create_hud_widget.py` (optional).
The C++ `UMHGameHudWidget` builds its own UI at runtime if no Widget Blueprint is assigned.

### 9. HUD & weather

- HUD appears automatically (objective, cash, weather, dialogue)
- Press **.** to cycle weather in PIE

---

## Optional graybox ground

**Automated:** run `Scripts/editor_import_osm.py` to import `southcoast.obj` and
place it at the world origin (100× scale, meters → centimeters). The script
also spawns debug road splines from `slice-newbedford.json` near the vertical
slice (capped at 120 splines for editor performance).

**Manual:** add a large **Plane** or **Landscape**, or import per steps below.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Default map missing on open | Run bootstrap script or create `/Game/Maps/MH_VerticalSlice` manually. |
| Slice JSON not found | Keep repo layout intact; `MHGameInstance.SlicePath` is relative to project dir. |
| Vehicle does not move | Wheel setup incomplete; check Chaos debug overlay. |
| Mission trigger never fires | Ensure `MHGameModeBase` is active; check trigger radius vs. player capsule. |
| Player falls through world | Add collision floor; raise spawn Z. |

---

## Next

- **Phase 2:** OSM import — `Docs/OSM_TO_UNREAL.md`
- **Phase 3:** Enhanced Input — `Docs/IMPROVEMENT_PLAN.md`
- **Package:** `./Scripts/package.sh` after content is cook-ready
