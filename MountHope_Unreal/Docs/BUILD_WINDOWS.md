# Build on Windows

## Prerequisites

1. **Epic Games Launcher** with **Unreal Engine 5.8** installed  
   Typical path: `C:\Program Files\Epic Games\UE_5.8`
2. **Visual Studio 2022** with the **Game development with C++** workload  
   (Desktop development with C++ is the minimum; include Windows 10/11 SDK.)
3. This repo cloned with the full folder layout (`QUAHOG_Web/`, `quahog-project-files/`, etc.)

## Fastest path (recommended)

1. Open **Epic Games Launcher → Library → Mount Hope** (or **Add** → browse to `MountHope_Unreal\MountHope.uproject`).
2. Double-click `MountHope.uproject` (or right-click → **Generate Visual Studio project files** first if prompted).
3. When the editor opens, click **Yes** to rebuild missing modules.  
   First compile can take 10–20 minutes.

That is enough to start the editor and run the Python bootstrap scripts.

## Command-line compile (PowerShell)

From the repo root or `MountHope_Unreal/`:

```powershell
cd MountHope_Unreal
.\Scripts\build.ps1
```

The script auto-detects `C:\Program Files\Epic Games\UE_5.x`. To pin a specific version:

```powershell
$env:UE_ROOT = "C:\Program Files\Epic Games\UE_5.8"
.\Scripts\build.ps1
```

Or double-click / run from cmd:

```cmd
cd MountHope_Unreal
Scripts\build.bat
```

### Build options

```powershell
$env:CONFIGURATION = "Development"   # or DebugGame, Shipping
$env:TARGET = "MountHopeEditor"      # editor target
.\Scripts\build.ps1
```

## After compile — editor setup

1. Open `MountHope.uproject` in the editor.
2. Enable **Edit → Plugins → Python Editor Script Plugin** (restart if asked).
3. Run **Tools → Execute Python Script** for each file, in order:
   - `Scripts/editor_bootstrap_vertical_slice.py`
   - `Scripts/editor_create_enhanced_input.py`
   - `Scripts/editor_import_osm.py`
   - `Scripts/editor_setup_navmesh.py`
4. Create **BP_MHVehicle** (parent `MHVehiclePawn`) with a mesh + Chaos wheels.
5. Press **Play**.

See `Docs/EDITOR_SETUP.md` for the full checklist.

## Package a Windows build

After `/Game/Maps/MH_VerticalSlice` and vehicle Blueprints exist:

```powershell
$env:UE_ROOT = "C:\Program Files\Epic Games\UE_5.8"
.\Scripts\package.ps1
```

Output: `MountHope_Unreal\Packaged\Win64\`

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `MountHope could not be compiled` | Install VS 2022 C++ workload; right-click `.uproject` → **Generate Visual Studio project files**; open `MountHope.sln` and build **Development Editor**. |
| `UE_5.8 not found` | Set `$env:UE_ROOT` to your actual engine folder from Epic Launcher → Library → **Engine version** → **Browse**. |
| Live Coding blocks build | Close the editor, or disable Live Coding under **Editor Preferences → Live Coding**. |
| Slice JSON missing at runtime | Keep repo layout intact; `MHGameInstance` loads `../QUAHOG_Web/public/slice-newbedford.json` relative to the project. |
| Python scripts fail | Enable Python Editor Script Plugin; compile C++ first so `MHPlayerCharacter` etc. exist. |

## Validate without Unreal (optional)

From Git Bash or WSL:

```bash
python MountHope_Unreal/Scripts/validate_scaffold.py
```

This does **not** replace a real compile — it only checks project structure.
