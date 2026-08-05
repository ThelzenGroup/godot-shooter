# Procedural Arena FPS

## Run

Open the project with Godot 4.7.1 standard (GDScript), then press Play. The
arena is generated entirely from primitive meshes and built-in materials.

## Controls

- **WASD** move, **Shift** sprint, **Space** jump
- **Mouse** look, **Left mouse** fire, **R** reload
- **1 / 2** switch pistol and rifle fire modes, **Esc** release the mouse

The player has no health regeneration. Waves 1–5 increase enemy count and
health; tune `MAX_WAVE`, spawn points, or the `ArenaEnemy` exports in
`scripts/main.gd` and `scripts/enemy.gd`.

A 3D first-person shooter built with [Godot 4](https://godotengine.org/) (GDScript).

## Requirements

- Godot 4.7 or newer (standard build, no .NET needed)

## Running

Open the project folder in the Godot editor and press F5, or from a shell:

```
godot --path . 
```

## Exporting

Install the matching export templates in the editor (Editor → Manage Export Templates), then:

```
godot --headless --path . --export-release "Windows Desktop" build/godot-shooter.exe
```
