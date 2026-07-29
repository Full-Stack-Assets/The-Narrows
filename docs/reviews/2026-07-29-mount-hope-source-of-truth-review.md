# Mount Hope Source-of-Truth Review

**Reviewed and execution-baselined:** July 29, 2026  
**Input:** `/Users/nicalbertson/Library/Mobile Documents/com~apple~CloudDocs/Downloads/quahog-main 3/plans/mount-hope.md`  
**Repository:** `Full-Stack-Assets/The-Narrows` at `4a999f6c3ea7fb812f753d9d0d1dcb863e730ae2`  
**Related implementation plan:** `docs/superpowers/plans/2026-07-29-the-narrows-godot-completion.md`

## Outcome

The supplied document is valuable as a feature inventory and development history, but it is not safe to execute literally.

Its durable direction is:

- a real South Coast open world;
- current title **The Narrows**;
- present-day subtitle **South Coast · Now**;
- a grounded crime-drama loop;
- Godot as the stated ship target after the June 26 engine pivot;
- the web game as the behavior/content reference;
- one deeply authored New Bedford opening before further geographic expansion.

Its obsolete or contradictory direction is:

- the **Mount Hope** product title;
- the **1986** setting;
- treating branded real-world vehicle/weapon lists as a production backlog;
- editing `QUAHOG_Web/` in a working loop that calls Godot the ship target;
- considering web, Godot, and Unreal canonical at the same time;
- marking proximity-only missions “done” when their authored encounters, dialogue, failure, and checkpoint behavior are absent;
- treating a successful export as sufficient proof of a playable release.

The existing web-first remaining-work plan has therefore been superseded by a Godot completion plan. The web build remains the reference implementation and an independent live product until a deliberate retirement decision is made.

## Evidence

### Repository declarations disagree

| Source | Current declaration |
|---|---|
| `plans/mount-hope.md` | `QUAHOG_GODOT1/` is the ship target; web is the port reference |
| `plans/elevation-plan.md` | Godot is the active ship target |
| `plans/web-godot-parity-checklist.md` | Web is the canonical reference; Godot is the ship target |
| `README.md` | Web is canonical; Godot is described as legacy |
| `ENGINES.md` | Web is canonical; Godot is legacy |
| `AGENTS.md`, opening | Godot is the shippable product |
| `AGENTS.md`, detailed section | Web is the only canonical runnable product |
| July 7–8 commits | Development is concentrated in `MountHope_Unreal/` |

The June 26 commit `fc5b2195b2679f6caf402d8f4bd97b57656d3c47` explicitly changed the plan to make `QUAHOG_GODOT1/` canonical. Root engine documentation was not reconciled afterward. Later Unreal work also did not reconcile the product declaration.

### Current Godot code is newer than the deployed Godot build

Current `main` contains:

- `project.godot`: application name **The Narrows**;
- `scripts/main_menu.gd`: “SOUTH COAST · NOW” and text wordmark “THE NARROWS”;
- `plans/the-narrows.md`: present-day brand decision.

The production Godot URL `https://quahog.vercel.app/` rendered on July 29:

- browser title “Mount Hope”;
- menu wordmark “MOUNT HOPE”;
- era line “SOUTH COAST · 1986”;
- a roughly 30-second first load to menu;
- another long load after selecting Play.

The deployment therefore does not prove that current `main` is shipped. A release must expose and verify the exact commit SHA.

### Mission completion is overstated

`QUAHOG_GODOT1/scripts/systems/story_mission.gd` contains the full campaign title list, but its implemented objective gates are primarily:

- reach a position;
- be in a car;
- have no police/faction heat.

The opener raises heat and displays “Ambush!” after reaching the pier, but does not instantiate an encounter, named actors, dialogue, enemies, failure conditions, or checkpoints. Similar gaps exist across later campaign missions. “Campaign data exists” is proven; “authored campaign is complete” is not.

### Verification is too weak

`QUAHOG_GODOT1/build_web.sh` currently:

- downloads Godot during the build;
- does not verify the downloaded binary checksum;
- runs import with `|| true`, allowing import errors to be ignored;
- exports a large Web build;
- has no repository Godot CI workflow;
- has no automated Godot unit/integration test runner.

`plans/smoke-test-checklist.md` is useful but entirely manual and does not record browser/device/build-SHA evidence.

## Requirement Disposition

Every major section of the supplied master plan is assigned below.

| Source sections | Disposition | Completion-plan coverage |
|---|---|---|
| Working loop; Foundations & ops; QA/release | **Schedule now** | Tasks 1–3, 14 |
| Godot roadmap P1–P10 | **Rebaseline from code/runtime evidence** | Tasks 2–14 |
| Player, camera, driving, heat, economy | **Preserve and regression-test** | Tasks 3, 8, 9 |
| “Off the Boat,” mission framework, dialogue | **Schedule now** | Tasks 5–6 |
| Save/load, Continue, settings | **Schedule now** | Task 7 |
| Boat and street race parity | **Schedule after vertical slice** | Task 8 |
| Police, NPC, traffic depth | **Schedule after vertical slice** | Task 9 |
| New Bedford world detail and landmarks | **Schedule one district only** | Task 10 |
| Audio, radio, VO | **Schedule text/subtitle-safe version** | Task 11 |
| Controls/accessibility | **Schedule before release** | Task 12 |
| Act I content | **Schedule after runtime is proven** | Task 13 |
| Act II/III labels currently in code | **Reauthor after Act I gate** | Deferred program backlog |
| Full South Coast, Brockton, Cape, highways | **Freeze until New Bedford gate passes** | Deferred program backlog |
| Large vehicle, weapon, wardrobe, character atlases | **Content backlog, not 1.0 scope** | Deferred program backlog |
| Interiors atlas | **One safehouse + one business for 1.0** | Task 10; remainder deferred |
| Advanced weather, tide, flood, seasons | **Keep Gloria hook; defer simulation depth** | Task 13; remainder deferred |
| Tooling/world editor/hot reload | **Defer until content cadence proves need** | Deferred program backlog |
| Photoreal Google 3D Tiles | **Reject for Godot ship target** | Web-only reference |
| Multiplayer/native console wrap | **Reject from current release scope** | Separate product decision |
| 1986 art/UI/props | **Superseded** | Replace with 2026 present-day direction |
| Mount Hope product branding | **Superseded** | Geography may retain “Mount Hope Bay” |
| Real vehicle/weapon trademarks | **Reference only** | Ship fictionalized names/designs |
| ElevenLabs as a hard dependency | **Reject** | Recorded/TTS VO is optional; subtitles must work without it |
| Parallel feature development in all engines | **Reject** | One ship target; other tracks are reference or separate products |

## Corrected Product Decision

Until the repository owner records a different choice, execute with this hierarchy:

1. `QUAHOG_GODOT1/` — ship target for The Narrows browser/mobile build.
2. `QUAHOG_Web/` — behavior, content, and comparison reference; maintain only release-blocking defects.
3. `MountHope_Unreal/` — separate premium PC/console research track; no shared completion claims.
4. earlier Unity/Godot/Unreal directories — legacy/reference.

This follows the later explicit engine pivot in `plans/mount-hope.md` while retaining the only deployed mature build as a reference.

## Honest Current Baseline

### Proven

- Godot project structure and main scenes exist.
- Current source is branded The Narrows / present day.
- OSM map loading, building streaming, driving, basic traffic/pedestrians, combat, heat, economy, radio, map, fast travel, businesses, collectibles, save/continue, and campaign data are implemented.
- A Godot web deployment exists and reaches a menu.

### Partial

- current-source deployment;
- startup performance;
- mission runtime depth;
- opener ambush and tutorial;
- save migrations and recovery;
- touch/responsive usability;
- boat/race parity;
- police search/give-up behavior;
- authored NPCs, interiors, landmarks, and ambience;
- gamepad/remapping/accessibility;
- automated tests and CI.

### Not proven

- current `main` exports without import errors;
- current `main` is what production serves;
- all manual smoke paths pass;
- a complete mission can fail, restart, checkpoint, and restore;
- Act I–III are authored rather than positional objective sequences;
- mobile performance and memory meet a release budget;
- cross-browser compatibility;
- a 30-minute stable play session.

## Immediate Priority

Do not add regions or expand the encyclopedic asset atlases next.

The correct next sequence is:

1. reconcile repository declarations and deployment ownership;
2. establish deterministic Godot import/export/tests in CI;
3. ship current The Narrows branding with a visible build SHA;
4. cut first-load time and make the menu/world transition measurable;
5. replace the positional mission script with a testable runtime;
6. make “Off the Boat” a real tutorial/encounter with checkpoint recovery;
7. prove save, mobile UI, and input behavior;
8. then add boat/race parity and one authored New Bedford content pack.
