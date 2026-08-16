# The Narrows Vertical-Slice Release Gate

Release candidate: ____________________  
Commit SHA: ____________________  
Preview URL: ____________________  
Tester/date: ____________________

Every required item must be checked against the same commit SHA. Record defects in the pull request and restart the affected section after a fix.

## Identity and startup

- [ ] Menu, loading screen, pause screen, and browser title say **The Narrows** and **South Coast · Now**.
- [ ] The visible build SHA matches the tested commit and deployed preview.
- [ ] Cold-load compressed initial payload is at most **35 MB**.
- [ ] Cold menu-visible is at most **8 s** and Play-to-interactive is at most **12 s**.
- [ ] Warm menu-visible is at most **3 s** and Play-to-interactive is at most **6 s**.

## Golden-path completion

- [ ] Desktop keyboard/mouse completes all eight “Off the Boat” objectives.
- [ ] Landscape mobile touch completes all eight objectives without keyboard input.
- [ ] Standard gamepad completes movement, look, combat, driving, dialogue, map, pause, and checkpoint restart.
- [ ] Mission reward is granted once and does not duplicate after reload.

## Layout and controls

- [ ] 1920×1080, 1280×720, and 844×390 keep pause, mission, minimap, radio, and action controls visible and non-overlapping.
- [ ] A landscape phone with 24 px left/right safe-area insets keeps all critical controls inside the usable rectangle.
- [ ] Short-screen pause/settings content scrolls; no button or label is clipped.
- [ ] Edited touch controls survive reload, Reset Layout restores defaults, and an off-screen saved layout is clamped back into view.

## Failure, save, and recovery

- [ ] Wasted, assigned-car destroyed, and encounter-boundary failures restart at `reach_fish_pier`.
- [ ] Pause **Restart Checkpoint** restores mission/encounter state without duplicating rewards.
- [ ] **Save & Quit** then **Continue** restores player, mission, economy, heat, business, vehicle, and world state.
- [ ] An unversioned `mount_hope_save.json` migrates to schema version 3.
- [ ] A corrupt primary exposes backup recovery; recovered progress loads successfully.
- [ ] **New Game** confirms, clears progress, and preserves graphics/audio/input/accessibility settings.

## Stability and sign-off

- [ ] Strict import, unit, Web export, deferred-content export, and asset-budget gates pass.
- [ ] Browser console and Godot logs contain no script, parse, resource-load, or uncaught runtime errors.
- [ ] Thirty continuous minutes of mission, driving, combat, map, radio, pause, save, and reload complete without crash or unrecoverable state.
- [ ] Desktop pass signed: ____________________
- [ ] Mobile pass signed: ____________________
- [ ] Gamepad pass signed: ____________________
- [ ] Release owner approval: ____________________
