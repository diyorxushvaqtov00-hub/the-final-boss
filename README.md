# The Final Boss

**A 2D top-down dark-fantasy action game prototype built with Godot 4**, with Android touch controls.

## Current gameplay
- Move with **WASD / arrow keys** or the on-screen MOVE pad.
- **Space** / ATTACK — short-range slash (18 damage).
- **E** / SKILL — Abyss Nova (42 damage, 4-second cooldown).
- **Shift** / DASH — quick dodge with a short damage-avoidance window (1.6-second cooldown).
- Akteynt has two combat phases; at half health, the boss moves faster and attacks harder.
- In phase two, Akteynt charges and launches a visible Abyss Orb projectile; dodge it or take 16 damage.
- Boss attacks have a visible wind-up cue so the player can try to dodge.
- Victory, defeat, and restart states.
- On-screen health bars and skill/dash cooldown labels.

## Open on Android
1. Download the repository as a ZIP and extract it to a new folder.
2. Open Godot 4.x on Android.
3. In Project Manager, choose **Import** and select `project.godot` from the extracted folder.
4. Open the project and press **Run Project**.

## Controls
| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / arrow keys | MOVE pad |
| Attack | Space | ATTACK |
| Abyss Nova | E | SKILL |
| Dash / dodge | Shift | DASH |
| Restart | R | Tap after game over |

## Validation and Android export
The GitHub Actions workflow runs a headless Godot project check on pushes and pull requests. This is intended to catch script or project errors early; it does not replace testing on an Android device.

**No verified APK is included yet.** Android export still needs export templates and Android build tools configured. The project should be tested in Godot before starting APK packaging.

## Structure
- `project.godot` — Godot project settings
- `scenes/main.tscn` — main scene
- `scripts/main.gd` — current prototype gameplay

## Roadmap
1. Run automated project checks and confirm the updated build on Android.
2. Replace placeholder circles with original character and boss sprites.
3. Add animation states, sound effects, enemy patterns, and more arenas.
4. Separate gameplay into reusable scenes and scripts.
5. Set up a reproducible Android APK build.
