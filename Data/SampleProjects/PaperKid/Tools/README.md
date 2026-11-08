# PaperKid's authoring tools

PaperKid is built through the engine editor's MCP tools. These scripts drive them; none of this is
game content. They are Raptor's PaperKid tools, ported to this engine's asset envelopes and schema
keys; the game's behaviours and its block rules, scripts in Raptor's, are the game's Beef code here
(`Code/`).

The editor they talk to is the project's OWN: the bike, the camera, the minimap's markers, the
cars, walkers, obstacles, porches, papers, bursts, pets and the title's strollers are the game's
native behaviours (`paperkid.bike`, `paperkid.obstacle`, ...), and each block's rules its native
level (`paperkid.level`, a scene settings block); the stock editor does not link the game's code,
so it knows no such components. So, first:

1. Open the project in the stock editor (`Sedulous.Tools.Editor --project
   Data/SampleProjects/PaperKid`) and run Project > Build Project (an agent: `project_build`).
   The first build compiles the engine and takes minutes.
2. Start the editor it built, on the project, with the MCP server on the port `mcp.py` uses
   (7415, unless `MCP_PORT` says otherwise):

   ```
   Data/SampleProjects/PaperKid/Code/build/Debug_Linux64/PaperKidEditor/PaperKidEditor \
       --project Data/SampleProjects/PaperKid --data-root Data --mcp-port 7415
   ```

   (or Project > Open With This Build, `editor_relaunch`, from the stock one started with
   `--mcp-port 7415`).
3. Once, on a project whose scenes still carry script behaviours or a level script: `native.py`
   (below).
4. Then the scripts as before. After a change to the code, build again and reopen the project's
   editor before running them.

## The scripts

- `mcp.py`: a small MCP client (`python3 mcp.py http <tool> '<json args>'`, or `--list`).
- `native.py`: the move from scripts to the game's code, run once (Sky Hopper's, with PaperKid's
  table). Every scene and prefab has each Script component's behaviours replaced by the game's
  native behaviours on the same entity, with the same values, and each block's level script (its
  scene's `script` settings: the Level class and its overrides) replaced by the `paperkid.level`
  settings block, turned on, with the same numbers: each document read whole with `scene_read` or
  `prefab_read`, checked with `scene_validate` and written back whole with `scene_write` or
  `prefab_write` (a prefab needs no page). Then the startup script setting is cleared (the game's
  `PaperKidGame` runs the run), the script assets are deleted, their sources under `Sources/`
  removed, and the project cooked. `--dry-run` says what it would change; `--keep-scripts` stops
  before the retiring.
- `pkgen.py`: scene and prefab XML built from the running editor's `component_schema`, so a
  component record or a settings block (the level's among them) starts from the engine's own
  defaults; `assets()` lists the project's assets by short type name.
- `setup.py <raw-dir>`: a fresh project's first run, what the rest builds on: the fonts and the
  audio imported from `<raw-dir>` (the files `CREDITS.md` lists), the Blender scripts' models
  (`KidBike.glb` into `Models/KidBike`, the town's `<Name>Model.glb` into `Models/Town`), the
  primitive meshes, the input map, the minimap's render texture, the screens and their theme
  (from `<raw-dir>` too; once imported, `Sources/` holds them, the HUD's minimap id filled in),
  a navigation zone per block, the scenes the blocks are written into, the manifest's settings (no
  startup script: the game's code runs the run) and the export presets. A rerun finds everything by
  name and changes nothing.
- `kit.py`: the blockout kit's prefabs (houses, road, kerb, cars, pedestrian, junk, newspaper,
  delivery zone, the throw's guides, the effects' prefabs); writes `kit.json` (prefab name ->
  guid).
- `block.py`: the five blocks (one generator, `town()`, sized by the ring road's distance from
  the middle; the `BLOCKS` table is the difficulty ramp, each block's numbers its `paperkid.level`
  block) and the Start scene. `block.py Block3`
  writes just that one. Bake a block's navigation after writing it (`page_open` the block, then
  `navigation_bake`). The look (`ENVIRONMENT`, `POST`) is written to two shared profiles,
  `Profiles/PaperKid Environment` and `Profiles/PaperKid Post`, which every scene's settings name;
  `asset_cook` after changing it.
- `fx.py`: the particle effects (Confetti, Sparkle, Dust, Puff) and the soft round sprite they
  use, written through `asset_data_write` from the engine's own new effect; `kit.py` wraps each in
  an `Fx*` prefab (the effect plus the `Fx` behaviour, which removes it once the burst has
  played), and the game's code spawns those where things happen.
- `anim.py`: the property-animation clips (the marker's bob, the porch mat's pulse) and the
  throw guides' glowing unlit material, written through `asset_data_write`; `kit.py` puts them on
  the delivery zone's pieces and the AimDot and TargetRing prefabs.
- `touch.py`: the touch controls in the input map (Controls): a floating stick on the left half,
  Throw in the bottom-right corner, Pause small in the top-left. It replaces only the map's touch
  bindings, so it can run again after a change.
- `ui/*.xml` + `ui/PaperKidSheet.css` + `importui.py`: the screens on the engine GUI (Title, Hud,
  Cleared, Failed, GameOver, Pause, Settings) and the sheet that gives them the morning edition's
  look, the project's GUI sheet; `importui.py` checks each with `gui_validate`, imports them and
  cooks. A re-import keeps their ids, which the game's code (`Code/PaperKid/src/Assets.bf`) pushes
  the screens by: `PaperKidGame` pushes every one.
- `blender/kit3d.py`: the modelling kit the Blender scripts share (bevelled boxes, tubes, spheres
  and tori with palette materials, parts rigid on bones, a two-bone IK solve, static export, a
  preview studio).
- `blender/town.py`: the houses, the cars and the street furniture (bin, hydrant, cone, newspaper),
  each written as `<Name>Model.glb` and imported as `Models/Town/<Name>Model`; `kit.py` keeps each
  prefab's colliders and behaviours and shows its model in place of the blockout's primitives.
- `blender/pedestrian.py`: the pedestrian, rigged with a Walk clip (two 0.65 m steps a second),
  imported as `Models/Town/PedestrianModel`; the `Pedestrian` behaviour turns the figure toward
  where it walks and plays Walk at its pace.
- `blender/animals.py`: the dog and the cat, from one four-legged builder and their proportions,
  each with Walk, Idle, Sit, LieDown and its own clip (Sniff, Groom), every clip starting and ending
  in the same standing pose; imported as `Models/Town/DogModel` and `Models/Town/CatModel`. The Walk
  carries its root one stride forward a loop, and its clip asset extracts that as root motion
  (horizontal): the model's animator moves the pet (Entity mode, aimed at the Pet entity by
  `block.py` through `pkgen.root_motion_entity`). On the
  title backdrop the `Pet` behaviour steers each about its lawn and picks what it does at each
  spot, and `Stroller` sends the cars and the walkers across (`block.py`'s `start()`).
- `blender/kid_bike.py`: the kid on his bike, modelled, rigged and animated in Blender (the
  Ride and Throw clips) and written as `KidBike.glb`; run it with Blender in the background
  (`blender --background --factory-startup --python blender/kid_bike.py -- <out dir> [preview]`),
  import the .glb as `Models/KidBike`, and `block.py` places its prefab on the Bike entity.
  The `Bike` behaviour plays Ride at the bike's speed and a throw clip on a throw.
- `drive.py`: a closed-loop playtest of Block1 over `pie_run` (laps the ring, throws at each zone
  once, reading the deliveries off the level's `mDelivered`); start PIE and New game first.
- `look.py`: measures the 3D image of the title and the start of Block1 (brightness, crushed and
  clipped pixels), for tuning the shared look by numbers.

A fresh build, in order: the Blender scripts, writing their `.glb` files into `<raw-dir>`; the
project's own editor built and started as above; then `setup.py <raw-dir>`, `fx.py`, `anim.py`,
`importui.py`, `kit.py`, `block.py`, then bake each block's navigation. The game's code names the
scenes, screens, prefabs, clips and sounds it uses by id (`Code/PaperKid/src/Assets.bf`), so a fresh
build's new ids go there, and the editor is built again before `kit.py` and `block.py`. A project
whose scenes still carry scripts runs `native.py` once first, then the rest as before.
