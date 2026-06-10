# Screen Overlay Coordinator (`IScreenRenderer` + `IScreenOverlay`)

**Status:** Shipped 2026-06-10. Deferred items consolidated in
[UI_DEFERRED.md](UI_DEFERRED.md).

Track 4 from [UI_RENDERING.md](UI_RENDERING.md). Refactors window-space
overlay rendering so a single render pass covers every overlay,
ownership of the overlay list moves from `EngineApplication` to
`RenderSubsystem`, and the naming joins the `IPipelineOverlay` /
`ISceneRenderer` convention.

Addresses [UI_RENDERING.md](UI_RENDERING.md) issue #5 (per-overlay
`BeginRenderPass` / `End` churn, manual loop external to the render
graph, no coordination between overlays).

## Goals

1. **One render pass for all window overlays** per frame. Today each
   `IOverlayRenderer` opens its own pass. With ~3-4 overlays
   (`EngineUISubsystem`, profiler HUDs, etc.) that's per-frame pass
   switches for no gain.
2. **`RenderSubsystem` owns the overlay registry**, not
   `EngineApplication`. Matches how `ISceneRenderer` already lives on
   the render side; `EngineApplication` stops doing things the render
   subsystem should own.
3. **Naming consistency** with the rest of the rendering vocabulary.
   See [Naming](#naming) below.

Out of scope (intentionally): editor / embedded-play integration. The
rationale is in [Not in scope for v1](#not-in-scope-for-v1).

## Naming

The engine ends up with four cleanly-paired roles after this lands:

| Interface | Role | Implemented by |
|---|---|---|
| `ISceneRenderer` | Renders scenes (top-level coordinator) | `RenderSubsystem` |
| `IScreenRenderer` | Renders the screen overlay layer (top-level coordinator) | `RenderSubsystem` |
| `IPipelineOverlay` | Per-pipeline overlay source (Track 0) | `UISceneModule`, `BillboardUIComponentManager`, future tools |
| `IScreenOverlay` | Window-level overlay source (this track) | `EngineUISubsystem`, future profiler HUD / debug overlays |

The pattern reads consistently:

- `I<Target>Renderer` = "renders Xs" (coordinator role)
- `I<Target>Overlay` = "an overlay belonging to Xs" (source role)

Renames the current `Sedulous.Engine.Render.IOverlayRenderer` (a
window-overlay source role today) to `IScreenOverlay`. There is no
legacy alias - per the Track 3 precedent, no compat wrappers.

## Design

### `IScreenOverlay`

```beef
// Sedulous.Engine.Render

/// An overlay that wants to draw into the window-space composition
/// layer (post-blit, before present). Registers with `IScreenRenderer`;
/// the renderer opens one render pass against the target each frame
/// and walks overlays in `OverlayOrder` order.
public interface IScreenOverlay
{
    /// Sort order. Lower draws first (background); higher draws last
    /// (foreground).
    int32 OverlayOrder { get; }

    /// Record draws into the active screen-overlay render pass. The
    /// render pass and color target are already set up; the overlay
    /// only emits draw commands. `width` / `height` give the target's
    /// pixel dimensions for viewport / scissor / projection.
    void Render(IRenderPassEncoder encoder, uint32 width, uint32 height, int32 frameIndex);
}
```

Notable changes from current `IOverlayRenderer`:

- Encoder type is `IRenderPassEncoder` (not `ICommandEncoder`). The
  render pass is open before `Render` is called. Implementers no
  longer call `BeginRenderPass` / `End`.
- Target view is **not** passed - it's bound by the shared pass.
- `width` / `height` / `frameIndex` stay for viewport setup and
  per-frame resource indexing.

### `IScreenRenderer`

```beef
// Sedulous.Engine.Render

/// Top-level coordinator for window-space overlay rendering.
/// Implemented by `RenderSubsystem`. Owns the sorted list of
/// `IScreenOverlay` sources and drives a single shared render pass per
/// `RenderOverlays` call.
public interface IScreenRenderer
{
    /// Sort order is recomputed when the registry changes.
    void RegisterOverlay(IScreenOverlay overlay);
    void UnregisterOverlay(IScreenOverlay overlay);

    /// Open one render pass against `target` with `LoadOp.Load`, walk
    /// all registered overlays sorted by `OverlayOrder`, and call each
    /// one's `Render` with the active encoder. No-op when no overlays
    /// are registered or `target` is null.
    void RenderOverlays(ICommandEncoder encoder, ITextureView target,
                       uint32 width, uint32 height, int32 frameIndex);
}
```

`RenderSubsystem` implements this. The registry is a small `List` +
sort-on-change (or insertion-sort, like `Pipeline.RegisterOverlay`
from Track 0). Capacity isn't a concern - real overlay counts are
in the single digits.

### Single shared render pass

`RenderOverlays` becomes:

```beef
public void RenderOverlays(ICommandEncoder encoder, ITextureView target,
                          uint32 width, uint32 height, int32 frameIndex)
{
    if (mScreenOverlays.IsEmpty || encoder == null || target == null) return;

    ColorAttachment[1] colorAttachments = .(.()
    {
        View = target,
        ResolveTarget = null,
        LoadOp = .Load,
        StoreOp = .Store,
        ClearValue = .(0, 0, 0, 1)
    });
    RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };

    let renderPass = encoder.BeginRenderPass(passDesc);
    if (renderPass == null) return;

    for (let overlay in mScreenOverlays)
        overlay.Render(renderPass, width, height, frameIndex);

    renderPass.End();
}
```

One pass, sorted iteration, no per-overlay setup. That's the perf
win - per-overlay `BeginRenderPass` is cheap individually but adds up
on real workloads with profiler + screen UI + debug HUD all active.

### `ScreenUIView` cascade

`ScreenUIView.RenderOverlay` today opens its own render pass internally
(`Code/Engine/Sedulous.Engine.UI/src/ScreenUIView.bf:80-84`). Under the
new model, the pass is already open when it's called. The cascade:

- `ScreenUIView.RenderOverlay(encoder, target, w, h, fi)` →
  `ScreenUIView.Render(renderPass, w, h, fi)` (renamed + signature
  changed; no own `BeginRenderPass`)
- `EngineUISubsystem` implements `IScreenOverlay`. Its `Render` is a
  thin pass-through to `mScreenView.Render(...)`.

Same for `UISubsystem` (Sedulous.UI.Runtime), which has its own
analog. Each window-level UI subsystem becomes an `IScreenOverlay`
that records draws into the shared pass.

### `EngineApplication` callsite

Today:
```beef
for (let overlay in mOverlayRenderers)
    overlay.RenderOverlay(encoder, mSwapChain.CurrentTextureView,
        mSwapChain.Width, mSwapChain.Height, mFrameIndex);
```

After:
```beef
let screenRenderer = mContext.GetSubsystemByInterface<IScreenRenderer>();
screenRenderer?.RenderOverlays(encoder, mSwapChain.CurrentTextureView,
    mSwapChain.Width, mSwapChain.Height, mFrameIndex);
```

`mOverlayRenderers` list and the `OnStartup` discovery
(`mContext.GetSubsystemsByInterface<IOverlayRenderer>(mOverlayRenderers)`)
both go away. `RenderSubsystem` discovers / registers overlays through
its `IScreenRenderer.RegisterOverlay` API instead - each overlay
subsystem self-registers in `OnInit`.

### Overlay self-registration

```beef
// In EngineUISubsystem.OnInit (after the existing setup):
let screenRenderer = Context?.GetSubsystemByInterface<IScreenRenderer>();
screenRenderer?.RegisterOverlay(this);

// In OnShutdown:
let screenRenderer = Context?.GetSubsystemByInterface<IScreenRenderer>();
screenRenderer?.UnregisterOverlay(this);
```

This replaces the previous "engine app discovers everyone with
`IOverlayRenderer` via reflection-style interface scan" pattern with
explicit registration on the renderer.

Init-order note: each overlay's `OnInit` must run after
`RenderSubsystem.OnInit`. Most overlays already depend on
`RenderSubsystem` for other reasons (Device, ShaderSystem); confirm
during implementation.

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | Add `IScreenOverlay` + `IScreenRenderer` interfaces. `RenderSubsystem` implements `IScreenRenderer` (registry + `RenderOverlays`). Old `IOverlayRenderer` interface still in place; not used yet. | Builds clean. Nothing routes through the new path yet. |
| B | Migrate `ScreenUIView`: rename `RenderOverlay` → `Render`, drop the internal `BeginRenderPass`/`End`, change first param to `IRenderPassEncoder`. | Builds clean. Existing callers updated. |
| C | Migrate active `IOverlayRenderer` implementers to `IScreenOverlay` (`EngineUISubsystem`, `Sedulous.UI.Runtime.UISubsystem`). Each self-registers with `IScreenRenderer` in `OnInit`, unregisters in `OnShutdown`. | Both subsystems now go through the new path. `EngineApplication` still has its old loop; both paths coexist briefly. |
| D | `EngineApplication.OnRenderFrame` calls `RenderSubsystem.RenderOverlays(...)`. Remove the per-overlay loop and the `mOverlayRenderers` field + `OnStartup` discovery. | Sandbox renders identically. Single shared render pass for all overlays. |
| E | Delete old `IOverlayRenderer` interface file. Confirm no stragglers. Migrate deprecated overlay implementers (LegacyUI / LegacyGUI) to `IScreenOverlay` if those projects still build. | Old interface gone. Full chain still builds. |

Sub-phase C is the safe-coexistence step: both the old per-overlay
loop and the new shared-pass path are live at the same time, but
`EngineApplication` hasn't yet switched to call `RenderOverlays`. So
the new path is registered but unused. Sub-phase D is the switch.

## Files

**New:**
- `Code/Engine/Sedulous.Engine.Render/src/IScreenOverlay.bf`
- `Code/Engine/Sedulous.Engine.Render/src/IScreenRenderer.bf`

**Modified:**
- `Code/Engine/Sedulous.Engine.Render/src/RenderSubsystem.bf` -
  implements `IScreenRenderer`, adds registry + `RenderOverlays`
- `Code/Engine/Sedulous.Engine.App/src/EngineApplication.bf` -
  removes `mOverlayRenderers` field and the discovery + iteration
  loop; calls `RenderSubsystem.RenderOverlays` once
- `Code/Engine/Sedulous.Engine.UI/src/EngineUISubsystem.bf` -
  switches from `: IOverlayRenderer` to `: IScreenOverlay`, signature
  + body updated, self-registers in `OnInit`
- `Code/Engine/Sedulous.Engine.UI/src/ScreenUIView.bf` - rename
  `RenderOverlay` → `Render`, drop internal `BeginRenderPass`/`End`,
  first param becomes `IRenderPassEncoder`
- `Code/Foundation/Sedulous.UI.Runtime/src/UISubsystem.bf` - same
  pattern as `EngineUISubsystem` (switch to `IScreenOverlay`, drop
  internal render pass)
- Deprecated paths (`Code/Deprecated/...`) - same conversion if they
  still build; otherwise note + skip

**Deleted:**
- `Code/Engine/Sedulous.Engine.Render/src/IOverlayRenderer.bf` (sub-phase E)

## Not in scope for v1

- **Editor / embedded-play integration.** `RenderOverlays` takes
  exactly one `target`, so calling it from inside an editor viewport's
  render path would draw every registered overlay into that viewport -
  including overlays that belong to other windows or the editor's own
  chrome. That's a different problem with at least three plausible
  shapes (per-overlay scope tagging, filtered `RenderOverlays(target,
  filter)`, or just "embedded-play scene UI never registers as a
  screen overlay - it lives entirely on the per-pipeline path from
  Tracks 1 / 2"). My current best guess is option 3, but it's worth
  designing when embedded play is on the table, not now.
- **Multi-window screen overlay routing.** Same reason. v1 assumes
  one window's swap chain is the target. Multi-window adds a routing
  layer (which overlays go to which window) that needs its own
  design.
- **Cross-overlay coordination** (e.g., one overlay reading another's
  state). The shared render pass is a perf win; it doesn't add
  inter-overlay communication. If real use cases appear, build them
  on top.
- **Overlay-side `IRenderPassEncoder` extensions** beyond what the
  existing `IOverlayRenderer` callers already use (no depth buffer,
  no MRT). Adding those is a larger conversation.

## After Track 4

Tracks 0-4 close out the UI rendering issues catalogued in
[UI_RENDERING.md](UI_RENDERING.md). At that point:

- Scene UI flows through `IPipelineOverlay` (per-pipeline, scoped to
  the scene's render target)
- Window-level UI flows through `IScreenOverlay` (registered with
  `RenderSubsystem`, single shared render pass per frame)
- Per-component / per-instance state is shared in the relevant
  manager (`UISceneModule`, `BillboardUIComponentManager`,
  `UIComponentManager` - all using one `VGRenderer` instance each
  via the ring-offset API from Track 3)

The remaining architectural decisions about embedded play surface
themselves once that feature is actually being built - the answers
are likely shaped by what the editor's render path looks like at
that point, not by speculation now.
