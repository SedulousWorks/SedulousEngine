# Sky Hopper's authoring tools

Sky Hopper is built through the engine editor's MCP tools. These scripts drive them; none of this
is game content. They are Raptor's Sky Hopper tools, ported to this engine's asset envelopes and
schema keys; the game's behaviours, scripts in Raptor's, are the game's Beef code here (`Code/`).

The editor they talk to is the project's OWN: the coins, enemies, hazards, pickups, the flag, the
player, the camera and the effects' timed lives are the game's native behaviours
(`skyhopper.coin`, `skyhopper.enemy`, ...), and the stock editor does not link the game's code, so
it knows no such components. So, first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/SkyHopper`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on the port `mcp.py` uses
   (7416, unless `MCP_PORT` says otherwise):

   ```
   Data/SampleProjects/SkyHopper/Code/build/Debug_Linux64/SkyHopperEditor/SkyHopperEditor \
       --project Data/SampleProjects/SkyHopper --data-root Data --mcp-port 7416
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7416`).
3. Once, on a project whose levels still carry script behaviours: `native.py` (below).
4. Then the scripts as before. After a change to the code, build again and reopen the project's
   editor before running them.

## The scripts

- `mcp.py`: a small MCP client (`python3 mcp.py http <tool> '<json args>'`, or `--list`).
- `native.py`: the move from scripts to the game's code, run once. Every scene and prefab (the
  levels and the FX prefabs) has each Script component's behaviours replaced by the game's native
  behaviours on the same entity, with the same values: each document read whole with `scene_read`
  or `prefab_read`, checked with `scene_validate` and written back whole with `scene_write` or
  `prefab_write` (a prefab needs no page). Then the startup script setting is cleared (the game's
  `SkyHopperGame` runs the run), the script assets are deleted, their sources under `Sources/`
  removed, and the project cooked. `--dry-run` says what it would change; `--keep-scripts` stops
  before the retiring. Its table maps each script asset to its native component and each script
  property to its field, so another sample reuses it with a table of its own.
- `skygen.py`: scene and prefab XML built from the running editor's `component_schema`, so a
  component record starts from the engine's own defaults (PaperKid's generator, with Sky Hopper's
  id namespace; an enum field takes its case by name).
- `levels.py`: levels 4 and 5 (Bee Meadow, Cloud Fortress) from pieces: grass islands with their
  tiles turned to face out, single cubes, crates, bricks, rock platforms, bridges, and coins,
  enemies, bees, saws, spiky balls, hearts, gems and the flag, each with its native behaviour. The
  sun, player, camera and scene settings come from Level3, so every level looks and plays alike.
  `levels.py Level4` writes one; a rewrite keeps the level's asset. The measures a route has to
  respect are in its docstring.
- `importui.py`: the game's screens on the engine GUI. `ui/` holds them: Title, Intro, Hud, Pause,
  Settings, LevelClear, GameOver, Victory and Fade (`.xml`), styled by `SkyHopperSheet.css`, the
  project's GUI sheet; the icons are the project's vector images (UI/Icons), shown by `<Image
  src="{guid}">`. It checks each with `gui_validate`, imports them into UI, makes the sheet the
  project's GUI sheet and cooks. A re-import keeps their ids, which the game's code
  (`Code/SkyHopper/src/Assets.bf`) pushes the screens by: `SkyHopperGame` pushes every one.
- `ik.py`: the hero's inverse kinematics in every level: foot IK (the rig's detached feet met by
  the shins, the pelvis Body) and an aim of the head (Neck, Head) on the Player, which drive the
  Character model's animator below it. The PlayerController behaviour turns the feet off in the
  air; the Coin behaviours point the head at the nearest coin within reach.
- `touch.py`: the touch controls in the input map (Controls): a floating stick on the left half,
  Jump in the bottom-right corner, Pause small in the top-left. It replaces only the map's touch
  bindings, so it can run again after a change.
- `toon.py`: the toon shading (`shaders/Toon.hlsl`, the project's Shaders/Toon), every material of
  the game put on it; `--pbr` puts them back on the built-in PBR.

Levels 1 to 3 were built earlier through the editor's tools, one entity at a time; their hearts
and gems were placed afterwards through `scene_read` and `scene_write`, and their behaviours moved
from scripts to the game's code by `native.py`.
