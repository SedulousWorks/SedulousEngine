# Scene Screen-Space UI (`UISceneModule`)

**Status:** Shipped 2026-06-10. Deferred items consolidated in
[UI_DEFERRED.md](UI_DEFERRED.md).

Track 2 from [UI_RENDERING.md](UI_RENDERING.md). Adds the "game HUD that
lives in this scene" path - one screen-space `RootView` per scene that
draws into that scene's pipeline output via the per-pipeline overlay
hook from Track 0 ([PIPELINE_OVERLAY_DONE.md](PIPELINE_OVERLAY_DONE.md)).

The HUD ends up inside the scene's viewport target in editor preview
(no bleed across viewports) and on the swap chain in runtime, with the
same code in both cases. This is what makes "preview your game inside
the editor" work correctly.

See [UI_RENDERING.md](UI_RENDERING.md) for the full problem context;
this doc is just the design + plan.

## Design

### `UISceneModule` class shape

Singleton-per-scene. Not a component manager - no entity-attached
components. Modeled on `RenderSceneModule` (per-scene singleton state
owner with no managed components):

```beef
// Sedulous.Engine.UI

class UISceneModule : SceneModule, IPipelineOverlay
{
    // === SceneModule lifecycle ===
    public override void OnSceneCreate(Scene scene) { ... }
    public override void OnSceneDestroy() { ... }

    // === IPipelineOverlay ===
    public int32 Order => 100;  // above Track 1 billboards (when they arrive)
    public void Render(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline) { ... }

    // === Public surface for game code ===
    public RootView Root { get; private set; }
    public UIContext UIContext { get; private set; }
}
```

Lives in `Sedulous.Engine.UI` (same place as `UIComponent` /
`UIComponentManager` / `ScreenUIView`).

### Resource ownership

| Resource | Ownership | Sharing |
|---|---|---|
| `UIContext` | Owned by `UISceneModule` | Per-scene. Isolated input routing per scene. |
| `RootView` | Owned by `UISceneModule` | Per-scene. Added to the module's UIContext. |
| `VGContext` | Owned by `UISceneModule` | Per-scene. Scratch for building VG batches. |
| `VGRenderer` | Owned by `UISceneModule` | Per-scene for v1. Sharing across scenes is a future optimization (would key by `(device, format, frameCount)`). |
| `StyleSheet` | Borrowed from `EngineUISubsystem` | Same `SharedStyleSheet` pattern `UIComponentManager` already uses. Consistent theming across screen-space, world-space, and scene UI. |
| `FontService` | Borrowed | Same instance the engine UI uses. |

### Pipeline registration

Following the existing engine-side wiring pattern (mirrors how
`WorldUIPass` gets registered):

- `EngineUISubsystem.OnSceneCreated(scene)`: construct a
  `UISceneModule`, initialize its VG resources, call
  `scene.AddModule(uiSceneModule)`.
- `EngineUISubsystem.OnSceneReady(scene)`: look up the scene's pipeline
  via `sceneRenderer.GetPipeline(scene)`. If non-null, call
  `pipeline.RegisterOverlay(uiSceneModule)`.
- `EngineUISubsystem.OnSceneDestroyed(scene)`: unregister the overlay
  from any pipelines it was registered with. `SceneModule.OnSceneDestroy`
  handles VG resource teardown.

Game code retrieves it via the standard module accessor:
`scene.GetModule<UISceneModule>().Root.AddView(myHUDLayout)`.

### Per-frame flow

`Render` (called by `OverlayPass` once per pipeline per frame) does
layout + draw in one shot:

```
Render(encoder, view, pipeline):
    1. Update Root.ViewportSize from view.Width / view.Height
    2. mVGContext.Clear()
    3. mUIContext.DrawRootView(Root, mVGContext)  ← layout + record VG commands
    4. batch = mVGContext.GetBatch()
    5. if batch empty: return
    6. mVGRenderer.UpdateProjection(view.Width, view.Height, view.FrameIndex)
    7. mVGRenderer.Prepare(batch, view.FrameIndex)
    8. mVGRenderer.Render(encoder, view.Width, view.Height, view.FrameIndex)
```

The render pass and its color-attachment state are already opened by
`OverlayPass` (LoadOp.Load, no depth). `UISceneModule` just records draw
calls into the active encoder.

No depth interaction. Always-on-top semantics for v1 (matches Track 0
scope).

### `Order` field

`UISceneModule` registers with `Order = 100`. Track 1 billboards will
register at a lower value (e.g., 50) so HUD draws on top of billboards
- the typical convention since HUD is the primary readability surface.

Other engine-side overlays (editor diagnostics if any are added later)
should pick `Order` values relative to these:

- `< 50` — backgrounds, far-screen elements
- `50` — billboards / world-anchored views (Track 1)
- `100` — scene HUD (Track 2)
- `> 100` — overlays that should sit above HUD (rare; modal warnings)

### Multi-pipeline scenes (deferred)

A scene currently associates with one pipeline via
`sceneRenderer.GetPipeline(scene)`. Editor multi-viewport (same scene
rendered through multiple pipelines) is a future case:

- `UISceneModule` needs a list of pipelines it's registered with, not
  just one
- `EngineUISubsystem` needs to notice when a scene gets bound to a new
  pipeline and register the overlay there
- Layout still happens once per Render call - each pipeline renders the
  same scene UI through its own view dimensions, so the per-call layout
  cost is paid per viewport (acceptable)

This isn't in scope for Track 2 v1. The interface in Track 0
(`RegisterOverlay` / `UnregisterOverlay`) already supports it; the
plumbing in `EngineUISubsystem` extends naturally when the editor
needs it.

### Input routing

Each tier has its own `UIContext`, so input must be dispatched in a
priority chain. Established convention:

1. **Window UI** (`EngineUISubsystem.mUIContext`) — first dibs.
2. **Scene UI** (`UISceneModule.UIContext` for each active scene) — if
   window didn't consume.
3. **World UI** (`UIComponent`'s per-component contexts, raycast-routed
   today) — if neither window nor scene consumed.

This matches how `IOverlayRenderer` draw order goes: window is the
"outermost / most authoritative" tier; if a modal dialog or main-menu
button is up at the window level, it should swallow clicks before the
HUD or world panel sees them.

**Mechanical change required.** `Sedulous.UI.InputManager.Process*`
methods today return `void` but already track a `Handled` flag on event
args via the capture-phase propagation that shipped in UI v2. To make
the priority chain work, the dispatch methods need to return that flag:

```beef
// Sedulous.UI.InputManager — extended return signatures
public bool ProcessMouseMove(float x, float y)
public bool ProcessMouseDown(MouseButton btn, float x, float y, float t)
public bool ProcessMouseUp(MouseButton btn, float x, float y)
public bool ProcessMouseWheel(float x, float y, float dx, float dy, KeyModifiers mods = .None)
public bool ProcessKeyDown(KeyCode k, KeyModifiers mods, bool isRepeat, float ts = 0)
public bool ProcessKeyUp(KeyCode k, KeyModifiers mods, float ts = 0)
public bool ProcessTextInput(char32 c)
```

Implementation is a one-line change per method: `return mArgs.Handled;`
after the existing dispatch. Existing call sites that ignore the return
value continue to work — Beef permits ignoring return values.

**`UIInputHelper` chain dispatch.** Today `Update(platformInput, context,
deltaTime)` routes to a single context. Add a chain-aware overload:

```beef
public void Update(IInputManager platformInput, Span<UIContext> contextChain, float deltaTime)
```

Existing single-context call sites continue to work via a one-element
chain.

For each event, walk the chain in order; stop on the first context
whose dispatch returns `true`. Mouse events (move, down, up, wheel),
keyboard events (down, up, text input), and gamepad events all follow
the same chain.

**Focus across contexts.** Each `UIContext` has its own `FocusManager`,
so multiple contexts can have focused views simultaneously. For v1, the
chain order resolves the ambiguity: window's focused view wins keyboard
input if window has a focused view; otherwise scene's. A future
refinement is "global focus" (only one view focused across all
contexts) — out of scope for v1.

**`EngineUISubsystem` wiring.** Build the context chain per frame:
window context first, then each active scene's `UISceneModule.UIContext`
in some scene-priority order (likely "active scene" or all scenes — TBD
in sub-phase). Pass to `UIInputHelper.Update`.

**World UI fallback.** The existing world UI raycast / hit-test for
`UIComponent` runs only if no UI context in the chain consumed the
event. Wire this into the same chain dispatch or keep it as a separate
fallback step in `EngineUISubsystem`'s input update — pick during
implementation.

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | `UISceneModule` skeleton: `SceneModule` + `IPipelineOverlay` platforms, VG resource fields, no rendering logic yet | Builds clean. Module can be added to a scene. `pipeline.RegisterOverlay` accepts it. |
| B | VG init / teardown: `Initialize(...)` (takes device, format, frameCount, fontService, shaderSystem, sharedStyleSheet); destructor cleans up; `Root` and `UIContext` constructed | Module life cycle test: create → add to scene → destroy → no leaks. |
| C | `Render` implementation: layout + draw via VGRenderer | Sandbox: add a Label or Button to `Root` via game code; it renders in the engine sandbox. |
| D | `EngineUISubsystem` wiring: construct + add in `OnSceneCreated`, register with pipeline in `OnSceneReady`, unregister + delete in `OnSceneDestroyed` | Sandbox scene has working HUD; closing scene doesn't leak. |
| E | **Input routing — `InputManager.Process*` returns `bool`**: extend the seven dispatch methods to return `args.Handled`; verify existing single-context call sites still work | All UI tests pass; no behavior change for single-context callers. |
| F | **Input routing — `UIInputHelper` chain dispatch**: add `Update(Span<UIContext>, ...)` overload that walks the chain in order, stopping on first `Handled` | Two-context test: event lands on first non-empty context; falls through when first context's RootView has no hit-testable view. |
| G | **Input routing — `EngineUISubsystem` builds the chain**: assemble window UIContext + active scenes' `UISceneModule` UIContexts each frame; pass to `UIInputHelper.Update`; verify world UI fallback still works | Targeted test: synthesized mouse events with mock UIContexts confirm the chain walks in order and stops on first `Handled`. World UI fallback still receives events when neither window nor scene contexts consume. |
| H | Sandbox demo: simple HUD in EngineSandbox (Label + clickable Button) added via `scene.GetModule<UISceneModule>().Root.AddView(...)`; clicking the button fires a game-side callback | Visual + functional confirmation: HUD renders inside the scene render target, composes with debug overlays on top, button click is delivered to scene UI through the input chain. |

## Files

**New:**
- `Code/Engine/Sedulous.Engine.UI/src/UISceneModule.bf` — class + lifecycle + IPipelineOverlay impl

**Modified (rendering):**
- `Code/Engine/Sedulous.Engine.UI/src/EngineUISubsystem.bf`:
  - `OnSceneCreated`: construct + initialize + add `UISceneModule` to scene
  - `OnSceneReady`: register module with `sceneRenderer.GetPipeline(scene)` as `IPipelineOverlay`
  - `OnSceneDestroyed`: unregister + cleanup
  - Per-frame: build the input context chain (window + each active scene's `UISceneModule.UIContext`) and pass to `UIInputHelper.Update`

**Modified (input — sub-phases E/F/G):**
- `Code/Foundation/Sedulous.UI/src/Input/InputManager.bf` — change the seven `Process*` methods to return `bool` (the post-dispatch `args.Handled`). Existing call sites that ignore the return value remain valid.
- `Code/Foundation/Sedulous.UI.Platform/src/UIInputHelper.bf`:
  - Add `Update(IInputManager platformInput, Span<UIContext> contextChain, float deltaTime)` overload
  - Mouse / keyboard / text / gamepad helpers walk the chain, stop on first `Handled`
  - Existing single-context `Update` stays as a one-element-chain wrapper

**Sandbox (sub-phase H only):**
- `Code/Samples/EngineSandbox/...` (or wherever appropriate) — simple HUD demo (Label + clickable Button)

## Tests

Lightweight integration confidence rather than exhaustive unit tests
(matches the renderer-side pattern from Track 0):

- Build verification: full engine sandbox builds with the new module
- Sandbox visual: HUD renders inside the scene render target, not the
  whole window
- Cleanup: scene destroy → no leaks (VGRenderer, VGContext, UIContext,
  RootView all freed)
- Empty Root: no children → batch empty → `Render` early-outs without
  drawing anything

If a `Sedulous.Engine.UI.Tests` project exists or gets added for
related work, registry-style tests for the module can land there. Not
worth setting up a test project just for this.

## Not in scope for v1

- **Global focus across contexts.** Each `UIContext` keeps its own
  `FocusManager`. Priority chain resolves keyboard routing if multiple
  contexts have a focused view (window wins). True "one view focused
  anywhere" is a future refinement.
- **Multi-pipeline scenes.** Single pipeline per scene assumed. The
  Track 0 hooks support multi-pipeline naturally; `EngineUISubsystem`
  wiring extends when needed.
- **Sharing `VGRenderer` across scenes.** Per-scene `VGRenderer` for
  v1. Future optimization: share keyed by `(device, format, frameCount)`
  across all `UISceneModule` instances.
- **Sharing `VGRenderer` with Track 1 billboards in the same scene.**
  Track 1 will own its own VG resources too in v1. Both Track 1 and
  Track 2 can later be refactored to share the scene's `UISceneModule`
  resources if perf calls for it.
- **Persistence / serialization of UI state.** Scene UI is built by
  game code each session; no `IModuleSerializer` implementation.
- **Hot reload of scene UI markup.** If `.sml` files back scene HUDs,
  hot-reload is a separate concern.

## After Track 2

With Track 0 (per-pipeline overlay) and Track 2 (scene HUD) landed,
the missing pieces for the full picture from UI_RENDERING.md are:

- **Track 1** (lightweight billboards): can build on Track 0 directly,
  or share `UISceneModule`'s resources for tighter integration. Either
  works.
- **Track 3** (shared `VGRenderer` for existing `UIComponent`):
  independent perf win; orthogonal.
- **Track 4** (window UI path refinement): orthogonal polish for the
  existing `IOverlayRenderer` path.

After Track 1 lands too, both scene HUD and billboards drawing
correctly per-pipeline means embedded-play-in-editor and split-screen
co-op are both unblocked from a rendering-architecture perspective.
