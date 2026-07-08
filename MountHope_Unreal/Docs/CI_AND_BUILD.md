# CI, Build & Test Pipeline

Mount Hope validates in three tiers, from cheapest to most thorough. Tiers 1–2 run
on any machine (no engine needed); Tier 3 needs a real Unreal Engine 5.8 install.

| Tier | What it checks | Where it runs | Engine needed? |
|------|----------------|---------------|----------------|
| 1. Scaffold validation | File presence, JSON schemas, source-contract symbols, plugin/engine wiring | `unreal-ci.yml` on every push/PR; local | No |
| 2. C++ static gate | Delimiter balance, `generated.h` ordering, `GENERATED_BODY`, Build.cs deps, `AddDynamic`↔`UFUNCTION` | `unreal-ci.yml` on every push/PR; local | No |
| 3. Build + automation tests + package | Real UBT compile, headless `Automation RunTests`, optional cook/package | `unreal-build.yml` (self-hosted, manual); local | **Yes** |

Tiers 1–2 are the sandbox-safe gates that guard the repo continuously. They catch
structural regressions (a missing `UFUNCTION` on a delegate, an unbalanced brace, a
dropped file) but they are **not a compiler** — only Tier 3 proves the module builds.

## Tier 1–2: local run

```bash
python3 MountHope_Unreal/Scripts/validate_scaffold.py
python3 MountHope_Unreal/Scripts/check_cpp.py
```

These are exactly what the `unreal-ci` GitHub Actions workflow runs on every push
and pull request touching `MountHope_Unreal/**`.

## Tier 3: local build + test

Requires Unreal Engine 5.8. Point `UE_ROOT` at your install:

```bash
export UE_ROOT="/Users/Shared/Epic Games/UE_5.8"   # macOS example
cd MountHope_Unreal

bash Scripts/build.sh        # compile the MountHopeEditor target (UBT)
bash Scripts/run_tests.sh    # headless automation tests (Automation RunTests MountHope)
bash Scripts/package.sh      # optional: cook + stage + pak + archive a build
```

`build.sh` honours `PLATFORM` (default `Linux`), `CONFIGURATION` (default
`Development`), and `TARGET` (default `MountHopeEditor`).

`run_tests.sh` honours `TEST_FILTER` (default `MountHope`) and `REPORT_DIR`
(default `Saved/AutomationReport`). It runs `UnrealEditor-Cmd` with `-nullrhi`
so it works on a GPU-less machine, then parses the exported report (falling back
to a log scan) and exits non-zero if any test failed. The raw report is left in
`Saved/AutomationReport/` for inspection.

`package.sh` honours `PLATFORM` (default `Win64`) and archives to
`Packaged/<PLATFORM>/`.

The C++ automation tests live in `Source/MountHope/Tests/` and are guarded by
`WITH_DEV_AUTOMATION_TESTS`, so they compile only in Editor/Development builds and
add nothing to a shipping package.

## Tier 3: continuous (self-hosted runner)

`unreal-build.yml` runs the full compile → test → (optional) package pipeline on a
self-hosted runner. It is **dormant by default** — `workflow_dispatch` only, so it
never blocks PRs while no runner exists — and does nothing until you:

1. **Register a self-hosted runner** with the labels `self-hosted` and `unreal`
   (Settings → Actions → Runners → New self-hosted runner), on a machine with
   Unreal Engine 5.8 installed.
2. **Set the `UE_ROOT` repository variable** (Settings → Secrets and variables →
   Actions → Variables) to the engine install path on that runner.
3. **Trigger it** from the Actions tab → *unreal-build* → *Run workflow*. Toggle
   *package* to also cook a build; pick the *platform*.

The workflow re-runs the Tier 1–2 gates first (fast fail), then `build.sh`,
`run_tests.sh`, and optionally `package.sh`. The automation report and any packaged
build are uploaded as artifacts. If the runner is offline the run simply stays
queued — it never reports a false failure on the shared PR checks.

## Why two workflows?

`unreal-ci.yml` (GitHub-hosted, automatic) and `unreal-build.yml` (self-hosted,
manual) are deliberately separate: the engine cannot be installed on GitHub-hosted
runners, so bolting the compile onto the PR-gating workflow would leave every PR
with a permanently pending/failing check. Splitting them keeps the always-on gate
green and honest while giving the heavyweight build an explicit, opt-in trigger the
moment a runner is available.
