# Billboard UI (`BillboardUIComponent`)

**Status:** Shipped 2026-06-10. Deferred items consolidated in
[UI_DEFERRED.md](UI_DEFERRED.md).

Track 1 from [UI_RENDERING.md](UI_RENDERING.md). Adds the lightweight
world-anchored UI path - damage numbers, floating health bars,
nameplates, world-space tooltips. Per-instance entity-attached
components share rendering through one manager-owned `VGRenderer`
that draws into the scene's pipeline output via Track 0's
[`IPipelineOverlay`](PIPELINE_OVERLAY_DONE.md) hook.

Companion to Track 2 ([UI_SCENE_DONE.md](UI_SCENE_DONE.md)): same per-pipeline
overlay mechanism, different anchoring model. Scene HUD is one
singleton per scene; billboards are many-per-scene, each tied to an
entity.

See [UI_RENDERING.md](UI_RENDERING.md) for the full problem context;
this doc is just the design + plan.

## Design

### `BillboardUIComponent`

Entity-attached. The component declares an anchor (entity transform +
offset), an orientation/anchor mode, a scaling mode, and a content
view subtree.

```beef
// Sedulous.Engine.UI

public enum BillboardOrientation
{
    /// Offset is applied in the anchor entity's local space - so the
    /// billboard follows the entity's rotation. Useful for "button on
    /// character's arm" cases.
    ScreenBillboard,

    /// Offset is applied in world space (Y always world-up). Billboard
    /// position stays at a fixed world-relative offset from the entity
    /// regardless of the entity's rotation. The typical mode for
    /// nameplates / health bars above enemies.
    Cylindrical,
}

public enum BillboardScale
{
    /// Content renders at its native size regardless of distance.
    /// Damage numbers, HUD-style nameplates.
    Fixed,

    /// Content scales inversely with distance to camera. At
    /// `ReferenceDistance`, scale = 1; closer = larger, farther =
    /// smaller. Clamped to `[MinScale, MaxScale]`.
    Distance,
}

public class BillboardUIComponent : Component
{
    /// World-space offset from the anchor entity's position.
    public Vector3 Offset;

    /// Orientation / anchor mode (see enum).
    public BillboardOrientation Orientation = .Cylindrical;

    /// Scaling mode (see enum).
    public BillboardScale ScaleMode = .Fixed;

    /// Reference distance for `BillboardScale.Distance` (world units).
    public float ReferenceDistance = 5.0f;

    /// Clamp bounds for `BillboardScale.Distance`.
    public float MinScale = 0.25f;
    public float MaxScale = 4.0f;

    /// The view subtree this billboard renders. Owned by the component
    /// while it's alive; added as a child of the manager's shared root
    /// during `OnComponentCreated` and removed on destroy.
    public View Content;
}
```

### `BillboardUIComponentManager`

`ComponentManager<BillboardUIComponent>` + `SceneModule` +
`IPipelineOverlay`. Owns the shared `UIContext`, `RootView`,
`VGContext`, and `VGRenderer` for every billboard in the scene.

**Shared root strategy (Option B from the decision):** the manager
owns one full-screen `AbsoluteLayout` `RootView`. Each component's
`Content` view is added as a child with `AbsoluteLayout.LayoutParams`
whose `X` / `Y` are recomputed each frame to the projected screen
position. One layout pass + one VG batch + one draw call per frame
for the entire scene's billboards (instead of N per-component
renders).

**Order = 50.** Draws under Scene HUD (Order = 100, Track 2) so HUD
sits on top.

**Initialization mirrors `UISceneModule`:** `Initialize(device,
pipelineOutputFormat, frameCount, fontService, shaderSystem,
sharedStyleSheet)` builds the UI / VG resources. Called by
`EngineUISubsystem` in `OnSceneReady` with the scene's
`pipeline.OutputFormat`.

### Per-frame flow (`Render`)

```
Render(encoder, view, pipeline):
    1. Get VP matrix from view (view.ViewProjectionMatrix)
    2. Walk active components:
         worldPos = ComputeWorldPosition(component, scene)
         clip    = Project(worldPos, vp)
         if clip.w <= 0:
             // Behind-camera projection produces nonsense NDC.
             // Position off-screen so the GPU clips the content
             // naturally and HitTest returns null for normal cursor
             // positions. No UI-tree modification - see "Culling"
             // below.
             screenXY = (-10000, -10000)
         else:
             screenXY = ClipToScreen(clip, view.Width, view.Height)
         scale   = ComputeScale(component, camera→entity distance)
         update Content.LayoutParams { X = screenXY.x - anchorOffset.x,
                                        Y = screenXY.y - anchorOffset.y,
                                        (optional ScaleX/Y if Distance) }
         depth = -clip.z / max(clip.w, eps)  (used for z-sort below)
    3. Sort root's children by depth (farther first so closer draws on top)
    4. UpdateRootView(root) - one layout pass for all billboards
    5. mVGContext.Clear()
    6. mUIContext.DrawRootView(root, mVGContext) - one batch
    7. mVGRenderer.UpdateProjection / Prepare / Render - one draw call
```

`ComputeWorldPosition` interprets `Orientation`:
- `ScreenBillboard`: `entity.LocalToWorld(component.Offset)` - offset
  rides the entity's transform
- `Cylindrical`: `entity.WorldPosition + component.Offset` - offset in
  world space (Y stays world-up regardless of entity rotation)

`ComputeScale` interprets `ScaleMode`:
- `Fixed`: returns 1.0
- `Distance`: `clamp(ReferenceDistance / distance, MinScale, MaxScale)`

`Distance` mode requires applying a 2D scale to the content. Either
via a wrapper view that scales children, or via a per-component
`ViewTransform` on the content view. Phase D nails the exact API once
we're in the code.

### Z-order between billboards

Closer billboards should draw on top of farther ones. **Deferred from
v1** - re-sorting via `ViewGroup.RemoveView`/`InsertView` each frame
triggers `DetachView`/`AttachView` per moved child, which churns
hover / focus / mutation-queue state. A clean solution needs either a
non-destructive child reorder API on `ViewGroup` (an explicit
`MoveChild(child, newIndex)` that doesn't detach), or a Z field on
`LayoutParams` that the layout/draw path respects. Either is its own
design and out of scope for Track 1 v1.

v1 just draws billboards in scene-add order. Overlapping billboards
may render with wrong z-order; acceptable for damage numbers and most
small floating UIs.

### Culling

**v1 doesn't cull.** Culling means deciding "this content shouldn't
participate in layout / hit-test / draw this frame," which from inside
the UI framework means manipulating `Visibility`, tree membership, or
similar tree state - and any of those have side effects (layout
invalidation, focus management, event suppression, animations, etc.)
that aren't appropriate for cull decisions made by something *outside*
the UI's own semantics. A user setting `Content.Visibility = .Hidden`
for game-logic reasons becomes indistinguishable from a manager-set
cull state.

For v1 the manager treats every active component as on-screen and
positions it via `LayoutParams.X / Y`. Behind-camera math is handled
purely as a positioning concern (off-screen coords as shown in the
flow above) so the GPU clips and HitTest naturally returns null for
cursor positions. No `Visibility` or tree membership is touched for
cull reasons.

A structured UI-culling solution is a separate future effort - see
"Not in scope" below.

### Input chain integration

Billboards are typically non-interactive, but the user case (clickable
world prompts) exists, so we wire input. The manager's `UIContext`
joins the engine's input chain after the Scene HUD context:

```
window UI -> scene HUD (UISceneModule) -> billboards (BillboardUIComponentManager) -> world UI raycast
```

`EngineUISubsystem` extends its per-frame chain building to add each
scene's `BillboardUIComponentManager.UIContext` after that scene's
`UISceneModule.UIContext`. Chain dispatch already handles "first
context whose `Handled` returns true wins" - billboards inherit this
behavior for free.

Hit-testing into the manager's root walks the root's children (each
component's `Content`). Components with `Visibility = .Gone` (behind-
camera-culled) are skipped naturally by the existing HitTest. So
clicking on a visible billboard hits the content view; clicking
anywhere else falls through to the next context (world UI raycast).

### Resource ownership

| Resource | Ownership |
|---|---|
| `UIContext` | Owned by `BillboardUIComponentManager` (per-scene). Separate from `UISceneModule`'s for input isolation. |
| `RootView` (full-screen `AbsoluteLayout`) | Owned by manager. |
| Component `Content` view | Owned by `BillboardUIComponent` while alive; added as child of manager's root during `OnComponentCreated`; removed on destroy. |
| `VGContext` | Owned by manager. |
| `VGRenderer` | Owned by manager. Separate from `UISceneModule`'s for v1; future optimization could share per-scene. |
| `StyleSheet` | Borrowed from `EngineUISubsystem` (same `SharedStyleSheet` pattern as `UIComponentManager` / `UISceneModule`). |
| `FontService`, `ShaderSystem` | Borrowed from host application. |

### Lifecycle

Mirrors `UIComponentManager`'s pattern + `UISceneModule`'s pipeline
hookup:

- `EngineUISubsystem.OnSceneCreated`: construct
  `BillboardUIComponentManager`, set borrowed Device / FontService /
  ShaderSystem / SharedStyleSheet fields, `scene.AddModule(it)`.
- `EngineUISubsystem.OnSceneReady`: get pipeline, call
  `manager.Initialize(device, pipeline.OutputFormat, frameCount, ...)`,
  `pipeline.RegisterOverlay(manager)`.
- `EngineUISubsystem.OnSceneDestroyed`: unregister overlay; scene's
  module removal triggers manager's Dispose (cleans VG + UI resources;
  components' `Content` is owned by components, freed with them).
- Component-side: `OnComponentCreated` adds `Content` as child of
  `manager.Root` with default `AbsoluteLayout.LayoutParams`. Component
  takes ownership of `Content` ref; manager's root holds the reference
  but doesn't own (caller manages).

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | `BillboardUIComponent` + enums (`BillboardOrientation`, `BillboardScale`); empty `BillboardUIComponentManager` skeleton (SceneModule + IPipelineOverlay shells, no render logic) | Builds clean. Component can be created on entities; manager accepts registration with `pipeline.RegisterOverlay`. |
| B | Manager VG init / teardown (mirrors UISceneModule's `Initialize`); shared `AbsoluteLayout` root constructed | Lifecycle test: create scene → add component → destroy scene → no leaks. |
| C | Projection helpers + `Render` minus orientation/scaling: project world position to screen, update child LayoutParams, layout + draw via VG. Hardcoded `Cylindrical` + `Fixed` only. | Sandbox: a single test billboard with a Label renders at the projected screen position of a test entity. Moving the entity moves the billboard. |
| D | `BillboardOrientation.ScreenBillboard` (offset transformed through entity matrix). | Test billboard with rotating entity: ScreenBillboard offset follows entity rotation, Cylindrical doesn't. |
| E | `BillboardScale.Distance` (apply 2D scale to content based on camera distance). | Test billboard scales as test camera moves closer / farther. |
| F | Behind-camera projection handled by off-screen position clamp (positioning only, no Visibility / tree manipulation). Z-order sorting deferred - see "Z-order" section. | Billboard whose anchor moves behind camera disappears via off-screen position. (Z-sort tested when the underlying ViewGroup reorder API lands.) |
| G | `EngineUISubsystem` wiring: construct + add manager in `OnSceneCreated`, register in `OnSceneReady`, unregister in `OnSceneDestroyed`. Input chain extended to include manager's `UIContext` after scene's `UISceneModule.UIContext`. | Sandbox: clicking on a billboard's Button increments its own counter; clicking elsewhere falls through to world UI / camera as expected. |
| H | Sandbox demo: a couple of billboard examples (a non-interactive nameplate above the test cube, a clickable damage-number popup spawner) | Visual + functional end-to-end confirmation. |

## Files

**New:**

- `Code/Engine/Sedulous.Engine.UI/src/BillboardUIComponent.bf`
- `Code/Engine/Sedulous.Engine.UI/src/BillboardUIComponentManager.bf`
- `Code/Engine/Sedulous.Engine.UI/src/BillboardOrientation.bf` (or
  inline in component file)
- `Code/Engine/Sedulous.Engine.UI/src/BillboardScale.bf` (ditto)

**Modified:**

- `Code/Engine/Sedulous.Engine.UI/src/EngineUISubsystem.bf`:
  - `OnSceneCreated`: construct + add `BillboardUIComponentManager`
  - `OnSceneReady`: initialize + register manager as `IPipelineOverlay`
  - `OnSceneDestroyed`: unregister
  - Per-frame chain building: add manager's `UIContext` to the chain
  - `IsMouseOverUI`: widen to also check each scene's
    `BillboardUIComponentManager.Root`

**Sandbox (sub-phase H only):**

- `Code/Samples/EngineSandbox/src/SandboxApp.bf` - add billboard demo
  setup

## Tests

Same lightweight integration confidence as Track 2 - build + sandbox
visual + cleanup. Worth a targeted unit test once the projection +
scale math lands (sub-phase E or F):

- Projection: a known world position with a known camera view-
  projection produces the expected screen coords.
- Distance scale: at `ReferenceDistance` scale = 1; at 2x = 0.5;
  clamped at `MinScale` / `MaxScale`.
- Z-sort: two billboards at known depths sort in the right order.

## Not in scope for v1

- **UI culling.** No `Visibility` / tree-membership manipulation by the
  manager for cull reasons. v1 lays out and renders every active
  component, relying on GPU clipping for off-screen / behind-camera
  content. A structured culling mechanism that doesn't conflict with
  user-controlled view state needs its own design pass - likely
  introducing a UI-framework-level concept like "render-only off"
  that's distinct from `Visibility`. Pull this in once that design
  lands; it benefits Scene HUD (Track 2) the same way it benefits
  billboards.
- **Worldspace-rotated billboards (true 3D quad billboards).** Tier A
  (`UIComponent`) covers world-aligned 3D panels. Tier B is always
  screen-space drawing at a projected world point.
- **Cinematic camera-roll variants.** "Screen-billboard" + "cylindrical"
  are conceptually the same in pure screen-space drawing if the camera
  doesn't roll. If camera-roll handling is needed later, add a
  `BillboardOrientation.WorldUp` mode that applies an inverse-roll 2D
  rotation to content.
- **Cross-scene sharing of `VGRenderer`.** Each scene's
  `BillboardUIComponentManager` has its own. Future optimization can
  share keyed by `(device, format, frameCount)`.
- **Sharing `VGRenderer` with `UISceneModule` in the same scene.**
  Separate for v1; refactor later if profile shows it matters.
- **Animated transitions between visibility states.** When a billboard
  comes into view (was culled, now isn't) it just appears. Smooth fade
  is a future polish item.
- **Per-billboard input gating.** If a clickable billboard exists,
  every billboard's `Content` participates in hit-testing. There's no
  "this billboard is render-only" opt-out flag yet. Add when needed
  (set `Content.IsHitTestVisible = false` works as a manual workaround
  even in v1).

## After Track 1

With Tracks 0, 1, 2 landed, the full picture from
[UI_RENDERING.md](UI_RENDERING.md) is complete except for:

- **Track 3** - shared `VGRenderer` for existing `UIComponent` (Tier
  A). Independent perf win.
- **Track 4** - window UI path refinement (Tier D). Independent
  polish.

Cross-pollination opportunities once both 1 and 2 are stable:

- Share a single `VGRenderer` across `UISceneModule` and
  `BillboardUIComponentManager` per scene. Cuts ~15 MB per scene.
- Share a single `UIContext` if input ownership semantics allow it
  (likely yes - one input scope per scene rather than two).
- Both could be folded into a single `SceneUIModule` that owns both
  the singleton HUD root + the entity-anchored billboard layer.
  Architecturally tidier; lose a little API symmetry.
