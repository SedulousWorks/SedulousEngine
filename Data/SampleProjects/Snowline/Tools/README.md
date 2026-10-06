# Snowline's tools

The scripts that build Snowline through the editor's MCP tools. They talk to a running editor with
the project open and its MCP server on (`Sedulous.Tools.Editor --project <this project>
--mcp-port 7417`, the port `mcp.py` uses unless `MCP_PORT` says otherwise; it reads the token the
editor writes). None of this is game content. They are Raptor's Snowline tools, ported to this
engine's asset envelopes, schema keys and script API; the generators that make no engine data
(`terrain.py`, `blender/`) are Raptor's as they are. Each script's own header says what it makes,
what it needs first and how to call it. Generated files land in `generated/` (gitignored); the
imported copies live in the project's `Sources/`.

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
5. **First run**: `setup.py`: the title's thumbnails, the script assets (`script_create`, their
   sources a draft from `render.py --draft`), the course scenes to write into, the screens
   (`ui/*.sml`) and the manifest's start scene and Game script.
6. **Shared assets**: `effects.py` (the track marks), `particles.py` (spray, powder, the gem's
   sparkle, the avalanche), `ghosts.py` (the ghosts' materials), `gems.py` (the sparkle prefab),
   `gates.py` (the gate and finish prefabs) and `graph.py` (the rider's animation graph).
7. **The scenes**: `course.py <course>` writes a course's scene: the terrain and its vegetation, the
   course line, the rider, the gates, the gems, the kickers, a gap, the medal ghosts, the player's
   ghost, an avalanche and the camera, each placed by the course's rules (`RULES`).
8. **The scripts' asset ids**: `render.py Snowline Board ...` (every name in `scripts/`) fills each
   script's `{{Asset}}` placeholders with the ids now made, writes `Sources/<Name>.as` and
   compile-checks it (`script_validate`); `render.py --check` reports without writing.
9. **The title's pictures**: `thumbnails.py [course ...]`, a screenshot of each course's scene.

`snowgen.py` is the scene and prefab writer the rest use (every record starts from the running
editor's schema defaults; PaperKid's `pkgen.py`), and `mcp.py` the client they share.

## Playtests

`course.py <course> autopilot` makes the rider steer itself down the course line, for measuring a
course with `pie_run`; `spin=<stick>` and `grab` add a held spin and grab in the air. Regenerate
the scene without them before committing it.

To ride Forest or Ridge in a playtest the save needs a bronze on the course before. Keep a copy of
`Editor/Snowline.save.xml` and put it back afterwards; it holds the player's own times and ghosts.
