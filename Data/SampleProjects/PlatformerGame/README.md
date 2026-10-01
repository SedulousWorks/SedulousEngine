# Sky Hopper

A small 3D platformer, built entirely through the engine's MCP tools: the test of how far an
agent gets making a game with them, where every missing or wrong tool was fixed in the engine
as part of the work. It has also shipped to a Steam Deck through the container build
(`Code/Tools/SteamDeck/`).

## The game

Three levels of floating grass islands (Grassy Hills, Crab Crossing, Sky Climb): hop between
platforms, collect coins, stomp crabs and skulls from above, dodge spikes, and reach the flag.
A title screen with settings (master, music and effect volumes), an intro banner per level, a
pause menu, a level clear banner and a victory screen with totals. Falling respawns you on the
last safe ground.

Controls: WASD to move, Space to jump, Escape to pause; the arrows and Enter drive the menus. A
gamepad works throughout: the left stick to move (and the stick or d-pad in menus), A (cross)
to jump and confirm, Start (Options) to pause.

## Project layout

- `Project.xml`: the manifest: the start scene, the Game script, the input map, the UI theme
  and fonts, and the render resolution (1280x720, letterboxed).
- `Sources/`: the raw sources: the AngelScript scripts, the UI markup and theme, the fonts, the
  audio, and the kit's glTF models.
- `Content/`: the asset envelopes (`*.xasset`) and their sidecars.
- `export_presets.xml`: the Linux desktop and Steam Deck export targets.
- `CREDITS.md` and `Licenses/`: the third-party assets and their licences. The music by CodeManu
  is CC-BY 3.0 and must stay credited; everything else is CC0, OFL or Apache 2.0.
- `Cooked/`, `.cache/`, `Editor/`, `Dist/`: generated, and gitignored; the tools rebuild them.

Open the project from the editor's project manager.
