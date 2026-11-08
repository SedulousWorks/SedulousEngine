# The gallery's tools

The scripts that build the Shader Gallery through the editor's MCP tools. They talk to a running
editor with the project open and its MCP server on (`mcp.py` reads the token the editor writes;
`MCP_PORT` picks another port than 7418).

That editor is the project's OWN: the camera's Gallery behaviour (`shadergallery.gallery`) is the
game's code in `Code/`, and the stock editor does not link it, so it knows no such component. So,
first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/ShaderGallery`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on:

   ```
   Data/SampleProjects/ShaderGallery/Code/build/Debug_Linux64/ShaderGalleryEditor/ShaderGalleryEditor \
       --project Data/SampleProjects/ShaderGallery --data-root Data --mcp-port 7418
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7418`; a new project also takes `--seed`, giving it the font, the sky and the three
   primitives the hall uses).
3. Then the scripts. After a change to the code (`lessons.py` included, which `ui.py` writes into
   `Code/`), build again and reopen the project's editor before running them.

## In order

1. `textures.py`: the generated textures (the tiles, the dissolve's noise) and ambientCG's Rock030
   (downloaded once), into `generated/` (gitignored).
   `blender --background --factory-startup --python blender/exhibits.py -- generated/Exhibits`:
   the knot, the rock, the water and the flag; then `importmodels.py` imports them into Models.
2. `controls.py`: the input map (Controls), made the project's default. Its action names are the
   ones the Gallery behaviour reads.
3. `ui.py`: the lesson list on the engine GUI (`ui/Gallery.xml` over `ui/GallerySheet.css`) and
   the game code's lesson table (`../Code/ShaderGallery/src/Lessons.bf`), written from the lessons
   table (a change to the table is a build, as above); then `importui.py` checks the list with
   `gui_validate`, imports both and makes the sheet the project's GUI sheet.
4. `shaders.py`: each lesson's shader (`shaders/NN_Name.hlsl`, checked with `shader_validate`,
   imported into Shaders) and its material (Materials/<Name>, put on the shader with
   `material_set_shader`, its parameters and textures set), then a cook.
5. `hall.py`: the hall's materials (Materials/Hall) and the hall (scene Hall), a plinth, exhibit
   and viewpoint per lesson (and a flagpole for the flag), and the camera with its Gallery
   behaviour (its starting yaw and pitch, and the list's document), made the project's default
   scene.

`lessons.py` is the table the others read: a lesson is a row there and its `.hlsl`. `scenegen.py`
(the scene document writer), `materialvalues.py` (a material's values, textures and modes by
property name) and `mcp.py` (the MCP client) are the helpers the others share.

## The port

These are Raptor's gallery tools, ported: `mcp.py`, `scenegen.py`, `controls.py` and
`importui.py` take the same changes as Lamplight's here (short asset type names, this engine's
input map and settings layout), and `materialvalues.py` finds the material's fields one level
deeper. The camera's behaviour, a script in Raptor's, is the game's Beef code here (`Code/`), so
`ui.py` writes its lesson table rather than a script and `hall.py` adds it as a component.
`generated/` was filled from Raptor's built copies (its `Sources/` textures and exhibits) rather
than by running `textures.py` and Blender again; either gives the same files.
