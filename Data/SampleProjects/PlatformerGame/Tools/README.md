# Sky Hopper's authoring tools

Sky Hopper is built through the engine editor's MCP tools (open the project with
`Sedulous.Tools.Editor --project <this project> --mcp-port 7416`, the port `mcp.py` uses unless
`MCP_PORT` says otherwise). These scripts drive them; none of this is game content. They are
Raptor's Sky Hopper tools, ported to this engine's asset envelopes, schema keys and script API.

- `mcp.py`: a small MCP client (`python3 mcp.py http <tool> '<json args>'`, or `--list`).
- `skygen.py`: scene and prefab XML built from the running editor's `component_schema`, so a
  component record starts from the engine's own defaults (PaperKid's generator, with Sky
  Hopper's id namespace, and bool and string script property overrides).
- `levels.py`: levels 4 and 5 (Bee Meadow, Cloud Fortress) from pieces: grass islands with their
  tiles turned to face out, single cubes, crates, bricks, rock platforms, bridges, and coins,
  enemies, bees, saws, spiky balls, hearts, gems and the flag. The sun, player, camera and scene
  settings come from Level3, so every level looks and plays alike. `levels.py Level4` writes one;
  a rewrite keeps the level's asset. The measures a route has to respect are in its docstring.
- `ik.py`: the hero's inverse kinematics in every level: foot IK (the rig's detached feet met by
  the shins, the pelvis Body) and an aim of the head (Neck, Head) on the Player, which drive the
  Character model's animator below it. PlayerController turns the feet off in the air; Coin.as
  points the head at the nearest coin within reach.

Levels 1 to 3 were built earlier through the editor's tools, one entity at a time; their hearts
and gems were placed afterwards through `scene_read` and `scene_write`.
