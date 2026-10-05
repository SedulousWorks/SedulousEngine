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
  audio imported from `<raw-dir>` (the files `CREDITS.md` lists), the Blender scripts' models
  (`KidBike.glb` into `Models/KidBike`, the town's `<Name>Model.glb` into `Models/Town`), the
  primitive meshes, the input map, the minimap's render texture, the screens and their theme
  (from `<raw-dir>` too; once imported, `Sources/` holds them, the HUD's minimap id filled in),
  the script assets, a navigation zone per block, the scenes the blocks are written into, the
  manifest's settings and the export presets. A rerun finds everything by name and changes nothing.
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
  writes with a nil id for an asset not made yet. An animation clip is `{{Clip:Name}}`. A name
  several assets answer to (each model's Walk clip) is refused: such an asset is a behaviour
  property, set where the prefab or scene is built.
- `blender/kit3d.py`: the modelling kit the Blender scripts share (bevelled boxes, tubes, spheres
  and tori with palette materials, parts rigid on bones, a two-bone IK solve, static export, a
  preview studio).
- `blender/town.py`: the houses, the cars and the street furniture (bin, hydrant, cone, newspaper),
  each written as `<Name>Model.glb` and imported as `Models/Town/<Name>Model`; `kit.py` keeps each
  prefab's colliders and behaviours and shows its model in place of the blockout's primitives.
- `blender/pedestrian.py`: the pedestrian, rigged with a Walk clip (two 0.65 m steps a second),
  imported as `Models/Town/PedestrianModel`; `Pedestrian.as` turns the figure toward where it walks
  and plays Walk at its pace.
- `blender/animals.py`: the dog and the cat, from one four-legged builder and their proportions,
  each with Walk, Idle, Sit, LieDown and its own clip (Sniff, Groom), every clip starting and ending
  in the same standing pose; imported as `Models/Town/DogModel` and `Models/Town/CatModel`. The Walk
  carries its root one stride forward a loop, and its clip asset extracts that as root motion
  (horizontal): the model's animator moves the pet (Entity mode, aimed at the Pet entity by
  `block.py` through `pkgen.root_motion_entity`). On the
  title backdrop `Pet.as` steers each about its lawn and picks what it does at each spot, and
  `Stroller.as` sends the cars and the walkers across (`block.py`'s `start()`).
- `blender/kid_bike.py`: the kid on his bike, modelled, rigged and animated in Blender (the
  Ride and Throw clips) and written as `KidBike.glb`; run it with Blender in the background
  (`blender --background --factory-startup --python blender/kid_bike.py -- <out dir> [preview]`),
  import the .glb as `Models/KidBike`, and `block.py` places its prefab on the Bike entity.
  `Bike.as` plays Ride at the bike's speed and Throw on a throw.
- `drive.py`: a closed-loop playtest of Block1 over `pie_run` (laps the ring, throws at each zone
  once); start PIE and New game first.
- `look.py`: measures the 3D image of the title and the start of Block1 (brightness, crushed and
  clipped pixels), for tuning the shared look by numbers.

A fresh build, in order: the Blender scripts, writing their `.glb` files into `<raw-dir>`, then
`setup.py <raw-dir>`, `render.py --draft` over every script (so the
kit's prefabs find their properties), `fx.py`, `anim.py`, `kit.py`, `render.py` over every script
again (now with the prefabs' ids), `block.py`, then bake each block's navigation.
