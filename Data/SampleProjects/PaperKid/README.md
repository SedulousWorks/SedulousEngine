# PaperKid

A small arcade game, the engine's editor sample project: a vertical slice that exercises the
game runtime end to end (scenes, physics, a scripted Game and Level tier, and game UI) and the
authoring stack that builds it. It mirrors Raptor's PaperKid, rebuilt for this engine: the two
engines' projects are not interchangeable.

## The game

Ride a bike around a town block delivering papers against the clock. Each level hands you a stack
of papers and a countdown: find the subscriber houses, throw papers into their delivery zones to
hit the level's quota, and clear it before the timer runs out. A third person follow camera and
primitive blockout art; a score chasing loop, not a sim.

Controls: WASD to ride, Space to throw, Escape to pause.

## Project layout

- `Project.xml`: the manifest. The start scene, the Game script, the input map, the bus layout
  and the UI font are set here.
- `Sources/`: the raw sources: the AngelScript scripts, the UI markup, the font and the sky.
- `Content/`: the asset envelopes (`*.xasset`) and their sidecars.
- `Cooked/`, `.cache/`, `Editor/`, `Dist/`: generated, and gitignored; the tools rebuild them.

The scripts reach the engine through its facades (`scene.Physics`, `scene.Scripts`, `Run`, `Ui`,
`Input`), never through component handles. Open the project from the editor's project manager.
