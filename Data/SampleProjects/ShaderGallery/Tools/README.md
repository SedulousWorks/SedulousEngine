# The gallery's tools

The scripts that build the Shader Gallery through the editor's MCP tools. They talk to a running
editor with the project open and its MCP server on (`Sedulous.Tools.Editor --project
Data/SampleProjects/ShaderGallery --seed --mcp-port 7418`, `--seed` giving a new project the font,
the sky and the three primitives the hall uses; `mcp.py` reads the token the editor writes;
`MCP_PORT` picks another port).

## In order

1. `textures.py`: the generated textures (the tiles, the dissolve's noise) and ambientCG's Rock030
   (downloaded once), into `generated/` (gitignored).
   `blender --background --factory-startup --python blender/exhibits.py -- generated/Exhibits`:
   the knot, the rock, the water and the flag; then `importmodels.py` imports them into Models.
2. `controls.py`: the input map (Controls), made the project's default.
3. `ui.py`: the lesson list (`ui/Gallery.sml`) and the camera's script (`scripts/Gallery.as`, from
   `scripts/Gallery.as.in`), written from the lessons table; then `importscripts.py` imports both.
4. `shaders.py`: each lesson's shader (`shaders/NN_Name.hlsl`, checked with `shader_validate`,
   imported into Shaders) and its material (Materials/<Name>, put on the shader with
   `material_set_shader`, its parameters and textures set), then a cook.
5. `hall.py`: the hall's materials (Materials/Hall) and the hall (scene Hall), a plinth, exhibit
   and viewpoint per lesson (and a flagpole for the flag), made the project's default scene.

`lessons.py` is the table the others read: a lesson is a row there and its `.hlsl`. `scenegen.py`
(the scene document writer), `materialvalues.py` (a material's values, textures and modes by
property name) and `mcp.py` (the MCP client) are the helpers the others share.

## The port

These are Raptor's gallery tools, ported: `mcp.py`, `scenegen.py`, `controls.py` and
`importscripts.py` take the same changes as Lamplight's here (short asset type names, this engine's
input map and settings layout), `materialvalues.py` finds the material's fields one level deeper,
and `scripts/Gallery.as.in` is written in this engine's AngelScript API. `generated/` was filled
from Raptor's built copies (its `Sources/` textures and exhibits) rather than by running
`textures.py` and Blender again; either gives the same files.
