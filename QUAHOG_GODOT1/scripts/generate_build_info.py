#!/usr/bin/env python3
"""Generate compile-time Godot provenance from the deployment environment."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def normalized_sha(raw_sha: str) -> str:
    sha = raw_sha.strip() or "local"
    if sha != "local" and not SHA_PATTERN.fullmatch(sha):
        raise ValueError(
            "VERCEL_GIT_COMMIT_SHA must be 'local' or 40 lowercase hexadecimal characters"
        )
    return sha


def render_script(commit_sha: str, build_date: str) -> str:
    return f"""extends Node

const COMMIT_SHA := {json.dumps(commit_sha)}
const BUILD_DATE := {json.dumps(build_date)}


func display_string() -> String:
\treturn format_display(COMMIT_SHA, BUILD_DATE)


static func format_display(commit_sha: String, build_date: String) -> String:
\tvar short_sha := commit_sha if commit_sha == "local" else commit_sha.left(7)
\treturn "%s · %s" % [short_sha, build_date]
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).with_name("autoloads") / "build_info.gd",
    )
    args = parser.parse_args()

    try:
        commit_sha = normalized_sha(os.environ.get("VERCEL_GIT_COMMIT_SHA", ""))
    except ValueError as error:
        parser.error(str(error))

    build_date = os.environ.get("BUILD_DATE", "").strip() or "unknown-date"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render_script(commit_sha, build_date), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
