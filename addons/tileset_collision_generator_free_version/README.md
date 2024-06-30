# Tileset Collision Generator (free version)

A plugin for the Godot Editor for automatically generating collision polygons for all tiles in tilesets. The algorithm determines if a pixel can be collided with via the alpha channel of the pixel. Everything that has an alpha value >= 40% is considered to be something that can be collided with.

* Collision polygons can be adjusted after they have been automatically generated.
* The tools only generates collision polygons for tiles which have no collision polygons yet.
* The implementation uses multithreading for parallel generation of collision polygons for tiles.
* The polygons are put on physics layer 0.

This free version only generates collision polygons for images where the width is <= 240 pixel and height <= 240 pixel.
The full version (which generates collision polygons for all images) can be bought [here](https://sanjox.itch.io/godot-collision-generator).

## How to install

### Via AssetLib

1. Open the plugin in the AssetLib.
2. Download it.
3. Activate the plugin under Project -> Project Settings... -> Plugins by checking "Enable".

### From repository

1. Download the files.
2. Move the folder "addons/tileset_collision_generator_free_version" into the folder "addons/" in your project.
   If the "addons" folder doesn't exist yet, create it first.
3. Activate the plugin under Project -> Project Settings... -> Plugins by checking "Enable".

## How to use

1. Select a TileSet file in the file browser in the Godot Editor.
2. Open the command palette (Editor -> Command Palette... or Ctrl+Shift+P) and run the command "Generate collision".

You can check out the generated collision polygons by opening the tile set, activating "Paint" and selecting the first physics layer under "Paint Properties".

## Feedback

You can send feedback to jonas.aschenbrenner@gmail.com.
