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
- Custom transparent SVG artwork for the hero and Akteynt, the Abyss Empress, with floating idle motion, ground shadows, and phase-colored glow.
- Directional hero rotation and lightweight cyan/purple/pink particle bursts for dash, slash, skill, boss-orb launch, and damage impacts.
- Animated boss attack telegraph, short forward strike lunge, expanding slash arc, and brief hit-flash reaction.
- A layered obsidian arena with a glowing rotating ritual seal, rune marks, stone cracks, and ambient floating embers.
- Hero movement afterimages during running and dashing, plus subtle footstep sparks; effects are drawn in-engine to stay lightweight on Android.
- A three-hit melee combo with changing damage, reach, slash arc, and a stronger third finisher.
- Phase-two Abyss Shockwave: a visible expanding ground ring that rewards timing a dash to evade it.

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
- `scripts/main.gd` — gameplay, controls, effects, and sprite rendering
- `assets/hero.svg` — original hero character artwork
- `assets/akteynt.svg` — original Dark Lord Akteynt artwork

## Roadmap
1. Run automated project checks and confirm the updated build on Android.
2. Add multi-frame run/attack animations and frame-based sprite effects.
3. Add sound effects, more enemy patterns, and additional arenas.
4. Separate gameplay into reusable scenes and scripts.
5. Set up a reproducible Android APK build.


## Current visual milestone
- Akteynt is named and presented as **Akteynt — Abyss Empress**, matching the supplied character direction rather than the old generic Dark Lord label.
- The boss is larger on screen and subtly scales during phase two to make the transformation feel more imposing.
- The hero sprite is slightly larger for better mobile readability.

**Honest status:** this is still an in-progress prototype. The supplied concept image is the art target; full multi-frame character animation, a rigged skeleton, and final-quality arena assets are not complete or verified in Godot yet.


## Akteynt 2D rig milestone (scaffold)
Added `scenes/akteynt_rig.tscn` and `scripts/akteynt_rig.gd` as the first bone-rig scaffold for the Abyss Empress. The hierarchy includes torso, head, rear hair, both arms, skirt panels, legs, and weapon bones. The controller provides procedural pose states for idle breathing, running, dash, attack, finisher, hurt recoil, and victory.

**Important limitation:** this is a rig scaffold, not the finished character. The current concept SVG has not yet been split into clean, independently pivoted artwork layers and bound to these bones; the rig is not yet used by the main fight scene. Godot runtime validation has not been performed in this environment.
