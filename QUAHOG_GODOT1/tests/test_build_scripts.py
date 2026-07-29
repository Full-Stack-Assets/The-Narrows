#!/usr/bin/env python3
"""Regression checks for the strict, cross-platform Godot verification gate."""

from pathlib import Path
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

    def test_ci_runs_the_strict_gate(self) -> None:
        workflow = REPO_ROOT / ".github" / "workflows" / "godot-ci.yml"

        self.assertTrue(workflow.is_file())
        contents = workflow.read_text(encoding="utf-8")
        self.assertIn("bash build_web.sh", contents)
        self.assertIn("actions/upload-artifact", contents)


if __name__ == "__main__":
    unittest.main()
