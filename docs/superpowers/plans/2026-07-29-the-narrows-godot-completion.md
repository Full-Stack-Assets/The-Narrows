# The Narrows Godot Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a verifiable, responsive Godot Web build of *The Narrows* with a polished 10–15 minute “Off the Boat” opening, durable progression, and one authored New Bedford content pack.

**Architecture:** `QUAHOG_GODOT1/` is the provisional ship target established by the later engine pivot in `plans/mount-hope.md`; `QUAHOG_Web/` is the behavior/content reference, and `MountHope_Unreal/` is a separate premium-platform track. Replace the monolithic proximity-driven campaign with typed mission resources and a pure transition runtime, put saves behind a versioned service, and gate releases through headless import/tests/export plus browser smoke evidence tied to a commit SHA.

**Tech Stack:** Godot 4.6 stable, GDScript, GL Compatibility renderer, Godot Web export, JSON/Resource data, GitHub Actions, Vercel, browser smoke automation.

**Execution branch:** `codex/godot-completion`.

## Global Constraints

- Product name: **The Narrows**.
- Subtitle/era: **South Coast · Now**, present day 2026.
- “Mount Hope” may describe Mount Hope Bay but must not be a player-facing product title.
- The supplied 1986 `mount-hope.md` is historical reference; the current `plans/the-narrows.md` brand decision wins.
- Execute implementation in a full checkout of `Full-Stack-Assets/The-Narrows`.
- All game changes target `QUAHOG_GODOT1/` unless a task explicitly names a reference-only file.
- Keep `QUAHOG_Web/` deployable, but do not duplicate new feature work into it during this plan.
- Do not add South Coast regions, a new engine, multiplayer, or a desktop wrapper before the Milestone 0.6 release gate in Task 8 passes.
- A mission title, marker, or coordinate sequence is not completion evidence; required encounters and state transitions must exist and be tested.
- ElevenLabs and other hosted services are optional enhancements. Gameplay and subtitles must work with no API keys.
- No task may check off “shipped” without the exact deployed commit SHA and a completed release record.
- Every behavior change begins with a failing automated test or a reproducible browser assertion.
- Use small commits; each task below is an independent review gate.

## Program Milestones

| Milestone | Tasks | Exit condition |
|---|---:|---|
| 0.4 — One product | 1 | Repository declarations agree on title, era, and ship target |
| 0.5 — Trustworthy build | 2–4 | Import, tests, export, deploy provenance, and startup budgets pass |
| 0.6 — Playable introduction | 5–8 | “Off the Boat” is authored, checkpointed, save-safe, responsive, and accessible by keyboard/touch |
| 0.7 — Sandbox depth | 9–10 | Boat/race parity and readable police/civic AI |
| 0.8 — Authored New Bedford | 11–13 | One detailed district and three mission-quality Act I chapters |
| 1.0 — Release | 14 | Cross-browser/device matrix and production soak pass |

## Authoritative File Map

| Responsibility | Existing file(s) | Planned boundary |
|---|---|---|
| App/menu/session | `scripts/main_menu.gd`, `scenes/main.tscn` | Keep menu composition; remove embedded legacy asset dependence |
| Global state/save | `scripts/autoloads/game_manager.gd` | Split persistence into `scripts/save/` |
| Campaign | `scripts/systems/story_mission.gd` | Split definitions, runtime, encounter integration |
| World assembly | `scripts/game_world.gd` | Keep composition; move feature logic into focused systems |
| Map/streaming | `scripts/world/map_loader.gd` | Keep loader; add metrics/budgets |
| Player | `scripts/player.gd` | Keep controller; consume normalized input actions |
| Vehicles | `scripts/vehicles/car.gd`, `traffic_car.gd` | Add boat and activity interfaces without rewriting car physics |
| Police/heat | `scripts/police.gd`, `scripts/systems/wanted_system.gd` | Extract deterministic pursuit transitions |
| HUD/maps/touch | `scripts/ui/*.gd` | Add responsive layout profile and settings surfaces |
| Audio/radio | `scripts/autoloads/audio_manager.gd`, `radio.gd` | Add subtitle-safe dialogue bus and measured loading |
| Verification | `build_web.sh`, `plans/smoke-test-checklist.md` | Add test runner, strict verify script, CI, release records |

---

## Task 1: Reconcile the Product and Engine Source of Truth

**Priority:** P0

**Files:**

- Create: `docs/product/source-of-truth.md`
- Modify: `README.md`
- Modify: `ENGINES.md`
- Modify: `AGENTS.md`
- Modify: `plans/mount-hope.md`
- Modify: `plans/elevation-plan.md`
- Modify: `plans/web-godot-parity-checklist.md`
- Replace content: `plans/roadmap-50.md`

**Interfaces:**

- Consumes: the decision recorded in the review document.
- Produces: one product/engine hierarchy used by every later task.

- [x] **Step 1: Write the authoritative declaration**

  `docs/product/source-of-truth.md` must state:

  ```text
  Product: The Narrows
  Setting: Massachusetts South Coast, present day (2026)
  Ship target: QUAHOG_GODOT1 (Godot 4.6 Web/mobile)
  Behavior/content reference: QUAHOG_Web
  Separate premium track: MountHope_Unreal
  Legacy/reference: QUAHOG_Unity, QUAHOG_Godot, QUAHOG_Unreal
  ```

  Include the two deploy URLs and require build-SHA display on each.

- [x] **Step 2: Make root guidance identical**

  Replace the contradictory canonical-engine paragraphs in `README.md`, `ENGINES.md`, and `AGENTS.md` with the declaration above. Retain engine-specific run commands under separate headings.

- [x] **Step 3: Repair the master plan’s working loop**

  In `plans/mount-hope.md`:

  - rename the document heading to The Narrows;
  - make Godot build/test/export the BUILD and VERIFY steps;
  - make web inspection a reference-comparison step;
  - remove instructions to fast-forward and push directly to `main`;
  - require pull-request review and exact deployment SHA;
  - replace the single overloaded checkbox legend with separate `Godot status` and `Web reference status` fields.

- [x] **Step 4: Replace the stale roadmap**

  `plans/roadmap-50.md` must become a short index linking to this plan, the source-of-truth review, the parity checklist, and the release matrix. Do not preserve “done” claims that are contradicted by the current code/runtime audit.

- [x] **Step 5: Verify declarations**

  Run:

  ```bash
  rg -n "canonical|ship target|legacy|1986|Mount Hope" \
    README.md ENGINES.md AGENTS.md plans docs/product
  ```

  Expected:

  - every canonical/ship-target statement follows the same hierarchy;
  - 1986 appears only in historical notes;
  - Mount Hope appears as a legacy title or geographic name.

- [x] **Step 6: Commit**

  ```bash
  git add README.md ENGINES.md AGENTS.md plans docs/product/source-of-truth.md
  git commit -m "docs: establish one The Narrows ship target"
  ```

---

## Task 2: Add Strict Godot Verification and CI

**Priority:** P0

**Files:**

- Create: `QUAHOG_GODOT1/scripts/verify.sh`
- Create: `QUAHOG_GODOT1/tests/test_runner.gd`
- Create: `QUAHOG_GODOT1/tests/test_smoke.gd`
- Modify: `QUAHOG_GODOT1/build_web.sh`
- Create: `.github/workflows/godot-ci.yml`

**Interfaces:**

- Produces: `tests/test_runner.gd::assert_true`, `assert_eq`, and exit code `0/1`; `scripts/verify.sh` becomes the single local/CI verification entry point.

- [x] **Step 1: Write a failing smoke suite**

  `tests/test_smoke.gd`:

  ```gdscript
  extends RefCounted

  static func run(t) -> void:
      t.assert_true(ResourceLoader.exists("res://scenes/main.tscn"), "main scene exists")
      t.assert_true(ResourceLoader.exists("res://scenes/game_world.tscn"), "world scene exists")
      t.assert_eq(ProjectSettings.get_setting("application/config/name"), "The Narrows", "product name")
      t.assert_eq(
          ProjectSettings.get_setting("rendering/renderer/rendering_method"),
          "gl_compatibility",
          "web renderer",
      )
  ```

- [x] **Step 2: Implement the test runner**

  `tests/test_runner.gd` extends `SceneTree`, loads a fixed suite list, records assertion failures, prints a summary, and calls `quit(1)` when any assertion fails.

  Initial suite list:

  ```gdscript
  const SUITES := [
      preload("res://tests/test_smoke.gd"),
  ]
  ```

- [x] **Step 3: Run the test and record the current result**

  ```bash
  godot --headless --path QUAHOG_GODOT1 \
    --script res://tests/test_runner.gd
  ```

  Expected: the runner executes four named assertions and exits `0`.

- [x] **Step 4: Stop ignoring import failures**

  Remove `|| true` from the import command in `build_web.sh`. Make the script accept:

  ```bash
  GODOT_BIN="${GODOT_BIN:-$WORK/godot}"
  ```

  After download, require:

  ```bash
  "$GODOT_BIN" --version | grep -F "4.6"
  ```

  The build must stop on download, import, version, template, or export failure.

- [x] **Step 5: Create the verification entry point**

  `scripts/verify.sh` must run, in order:

  ```bash
  "$GODOT_BIN" --headless --path "$PROJECT" --import
  "$GODOT_BIN" --headless --path "$PROJECT" --script res://tests/test_runner.gd
  "$GODOT_BIN" --headless --path "$PROJECT" --export-release Web build/web/index.html
  ```

  It must also fail when stderr contains `SCRIPT ERROR`, `Parse Error`, or `Failed to load`.

- [x] **Step 6: Add Godot CI**

  `.github/workflows/godot-ci.yml` must:

  - run on `QUAHOG_GODOT1/**`, the workflow, and shared map-data changes;
  - cache the Godot binary/templates by exact `4.6-stable` version;
  - run `bash QUAHOG_GODOT1/scripts/verify.sh`;
  - upload `QUAHOG_GODOT1/build/web/` only after success;
  - never publish from pull requests.

- [x] **Step 7: Verify and commit**

  ```bash
  cd QUAHOG_GODOT1
  GODOT_BIN=godot bash scripts/verify.sh
  cd ..
  git add QUAHOG_GODOT1/build_web.sh QUAHOG_GODOT1/scripts/verify.sh QUAHOG_GODOT1/tests .github/workflows/godot-ci.yml
  git commit -m "test(godot): add strict import test and export gate"
  ```

---

## Task 3: Ship Current Branding with Build Provenance

**Priority:** P0

**Files:**

- Modify: `QUAHOG_GODOT1/project.godot`
- Modify: `QUAHOG_GODOT1/scripts/main_menu.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Replace: `QUAHOG_GODOT1/assets/ui/title_poster.webp`
- Replace: `QUAHOG_GODOT1/assets/ui/title_poster_sm.webp`
- Replace: `QUAHOG_GODOT1/assets/ui/cover.webp`
- Replace: `QUAHOG_GODOT1/assets/ui/cover_sm.webp`
- Create: `QUAHOG_GODOT1/scripts/autoloads/build_info.gd`
- Create: `QUAHOG_GODOT1/scripts/generate_build_info.py`
- Modify: `QUAHOG_GODOT1/build_web.sh`
- Modify: `QUAHOG_GODOT1/project.godot`
- Modify: `QUAHOG_GODOT1/vercel.json`
- Create: `docs/releases/deployment-record.md`

**Interfaces:**

- Produces: `BuildInfo.commit_sha`, `BuildInfo.build_date`, `BuildInfo.display_string()`.

- [x] **Step 1: Add a failing build-info test**

  Create `tests/test_build_info.gd` and add it to the runner. Assert:

  - `display_string()` contains a non-empty SHA;
  - fallback SHA is `"local"`;
  - a supplied 40-character SHA renders its first seven characters.

- [x] **Step 2: Generate build metadata before export**

  `generate_build_info.py` reads `VERCEL_GIT_COMMIT_SHA` and `BUILD_DATE` from the build environment, validates the SHA as either `local` or 40 lowercase hexadecimal characters, and writes:

  ```gdscript
  extends Node

  const COMMIT_SHA := "local"
  const BUILD_DATE := "unknown-date"

  func display_string() -> String:
      var short_sha := COMMIT_SHA if COMMIT_SHA == "local" else COMMIT_SHA.left(7)
      return "%s · %s" % [short_sha, BUILD_DATE]
  ```

  Empty environment values become `local` and `unknown-date`. Invoke the generator from `build_web.sh` immediately before import/export and register `BuildInfo` as an autoload. The exported game must not depend on runtime access to Vercel environment variables.

- [x] **Step 3: Remove embedded legacy title art**

  Replace the four title/cover assets with current The Narrows art. The image pixels must not contain:

  - `MOUNT HOPE`;
  - `1986`;
  - third-party game or vehicle logos.

  Keep the menu’s text wordmark as the accessible/fallback title.

- [x] **Step 4: Display provenance**

  Show `BuildInfo.display_string()`:

  - in the menu footer;
  - in the pause/legal panel;
  - in a small HUD debug line when debug display is enabled.

- [x] **Step 5: Record deployment identity**

  `docs/releases/deployment-record.md` must contain a table with:

  ```text
  Environment | URL | Commit SHA | Built at | Verified at | Verifier
  ```

  A production row is valid only when the UI SHA matches the merged SHA.

- [ ] **Step 6: Verify production**

  Export and deploy a preview, then assert:

  - browser title is `The Narrows`;
  - menu says `THE NARROWS` and `SOUTH COAST · NOW`;
  - `MOUNT HOPE` and `1986` are absent;
  - displayed SHA matches the preview source.

- [x] **Step 7: Commit**

  ```bash
  git add QUAHOG_GODOT1/project.godot QUAHOG_GODOT1/build_web.sh QUAHOG_GODOT1/scripts/main_menu.gd QUAHOG_GODOT1/scripts/ui/hud.gd QUAHOG_GODOT1/scripts/autoloads/build_info.gd QUAHOG_GODOT1/scripts/generate_build_info.py QUAHOG_GODOT1/assets/ui QUAHOG_GODOT1/vercel.json QUAHOG_GODOT1/tests/test_build_info.gd docs/releases/deployment-record.md
  git commit -m "fix(godot): ship current branding and build provenance"
  ```

---

## Task 4: Cut First Load and Instrument Startup

**Priority:** P0

**Files:**

- Create: `QUAHOG_GODOT1/scripts/autoloads/startup_metrics.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/loading_screen.gd`
- Modify: `QUAHOG_GODOT1/scripts/main_menu.gd`
- Modify: `QUAHOG_GODOT1/scripts/game_world.gd`
- Modify: `QUAHOG_GODOT1/scripts/world/map_loader.gd`
- Modify: `QUAHOG_GODOT1/export_presets.cfg`
- Create: `QUAHOG_GODOT1/scripts/check_asset_budget.py`
- Create: `QUAHOG_GODOT1/tests/test_startup_manifest.gd`

**Interfaces:**

- Produces: `StartupMetrics.mark(name)`, `StartupMetrics.elapsed_ms(from, to)`, and JSON-safe `StartupMetrics.snapshot()`.

- [x] **Step 1: Define startup budgets**

  Enforce:

  - menu interactive within `12 s` on broadband desktop after a cold cache;
  - Play-to-world-control within `12 s`;
  - initial Web payload at or below `35 MB` compressed;
  - radio/music not required before the menu becomes interactive;
  - first map tile and player load before nonessential districts/assets.

- [x] **Step 2: Test metric transitions**

  Add a suite asserting ordered marks for:

  ```text
  boot → menu_visible → play_pressed → core_map_ready → player_ready → world_interactive
  ```

  Reject duplicate terminal marks and negative durations.

- [x] **Step 3: Add real progress phases**

  `loading_screen.gd` must render the active phase and bounded progress:

  - `STARTING`;
  - `LOADING CORE MAP`;
  - `SPAWNING PLAYER`;
  - `STARTING CITY`;
  - `READY`.

  Do not show synthetic percentages disconnected from completed work.

- [x] **Step 4: Move nonessential work behind world interaction**

  In `game_world.gd` and `map_loader.gd`:

  - load only the New Bedford core around the player before control;
  - start distant tile streaming after `world_interactive`;
  - defer radio tracks, distant hero assets, Fall River/Brockton/Cape tiles, and large ambient pools;
  - cap work per frame through the existing `stream_tile_budget()`.

- [x] **Step 5: Enforce asset budgets**

  `check_asset_budget.py` must report and fail on:

  - any audio file above `3 MB`;
  - any texture above `4 MB`;
  - any GLB above `8 MB`;
  - total eagerly loaded menu assets above `8 MB`;
  - exported compressed payload above `35 MB`.

- [ ] **Step 6: Verify cold and warm startup**

  Run a browser trace twice: once after clearing only this site’s cache in an isolated test profile and once warm. Record menu-interactive and world-interactive timings in the release record.

- [x] **Step 7: Commit**

  ```bash
  git add QUAHOG_GODOT1/scripts/autoloads/startup_metrics.gd QUAHOG_GODOT1/scripts/autoloads/loading_screen.gd QUAHOG_GODOT1/scripts/main_menu.gd QUAHOG_GODOT1/scripts/game_world.gd QUAHOG_GODOT1/scripts/world/map_loader.gd QUAHOG_GODOT1/scripts/check_asset_budget.py QUAHOG_GODOT1/tests/test_startup_manifest.gd QUAHOG_GODOT1/export_presets.cfg
  git commit -m "perf(godot): make startup measurable and progressive"
  ```

---

## Task 5: Replace the Positional Campaign with a Typed Mission Runtime

**Priority:** P0

**Files:**

- Create: `QUAHOG_GODOT1/scripts/missions/mission_definition.gd`
- Create: `QUAHOG_GODOT1/scripts/missions/mission_progress.gd`
- Create: `QUAHOG_GODOT1/scripts/missions/mission_runtime.gd`
- Create: `QUAHOG_GODOT1/scripts/missions/mission_event.gd`
- Create: `QUAHOG_GODOT1/data/missions/off_the_boat.json`
- Modify: `QUAHOG_GODOT1/scripts/systems/story_mission.gd`
- Create: `QUAHOG_GODOT1/tests/test_mission_runtime.gd`

**Interfaces:**

- Consumes: world events from player, vehicles, wanted, encounter, and dialogue systems.
- Produces:

  ```gdscript
  MissionRuntime.start(definition: MissionDefinition) -> void
  MissionRuntime.dispatch(event: MissionEvent) -> void
  MissionRuntime.snapshot() -> Dictionary
  MissionRuntime.restore(snapshot: Dictionary) -> Error
  MissionRuntime.restart_checkpoint() -> void
  ```

- [x] **Step 1: Define supported objective types**

  Use:

  ```gdscript
  enum ObjectiveType {
      REACH,
      INTERACT,
      ENTER_VEHICLE,
      DEFEAT_ENCOUNTER,
      LOSE_HEAT,
      SURVIVE,
      DIALOGUE,
  }
  ```

  Every objective has a unique `id`, visible text, completion predicate data, and optional checkpoint flag.

- [x] **Step 2: Write failing transition tests**

  Cover:

  - unrelated events do not advance;
  - matching reach/interact/vehicle/encounter/heat/dialogue events advance;
  - rewards emit once;
  - failure retains the last checkpoint;
  - restart restores the checkpoint objective;
  - a completed mission ignores later events;
  - malformed definitions are rejected with a named error.

- [x] **Step 3: Implement data parsing and validation**

  Reject definitions with:

  - duplicate mission or objective IDs;
  - no objectives;
  - unsupported objective type;
  - missing target/entity/encounter fields required by a type;
  - non-positive reach radius or survive duration;
  - negative rewards.

- [x] **Step 4: Implement the pure runtime**

  The runtime updates progress only from `MissionEvent`. It must not read player position every frame or directly write saves/cash.

- [x] **Step 5: Adapt `story_mission.gd`**

  Reduce `story_mission.gd` to:

  - load/validate definitions;
  - translate existing world signals into events during migration;
  - apply emitted reward/save/weather effects;
  - expose current title/objective/marker to the HUD.

- [x] **Step 6: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/missions QUAHOG_GODOT1/data/missions QUAHOG_GODOT1/scripts/systems/story_mission.gd QUAHOG_GODOT1/tests/test_mission_runtime.gd
  git commit -m "feat(godot): add a typed checkpointed mission runtime"
  ```

---

## Task 6: Author “Off the Boat” as the Tutorial Vertical Slice

**Priority:** P0

**Files:**

- Modify: `QUAHOG_GODOT1/data/missions/off_the_boat.json`
- Create: `QUAHOG_GODOT1/scripts/missions/encounter_director.gd`
- Create: `QUAHOG_GODOT1/scripts/dialogue/dialogue_definition.gd`
- Create: `QUAHOG_GODOT1/scripts/dialogue/dialogue_runner.gd`
- Create: `QUAHOG_GODOT1/data/dialogue/off_the_boat.json`
- Modify: `QUAHOG_GODOT1/scripts/game_world.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Modify: `QUAHOG_GODOT1/scripts/player.gd`
- Create: `QUAHOG_GODOT1/tests/test_off_the_boat.gd`

**Interfaces:**

- Produces: `EncounterDirector.start(encounter_id)`, `reset(encounter_id)`, `encounter_completed`; `DialogueRunner.start(conversation_id)`, `advance()`, `skip()`, `line_changed`, `conversation_completed`.

- [x] **Step 1: Encode the actual sequence**

  Required objectives:

  1. reach Seamen’s Bethel;
  2. interact with Deacon;
  3. reach the fish pier;
  4. survive and defeat the pier ambush;
  5. enter the assigned getaway car;
  6. lose police heat;
  7. reach the safehouse;
  8. complete the safehouse dialogue and receive the reward.

- [x] **Step 2: Test the golden event path**

  The test must dispatch all eight beats, assert exact objective order, and confirm the reward is emitted once.

- [x] **Step 3: Test three failure paths**

  Cover:

  - player wasted during the ambush;
  - assigned car destroyed before escape;
  - player remains outside the ambush boundary for 15 seconds.

  All restart at the checkpoint before the pier encounter with enemies, player health, assigned car, heat, and reward state reset.

- [x] **Step 4: Implement the encounter**

  Spawn a bounded, deterministic encounter:

  - two melee enemies and one ranged enemy;
  - encounter actors carry the encounter ID;
  - no respawn after completion;
  - reset removes surviving actors before spawning replacements;
  - combat completion emits only when all registered enemies are defeated.

- [x] **Step 5: Implement subtitle-first dialogue**

  Every line contains speaker, text, optional audio asset, and optional auto-advance duration. Missing audio must never block advance. Support keyboard, touch, and standard gamepad confirm/skip actions.

- [x] **Step 6: Make the tutorial contextual**

  Show one action at a time using the current input device:

  - move/look;
  - interact;
  - attack/aim;
  - enter/drive;
  - map;
  - lose heat;
  - pause/save.

  Hide a prompt permanently after its action is demonstrated.

- [ ] **Step 7: Run the Milestone 0.6 mission gate**

  Verify new game, complete, fail/restart, quit/reload, and continue paths on desktop keyboard and mobile touch.

- [x] **Step 8: Commit**

  ```bash
  git add QUAHOG_GODOT1/data/missions/off_the_boat.json QUAHOG_GODOT1/data/dialogue QUAHOG_GODOT1/scripts/missions QUAHOG_GODOT1/scripts/dialogue QUAHOG_GODOT1/scripts/game_world.gd QUAHOG_GODOT1/scripts/ui/hud.gd QUAHOG_GODOT1/scripts/player.gd QUAHOG_GODOT1/tests/test_off_the_boat.gd
  git commit -m "feat(godot): ship the Off the Boat tutorial encounter"
  ```

---

## Task 7: Add Versioned, Recoverable Save Data

**Priority:** P0

**Files:**

- Create: `QUAHOG_GODOT1/scripts/save/save_schema.gd`
- Create: `QUAHOG_GODOT1/scripts/save/save_migrations.gd`
- Create: `QUAHOG_GODOT1/scripts/save/save_service.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/game_manager.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/business_manager.gd`
- Modify: `QUAHOG_GODOT1/scripts/main_menu.gd`
- Create: `QUAHOG_GODOT1/tests/test_save_service.gd`

**Interfaces:**

- Produces:

  ```gdscript
  SaveService.write(snapshot: Dictionary) -> Error
  SaveService.read() -> Dictionary
  SaveService.has_valid_save() -> bool
  SaveService.clear_progress_preserve_settings() -> Error
  SaveMigrations.to_current(data: Dictionary) -> Dictionary
  ```

- [x] **Step 1: Define schema version 3**

  Include:

  - player position/yaw/health/armor;
  - cash, reputation, police heat, faction heat;
  - mission runtime snapshot and claimed rewards;
  - businesses and revenue state;
  - collectibles and activity results;
  - current vehicle identity/condition;
  - world clock/weather;
  - graphics/audio/input/accessibility settings;
  - save timestamp and source build SHA.

- [x] **Step 2: Test old-save migration**

  Add fixtures for:

  - the current unversioned `mount_hope_save.json`;
  - campaign format 2;
  - corrupt JSON;
  - missing fields;
  - future unsupported version.

  Assert settings survive “New Game” while progress resets.

- [x] **Step 3: Implement atomic write and backup**

  Write and validate `save.tmp.json`, rotate the previous valid primary to `save.backup.json`, then rename the temporary file to `the_narrows_save.json`.

- [x] **Step 4: Remove persistence from `game_manager.gd`**

  `game_manager.gd` owns runtime state and delegates all file work to `SaveService`. Preserve compatibility through migrations; do not continue writing `mount_hope_save.json`.

- [x] **Step 5: Fix menu behavior**

  - Continue appears only for a valid save.
  - New Game confirms before replacing progress.
  - Corrupt primary offers backup recovery.
  - Pause exposes Restart Checkpoint and Save & Quit.

- [x] **Step 6: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/save QUAHOG_GODOT1/scripts/autoloads/game_manager.gd QUAHOG_GODOT1/scripts/autoloads/business_manager.gd QUAHOG_GODOT1/scripts/main_menu.gd QUAHOG_GODOT1/tests/test_save_service.gd
  git commit -m "feat(godot): add versioned recoverable saves"
  ```

---

## Task 8: Make the Game Shell Responsive and Input-Complete

**Priority:** P0

**Files:**

- Create: `QUAHOG_GODOT1/scripts/ui/layout_profile.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/big_map.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/minimap.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/virtual_joystick.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/touch_button.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/touch_camera.gd`
- Modify: `QUAHOG_GODOT1/project.godot`
- Create: `QUAHOG_GODOT1/tests/test_layout_profile.gd`
- Create: `plans/vertical-slice-release-checklist.md`

**Interfaces:**

- Produces: `LayoutProfile.for_viewport(size: Vector2, safe_area: Rect2) -> Dictionary`.

- [ ] **Step 1: Test target viewports**

  Assert profiles for:

  - `1920 × 1080`;
  - `1280 × 720`;
  - `844 × 390` landscape phone;
  - a phone safe area with `24 px` left/right insets.

  Profiles must keep pause, mission, minimap, radio, and action bounds inside the usable rectangle with no pairwise overlap among critical controls.

- [ ] **Step 2: Implement responsive layout profiles**

  Use containers/anchors for:

  - desktop;
  - compact landscape;
  - touch landscape.

  Scroll pause/settings content when height is below `600 px`. Hide keyboard help on touch and expose it from pause.

- [ ] **Step 3: Normalize input actions**

  Add keyboard and standard gamepad bindings for movement, look, interact, enter/exit, attack, aim, reload, weapon selection, map, pause, dialogue advance/skip, and checkpoint restart.

- [ ] **Step 4: Preserve editable touch controls safely**

  Keep drag/resize/edit mode, but provide Reset Layout and ensure no saved control can be restored entirely outside the current safe area.

- [ ] **Step 5: Create the vertical-slice gate**

  `plans/vertical-slice-release-checklist.md` must require:

  - current branding and matching SHA;
  - startup budgets;
  - desktop keyboard completion;
  - mobile touch completion;
  - gamepad manual pass;
  - no clipped/overlapping critical UI;
  - mission fail/restart/reload;
  - save migration/recovery;
  - no console/script errors;
  - 30-minute stability session.

- [ ] **Step 6: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/ui QUAHOG_GODOT1/project.godot QUAHOG_GODOT1/tests/test_layout_profile.gd plans/vertical-slice-release-checklist.md
  git commit -m "fix(godot): make the game shell responsive and input-complete"
  ```

---

## Task 9: Port the Boat and Street-Race Activities

**Priority:** P1 after Milestone 0.6

**Files:**

- Create: `QUAHOG_GODOT1/scripts/vehicles/boat.gd`
- Create: `QUAHOG_GODOT1/scenes/boat.tscn`
- Create: `QUAHOG_GODOT1/scripts/activities/activity_runtime.gd`
- Create: `QUAHOG_GODOT1/scripts/activities/street_race.gd`
- Create: `QUAHOG_GODOT1/data/activities/new_bedford_race.json`
- Create: `QUAHOG_GODOT1/data/activities/harbor_run.json`
- Modify: `QUAHOG_GODOT1/scripts/player.gd`
- Modify: `QUAHOG_GODOT1/scripts/game_world.gd`
- Modify: `QUAHOG_GODOT1/scripts/systems/water_hazard.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Create: `QUAHOG_GODOT1/tests/test_activity_runtime.gd`

**Interfaces:**

- Produces: activity start/checkpoint/fail/complete/reward transitions shared by race and harbor run.

- [ ] **Step 1: Test activity transitions**

  Cover ordered checkpoints, skipped checkpoint rejection, timeout, abandon, best-time update, reward-once, and save restore.

- [ ] **Step 2: Implement boat mode**

  Boat behavior must include board/exit, throttle, steer, buoyancy/bob, camera, wake, safe recovery, and water-hazard exemption only while aboard.

- [ ] **Step 3: Implement the New Bedford race**

  Use a compact road circuit in the authored district. Include start confirmation, ordered checkpoints, timer, best time, payout, cancel, and reset.

- [ ] **Step 4: Implement the harbor run**

  Use the same activity runtime with boat checkpoints and Coast Guard/police heat hooks. Do not require a new ocean simulation.

- [ ] **Step 5: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/vehicles/boat.gd QUAHOG_GODOT1/scenes/boat.tscn QUAHOG_GODOT1/scripts/activities QUAHOG_GODOT1/data/activities QUAHOG_GODOT1/scripts/player.gd QUAHOG_GODOT1/scripts/game_world.gd QUAHOG_GODOT1/scripts/systems/water_hazard.gd QUAHOG_GODOT1/scripts/ui/hud.gd QUAHOG_GODOT1/tests/test_activity_runtime.gd
  git commit -m "feat(godot): add boat and street-race activities"
  ```

---

## Task 10: Make Police, Traffic, and Pedestrians Readable

**Priority:** P1

**Files:**

- Create: `QUAHOG_GODOT1/scripts/ai/police_state.gd`
- Create: `QUAHOG_GODOT1/tests/test_police_state.gd`
- Modify: `QUAHOG_GODOT1/scripts/police.gd`
- Modify: `QUAHOG_GODOT1/scripts/systems/wanted_system.gd`
- Modify: `QUAHOG_GODOT1/scripts/npc.gd`
- Modify: `QUAHOG_GODOT1/scripts/vehicles/traffic_car.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/minimap.gd`

**Interfaces:**

- Produces police states `UNAWARE`, `PURSUING`, `SEARCHING`, `DISENGAGING`.

- [ ] **Step 1: Test pursuit state transitions**

  Assert:

  - sight plus heat enters pursuit;
  - lost sight enters search at last-known position;
  - reacquisition returns to pursuit;
  - remaining unseen for the configured search duration disengages;
  - heat does not decay while actively seen;
  - backup count is capped by wanted tier and quality profile.

- [ ] **Step 2: Integrate readable police behavior**

  Show SPOTTED, SEARCHING, and ESCAPED HUD states and the last-known search area on minimap.

- [ ] **Step 3: Improve traffic**

  Traffic must stop at lights, yield to blockers/player, avoid spawning in view, and recover from a stalled route without teleporting visibly.

- [ ] **Step 4: Improve pedestrian reactions**

  Add idle, walk, flee, cower, converse, and vehicle-dodge states. Scale density/behavior update rate by distance and quality profile.

- [ ] **Step 5: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/ai QUAHOG_GODOT1/scripts/police.gd QUAHOG_GODOT1/scripts/systems/wanted_system.gd QUAHOG_GODOT1/scripts/npc.gd QUAHOG_GODOT1/scripts/vehicles/traffic_car.gd QUAHOG_GODOT1/scripts/ui/hud.gd QUAHOG_GODOT1/scripts/ui/minimap.gd QUAHOG_GODOT1/tests/test_police_state.gd
  git commit -m "feat(godot): add readable pursuit and civic AI"
  ```

---

## Task 11: Author One Detailed New Bedford District

**Priority:** P1

**Files:**

- Create: `QUAHOG_GODOT1/data/world/new_bedford_core.json`
- Create: `QUAHOG_GODOT1/scripts/world/district_authoring.gd`
- Modify: `QUAHOG_GODOT1/scripts/world/map_loader.gd`
- Modify: `QUAHOG_GODOT1/scripts/world/hero_hubs.gd`
- Modify: `QUAHOG_GODOT1/scripts/world/safehouse_zone.gd`
- Modify: `QUAHOG_GODOT1/scripts/world/diner_interior.gd`
- Add assets: `QUAHOG_GODOT1/assets/environment/new_bedford/`
- Create: `QUAHOG_GODOT1/tests/test_district_manifest.gd`

**Interfaces:**

- Produces a district manifest of hero overrides, façade profiles, prop zones, interior entrances, ambience zones, and mission anchors.

- [ ] **Step 1: Define the district boundary and manifest**

  Limit authored work to the opening route around:

  - Seamen’s Bethel;
  - fish pier;
  - assigned-car location;
  - safehouse;
  - one diner/business;
  - connecting streets.

- [ ] **Step 2: Test manifest integrity**

  Assert unique IDs, valid asset paths, non-overlapping mission anchors, accessible entrances, and all coordinates within the district bounds.

- [ ] **Step 3: Replace the most visible placeholders**

  Deliver:

  - accurate Bethel silhouette and entrance;
  - fish-pier props and working-waterfront dressing;
  - brick, granite, clapboard, and storefront façade profiles;
  - sidewalks, crosswalks, signs, parking, street furniture;
  - one safehouse interior and one business interior;
  - three pedestrian and three vehicle visual variants;
  - harbor, street, and interior ambience zones.

- [ ] **Step 4: Keep distant regions cheap**

  Do not hand-author Fall River, Brockton, Cape Cod, or new corridors. They remain navigation/reference geography with existing streaming/LOD.

- [ ] **Step 5: Verify the mission route**

  Capture reviewed desktop/mobile screenshots at Bethel, pier, safehouse, and business in clear, rain, dusk, and night conditions. Check collision and entry paths.

- [ ] **Step 6: Commit**

  ```bash
  git add QUAHOG_GODOT1/data/world/new_bedford_core.json QUAHOG_GODOT1/scripts/world QUAHOG_GODOT1/assets/environment/new_bedford QUAHOG_GODOT1/tests/test_district_manifest.gd
  git commit -m "feat(godot): author the New Bedford opening district"
  ```

---

## Task 12: Complete Accessibility, Settings, and Audio Fallbacks

**Priority:** P1

**Files:**

- Create: `QUAHOG_GODOT1/scripts/input/action_bindings.gd`
- Create: `QUAHOG_GODOT1/scripts/ui/settings_menu.gd`
- Create: `QUAHOG_GODOT1/scripts/ui/subtitle_panel.gd`
- Modify: `QUAHOG_GODOT1/scripts/ui/hud.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/audio_manager.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/radio.gd`
- Modify: `QUAHOG_GODOT1/scripts/dialogue/dialogue_runner.gd`
- Modify: `QUAHOG_GODOT1/scripts/save/save_schema.gd`
- Create: `QUAHOG_GODOT1/tests/test_action_bindings.gd`

**Interfaces:**

- Produces device-independent action bindings and subtitle events shared by mission dialogue/radio.

- [ ] **Step 1: Test binding validation**

  Cover duplicate bindings, required-action protection, keyboard/gamepad defaults, remap persistence, and reset to defaults.

- [ ] **Step 2: Add settings**

  Include:

  - remappable keyboard/gamepad controls;
  - invert look/steering;
  - subtitle on/off, size, and background;
  - UI scale `100%`, `125%`, `150%`;
  - high-contrast markers;
  - reduced camera shake and reduced motion;
  - hold/toggle aim and sprint;
  - music, radio/voice, ambience, and effects volume.

- [ ] **Step 3: Guarantee dialogue fallback**

  Dialogue always renders subtitles. Missing/failed audio advances through the same input path and records a nonfatal diagnostic.

- [ ] **Step 4: Add accessible release paths**

  Complete “Off the Boat” with:

  - keyboard only;
  - standard gamepad;
  - touch;
  - subtitles on and audio muted;
  - UI scale 150%.

- [ ] **Step 5: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/scripts/input QUAHOG_GODOT1/scripts/ui/settings_menu.gd QUAHOG_GODOT1/scripts/ui/subtitle_panel.gd QUAHOG_GODOT1/scripts/ui/hud.gd QUAHOG_GODOT1/scripts/autoloads/audio_manager.gd QUAHOG_GODOT1/scripts/autoloads/radio.gd QUAHOG_GODOT1/scripts/dialogue/dialogue_runner.gd QUAHOG_GODOT1/scripts/save/save_schema.gd QUAHOG_GODOT1/tests/test_action_bindings.gd
  git commit -m "feat(godot): add accessible controls and subtitle-safe audio"
  ```

---

## Task 13: Replace Campaign Placeholders with an Authored Act I Pack

**Priority:** P1 after Tasks 5–12

**Files:**

- Create: `QUAHOG_GODOT1/data/missions/auction_rules.json`
- Create: `QUAHOG_GODOT1/data/missions/linguica_run.json`
- Create: `QUAHOG_GODOT1/data/missions/harbor_heat.json`
- Create: `QUAHOG_GODOT1/data/dialogue/act_one.json`
- Create: `QUAHOG_GODOT1/tests/test_act_one_integrity.gd`
- Modify: `QUAHOG_GODOT1/scripts/systems/story_mission.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/business_manager.gd`
- Modify: `QUAHOG_GODOT1/scripts/autoloads/radio_hooks.gd`

**Interfaces:**

- Consumes the mission, encounter, dialogue, save, activity, police, and district systems from prior tasks.
- Produces a three-mission pack that unlocks free-roam economy and activities.

- [ ] **Step 1: Define authored mission requirements**

  Each mission must include:

  - at least one named-character dialogue;
  - at least one interaction or encounter objective;
  - one failure condition;
  - one checkpoint;
  - a unique world/economy consequence;
  - a reward and replay policy.

- [ ] **Step 2: Test content integrity**

  Assert:

  - IDs and objective IDs are unique;
  - prerequisite graph has no cycle;
  - all dialogue/encounter/entity/asset references exist;
  - every mission is reachable after “Off the Boat”;
  - rewards cannot be claimed twice;
  - save/restore returns to the same checkpoint.

- [ ] **Step 3: Author “Auction Rules”**

  Center it on a collector encounter and Reggie’s garage, with a real lose-heat escape and an economy unlock.

- [ ] **Step 4: Author “The Linguiça Run”**

  Use pickup interaction, fragile/contraband state, timed delivery pressure, and a radio reaction. Do not make it only two reach markers.

- [ ] **Step 5: Author “Harbor Heat”**

  Include Sully’s hold on the harbor, a combat or protect encounter, police search/escape, safehouse return, and an Act I completion consequence.

- [ ] **Step 6: Demote un-authored later acts**

  Remove Act II/III entries from the automatic playable campaign until each meets the same definition of done. Preserve their design notes in a content backlog rather than presenting coordinate chains as finished missions.

- [ ] **Step 7: Verify and commit**

  ```bash
  godot --headless --path QUAHOG_GODOT1 --script res://tests/test_runner.gd
  git add QUAHOG_GODOT1/data/missions QUAHOG_GODOT1/data/dialogue/act_one.json QUAHOG_GODOT1/tests/test_act_one_integrity.gd QUAHOG_GODOT1/scripts/systems/story_mission.gd QUAHOG_GODOT1/scripts/autoloads/business_manager.gd QUAHOG_GODOT1/scripts/autoloads/radio_hooks.gd
  git commit -m "feat(godot): replace Act I placeholders with authored missions"
  ```

---

## Task 14: Enforce Release Budgets and Ship 1.0

**Priority:** P0 for release

**Files:**

- Create: `docs/qa/release-matrix.md`
- Create: `docs/qa/known-issues.md`
- Create: `docs/qa/save-compatibility.md`
- Create: `CHANGELOG.md`
- Modify: `plans/smoke-test-checklist.md`
- Modify: `.github/workflows/godot-ci.yml`
- Modify: `docs/releases/deployment-record.md`

**Interfaces:**

- Consumes every automated/manual gate above.
- Produces a release record tied to one merged SHA and one production deployment.

- [ ] **Step 1: Build the release matrix**

  Track:

  - Chrome and Edge desktop;
  - Safari desktop;
  - current iOS Safari;
  - current Android Chrome;
  - keyboard/mouse, standard gamepad, and touch;
  - new game, continue, old-save migration, corrupt-save recovery;
  - complete/fail/restart/reload for “Off the Boat”;
  - boat, race, police search, economy, Act I;
  - clear/rain/dusk/night;
  - 30-minute soak and three mission-restart memory loop.

- [ ] **Step 2: Enforce performance budgets**

  Release fails when:

  - menu interactive exceeds `12 s` cold broadband desktop;
  - Play-to-control exceeds `12 s`;
  - desktop median frame rate is below `55 FPS` on the reference machine;
  - agreed reference phone median is below `30 FPS`;
  - heap grows more than `10%` across three identical opener retries;
  - WebGL context is lost during the soak;
  - compressed initial payload exceeds `35 MB`.

- [ ] **Step 3: Update smoke-test evidence**

  Convert each checkbox in `plans/smoke-test-checklist.md` into a row with:

  ```text
  Build SHA | Platform | Input | Result | Evidence | Date | Verifier
  ```

  Automated checks may link CI artifacts; visual/feel checks link a screenshot or recording.

- [ ] **Step 4: Run the release candidate**

  ```bash
  cd QUAHOG_GODOT1
  GODOT_BIN=godot bash scripts/verify.sh
  python3 scripts/check_asset_budget.py
  ```

  Then complete the release matrix against the preview built from the same SHA.

- [ ] **Step 5: Publish production**

  - merge the reviewed release pull request;
  - deploy only the saved artifact/source SHA;
  - verify the in-game SHA equals the merged SHA;
  - rerun menu, opener, save/continue, boat/race, and Act I smoke paths;
  - add known issues, save version, and deployment record to `CHANGELOG.md`.

- [ ] **Step 6: Commit release records**

  ```bash
  git add docs/qa docs/releases/deployment-record.md plans/smoke-test-checklist.md CHANGELOG.md .github/workflows/godot-ci.yml
  git commit -m "release(godot): certify The Narrows 1.0"
  ```

---

## Deferred Program Backlog

These supplied-master-plan areas remain valid but are intentionally outside the 1.0 completion path:

- authored Act II and Act III;
- Fall River, Brockton, Cape Cod, and new highway expansion;
- the exhaustive 1980s vehicle list, rewritten as a smaller fictional present-day fleet;
- motorcycles, mopeds, bicycles, aircraft, and large marine fleets;
- complete weapons/wardrobe/character atlases;
- more than two enterable interiors;
- advanced tides, seasons, snow, full flood simulation, destruction, and procedural living economy;
- facial capture/lipsync and complete recorded VO;
- in-engine world/mission editor;
- desktop/console packaging and multiplayer.

Each deferred item requires a separate implementation plan with a player-facing goal, measurable acceptance criteria, asset budget, and release owner.

## Explicitly Rejected from This Ship Target

- rebranding the product back to Mount Hope;
- restoring the 1986 setting;
- using real trademarked vehicle/weapon names as shipped content;
- making Google 3D Tiles or ElevenLabs required for play;
- claiming completion from coordinate markers alone;
- feature-by-feature parallel development in web, Godot, and Unreal;
- publishing a build whose commit SHA cannot be proven.

## Completion Definition

This program is complete only when:

- all 14 tasks and checkboxes are complete;
- repository source-of-truth files agree;
- strict import, automated tests, and Web export pass from a clean checkout;
- production displays current The Narrows branding and the exact merged SHA;
- startup, payload, frame-rate, memory, and soak budgets pass;
- “Off the Boat” is an authored, fail-safe, checkpointed tutorial;
- saves migrate and recover;
- desktop, mobile touch, and gamepad paths pass;
- boat and street-race activities work;
- police search/escape and civic AI are readable;
- the opening New Bedford district and Act I content meet their authored gates;
- the cross-browser release matrix is signed off with evidence.
