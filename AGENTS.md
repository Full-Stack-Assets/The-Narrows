# The Narrows Repository Instructions

The product is **The Narrows — South Coast · Now**, set in the present day
(2026). Read `docs/product/source-of-truth.md` and `plans/the-narrows.md` before
changing player-facing content.

## Track hierarchy

- `QUAHOG_GODOT1/` is the ship target for the Web/mobile product.
- `QUAHOG_Web/` is a behavior/content reference and deployed comparison build.
- `MountHope_Unreal/` is a separate premium PC/console research track.
- `QUAHOG_Unity/`, `QUAHOG_Godot/`, and `QUAHOG_Unreal/` are legacy/reference.

Do not describe Web, Unreal, or a legacy directory as the canonical main
product. Do not claim a Godot feature complete because a reference
implementation exists elsewhere.

## Godot workflow

Use Godot 4.6 stable with GL Compatibility.

```bash
cd QUAHOG_GODOT1
GODOT_BIN=godot bash scripts/verify.sh
```

Until `scripts/verify.sh` lands, `bash build_web.sh` is the historical exporter;
it is Linux-oriented and not a sufficient local verification gate.

Requirements:

- import, tests, and Web export must all pass;
- never ignore import errors;
- preserve current saves through explicit migrations;
- use testable mission/activity state transitions rather than frame-polled
  coordinate-only completion;
- keep keyboard, standard gamepad, and touch paths functional;
- record the exact deployed commit SHA.

## Reference web workflow

Run from `QUAHOG_Web/`:

```bash
npm install
npm test
npm run build
```

The web build may require Vercel functions for optional satellite, TTS, and
music features. Those services must degrade gracefully and are not required by
the Godot ship target.

## Unreal workflow

Run the repo-local structural gates:

```bash
python3 MountHope_Unreal/Scripts/validate_scaffold.py
python3 MountHope_Unreal/Scripts/check_cpp.py
```

These are not substitutes for a real Unreal Engine 5.8 compile.

## Product constraints

- Player-facing title: The Narrows.
- Player-facing era: South Coast · Now / 2026.
- “Mount Hope” is a retired title or an in-world geographic reference only.
- Ship original fictional brands; real games, vehicles, and weapons are
  references, not licensed content.
- Do not expand to new regions before the opening New Bedford vertical-slice
  gate passes.
