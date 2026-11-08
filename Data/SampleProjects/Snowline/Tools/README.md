# Snowline's tools

The scripts that build Snowline through the editor's MCP tools. None of this is game content. They
are Raptor's Snowline tools, ported to this engine's asset envelopes and schema keys; the game's
behaviours and its game script, scripts in Raptor's, are the game's Beef code here (`Code/`). The
generators that make no engine data (`terrain.py`, `blender/`) are Raptor's as they are. Each
script's own header says what it makes, what it needs first and how to call it. Generated files land
in `generated/` (gitignored); the imported copies live in the project's `Sources/`.

The editor they talk to is the project's OWN: the board, the gates, the finish, the gems, the
kickers, the gap, the avalanche, the medal ghosts and the player's, the camera, the track marks and
the gem's burst are the game's native behaviours (`snowline.board`, `snowline.gate`, ...), and the
stock editor does not link the game's code, so it knows no such components. So, first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/Snowline`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on the port `mcp.py` uses
   (7417, unless `MCP_PORT` says otherwise; it reads the token the editor writes):

   ```
   Data/SampleProjects/Snowline/Code/build/Debug_Linux64/SnowlineEditor/SnowlineEditor \
       --project Data/SampleProjects/Snowline --data-root Data --mcp-port 7417
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7417`).
3. Once, on a project whose scenes still carry script behaviours: `native.py` (below).
4. Then the scripts as before. After a change to the code, build again and reopen the project's
   editor before running them.

## The move from scripts

`native.py` is the move from scripts to the game's code, run once (Sky Hopper's, PaperKid's and
Lamplight's, with Snowline's table; Snowline has no level script). Every scene and prefab has each
Script component's behaviours replaced by the game's native behaviours on the same entity, with the
same values: each document read whole with `scene_read` or `prefab_read`, checked with
`scene_validate` and written back whole with `scene_write` or `prefab_write` (a prefab needs no
page). A course scene is converted in one read and one write, as any other: its terrain, heightfield
and splat are assets of their own, not in the document. Then the startup script setting is cleared
(the game's `SnowlineGame` runs the run), the script assets are deleted, their sources under
`Sources/` removed, and the project cooked. `--dry-run` says what it would change; `--keep-scripts`
stops before the retiring. Two of the scripts' properties are stored under another key, a field of
that name hiding the behaviour's own member: the kicker's `run` is `rampRun` and the avalanche's
`release` is `releaseAt`; a ghost's `medal` (0, 1, 2) is its `GhostMedal` (gold, silver, bronze).

## In order

1. **Models** (Blender 5, headless; the shared modelling kit is `blender/kit3d.py`):
   - `blender/props.py`: the pines and rocks, the gate poles and flags, the finish, the gems and
     the kicker, into `generated/Props`.
   - `blender/rider.py`: the rider on the board, rigged, with its clips, into `generated/Rider`.
2. **Project setup**: `controls.py` (the input map, made the project's default) and `look.py` (the
   environment and post profiles every course shares).
3. **Each course** (`Meadow`, `Forest`, `Ridge`):
   - `terrain.py <course>`: the heightfield, the splatmap, the layers' textures and the course line,
     from the course's table of rules (its bends, its groomed width, its forest, a shortcut, a gap).
   - `importall.py <course>`: imports those and the models, and makes the course's terrain asset.
4. **Sounds**: `sounds.py` (wind, the gem chime and the avalanche's rumble, generated; with
   `--kenney <dir> --music <dir>`, the Kenney sound effects and the two music tracks; with
   neither, what is already in `generated/Audio`).
5. **First run**: `setup.py`: the title's thumbnails, the course scenes to write into, the screens
   on the engine GUI (`ui/*.xml`, filled in by `render.py` with the thumbnails' ids, checked with
   `gui_validate`, styled by `ui/SnowlineSheet.css`, the project's GUI sheet) and the manifest's
   start scene (no startup script: the game's `SnowlineGame` runs the run). A re-import keeps the
   screens' ids, which the game's code (`Code/Snowline/src/Assets.bf`) pushes them by; it names the
   courses, the sounds and the gem's burst by id the same way.
6. **Shared assets**: `effects.py` (the track marks, with their `snowline.track_mark` behaviour),
   `particles.py` (spray, powder, the gem's sparkle, the avalanche), `ghosts.py` (the ghosts'
   materials), `gems.py` (the sparkle prefab, with its `snowline.expire` behaviour),
   `gates.py` (the gate and finish prefabs) and `graph.py` (the rider's animation graph).
7. **The scenes**: `course.py <course>` writes a course's scene: the terrain and its vegetation, the
   course line, the rider, the gates, the gems, the kickers, a gap, the medal ghosts, the player's
   ghost, an avalanche and the camera, each placed by the course's rules (`RULES`) with its native
   behaviour (the rider's `Board`, each gate's `Gate`, the `Finish`, each `Gem`, `Kicker`, the
   `Gap`, each medal's `Ghost`, the `PlayerGhost`, the `Avalanche` and the camera's
   `FollowCamera`).
8. **The title's pictures**: `thumbnails.py [course ...]`, a screenshot of each course's scene.

`snowgen.py` is the scene and prefab writer the rest use (every record starts from the running
editor's schema defaults; PaperKid's `pkgen.py`), and `mcp.py` the client they share.

A fresh build, in order: the Blender scripts; the project's own editor built and started as above;
then steps 2 to 8. The game's code names the courses, screens, sounds and the gem's burst by id
(`Code/Snowline/src/Assets.bf`), so a fresh build's new ids go there, and the project is built
again before it is played. A project whose scenes still carry scripts runs `native.py` once first,
then the rest as before.

## Playtests

`course.py <course> autopilot` makes the rider steer itself down the course line, for measuring a
course with `pie_run`; `spin=<stick>` and `grab` add a held spin and grab in the air. Regenerate
the scene without them before committing it.

To ride Forest or Ridge in a playtest the save needs a bronze on the course before. Keep a copy of
`Editor/Snowline.save.xml` and put it back afterwards; it holds the player's own times and ghosts.
