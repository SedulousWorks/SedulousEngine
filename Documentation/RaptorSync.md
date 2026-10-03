# Raptor sync of 2026-10-03

Raptor (`/home/robert/Dev/CPP/GameEngine`, local `master`) from the last synced commit 122035b2
to 0b60c738: 189 commits, 22 documentation only. Most of the rest are Raptor porting Sedulous
work (its plan: `Documentation/Plans/week-2026-09-26.md`, groups 0 and A to E) and are skipped
here. What follows is what applies to Sedulous, mapped by five read-only reviews, in port order.
Each item is one commit with its tests; strike an item in the commit that lands it, and move
the sync marker to 0b60c738 when the list is done. Then PaperKid is rebuilt over MCP to mirror
Raptor's (the last group).

## Group 1: fixes, small and independent

1. ~~61ddc952~~ (done) Physics: Jolt's bring-up takes a lock. `JoltRuntime.Acquire` increments a counter
   and calls `JPH_Init` outside any lock, so a second cook on a worker goes on while the first
   is still initialising. Static Monitor around a plain counter; the eight-thread cooking test.
2. ~~Take-back (fd631023)~~ (done): thumbnails average in linear light, then encode RGB (`ThumbnailStage
   .Downscale` still writes linear values as bytes since the encode-once change: too dark).
3. ~~Take-back (fd631023)~~ (done): `TextureFormats.IsFloat` (R16F, R32F, RG16F, RG32F too), used by the
   tonemap's `EncodesOnWrite`; FXAA told its input is linear on an sRGB or float target, the
   shader taking `sqrt(luma)` so its thresholds still apply.
4. ~~Take-back (b2a3e376)~~ (done): installing a template replaces its bundle whole, in `Create(.Install)`
   and `Import` (a sidecar the new build dropped no longer lingers and ships).
5. ~~93d511dd~~ (done) UI: an unknown gravity name in markup is a warning.
6. ~~ffad9393~~ (done) Render: the mesh rings hold every shadow caster, and a dropped draw warns.
7. ~~3adbf8c4~~ (done) Render: a `BindGroupCache` that checks every view and its generation; TAA uses it.
8. ~~0b60c738~~ (done) Render: the MSAA resolve and the SSR and SSGI resolves use it (velocity was left out
   of their keys).
9. ~~a8723a4f~~ (done) Scene: a running scene is stopped before it is destroyed.
10. ~~ca6856f3 + 9ee94a34~~ (done) Engine.Navigation: an agent that cannot join the navmesh, and a zone
    with no usable navmesh, say so.

## Group 2: take-backs from Raptor's review of our ports

11. ~~52839fba~~ (done): a created template takes an id, name and notes (`--id`, `--name`, `--notes` on
    `Sedulous.Tools.Export --template create`); the Steam Deck script passes them instead of
    rewriting template.xml with a regex.
12. ~~c0dc7379~~ (done): the dist manifest copies the project settings through their own serialization,
    not field by field (`ExportDriver`).
13. ~~9af5a57e~~ (not ported, a deliberate difference): Raptor's `export_preset_set` refuses a
    `platform` or `config` no installed template has. Here a preset may name a template this
    machine lacks (presets travel with the project, templates do not; the result's `template` is
    null), so the check stays the platforms the engine targets, not this machine's templates.
14. ~~0c6a0393~~ (done): the HTTP tests Sedulous lacks (sequence numbers across re-dispatch, a departed
    peer's request abandoned, a pending one abandoned at `Stop`).
15. From Raptor's notes for us, each its own commit:
    - ~~a~~ (done) DefaultApplication clears the factory set at shutdown while the device lives
      (and releases its own manager's products first; a borrowed manager forgets the factories).
    - ~~b~~ (done) `EngineCompositionTests`: "each domain id once" and "each factory matches
      its description".
    - c A regression test for 5aa79822's teardown order.
    - d `SceneReference`'s typeIds text interpolates the hash basis.
    - e Check the audio clip and cue pages keep a paused audition (Raptor's pages dropped it).
    - The PaperKid override test walks the Level script's overrides too: with group 6.

16. bc87304e, eadecdd5, 1896bfed, b6a08629, f3fc2d35: the project settings and the export
    presets describe their fields through reflection, and the Project Settings dialog,
    `project_info`/`project_settings_set` and `export_presets`/`export_preset_set` all build
    from it (one shared reflected-fields module), instead of three hand-kept field lists
    (`ProjectSettingsDialog`, `ProjectInfoTool`, `ExportPresetTools`) that drift as fields are
    added, the bug class item 12 fixes for the manifest. The tool keys become the reflected
    field names (`defaultSceneId`, `renderMsaaSamples`), as Raptor's: the McpGuide and every
    test calling the tools change with them. The largest take-back; after 11 to 15.

## Group 3: navigation over static geometry

17. 79bef80d Navigation: a bake can be bounded to a region (`NavigationBakeParams.Bounds`).
18. 904aa179 Editor.Navigation: a zone bakes within its box. Before 21: once wide static
    ground feeds the bake, the bound keeps the grid small.
19. 7307ed3b Scene: `IStaticGeometrySource`, systems that own static level geometry say so.
20. 9e9a21d5 Physics: `AppendBodyTriangles`, bodies give their world triangles touching a box.
21. 0bbc1e88 Engine.Physics: static, solid bodies are the scene's static geometry (one
    `DescribeBody` shared with body creation; works in edit mode with no world).
22. 7948ddd8 Engine.Terrain: a terrain's surface is static geometry (the triangulation moves out
    of `NavigationBake`).
23. 81236cd8 Editor.Navigation: bake the scene's static geometry, not every mesh (cars and
    walkers no longer bake into the navmesh).
24. c08cec05 + e3eb6dc1 Editor.Scene: `navigation_bake`, the inspector's Bake Navigation as a
    live scene MCP tool (`SceneMcpTools`; the scene tool tripwire 17 to 18; the McpGuide).

## Group 4: orthographic cameras and render textures

25. eb546ef1 RenderGraph: an imported target takes its final state right after its last pass.
26. cfe503d5 Render: an orthographic view clusters its lights and skips the perspective-only
    passes (AO, SSR, SSGI, TAA); `Float4x4.IsOrthographic`.
27. 06265006 Engine.Render: a camera can be orthographic (`CameraProjection`, `OrthoHeight`;
    the extract, the camera preview and gizmo build through one function). 17e80a08 needs only
    the new enums to keep their reflection data.
28. 19314649 Texture.Resource: a render texture is a texture a camera can draw into.
29. 7b2a6642 Texture.Pipeline: the render texture asset, its cook and File > New.
30. aa13434d Resource, Editor.Mcp: a texture reference names both asset types it takes.
31. 4e9f1a6d Engine.Render: a camera can render into a texture (`Target`, `TargetInterval`;
    scene overlays off for a target view).

## Group 5: images in game UI and script handles

32. 556f3847 UI: an ImageView names what it shows (`source=`), resolved by the context's
    provider.
33. 48c2f248 Engine.UI: an image in game UI shows a texture asset, render textures included.
34. 8c4a3c4b Engine.UI.Script: views move and turn from script (translation, rotation).
35. 16de4509 Script: an Image handle and `SetCameraTarget` from a script.

## Group 6: PaperKid rebuilt over MCP

36. 92bfed84 (+ bdd54b09): Raptor's rebuilt PaperKid, recreated through the MCP tools: five
    blocks on a ring road, the bike's auto-aimed throws, cars and walkers on navmeshes, the
    orthographic minimap camera drawing into a render texture the HUD shows, seven screens.
    Files cannot be copied (different envelopes, type hashes and script dialect); Raptor's
    `Data/SampleProjects/PaperKid/Tools/` generators (kit.py, block.py) are the recipe. It
    replaces the work-in-progress PaperKid here.

## Already here or not applicable (no action)

Raptor catching up to Sedulous: 6e0c600f, 43d7a699, c107f0eb, fcbe189a, e4f00a90, e26f2edc,
6c4aa616, 6cba91b5, ea7f905e, d644fad5, 14af245c, 22ddc394, 687bfcc5, f82cfd56, c3965c74,
6eaaadbc, a006c168, and every commit of Raptor's groups 0 and A to E. Not applicable to Beef:
cfdbbda4 (Beef formats a float as its own shortest form), 17e80a08 (Beef reflects enum names),
903188e7 and e6bc58f8 (C++ module hygiene). Already ported: 9ac175be (6df4e688).
