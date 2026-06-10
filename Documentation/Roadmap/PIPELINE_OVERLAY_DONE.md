# Per-Pipeline Overlay Mechanism

**Status:** Shipped 2026-06-10. Deferred items consolidated in
[UI_DEFERRED.md](UI_DEFERRED.md).

Track 0 from [UI_RENDERING.md](UI_RENDERING.md). Adds a renderer-side
extension point that lets external subsystems contribute draws to a
pipeline's output target with access to the active `RenderView` and
without coupling the renderer to those subsystems' rendering tech.

This is the foundation that unblocks lightweight billboard UI (Track 1)
and scene screen-space UI (Track 2). It is also the right hook for any
future "draw something on top of a pipeline's scene" use case that
isn't debug instrumentation.

See [UI_RENDERING.md](UI_RENDERING.md) for the full problem context;
this doc is just the design + plan.

## Design

### `IPipelineOverlay` interface

```beef
// Sedulous.Renderer

public interface IPipelineOverlay
{
    int32 Order { get; }
    void Render(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline);
}
```

Lives in `Sedulous.Renderer` (same project as `Pipeline`). Signature
uses only renderer-level types — `IRenderPassEncoder`, `RenderView`,
`Pipeline`. No engine concepts, no VG types. Boundary from
UI_RENDERING.md issue #6 preserved.

`Order` controls draw priority within a pipeline. Lower runs first.
External callers (engine UI, editor diagnostics, custom subsystems)
implement this interface and register with the pipelines they want to
draw into.

### `Pipeline` registry

`Pipeline` gains a small overlay registry:

```beef
// Sedulous.Renderer.Pipeline

private List<IPipelineOverlay> mOverlays = new .() ~ delete _;

public Span<IPipelineOverlay> Overlays => mOverlays;

public void RegisterOverlay(IPipelineOverlay overlay)
{
    // Insertion-sorted by Order so iteration is just a forward walk.
    int idx = 0;
    while (idx < mOverlays.Count && mOverlays[idx].Order <= overlay.Order)
        idx++;
    mOverlays.Insert(idx, overlay);
}

public void UnregisterOverlay(IPipelineOverlay overlay)
{
    mOverlays.Remove(overlay);
}
```

No ownership transfer — the registry stores references; callers own
the implementation's lifetime. `UnregisterOverlay` must be called
before the overlay is deleted.

### `OverlayPass` (the reclaimed name)

```beef
// Sedulous.Renderer.Passes.OverlayPass

class OverlayPass : PipelinePass
{
    public override StringView Name => "Overlay";

    public override void AddPasses(RenderGraph graph, RenderView view, Pipeline pipeline)
    {
        if (pipeline.Overlays.IsEmpty)
            return;

        let outputHandle = graph.GetResource("PipelineOutput");
        if (!outputHandle.IsValid)
            return;

        graph.AddRenderPass("Overlay", scope (builder) => {
            builder
                .SetColorTarget(0, outputHandle, .Load, .Store)
                .NeverCull()
                .SetExecute(new [=] (encoder) => {
                    Execute(encoder, view, pipeline);
                });
        });
    }

    private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
    {
        using (Profiler.Begin("Overlay"))
        {
            for (let overlay in pipeline.Overlays)
                overlay.Render(encoder, view, pipeline);
        }
    }
}
```

**One render pass total** for all registered overlays, avoiding the
per-overlay `BeginRenderPass` / `End` switching that plagues the
current `IOverlayRenderer` path (UI_RENDERING.md issue #5).

**No depth attachment** for v1. Always-on-top semantics. Overlays
configure their own pipeline state with `DepthMode = .Disabled`. Adding
depth-aware overlays later (e.g., world prompts occluded by walls) is
non-breaking — separate pass or attachment-as-option, decided then.

### Pass placement

Insert between `ParticlePass` and `DebugGeometryPass` in
`RenderSubsystem.bf` pass registration order:

```
DepthPrepass
ForwardOpaquePass
DecalPass
SkyPass
ForwardTransparentPass
ParticlePass
OverlayPass            ← NEW: scene UI / game HUD
DebugGeometryPass      ← editor gizmos draw on top of scene UI
DebugScreenPass        ← perf / debug text on top of everything
```

Conceptual three-tier composition:

1. **Game-visible content** (forward, particles, OverlayPass)
2. **Editor / tooling** (DebugGeometryPass — gizmos, axes, debug primitives)
3. **Diagnostic** (DebugScreenPass — perf HUD, frame stats, debug text)

Editor gizmos correctly appear over game UI so they remain
manipulable; diagnostic text is never occluded.

### Multi-window / multi-pipeline propagation

Registration is per-`Pipeline` directly. Callers manage the mapping
between their scope (scene, viewport, undocked window) and the pipelines
they want to draw into.

Typical flow for a scene-attached overlay:

- `UISceneModule.OnSceneCreate(scene)` discovers which pipelines the
  scene is rendered through (via existing extraction-time scene-to-
  pipeline associations) and calls `pipeline.RegisterOverlay(this)` on
  each.
- `UISceneModule.OnSceneDestroy` unregisters from each.
- When a scene gets bound to a new pipeline at runtime (editor docks a
  scene into a new viewport), register on the new pipeline; when
  unbound, unregister.

Pipeline registry stays a flat list; the multi-window complexity lives
at the scene-module layer where it belongs and where the bookkeeping is
already needed for other reasons.

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | Define `IPipelineOverlay` + `Pipeline.RegisterOverlay`/`UnregisterOverlay`/`Overlays` | Builds clean. Registration/unregistration unit tests pass. Order-sorted insertion verified. |
| B | Create `OverlayPass` + wire into pass registration in `RenderSubsystem.bf` between `ParticlePass` and `DebugGeometryPass` | Builds clean. With no overlays registered, sandbox renders identically to today. Render graph dump shows the new pass slot. |
| C | Sandbox stub overlay drawing a screen-space rect via a simple test pipeline | A colored rect renders in the sandbox at the right position; confirms encoder + view + pipeline are wired correctly. Disposes cleanly on shutdown. |
| D | Unit tests for `Pipeline` registry (register/unregister, order, no-overlay early-out) | Tests pass under `Sedulous.Renderer.Tests` (or wherever pipeline tests live). |

Sub-phase C's stub can be discarded after Track 1 / Track 2 land —
it's an integration smoke test, not shipped code.

## Files

**New:**

- `Code/Foundation/Sedulous.Renderer/src/IPipelineOverlay.bf` —
  interface
- `Code/Foundation/Sedulous.Renderer/src/Passes/OverlayPass.bf` — pass
  implementation

**Modified:**

- `Code/Foundation/Sedulous.Renderer/src/Pipeline.bf` — add `mOverlays`
  list, `Overlays` accessor, `RegisterOverlay` / `UnregisterOverlay`
  methods, cleanup in destructor (no overlay deletion — non-owning
  registry)
- `Code/Engine/Sedulous.Engine.Render/src/RenderSubsystem.bf` — insert
  `pipeline.AddPass(new OverlayPass())` between `ParticlePass` and
  `DebugGeometryPass` (line ~1399-1400)

## Tests

Under `Code/Foundation/Sedulous.Renderer.Tests` (or matching test
project — discover at sub-phase D):

- **Registry tests:** register → `Overlays` contains it; unregister →
  it's gone; double-register doesn't duplicate; unregister of
  unregistered is a no-op.
- **Order tests:** registering overlays out of order produces a
  sorted iteration; same Order is stable (insertion order within
  ties).
- **Pass early-out:** `OverlayPass.AddPasses` adds nothing to the
  graph when `Overlays.IsEmpty`.
- **Render dispatch:** a mock `IPipelineOverlay` records calls;
  confirms `Render` receives non-null encoder, the expected
  `RenderView`, and the owning `Pipeline`.

Sandbox-level integration (sub-phase C) is the end-to-end test for the
encoder-actually-draws path.

## Not in scope for v1

- **Depth-aware overlays.** Pass has no depth attachment in v1. Adding
  later is non-breaking (separate pass, or attachment-as-option).
- **Per-overlay color-target overrides.** All overlays draw into
  `PipelineOutput` with `LoadOp.Load`. If a future overlay wants a
  different target (e.g., a separate UI render target for editor
  picking), that's a separate mechanism.
- **Overlay scheduling beyond `Order`.** No "run after pass X" or
  "group with Y" — just a single sorted int. Sufficient for current
  uses; richer scheduling is a v2 problem if it shows up.
- **Thread-safe registration.** Register/Unregister assume single-
  threaded access from the engine update path. If a use case appears
  for off-thread registration, add a lock then.
- **Persistence / serialization of overlays.** Overlays are code-side
  registrations, not scene data.
- **Generic `IPipelineOverlay` outside UI.** This doc focuses on the
  hook itself; how UI / editor / custom subsystems use it is each of
  their concerns. Track 1, 2, and any future track using this hook
  document their own usage.

## After Track 0

Track 0 alone changes nothing user-visible (no overlays registered by
default). It's pure infrastructure. The follow-ons:

- **Track 3** (shared VGRenderer in `UIComponentManager`) — independent
  of Track 0, but could be done concurrently to validate the
  shared-renderer pattern.
- **Track 1** (`BillboardUIComponent` / Manager) — implements
  `IPipelineOverlay`, registers per-pipeline, draws billboards via a
  shared VGRenderer.
- **Track 2** (`UISceneModule`) — implements `IPipelineOverlay`,
  registers per-pipeline, draws scene HUD via the same or a
  scene-shared VGRenderer.

Both Track 1 and Track 2 produce concrete `IPipelineOverlay`
implementations once this foundation lands.
