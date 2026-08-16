# Engine Reconciliation

This repository contains several implementations created during prototyping.
They do not share canonical status.

## Decision

`QUAHOG_GODOT1/` is the **The Narrows ship target**.

- Engine: Godot 4.6 stable.
- Renderer: GL Compatibility.
- Platforms in current scope: Web and mobile browser.
- Product title: The Narrows.
- Setting: Massachusetts South Coast, present day (2026).

This decision records the later June 26 Godot pivot in `plans/mount-hope.md`
and supersedes the June 21 web-canonical declaration that remained in older
root documentation.

## Track roles

| Track | Status | Validation |
|---|---|---|
| `QUAHOG_GODOT1/` | **Ship target** | strict Godot import, tests, Web export, browser release matrix |
| `QUAHOG_Web/` | Reference/deployed comparison | `npm test`, `npm run build`, browser smoke |
| `MountHope_Unreal/` | Separate premium PC/console research track | repo static gates plus real UE 5.8 compile on an Unreal workstation |
| `QUAHOG_Unity/` | Legacy | no main-product completion claims |
| `QUAHOG_Godot/` | Legacy predecessor | no main-product completion claims |
| `QUAHOG_Unreal/` | Legacy predecessor | no main-product completion claims |

## Cross-track rules

- Port behavior and content deliberately; do not develop every feature in all
  engines at once.
- Shared story and map data may be reused, but runtime-specific code stays in
  its track.
- A working reference-web feature is not evidence that the Godot ship target
  is complete.
- Unreal work does not replace the browser/mobile ship target without a new,
  explicit product decision.
- Every release record identifies track, commit SHA, test evidence, and URL or
  package.

## Map pipeline

`quahog-project-files/mapdata/` is the shared source pipeline. Godot consumes
the committed derived data under `QUAHOG_GODOT1/data/map/`. Regeneration is not
required for ordinary game development.
