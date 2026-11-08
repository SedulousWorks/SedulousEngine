# Lamplight's tools

The scripts that build Lamplight through the editor's MCP tools. They are Raptor's Lamplight tools,
ported to this engine's asset envelopes and schema keys; the game's behaviours and its game script,
scripts in Raptor's, are the game's Beef code here (`Code/`). The generators that make no engine
data (`blender/`) are Raptor's as they are. Each script's own header says what it makes, what it
needs first and how to call it. Generated files land in `generated/` (gitignored); the imported
copies live in the project's `Sources/`.

The editor they talk to is the project's OWN: the thief, his steps, his light meter, the camera
rig, the guards, doors, lamps, the torches' flicker, loot, the alarm, checkpoints, exits, pebbles
and the cutaway walls are the game's native behaviours (`lamplight.thief`, `lamplight.guard`, ...),
and the stock editor does not link the game's code, so it knows no such components. So, first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/Lamplight`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on the port `mcp.py` uses
   (7417, unless `MCP_PORT` says otherwise; it reads the token the editor writes):

   ```
   Data/SampleProjects/Lamplight/Code/build/Debug_Linux64/LamplightEditor/LamplightEditor \
       --project Data/SampleProjects/Lamplight --data-root Data --mcp-port 7417
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7417`).
3. Once, on a project whose scenes still carry script behaviours: `native.py` (below).
4. Then the scripts as before. After a change to the code, build again and reopen the project's
   editor before running them.

## The move from scripts

`native.py` is the move from scripts to the game's code, run once (Sky Hopper's and PaperKid's,
with Lamplight's table; Lamplight has no level script). Every scene and prefab has each Script
component's behaviours replaced by the game's native behaviours on the same entity, with the same
values: each document read whole with `scene_read` or `prefab_read`, checked with `scene_validate`
and written back whole with `scene_write` or `prefab_write` (a prefab needs no page). Then the
startup script setting is cleared (the game's `LamplightGame` runs the run), the script assets are
deleted, their sources under `Sources/` removed, and the project cooked. `--dry-run` says what it
would change; `--keep-scripts` stops before the retiring.

## In order

1. **Models** (Blender 5, headless; the shared modelling kit is `blender/kit3d.py`):
   - `blender/manor.py`: the manor kit on its 2 m grid (wall, doorway, door, corner post, floor)
     and the furniture (table, oil lamp), into `generated/Manor`.
   - `blender/grounds.py`: the grounds kit (hedge and its corner, the garden wall and its piers,
     an iron gate, a lantern post, grass, gravel, flagstone and cobble tiles, a hay bale, a
     trough), into `generated/Grounds`; `blender/loot.py`: the purse, candlestick, key and
     ledger, into `generated/Loot`.
   - `blender/thief.py`: the thief, rigged, with its clips (Idle, Walk, Sneak, Run, Crouch), into
     `generated/Thief`; `blender/guard.py`: the guard with his lantern (Idle, Walk, Run, Look),
     into `generated/Guard`. Both stand on `blender/figure.py`'s shared rig and gaits.
   - `importmodels.py`: imports them, the kits into `Models/Manor` and `Models/Grounds`, the loot
     into `Models/Loot`, the thief and the guard into `Models`, a group per model. Without
     Blender, copy the built models from `Sources/` into `generated/<Folder>/` by those groups.
2. **Project setup**: `setup.py` (the UI font, made the default, and the Sphere primitive),
   `controls.py` (the input map, made the project's default), `look.py` (the night environment
   and the post profile every level shares), `materials.py` (the put-out lamp's and the
   pebble's), `surfaces.py` (what floors are made of, as physical materials),
   `sounds.py` (footsteps on each surface, the loot's jingle and chime, the rain, all generated)
   and `effects.py` (the rain). `graph.py` writes the thief's and the guard's animation graphs.
3. **Screens and prefabs**: `importui.py` imports the screens on the engine GUI and the guards'
   meter (`ui/*.xml`, styled by `ui/LamplightSheet.css`, the project's GUI sheet). A re-import
   keeps their ids, which the game's code (`Code/Lamplight/src/Assets.bf`) pushes the screens by;
   it names the levels and the sounds it plays by id the same way. Then `prefabs.py` writes the
   prefabs (the pebble, with its `lamplight.pebble` behaviour).
4. **The levels**: `level.py` writes each level's scene from its table in `levels.py` (the
   Gardens, the Stable Yard, the Ground Floor, the Cellars, the Upper Floor and the test Room):
   ground, wall runs and their openings, props, lamps, guards and their rounds, loot, the target,
   the exit, checkpoints, rain, each with its native behaviour (the thief's `Thief`, `Footsteps`
   and `LightMeter`, the camera's `CameraRig`, each guard's `Guard`, a `CutawayWall` on every
   wall piece, `Lamp`, `Flicker`, `Door`, `Loot`, `Alarm`, `Exit` and `Checkpoint`); it bakes
   each level's navigation, and makes the first level the project's default scene.

A fresh build, in order: the Blender scripts; the project's own editor built and started as above;
then `setup.py`, `controls.py`, `look.py`, `materials.py`, `surfaces.py`, `sounds.py`,
`effects.py`, `graph.py`, `importui.py`, `prefabs.py` and `level.py`. The game's code names the
levels, screens and sounds by id (`Code/Lamplight/src/Assets.bf`), so a fresh build's new ids go
there, and the editor is built again before playing. A project whose scenes still carry scripts
runs `native.py` once first, then the rest as before.

`scenegen.py` (the scene document writer) and `mcp.py` (the MCP client) are the helpers the others
share.
