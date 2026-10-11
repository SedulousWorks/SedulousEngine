# Lamplight

A night-time manor heist in pure stealth, built through the engine's MCP tools. It is Raptor's
Lamplight, ported: the same levels, models, sounds and rules, its scripts in this engine's
AngelScript API.

## The game

Get into the manor, take what you came for and get out unseen. Keep to the dark: a light meter
reads how lit you stand from the scene's own lights, and a guard's eye reads the same, by his
lantern's cone. Guards walk their rounds on the navigation mesh and hear footsteps on each
surface (gravel louder than boards, grass softer, a sneak silent); they come to look at a noise,
grow suspicious at a glimpse and give chase at a clear sight. Put out lamps and lanterns, throw a
pebble to draw a guard away, and pick locked doors and gates by holding Use. Walls between the
camera and the thief dither away.

Five levels, each opened by getting away from the one before it:
- **The Gardens**: walled squares of clipped yew by moonlight, one guard on the paths, the
  gardener's key in the south-east square, out by the locked north gate.
- **The Stable Yard**: in the rain, wet setts that shine in the lamps, a gravel lane loud
  underfoot, hay bales and a trough for cover, two guards, and the ledger in the tack room behind
  a locked door.
- **The Ground Floor**: in by the front door, the hall, dining room, library, kitchen and study,
  doors between (some locked; the guards have the keys), each room's echo its size; the butler's
  keys in the study, on down the kitchen hatch.
- **The Cellars**: dark but for their torches, so the exposure swings between them; a wine cellar
  with no light at all, a watched vault, and the steward's room behind a locked gate.
- **The Upper Floor**: three guards, the vault behind a strong door that takes twice as long to
  pick, and an alarm a chase rings, bringing every guard on the floor; the family jewels.

A caught thief goes back to his last checkpoint. A level ends with its results: the time, the
loot, how often you were seen and caught, and the ghost mark for a level done without being seen
at all. Best times, loot and ghost marks are saved.

Controls: W A S D (or the left stick) to move, C (B) to sneak, Left Shift (left stick press) to
run, F (A) to use: open, put out, hold to pick a lock; G (X) to throw a pebble, Q and E (LB and
RB) to turn the view, Escape (Start) to pause.

## How it is built

Everything is made by the scripts in `Tools/` through the editor's MCP tools; see
`Tools/README.md` for the order. The models are Raptor's, built by its Blender scripts
(`Tools/blender/`); the sounds are generated (`Tools/sounds.py`); the levels are written from
their tables (`Tools/levels.py`) by `Tools/level.py`, which also bakes each level's navigation.

The port's one engine gap: a noise is one event carrying its place and its loudness, a `Float4`,
which script events here could not carry until this port added it.
