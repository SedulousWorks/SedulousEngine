# Raptor sync of 2026-10-03 (second)

Raptor (`/home/robert/Dev/CPP/GameEngine`, local `master`) from the last synced commit 0b60c738
to 8be4094d: 65 commits. A third are PaperKid and Sky Hopper content, specs and weekly notes;
the rest are four engine features (the colour pipeline, shadow controls, run audio, render
profiles) and a few fixes. Mapped by five read-only reviews, in port order. Each item is one
commit with its tests; strike an item in the commit that lands it, and move the sync marker to
8be4094d when the list is done. Then PaperKid is rebuilt over MCP to mirror Raptor's (the last
group, carried over from the previous sync).

Sedulous counts data versions from 1 where Raptor counts from 0: a version Raptor bumps to N is
bumped here to the next one after Sedulous's own, never to Raptor's number. Raptor's specs are
not ported (Sedulous keeps none); what they decided is in the items.

## Group 1: fixes, small and independent

1. ~~17cd7c08~~ (done) Image.DDS.Tests: the bit writer takes no bit past a u32's 32 (`DdsTests.bf`
   `BitWriter.Put`).
2. ~~9f4b0370~~ (done) Graphics: every executable takes its device from its command line the same way: one
   call giving the backend and the validation flags, used by the editor, the desktop player
   (which ignores `--no-gpu-validation` today) and the desktop samples, which stop forcing
   validation on (MultiWindow keeps it; the web programs take no command line).
3. ~~a6fc8996~~ (done) Editor.Scene: a Game tab's screenshot is what the tab drew, with its scale (the
   capture's resample goes; `pie_screenshot` and `pie_run`'s shots report `renderWidth`,
   `renderHeight` and `scale` when the tab draws scaled; McpGuide).
4. ~~b1dd4e68~~ (done) Sky Hopper: the exported player is named for its game ("Sedulous SkyHopper").
5. ~~Backlog~~ (done), from Raptor's findings, each checked here: TAA still looks jittery (6896586f), auto
   exposure settles visibly at the start of a scene (71dec790), `var()` inside a drawable's
   arguments draws white silently, and every new particle system has the same seed (a5f112f8).

## Group 2: the colour pipeline (an authored colour is sRGB, decoded where it reaches the GPU)

6. ~~412af1d4~~ (done) Core: `ToLinear(Color)` and `ToSrgb(Color)`; `Color` documented as authored sRGB.
7. ~~d8c84631 + 55f58ece~~ (done) Engine.Render: extraction decodes every authored colour (mesh, instanced
   tints, sprite, decal, cameras' clears, lights, ambient, sky); the default environment colours
   written in sRGB so a default scene keeps its look.
8. ~~aa36f9c2~~ (done) Materials: `Color` and `ColorHdr` property types, decoded at upload
   (`EncodeUniformsForGpu`); a stored Float4 adopts its builtin template's colour type; the
   material page's rows.
9. ~~d0d33155~~ (done, Sedulous's part) Sky Hopper: its 35 materials re-expressed in sRGB, look kept.
10. ~~c89cd6fb~~ (done) Engine.Particles: particle colours decoded to linear where they are drawn.
11. ~~ad81b72b~~ (done) Render: debug colours decoded like every authored colour (`color.hlsli`); the colour
    probes.
12. ~~40d28176~~ (done) Model.GLTF: colour factors read as authored sRGB; emissive strength kept as an
    intensity.
13. ~~eaaa699c + 5b1d2c44~~ (done) Model.FBX: material colours read as authored sRGB, the emission factor an
    intensity; a legacy material's colour ignores its diffuse factor.
14. ~~1ed763b7~~ (done) UI.Viewport, Editor: viewport backdrops are sRGB like every UI colour.
15. ~~b4d0f7a9~~ (done) Docs: the colour rule in the MCP guide and in `entity_set`'s description.

## Group 3: shadow controls

16. ~~a8901c7c~~ (done) Render: a light's shadow biases and strength reach the shadow it casts (defaults
    equal to today's constants).
17. ~~352edbf7~~ (done) Engine.Render: shadow controls on the light (`ShadowStrength`, `ShadowNormalBias`,
    `ShadowDepthBiasScale`; the light record's next version, reading the current one).
18. ~~(enabler)~~ (done) Scene: a settings block can read an older version (`SettingsMinReadDataVersion`,
    through every place a block is read).
19. ~~6bbe994f~~ (done) Engine.Render: a scene sets its sun's shadow reach (environment `ShadowDistance`,
    `ShadowCascadeSplit`, `ShadowFadeDistance`; the render frame's and subsystem's globals go).

## Group 4: run audio and script voice control

20. 4b830b03 (engine half) Audio: a playing voice's volume and pitch ease over a duration, and a
    stop can fade.
21. 8799a9ce + b7afa416 Audio: run groups, one level above the scene groups, custom buses
    included (one music slot per run, a run's own bus gains, pause and mute).
22. 448232bc Scene, GameInstance: a scene knows its run.
23. a5131c2d Engine.Audio: a game's sound belongs to its run (the subsystem's runs, focus and
    hear-all, the listener gated by them; a facade per run installed on its run host, with the
    stop-music, mute and named-bus verbs Raptor's facade has).
24. 4b830b03 (script half) Script: a script controls a playing voice, the music's included.
25. ae387d16 Editor, DefaultApp: Stop, Pause and focus act on the game's run (the Game audio
    preference, Hear every Game tab).

## Group 5: render profiles (a game's look set once and shared by its scenes)

26. 0b5b3aa8 + 7aaa4d36 Engine.Render, Render.Pipeline: the environment and post-process
    profiles, a block's `Source`, its effective values; the profile assets, their cook and
    File > New (together: the composition test wants a builder for every cooked form).
27. 62f6aa73 Editor.Mcp: what makes a product, shared (`SourceAssetTypesFor`).
28. babadd96 Editor: a scene's settings in profile mode edit the profile (Make Profile, Copy
    Into Scene).
29. 5515b8ab Editor: a profile asset's page, with a preview scene.
30. f3df9db4 McpGuide: a game's look through render profiles.

## Group 6: PaperKid rebuilt over MCP

31. 92bfed84 (+ bdd54b09) and every PaperKid commit since, to 8be4094d: Raptor's rebuilt
    PaperKid, recreated through the MCP tools: five blocks on a ring road, the bike's auto-aimed
    throws with their guides, cars and walkers on navmeshes, the orthographic minimap camera
    drawing into a render texture the HUD shows, the screens and their newsprint theme, the
    music, sounds and particle effects, one look shared through render profiles, a Steam Deck
    preset. Files cannot be copied (different envelopes, type hashes and script dialect);
    Raptor's `Data/SampleProjects/PaperKid/Tools/` generators are the recipe. It replaces the
    work-in-progress PaperKid here. The PaperKid sample test walks the Level script's overrides
    too.

## Already here or not applicable (no action)

Already here: eb89f063 merges the TAA and resolve bind group fixes ported last sync
(3adbf8c4, 0b60c738). Specs and weekly notes: f6902223, f3bbdcb4, b39b2829, aa3d8fbb,
f494960e, 31505b35, 91a7174e, a5f112f8, 8be4094d (their findings are item 5). Sky Hopper's
look in Raptor (0ab313df, 67852d42) is its own tuning. The PaperKid sample test's counts
(efbb26d3, 3688492e) come with group 6.
