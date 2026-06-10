# UI Rendering — Deferred Work

Consolidated catalog of items explicitly deferred from the UI rendering
tracks that closed out [UI_RENDERING.md](UI_RENDERING.md). Each item is
intentionally not yet done — pull one in when its motivating use case
shows up (or perf forces it), not pre-emptively.

Tracks referenced below:

- Track 0 — Per-pipeline overlay hook ([PIPELINE_OVERLAY_DONE.md](PIPELINE_OVERLAY_DONE.md))
- Track 1 — Billboard UI ([UI_BILLBOARD_DONE.md](UI_BILLBOARD_DONE.md))
- Track 2 — Scene screen-space UI ([UI_SCENE_DONE.md](UI_SCENE_DONE.md))
- Track 3 — Shared `VGRenderer` for `UIComponent` ([UI_SHARED_VGRENDERER_DONE.md](UI_SHARED_VGRENDERER_DONE.md))
- Track 4 — Screen overlay coordinator ([UI_SCREEN_RENDERER_DONE.md](UI_SCREEN_RENDERER_DONE.md))

---

## UI culling

**Source:** Tracks 1 & 2.

Decide "this UI content shouldn't participate in layout / hit-test /
draw this frame" without conflicting with user-controlled view state.
Today the billboard manager and scene HUD lay out and render every
active root every frame, relying on GPU clipping for off-screen content.

The blocker is semantic. Inside the UI framework, "skip this" means
manipulating `Visibility` or tree membership — both have side effects
(layout invalidation, focus management, event suppression, animation
state) that aren't appropriate for cull decisions made *outside* the
UI's own semantics. A user setting `Content.Visibility = .Hidden` for
game-logic reasons becomes indistinguishable from a manager-set cull
state.

Likely shape when picked up: a UI-framework-level "render-only off"
concept distinct from `Visibility`. Benefits Scene HUD (Track 2) and
billboards (Track 1) equally.

---

## Z-order between billboards

**Source:** Track 1.

Closer billboards should draw on top of farther ones. v1 draws in
scene-add order; overlapping billboards may render with wrong z-order.

Blocked on the underlying UI framework. Re-sorting via
`ViewGroup.RemoveView` / `InsertView` each frame triggers
`DetachView` / `AttachView` per moved child, which churns hover /
focus / mutation-queue state. A clean solution needs one of:

- A non-destructive child reorder API on `ViewGroup`
  (e.g., `MoveChild(child, newIndex)` that doesn't detach), or
- A `Z` field on `LayoutParams` that the layout / draw path respects.

Either is its own design pass.

---

## Editor / embedded-play integration for screen overlays

**Source:** Track 4.

`IScreenRenderer.RenderOverlays` takes exactly one `target`. Calling it
from inside an editor viewport would draw every registered overlay
into that viewport, including overlays that belong to other windows or
the editor's own chrome.

Three plausible shapes when this is needed:

1. Per-overlay scope tagging (overlay declares which window(s) it
   belongs to).
2. Filtered `RenderOverlays(target, filter)` so the caller chooses.
3. Embedded-play scene UI never registers as a screen overlay — it
   lives entirely on the per-pipeline path (Tracks 1 / 2). Editor
   chrome stays on the editor's own screen-overlay path.

Current best guess: option 3, but worth deciding when embedded play is
actually on the table.

---

## Multi-window screen overlay routing

**Source:** Track 4.

v1 assumes one window's swap chain is the target. Multi-window adds a
routing layer (which overlays go to which window) that needs its own
design. Closely related to the editor-integration question above.

---

## Multi-pipeline scenes

**Source:** Track 2.

A scene currently associates with one pipeline via
`sceneRenderer.GetPipeline(scene)`. Editor multi-viewport (same scene
rendered through multiple pipelines) is a future case:

- `UISceneModule` needs a list of pipelines it's registered with, not
  just one.
- `EngineUISubsystem` needs to notice when a scene gets bound to a new
  pipeline and register the overlay there.
- Layout still runs once per `Render` call — per-viewport layout cost
  is acceptable.

Track 0's `RegisterOverlay` / `UnregisterOverlay` API already supports
this; the plumbing in `EngineUISubsystem` extends naturally.

---

## VG resource sharing across UI managers

**Source:** Tracks 1, 2, 3.

Each `UISceneModule`, `BillboardUIComponentManager`, and
`UIComponentManager` owns its own `VGRenderer` today. Per-manager VG
buffers carry over from the per-instance fix in Track 3, but managers
in the same scene still don't share.

Future optimizations, in increasing scope:

- **Per-scene sharing.** Combine `UISceneModule` +
  `BillboardUIComponentManager` resources. Both render into the same
  pipeline output, same format. Saves ~15 MB per scene.
- **Cross-scene sharing.** Key by `(device, format, frameCount)`. One
  `VGRenderer` services every scene with matching parameters.
- **Cross-format sharing.** Currently `UIComponentManager` is locked to
  `RGBA8UnormSrgb` and the scene-pipeline managers track the pipeline's
  format (often `RGBA16Float`). Crossing the format gap requires a more
  flexible `VGRenderer` API.

The Track 3 ring-offset API is the foundation — multiple clients can
already feed one renderer sequentially per frame.

---

## Format flexibility for shared `VGRenderer`

**Source:** Track 3.

`UIComponentManager`'s shared renderer is hardcoded to
`.RGBA8UnormSrgb` + `frameCount = 2` (every world UI component uses
this today). A scene that wants a different per-component texture
format needs the design revisited.

---

## VGRenderer capacity tuning

**Source:** Track 3.

`MAX_VERTICES = 131072` and `MAX_INDICES = 393216` are unchanged from
the per-instance era. Tune if overflow shows up in the shared-renderer
workloads.

---

## Global focus across `UIContext`s

**Source:** Track 2.

Each `UIContext` keeps its own `FocusManager`, so multiple contexts can
have focused views simultaneously. The input chain order resolves
keyboard routing ambiguity (window wins, then scene HUD, then
billboards) — but "true global focus" (only one view focused anywhere)
is a future refinement.

---

## Cross-overlay coordination

**Source:** Track 4.

The shared screen-overlay render pass is a perf win; it doesn't add
inter-overlay communication. If real use cases appear (e.g., one
overlay reading another's state, ordering dependencies beyond
`OverlayOrder`), build them on top of the existing registry.

---

## Overlay-side depth / MRT support

**Source:** Tracks 0 & 4.

The pipeline-overlay and screen-overlay render passes both have a
single color attachment in v1 — no depth buffer, no MRT. Existing
overlay use cases (UI VG, billboards, scene HUD) don't need either.

Adding a depth attachment later is non-breaking (separate pass, or
attachment-as-option). MRT is a larger conversation.

---

## Per-overlay color-target overrides

**Source:** Track 0.

All `IPipelineOverlay` overlays draw into `PipelineOutput` with
`LoadOp.Load`. If a future overlay wants a different target (e.g., a
separate UI render target for editor picking), that's a separate
mechanism.

---

## Richer overlay scheduling

**Source:** Track 0.

`IPipelineOverlay.Order` and `IScreenOverlay.OverlayOrder` are both
single sorted `int32`s. No "run after pass X" / "group with Y" /
explicit dependency edges. Sufficient for current uses; richer
scheduling is a v2 problem if it shows up.

---

## Thread-safe overlay registration

**Source:** Track 0.

`Pipeline.RegisterOverlay` / `UnregisterOverlay` and
`IScreenRenderer.RegisterOverlay` / `UnregisterOverlay` assume
single-threaded access from the engine update path. If an off-thread
registration use case appears, add a lock then.

---

## Persistence / serialization of overlays and UI state

**Source:** Tracks 0 & 2.

Overlays are code-side registrations, not scene data. Scene UI is
built by game code each session — no `IModuleSerializer`
implementation for `UISceneModule`. Hot reload of scene UI markup
(`.sml` files driving scene HUDs) is a separate concern.

---

## Generic `IPipelineOverlay` outside UI

**Source:** Track 0.

The hook itself is in `Sedulous.Renderer` — no UI coupling. Editor
diagnostics, custom debug subsystems, etc. can use it. The Track 0
doc focuses on the hook; how non-UI subsystems use it is each
subsystem's concern.

---

## Track 1 polish items

**Source:** Track 1.

Smaller deferred items specific to billboards:

- **Worldspace-rotated billboards (true 3D quad billboards).** Tier A
  (`UIComponent`) already covers world-aligned 3D panels. Tier B
  billboards are always screen-space drawing at a projected world
  point — adding 3D-quad billboards is a different rendering mode.
- **Cinematic camera-roll variants.** A `BillboardOrientation.WorldUp`
  mode that applies an inverse-roll 2D rotation to content. Only
  needed if camera-roll handling matters in a project.
- **Animated transitions between visibility states.** When a billboard
  comes into view (e.g., un-culled) it just appears. Smooth fade is a
  future polish item — tied to the UI culling work above.
- **Per-billboard input gating opt-out.** No `IsRenderOnly` flag on
  the component yet. Manual workaround: set
  `Content.IsHitTestVisible = false`. Add a proper flag when a real
  use case appears.
