# Web → Godot Replication Checklist

Spreadsheet-style inventory for porting the **QUAHOG_Web** behavior/content
reference into **QUAHOG_GODOT1**, the ship target.
Baseline: `main` @ elevation Tier 12 + merged web photoreal (#23).

**Legend**

| Parity status | Meaning |
|---------------|---------|
| **Done** | Feature exists in Godot with comparable behavior |
| **Partial** | Core exists but missing polish, scope, or UX parity |
| **Missing** | Not implemented in Godot |
| **Web-only** | Intentionally or impractically web-specific |
| **Godot-only** | Exists in Godot but not in web |

| Port difficulty | Meaning |
|-----------------|---------|
| **Low** | Mostly logic/UI; existing patterns to copy |
| **Medium** | New scenes, physics, or content authoring |
| **High** | Major systems, art pipeline, or third-party deps |

| Priority | Meaning |
|----------|---------|
| **P0** | Blocks “real game” feel; do first |
| **P1** | High player-visible value |
| **P2** | Polish / depth |
| **P3** | Nice-to-have / long tail |
| **Skip** | Do not port (web-only or superseded) |

---

## 1 — App shell & session

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Title / new game / continue | `App.tsx`, `ui/StartMenu.tsx` | `main_menu.gd`, `autoloads/game_manager.gd` | Done | — | — |
| Loading screen | `Experience.tsx` (slice fetch) | `autoloads/loading_screen.gd` | Done | — | — |
| Error boundary / crash UX | `ui/ErrorBoundary.tsx` | — | Missing | Low | P2 |
| Quality presets (low/med/high) | `quality.ts`, `Experience.tsx` | `game_manager.gd` (cheat quality), `map_loader.gd` LOD | Partial | Low | P2 |
| Photoreal Mode (Google 3D Tiles) | `earth/EarthApp.tsx`, `earth/PlayWorld.tsx`, `earth.tsx` | — | Web-only | High | Skip |
| Session reset (new game clears state) | `StartMenu.tsx`, `store.ts` | `game_manager.gd` `new_game()` | Done | — | — |
| Disclaimer / fiction notice | `PauseMenu.tsx` | `hud.gd` pause panel (partial) | Partial | Low | P3 |

---

## 2 — Core game state

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Zustand game store (mode, pause, weather) | `store.ts` | `game_manager.gd` | Done | — | — |
| Stats (cash, health, police, faction) | `game.ts` | `game_manager.gd`, `wanted_system.gd` | Done | — | — |
| Dual heat (police ★ + faction 🔪) | `game.ts`, `HUD.tsx` | `wanted_system.gd`, `hud.gd` | Done | — | — |
| World clock / day-night hour | `world/DayNight.tsx`, `shared.ts` | `game_world.gd` | Done | — | — |
| Pause / resume | `store.ts`, `ui/PauseMenu.tsx` | `hud.gd` `_toggle_pause` | Done | — | — |
| Pause progression summary | `ui/PauseMenu.tsx` | `hud.gd` `_refresh_pause_stats` | Done | — | — |
| Controls reference overlay | `ui/PauseMenu.tsx` | `hud.gd` controls panel | Done | — | — |
| Toasts / on-screen messages | `ui/Toasts.tsx` | `game_manager.gd` `show_message()` | Partial | Low | P2 |

---

## 3 — Player & camera

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| On-foot movement (WASD) | `actors/Player.tsx`, `input.ts` | `player.gd` | Done | — | — |
| Third-person follow camera | `actors/FollowCamera.tsx` | `player.gd` + camera rig | Done | — | — |
| Enter / exit vehicle (E) | `actors/Player.tsx`, `actors/Car.tsx` | `player.gd`, `vehicles/car.gd` | Done | — | — |
| Health / armor pickups | `world/HealthPickups.tsx`, `world/Pickups.tsx` | `game_world.gd` pickups | Done | — | — |
| Footsteps SFX | `audio/sfx.ts` | `audio_manager.gd` | Partial | Low | P2 |
| Character menu (C) | `ui/CharacterMenu.tsx` | — | Missing | Medium | P3 |
| Photo mode / camera item | `store.ts` (`photo`) | — | Missing | Medium | P3 |

---

## 4 — Vehicles & driving

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Stealable traffic / parked cars | `world/ParkedCars.tsx`, `actors/Car.tsx` | `vehicles/car.gd`, `traffic_car.gd` | Done | — | — |
| Arcade car physics (Rapier) | `actors/Car.tsx` | `vehicles/car.gd` (Godot physics) | Partial | — | — |
| Horn (H) | `actors/Car.tsx`, `audio/sfx.ts` | `car.gd`, touch HORN button | Done | — | — |
| Headlights / taillights | `actors/Car.tsx`, `world/DayNight.tsx` | `car.gd`, `game_world.gd` | Done | — | — |
| Handbrake / drift | `actors/Car.tsx` | `car.gd` | Done | — | — |
| Tire skid marks | `world/SkidMarks.tsx` | `car.gd` `_spawn_skid_marks` | Done | — | — |
| Wet-road friction (rain) | `world/Rain.tsx`, `actors/Car.tsx` | `car.gd` wet friction | Done | — | — |
| Vehicle variety (sedan/SUV/truck) | `earth/Vehicles.tsx` | Single car mesh + traffic variants | Partial | Medium | P2 |
| Drive joystick / invert option | `ui/TouchControls.tsx`, `input.ts` | `virtual_joystick.gd`, cheats | Partial | Low | P2 |
| Engine audio loop | `audio/sfx.ts` | `car.gd` + `audio_manager.gd` | Done | — | — |

---

## 5 — Boat & water traversal

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Pilotable harbor boat | `actors/Boat.tsx` | — | Missing | High | P0 |
| Board boat at marina (E) | `actors/Boat.tsx`, `economy.ts` | — | Missing | High | P0 |
| Boat wake VFX | `actors/Boat.tsx` | — | Missing | Medium | P1 |
| Water as non-drivable barrier (cars) | `world/Water.tsx`, `waterZones.ts` | `water_zones.gd`, `water_hazard.gd` | Done | — | — |
| Drivable bridge corridors | `world/Bridges.tsx`, `waterZones.ts` | `map_loader.gd` deck colliders | Done | — | — |
| Marina / pier set dressing | `world/Marina.tsx`, `world/Piers.tsx` | `map_loader.gd` (partial) | Partial | Medium | P2 |

---

## 6 — Combat & weapons

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Shoot / melee combat | `actors/Player.tsx`, `world/Character.tsx` | `player.gd`, `weapon_db.gd` | Done | — | — |
| Weapon pickups (pistol/bat/shotgun/rifle) | `world/Pickups.tsx` | `weapons/weapon_pickup.gd` | Done | — | — |
| Gun shop purchases | `world/` (economy hooks) | `world/shop.gd`, `ui/shop_menu.gd` | Done | — | — |
| Tracers / muzzle flash | `world/Tracers.tsx`, `world/Impacts.tsx` | `vfx_helper.gd` (lighter) | Partial | Medium | P2 |
| NPC panic on gunfire | `world/StreetLife.tsx` | `npc.gd` (partial) | Partial | Low | P2 |
| Faction enforcer spawns | `world/Consequence.tsx` | `faction_enforcer.gd`, `consequence_manager.gd` | Done | — | — |

---

## 7 — Police, heat & consequences

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Wanted level escalation | `world/Police.tsx`, `game.ts` | `police.gd`, `wanted_system.gd` | Done | — | — |
| Cop chase / bust | `world/Police.tsx` | `police.gd` | Done | — | — |
| Heat decay over time | `game.ts` | `wanted_system.gd` | Done | — | — |
| Safehouse heat bleed + save | `world/Safehouse.tsx` | `safehouse_zone.gd` | Done | — | — |
| Safehouse sleep / time skip (T) | `world/Safehouse.tsx`, `DayNight.tsx` | `safehouse_zone.gd` (time skip) | Done | — | — |
| Pay-n-Spray / respray ($200) | `world/Respray.tsx` | `respray_zone.gd` | Done | — | — |
| Owned business as mini-safehouse | `world/Businesses.tsx` | `business_fronts.gd`, `business_manager.gd` | Done | — | — |

---

## 8 — Missions & story

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Campaign mission chain | `mission.ts`, `world/MissionRunner.tsx` | `systems/story_mission.gd` | Done | — | — |
| Off the Boat opener | `mission.ts` | `story_mission.gd` | Done | — | — |
| Act I (Auction, Linguiça, Harbor Heat) | `mission.ts` | `story_mission.gd` | Done | — | — |
| Act II (Spindle City, Acquitted, Undefeated) | `mission.ts` | `story_mission.gd` | Done | — | — |
| Act III (Heritage, Compound, Gloria, Big Mamie) | `mission.ts` | `story_mission.gd` | Done | — | — |
| Gloria weather event (hurricane) | `mission.ts`, `world/Rain.tsx` | `story_mission.gd` + weather hooks | Partial | Medium | P1 |
| Mission waypoint markers | `world/MissionRunner.tsx` | `job_marker.gd` | Done | — | — |
| Delivery side jobs | `world/GameSystems.tsx` | `systems/job_manager.gd`, `mission_giver.gd` | Done | — | — |
| Mission VO / bark lines | `audio/vo.ts` | — | Missing | High | P1 |

---

## 9 — Economy & businesses

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Cash earn / spend | `economy.ts`, `game.ts` | `game_manager.gd` | Done | — | — |
| Buyable business fronts (B) | `world/Businesses.tsx`, `economy.ts` | `business_fronts.gd`, `business_manager.gd` | Done | — | — |
| Passive business revenue events | `world/GameSystems.tsx` | `business_manager.gd` | Done | — | — |
| Diner food purchases | — | `diner_interior.gd`, `diner_menu.gd` | Godot-only | — | — |
| Gun shop | — | `shop.gd` | Godot-only | — | — |

---

## 10 — Collectibles & optional activities

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Scrimshaw collectibles (8) | `world/Collectibles.tsx`, `store.ts` | `scrimshaw_collectible.gd`, `game_manager.gd` | Done | — | — |
| Street race checkpoints | `world/Race.tsx`, `race.ts` | — | Missing | Medium | P1 |
| Race timer / payout | `race.ts` | — | Missing | Low | P1 |

---

## 11 — HUD & menus

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Cash / health / wanted HUD | `HUD.tsx` | `ui/hud.gd` | Done | — | — |
| Minimap | `Minimap.tsx` | `ui/minimap.gd` | Done | — | — |
| Mission objective text | `HUD.tsx`, `mission.ts` | `hud.gd`, `story_mission.gd` | Done | — | — |
| Scrimshaw counter | `HUD.tsx` | `hud.gd` | Done | — | — |
| Businesses owned indicator | `HUD.tsx` | `hud.gd` | Done | — | — |
| Radio now-playing strip | `HUD.tsx`, `audio/Radio.tsx` | `hud.gd`, `radio.gd` | Partial | Low | P2 |
| Debug stats overlay | `ui/DebugStats.tsx` | `cheats_panel.gd` (partial) | Partial | Low | P3 |
| Music player UI (score) | `ui/MusicPlayer.tsx` | `audio_manager.gd` | Partial | Low | P3 |

---

## 12 — Big map & fast travel

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Full-screen OSM road map (M) | `ui/BigMap.tsx` | `ui/big_map.gd` | Done | — | — |
| Pan / zoom map | `ui/BigMap.tsx` | `big_map.gd` (fixed zoom) | Partial | Medium | P2 |
| Street-name labels when zoomed | `ui/BigMap.tsx` | — | Missing | Low | P3 |
| Tap-to-close map | `ui/BigMap.tsx` | `big_map.gd` | Done | — | — |
| Named fast-travel destinations | `places.ts`, `ui/BigMap.tsx` | `big_map.gd` `DESTINATIONS` | Done | — | — |
| South Coast region teleports | `places.ts` | `big_map.gd` `REGIONS` | Done | — | — |
| Civic landmark labels on map | `places.ts`, `ui/BigMap.tsx` | `big_map.gd` `_landmarks` | Partial | Low | P2 |

---

## 13 — Touch & mobile UX

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Virtual joystick (move) | `ui/TouchControls.tsx` | `ui/virtual_joystick.gd` | Done | — | — |
| Touch camera look | `ui/TouchControls.tsx` | `ui/touch_camera.gd` | Done | — | — |
| Action buttons (E, shoot, horn, etc.) | `ui/TouchControls.tsx` | `ui/touch_button.gd`, `hud.gd` | Done | — | — |
| HUD layout edit mode | — | `hud.gd` edit controls | Godot-only | — | — |
| Canvas focus requirement | `App.tsx` (web quirk) | N/A (Godot handles input) | Done | — | — |

---

## 14 — Audio, radio & VO

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| In-game radio stations | `audio/radioEngine.ts`, `audio/Radio.tsx` | `autoloads/radio.gd` | Done | — | — |
| Station cycle / mute | `audio/Radio.tsx` | `radio.gd` | Done | — | — |
| Radio milestone barks | `audio/radioEngine.ts` | `autoloads/radio_hooks.gd` | Done | — | — |
| Dynamic score / ambient music | `audio/` (Vercel music API) | `audio_manager.gd` | Partial | Medium | P2 |
| ElevenLabs mission VO | `audio/vo.ts`, `api/` | — | Missing | High | P2 |
| Harbor / district ambience | `world/StreetLife.tsx`, `audio/sfx.ts` | `audio_manager.gd`, `game_world.gd` | Partial | Low | P2 |
| Impact / screech / cash SFX | `audio/sfx.ts` | `audio_manager.gd` | Partial | Low | P2 |

---

## 15 — World rendering & map data

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| OSM slice load (New Bedford) | `slice.ts`, `public/slice-newbedford.json` | `map_loader.gd`, `data/map/slice-newbedford.json` | Done | — | — |
| Streaming tile buildings | `world/StreamingBuildings.tsx` | `map_loader.gd` tile streaming | Done | — | — |
| Procedural building extrusion | `world/Buildings.tsx` | `map_loader.gd` | Done | — | — |
| Aerial / satellite ground drape | `world/AerialGround.tsx`, `api/staticmap.ts` | Procedural ground | Partial | High | P3 |
| Roads + sidewalks mesh | `world/Roads.tsx` | `map_loader.gd` | Partial | Medium | P2 |
| Crosswalks / road fixtures | `world/Crosswalks.tsx`, `world/RoadFixtures.tsx` | `map_loader.gd` (partial) | Partial | Medium | P2 |
| Distance culling / LOD | `world/CullByDistance.tsx`, `quality.ts` | `map_loader.gd`, quality presets | Partial | Medium | P2 |
| Hero landmarks (museum, bethel, etc.) | `world/Landmarks.tsx`, `world/Heroes.tsx` | `hero_hubs.gd`, `map_loader.gd` | Partial | Medium | P1 |
| Neon signs / coastal dusk | `world/NeonSigns.tsx` | `neon_signs.gd`, `game_world.gd` | Done | — | — |
| Graffiti / posters / decals | `world/Graffiti.tsx`, `world/Posters.tsx`, `world/Decals.tsx` | — | Missing | Medium | P3 |
| Area trees / foliage | `world/AreaTrees.tsx`, `world/Foliage.tsx` | `map_loader.gd` (sparse) | Partial | Medium | P2 |
| Utility poles / street signs | `world/UtilityPoles.tsx`, `world/StreetSigns.tsx` | — | Missing | Medium | P3 |
| Port clutter / harbor props | `world/PortClutter.tsx`, `world/HarborProps.tsx` | `map_loader.gd` (partial) | Partial | Medium | P2 |
| Billboards / awnings | `world/Billboards.tsx`, `world/Awnings.tsx` | — | Missing | Medium | P3 |
| N8AO / post-processing | `Experience.tsx`, `quality.ts` | Godot compositor (different stack) | Partial | High | P3 |
| Photoreal earth vehicles | `earth/Vehicles.tsx` | — | Web-only | High | Skip |

---

## 16 — Weather & environment

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Day / night cycle | `world/DayNight.tsx`, `world/EnvLight.tsx` | `game_world.gd` | Done | — | — |
| Weather toggle (R) clear/rain | `world/Rain.tsx`, `store.ts` | `game_world.gd` rain | Done | — | — |
| Rain particles / wet visuals | `world/Rain.tsx`, `world/Effects.tsx` | `game_world.gd` (lighter) | Partial | Medium | P2 |
| Streetlights TOD | `world/DayNight.tsx` | `game_world.gd`, `map_loader.gd` | Done | — | — |
| Traffic lights at junctions | `world/TrafficLights.tsx` | `map_loader.gd` `_build_traffic_props` | Done | — | — |
| Seagulls / ambient critters | `world/Gulls.tsx` | — | Missing | Low | P3 |

---

## 17 — Street life & traffic

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| OSM-routed traffic cars | `world/StreetLife.tsx` | `traffic_car.gd`, `game_world.gd` | Partial | Medium | P1 |
| Wandering pedestrians | `world/StreetLife.tsx`, `world/ModelCharacter.tsx` | `npc.gd` | Partial | Medium | P1 |
| TOD density scaling | `world/StreetLife.tsx` | `game_manager.gd` `traffic_car_count()` | Done | — | — |
| Parked decorative cars | `world/ParkedCars.tsx` | `map_loader.gd` (sparse) | Partial | Low | P2 |
| Street extras (benches, etc.) | `world/StreetExtras.tsx`, `world/Props.tsx` | — | Missing | Medium | P3 |

---

## 18 — Persistence

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| Stats save (localStorage) | `game.ts` | `game_manager.gd` save | Done | — | — |
| Position save | `shared.ts`, localStorage | `game_manager.gd` | Done | — | — |
| Scrimshaw bitmask | `world/Collectibles.tsx` | `game_manager.gd` | Done | — | — |
| Campaign progress | `mission.ts` | `game_manager.gd` `campaign_mi/step` | Done | — | — |
| Owned businesses mask | `economy.ts` | `business_manager.gd` | Done | — | — |
| Safehouse autosave on rest | `world/Safehouse.tsx` | `safehouse_zone.gd` | Done | — | — |

---

## 19 — Debug & cheats

| Web feature | Web files | Godot counterpart | Parity | Difficulty | Priority |
|-------------|-----------|-------------------|--------|------------|----------|
| No-police cheat | URL / dev hooks | `cheats_panel.gd`, `game_manager.gd` | Done | — | — |
| Traffic / time / weather cheats | — | `cheats_panel.gd` | Godot-only | — | — |
| Teleport / cash cheats | — | `cheats_panel.gd` | Godot-only | — | — |
| CAM debug overlay | `ui/DebugStats.tsx` | — | Missing | Low | P3 |

---

## Summary — recommended port order

### P0 (do next)

| # | Feature | Why |
|---|---------|-----|
| 1 | **Pilotable boat** | Web has full marina loop; Godot has water barriers but no boat mode |
| 2 | **Street races** | Self-contained activity with cash reward; web-complete reference |

### P1 (high leverage)

| # | Feature | Why |
|---|---------|-----|
| 3 | Traffic + pedestrian polish | Godot has systems but thinner than web `StreetLife.tsx` |
| 4 | Gloria hurricane mission weather | Story beat needs stronger environmental sync |
| 5 | Hero landmark pass | Makes streamed world feel authored |
| 6 | Mission VO (or text bark fallback) | Story presence without ElevenLabs dependency |

### P2 (polish band)

- Big map pan/zoom + landmark labels  
- Vehicle model variety  
- Roads/sidewalks/crosswalk mesh parity  
- SFX pass (footsteps, impacts, ambience)  
- Area trees / port clutter  
- Error boundary equivalent for web export  

### P3 / Skip

- Graffiti, billboards, utility poles, seagulls  
- Aerial satellite drape (Vercel-only; procedural OK for Godot)  
- N8AO / photoreal earth mode (**Skip** — separate product surface)  
- Character menu / photo mode  

---

## Godot advantages (no web port needed)

These already exceed or differ from web in useful ways:

- HUD layout editor (`hud.gd`)
- Rich cheats panel (`cheats_panel.gd`)
- Diner interior economy (`diner_interior.gd`)
- Full South Coast region fast-travel list (`big_map.gd` `REGIONS`)
- Wet-road skid system tuned for Godot physics
- Web-export-safe radio streaming (`radio.gd` `PLAYBACK_TYPE_STREAM`)

---

## How to use this doc

1. Pick a **P0/P1** row.  
2. Read the **Web files** column as the spec.  
3. Implement in the **Godot counterpart** path (or create it).  
4. Update the **Parity** column when done.  
5. Cross-check against `plans/smoke-test-checklist.md` and run
   `GODOT_BIN=godot bash QUAHOG_GODOT1/scripts/verify.sh`.

*Generated from codebase audit on `main` (post Tier 12 + photoreal merge).*
