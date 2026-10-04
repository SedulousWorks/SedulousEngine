# Raptor sync of 2026-10-04

Raptor (`/home/robert/Dev/CPP/GameEngine`, local `master`) from the last synced commit 76e6bdb6
to 26236a7e: 32 commits. Engine features (script rumble, a game's save, UI tweens with an
easing, SVG icons in a game's theme), the web player's page and export, and Sky Hopper's next
step (the kit's bee, pickups and hazards, lives and a score kept between runs, two more levels),
which needs every one of the engine features first. Mapped by four read-only reviews, in port
order. Each item is one commit with its tests; strike an item in the commit that lands it, and
move the sync marker to 26236a7e when the list is done.

Sedulous counts data versions from 1 where Raptor counts from 0: a version Raptor bumps to N is
bumped here to the next one after Sedulous's own, never to Raptor's number. Raptor's specs and
its Documentation/Systems pages are not ported; what they say that a game author needs goes in
`Documentation/Shipping`.

Not ported: a49bf057 (the credits name "GameEngine": Raptor keeps its engine's name out of
public text, Sedulous names itself), e841c88a (Raptor's backlog note).

## Group 1: engine

1. ~~6db2b4a3~~ (done) ModelImporter: the manifest's name is reserved before a sub-asset claims
   it, so Gem_Blue.gltf's material "Gem_Blue" takes a suffix instead of the manifest's instance.
2. ~~eef9d560~~ (done) Input: `ActionRuntime.Rumble(pad, low, high, seconds)` and `StopRumble()`, applied at
   the end of `Update` through that frame's devices; `Input.Rumble(low, high, seconds)`,
   `Input.Rumble(gamepad, ...)` and `Input.StopRumble()` on the facade; `GameInstance.StopScript`
   stops its source's pads (before its no-game early return). Scripting.md.
3. ~~92822eca~~ (done) Core: `WriteFileAtomic`, a temp file moved over the target. Beef's `File.Move` does
   not replace an existing file on Windows (`MoveFileW`), so Windows takes `MoveFileExW` with
   `MOVEFILE_REPLACE_EXISTING`.
4. ~~bd1cce79~~ (done) Settings: `SaveValues`, a serializable section of typed values by key.
5. ~~362e8f61~~ (done) GameInstance: `RunSave` (open, flush only when changed, atomically, as XML) and the
   `Save` service facade (in GameInstance, which Script.Facades cannot name); an idle `Save` for
   scripts outside a run; `StopScript` flushes. Scripting.md gets "Saving"; the surface type
   count tripwires move by one.
6. ~~30fd32e0~~ (done) Project: `<name>.save.xml` (`project.save.xml` unnamed); the player keeps it in the
   user data directory, a Game tab in `<project>/Editor/`.
7. ~~d83b1837~~ (done) UI: an animation names the channel it drives (`AnimationChannel`),
   `AnimationManager.CancelForView(view, channel)`, `ViewAnimator.TranslateTo`.
8. ~~24d7a969~~ (done) UI script: `Ease`, and every handle's `MoveTo`, `Scale`/`SetScale`, `ScaleTo`,
   `RotateTo`, `Pulse` and an eased `FadeTo` (default arguments where Raptor overloads); a set
   stops only its own channel.
9. 9497a67e UI: a vector image asset (`.svg`, importer, builder, resource, factory); a theme's
   `@icon name "{guid}"` is embedded at cook (theme resource version 2) and drawn by the game's
   UI and the canvas and world panel themes. Builder/description/set counts move; Assets.md.
10. ba347f37 Editor: the theme page's preview draws icons and images.

## Group 2: the web player and its export

11. d7237f84 Player: the user data directory is an IndexedDB mount on the web, so a save and the
    user settings outlive the page (`PersistUserData` after each write; `-lidbfs.js`).
12. 56d568a5 Export: a renamed web player stays a page (`index` stages as `index.html`).
13. 7e6fbeee Player: `serve.py` beside a web export, serving it over HTTPS to another device;
    staged into the web template.
14. e28d714c, 7d0945b3, c72427ef, 137a3dfc, 26236a7e Player: the web page shows what is loading
    until the game runs, says when a game quits and offers to play again, and says in plain
    words when WebGPU is not there. One commit, ending at 26236a7e's text.
15. 8b9d4bbe, ae59b405 (their Sedulous counterparts) Documentation: how the web template is built
    and installed, serving a web export to another device, and web saves
    (`Documentation/Shipping/Web.md`). Building the template is a machine step, not a commit.

## Group 3: the games (through the MCP tools)

16. 16684936, ddc3f5a1 Sky Hopper and PaperKid: the pad rumbles with the game (PaperKid's
    `Tools/scripts` copies too).
17. 8967bae2, b321c2ac, 3493c59c Sky Hopper and PaperKid: a Web export preset (`index`, through
    `export_preset_set`); both ignore `/Cooked-*/`.
18. eaf32784 Sky Hopper: the kit's bee, pickups, hazards and level pieces imported, and six SVG
    HUD icons; CREDITS.md.
19. a688882a Sky Hopper: lives, a score and stars, kept between runs (Mover, Pickup, Enemy's
    hover, the Game script, GameOver, the HUD's icons, the gems and hearts in Levels 1-3).
20. 8ac36257 Sky Hopper: Bee Meadow and Cloud Fortress, built by `Tools/` (mcp.py, skygen.py,
    levels.py, ported as PaperKid's were).
21. b97873c9 Sky Hopper: the level's card drops in once the fade clears.
