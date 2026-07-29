#!/usr/bin/env python3
"""Regression checks for the strict, cross-platform Godot verification gate."""

from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = PROJECT_ROOT.parent


class BuildScriptTests(unittest.TestCase):
    def test_build_script_is_cross_platform_and_strict(self) -> None:
        script = (PROJECT_ROOT / "build_web.sh").read_text(encoding="utf-8")

        self.assertIn("uname -s", script)
        self.assertIn("macos.universal.zip", script)
        self.assertNotIn("--import || true", script)
        self.assertIn('GODOT_BIN="${GODOT_BIN:-', script)
        self.assertIn('touch "$WORK/._sc_"', script)
        self.assertIn('editor_data/export_templates/${TPL_VERSION}', script)

    def test_single_verification_entry_point_exists(self) -> None:
        verify_script = PROJECT_ROOT / "scripts" / "verify.sh"

        self.assertTrue(verify_script.is_file())
        self.assertTrue(verify_script.stat().st_mode & 0o111)
        contents = verify_script.read_text(encoding="utf-8")
        self.assertIn('rm -r -- "$PROJECT_ROOT/build/web"', contents)

    def test_ci_runs_the_strict_gate(self) -> None:
        workflow = REPO_ROOT / ".github" / "workflows" / "godot-ci.yml"

        self.assertTrue(workflow.is_file())
        contents = workflow.read_text(encoding="utf-8")
        self.assertIn("bash build_web.sh", contents)
        self.assertIn("actions/upload-artifact", contents)

    def test_provenance_is_rendered_in_menu_pause_and_debug_ui(self) -> None:
        menu = (PROJECT_ROOT / "scripts" / "main_menu.gd").read_text(encoding="utf-8")
        hud = (PROJECT_ROOT / "scripts" / "ui" / "hud.gd").read_text(encoding="utf-8")

        self.assertIn("BuildInfo.display_string()", menu)
        self.assertGreaterEqual(hud.count("BuildInfo.display_string()"), 2)

    def test_startup_uses_a_bounded_core_manifest(self) -> None:
        loading = (PROJECT_ROOT / "scripts" / "autoloads" / "loading_screen.gd").read_text(
            encoding="utf-8"
        )
        world = (PROJECT_ROOT / "scripts" / "game_world.gd").read_text(encoding="utf-8")

        self.assertIn("CORE_PRELOAD_PATHS", loading)
        self.assertIn('set_phase("LOADING CORE MAP")', loading)
        self.assertNotIn('await _vfx_warmup()', loading)
        self.assertIn('StartupMetrics.mark("world_interactive")', world)
        self.assertIn('call_deferred("_start_deferred_city")', world)


class AssetBudgetTests(unittest.TestCase):
    def test_budget_checker_reports_every_budget_class(self) -> None:
        checker = PROJECT_ROOT / "scripts" / "check_asset_budget.py"
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "assets/audio").mkdir(parents=True)
            (root / "assets/ui").mkdir(parents=True)
            (root / "assets/models").mkdir(parents=True)
            (root / "build/web").mkdir(parents=True)
            (root / "assets/audio/large.mp3").write_bytes(b"a" * 33)
            (root / "assets/ui/large.png").write_bytes(b"b" * 33)
            (root / "assets/models/large.glb").write_bytes(b"c" * 33)
            (root / "assets/ui/menu.webp").write_bytes(b"d" * 33)
            (root / "build/web/index.pck").write_bytes(os.urandom(64))

            result = subprocess.run(
                [
                    sys.executable,
                    str(checker),
                    "--project-root",
                    str(root),
                    "--export-dir",
                    str(root / "build/web"),
                    "--menu-asset",
                    "assets/ui/menu.webp",
                    "--max-audio-bytes",
                    "32",
                    "--max-texture-bytes",
                    "32",
                    "--max-glb-bytes",
                    "32",
                    "--max-menu-bytes",
                    "32",
                    "--max-payload-bytes",
                    "32",
                ],
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        for budget_class in ["audio", "texture", "GLB", "menu", "payload"]:
            self.assertIn(budget_class, result.stdout)


class BuildInfoGeneratorTests(unittest.TestCase):
    def _generate(self, commit_sha: str, build_date: str) -> str:
        generator = PROJECT_ROOT / "scripts" / "generate_build_info.py"
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "build_info.gd"
            environment = os.environ.copy()
            environment["VERCEL_GIT_COMMIT_SHA"] = commit_sha
            environment["BUILD_DATE"] = build_date
            subprocess.run(
                [sys.executable, str(generator), "--output", str(output)],
                check=True,
                cwd=PROJECT_ROOT,
                env=environment,
            )
            return output.read_text(encoding="utf-8")

    def test_empty_values_generate_local_fallbacks(self) -> None:
        contents = self._generate("", "")

        self.assertIn('const COMMIT_SHA := "local"', contents)
        self.assertIn('const BUILD_DATE := "unknown-date"', contents)

    def test_full_sha_and_build_date_are_embedded(self) -> None:
        sha = "0123456789abcdef0123456789abcdef01234567"
        contents = self._generate(sha, "2026-07-29T15:00:00Z")

        self.assertIn(f'const COMMIT_SHA := "{sha}"', contents)
        self.assertIn('const BUILD_DATE := "2026-07-29T15:00:00Z"', contents)

    def test_invalid_sha_is_rejected(self) -> None:
        generator = PROJECT_ROOT / "scripts" / "generate_build_info.py"
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "build_info.gd"
            environment = os.environ.copy()
            environment["VERCEL_GIT_COMMIT_SHA"] = "not-a-commit"
            result = subprocess.run(
                [sys.executable, str(generator), "--output", str(output)],
                cwd=PROJECT_ROOT,
                env=environment,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("40 lowercase hexadecimal", result.stderr)


if __name__ == "__main__":
    unittest.main()
