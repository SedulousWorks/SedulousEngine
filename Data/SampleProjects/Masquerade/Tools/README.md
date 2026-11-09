# Masquerade's tools

The scripts that build Masquerade through the editor's MCP tools. They are Raptor's Masquerade
tools, ported to this engine's asset envelopes and schema keys; the game's behaviours and its game
script, scripts in Raptor's, are the game's Beef code here (`Code/`). The generators that make no
engine data (`blender/`) are Raptor's as they are. Each script's own header says what it makes, what
it needs first and how to call it. Generated files land in `generated/` (gitignored); the imported
copies live in the project's `Sources/`.

The editor they talk to is the project's OWN: the guests, the player, the camera rig, the ball and
the orchestra are the game's native behaviours (`masquerade.guest`, `masquerade.ball`, ...), and the
stock editor does not link the game's code, so it knows no such components. So, first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/Masquerade`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on the port `mcp.py` uses
   (7419, unless `MCP_PORT` says otherwise; it reads the token the editor writes), `--seed` giving
   a new project the font, the sky and the primitives:

   ```
   Data/SampleProjects/Masquerade/Code/build/Debug_Linux64/MasqueradeEditor/MasqueradeEditor \
       --project Data/SampleProjects/Masquerade --data-root Data --seed --mcp-port 7419
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7419`).
3. Once, on a project whose scenes still carry script behaviours: `native.py` (below).
4. Then the scripts as before. After a change to the code, build again and reopen the project's
   editor before running them.

## The move from scripts

`native.py` is the move from scripts to the game's code, run once (Sky Hopper's, PaperKid's,
Lamplight's and Snowline's, with Masquerade's table; Masquerade has no level script). Every scene
and prefab has each Script component's behaviours replaced by the game's native behaviours on the
same entity, with the same values: each document read whole with `scene_read` or `prefab_read`,
checked with `scene_validate` and written back whole with `scene_write` or `prefab_write` (a prefab
needs no page). Then the startup script setting is cleared (the game's `MasqueradeGame` runs the
run), the script assets are deleted, their sources under `Sources/` removed, and the project
cooked. `--dry-run` says what it would change; `--keep-scripts` stops before the retiring.

## In order

1. **Models** (Blender 5, headless; the shared modelling kit is `blender/kit3d.py`):
   - `blender/palace.py`: the palace kit on its 2 m grid (flagstones, marble, wall, window, pier,
     column, balustrade, fountain, lantern, planter, bench, chandelier, the orchestra's dais), into
     `generated/Palace`.
   - `blender/canal.py`: the canal kit (paving, the quays' coping, water, a walkable bridge, house
     fronts in three colours with and without doors, mooring poles, a gondola with its gondolier,
     a wellhead, a mask stall), into `generated/Canal`.
   - `blender/gardens.py`: the garden kit (lawn, gravel, hedge and its corner, a statue, an urn),
     into `generated/Gardens`; the Gardens take the rest from the palace kit.
   - `blender/guest.py`: the guests, six costumes (three gowns, three coats) on the one rig of
     `blender/figure.py`, each with the clips Idle, Walk, Talk and Dance, into `generated/Guests`.
   - `importmodels.py`: imports them, the kits into `Models/Palace`, `Models/Canal` and
     `Models/Gardens` and the guests into `Models/Guests`, a group per model.
   - `shaders.py`: imports `shaders/Mask.hlsl` and `shaders/Silk.hlsl` and puts every costume's
     mask, silk and cloth materials on them (after `importmodels.py`, which makes them afresh).
2. **Project setup**: `controls.py` (the input map, made the project's default), `look.py` (the
   night environment and the post profile every map shares, written when a map is) and
   `sounds.py` (the orchestra's three pieces and the round's sounds, generated and imported into
   `Audio/`; before the scripts, which name them, and the maps, whose crowd plays the murmur).
3. **Screens**: `glyphs.py` first (the pad's button glyphs the prompts show, drawn and imported into
   `UI/Glyphs`) and `portraits.py` (each costume's head and shoulders, rendered by `blender/guest.py`
   and imported into `UI/Portraits`, for the HUD's mark); then `importui.py` checks the screens
   with `gui_validate` and imports them (`ui/*.xml` on the engine GUI, over
   `ui/MasqueradeSheet.css`, made the project's GUI sheet), filling each document's and the
   sheet's `{{Texture:PadSouth}}`-style asset ids. A re-import keeps their ids, which the game's
   code (`Code/Masquerade/src/Assets.bf`) pushes the screens by; it names the maps, the portraits,
   the sounds and the music by id the same way.
4. **The maps**: `maps.py` writes each map's scene (the Palace, the Canal and the Gardens): the ground, walls and
   props with their colliders, the lights, the places guests go, the orchestra, 150 guests drawn
   as instances of their costumes (grouped by costume under the Crowd), the four hunters with a
   look per costume, the camera and the Ball, each with its native behaviour (every guest's and
   bot's `Guest`, the player's `Player`, the camera's `CameraRig`, the dais's `Orchestra` and the
   `Ball`), and the hunter prefab a joining player gets (with its `Player`); it bakes the map's
   navigation and makes the Palace the project's default scene.
5. **Export**: `presets.py` writes the export presets (Snowline's: the Linux desktop, the Steam
   Deck and the Web, each shipping the credits).

A fresh build, in order: the Blender scripts; the project's own editor built and started as above;
then `importmodels.py`, `shaders.py`, `controls.py`, `look.py`, `sounds.py`, `glyphs.py`,
`portraits.py`, `importui.py`, `maps.py` and `presets.py`. The game's code names the maps, screens,
portraits and sounds by id (`Code/Masquerade/src/Assets.bf`), so a fresh build's new ids go there,
and the editor is built again before playing. A project whose scenes still carry scripts runs
`native.py` once first, then the rest as before.

`scenegen.py` (the scene document writer) and `mcp.py` (the MCP client) are the helpers the others
share.
