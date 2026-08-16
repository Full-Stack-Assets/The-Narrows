#!/usr/bin/env python3
"""Fail a build when The Narrows' startup assets exceed explicit byte budgets."""

from __future__ import annotations

import argparse
from pathlib import Path
import zlib


MIB = 1024 * 1024
DEFAULT_MENU_ASSETS = (
    "assets/ui/title_poster.webp",
    "assets/ui/theme.tres",
    "assets/fonts/noto_serif.ttf",
    "assets/audio/sfx/ui/ui_menu_click.mp3",
)


def compressed_size(path: Path) -> int:
    compressor = zlib.compressobj(level=6, wbits=31)
    total = 0
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            total += len(compressor.compress(chunk))
    return total + len(compressor.flush())


def oversized_files(root: Path, extensions: set[str], limit: int) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*")
        if path.is_file()
        and path.suffix.lower() in extensions
        and path.stat().st_size > limit
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--export-dir", type=Path)
    parser.add_argument("--menu-asset", action="append", default=[])
    parser.add_argument("--max-audio-bytes", type=int, default=3 * MIB)
    parser.add_argument("--max-texture-bytes", type=int, default=4 * MIB)
    parser.add_argument("--max-glb-bytes", type=int, default=8 * MIB)
    parser.add_argument("--max-menu-bytes", type=int, default=8 * MIB)
    parser.add_argument("--max-payload-bytes", type=int, default=35 * MIB)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.project_root.resolve()
    failures: list[str] = []
    categories = (
        ("audio", {".mp3", ".ogg", ".wav", ".flac"}, args.max_audio_bytes),
        ("texture", {".png", ".webp", ".jpg", ".jpeg", ".ktx"}, args.max_texture_bytes),
        ("GLB", {".glb"}, args.max_glb_bytes),
    )
    for label, extensions, limit in categories:
        for path in oversized_files(root / "assets", extensions, limit):
            failures.append(
                "%s: %s is %.2f MiB (limit %.2f MiB)"
                % (label, path.relative_to(root), path.stat().st_size / MIB, limit / MIB)
            )

    menu_assets = tuple(args.menu_asset) if args.menu_asset else DEFAULT_MENU_ASSETS
    menu_paths = [root / relative for relative in menu_assets if (root / relative).is_file()]
    menu_total = sum(path.stat().st_size for path in menu_paths)
    if menu_total > args.max_menu_bytes:
        failures.append(
            "menu: eager assets total %.2f MiB (limit %.2f MiB)"
            % (menu_total / MIB, args.max_menu_bytes / MIB)
        )

    if args.export_dir:
        export_dir = args.export_dir.resolve()
        payload_files = sorted(
            path
            for path in export_dir.rglob("*")
            if path.is_file()
            and path.name.startswith("index.")
            and path.suffix.lower() not in {".map", ".import"}
        )
        payload_total = sum(compressed_size(path) for path in payload_files)
        if payload_total > args.max_payload_bytes:
            failures.append(
                "payload: compressed export totals %.2f MiB (limit %.2f MiB)"
                % (payload_total / MIB, args.max_payload_bytes / MIB)
            )

    if failures:
        print("Asset budget failed:")
        for failure in failures:
            print("- " + failure)
        return 1

    print("Asset budget passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
