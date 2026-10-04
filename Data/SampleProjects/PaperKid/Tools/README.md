# PaperKid's authoring tools

PaperKid is built through the engine editor's MCP tools (open the project with
`Sedulous.Tools.Editor --project <this project> --mcp-port 7415`, the port `mcp.py` uses unless
`MCP_PORT` says otherwise). These scripts drive them; none of this is game content. They are
Raptor's PaperKid tools, ported to this engine's asset envelopes, schema keys and script API.

- `mcp.py`: a small MCP client (`python3 mcp.py http <tool> '<json args>'`, or `--list`).
- `pkgen.py`: scene and prefab XML built from the running editor's `component_schema`, so a
  component record starts from the engine's own defaults; `assets()` lists the project's assets
  by short type name.
- `setup.py <raw-dir>`: a fresh project's first run, what the rest builds on: the fonts and the
  audio imported from `<raw-dir>` (the files `CREDITS.md` lists), the primitive meshes, the input
  map, the minimap's render texture, the screens and their theme (from `<raw-dir>` too; once
  imported, `Sources/` holds them, the HUD's minimap id filled in), the script assets, a
  navigation zone per block, the scenes the blocks are written into, the manifest's settings and
  the export presets. A rerun finds everything by name and changes nothing.
- `kit.py`: the blockout kit's prefabs (houses, road, kerb, cars, pedestrian, junk, newspaper,
  delivery zone, the throw's guides, the effects' prefabs); writes `kit.json` (prefab name ->
  guid).
- `block.py`: the five blocks (one generator, `town()`, sized by the ring road's distance from
  the middle; the `BLOCKS` table is the difficulty ramp) and the Start scene. `block.py Block3`
  writes just that one. Bake a block's navigation after writing it (`page_open` the block, then
  `navigation_bake`). The look (`ENVIRONMENT`, `POST`) is written to two shared profiles,
  `Profiles/PaperKid Environment` and `Profiles/PaperKid Post`, which every scene's settings name;
  `asset_cook` after changing it.
- `fx.py`: the particle effects (Confetti, Sparkle, Dust, Puff) and the soft round sprite they
  use, written through `asset_data_write` from the engine's own new effect; `kit.py` wraps each in
  an `Fx*` prefab (the effect plus `Fx.as`, which removes it once the burst has played), and the
  scripts spawn those where things happen.
- `anim.py`: the property-animation clips (the marker's bob, the porch mat's pulse) and the
  throw guides' glowing unlit material, written through `asset_data_write`; `kit.py` puts them on
  the delivery zone's pieces and the AimDot and TargetRing prefabs.
- `scripts/*.as` + `render.py`: the game's scripts with `{{AssetName}}` placeholders (a prefab
  sharing a script's name is `{{Prefab:Name}}`); `render.py <Name>...` fills in the asset ids,
  writes `Sources/<Name>.as` and compile-checks it. `--check` compiles without writing; `--draft`
  writes with a nil id for an asset not made yet.
- `drive.py`: a closed-loop playtest of Block1 over `pie_run` (laps the ring, throws at each zone
  once); start PIE and New game first.
- `look.py`: measures the 3D image of the title and the start of Block1 (brightness, crushed and
  clipped pixels), for tuning the shared look by numbers.

A fresh build, in order: `setup.py <raw-dir>`, `render.py --draft` over every script (so the
kit's prefabs find their properties), `fx.py`, `anim.py`, `kit.py`, `render.py` over every script
again (now with the prefabs' ids), `block.py`, then bake each block's navigation.
