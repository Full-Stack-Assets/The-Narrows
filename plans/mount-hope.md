# The Narrows — Historical Master Checklist & Running Log

> **Title:** The Narrows (*South Coast · Now*, 2026). Legacy working titles:
> Project QUAHOG and Mount Hope. Product/engine authority now lives in
> `docs/product/source-of-truth.md`; the execution backlog lives in
> `docs/superpowers/plans/2026-07-29-the-narrows-godot-completion.md`.

This file preserves the broad feature inventory and historical running log.
Update status only when the named track is built, verified, and shipped. Do not
use a web-reference checkmark as evidence that the Godot ship target is done.

- **Working title:** **The Narrows** (retired “Project QUAHOG” and “Mount Hope” as product name)
- **Canonical engine (build target):** `QUAHOG_GODOT1/` — **Godot 4.6**, GL Compatibility (mobile/web export), pure GDScript. This is what we ship.
- **Reference spec (port FROM here):** `QUAHOG_Web/` — Three.js / React Three Fiber + Rapier. The web build is the most complete realization of The Narrows; **Parts I–III below describe its feature set and are the target the Godot port recreates.** Live: https://projectsouthcoast.vercel.app
- **Goal:** recreate the web game in Godot — the exact New Bedford map (buildings, roads, waterfront), the characters/heroes, vehicles, and the full GTA-style gameplay loop — as a faithful port, then carry it forward natively.
- **Cadence:** execute the active completion plan one reviewable task at a time;
  keep strict Godot import, tests, and export green.
- **Design canon:** `quahog-project-files/CHARACTERS_AND_MISSIONS.md`, `GEMINI_BUILD_PROMPT.md`, `ROADMAP.md`.
- **Verification:** headless compile — `godot --headless --path QUAHOG_GODOT1 --import` must report zero script/parse errors before shipping.

Godot status legend: `[Gx]` verified and shipped · `[G~]` partial · `[G ]` not
started. Web reference status: `[Wx]`, `[W~]`, `[W ]`. Historical unprefixed
checkboxes are not authoritative until re-baselined against code, tests, and a
deployment SHA.

> **Re-baselining note:** Parts I–III were authored against the web build and
> remain a reference inventory. Record Godot and web status separately; never
> mirror one track’s checkmark into the other.

---

## Working loop (how this plan gets executed)

Repeat this loop every working cycle. One task (or one small coherent batch) at a
time; keep the build green; be honest about status.

1. **READ** — open the active completion plan, this historical inventory, and
   the latest running-log entry. Select the next dependency-ready task.
2. **SCOPE** — restate the task, files, tests, and acceptance criteria. Mark only
   the active plan’s checkbox in progress.
3. **BUILD** — implement in `QUAHOG_GODOT1/`; use `QUAHOG_Web/` only as a
   behavior/content reference unless the task explicitly names a web fix.
4. **VERIFY** — run `GODOT_BIN=godot bash QUAHOG_GODOT1/scripts/verify.sh`.
   Import, automated tests, and release Web export must all pass.
5. **REVIEW** — compare the result to the acceptance criteria and inspect the
   affected desktop/mobile runtime paths. Record partial work honestly.
6. **COMMIT** — commit the focused change on a feature branch and append the
   commit hash, verification result, and follow-up to the running log.
7. **PULL REQUEST** — push the feature branch, review it, and merge normally.
   Do not fast-forward local work directly into `main`.
8. **DEPLOY & PROVE** — verify the deployed build displays the merged commit SHA
   and record the URL/date/verifier.
9. **REPEAT** — return to the active completion plan.

**Rules of the loop**
- Never leave the build broken between cycles.
- Don't check a box until it's actually built + verified + shipped.
- Record blockers explicitly (e.g., needs a key/asset/user decision) and skip to
  the next unblocked task rather than stalling.
- Batch only tightly-related tasks; otherwise one at a time for clean history.
- The user can interrupt to re-prioritize at any point; honor it, then resume the loop.

---

## §G0. Godot port — current state (baseline)

What `QUAHOG_GODOT1/` actually has today (from the initial upload), verified compiling
on Godot 4.6. This is the floor we build the recreation on.

- [x] Project boots: `project.godot` (The Narrows, GL Compatibility, mobile/landscape), autoloads (LoadingScreen, AudioManager, GameManager, VFX), input map (move/jump/sprint/interact/fire/aim/reload/enter_vehicle/crouch/pause).
- [x] Main menu scene → game world scene flow (`scenes/main.tscn`, `game_world.tscn`, `player.tscn`).
- [x] Player controller: walk/sprint, health/armor/damage (`take_damage`), melee + gunfire, hooks for models/audio (load-at-runtime, degrades without assets).
- [x] Weapons data + behavior: fists/bat/pistol/shotgun/rifle (`data/weapon_db.gd`), pickups.
- [x] NPCs + police (3-HP enemies, pursuit), wanted system, job manager (deliveries), shops (weapons/ammo).
- [x] UI: HUD, minimap, shop menu, touch controls (virtual joystick + buttons).
- [~] City: **procedural grid** city (`world/city_builder.gd`) — placeholder; **to be replaced by the real New Bedford map** (see roadmap P1).
- [ ] Real OSM map, real heroes/characters, missions, economy, radio, weather/VFX depth — all to be ported from the web spec.

## §GR. Recreation roadmap (phased — the Godot port of the web game)

Coarse phases; each expands into working-loop tasks. Order: world foundation → actors →
systems → content → aesthetics/polish. Re-order freely as reality dictates.

- [x] **P1 — World foundation: the real map.** `MapLoader` imports `slice-newbedford.json` (roads/buildings/land-use/landmarks/water) and builds extruded buildings + per-tile colliders, road ribbons (asphalt), ground plane + collider; derives all spawn fields. Procedural grid replaced.
- [~] **P2 — Streaming & scale.** Fixed core radius built at load; ambient traffic/pedestrians stream player-relative (respawn when far). Tile streaming/LOD still open.
- [x] **P3 — Player & camera parity.** Chase + look cameras, on-foot + driving, wall/ground collision on the real geometry; T-pose fixed (skeleton unique-name).
- [x] **P4 — Vehicles & traffic.** Drivable physics car (enter/exit, speedometer, engine/screech audio) + parked cars + ambient kinematic traffic (sedan/taxi/SUV) cruising the road graph and following the player.
- [x] **P5 — NPCs & police.** Pedestrians wander + follow the player + flee from gunfire; police pursue/shoot/arrest on heat; cop blips on the minimap.
- [~] **P6 — Gameplay systems.** Delivery job loop (pickup→dropoff→payout), dual-axis heat/wanted (gunfire draws police), wallet/economy, save/Continue (position+heading+cash+wanted), day/night clock. Mission chain + safehouses/businesses still open.
- [~] **P7 — Heroes & landmarks.** Real landmark dataset surfaced on the Big Map + minimap (Seamen’s Bethel, Whaling Museum, etc.). 3D hero models (Battleship Cove, Braga, Lizzie Borden) still open (need corridor slice).
- [x] **P8 — Aesthetics & atmosphere.** Dusk look + day/night cycle, rain weather, day/night streetlights, fog/glow tuning, façade/asphalt textures — within GL Compatibility.
- [~] **P9 — Audio & radio.** SFX (weapons/footsteps/pickups/vehicle), exploration score + coastal ambience, 4 radio stations (manifest, shuffle, HUD + number keys, score-ducking). VO pipeline still open.
- [~] **P10 — UI/UX, accessibility, polish, perf, QA.** HUD parity (cash/wanted/clock/speedometer/objective/radio), main menu + Settings (volume) + pause, touch controls, M-map/number-radio keys, headless smoke tests green. Gamepad/perf pass still open.

### §GR-FT. Maps, fast travel & the New Bedford ↔ Fall River corridor

Reference-heavy navigation (web parity): minimap + full-screen Big Map + fast travel,
expanding outward from the New Bedford core along the real highway spine.

- [x] **Minimap** — real OSM streets binned into cells, player heading, objective/cop blips, district label.
- [x] **Big Map** (HUD `MAP`) — full street network zoomed out, player + objective markers.
- [x] **Fast travel** — `player.fast_travel_to()` raycasts to ground; Big Map shows named destinations (Downtown, Whaling Museum, State Pier, North/South End, Fort Taber, Fairhaven, Clark's Cove), tap a name to jump.
- [ ] **Big Map polish** — set-waypoint, street-name labels, water/parks fill, legend. (Pan/zoom intentionally omitted per user.)
- [x] **Corridor unlocked (2026-06-27).** The full South Coast was already in the Godot data (16,167 roads spanning NB→Westport→Fall River; 955 building tiles to X=−44 ≈ 22 km west). Rather than re-pull, the loader now builds ground + land-use + the **entire road network** once over the full extent, and **streams building tiles** within `_stream_radius` of the player (re-streamed on tile-cross / after fast travel). So NB ↔ Dartmouth ↔ Westport ↔ Fall River are all explorable at constant per-frame cost.
- [x] **Corridor fast-travel** — Big Map **TRAVEL** button column: New Bedford / Fort Taber / Fairhaven / Dartmouth / Westport / Fall River (real coords); lands on the ground, tiles stream in.
- [~] **Drivable highways detailing (2026-06-27/28)** — motorway/trunk (+links) read as highways: **steel guardrails**, **green MUTCD guide-sign gantries**, **lane paint** (solid white edge lines + dashed white lane dividers), and no city sidewalks. City arterials (primary/secondary/tertiary) get a **double-yellow centreline** and **white stop bars** at major intersections (junctions where 3+ arterial ways meet — 283 detected). Fast travel brings your car (parks it via the drive-integrator reset). All visual (driving still uses the ground plane). Still want: on/off ramps as distinct surfaces, zebra crosswalks.
- [x] **Fall River heroes (2026-06-27)** — **Braga (“Verde”) Bridge** as a green through-truss over the real 823 m I-195 deck (chords + verticals + diagonals + portal bracing; asphalt stays drivable). **USS Massachusetts** silhouette (hull, superstructure, conning tower, funnel, mast, 4 twin-barrel turrets) moored at Battleship Cove on its real coords, aligned to the bridge. **Hero beacons**: 15 curated South Coast landmarks carry an emissive dusk beacon + billboard name. **Mill-belt tint**: FR/Westport buildings (x < −16 km) bias to deep mill brick + granite. Both bridge + cove are in the Big Map travel column. Still want: Lizzie Borden House (not in OSM slice — needs a manual coord).
- [x] **Fast travel brings your car (2026-06-27)** — teleporting while driving moves the car with you and keeps you at the wheel (place_at zeroes physics + snaps the chase cam).
- [x] **More real map layers (2026-06-27)** — render the previously-unused OSM overlays: harbour **islands**, **railbeds**, and the granite **Hurricane Barrier** across the harbour mouth.

---

# Part I — Target spec (web build feature set; boxes reflect WEB status)

## 0. Foundations & ops
- [x] Repo + branch workflow; Vercel project + git auto-deploy (`projectsouthcoast`)
- [x] Historical June 21 engine reconciliation: R3F was selected at that time;
  superseded by the June 26 Godot ship-target pivot and
  `docs/product/source-of-truth.md`
- [x] Game named **The Narrows** (formerly Mount Hope)
- [x] Design docs: README, ROADMAP, Characters & Missions bible, Gemini build spec
- [x] CI: typecheck/build check on PRs — `.github/workflows/web-ci.yml` runs `tsc && vite build` on PRs/pushes touching `QUAHOG_Web` (uses `npm install`; lockfile drifts from package.json — `@vercel/blob` missing from the lock)
- [~] Bundle code-splitting — `vite.config` `manualChunks` splits three / @react-three / rapier / react into long-lived vendor chunks; earth is already its own entry (lazy-load of the earth route still open)
- [x] Asset loading/preload screen + progress bar — `loadSlice` streams the slice JSON and reports 0..1; StartMenu shows a progress bar + `LOADING NEW BEDFORD · NN%`
- [x] Error boundary + crash overlay on the main game — `ui/ErrorBoundary.tsx` wraps `<App>` in `main.tsx` (recoverable overlay + reload + build stamp)
- [~] Versioning / changelog; **build stamp in-game (commit hash, build date) — done** (HUD bottom-left, injected by vite define); changelog still open
- [x] Analytics-free telemetry stub (FPS, load time) behind a debug flag — `ui/DebugStats.tsx`, off by default (`?debug` / localStorage / backtick toggle)

## 1. World data & pipeline
- [x] OSM pull: New Bedford + Fall River (roads/water/rail/coastline/boundary)
- [x] Exports: GeoJSON, PMTiles, OBJ (`quahog-project-files/mapdata/`)
- [x] Slice blockout JSON (1071 buildings, 808 roads, harbor water, landmarks)
- [x] Pipeline scripts: `split_layers.py`, `bake_meshes.py`, `make_slice.py`
- [ ] Expand slice: full Fall River, Brockton, Cape Cod
- [ ] Real building heights/levels where OSM-tagged; roof shapes
- [ ] POI/landmark dataset beyond New Bedford
- [x] Land use layers (parks/grass, parking lots, beaches, water edges) for ground variety — OSM overlays baked to `*-newbedford.json`, rendered by `FlatAreas` (parks/wood/cemetery green, parking grey, beach tan) + `Water`
- [ ] Sidewalk/curb extraction (separate ped surfaces from roadway)
- [x] Railways, bridges, piers as distinct meshes — `Rail`, `Bridges`, `Piers`
- [ ] Street-name + address data for signage/navigation

## 2. World rendering & environment
- [x] Real street grid (roads + highways, textured)
- [x] Auto-extruded buildings (hull colliders near core, merged far mesh)
- [x] Harbor ocean (triangulated water)
- [x] Daytime sky + sun + fog
- [x] Procedural ground/road textures
- [x] Clouds + airliners
- [x] Hero landmark: Seamen’s Bethel (modeled + collider)
- [~] Satellite ground via signed Static Maps proxy — needs Vercel env vars + verify/align
- [ ] Varied building façades (windows, doors, brick/clapboard/granite materials, storefronts, roof detail)
- [~] Curbs, sidewalks, crosswalks, road markings, manholes, potholes — concrete apron curbs + dedicated sidewalk texture, `Crosswalks`, lane markings, `RoadFixtures` (manholes/grates), asphalt repair patches; potholes still open
- [x] Parks/grass/trees/foliage, planters, hedges — `FlatAreas` greens + `AreaTrees`/`Props` trees + `Foliage` bushes/tufts
- [ ] Distant skyline / horizon backdrop + atmospheric haze
- [ ] Hand-detailed landmarks: Whaling Museum, Custom House, Double Bank, Battleship Cove, Lizzie Borden House, St. Anne’s, Braga/Verde Bridge, the mills
- [ ] Interiors for key buildings (chapel, bar, gym, safehouse)
- [ ] LOD + impostors for distant buildings

## 3. Aesthetics & art direction
- [ ] Define a **style guide** (palette, era 2026, materials, signage fonts, mood boards) in `quahog-project-files/` — see STYLE_GUIDE.md
- [ ] Time-of-day color grading (dawn/day/golden hour/dusk/night palettes)
- [x] Filmic tone mapping (ACES) + exposure
- [~] Post FX: bloom, SSAO/GTAO, vignette, subtle film grain, chromatic aberration, sharpen — bloom + vignette + SMAA + **chromatic aberration + film grain** live (Effects.tsx); SSAO/sharpen TODO
- [ ] Depth of field (cinematic + photo mode), motion blur (camera + object)
- [ ] **“Coastal Neon” dusk**: glowing tavern/shop signs, wet-surface reflections, neon spill light
- [ ] Screen-space reflections / reflective wet roads
- [ ] God rays / volumetric light shafts through fog
- [ ] Color LUT system (swap grades per district/weather/mission)
- [ ] Material weathering: rust, grime, salt stains, peeling paint, moss on granite
- [ ] Decal system: stains, cracks, graffiti, posters, tire marks, blood (toggleable)
- [ ] Consistent PBR material library (asphalt, cobble, brick, granite, wood, metal, glass, water)

## 4. Lighting
- [x] Day/night dynamic sun/moon + ambient changes — DayNight.tsx, 600s cycle, sun pos/intensity/color + hemisphere + ambient + fog/bg drive
- [~] Street lights (auto on at dusk), warm sodium glow — lamp-head emissive ramps with night (Props.tsx); real per-lamp point lights TODO
- [~] Lit building windows at night (emissive, randomized) — warm emissive glow ramps at night across all building materials (Buildings.tsx); per-window mask/randomization TODO
- [ ] Neon/shop signs as light sources
- [ ] Vehicle headlights/taillights/brake lights as real lights
- [ ] Emergency lights (police) flashing
- [x] **Palmer’s Island Lighthouse** rotating beam — Lighthouse() in DayNight.tsx, beam brighter at night
- [ ] Light probes / baked GI for interiors; shadow cascades tuning
- [x] Moon + star sky at night; sunrise/sunset gradients — drei <Stars> + Sky sunPosition + fog/bg gradient by hour

## 5. Weather & VFX
- [~] **WeatherController** state machine: Clear / Dense Fog / Coastal Rain / Nor’easter — Clear/Rain/**Fog** cycle (store.ts, key R); Nor’easter TODO
- [~] Rain particles + screen rain droplets + ripples/puddles — falling rain streaks (Rain.tsx) + grey grade/closer fog (DayNight); droplets/puddles TODO
- [x] Wet-surface shader blend (roads darken/shine when wet) — roads drop roughness + gain metalness in rain (Roads.tsx)
- [x] Fog volumes (dense coastal fog), variable density — FOG weather state pulls scene fog near/far right in (DayNight.tsx)
- [ ] Wind (sway on trees/flags/signs; blowing litter/leaves)
- [ ] Lightning + thunder (Nor’easter)
- [ ] Snow/sleet variant; splash particles in puddles
- [ ] Weather ↔ vehicle friction tie-in (slick cobbles, flooded docks)
- [ ] Smooth weather transitions + scheduler

## 6. Ocean & harbor
- [x] Static harbor water surface
- [~] Animated waves (Gerstner) + foam at shoreline/piers — crossing-sine ocean swell on the harbor surface (Water.tsx); true Gerstner + shoreline foam TODO
- [ ] Reflections + fresnel + depth-based color
- [~] Boats bobbing; ferries; fishing vessels with wakes — bobbing fishing boats (HarborProps.tsx); ferries/wakes TODO
- [~] Buoys, nets, lobster traps, dock pilings — dock pilings + bobbing buoys along the OSM shoreline (HarborProps.tsx); nets/traps TODO
- [~] Splashes when entering water; swim/drown logic — open water is now a **barrier**: drive/walk in and you sink + recover onto land, so bridges are the only crossing (Hazards.tsx/waterZones.ts); splash VFX + true swim TODO
- [ ] Tide / “Gloria” flood level change

## 7. World props & set dressing
- [~] Street furniture: lamp posts, benches, trash cans, hydrants, mailboxes,
  bus stops, parking/payment kiosks — instanced lamp
  posts/benches/hydrants/mailboxes along road edges in the web reference;
  current-day bus stops and parking fixtures remain open in Godot
- [~] Traffic lights + stop signs (functional + decorative) — decorative signal heads cycling R/G/A near the core (TrafficLights.tsx); functional stop-at-light + stop signs TODO
- [ ] Power lines / utility poles, dumpsters, crates, pallets
- [ ] Storefront awnings, signage, A-frame signs, window displays
- [x] Parked cars lining streets — static vehicles tucked against the curb near the core (ParkedCars.tsx)
- [ ] Harbor props: nets, traps, barrels, forklifts, shipping containers
- [~] Vegetation: street trees, weeds in cracks, harbor grass — instanced street trees (Props.tsx); weeds/harbor grass TODO
- [ ] Litter/newspapers/leaves (wind-driven), puddles
- [ ] Birds: gulls (flocking near harbor), pigeons; stray dogs/cats

## 8. Environmental storytelling
- [~] Posters/flyers for the radio stations + fictional businesses — wheat-pasted flyer boards (WHALE/The Rage/Maré Alta + Feast banner) near the core (Posters.tsx); building-wall pasting TODO
- [ ] Graffiti tags per faction/turf
- [ ] Murals (Portuguese/Cape Verdean South End, whaling heritage)
- [ ] Memorials/plaques at real landmarks (flavor text)
- [ ] Seasonal/feast banners (Feast of the Blessed Sacrament)
- [ ] Newspaper headlines that react to player rampages/missions

## 9. Characters & animation
- [x] Rigged human model (GLB) for player + pedestrians
- [ ] Tune model scale/orientation/feet alignment
- [ ] Anim states: idle, walk, run, sprint, enter/exit car, punch, hit-react, knockdown, death, aim, shoot
- [ ] Locomotion blendspace + foot IK on slopes/stairs
- [ ] Ragdoll on death/knockdown
- [ ] Multiple ped models + wardrobe/skin variety; gender mix
- [ ] Named character models (Vinny, allies, antagonists) + portraits
- [ ] Facial animation / lipsync for cutscenes & dialogue
- [~] Player outfit changes; wet/dirty clothing states — character menu outfit-colour picker tints the player model live (CharacterMenu.tsx); wet/dirty states TODO

## 10. Player & controls
- [x] Rapier character controller: walk/sprint, collision
- [x] Enter/exit + drive car (E)
- [x] Melee punch (F) → KO/kill
- [x] 1st/3rd-person toggle (V)
- [~] Jump, crouch, sprint stamina, cover, vault, climb, swim — sprint (Shift) with a draining stamina bar; jump/crouch/cover/vault/climb/swim TODO
- [ ] Mouse-look / pointer-lock aim; gamepad support; remappable controls
- [ ] Interaction system (prompts: enter, talk, pick up, sit, sleep)
- [ ] Inventory + weapon wheel
- [ ] Footstep surface detection (cobble/asphalt/wood/grass/water)

## 11. Combat & weapons
- [x] Melee punch → KO/kill + knockback
- [ ] Melee combo / block / grapple; lock-on
- [~] Gunplay: aiming, hitscan/projectile, reticle, cover-shoot, recoil — pistol hitscan + tracer/muzzle flash + recoil shake + **reticle** (Player + Tracers.tsx + HUD); cover-shoot TODO
- [~] Weapon set: fists, bat, pistol, shotgun, SMG, “heavy” (Quequechan Mill tier) — fists + pistol + **shotgun** (spread); bat/SMG/heavy TODO
- [~] Ammo, reload, pickups, weapon switching — **weapon switching** (1/2/3 + G); ammo/reload/pickups TODO
- [ ] Damage model + health/armor + regen/medkits
- [~] Hit reactions, ragdolls, blood decals (toggleable), impact particles — pooled blood/dust impact bursts on hits (Impacts.tsx); ragdolls/decals TODO
- [~] Enemy combat AI (cops, faction enforcers): chase, shoot, take cover, flank — cop cars chase, ram, and arrest (Police.tsx); shooting/cover/flank + faction enforcers TODO

## 12. Vehicles
- [x] Real car models (Bronco/Mustang/G/Z/RAV4) — player + traffic
- [x] Arcade driving (accel/brake/steer/reverse), enter/exit, collision — faster top speed + speed-scaled steering; ram traffic to halt it; **carjack** traffic on foot (E) with model/colour swap
- [ ] Wheel rotation + steering animation; suspension travel
- [~] Working lights (head/tail/brake/reverse/turn signals) — head/tail emissive ramp at dusk, player taillights flare on braking, **white reverse lights when backing up** (Vehicles.tsx/Car.tsx); turn signals TODO
- [ ] Damage/deformation, smoke when wrecked, explosions
- [ ] Region-accurate spawns (“Townie”, “Linguiça” moped, “Codfish 40”, lowriders, preppy imports)
- [~] Motorcycles/mopeds, boats, bicycles — **pilotable yacht** (Boat.tsx; board at the Long Island marina, drives on water, wake); motorcycles/mopeds/bicycles TODO
- [ ] Garage / car storage / customization (paint, wheels)
- [ ] Car radio audible inside; horn

## 13. Driving feel & vehicle FX
- [~] Tire skid marks (decals) + skid/screech audio — skid-mark decal ring buffer on hard cornering (SkidMarks.tsx); screech audio TODO
- [ ] Tire smoke, dust on dirt, water spray in rain/puddles
- [~] Camera FOV/shake scaling with speed; speed lines — FOV widens + subtle shake with car speed (FollowCamera); speed lines TODO
- [~] Engine audio with RPM/gears; backfire — procedural engine note tracks speed (audio/sfx.ts); gears/backfire TODO
- [~] Collision crunch sfx + sparks; ragdoll peds on impact — ram crunch sfx (sfx.ts); sparks/ragdoll TODO
- [~] Handbrake, drift, boost feel tuning — Space handbrake scrubs speed + loosens steering for a drift (Car.tsx); boost TODO

## 14. NPCs & living city
- [x] Wandering pedestrians (kinematic) + contact/knockback
- [x] Traffic following the real road network (turns at intersections)
- [x] Peds react to melee (KO/kill, lie down)
- [~] Ped AI states: idle/converse/walk/flee/panic/cower; weather reactions (umbrellas) — wander + **flee/panic** from gunfire/violence + oncoming fast cars (StreetLife); converse/cower/weather TODO
- [ ] Ped density + variety by district + time of day; crowds
- [ ] Traffic: lanes, stop at lights, yield, collision avoidance, honking, react to player
- [ ] Faction NPCs + turf spawns (Azorean Syndicate, South End/Crioulo, Cape Set, Provençal)
- [x] Police NPCs + pursuit + backup escalation — cop cars spawn/escalate with police heat and home in (Police.tsx); shootable, arrest on foot
- [ ] NPC daily schedules / spawn zones
- [ ] Performance: instanced/pooled crowds + LOD

## 15. Gameplay systems (canon)
- [x] **MissionManager**: objective/trigger/state/reward engine + markers + waypoints — mission.ts + MissionRunner.tsx (objective beam/ring); waypoint trail TODO
- [x] **Dual-axis Heat/Wanted**: Axis A police (1–5), Axis B faction aggro; decay; busted/wasted states — police+faction 0–5 + decay (game.ts); **busted/wasted** loop with respawn (Consequence.tsx)
- [x] **Safehouses** (Maplecroft) — clear heat + save + sleep/time-skip — safehouse zone bleeds off heat + autosaves; **T sleeps til 07:00** (heal + clear heat + advance day + save) (Safehouse.tsx)
- [x] **PlayerWallet** + currency UI — game.ts cash + addCash; HUD cash readout
- [x] **AcquisitionEngine** (5 businesses) + property ownership/markers — 5 buyable fronts with markers + B-to-buy + persistence (economy.ts, Businesses.tsx)
- [x] **RevenueManager** (daily yields, margin-leak events) — per-day yields trickle into the wallet (GameSystems) + one-off margin-leak/boom events on owned fronts (`rollRevenueEvent`, every 90–210s, toast + sfx)
- [ ] **ChopShopArmsManager** (weapons gated to Quequechan Mill #4 tier)
- [ ] **WeatherController** ↔ vehicle friction
- [ ] **Dialect Engine** (non-rhotic barks; Chip Worthington hard-Rs)
- [ ] **RadioManager** integration with story milestones
- [~] Save/load (IndexedDB/localStorage) + autosave + multiple slots — localStorage save + 20s autosave (GameSystems.tsx); multi-slot TODO
- [x] Time of day clock + day counter; time-skip — HUD clock + **Day N** counter (midnight rollover) + **safehouse sleep** time-skip (shared.day, DayNight, Safehouse, HUD)
- [ ] Respect/reputation + faction standing

## 16. Missions & content
- [~] **“Off the Boat”** opener (arrival → Bethel → fish-pier ambush → fog getaway → safehouse) — 3-step playable version (Bethel → steal car → safehouse); ambush/fog beats TODO
- [~] Mission framework primitives: go-to, follow, deliver, chase, escape, eliminate, protect, steal, tail, timed, stealth — go-to + steal/needCar + **deliver** + **escape (noHeat: lose the cops)** live; follow/eliminate/protect/tail/timed/stealth TODO
- [ ] Cutscene system (scripted camera + dialogue + subtitles)
- [~] Act I (New Bedford): harbor takeover arc — **Auction Rules** (lean on Sully's collectors → cool the car at Reggie's) + **The Linguiça Run** + **Harbor Heat** (break Sully's grip, lose the cops) playable in the chain; Sully boss beat TODO
- [~] Act II (Fall River): “Acquitted” (Borden) + “The Undefeated” (boxing) — **Spindle City** (I-195 over the Braga to Battleship Cove) + **Acquitted** (Borden House → run the ledger, lose the tail) playable; The Undefeated waits on the Brockton pull
- [ ] Act III (Cape + “Gloria” storm) → Battleship Cove finale
- [ ] Branching/optional outcomes; mission replay
- [ ] Dialogue system (NPC conversations, choices where relevant)

## 17. Progression & economy
- [~] Cash earning/spending loops (missions, businesses, side jobs, theft) — mission rewards + business income + buy fronts; side jobs/theft fences TODO
- [~] Property empire with upkeep + income tick — buy 5 fronts, passive income tick (economy.ts); upkeep/leak events TODO
- [ ] Player upgrades/skills (driving, shooting, health, stamina)
- [ ] Shops: weapons, clothing, vehicle mods, food (health)
- [ ] Bank/stash; bribes; fines

## 18. Side activities & minigames
- [ ] Street races (bridge circuits, checkpoints, timers)
- [ ] Boxing circuit (Champion City Gym)
- [ ] Boat smuggling runs (Coast Guard heat)
- [ ] Clam-shack delivery time-trials
- [ ] Vigilante/taxi/“rampage” style diversions
- [~] Collectibles (e.g., hidden whaling artifacts/landmarks photo-ops) — 8 hidden scrimshaw collectibles with bounty + persistence (Collectibles.tsx); photo-ops TODO
- [ ] Lizzie Borden ghost-tour caper

## 19. Audio & music
- [x] Radio: 4 stations (WHALE, The Rage, The Anvil, Maré Alta) — TTS hosts, music, switching/mute
- [x] Radio depth: longer scripts, ad reads, weather/news, hosts react to milestones — 50+ lines/host + ad/ident/news rotation + **wanted/weather reactions** + **milestone reactions** via `radio.flashNews()` (evade-chase, buy-a-front)
- [ ] More stations + larger procedural/licensed-free music sets
- [~] VO pipeline for NPC/mission dialogue (TTS now, recorded later) — ElevenLabs server proxy (api/tts.ts) + vo.ts client wired to radio hosts, Web-Speech fallback; NPC/mission dialogue hookup TODO
- [ ] Mission/score adaptive music layers (calm/tension/chase)

## 20. Audio aesthetics & ambience
- [~] Per-district ambient beds (harbor gulls/waves, mill hum, downtown traffic, Cape calm) — harbor wind + gull-cry bed (sfx.ts); per-district variation TODO
- [ ] Time-of-day ambience (dawn birds, night crickets/quiet)
- [ ] Weather audio (rain, wind, thunder, foghorn)
- [x] SFX: footsteps by surface, doors, punches/impacts, gunfire, glass, car crunch, horns — punches, gunfire, car crunch, horn via procedural Web Audio (sfx.ts); footsteps/doors/glass TODO
- [ ] 3D spatialization + reverb zones (alleys, interiors, under bridges) + occlusion
- [ ] Doppler on passing vehicles; distance attenuation
- [~] UI sfx (menu, mission start/complete, cash, wanted-up) — mission-advance/cash + bust stings (sfx.ts); menu/wanted-up TODO

## 21. UI / UX
- [x] Basic HUD (title, controls, mode)
- [~] Minimap/radar (rotation, streets, property icons, hostile blips, lighthouse sweep, objective) — player-centered radar (Minimap.tsx: roads, water, parks, objective, heading, cop blips, police/hospital markers, **business-front icons** (owned filled / buyable hollow), waypoint); rotation TODO
- [~] Health/armor, stamina, wanted badges (police + faction), wallet, ammo, weapon — health + stamina bars + police/faction badges + wallet + clock + weapon (HUD.tsx); armor/ammo TODO
- [~] Objective markers + waypoints + on-screen distance — world beam/ring marker + map blip + **on-screen metres** to objective (HUD); off-screen waypoint arrow TODO
- [~] Interaction prompts + context hints — contextual prompts (E steal/enter, B buy) + control crib (HUD); richer context hints TODO
- [~] Big map screen (set waypoint, fast-travel, legend) — full-screen pannable/zoomable map with real street-name labels, water, player heading + objective (BigMap.tsx, M to open); waypoint/fast-travel TODO
- [ ] Subtitles + dialogue UI + phone/contacts
- [x] Notifications (mission, cash, busted/wasted), damage vignette + directional hit indicators — toast notifications (Toasts.tsx) + damage vignette; directional hit indicators TODO

## 22. UI aesthetics & menus
- [~] **Present-day Coastal Noir UI** theme — consistent courier/neon palette
  across HUD, menus, title, toasts; full responsive/accessibility kit remains
  open
- [~] Main menu (New/Continue/Load/Settings/Extras) with art + ambient scene — title/start screen over the live world with tips (StartMenu.tsx); New/Continue/Load split TODO
- [~] Pause menu, mission screen, stats/progress screen — pause/**settings** overlay (resume, view, weather, effects, **shadows**, volume, reset) + **Stats overlay** (day/health/cash/wanted/fronts/scrimshaw/mission) + **Credits**; dedicated mission screen TODO
- [~] Loading screens with art + tips/lore — title screen doubles as a loading screen with rotating tips (StartMenu.tsx); art TODO
- [ ] Map/HUD icon set; mission-text styling; credits
- [ ] Photo-mode UI (filters, frames, stickers)

## 23. Game feel / juice
- [~] Camera shake (impacts, explosions, engine, gunfire) — melee + speed shake (shared.shake/addShake, FollowCamera); explosions/gunfire TODO
- [ ] Hit-stop / time-dilation on big hits; slow-mo finishers (optional)
- [ ] Impact particles (sparks, dust, debris, blood toggle), screen-space hit FX
- [ ] Controller rumble / gamepad haptics
- [x] Damage/low-health screen FX (desaturate, pulse, blur) — red inset damage vignette scaling with low health (HUD.tsx)
- [ ] Pickup/cash pop FX + sound; wanted-up sting
- [ ] Foot dust, splash, footstep decals

## 24. Camera
- [x] Third-person chase + first-person toggle
- [ ] Collision-aware camera (no clipping through walls); auto-occlusion fade
- [ ] Aim/over-the-shoulder camera; lock-on framing
- [ ] Cinematic/cutscene camera rig; mission intro fly-bys
- [ ] Photo mode free-cam (already exists on earth page — port + expand)
- [~] Smoothing, FOV options, motion-sickness comfort settings — **FOV slider (45–85°)** in pause settings, persisted, feeds the chase/eye camera base FOV (FollowCamera); per-axis comfort options TODO

## 25. Accessibility
- [ ] Subtitles + size/background options
- [~] Full control remap; gamepad + KB/M; **touch** — on-screen thumb-stick + a **full action-button set** (enter, fire, hit, gun, **handbrake + sprint held**, horn, map, menu, buy, outfit, photo, sleep, weather, weapon 1–4), each **draggable + resizable + show/hide toggle**, layout persisted (TouchControls.tsx, input.setVirtualHold); KB/M remap TODO
- [ ] Colorblind modes; UI scale; high-contrast
- [ ] Aim assist; difficulty options; hold-vs-toggle
- [ ] Reduce-motion / camera-shake toggle; flashing-lights warning

## 26. Save / settings / onboarding
- [ ] Save/load UI + autosave + slots + cloud-ready format
- [~] Settings: graphics presets + toggles (shadows, post FX, draw distance), audio mix, controls — **Shadows on/off** + Effects on/off + volume + weather + camera-shake toggles, persisted (PauseMenu/GameSystems); draw-distance/quality presets + control remap TODO
- [ ] First-time tutorial / control onboarding (the opener doubles as this)
- [ ] Resume/“continue” flow; new-game-plus (stretch)

## 27. Tooling (“devkit”) & pipeline
- [x] OSM → game asset pipeline (data scripts)
- [x] GLTF asset import (characters); procedural world-gen
- [ ] In-browser world/mission editor: place markers, define triggers/objectives, free-cam, entity inspector, save to JSON
- [ ] Debug overlays (colliders, AI states, nav, FPS/stats, spawn tools, teleport)
- [ ] Hot-reload content data (missions/props from JSON)
- [ ] Documented art/VO drop-in pipeline (commissioned models + recorded VO slots)
- [ ] Asset budget/validation tooling (poly/texture/memory)

## 28. Districts / content expansion
- [x] New Bedford waterfront (primary)
- [~] New Bedford full (downtown, South End, North End) — slice now spans **New Bedford · Fairhaven · Dartmouth** (16,252 buildings / 3,868 roads), real City Hall/PD/libraries, elevated Acushnet bridges; South/North End + St. Luke's + Padanaram/UMassD (multi-slice) TODO
- [~] Fall River (Spindle City): Flint, Lizzie Borden, Battleship Cove, Braga Bridge, mills — geography + roads + **drivable Braga Bridge** streamed in (region now 68k buildings / 954 tiles); Battleship Cove/Lizzie Borden hero detail TODO
  - [x] **Westport** + I-195/Route 6 corridor (New Bedford → Westport → Fall River)
  - [x] Fairhaven down **Sconticut Neck → West Island**; **Off the Hook** marina purchasable + boat dock
  - on the way west, make the **Dartmouth Mall** a central hub location (shops/missions/parking) — TODO
- [ ] Brockton (Champion City Gym, boxing)
- [ ] Cape Cod (marinas, Fake Kennedys)
- [ ] Connecting roads/highways between districts; fast-travel
- [ ] “Gloria” hurricane set-piece (flood, map alteration, sunk boats)

## 29. Performance & optimization
- [~] Instanced rendering (buildings, props, crowds, traffic) — props/parked cars/trees/skids/impacts instanced; far buildings merged per chunk
- [~] LOD + frustum/occlusion culling; impostors for far buildings — far buildings chunked per 160 m cell + frustum + 1050 m distance cull (Buildings.tsx); LOD/impostors TODO
- [ ] Object pooling (peds, cars, particles, decals)
- [ ] Texture atlasing + compression; geometry merging
- [ ] Frame budget profiling; fixed-timestep physics; web worker offload where possible
- [ ] Quality presets + dynamic resolution; mobile/low-end fallback
- [ ] Bundle split + lazy loading; asset streaming by district

## 30. QA / testing / release
- [ ] Smoke-test checklist per build (load, walk, drive, combat, radio, save)
- [ ] Automated typecheck/build gate
- [ ] Cross-browser + perf testing; input device testing
- [ ] Bug tracker / known-issues list
- [ ] Release notes + in-game version stamp
- [x] Legal/attribution page (OSM ODbL, model licenses, parody disclaimer) — Credits overlay in the pause menu (OSM ODbL, CesiumMan CC-BY, engine/audio credits, parody disclaimer) (PauseMenu.tsx)

## 31. Parked / external
- [~] Photoreal Google 3D Tiles build (`earth.html`) — full play world built; **blocked on billed Google key**; revisit if resolved
- [ ] *(external)* Native/console wrap — Sony/Microsoft dev program + devkits (business/legal, not buildable here)
- [ ] *(stretch)* Desktop wrap (Tauri/Electron) for an installable PC build of the web game
- [ ] *(stretch)* Multiplayer / co-op

---

# Part II — World Detail Atlas (intricate, per-city)

Granular mapping + aesthetic tasks. Each top-level checkbox is a trackable unit;
the nested bullets are the intricate spec for that unit. Grounded in the real
South Coast (real roads, real architecture). All achievable in the web engine via
modular kits + procedural placement driven by OSM data.

## 32. Roads & paving (surface system, all cities)
- [~] **Road-class material set** — distinct look per OSM class — Roads.tsx 3 classes (highway/surface/cobble); per-class wear sub-bullets TODO
  - motorway/trunk: smooth dark highway asphalt + rumble strips, wide lanes
  - primary/secondary: city asphalt, patched, oil-stained centerlines
  - residential: narrower, cracked, frost-heaved, tar crack-seal “snakes”
  - service/alley: broken asphalt, gravel patches, weeds in seams
- [~] **Historic cobblestone & brick** — Johnny Cake Hill / NB historic district — makeCobbleTexture() running-bond granite setts on footway/path/steps
  - rounded granite setts, uneven height, moss in joints, wet-shine, cart-rut wear
  - brick-paved crosswalks & plazas; herringbone vs running-bond patterns
- [~] **Lane & road markings** — double-yellow, dashed white, turn arrows, stop bars, “ONLY”, crosswalk zebra/ladder, faded/repainted, plow-scraped — center/edge lines baked into highway asphalt texture; arrows/stop-bars/crosswalks TODO
- [ ] **Curbs & edges** — granite curbstones (NB/FR signature), curb cuts, ADA ramps, rolled curbs in suburbs, painted (yellow no-park / blue handicap)
- [ ] **Drainage & utilities in-road** — catch-basin grates, manhole covers (city seal), water/gas valve caps, sewer steam, gutter flow in rain
- [ ] **Wear & grime decals** — potholes (patched/open), tar seams, oil drips at stop lines, skid marks, manhole settling rings, salt-stain whitening
- [ ] **Embedded rail/trolley tracks** — old streetcar rails flush in pavement near downtown/mills
- [ ] **Parking** — parallel-park lane markings, metered spots, lots (striped, light poles, painted arrows), gravel/dirt back lots
- [ ] **Road geometry polish** — crown/camber, banking on ramps, expansion joints on bridges, smooth spline tangents at corners (no hard kinks)

## 33. Intersections, signage & street systems
- [~] **Traffic control** — period (1980s) signal heads on mast arms + pedestal, walk/don’t-walk, blinking-yellow at night, stop/yield signs, all-way stops — cycling signal heads near the core (TrafficLights.tsx); walk signals/stop signs/blinking-night TODO
- [ ] **Rotaries/traffic circles** — President Ave rotary (FR) and others, yield geometry, central island landscaping
- [~] **Signage kit** — green street-name signs, one-way, no-parking, speed limit, school zone, route shields (**I-195, US-6, MA-18, MA-24, MA-79, MA-138**), overhead guide signs on highways — 3D green street-name blades on poles at named-road endpoints (StreetSigns.tsx, real OSM names); regulatory/route shields TODO
- [ ] **Street lighting** — cobra-head sodium (amber) on arterials; historic acorn/harbor lamps in the cobblestone district; auto-on at dusk; pools of warm light
- [ ] **Roadside furniture** — utility poles with sagging wires + transformers + pole-mounted signs, fire hydrants, USPS blue mailboxes, newspaper boxes, bus shelters, phone booths, parking meters, benches, bike racks
- [ ] **Wires & overhead** — power/phone line spans pole-to-pole, service drops to houses, traffic-signal span wires, slight catenary sag + wind sway

## 34. Buildings & façade system (modular kit, shared)
- [ ] **Footprint → mass → roof** — extrude OSM footprints with real heights; roof types: flat+parapet, gable, hip, mansard, sawtooth (mills), with chimneys/vents/AC units/water tanks
- [~] **Façade module library** — tileable bays with: double-hung windows, storefront plate glass, arched/round-top windows, bay windows, doors/transoms, cornices, lintels, sills, string courses, quoins — procedural per-floor window grid (day glass + night-lit emissive) with UV mapping + colour by use/height (StreamingBuildings + makeFacadeMaps); storefronts/cornices/variety TODO
- [ ] **Material set (PBR)** — red brick (multiple bonds), Fall River **granite block**, clapboard, wood shingle, stucco, cast stone, painted brick, glazed terra-cotta trim
- [ ] **Detail props** — fire escapes (tenement signature), downspouts/gutters, awnings, window AC units, satellite-less era TV antennas, rooftop billboards, ghost-sign painted ads, parapets, cornice brackets
- [ ] **Weathering pass** — soot near rooflines, rust streaks under metal, salt bloom near harbor, peeling paint, water stains, boarded windows in dead zones
- [ ] **Glass & interiors fake-out** — parallax/interior-cubemap windows + lit rooms at night (randomized warm/cool, some dark)
- [ ] **Procedural façade assignment** — pick kit + materials by district + building size + era so streets read coherent, not repetitive

## 35. Residential typologies (New England)
- [ ] **Triple-decker** (the iconic FR/NB three-family) — stacked porches, flat/low roof, clapboard, side stair, small yard, driveway
- [ ] **Sea-captain & mill-owner mansions** — Greek Revival / Federal / Italianate on County St (NB) and the Highlands (FR); columns, widow’s walks, iron fences
- [ ] **Victorian / Queen Anne** — turrets, gingerbread trim, polychrome paint, wrap porches
- [ ] **Worker row houses & duplexes** — tight mill-adjacent rows, shared walls
- [ ] **Cape Cod cottages & shingle-style** — gray weathered shingles, gambrel/saltbox roofs, dormers, hydrangeas, crushed-shell driveways (Cape district)
- [ ] **Postwar ranches & capes** — suburban Brockton/outer districts
- [ ] **Yard kit** — picket/chain-link fences, stoops, clotheslines, lawns, hedges, mailboxes, detached garages, above-ground pools, lawn ornaments

## 36. Commercial, storefronts & signage
- [ ] **Mixed-use main streets** — ground-floor retail under apartments (Acushnet Ave NB, South Main/Columbia FR)
- [ ] **Storefront kit** — recessed entries, plate-glass display windows, bulkhead bases, transoms, roll-down security gates, awnings
- [ ] **Signage** — neon, hand-painted, plastic backlit box signs, projecting blade signs, barber poles, era-correct logos (fictional)
- [ ] **Business types (flavor)** — Portuguese bakery (malasadas), package store, pharmacy, luncheonette/diner, fish market, hardware, laundromat, pawn shop, tavern/bar (neon), corner store, record shop, movie marquee, gas station (period pumps + price signs)
- [ ] **Interiors (hero shops)** — bar, bakery, gym, gun-running mill front, safehouse — enterable, dressed
- [ ] **Window dressing** — products, “OPEN/CLOSED” signs, flyers/posters, day-night open/close states

## 37. Civic, religious & industrial
- [ ] **Fall River granite mills** — multi-story granite blocks, tall mill windows, sawtooth/monitor roofs, brick smokestacks, water/stair towers, loading docks, mill yards + the Quequechan canal/river running through
- [ ] **Churches** — St. Anne’s basilica (twin spires, granite + marble), Seamen’s Bethel, ornate Catholic parishes; stained glass; bell towers
- [ ] **Civic buildings** — city hall, library, courthouse, post office, fire/police stations, schools (brick + columns)
- [ ] **Industrial waterfront** — fish-processing plants, ice houses, cold storage, fuel depots, rail spur + freight yard, water towers
- [ ] **Parks & green** — Buttonwood Park (NB), Kennedy Park (FR), Cape beaches/dunes; trees, paths, ballfields, bandstands, monuments

## 38. Ocean, harbor & working waterfront (per body of water)
- [ ] **New Bedford Harbor / Acushnet River** — the Hurricane Barrier (massive stone + gate), State Pier, fish piers with draggers/scallopers moored, fuel & ice docks, co-op
- [ ] **Palmer’s Island Lighthouse** — modeled + rotating beam
- [ ] **Mount Hope Bay (Fall River)** — Battleship Cove (USS Massachusetts, PT boats, submarine Lionfish), waterfront under the Braga Bridge
- [ ] **Cape Cod waters** — beaches, dunes, marinas, moored yachts, the Canal
- [ ] **Water shading** — Gerstner waves, foam at shore/pilings, fresnel + depth color, oily sheen near docks, reflections, wakes behind boats
- [ ] **Waterfront props** — pilings, bollards, cleats, lobster traps stacked, nets drying, buoys, dinghies, gulls on every piling, breakwaters/jetties, seaweed at tide line
- [ ] **Boats (ambient + usable)** — fishing draggers, ferries (Cuttyhunk/Vineyard), pleasure boats, Coast Guard; bobbing animation; usable boat for smuggling
- [ ] **Tide & flood** — tide line shading; “Gloria” storm-surge flood that raises water over low roads/docks

## 39. Inter-city highway network (major upgrade)
- [~] **I-195** — the east-west spine linking **New Bedford ↔ Fall River**: 4-lane divided, median jersey barrier, guardrails, breakdown lanes, overhead green guide signs, mile markers, sodium lighting, embankments — real I-195 + Route 18/US-6 geometry rendered as highway ribbons + drivable bridges across the region; barriers/guide-signs/ramps detailing TODO
- [ ] **Interchanges & ramps** — on/off ramps, cloverleaf/diamond interchanges, gore points, merge/accel lanes, ramp meters-off (era), exit numbering
- [ ] **MA-24** — Fall River ↔ **Brockton** (north); **US-6** coastal route; **MA-18** NB waterfront connector to I-195; **MA-79/138** spurs
- [ ] **Cape connection** — US-6 to the **Sagamore/Bourne bridges** over the Cape Cod Canal
- [ ] **Highway dressing** — sound barriers, cut-slope/embankment terrain, drainage culverts, overpasses with shadow, reflective signage, rumble strips, lane reflectors, breakdown shoulders, brush/treelines
- [ ] **Traffic on highways** — faster lane-following AI, merging, trucks, exits; police highway pursuit
- [ ] **Seamless streaming** — load/unload districts as you drive the highway between cities (no loading screens)

## 40. Bridges (hero infrastructure)
- [~] **Braga Bridge (“Verde Bridge”, Fall River)** — the long green steel cantilever over the Taunton River; deck, towers, truss detail, lime-green paint, night lighting + fog glow; drivable, with Battleship Cove beneath — **drivable** via the generic ramped-deck system (carries I-195 over the Taunton); green steel truss/full height + lighting TODO
- [~] **New Bedford–Fairhaven Bridge** — swing-span over the Acushnet, low steel deck — **drivable ramped deck + piers** (Bridges.tsx, generic for all spans); swing-span animation + steel truss detail TODO
- [ ] **Brightman St / old bascule bridges** — period detail
- [ ] **Sagamore & Bourne Bridges** — Cape Cod Canal steel arches
- [ ] **Rail & canal bridges** — smaller crossings tying districts
- [ ] **Bridge tech** — expansion joints (bump/rumble), pylons in water w/ reflections, under-bridge ambient shadow + reverb, navigation lights, suicide-fence/railings

## 41. Per-city aesthetic packs
- [ ] **New Bedford — “Whaling City”**
  - cobblestone historic district + Seamen’s Bethel/Whaling Museum/Custom House; working fish harbor; Acushnet Ave commercial; South End (Cape Verdean/Portuguese) triple-deckers + murals; County St mansions; the Hurricane Barrier; gritty maritime palette (greys, weathered wood, rust, harbor blue)
- [ ] **Fall River — “Spindle City”**
  - granite textile mills + smokestacks dominating the skyline; the Flint + the Highlands; the Quequechan; Columbia St Portuguese district; Battleship Cove + the green Braga Bridge; Lizzie Borden house (Second St) + Maplecroft (French St); steep hills; granite-grey + brick-red palette
- [ ] **Brockton — “City of Champions”**
  - brick downtown, boxing gyms (Champion City Gym), Campanello-era homes, working-class grid; warmer brick palette
- [ ] **Cape Cod**
  - weathered-shingle cottages, marinas + yachts, dunes/beaches/lighthouses, US-6, preppy yacht-club money; bright sand/sea-glass palette; summer-crowd density
- [ ] **District transitions** — palette/material/density blends so each city reads distinct from the road

## 42. Other major upgrades & systems
- [ ] **OSM footprint → typology classifier** — auto-tag each building (triple-decker / mill / storefront / mansion / civic) to assign the right kit + materials
- [ ] **Procedural city generator** — scale detailing to full districts from data (no hand placement per building)
- [ ] **Per-city satellite ground** — signed Static Maps draped + aligned for each district (extend the proxy)
- [ ] **Full road-network graph + navmesh** — drives traffic routing, ped sidewalks, GPS/route line, AI pursuit
- [ ] **Streaming & LOD at multi-city scale** — district chunks, impostors, instanced props/crowds, memory budget
- [ ] **Season + time-of-day dressing** — snow banks (winter), leaves (fall), summer crowds (Cape), holiday/feast banners
- [ ] **Interiors streaming** — enterable hero interiors load/unload seamlessly
- [ ] **Living economy** — shops open/close by time; ferries run on schedule; rush-hour traffic density
- [ ] **Destructible/dynamic props** — bins, signs, fences, fruit stands, fire hydrants (spray), light poles
- [ ] **GPS / waypoint route line** on roads to objectives (mini-map + world)

---

# Part III — System Detail Atlases (exhaustive)

Each game system gets its own deep atlas. Real-world 1980s references are listed
for accuracy; **ship fictionalized analogs** (Vice-City style) to avoid trademark.
Per-asset build spec lives under each entry. VO is produced via **ElevenLabs**
(see §G), keyed through a server proxy so the API key never ships in the client.

## A. Vehicle Atlas — the 1980s market (fictionalize on ship)
Per vehicle: low-poly model + LODs, color/livery + dirt/rust variants, damage
deform, working lights, optional interior, handling profile (mass/grip/accel/top
speed/braking), engine+horn audio, spawn rules (district/era/wealth).

- [ ] **American full-size sedans/coupes** — Caprice/Impala, LTD Crown Victoria, Delta 88, Bonneville, Town Car, Fleetwood/DeVille, Diplomat/Gran Fury (cop), Grand Marquis
- [ ] **American mid-size & compact** — Citation, Fairmont, Reliant/Aries (K-car), Cavalier, Tempo/Topaz, Celebrity, Century, Cutlass Ciera, Corsica, Taurus (’86)
- [ ] **Muscle / pony / performance** — Camaro (Z28/IROC), Firebird/Trans Am, Mustang 5.0 (Fox), Corvette C4, Monte Carlo SS, Buick Grand National/GNX, Mustang SVO, Dodge Daytona, Charger 2.2
- [ ] **Personal-luxury coupes** — Eldorado, Riviera, Toronado, Thunderbird, Cordoba, Mark VI/VII, Monte Carlo, Cutlass Supreme
- [ ] **Station wagons** — Country Squire (woody), Caprice/Custom Cruiser wagon, Colony Park, Vista Cruiser, K-wagon
- [ ] **Pickups** — F-150/F-250, C/K (Silverado), D-series/Ram, Ranger, S-10, Toyota Hilux/pickup, Datsun/Nissan 720
- [ ] **SUVs / 4x4** — Bronco (full + Bronco II), Blazer K5/S-10, Jeep CJ-7 / Wrangler YJ, Cherokee XJ, Wagoneer, Suburban, Scout II, Toyota Land Cruiser/4Runner
- [ ] **Vans & minivans** — Econoline, G-van (boogie van w/ murals), Caravan/Voyager (’84 minivan), Astro, VW Vanagon, Toyota Van
- [ ] **Japanese imports** — Civic/CRX, Accord, Corolla (AE86), Celica, Supra, Datsun/Nissan 280ZX→300ZX, Sentra, Maxima, Camry, Cressida, Mazda RX-7, 626, Mitsubishi Starion/Conquest, MR2, Subaru GL/Brat, Isuzu Impulse
- [ ] **German** — VW Rabbit/Golf GTI, Jetta, Scirocco, BMW E30 3-series, E28 5-series, Mercedes W123/W124, 190E, S-class W126, Audi 4000/5000, Porsche 911/944/928/924
- [ ] **Other European** — Saab 900 (Turbo), Volvo 240/740, Peugeot 505, Fiat/Alfa Spider, Renault Alliance, **Yugo GV**, Lancia, Lotus Esprit
- [ ] **Economy / subcompact** — Chevette, Escort/EXP, Festiva, Sprint/Metro, Horizon/Omni, Pinto holdovers, Gremlin/Pacer holdovers
- [ ] **Exotics & sports** — Ferrari Testarossa/308/328, Lamborghini Countach, DeLorean DMC-12, Porsche 959, Lotus, De Tomaso, TVR
- [ ] **Luxury / executive** — Rolls-Royce/Bentley, Mercedes S, Jaguar XJ/XJS, Cadillac limo, stretch limo
- [ ] **Commercial & service** — yellow taxi (Checker/Caprice), marked police cruiser + unmarked, fire engine + ladder truck, ambulance, garbage truck, box/delivery truck, semi tractor-trailer, tow truck, dump truck, cement mixer, school bus, transit bus, USPS mail jeep/LLV, ice-cream truck, food truck, news van, utility/bucket truck, hearse, parade float
- [ ] **Motorcycles & mopeds** — Harley (cruiser/chopper/police), Honda CB/Nighthawk/Gold Wing, cafe racer, dirt bike, scooter/Vespa, **moped (the “Linguiça”)**
- [ ] **Boats & marine** — fishing dragger/scalloper, lobster boat, ferry (Cuttyhunk/Vineyard), speedboat/cigarette boat, sailboat/yacht, dinghy/skiff, Coast Guard cutter/RIB, tugboat, **“Codfish 40” cruiser**
- [ ] **Misc/utility** — bicycle (BMX/road/beach cruiser), forklift, golf cart, riding mower, go-kart, airport tug, harbor crane
- [ ] **Canon flavor mapping** — “Townie” rusted beater (K-car/Caprice analog) heavy in Fall River; “Linguiça” moped; “Codfish 40” cruiser; preppy imports + yachts on the Cape; lowriders for the South End/Crioulo crews
- [ ] **Systems** — vehicle data table (stats/spawn), paint/livery system, dirt/rust/damage materials, license plates (MA), wreck/burn states, ambient parked-car variety, rarity/wealth tiers per district

## B. Character Atlas
Per character: model (GLB/MetaHuman-grade), rig + anim set, face + lipsync,
portrait, **ElevenLabs voice profile**, wardrobe, role/missions.
- [ ] **Vinny Tavares (protagonist)** — full sheet: look, wardrobe options, voice, ability/anim set, arc beats
- [ ] **Allies** — Auntie Conceição, Deacon Mealy, Reggie “Two-Stroke” Pina, Marisol Cabral, Iron Mike Fontaine (each: bio, model, VO, mission role)
- [ ] **Antagonists** — Sully Brangwynne, Chip Worthington III, Lady Borden, the Fake Kennedys (each: bio, model, VO, boss role)
- [ ] **Radio personalities** — Buddy Mello, Iron Mike, DJ Sully, Tia Conceição (voices + on-air persona)
- [ ] **Faction rosters** — Azorean Syndicate, Crioulo/South End Crew, Cape Set, Provençal, the Brass (police): boss → lieutenants → enforcers → grunts, with colors/wardrobe/vehicles/turf
- [ ] **Named minor NPCs** — vendors, fixers, fence, mechanic, bartender, priest, gym corner-man, ferry captain, mission-givers
- [ ] **Generic NPC archetypes** — dockworker, fisherman, millhand, factory worker, preppy/yachtie, cop, priest/nun, businessman, retiree, teen, jogger, drunk, tourist, panhandler, kid — each w/ model set + wardrobe + voice bank
- [ ] **Production** — character data table, casting/voice map, portrait set, relationship/standing data

## C. Pedestrian Behavior Atlas (elevated AI)
- [ ] **Core states** — idle, stroll, commute, sit, lean/smoke, window-shop, jog, wait (crosswalk/bus), converse, eat
- [ ] **Threat reactions** — flee, panic-run, cower, hands-up, rubberneck/film, fight back, call cops, hide indoors
- [ ] **World reactions** — to weather (umbrellas, run for cover, hunch in cold), to vehicles (dodge, jump back, yell, slap hood), to gunfire/explosions (scatter), to fire/water
- [ ] **Social behaviors** — groups walking, conversations (turn-take + gestures), queues, crowds at events (Feast, boxing, ferry), street performers, arguments
- [ ] **Daily schedules** — per archetype + time-of-day (home→work→lunch→home→nightlife); shops/bars populate accordingly
- [ ] **Navigation** — sidewalk navmesh, crosswalks, jaywalking, doorway enter/exit, stairs, avoid obstacles + each other, personal space
- [ ] **Dialogue/barks** — dialect engine + **ElevenLabs** archetype voice banks; greetings, insults, reactions, ambient chatter; subtitles
- [ ] **Reputation reactions** — defer/fear/respect by player standing + turf; faction members hostile on their turf
- [ ] **Density & perf** — per-district/time spawn density, crowd pooling, behavior LOD (simplify off-screen)

## D. Interiors Atlas
Shared modular interior kit (walls/floors/ceilings/doors/stairs/windows/lighting),
era-1980s prop library, ambient audio + interactables; hero interiors fully
dressed, ambient ones use window fake-out.
- [ ] **Residential** — triple-decker apartment (kitchen, living, 2 bed, bath, hall, back porch), sea-captain mansion (foyer, parlor, study, grand stair, bedrooms), Cape cottage, worker flat, tenement hallway
- [ ] **Safehouses** — starter flat, **Maplecroft B&B** (period-creepy), upgraded apartments, mansion endgame — each w/ bed (save), wardrobe (change), stash
- [ ] **Bars/nightlife** — tavern (neon, pool table, jukebox), dive bar, social club (Portuguese/Azorean), gambling back-room
- [ ] **Food** — Portuguese bakery (cases of malasadas), diner/luncheonette (counter+booths), clam shack, coffee shop
- [ ] **Shops** — package/liquor store, pharmacy, pawn shop, hardware, record shop, barbershop, gun-running mill front, gas-station mart, corner store
- [ ] **Civic/religious** — Seamen’s Bethel (ship-prow pulpit), church nave, city hall, police station (cells), library, courthouse
- [ ] **Industrial** — granite mill floor (looms / chop-shop bay), warehouse, fish-processing, ice house, boat cabin/wheelhouse
- [ ] **Sports/training** — Champion City Gym (ring, bags, lockers)
- [ ] **Systems** — interior streaming (load on enter), occlusion, exterior/interior door transitions, interior lighting + ambience, NPC population, lootables/interactables

## E. Weapons Atlas (1980s-appropriate, fictionalized)
Per weapon: model, damage/range/fire-rate/recoil/mag, ammo type, reload + holster
anim, sound (foley/ElevenLabs), pickup, tier (Quequechan Mill upgrade), legality
(heat on draw/fire).
- [ ] **Fists & improvised** — fists, brass knuckles, baseball bat, crowbar, pipe, tire iron, chain, broken bottle, hammer, **gaff/fishing knife/oar** (maritime), nightstick/baton
- [ ] **Knives/blades** — switchblade, hunting knife, machete, cleaver
- [ ] **Pistols** — .38/.357 revolver, 9mm auto (Beretta-92 analog), .45 (1911 analog), compact/snub, Glock-17 analog (new ’82), Desert Eagle analog
- [ ] **Shotguns** — pump, sawn-off, double-barrel, semi-auto
- [ ] **SMGs** — Uzi analog, MAC-10/11 analog, MP5 analog, grease gun
- [ ] **Rifles** — bolt hunting rifle, lever-action, AK analog, M16/AR analog, M1 carbine, sniper (scoped)
- [ ] **Heavy (mill-tier)** — RPG/LAW analog, light MG, flamethrower, mounted gun
- [ ] **Thrown/placed** — molotov, frag grenade, pipe bomb, dynamite, throwing knife, brick
- [ ] **Special / regional** — harpoon/whaling gun, speargun, flare gun (signal), nail gun, taser-prototype
- [ ] **Systems** — weapon wheel/inventory, ammo types + pickups, holstering, dual-wield (stretch), durability for melee, weapon shops + the mill chop-shop tier gate, cops react to brandishing

## F. Clothing & Wardrobe Atlas
Player slots: head, face/eyes, torso-inner, torso-outer, hands, legs, feet,
accessories. Per item: model fit to rig, materials, color variants, wet/dirty/
blood states, price, vendor, unlock.
- [ ] **Tops** — t-shirt, polo, flannel, bowling shirt, Hawaiian shirt, fisherman’s/cable-knit sweater, hoodie, tank, dress shirt
- [ ] **Outerwear** — leather jacket (biker), denim jacket, Members-Only jacket, windbreaker/track jacket, bomber, peacoat, oilskin/raincoat (slicker), suit jacket/blazer, varsity jacket
- [ ] **Bottoms** — jeans (straight/acid-wash), chinos, track pants, work pants, shorts, suit trousers, coveralls
- [ ] **Footwear** — high-top sneakers, running shoes, work boots, cowboy boots, loafers, deck/boat shoes, dress shoes
- [ ] **Headwear** — ballcap, trucker cap, knit watch cap, fedora, bandana, headband, do-rag
- [ ] **Eyewear/accessories** — aviators, Wayfarers, gold chains, watch, gloves, belt, suspenders, fanny pack, backpack
- [ ] **Role/faction outfits** — Azorean Syndicate sharp suit, South End/lowrider streetwear, Cape preppy (sweater-over-shoulders, boat shoes), dockworker/oilskins, millhand coveralls, cop uniform, priest cassock, boxer trunks+robe, tracksuit
- [ ] **Systems** — clothing shops, change at safehouse, full outfit presets, dirt/wet/blood overlay states, story-locked outfits, disguise (lower heat/faction recognition)

## G. Radio & VO Atlas (ElevenLabs pipeline)
- [ ] **VO production pipeline** — ElevenLabs voice per host/character → generated audio assets → packaged/streamed; **server proxy for the ElevenLabs key** (mirror the maps-signing proxy); Web-Speech fallback for dev; subtitle/caption data alongside each line
- [ ] **The Rage (1480 AM, talk)** — Buddy Mello: rant scripts (bridge traffic, potholes, the Pats, civic gripes), caller segments, station IDs, milestone-reactive lines (player rampage callouts)
- [ ] **The Anvil (WBOX, sports)** — Iron Mike Fontaine: boxing gospel, City-of-Champions hype, fight recaps, training rants
- [ ] **WHALE 92.1 (classic rock)** — DJ Sully: patter, dedications, triple-shots, weekend-format bits
- [ ] **Maré Alta 105.3 (Portuguese/Cape Verdean oldies)** — Tia Conceição: warm host bits (PT/Kriolu phrases), feast-season shout-outs
- [ ] **New stations** — Cape yacht-rock/AOR (preppy), punk/hardcore (youth), AM news/talk, Cape Verdean kriolu, country, oldies/doo-wop
- [ ] **Shared content** — fictional **commercials** for South Coast businesses, PSAs, **traffic/weather/news** that reference real geography + react to player/story milestones, station jingles/IDs, time-of-day shows
- [ ] **Music** — royalty-free/procedural now → curated license-free later; per-station playlists, crossfade, in-car vs walking ambience, volume ducking under talk
- [ ] **Mission/cinematic VO** — character dialogue, mission briefings, in-game phone calls, cutscene lines — all via ElevenLabs voice map; lipsync hookup

---

## Running log

### 2026-06-21
- Pulled OSM data (New Bedford + Fall River); produced GeoJSON/PMTiles/OBJ + MapLibre viewer; baked the web slice blockout (1071 buildings, 808 roads, harbor).
- Reconciled engines → **R3F canonical**; Unity (PR #18) + Godot legacy; ported StreetLife + car tuning.
- Locked **real names + original characters**; chose **New Bedford waterfront** opener.
- Built the web vertical slice: third-person walk + drivable car + Rapier collision on the real grid; deployed to Vercel via git integration.
- Named the game **Mount Hope**; modeled **Seamen’s Bethel**; spawn in front of it.
- Stylized-realism pass: harbor ocean, daytime sky, textured ground/roads, highways; expanded slice.
- Added **radio** (4 stations, TTS hosts, procedural music, switching/mute).
- Wrote **Characters & Missions bible** and the **Gemini build spec** (AAA console+PC framing, all canon).
- Photoreal **Google 3D Tiles** build (`earth.html`) with full play world + signing proxy — **blocked by Google billing/quota**; parked.
- Pivoted to make the **stylized web game canonical**; folded in **rigged human model**, **radio**, and a **signed Static Maps proxy** for satellite ground (needs Vercel env vars).
- Gameplay pass: **real car models** (player + traffic), **melee combat** (F → KO/kill), **1st/3rd-person toggle** (V), **clouds + planes**; HUD controls updated.
- Created `plans/mount-hope.md` as source of truth, then **expanded it** into a full essential-systems + aesthetics/art-direction/game-feel checklist.
- Added **Part II — World Detail Atlas**: intricate per-city mapping & aesthetic tasks — road/paving system, intersections & signage, modular building/façade kit, NE residential typologies (triple-deckers, mansions, Cape cottages), storefronts & signage, granite mills/churches/civic, ocean & working-waterfront detail, the **inter-city highway network (I-195, MA-24, US-6, MA-18)**, hero **bridges (Braga/“Verde”, Fairhaven, Sagamore/Bourne)**, per-city aesthetic packs (NB/FR/Brockton/Cape), and major systems upgrades (typology classifier, procedural city-gen, navmesh, streaming/LOD, living economy).
- Added **Part III — System Detail Atlases**: exhaustive **vehicle atlas** (the 1980s market by category, fictionalized for ship), plus **character**, **elevated pedestrian-AI**, **interiors**, **weapons**, **clothing/wardrobe**, and **radio & VO** atlases — the radio/VO atlas specifies an **ElevenLabs** pipeline (server-proxied key, subtitles, per-host/character voices, more stations, ads/news/music).
- Added the **Working loop** process (read → scope → build → verify → review → check off → log → commit → repeat) as the canonical execution protocol.
- **Execution batch (+10 items, recommended order):** ① `Props.tsx` — instanced street furniture (lamp posts, hydrants, mailboxes, benches) along road edges (§7); ② lamp-head + building **lit-window glow** ramping at night (§4); ③ **camera FOV scales with car speed** (§13); ④ `SkidMarks.tsx` tire-mark decals on hard cornering (§13); ⑤ **camera shake** (melee + speed via `addShake`) + **low-health damage vignette** (§23); ⑥ `Minimap.tsx` player-centered **radar** (roads/water/objective/heading) (§21); ⑦ `Rain.tsx` + storm grade/closer fog, **R** toggles rain (§5); ⑧ `HarborProps.tsx` — dock pilings + bobbing buoys/fishing boats on the OSM shoreline (§6); ⑨ instanced **street trees** (§7); ⑩ `PauseMenu.tsx` — **Esc/P pause** (resume/view/weather/reset) freezing player/car/time (§26). Added `shared.carSpeed/skid/shake` + `store.ts` weather/paused/slice. Shipped (`d238002`).
- **Execution batch (§32/§3/§4/§15/§16):** rewrote `Roads.tsx` into a 3-class surface system (highway w/ lane markings · asphalt streets · historic granite cobblestone via new `makeCobbleTexture`); added `Effects.tsx` (bloom + vignette + SMAA) + **ACES tone mapping**; added `DayNight.tsx` (600 s day/night cycle driving sun/hemisphere/ambient/fog/bg + drei `<Stars>` + **Palmer’s Island lighthouse beam**); added `game.ts` **PlayerWallet + dual-axis Heat/Wanted** (police + faction 0–5, decay) with `GameSystems.tsx` autosave/load; added `mission.ts` + `MissionRunner.tsx` **mission engine** with a 3-step playable **“Off the Boat”** opener (Bethel → steal car → safehouse) + objective beam/ring marker; HUD gained cash/clock/stars/health panel + objective banner. Shipped (`39ece9e`, `80a05b8`).

- **Player-request batch (UX/driving/map/mobile):** ① collapsible **radio menu** + new **character menu** (outfit-colour tint applied live to the player model) with launcher buttons (§9/§22); ② **inverted A/D** on-foot strafing (§10); ③ **large map** screen — full-screen pannable/zoomable, real OSM **street-name labels**, water, player heading + objective (BigMap.tsx, M), plus **3D street-name signs** in-world (StreetSigns.tsx) (§21/§33); ④ **faster + smoother driving** (top speed 22→44, speed-scaled steering, removed the continuous camera speed-shake that caused the "shaky/bumpy" feel) and **vehicle combat/theft** — ram a traffic car to stop it, **carjack** it on foot (E) with model/colour swap + heat (§12/§13); ⑤ **touch controls** — on-screen thumb-stick + action buttons for phones (TouchControls.tsx, coarse-pointer only) (§25). Shipped (`1800e75`, `91a9e50`, `0aee2eb`).

- **"Heat has teeth" batch:** added **gunplay** — G draws a pistol, click/Space fires a hitscan along the aim with tracer + muzzle flash (Tracers.tsx), dropping peds and damaging cops (§11); **police pursuit** — cop cars spawn and escalate with the police-heat axis, home in with a flashing lightbar, drain health on contact and arrest the player on foot, and are shootable for a payout (Police.tsx, §14); the **busted/wasted** loop — black-out → cash penalty → heat cleared → respawn at the Bethel (Consequence.tsx, §15); a **safehouse** zone that bleeds off heat and autosaves (Safehouse.tsx, §15); and dynamic **vehicle head/tail/brake lights** (dusk + braking, §12). Shipped (`d8884af`).

- **"World reacts" batch:** pedestrians now **flee/panic** from gunfire, melee, and oncoming fast cars (shared.alarm threat model, StreetLife §14); **impact particles** — pooled blood/dust bursts at every melee + gun hit (Impacts.tsx §23); an **aiming reticle** appears when the pistol is drawn (§11/§21); and **parked cars** line the curbs near the core (ParkedCars.tsx §7/§12). Shipped (`34967af`).

- **Audio + police-fairness batch:** procedural **SFX** (gunshot, punch, car crunch, horn-H, cash/UI/bust stings), a **speed-tracked engine note**, a **police siren**, and a **harbor wind + gull ambience** bed (audio/sfx.ts §19/§20/§13). Reworked **police** to be fair (chase at 3★+, slower/fewer units, spawn a few streets away, **losable**, no accidental kills, **5 s arrest grace**) and fixed the **busted/wasted respawn** → BUSTED to the **police station**, WASTED to the **hospital** (places.ts §14/§15). Added **cop blips + police-station markers** to the minimap and big map, and made the **touch controls drag-to-move + resizable** with persisted layout plus gun/fire buttons (§21/§25). Hook false-positive removed (option A). Shipped (`ef1a38e`, `d8fe418`).

- **30-item goal run:** across several batches — **economy** (5 buyable fronts + passive revenue, economy.ts §15/§17); **feel** (Shift sprint+stamina, Space handbrake/drift, chromatic-aberration + film-grain post, on-screen objective distance §10/§13/§3/§21); **weather/ocean/streets** (fog state + wet roads + ocean swell + cycling traffic signals §5/§6/§7); **UI/meta** (title/start screen, pause **settings** with effects+volume, **toast** notifications §22/§26/§21); **combat/side-content** (weapon switching + **shotgun** spread, hidden **scrimshaw** collectibles, **flyer/poster** boards §11/§18/§8). Also reworked police fairness + busted/wasted respawn and added the procedural **SFX/ambience** engine (sfx.ts). Hook false-positive removed (option A). Shipped across `ef1a38e`→`HEAD`.

- **Direction adjust + Step 1 (world build-out):** per user, dropped the planned combat-depth section and refocused the next roadmap on **world rendering + inter-city highways + surrounding towns (Dartmouth, Fairhaven, Westport) → Fall River**. Added in-world **St. Luke's Hospital** stand-in (WASTED respawn) + hospital/police **map markers** on the minimap and big map. **Re-pulled a larger New Bedford slice** via Overpass (waterfront→downtown: **7,645 buildings / 1,753 roads**, up from ~1,071), taught `make_slice.py` to capture civic landmarks, and **re-anchored the police station to the real downtown NBPD footprint** (hospital follows when the pull widens west to St. Luke's). ElevenLabs (key→`ELEVENLABS_API_KEY` env) + gamepad (native API) links handed to the user. Shipped (`d6eda37`, `5e2383d`).

- **Perf → radio depth → Dartmouth (ordered batch):** ① **Perf pass** — far buildings chunked into a 160 m grid with automatic frustum culling + a 1050 m distance cull and no shadow casting, so the now-16k-building world stays interactive (Buildings.tsx §29). ② **Radio depth** — ad/ident/news rotation + hosts reacting to **wanted level** and **weather**, on top of ~4× longer host scripts (radioEngine §19); ElevenLabs VO pipeline (proxy + client) wired to all four hosts with Web-Speech fallback (§33), Iron Mike=Shaun-Boston + Buddy voices recorded. ③ **Step 16 Fairhaven** (+ elevated Acushnet bridges) and **Step 17 Dartmouth** (Route 6 corridor) pulled into the slice — now **New Bedford · Fairhaven · Dartmouth**, 16,252 buildings / 3,868 roads (mapgen now sends a User-Agent to beat the Overpass WAF). Shipped (`66e8fbc`→`f8cd5cc`).

- **Step 19 + music + Phase 1 aesthetics + ocean barrier:** ① **multi-tile building streaming** (public/tiles/, 500 m tiles loaded by distance + per-tile colliders; main slice 3.5 MB→849 KB) — unblocks whole-region build-out. ② **Legitimate music** — radio plays real MP3 tracks per station (ElevenLabs Music generator scripts/gen_music.py) with synth fallback. ③ **Phase 1 aesthetics** — STYLE_GUIDE.md; **façade window kit** (procedural per-floor windows, day glass + night-lit, colour by use/height); **shadows follow the player** across the map. ④ **Ocean** — wave-wash ambience everywhere + **water is now a barrier** (sink/recover, Hazards.tsx) so bridges are the required crossing; bridges lowered to a drivable at-grade causeway on pilings. ⑤ Removed the gull-cry **squeak**. Shipped (`25db5fa`→`a4d903b`).

- **Drivable bridges + Sconticut/boats:** ① **drivable elevated bridges** (Bridges.tsx stitches OSM bridge ways into spans, ramps grade→7 m crest→grade with a trimesh collider + piers). ② Fixed the **floating hospital** placeholder. ③ Extended the slice SE down **Sconticut Neck → West Island/Long Island** (36k buildings / 398 tiles, slice still 1.79 MB). ④ **Off the Hook Bar and Grill** purchasable at 56 Goulart Memorial Dr, doubling as the boat dock. ⑤ **Pilotable yacht** (Boat.tsx — board with E, drive on water, exempt from the water barrier) + moored-yacht **Marina** at Long Island (wealthy area = yachts; NB harbor keeps trawlers). Noted **Dartmouth Mall** as a hub for the Fall River push. Shipped (`d065234`→`dd0bcbd`).

- **Phase 2 + 3 visual:** **IBL** (procedural PMREM env → real reflections/ambient on glass, wet roads, cars, water), asphalt **normal maps**, **Gerstner ocean** (multi-wave + reflective); **time-of-day colour grade** (warm dusk / cool night), a **sun-glow** sprite (bloom haze), **coastal-neon dusk signs** on every business front. Shipped (`108402d`, `af4771c`).

- **Region build-out → Fall River:** stopped tracking the raw OSM dump (gitignore) to keep the repo lean, then extended the slice west along the **I-195 / Route 6 corridor** through **Westport** and on to **Fall River + the Charles M. Braga Jr. Memorial Bridge** (drivable). Region now **68,482 buildings / 16,167 roads / 954 streamed tiles** (slim slice 4.2 MB); pulls done incrementally and merged (dedupe by id) to stay within Overpass limits. Shipped (`793e0c4`→`25abda5`).

- **Roads perf → heroes → Phase 2 cont:** ① **road chunking** — roads split into 1000 m cells with frustum + 1500 m distance culling (Roads.tsx) instead of one always-drawn 16k-road mesh. ② **Hero landmarks** (Heroes.tsx) — stylized **USS Massachusetts** at Battleship Cove, the **Lizzie Borden House**, and the **Dartmouth Mall** hub (also a purchasable front), on real coords. ③ **Phase 2 storefront awnings** — instanced two-tone awnings along commercial frontages near the core. Shipped (`788dac5`→`3778469`).

- **Region fixes + fast travel:** ground enlarged 3 km → 60 km so the whole map has land+collider (no more floating Fall River/voids); **water lifted clear of the ground** so it's visible in 3D (was map-only) + brighter teal; **bridge railings**; **fast travel** from the big map (M) to town centers + hero spots; the **Braga Bridge** now reads green (rails + truss towers). Shipped (`f5ccbeb`→`0293104`).

- **Stack fix + Phase 2 street detail:** fixed road **z-fight flicker / "floating"** (ground top moved to y=0 below the roads), capped DPR for framerate, fast travel now brings your car; then Phase 2 — **sidewalk/curb aprons** framing every street, **rooftop clutter** (water tanks/AC) on mid-rises, and **crosswalks** at intersections. Shipped (`8c9648f`→`472af59`).

- **"Next 50" grind (part 1, ~16 items):** rolling **wheels** on all vehicles (§12); **footsteps + foot-dust** (§20/§23); **gamepad** support (§25/§47); **reduce-shake** toggle (§25); off-screen **waypoint arrow** (§21); **mission chain** — Off the Boat → Linguiça Run → Spindle City (§16); out-of-combat **health regen** (§11); **wanted-up sting** (§23); context **enter prompts** (boat/car/steal, §21); **settings persistence** (§26); **pause stats** screen (§22); denser **pedestrians + traffic that yields** to the player (§14); **UI sfx** on menus (§20); **utility poles + wires** (§7). Shipped (`57e1334`→`9325ed9`).

- **"Next 50" grind (part 2, ~5 items):** adaptive **chase-music duck** under police heat (§19); ground **grime/oil decals** (§32); **street race** side activity with checkpoints + best time (§18); title-screen **New Game / Continue** (§22). Shipped (`ea67a17`→`b79e06c`).

- **"Next 50" grind (part 3, ~3 items):** harbor **gulls** + **photo mode** (O, cinematic orbit, HUD hidden); **radio subtitles** — the dial now captions the currently spoken host/ad line in the active host's name (radioEngine `onSubtitle` → HUD §33); **custom map waypoint** — right-click the big map to drop a pink pin, the HUD shows a pink bearing arrow + distance to it, clear via the 📍 button (BigMap/HUD/shared §21). Shipped (`1c53cd0`→`a8f1ddd`).

- **"Next 50" grind (part 4, +1):** **owned-front rest perk** — standing on foot inside a front you own now heals you fast (≈12/s) and bleeds off police + faction heat (a payoff for buying property), with a one-time "Resting at …" toast (Businesses §15). Shipped (`a8f1ddd`→`ac13bf1`).

- **"Next 50" grind (part 5, +1):** **traffic obeys red lights** — TrafficLights now publishes its signal stop-lines to `shared.stopZones` with a live red flag (red + amber = stop); ambient traffic halts when a red stop-line is just ahead (≤8 m) and aligned with its travel direction, so cross-street cars ignore it and cars queue behind each other (StreetLife `redAhead`, §14). Shipped (`ac13bf1`→`5038695`).

- **"Next 50" grind (part 6, +2):** **waypoint on the radar** — the player-placed waypoint now shows as a pink dot on the minimap, clamped to the radar ring when off-range (Minimap §21); **waypoint auto-clear** — driving/walking within 9 m of it clears the pin with a "Waypoint reached" toast (GameSystems §21). Shipped (`5038695`→`5115727`).

- **"Next 50" grind (part 7, +1):** **baseball bat melee** — key **4** equips a bat (key **1** back to bare fists); the bat reaches farther (2.8 m), hits harder, and knocks pedestrians flying with a heavier camera punch; it renders in the player's hand and reads on the HUD as 🏏 BAT (store `melee`, GameSystems, Player, HUD §10/§11). Shipped (`5115727`→`3783f51`).

- **"Next 50" grind (part 8, +1):** **scrimshaw counter** — the hidden-collectible tally is now a persistent HUD readout (🦴 n/8), reactive via `store.scrimshaw`, seeded from the save on load and bumped on pickup (Collectibles/store/HUD §18). Shipped (`3783f51`→`74eebc9`).

- **"Next 50" grind (part 9, +1):** **traffic brake lights** — ambient cars now flare their taillights whenever they're halted (red light, yielding to the player, or freshly rammed) via the existing Vehicle `brake` getter, so a queue at a red reads correctly at night (StreetLife §12). Shipped (`74eebc9`→`c9a56f3`).

- **"Next 50" grind (part 10, +2):** **ragdoll launch** — pedestrians struck by the bat (or run over by a car at speed) are now flung along the blow, tumbling through the air with gravity + spin before settling, instead of just flopping flat; running someone over also registers a hit + draws heat once (StreetLife §14/§23). **Wall graffiti** — colourful procedural spray tags (`makeGraffiti`) on upright quads set back from the street where walls are, facing the road, near-core only (Graffiti.tsx §32). Shipped (`c9a56f3`→`e03fabd`).

- **Code-review fixes (batches Q–X):** ran a high-effort 8-angle review of the grind and fixed the real bugs it surfaced. ① **Red-light coordinate bug** — TrafficLights published stop-line bearings from un-negated OSM northing while `redAhead` compared world-space car headings, so cars ran reds (and cross-traffic stopped at green) on diagonal roads; bearing now computed in world space. ② **New Game wasn't fresh** — migrated `waypoint` into the zustand store (deleting BigMap's `force()` re-render hack) and added `useGame.resetSession()` so New Game clears bat/photo/armed/scrimshaw/waypoint; `Collectibles` is now keyed on a `gameId` so its picked-up ref re-reads the wiped save. ③ **Bat wasn't lethal** — hit-resolution now advances one stage per damage point, so a 2-damage blow (bat/gun/car) drops a standing ped outright while a fist only knocks down (also kills the run-over jitter/2-frame-kill). ④ **Ragdoll launch classifier** — "hard" fling now keys off the hit amount, not push magnitude, so point-blank run-overs and gunshots fling correctly (pistol now sets a launch push). ⑤ **Melee/gun mismatch** — F is a pistol-whip (not a bat strike) while a gun is drawn. Build green. Shipped (`e03fabd`→`c04cf3a`).

- **Cleanup (review §9/§10):** extracted the shared road-edge sampler `roadSamples.ts` (`sampleRoadEdges`) — the iterate-roads / skip-bridge / highway-whitelist / arc-length walk / sparse / radius-cull loop now lives in one place; `Decals` and `Graffiti` both call it and add their own jitter / perpendicular offset. `Graffiti` now buckets tags straight into per-variant arrays (dropped the redundant `byVariant` filter pass + the `v` field). Shipped (`c04cf3a`→`f786212`).

- **Grind Y/Z + player fixes:** **position-save Continue** — the player's spot/mode/car persist (20 s autosave + pagehide) and resume on Continue; New Game wipes the key (GameSystems §26). **Speedometer** MPH readout while driving + **Pay-n-Spray** at the Anvil Garage (drive in with heat → $200 respray clears the wanted level + repaints, Respray.tsx §14). **Player report:** raised the **Braga Bridge** ~10 ft (green span now crests at 10 m with a 40 m ramp so it stays drivable, lifting it clear of the approach roads); reduced the **"squished roads"** at the I-195 interchange — trimmed highway carriageway width to 0.82× so the close divided carriageways read as separate roads with a median, plus polygon-offset on road materials to kill the overlap z-fight (Bridges/Roads). Shipped (`f786212`→`ce…`).

- **Audio/radio pipeline + content:** fixed host VO (built-in premade voices per character so none fall silent; a per-voice failure no longer disables all VO). Added the **music drop-in system** — `scripts/gen_manifests.mjs` (auto-run via pre/dev/build) + `MusicPlayer.tsx` + a **webhook receiver** (`/api/music-webhook` → Vercel Blob) and `/api/music`; the radio reads Blob → static manifest → synth, and the in-game radio shows **now-playing + skip** on music stations. Wrote `radio-scripts.md` (host VO, songs w/ lyrics, jingles). 

- **"Next 50" grind (parts AA–GG):** **cash drops** from downed peds (Pickups); **HUD compass** + **tire-screech** sfx; **pedestrian barks** on melee; **Quit-to-title** in the pause menu; **vehicle damage + engine smoke** (resets on respray/carjack); **respawning health packs**; **near-miss driving cash bonus**; **pause-menu controls reference**; **"EVADED" cash reward** for losing the cops. Shipped (`…`→HEAD).

### 2026-06-22 — DIRECTION CHANGE: perfect New Bedford first
Per the user: **stop all city/region expansion. Make the New Bedford core genuinely good before going anywhere else.** Fall River / Westport / Dartmouth / the bridges stay in the slice but are not the focus; no new regions get pulled until NB is "perfect."
- Fixed the blocker: Vercel **install command** was `node install` → every deploy failed at install; overridden to `npm install` in `vercel.json`. Deploys live again at projectsouthcoast.vercel.app.
- Wired uploaded audio: Maré Alta plays 3 real songs; The Rage plays jingles.
- **Rendering pass:** sRGB colorspace on all procedural textures (fixes washed-out look), anisotropy ×16, 256px asphalt, building façade normal-relief, shadow bias.
- **"New Bedford to perfection" checklist (open):**
  - [~] Buildings: era/material variety (brick mills, granite downtown, triple-deckers), height + roofline variation, less "extruded box" look — short footprints (<14 m) now get **peaked hip roofs** (apex-fan over the centroid; tall granite/mills stay flat); era/material variety still TODO
  - [ ] Streets: surfaces, intersections, curbs/sidewalks, signage, parked density
  - [ ] Lighting/atmosphere: ambient occlusion, color grade, fog, reflections
  - [ ] Waterfront: piers, working docks, boats, hurricane barrier, water quality
  - [ ] Landmarks: Seamen's Bethel + downtown accuracy, hero buildings

### 2026-06-24 — NB rooflines + favicon
- **Peaked roofs (less "extruded box"):** `StreamingBuildings.tsx` now caps short
  footprints (`height < 14 m`) with a peaked hip roof — a triangle fan from each
  footprint edge to a single apex over the centroid (pitch ≈ steep 35-45° on
  house/triple-decker widths, capped at 5.5 m so wide blocks don't spike). Tall
  granite-downtown + brick mills keep realistic flat roofs; heroes untouched;
  rooftop water-tank/AC clutter moved to flat-roofed buildings only. Found +
  fixed a backface-culling bug (fan winding faced down → roofs invisible behind
  the flat extrude cap); winding now derived from the footprint's signed area in
  world XZ so it's robust to OSM orientation. Verified deterministically (merged
  geometry max-Y rises above walls, roof normals face up) and visually in photo
  mode (incl. a magenta debug pass to confirm the peak shape). Added an inline
  SVG favicon (kills the `favicon.ico` 404). Shipped (`b64ddac`).

### 2026-06-27 — GODOT PORT: world load fix + systems sprint (deployed)
The Godot build (`QUAHOG_GODOT1`, deployed at quahog.vercel.app) went from a
broken deploy to a feature-complete vertical slice. Every commit verified with a
full `--export-release "Web"` (release export = warnings-as-errors) **and** a
headless game-world boot scan (0 script errors / leaks).
- **Critical fix:** the pause-panel construction had been orphaned into
  `_on_radio_track()` (local `title` collided with the param), a hard release-export
  parse error that cascaded to "Could not resolve hud.gd" → `game_world.gd` failed
  to load → the **entire world failed to boot in the deployed build**. Moved back
  into `_build_pause()`.
- **Navigation:** minimap (real streets + nearest-landmark label) · full-screen Big
  Map (streets, landmarks, named destinations, ✕/M close) · fast travel
  (`player.fast_travel_to`, ground-raycast, refuses open water; tap a named place).
  Fixed two playtest bugs: map flinging the player over the harbour + closing on any
  tap.
- **Atmosphere:** dusk-anchored day/night cycle (sun/ambient/fog/glow), rain weather,
  day/night-driven streetlights, HUD clock + ☔.
- **Living city:** ambient traffic (`traffic_car.gd`) + pedestrians both follow the
  player (respawn when far); pedestrians flee gunfire; police pursue/shoot/arrest;
  firing in public draws a star.
- **Systems/UI:** Save/Continue (pos+heading+cash+wanted; menu Continue vs New Game)
  · Settings volume sliders (persisted) · main-menu web-parity text · radio (4
  stations, HUD button + number keys, ducks the score) · speedometer.
- **Open (need a decision):** corridor slice port (RT18/I-195/Fall River — port the
  web build's pulled OSM region) · web first-load size (~200 MB, 58 MB radio MP3s;
  needs ffmpeg re-encode or asset trim) · gamepad/perf pass · mission chain.
