# godot-shooter

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
