# Masquerade's tools

The scripts that build Masquerade through the editor's MCP tools. They talk to a running editor
with the project open and its MCP server on (`Sedulous.Tools.Editor --project
Data/SampleProjects/Masquerade --seed --mcp-port 7419`, `--seed` giving a new project the font, the
sky and the primitives; `mcp.py` reads the token the editor writes; `MCP_PORT` picks another port).
They are Raptor's Masquerade tools, ported to this engine's asset envelopes, schema keys and script
API; the generators that make no engine data (`blender/`) are Raptor's as they are. Each script's
own header says what it makes, what it needs first and how to call it. Generated files land in
`generated/` (gitignored); the imported copies live in the project's `Sources/`.

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
2. **Project setup**: `controls.py` (the input map, made the project's default) and `look.py` (the
   night environment and the post profile every map shares, written when a map is).
3. **Scripts**: `importscripts.py` imports `ui/*.sml` and then `scripts/*.as`, filling each
   script's `{{UI:Hud}}`-style asset ids, and makes `Masquerade.as` (the game: the title, the
   HUD, pause, the results, the best round in the save) the startup script. The rest: a guest
   (`Guest`: wandering, talking and dancing to the cues; a bot is one too), the player (`Player`),
   the round (`Ball`: four hunters in a ring of targets, tagging, the mask's flare, the bots'
   hunting, the scores), the orchestra and its cues (`Orchestra`), and the camera (`CameraRig`).
4. **The maps**: `maps.py` writes each map's scene (the Palace, the Canal and the Gardens): the ground, walls and
   props with their colliders, the lights, the places guests go, the orchestra, 150 guests drawn
   as instances of their costumes (grouped by costume under the Crowd), the four hunters with a
   look per costume, the camera and the Ball; it bakes the map's navigation and makes the Palace
   the project's default scene.

`scenegen.py` (the scene document writer) and `mcp.py` (the MCP client) are the helpers the others
share.
