#!/usr/bin/env python3
"""Reject Web packs that omit runtime-only dependencies or ship retired canon art."""

from argparse import ArgumentParser
from pathlib import Path


REQUIRED_PATHS = (
    "scripts/autoloads/game_manager.gd",
    "scripts/save/save_schema.gd",
    "scripts/save/save_service.gd",
    "scripts/npc.gd",
    "scripts/mission_giver.gd",
    "scripts/ui/cheats_panel.gd",
    "scenes/boat.tscn",
    "assets/ui/btn_plain.tres",
    "assets/environment/new_bedford/granite.tres",
    "assets/props/containers/dumpster.glb",
    "assets/audio/ambient/ambient_coastal_city_coastal_city.mp3",
)
FORBIDDEN_PATHS = (
    "assets/ui/loading_screen.png",
    "assets/ui/wordmark_title.png",
)


def check_pack(pack_path: Path) -> list[str]:
    payload = pack_path.read_bytes()
    errors: list[str] = []
    for path in REQUIRED_PATHS:
        if path.encode() not in payload:
            errors.append(f"missing exported runtime dependency: {path}")
    for path in FORBIDDEN_PATHS:
        if path.encode() in payload:
            errors.append(f"retired canon asset shipped in Web pack: {path}")
    return errors


def main() -> int:
    parser = ArgumentParser()
    parser.add_argument("--pack", type=Path, default=Path("build/web/index.pck"))
    args = parser.parse_args()
    if not args.pack.is_file():
        print(f"Export manifest failed: pack not found: {args.pack}")
        return 1
    errors = check_pack(args.pack)
    if errors:
        print("Export manifest failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Export manifest passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
