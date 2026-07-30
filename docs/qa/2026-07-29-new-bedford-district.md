# New Bedford opening district QA — 2026-07-29

## Scope

The reviewed route covers Seamen's Bethel, the New Bedford Fish Pier, the
opening safehouse, Linguiça Linq, the assigned-car/mission anchors, and the
connecting authored block.

## Automated contracts

- `python3 -m unittest tests/test_build_scripts.py`: 11 tests passed.
- Godot headless suite: 286 assertions passed.
- Web export manifest: passed; retired title/loading art absent and required
  opening-route resources present.
- Compressed asset budget: passed under the 35 MiB opening-payload limit.
- Manifest validation covers unique IDs, bounds, asset references,
  non-overlapping mission anchors, entrance radius/approach width, visual
  variants, and collision on the Bethel and pier.
- Core/deferred tests prove missing deferred models are skipped safely and are
  mounted idempotently when the deferred pack becomes available.

## Visual matrix

The local WebGL release export was reviewed at 1280×720 and 844×390 for every
combination below. The capture harness clears browser storage before each case,
sets time/weather through the shipped test tools, quick-starts the location,
waits for `DISTRICT_CORE_DRESSING_READY`, and rejects console/page errors.

| Viewport | Clear 12:00 | Forced rain 12:00 | Dusk 18:00 | Night 00:00 |
| --- | --- | --- | --- | --- |
| Desktop | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner |
| Mobile landscape | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner | Bethel, pier, safehouse, diner |

Result: 32/32 frames captured with an empty diagnostics list. Forced rain is
visible from the interactive core; night keeps the player, route surface,
entrances, and landmark lighting readable.

## Visual/collision review

- Bethel has a collision-backed nave, gabled colonial silhouette, individual
  windows, entrance trim, steps, forecourt, signage, and time-aware lanterns.
- The pier has a collision-backed deck, harbor water, working shed, windows,
  roof, hoist, crates, bollards, dumpster, and harbor ambience.
- The safehouse and diner have unobstructed, collision-backed approaches and
  recognizable frontage/interior dressing.
- Business/safehouse indicators are ground rings; the former upright neon
  arches and oversized marker wall are gone.
- Twelve collision-backed façade placements enclose the route while distant
  regions remain on the existing streamed/LOD path.
- Four lightweight practical street lamps ship in the opening core so night
  navigation does not wait for the deferred content pack.

## Reproduction

The reviewed screenshots are written to:

`/tmp/narrows-task11-matrix/{desktop,mobile}/{clear,rain,dusk,night}-{bethel,pier,safehouse,diner}.png`

The temporary Playwright harness is `/tmp/narrows-district-matrix.mjs`.
