# The Final Boss

**A 2D top-down dark-fantasy action prototype built with Godot 4**, designed with Android touch input in mind.

## Current prototype
- Move using **WASD** or **arrow keys** on desktop.
- **Space** to attack when close to Akteynt.
- **E** to use Abyss Nova (4-second cooldown).
- Player and boss health bars.
- Akteynt follows the player and deals contact damage.
- On-screen touch zones are included as an early mobile-control prototype.

## Open the project
1. Install **Godot 4.x**.
2. In the Project Manager, choose **Import**.
3. Select this repository folder and open `project.godot`.
4. Press **Run Project**.

## Android build
This repository does not yet contain a verified APK. Android export requires Godot export templates and Android SDK/JDK setup. A GitHub Actions workflow can be added after confirming the project imports and runs correctly.

## Structure
- `project.godot` — Godot project settings
- `scenes/main.tscn` — main scene
- `scripts/main.gd` — prototype gameplay and drawing

## Roadmap
1. Validate the prototype in Godot 4.
2. Improve touch controls and combat feedback.
3. Add character art, animation, audio, and boss phases.
4. Configure reproducible Android APK builds.
