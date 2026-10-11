# Lamplight's tools

The scripts that build Lamplight through the editor's MCP tools. They talk to a running editor with
the project open and its MCP server on (`Sedulous.Tools.Editor --project <this project>
--mcp-port 7417`, the port `mcp.py` uses unless `MCP_PORT` says otherwise; it reads the token the
editor writes). They are Raptor's Lamplight tools, ported to this engine's asset envelopes, schema
keys and script API; the generators that make no engine data (`blender/`) are Raptor's as they
are. Each script's own header says what it makes, what it needs first and how to call it.
Generated files land in `generated/` (gitignored); the imported copies live in the project's
`Sources/`.

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
3. **Scripts**: `importscripts.py` imports `ui/*.sml` and then `scripts/*.as`, filling each
   script's `{{UI:Title}}`-style asset ids, and makes `Lamplight.as` (the game: title, HUD,
   pause, results, saves) the startup script. The rest: the thief (`Thief`, `Footsteps`,
   `LightMeter`), the guard (`Guard`, and his `GuardMeter`), the quarter-turn camera
   (`CameraRig`), the wall that fades out of the camera's way (`CutawayWall`), lamps (`Lamp`),
   doors and gates (`Door`), the pebble (`Pebble`), loot and targets (`Loot`), the exit (`Exit`)
   and checkpoints (`Checkpoint`). Then `prefabs.py` writes the prefabs that use them (the
   pebble).
4. **The levels**: `level.py` writes each level's scene from its table in `levels.py` (the
   Gardens, the Stable Yard, and the test Room): ground, wall runs and their openings, props,
   lamps, guards and their rounds, loot, the target, the exit, checkpoints, rain; it bakes each
   level's navigation, and makes the first level the project's default scene.

`scenegen.py` (the scene document writer) and `mcp.py` (the MCP client) are the helpers the others
share.
