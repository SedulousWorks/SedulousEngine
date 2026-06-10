# Shared `VGRenderer` for `UIComponent`

**Status:** Shipped 2026-06-10. Deferred items consolidated in
[UI_DEFERRED.md](UI_DEFERRED.md).

Track 3 from [UI_RENDERING.md](UI_RENDERING.md). Eliminates the
per-`UIComponent` `VGRenderer` (~15 MB GPU vertex/index buffers + an
internal pipeline state object per instance). After this lands a
single shared `VGRenderer` lives on `UIComponentManager` and every
component in the scene draws through it.

For 40 world-UI components today this is roughly **~600 MB → ~15 MB**
of VG buffer memory. The per-component render texture (~1 MB at
512×512 RGBA8) stays - that's legitimate Tier A cost since each panel
has its own content.

See [UI_RENDERING.md](UI_RENDERING.md) issue #1 for the original
diagnosis and the broader rationale.

## The technical hurdle

`VGRenderer`'s current per-frame buffer model writes from offset 0 on
every `Prepare(batch, frameIndex)`. Each `Render` call reads from the
same offset 0. With one `VGRenderer` per component (today), each
component has its own private buffers - no conflict.

With a shared `VGRenderer` serving multiple components per frame:

```
CPU:
  Prepare(batch1, 0)  ← writes batch1 to buf[0] @ offset 0
  RecordPass1(... offset=0 ...)
  Prepare(batch2, 0)  ← OVERWRITES buf[0] @ offset 0 with batch2
  RecordPass2(... offset=0 ...)
  Submit

GPU:
  Execute Pass1 → reads buf[0] = batch2 (WRONG)
  Execute Pass2 → reads buf[0] = batch2
```

The buffer writes are CPU-side into mapped memory; the GPU only reads
during command execution, after submit. So multiple components per
frame with shared buffers conflict.

This must be solved before the shared-renderer refactor is safe.

## Solution: ring-offset Prepare/Render

Each frame the shared `VGRenderer` allocates fresh slices out of its
per-frame buffers. `Prepare` appends; `Render` reads from the slice
that the corresponding `Prepare` returned.

```beef
// VGRenderer additions:

public struct VGRenderSlice
{
    public uint32 VertexOffset;
    public uint32 VertexCount;
    public uint32 IndexOffset;
    public uint32 IndexCount;
    public int    DrawCommandStart;
    public int    DrawCommandCount;
}

/// Resets per-frame offsets. Call once per frame before the first
/// Prepare (any subsequent Prepare in the same frame appends).
public void BeginFrame(int32 frameIndex);

/// Uploads the batch to the next available slice in this frame's
/// buffers and returns a token to use with Render.
public VGRenderSlice Prepare(VGBatch batch, int32 frameIndex);

/// Renders just the slice that Prepare returned (binds offsets,
/// draws those commands).
public void Render(IRenderPassEncoder encoder, uint32 width,
                   uint32 height, int32 frameIndex, VGRenderSlice slice);
```

**No legacy wrappers.** Every existing caller migrates to the new
shape (`BeginFrame` once per frame, then `Prepare` returning a slice,
then `Render(..., slice)`). For single-batch-per-frame callers
(UISceneModule, BillboardUIComponentManager, ScreenUIView) this is a
mechanical edit: add one `BeginFrame` line, capture the `slice` from
`Prepare`, pass it to `Render`. Call sites are enumerated in the Files
section.

Overflow: if the sum of slices in a frame exceeds the buffer capacity
(currently `MAX_VERTICES = 131072`), additional `Prepare` calls return
an empty slice and log a warning. Capacity can be bumped if real
content needs more, but for the typical world-UI workload (a few
panels with hundreds of vertices each) the existing cap is fine.

## Design

### `UIComponentManager` ownership change

Manager gains:

```beef
private VGContext mSharedVG;
private VGRenderer mSharedVGRenderer;

public VGContext SharedVG => mSharedVG;
public VGRenderer SharedVGRenderer => mSharedVGRenderer;
```

Initialized lazily on first `OnComponentInitialized` (when `Device` /
`FontService` / `ShaderSystem` are already injected). Disposed in
`Dispose`.

Format and frame count are hardcoded to `.RGBA8UnormSrgb` + `2`
(matches every existing world UI texture; no scene mixes formats).

### `UIComponent` simplification

Removes:
```beef
public VGContext VG;        // gone
public VGRenderer Renderer; // gone
```

Keeps:
```beef
public UIContext UIContext;
public RootView Root;
public ITexture Texture;
public ITextureView TextureView;
public bool IsDirty;
// ... existing serialized + sprite fields
```

### `WorldUIPass.ExecuteWorldUI` rewrite

Today reads `comp.VG` and `comp.Renderer` directly. Switches to:

```beef
// Pass gains a Manager reference set at registration time.
public UIComponentManager Manager;

private static void ExecuteWorldUI(IRenderPassEncoder encoder,
                                    UIComponent comp,
                                    UIComponentManager mgr,
                                    VGRenderSlice slice)
{
    // ... layout + uiCtx.DrawRootView(comp.Root, mgr.SharedVG) ...
    // ... mgr.SharedVGRenderer.Render(encoder, w, h, 0, slice) ...
}
```

`AddPasses` BeginFrame's the shared renderer once, then per dirty
component:
1. Builds the batch (`mgr.SharedVG.Clear()` then
   `uiCtx.DrawRootView(comp.Root, mgr.SharedVG)`)
2. `slice = mgr.SharedVGRenderer.Prepare(batch, 0)` - captures the
   slice
3. Records the render pass, capturing `slice` for the execute closure
4. The execute closure calls
   `mgr.SharedVGRenderer.Render(encoder, w, h, 0, slice)`

`SharedVG` gets cleared per component because we only need the batch
data through the `Prepare` call that copies vertices into the shared
buffer slice.

### Sprite-display sub-component is unchanged

The Sprite + MaterialInstance that displays the per-component texture
in the 3D scene stays the same. Track 3 only changes how the texture
gets *written* each frame.

### Editor / multi-window

Each scene has its own `UIComponentManager` and so its own shared
`VGRenderer`. Sharing across scenes / windows is the same future
optimization as for Track 1 / Track 2 - not in scope here.

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | `VGRenderer` ring-offset API: `BeginFrame`, `Prepare(batch, frameIndex) → VGRenderSlice`, `Render(..., VGRenderSlice)`. **Old `Prepare`/`Render` signatures removed.** Capacity overflow returns empty slice + warning. | Doesn't build yet - call sites unmigrated. (Intentional - guard against accidental old-API use.) |
| B | Migrate existing single-batch callers: `UISceneModule.Render`, `BillboardUIComponentManager.Render`, `ScreenUIView.RenderOverlay`. Each adds a `BeginFrame` and threads a slice through. | Builds clean. UI tests, sandbox screen UI, scene HUD, billboards render identically. |
| C | `UIComponentManager` gains `SharedVG` + `SharedVGRenderer`, lazy-init in `OnComponentInitialized`, disposed in `Dispose`. (Per-component VG/Renderer fields still created in parallel for now - bypass not yet wired.) | Builds clean. Sandbox world UI unchanged (still uses per-component path). Shared renderer exists but unused. |
| D | `WorldUIPass.Manager` field; `AddPasses` uses shared resources via slice; `ExecuteWorldUI` rewritten to take a slice. | Sandbox world UI still works; render path goes through shared renderer. |
| E | Remove `UIComponent.VG` + `UIComponent.Renderer` fields; remove their construction in `OnComponentInitialized`; clean up `OnComponentDestroyed`. | No memory leak on scene shutdown. Per-instance VG buffer memory dropped. |
| F | Sandbox verification: 1-2 world UI components still display + remain interactive. Optionally bump to 8-10 to demonstrate cost scaling. | Visual + memory inspection. |
| G | **Apply same ring-offset refactor to `DrawingRenderer`** (parallel system in `Sedulous.Drawing.Renderer`). Both the `Prepare`/`Render` path and the `PrepareInstanced`/`RenderInstanced` path get the same treatment. Migrate existing `DrawingRenderer` callers. | Builds clean; any existing drawing-based UI / sprite paths render identically. |

Sub-phase C exists so the migration is reversible mid-flight; if
something breaks in D/E the per-component path is still there to fall
back on while debugging. C is a small intermediate state, not a
shippable end state.

Sub-phase G applies once A-F have proven the pattern works.
`DrawingRenderer` mirrors `VGRenderer`'s structure but with both
batched and instanced flows, so the refactor is the same shape twice.

## Files

**Modified (sub-phase A - VGRenderer API):**

- `Code/Foundation/Sedulous.VG.Renderer/src/VGRenderer.bf` - ring-offset
  `BeginFrame` / `Prepare` (returns slice) / `Render` (takes slice).
  Old signatures removed.

**Modified (sub-phase B - migrate existing single-batch callers):**

- `Code/Engine/Sedulous.Engine.UI/src/UISceneModule.bf` - one BeginFrame
  + slice threaded through Render
- `Code/Engine/Sedulous.Engine.UI/src/BillboardUIComponentManager.bf` -
  same
- `Code/Engine/Sedulous.Engine.UI/src/ScreenUIView.bf` - same

**Modified (sub-phases C-E - shared resources):**

- `Code/Engine/Sedulous.Engine.UI/src/UIComponentManager.bf` - shared
  `SharedVG` + `SharedVGRenderer`, lazy init, dispose
- `Code/Engine/Sedulous.Engine.UI/src/UIComponent.bf` - drop `VG` +
  `Renderer` fields
- `Code/Engine/Sedulous.Engine.UI/src/WorldUIPass.bf` - manager
  reference, slice-based execute path
- `Code/Engine/Sedulous.Engine.UI/src/EngineUISubsystem.bf` - wire
  `WorldUIPass.Manager` at registration time

**Modified (sub-phase G - DrawingRenderer parallel):**

- `Code/Foundation/Sedulous.Drawing.Renderer/src/DrawingRenderer.bf` -
  same ring-offset treatment for `Prepare`/`Render` AND
  `PrepareInstanced`/`RenderInstanced`
- Any existing `DrawingRenderer` call sites (audit during sub-phase G)

**New:**

- (Possibly) `Code/Foundation/Sedulous.VG.Renderer/src/VGRenderSlice.bf`
  if the struct lives in its own file. Could also be nested inside
  `VGRenderer.bf`. Same call for `DrawingRenderSlice` in sub-phase G.

## Not in scope for v1

- **Cross-scene sharing.** Each `UIComponentManager` still has its own
  `VGRenderer`. Sharing across scenes / windows keyed by
  `(device, format, frameCount)` is the same future work flagged for
  Tracks 1 + 2.
- **Format flexibility.** Manager's shared renderer is hardcoded to
  `.RGBA8UnormSrgb` + `frameCount = 2` (the format every world UI
  component currently uses). If a scene ever needs a different
  per-component texture format, the design needs revisit.
- **Capacity tuning.** `MAX_VERTICES = 131072` carries over. Bump if
  overflow shows up.
- **Sharing the manager's `VGRenderer` with `UISceneModule` /
  `BillboardUIComponentManager` in the same scene.** Different format
  (RGBA8 vs RGBA16Float). Same scene-level VGRenderer sharing
  optimization noted for Tracks 1 + 2 applies but isn't pulled in
  here.

## After Track 3

This is the last of the originally-scoped UI rendering tracks except
Track 4 (window UI path refinement - polish for `IOverlayRenderer`
overhead). With Track 3 done, the full Tier A/B/C/D model from
UI_RENDERING.md is shipped and the per-instance VG cost is fixed
across the existing world-UI path that's been in production.
