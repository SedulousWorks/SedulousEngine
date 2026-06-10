# UI Rendering - Issue Catalog

Original catalog of UI rendering architecture issues. All seven issues
were addressed across Tracks 0-4 (shipped 2026-06-10). This doc remains
as the historical record of the diagnosis and the Tier A/B/C/D framing
that drove the solution shape. Each issue below carries a pointer to
the track that resolved it.

Related (already settled, mentioned for context):

- [UI_EVOLUTION.md](UI_EVOLUTION.md) - the framework evolution work
  shipped 2026-06-08 (`.sss`, `.sml`, focus + gamepad, pseudo-elements,
  property normalization, capture-phase events).
- [UI_STYLE_DONE.md](UI_STYLE_DONE.md) - per-view style overrides
  (inline + local stylesheets), shipped 2026-06-10.

The five tracks below all shipped 2026-06-10. Linked docs are the
historical design + sub-phase plans; deferred items from each are
consolidated in [UI_DEFERRED.md](UI_DEFERRED.md):

- Track 0 — [PIPELINE_OVERLAY_DONE.md](PIPELINE_OVERLAY_DONE.md)
- Track 1 — [UI_BILLBOARD_DONE.md](UI_BILLBOARD_DONE.md)
- Track 2 — [UI_SCENE_DONE.md](UI_SCENE_DONE.md)
- Track 3 — [UI_SHARED_VGRENDERER_DONE.md](UI_SHARED_VGRENDERER_DONE.md)
- Track 4 — [UI_SCREEN_RENDERER_DONE.md](UI_SCREEN_RENDERER_DONE.md)

---

## Motivating problem

Building game UI on top of Sedulous.Engine.UI hits a perf wall fast.
Damage numbers, floating health bars, nameplates over enemies, world-
space prompts - none of these can practically use the current
`UIComponent` path because each instance allocates its own GPU
resources, render texture, and renderer. The fallback in past projects
was to use the debug draw system, which works at low scale but is not
DPI-aware and has no real font rendering.

The discussion expanded from "Tier B world UI" into a broader audit of
where UI attaches to the rendering pipeline and what works vs. what
doesn't.

---

## Issues

### 1. Per-instance `VGRenderer` GPU cost — *Resolved by Track 3*

Each `UIComponent` today owns its own `VGRenderer`. Each `VGRenderer`
allocates per-frame vertex + index buffers sized for
`MAX_VERTICES = 131072` and `MAX_INDICES = 393216`, multiplied by
`frameCount` (typically 2-3). That's **~12-18 MB of GPU buffer memory
per instance** before any textures.

Real-world impact: 40 floating damage numbers and health bars =
~600 MB of VG buffer memory + 40 × 1 MB render textures. This is the
heaviness that drove the debug-draw workaround in past games.

Aggravating factor: every instance also rebuilds an identical
`RenderPipeline`, `BindGroupLayout`, `PipelineLayout`, and sampler -
small per-instance cost, but unnecessary multiplication.

`VGRenderer` is in fact **stateless between `Render` calls** - clears
its scratch buffers, uploads the new batch, draws. Multiple clients
could feed one renderer sequentially each frame. It's not being used
that way.

### 2. `IOverlayRenderer` is window-wide and screen-space only — *Resolved by Tracks 0, 2, 4*

`Sedulous.Engine.Render.IOverlayRenderer` has this signature:

```beef
int32 OverlayOrder { get; }
void RenderOverlay(ICommandEncoder encoder, ITextureView target,
                   uint32 w, uint32 h, int32 frameIndex);
```

`EngineApplication.bf:546` iterates all `IOverlayRenderer`
implementations and calls each with `mSwapChain.CurrentTextureView` -
the **full window's** target. No view-projection matrix, no
`RenderView`, no `Pipeline`, no depth buffer.

Consequences:

- Works fine for runtime single-window games and for the editor's own
  chrome (legitimate window-level UI).
- Breaks for **scene UI** (HUD, menus tied to a game scene) when the
  scene runs **inside an editor viewport** - the overlay would paint
  over the entire editor window, bleeding across viewport panels and
  surrounding chrome. Not a current bug because editor scene view is
  edit-only today, but it's a structural limitation for embedded play.
- Breaks for **multi-viewport games** (split-screen co-op) in the same
  way.
- Provides no projection state, so billboards / world-anchored UI
  can't use it without out-of-band V/P access.

### 3. No per-pipeline overlay mechanism for scene UI — *Resolved by Track 0*

Scene-attached UI (game HUD, billboards, in-scene tooltips) wants to
render with knowledge of its pipeline's `RenderView` (V/P matrix,
viewport dims) and into that pipeline's output target. No such hook
exists today. Available hooks:

- `IOverlayRenderer` - window-level, no per-pipeline scoping
- `WorldUIPass` - per-pipeline but specific to texture-backed
  `UIComponent` (Tier A) panels; can't host lightweight billboard or
  direct-to-target UI
- `DebugScreenPass` - renderer-internal, used for DebugFont overlay only
- `DebugGeometryPass` - renderer-internal, used for DebugDraw lines/tris

The closest precedent is the per-pipeline `Pipeline.DebugDraw` slot
(which `DebugGeometryPass` merges with `RenderContext.DebugDraw`) - same shape
of solution but for debug primitives, not for arbitrary draws.

### 4. `DebugScreenPass` per-pipeline asymmetry (FIXED)

`DebugGeometryPass` reads both `pipeline.DebugDraw` (per-pipeline) and
`renderContext.DebugDraw` (global) and merges them, fixing a prior
viewport-bleed bug for gizmos.

`DebugScreenPass` (which draws DebugFont 2D text + projected 3D text) only
read `renderContext.DebugDraw`. The same bleed would occur for any
scene-scoped overlay text in editor multi-viewport.

**Status: fixed.** `DebugScreenPass` now mirrors `DebugGeometryPass`'s local +
global merge pattern.

### 5. Current `IOverlayRenderer` rendering path has its own issues — *Resolved by Track 4*

Independent of the per-pipeline question, the existing window-level
overlay path has friction worth flagging:

- **Each overlay does its own `BeginRenderPass` / draw / `End`.** Look
  at `ScreenUIView.RenderOverlay` - it opens a full render pass just
  to record VG draws. With multiple overlays (profiler HUD, screen UI,
  debug HUD), that's multiple render pass switches per frame.
- **External to the render graph.** `EngineApplication` runs a manual
  `for` loop after `Render()` returns. The graph handles every other
  ordering / transition decision. Window UI is the one path outside it.
- **No coordination between overlays.** Sorted by `OverlayOrder` int
  but otherwise isolated - no way for two overlays to share a pass or
  inspect each other.
- **No depth buffer access.** Fine for current uses; would matter if a
  window-level UI element ever wanted depth interaction.

### 6. Boundary constraint: renderer doesn't depend on VG — *Preserved through all tracks*

`Sedulous.Renderer` does not reference `Sedulous.VG` or
`Sedulous.VG.Renderer`. The renderer owns simple primitives (DebugDraw
lines/tris, DebugFont bitmap text) and stops there. VG is heavier and
lives in the UI/engine layer.

Implications:

- `VGRenderer` cannot be owned by `RenderContext` or `Pipeline`.
- Any per-pipeline UI hook the renderer exposes must be a generic
  interface with no VG types in the signature. The UI subsystem
  implements the interface and uses `VGRenderer` internally.
- Converting VG output into DebugDraw primitives is not viable - it
  either drops fidelity (gradients, AA, sub-pixel glyphs) or grows
  DebugDraw into a VG clone inside the renderer, defeating the
  boundary.
- The texture-handoff model (VG -> texture -> DebugDraw blits it) is
  what `UIComponent` does today via the sprite path, and it's the
  source of the per-instance cost in issue #1.

The clean shape: renderer provides a scheduled slot
(`(IRenderPassEncoder, RenderView)`); UI subsystem registers a callback
that uses VG internally. Renderer remains VG-agnostic.

### 7. Multiwindow + dock/undock UI is real and shouldn't be touched casually — *Preserved; cross-window VG sharing deferred ([UI_DEFERRED.md](UI_DEFERRED.md))*

`VGExternalTextureCache` is in use today to solve real multi-window
scenarios including editor panels that can undock to real OS windows
and redock. Don't propose changes to it without full context of how
it's used. Sharing strategy for VGRenderer across windows interacts
with this and needs careful thought; multi-window keying is per
`(device, target format, frame count)`.

---

## Conceptual framing: three tiers of UI rendering

Useful vocabulary for the discussion ahead. Not a design - just a
naming.

| Tier | Use case | Implementation |
|---|---|---|
| **A. True 3D panel** (`UIComponent`) | Interactive in-world surfaces (terminal screens, signage); arbitrary 3D orientation; readable from oblique angles | Per-component render texture + shared `VGRenderer` on `UIComponentManager` (Track 3) + sprite display path |
| **B. Billboarded screen-projected view** (`BillboardUIComponent`, Track 1) | Damage numbers, floating health bars, nameplates, world-anchored tooltips | Manager-shared `VGRenderer` + `UIContext`; draws via Track 0's `IPipelineOverlay` |
| **C. Screen-space scene UI** (`UISceneModule`, Track 2) | Game HUD, menus tied to a game scene, things that should appear inside a specific viewport in editor preview | Per-scene singleton module + per-scene `VGRenderer`; draws via Track 0's `IPipelineOverlay` |
| **D. Window-level UI** (`ScreenUIView` via `IScreenOverlay`, Track 4) | App chrome, no-scene UI (main menu before scene load, loading screens, modal dialogs not tied to gameplay) | `IScreenOverlay` implementers register with `RenderSubsystem`; one shared render pass per frame |

Tier B and C share Track 0's `IPipelineOverlay` hook; they differ only
in whether content is positioned by world projection or by screen
coordinates.

---

## Tracks identified

Five separable workstreams were carved out of the issues above. Each
shipped its own design + sub-phase doc; see the links at the top of
this file. As-shipped summary:

- **Track 0 — Per-pipeline overlay mechanism.** `IPipelineOverlay` +
  `Pipeline` overlay registry; VG-agnostic interface lives in
  `Sedulous.Renderer`. Foundation for Tracks 1 and 2.
- **Track 1 — Billboard UI (Tier B).** `BillboardUIComponent` +
  manager; orientation modes (Cylindrical, ScreenBillboard,
  WorldAligned, CameraFacing, CameraFacingY); distance scaling;
  draws via Track 0's hook.
- **Track 2 — Scene screen-space UI (Tier C).** `UISceneModule` per
  scene; draws into pipeline output via Track 0's hook. Makes scene
  HUD work correctly inside editor viewports.
- **Track 3 — Shared `VGRenderer` for `UIComponent` (Tier A).**
  Ring-offset API; one shared `VGRenderer` per `UIComponentManager`
  instead of one per component. Same pattern applied to
  `DrawingRenderer`.
- **Track 4 — Screen overlay coordinator (Tier D).** `IScreenOverlay`
  + `IScreenRenderer`; one shared render pass per frame for all
  window-level overlays. Old `IOverlayRenderer` removed.

---

## Out of scope / settled

- **`VGExternalTextureCache` mechanism** - in use for multiwindow
  including dock/undock-to-OS-window. Don't change without full
  context (issue #7).
- **Editor's own UI rendering** - separate hierarchy from
  `EngineApplication`; not crossing paths with engine UI; not part of
  this discussion.
- **`DebugScreenPass` per-pipeline merge** - shipped (issue #4 fix).
- **Sedulous.Drawing vs VG selection** - VG is the path forward for
  UI; Drawing is its own (lighter) library not part of this thread.

