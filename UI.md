# Sedulous.UI — Game UI Framework Plan

Plan for a retained-mode game UI framework built on `Sedulous.VG`, with XML
authoring and code-first authoring both first-class. Designed to replace
`Sedulous.GUI` (WPF-style, too heavy) for game UI use cases. The architecture
draws explicitly from two prior frameworks reviewed in detail:
`Sedulous.GUI` (WPF-derived) and the legacy `Sedulous.UI` in BansheeBeef
(Android-derived). Where the two diverge, this plan picks the simpler,
more game-loop-friendly choice — usually the Android one.

## Goals

1. **Flat view hierarchy.** `View` / `ViewGroup` / `RootView` — two real
   levels, no five-deep WPF inheritance chain.
2. **Game-loop-friendly:** layout invalidation is an *opt-in optimization*,
   not a requirement. Default = re-measure / re-arrange every frame, which
   game loops already do. WPF-style invalidation propagation pays cost
   even when you'd recompute anyway.
3. **Manual-memory safe.** Every long-lived view reference is an
   `ElementHandle<T>` resolved through a registry that can return null
   without crashing. Tree mutations route through a deferred queue
   drained at safe sync points.
4. **Composable visuals via Drawables.** Backgrounds, borders, state
   variants are `Drawable` objects (StateListDrawable, LayerDrawable,
   NineSliceDrawable, etc.) — not nested widgets, not WPF brushes.
5. **Fully skinnable** through a flat string-keyed `Theme` with an
   `IThemeExtension` registry so external libraries can inject styles
   without modifying the core themes.
6. **Data virtualization built in:** `IListAdapter` / `ITreeAdapter` +
   `ViewRecycler` + `SelectionModel` for efficient list/tree views.
   Trees flatten through `FlattenedTreeAdapter` so one virtualization
   path serves both.
7. **DPI-aware** via a single global scale at `RootView`, not per-element
   transforms.
8. **XML *and* code authoring** at equal parity through a `UIRegistry`.
   A UI declared in XML is identical to the same UI constructed in code.
9. **Extensible.** Custom view subclasses are first-class — no
   distinction between built-in and user-defined.
10. **Game-specific:** in-world anchored UI, gamepad navigation, kinetic
    scrolling via `MomentumHelper`, hot reload of XML during dev.
11. **Cleanly layered** so the core has no rendering or engine dependency
    — runs headless for tests, tooling, and editor support.

## Non-goals

- WPF/XAML compatibility. Our XML is similar but its own format.
- Designer tooling (WYSIWYG editor) — XML hot reload covers dev for now.
- Accessibility (screen readers) — `View.ContentDescription` field only;
  no actual reader integration yet.
- Advanced IME / RTL text shaping beyond what `Sedulous.Fonts` already does.
- CSS selectors / cascading. `Theme` is a flat dictionary.
- Property binding / `INotifyPropertyChanged` infrastructure. Bindings are
  optional, lightweight, query-based.
- Routed events as a separate type system. Event handlers + `Handled` flag.

## Library Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  Samples                                                             │
│  UISandbox — gallery/showcase; grows as each phase lands.            │
│  Uses Sedulous.UI.Runtime directly (no engine required).             │
├──────────────────────────────────────────────────────────────────────┤
│  Sedulous.Engine.UI                                                  │
│  - Full engine integration: scene hooks, resource system wiring      │
│  - WorldSpaceUIComponent + manager (3D-anchored UI)                  │
│  - Default IFloatingWindowHost using engine windows                  │
│  - Builds on Sedulous.UI.Runtime's subsystem                         │
├──────────────────────────────────────────────────────────────────────┤
│  Sedulous.UI.Runtime      Sedulous.UI.Toolkit    Sedulous.UI.Gamekit │
│  - UISubsystem            - Dock manager         - HUD widgets       │
│    (owns UIContext +      - Floating windows     - Radial gauges     │
│     VGContext +           - PropertyGrid         - Action bars       │
│     VGRenderer)           - DataGrid             - Nameplates        │
│  - UIInputHelper          - UI Inspector         - Minimap widgets   │
│    (Shell→UI adapter)     - Tooling-oriented     - Damage numbers    │
│  - ShellClipboardAdapter    widgets              - Floating anchors  │
│  - InputMapping                                                      │
│  Depends on: Sedulous.Runtime + Sedulous.Shell                       │
├──────────────────────────────────────────────────────────────────────┤
│  Sedulous.UI                         Sedulous.UI.Resources           │
│  - View hierarchy, layout,           - ThemeResource                 │
│    input routing (internal)          - UILayoutResource              │
│  - Theme / Drawable system           - XML serializers               │
│  - XML loader, view registry         - Hot reload hooks              │
│  - Adapters + virtualization                                         │
│  - Animation, drag-drop, overlays                                    │
│  - Walks tree, draws to VGContext                                    │
│                                                                      │
│  Sedulous.UI.Tests (xUnit-style tests mirroring UI's folders)        │
│  - A phase isn't complete until its tests pass.                      │
├──────────────────────────────────────────────────────────────────────┤
│  Sedulous.VG, Sedulous.Fonts, Sedulous.ImageData,                    │
│  Sedulous.Xml, Sedulous.Resources, Sedulous.Core.Mathematics         │
├──────────────────────────────────────────────────────────────────────┤
│  Sedulous.VG.Renderer (renders the VGBatch UI produces)              │
└──────────────────────────────────────────────────────────────────────┘
```

UI is rendered the same way `Sedulous.GUI` is: it draws into a `VGContext`,
producing a `VGBatch`. `VGRenderer` handles the GPU side — there's no
dedicated UI renderer. This is the existing engine pattern.

### Why this split

- **`Sedulous.UI`** (core) depends only on CPU-side libraries (VG, Fonts,
  ImageData, Xml). Walks the tree and draws into a caller-provided
  `VGContext`. Layout, input routing, adapters, animation, overlays are
  all pure logic — testable headless. Does **not** know about Shell, OS
  input, or engine subsystems.

- **`Sedulous.UI.Runtime`** provides the `UISubsystem` + Shell integration
  (input helper, clipboard adapter, input mapping). This is what standalone
  apps — including `UISandbox` — use. Depends on `Sedulous.Runtime` +
  `Sedulous.Shell`, but **not** on `Sedulous.Engine.*`. Follows the
  existing `Sedulous.GUI.Runtime` precedent.

- **`Sedulous.UI.Toolkit`** builds advanced/tooling widgets on top of core
  UI — dock manager, floating windows, property grid, data grid, UI tree
  inspector, and anything an editor-style app needs. Separated so games
  that don't need tools don't pull in the overhead.

- **`Sedulous.UI.Gamekit`** builds game-focused widgets on top of core UI
  — HUD bars, radial gauges, action bars, nameplates, damage numbers,
  floating anchors. Separated so tooling apps don't pull in game-specific
  visuals.

- **`Sedulous.UI.Resources`** wraps UI domain types as `IResource`
  implementations, mirroring the project's pattern (`Sedulous.Fonts` /
  `Sedulous.Fonts.Resources`, etc.). Themes and UI XML layouts go through
  the engine's resource pipeline (async loading, caching, hot reload).

- **`Sedulous.UI.Tests`** is a dedicated test project that mirrors the
  source tree's folder structure (Tests/Core, Tests/Layout, Tests/Input,
  Tests/Drawing, Tests/Animation, Tests/Overlay, Tests/Data, etc.).
  **A phase is not complete until its tests pass.** Tests are written
  alongside the phase's code, not deferred.

- **`Sedulous.Engine.UI`** adds full engine integration on top of
  `Sedulous.UI.Runtime`: scene components (world-space UI), resource
  system registration, and the default `IFloatingWindowHost` using engine
  windows. Apps that need scene-integrated UI pull this in; apps that just
  need a screen-space overlay can stop at `Sedulous.UI.Runtime`.

### UISandbox

Lives at `Code/Samples/UI/UISandbox/`, mirroring `VGSandbox`'s layout.
Uses `Sedulous.Runtime.Client.Application` + `Sedulous.UI.Runtime` —
does **not** require the full engine. **Established in Phase 1 along with
the Runtime subsystem** — the sandbox is a running, rendering app from
the first phase, and every later phase simply grows it. No big-bang
integration moment where everything has to come together at once.

Each phase grows the sandbox with new demos for that phase's features,
becoming a cumulative gallery of everything the framework can do by the
end. Between phases, the sandbox can be refactored to match API changes.

## Design Decisions (all resolved)

1. **XML property binding:** ✅ **Registration-based.** `UIRegistry`
   requires explicit `RegisterProperty<T, TValue>(name, setter)` calls at
   startup. Easier to debug than attribute-based reflection, and the
   contract is explicit. Reflection fallback can be added later without
   breaking registrations.

2. **`LayoutParams` subclass dispatch from XML:** ✅ **Implicit via parent
   runtime type.** The XML loader inspects the parent ViewGroup's runtime
   type and calls its `CreateDefaultLayoutParams()` to construct the
   correct subclass, then sets attributed properties on it. Matches
   Android's XML style; no nested `<LinearLayout.LayoutParams>` boilerplate.

3. **Animation target deletion mid-animation:** ✅ **Default
   `FillBehavior.Stop`.** Cancel as-is when target is destroyed. `Reset`
   (restore original value before cancel) is opt-in per-animation — adds
   cost of storing original + delegate, rarely needed.

4. **Binding evaluation model:** ✅ **Push for `{Binding}` XML syntax**
   (requires observable source so push is cheap), **poll for
   `view.BindValue(...)` convenience** (simpler for hot-path code like
   HUDs that re-read every frame anyway). Per-call choice lets the user
   pick the right trade-off.

5. **Text atlas re-use across DPI scales:** ✅ **Keep both for one frame,
   evict after.** During DPI-change events (drag to different monitor,
   settings change), we briefly need both the old and new atlases because
   the first frame after the change may still reference old glyphs during
   transition. One-frame hold is cheap; permanent keep-alive leaks memory
   on games that dynamically scale UI.

# Core Concepts

## 1. View / ViewGroup / RootView

Three levels, deliberately flat:

```beef
public class View
{
    // Identity (registered with UIContext)
    public ViewId Id { get; }                  // stable for lifetime
    public String Name;                        // for XML/hot-reload
    public String StyleId;                     // theme key prefix

    // Tree (raw refs — owner owns)
    public View Parent { get; internal set; }
    public LayoutParams LayoutParams;          // parent-specific subclass

    // Layout-managed
    public RectangleF Bounds;                  // local-space final rect (logical units)
    public Vector2 MeasuredSize;               // computed by Measure

    // State
    public Visibility Visibility = .Visible;
    public bool IsEnabled = true;
    public bool IsFocusable;
    public bool IsTabStop = true;
    public int32 TabIndex;
    public bool ClipsContent;
    public bool IsHitTestVisible = true;
    public Matrix RenderTransform = Matrix.Identity;
    public Vector2 RenderTransformOrigin = .(0.5f, 0.5f);
    public CursorType Cursor;                  // None = inherit
    public String ContentDescription;          // accessibility hook

    // Lifecycle hooks
    public virtual void OnAttachedToContext(UIContext ctx);
    public virtual void OnDetachedFromContext();

    // Layout
    public void Measure(MeasureSpec wSpec, MeasureSpec hSpec);
    public void Layout(float x, float y, float w, float h);
    protected virtual void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec);
    protected virtual void OnLayout(float left, float top, float right, float bottom);
    public virtual float GetBaseline();        // for typography-aware containers; -1 = no baseline

    // Render
    public virtual void OnDraw(UIDrawContext ctx);

    // Input
    public virtual View HitTest(Vector2 localPoint);
    public virtual void OnMouseDown(MouseEventArgs e);
    public virtual void OnMouseUp(MouseEventArgs e);
    public virtual void OnMouseMove(MouseEventArgs e);
    public virtual void OnMouseWheel(MouseWheelEventArgs e);
    public virtual void OnKeyDown(KeyEventArgs e);
    public virtual void OnKeyUp(KeyEventArgs e);
    public virtual void OnTextInput(TextInputEventArgs e);
    public virtual void OnFocusGained();
    public virtual void OnFocusLost();

    // Invalidation
    public void InvalidateLayout();
    public void InvalidateVisual();
}

public class ViewGroup : View
{
    public List<View> Children;
    public Thickness Padding;

    public virtual void AddView(View child, LayoutParams lp = null);
    public virtual void RemoveView(View child, bool dispose = true);
    public virtual void RemoveAllViews(bool dispose = true);
    public virtual LayoutParams CreateDefaultLayoutParams();
    public virtual bool CheckLayoutParams(LayoutParams lp);
    // OnMeasure / OnLayout abstract — concrete subclasses define layout strategy
}

public class RootView : ViewGroup
{
    // Per-window state
    public float DpiScale;
    public Vector2 ViewportSize;
    public PopupLayer PopupLayer;
    public CursorType ActiveCursor;
    // PopupLayer is auto-kept as the last child for z-order (override AddView)
}
```

The flat hierarchy avoids WPF's ContentControl / Decorator / Container /
Control split. Single-child-with-decoration is just a `ViewGroup` with one
child. The two-tier `View` / `ViewGroup` model came from Android and has
proven simpler to reason about.

## 2. Element Registry + Handles

Beef is manual memory. Once a view is deleted, any field anywhere holding
a `View*` becomes a use-after-free waiting to fire. UI code accumulates
these references naturally: focused, hovered, mouse-capturing, drag source,
popup owner, animation target, binding target, deferred command target,
inspector selection, and more.

```beef
public struct ViewId : IHashable, IEquatable<ViewId>
{
    public readonly int32 Value;
    public bool IsValid => Value != 0;
    public static ViewId Invalid => default;
    public static ViewId Generate();           // atomic counter
}

public struct ElementHandle<T> where T : View
{
    public T TryResolve(UIContext ctx);        // null if dead or wrong type
    public bool IsValid(UIContext ctx);
}

public class UIContext
{
    public View GetElementById(ViewId id);
    public ElementHandle<T> GetHandle<T>(T view) where T : View;
    public void NotifyElementDeleted(View view);
}
```

**Where handles are mandatory** (storing raw `View*` here is a bug):

| State | Why |
|-------|-----|
| `UIContext.Focused` | Focused view can be destroyed before next event |
| `UIContext.Hovered` | Hover target can disappear (popup closes, anim removes it) |
| `UIContext.Capturing` | Drag-target deletion mid-drag is normal |
| `Popup.Owner` | Popup outlives the view that opened it |
| Deferred command's target | Queued for removal between enqueue and drain |
| `Animation.Target` | Animation outlives view if view destroyed mid-tween |
| `Binding.Target` | Binding source can survive view destruction |
| `Inspector.Selection` | Shouldn't crash when selection destroyed |
| `WorldSpaceUIComponent.Root` | Component lives separately from view tree |
| `DragDropManager.SourceView` | Drag source can be destroyed mid-drag |

**Where raw pointers are fine:**

- Inside one phase of one frame (the layout walk holds raw `View*` while iterating)
- Parent → child within the tree (the tree owns its children)
- Inside one synchronous method call

**Rule of thumb:** if a reference outlives the current synchronous
operation, it must be a handle.

The simple atomic-counter approach (no generation) is sufficient when
combined with `IsPendingDeletion` and the registry. The registry stops
returning the view as soon as deletion is queued; resolved handles get
null immediately, even before the actual `delete` happens.

## 3. Deferred Mutation

Foundational. Event handlers, animation callbacks, and binding updates
routinely want to mutate the tree (remove the clicked view, add a popup,
reparent a drag target, change focus). Doing these synchronously while the
input router or render walk iterates leads to use-after-free, invalidated
parent references, and stale focus pointers.

The framework owns a single command queue on `UIContext`. **All
structural mutations route through it:**

```beef
public class UIContext
{
    public void Defer(delegate void() action);

    // Convenience deferred mutations on View:
    //   view.QueueRemove();
    //   view.QueueReparent(newParent, lp);
    //   view.QueueDestroy();      // also frees memory
    //   view.QueueFocus();
}
```

**Rules:**
- **Tree structure** changes (add / remove / reparent / destroy) are *always*
  deferred. Synchronous variants exist on `ViewGroup` (`AddView`,
  `RemoveView`) but assert when called outside a "safe" phase. User code
  uses the `Queue*` variants.
- **Focus changes** are deferred (they unwind input routing in subtle ways).
- **Property mutations** that don't affect tree structure (text, color,
  opacity, `Value`) are immediate — they don't invalidate iteration.
- **Theme switches** are deferred (touch every view; can't run mid-draw).
- **Layout invalidation** is immediate but lazy: `InvalidateLayout` only
  flips a flag; the layout pass actually runs in the layout phase.

**`IsPendingDeletion` flag** is set immediately when destroy is queued,
before the actual drain. Lets handlers reject operations on doomed views
via `if (view.IsPendingDeletion) return`. Safer than a "is it in the queue"
lookup because handlers may have cached references.

**Drain points:** the queue is drained at:
1. Start of each frame (before layout)
2. Between input event delivery and layout
3. Between layout and draw

`UIPhase` tracking on `UIContext` (Idle, RoutingInput, LayingOut, Drawing)
lets synchronous mutations assert when called in unsafe phases — catches
misuse early.

When a tree subtree is removed/destroyed, the queue calls
`NotifyTreeDeleted(view)` which recursively notifies `InputManager`,
`FocusManager`, `DragDropManager`, `AnimationManager`, etc. so they can
clear any references to deleted views.

## 4. Layout: MeasureSpec, LayoutParams, Gravity, Visibility

Different from WPF's "available size + alignment" model. Adopted from
Android because it's clearer and supports weighted distribution without
recursion.

### MeasureSpec (mode + size)

```beef
public enum MeasureMode { Unspecified, AtMost, Exactly }

public struct MeasureSpec
{
    public MeasureMode Mode;
    public float Size;

    public static MeasureSpec Unspecified() => .{ Mode = .Unspecified };
    public static MeasureSpec AtMost(float size) => .{ Mode = .AtMost, Size = size };
    public static MeasureSpec Exactly(float size) => .{ Mode = .Exactly, Size = size };

    /// Resolve a desired size against this spec.
    public float Resolve(float desired)
    {
        switch (Mode) {
        case .Exactly:    return Size;
        case .AtMost:     return Math.Min(desired, Size);
        case .Unspecified: return desired;
        }
    }
}
```

Children always know whether the constraint is hard or soft. Eliminates
ambiguity in weighted distribution. WPF passes one `availableSize` —
child has to guess.

### LayoutParams (subclass per ViewGroup)

Layout-specific child params live **on the child**, not on the parent.
Each `ViewGroup` defines its own `LayoutParams` subclass:

```beef
public class LayoutParams
{
    public const float MatchParent = -1;
    public const float WrapContent = -2;
    public float Width = WrapContent;
    public float Height = WrapContent;
    public Thickness Margin;
}

public class LinearLayout : ViewGroup
{
    public class LayoutParams : Sedulous.UI.LayoutParams
    {
        public float Weight;       // proportional distribution
        public Gravity Gravity;    // cross-axis alignment per child
    }

    public override LayoutParams CreateDefaultLayoutParams() => new LinearLayout.LayoutParams();
    public override bool CheckLayoutParams(LayoutParams lp) => lp is LinearLayout.LayoutParams;
}
```

`AddView` validates type via `CheckLayoutParams` (auto-creates default if
null). Type-safe, no attached property registry, no reflection.

### Gravity (bit flags)

```beef
public enum Gravity : int32
{
    None    = 0,
    Left    = 0x01,  Right   = 0x02,  CenterH = 0x04,  FillH = 0x08,
    Top     = 0x10,  Bottom  = 0x20,  CenterV = 0x40,  FillV = 0x80,
    Center  = CenterH | CenterV,
    Fill    = FillH | FillV,
}
```

One value combines horizontal + vertical alignment + fill semantics. Fill
is distinct from alignment (unlike WPF's `Stretch` which conflates them).
`HasFlag()` extracts decisions; `GravityHelper.Apply()` resolves to final
position.

### Visibility (3-state)

```beef
public enum Visibility { Visible, Invisible, Gone }
```

- `Visible` — renders + takes layout space
- `Invisible` — no render + still takes space (reserve)
- `Gone` — no render + no space

Layout panels skip `Gone` children entirely. Many UI systems conflate
all three; the distinction is essential for things like "hide an icon
without reflowing the row".

### Built-in layout primitives

| Type | Behavior |
|------|----------|
| `LinearLayout` | Horizontal/vertical stack with weight distribution and per-child Gravity. Two-pass when weights present (measure fixed, distribute remaining). Optional baseline alignment for horizontal text. |
| `FrameLayout` | Stack-on-top with per-child Gravity. Use for layered content + alignment. |
| `GridLayout` | Row/column matrix. `GridSpec` per dimension: `Pixel`, `Auto`, `Star` (proportional). Two-pass: measure unconstrained for Auto, then re-measure with cell constraints. |
| `FlowLayout` | Wrap to next line when exceeding axis. Horizontal (rows) or Vertical (columns). |
| `AbsoluteLayout` | Children positioned by explicit X/Y in `LayoutParams`. |

### Layout invalidation (opt-in)

`UIContext.UseDirtyTracking = false` (default). Re-measure / re-arrange
every frame. Game loops re-render every frame anyway; invalidation
overhead doesn't pay for itself. Toggle to `true` for editor-style apps
where layout cost dominates and frames are sparse.

### Layout-property vs render-property

Properties that affect desired size (border thickness, padding, font size,
content) call `InvalidateLayout`. Pure visual properties (color) only
`InvalidateVisual`. Theme changes call `InvalidateLayout` because theme
can change padding/sizes.

### Stretch is opt-in, not implicit

Children stretch only when `LayoutParams.Width = MatchParent` (or Gravity
includes `FillH`). Explicit `Width = 100` overrides any stretch hint.
Prevents "I set width but it stretches anyway" surprise.

### Children arranged in *content* bounds (post-padding)

`ViewGroup.OnLayout(left, top, right, bottom)` receives content bounds —
padding already trimmed. Each ViewGroup arranges within already-trimmed
space; padding handled once in base class.

### `SizeConstraints.Infinity` constant

Use a large but finite constant (`100_000.0f`), not `float.MaxValue`.
Avoids numerical instability in layout math.

### Reverse-order hit testing

`ViewGroup` hit-tests children back-to-front (N→0). Topmost wins, matching
visual z-order (children rendered front-to-back 0→N).

## 5. Drawable System

The visual primitive. `Drawable` is stateless and composable.

```beef
public abstract class Drawable
{
    /// State-unaware draw.
    public abstract void Draw(UIDrawContext ctx, RectangleF bounds);

    /// State-aware draw — default delegates to state-unaware.
    public virtual void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
        => Draw(ctx, bounds);

    /// Optional natural size (e.g., for icons / images).
    public virtual Vector2? IntrinsicSize => null;

    /// Padding contributed by this drawable (e.g., nine-slice borders).
    /// Layout queries this and merges via max(themePadding, explicitPadding).
    public virtual Thickness DrawablePadding => default;
}
```

**Drawable types** (concrete primitives):

| Type | Role |
|------|------|
| `ColorDrawable` | Solid-color fill |
| `RoundedRectDrawable` | Fill + optional border with corner radius |
| `NineSliceDrawable` | Stretch-around-corners image; `Expand` insets allow shadow/glow extending beyond bounds |
| `ImageDrawable` | Plain image draw with optional `Expand` |
| `GradientDrawable` | Linear gradient (4 directions: TtoB, LtoR, TLtoBR, TRtoBL). Limited deliberately. |
| `ShapeDrawable` | Wraps a `delegate void(UIDrawContext, RectangleF)` for procedural drawing without subclassing |

**Composition primitives:**

| Type | Role |
|------|------|
| `StateListDrawable` | Maps `ControlState` enum → `Drawable`. Pre-allocated array for O(1) state lookup. Falls back to default if state-specific is null. |
| `LayerDrawable` | Stacks multiple drawables in order with per-layer insets. Replaces VisualBrush composition; flat alternative to nested widgets just for visuals. |
| `InsetDrawable` | Wraps a drawable with insets and advertises them via `DrawablePadding`. Useful for "this drawable wants 8px of content padding". |

**Why drawables instead of brushes:**
- State-aware in the primitive (no triggers/converters)
- Composable as data, not as widget tree
- Drawable advertises its own padding requirements
- Theme drawables (loaded from images) plug in identically to procedural ones

**`DrawablePadding` rule:** when a view has both a drawable background
that contributes padding (nine-slice border) and an explicit `Padding`
property, the effective padding is `max(themePadding, explicitPadding)`
component-wise. Theme can set a minimum; app overrides only to *increase*.

## 6. Theming

Flat, string-keyed, type-segmented dictionaries. No cascading, no
templates, no triggers.

```beef
public class Theme
{
    // Typed dictionaries keyed by "ViewType.Property" strings:
    //   "Button.Background", "Label.Foreground", "Panel.Padding", ...
    Color GetColor(StringView key);
    float GetDimension(StringView key);
    Thickness GetPadding(StringView key);
    Drawable GetDrawable(StringView key);
    String GetString(StringView key);
    CachedFont GetFont(StringView key);

    // For state-aware views:
    Drawable GetStateListDrawable(StringView key); // returns a StateListDrawable

    // Lifecycle
    public Palette Palette;
    public void ApplyExtensions();   // calls registered IThemeExtension
}

public static class Theme
{
    public static void RegisterExtension(IThemeExtension ext);
    // Registered extensions are applied after base theme initialization,
    // so external libraries can inject styles without touching core.
}
```

### Palette + ControlState

```beef
public struct Palette
{
    public Color Primary, PrimaryAccent;
    public Color Background, Surface;
    public Color OnPrimary, OnSurface;
    public Color Text, TextDim;
    public Color Error, Success, Warning;

    public Color Lighten(Color c, float amount);
    public Color Darken(Color c, float amount);
    public Color Desaturate(Color c, float amount);

    public Color ComputeHover(Color baseColor);     // +15% lightness
    public Color ComputePressed(Color baseColor);   // -15% lightness
    public Color ComputeDisabled(Color baseColor);  // -50% saturation, 50% alpha
    public Color ComputeFocused(Color baseColor, Color accent);

    public Color ResolveState(Color baseColor, ControlState state, Color accent);
}

public enum ControlState
{
    Normal,
    Hover,
    Pressed,
    Focused,
    Disabled,
    // Priority order for resolution: Disabled > Pressed > Focused > Hover > Normal
}
```

State priority is enforced by `View.GetControlState()` which checks in
order and returns the first match. Theme `StateListDrawable` lookups use
this priority to find the right variant; missing variants fall back to
the next-priority match.

### Per-control nullable override pattern

Every control has nullable fields for visual properties:

```beef
public class Button : View
{
    private Color? mBackground;          // null = use theme
    public Color Background
    {
        get => mBackground ?? Context.Theme.GetColor("Button.Background");
        set { mBackground = value; InvalidateVisual(); }
    }
}
```

Null means "inherit from theme". Avoids a separate "uses theme" boolean
per property; the absence *is* the signal.

### Default themes

Library ships `DarkTheme` and `LightTheme` factories. Both seed from a
`Palette` and call `Palette.Compute*` to derive state colors — math-
consistent variants without manual tuning.

### Theme switching

Deferred (touches every view; can't run mid-draw). Causes
`InvalidateLayout` on next frame because theme can change padding/sizes.

## 7. Input Routing

### Pooled event args

Single `MouseEventArgs`, `MouseWheelEventArgs`, `KeyEventArgs`,
`TextInputEventArgs` instances reused via `Reset()` per event. Zero
allocation in the hot input path.

### Hover / pressed / capture state

Stored as `ViewId` on `InputManager`, resolved via the registry on each
use:

```beef
public class InputManager
{
    private ViewId mHoveredViewId;
    private ViewId mPressedViewId;

    public View Hovered => Context.GetElementById(mHoveredViewId);
    public View Pressed => Context.GetElementById(mPressedViewId);
}
```

### Hover refreshed on mouse-down, not just mouse-move

If the mouse hasn't physically moved between a popup closing and a click
landing, hover is stale. Refresh on every input event.

### Mouse wheel bubbles, other mouse events don't

Scroll containers nested inside other elements need bubbling so the
parent scroller can intercept. Clicks shouldn't bubble.

### Capture (single view)

`FocusManager.SetCapture(view)` / `ReleaseCapture()`. While captured, all
mouse events route to that view regardless of hit-test. Used by sliders,
drag operations, scroll thumbs.

### Click count + distance threshold

Double/triple click: same button, time window AND distance threshold
both required. `ClickCount` passed in `MouseEventArgs` so controls just
check `evt.ClickCount >= 2`.

### Modifier keys per-event

Each event carries its own `KeyModifiers`. No global "what's held now"
state. Avoids race between modifier state and event delivery.

### `IsRepeat` on key events

Distinguishes initial press from OS-driven auto-repeat. Useful for
one-shot triggers that don't want auto-repeat.

### `e.Handled` cooperative

Handlers set `e.Handled = true` to stop propagation; downstream code
checks before processing. Cooperative (not enforced).

### Tab vs Ctrl+Tab distinction

Plain Tab = focus traversal. Ctrl+Tab = control-internal cycling
(TabControl, etc.). Reserve the convention.

### Accelerators (Alt+key) bypass focus

Searched top-down through the tree for `IAcceleratorHandler` implementers.
Different system from focus dispatch — keeps menu logic out of focus.

### Drag candidate walks parent chain

On left mouse down, walk up from the hit view looking for `IDragSource`.
`DragDropManager.BeginPotentialDrag()` if found. Skipped on double-click
(double-click action may destroy the view, causing phantom drag).

## 8. Focus Model

Three orthogonal axes:

- `IsFocusable` — can be focused programmatically
- `IsTabStop` — participates in Tab order
- `IsEffectivelyEnabled` — functional now, walking parent chain (disabled
  parent disables children regardless of local state)

Disabled controls skip Tab order without becoming unfocusable. Walking
the parent chain for "effective" state mirrors HTML/CSS expectations.

### `IsFocusWithin`

True when any descendant has focus. Essential for styling containers
around focused inputs (dialog highlights when a field inside focuses).
Computed by walking from `Focused` up to root.

### Tab order: HTML-style

```beef
focusables.Sort((a, b) => {
    // TabIndex > 0 first, sorted by index
    // Then TabIndex == 0 in tree order
});
```

`TabIndex > 0` views explicitly ordered by index. `TabIndex == 0` views
follow tree order (natural reading order). Matches web/HTML.

### Focus restoration

When a popup, modal, or floating window closes, focus returns to whatever
was focused before. `FocusManager` keeps a small focus stack tied to
overlay open/close.

### Modal focus trapping

Tab navigation checks `if (modalManager.HasModal) modal.HandleTabNavigation()`.
Focus trap stays out of focus core; modal manager opts in.

### Cursor inheritance

`View.EffectiveCursor` walks parent chain — self.Cursor, fall back to
parent until root returns Default. Parents set fallback cursors without
children opting in.

## 9. Adapter + Recycler (Data Virtualization)

The adapter pattern is the **primary abstraction boundary** between data
and UI. Used by `ListView` and `TreeView`.

```beef
public interface IListAdapter
{
    int32 ItemCount { get; }

    /// View type for an item (for recycling pools). Default: 0.
    int32 GetItemViewType(int32 position);

    /// Create a new view instance of the given type.
    View CreateView(int32 viewType);

    /// Bind data at `position` into `view`.
    void BindView(View view, int32 position);

    /// Notify observers (registered by ListView).
    EventAccessor<delegate void(IListAdapter)> OnChanged { get; }
    EventAccessor<delegate void(int32 start, int32 count)> OnRangeChanged { get; }
}

public interface ITreeAdapter
{
    /// Tree-shaped contract: GetChildCount, GetChild, IsExpanded, GetItemViewType, ...
    /// Wrapped by FlattenedTreeAdapter to expose as IListAdapter for ListView reuse.
}

public class FlattenedTreeAdapter : IListAdapter
{
    public this(ITreeAdapter source);
    /// Maintains a flat list of currently-visible nodes.
    /// Tracks expansion state (lives in source ITreeAdapter).
    /// Wraps user view with a row container holding expand icon + indent.
}

public class ViewRecycler
{
    /// Pool of views per `viewType`.
    public View Acquire(int32 viewType);
    public void Recycle(View view, int32 viewType);

    public int32 CreatedCount { get; }
    public int32 RecycledCount { get; }
    public int32 ReusedCount { get; }
}

public class SelectionModel
{
    public SelectionMode Mode;             // None / Single / Multiple
    public HashSet<int32> SelectedIndices; // by position
    public EventAccessor<delegate void()> OnSelectionChanged { get; }

    /// When the data shifts (tree expand inserts items), re-anchor selection.
    public void ShiftIndices(int32 start, int32 delta);
}
```

**Properties of the design:**

- Adapter owns *both* view creation and data binding. No "item template"
  separation.
- Multiple view types per adapter via `GetItemViewType()` — heterogeneous
  lists work natively.
- `ViewRecycler` is a separate object that lives on the consuming view.
  Diagnostic counters help measure pool effectiveness.
- Trees flatten to lists for virtualization (one virtualization path).
  Expansion state lives in the tree adapter — not the flat one.
- Selection is decoupled from data. Multiple views can share a
  `SelectionModel`. `ShiftIndices` adjusts when data inserts/removes.

`ListView` virtualization:
- Fixed item height: O(1) visible range computation
- Variable height: cache per-item height + offset, binary search for visible range
- Views recycled immediately on scroll-out (no keep-alive window)

## 10. Scrolling

Three pieces, deliberately separate.

### MomentumHelper (struct)

```beef
public struct MomentumHelper
{
    public float VelocityX, VelocityY;
    public float Friction = 6.0f;       // higher = stops sooner
    public float StopThreshold = 0.5f;  // px/sec — below this, snap to 0

    public (float dx, float dy) Update(float deltaTime) mut;
}
```

Exponential decay: `decay = 1 - friction * dt; velocity *= decay`. Snap
to zero below threshold. Owned by scrollable views as a member, not a
separate object. Physics-based (not tweening).

### ScrollBar (standalone view)

`ScrollBar` is a standalone `View` — not built into `ScrollView`. Has its
own measure/layout/draw/input. Independently themeable. Plugged in by
composition.

`ScrollView` and `ListView` own them but **don't put them in `mChildren`**
— managed separately, drawn after the children, hit-tested first.

### ScrollBarPolicy enum

```beef
public enum ScrollBarPolicy
{
    Never,    // No scrollbar; scroll via wheel/drag only
    Auto,     // Show only when content exceeds viewport
    Always    // Always show, even when content fits
}
```

Per-axis. When both axes are `Auto` and one becomes visible, layout
recomputes once more (cascading visibility).

### Negative-offset layout (not render translate)

`ScrollView.OnLayout` arranges its content at `(Padding.Left - mScrollX,
Padding.Top - mScrollY, ...)`. Hit-test, layout, and bounds-checking
naturally account for scroll without per-frame transform inversion.
Cleaner than translate-on-render.

### Scroll-into-view

`view.ScrollIntoView()` walks up to find the nearest scrollable ancestor
and adjusts offset to make `view.Bounds` visible.

## 11. Text Editing

### TextEditingBehavior + ITextEditHost

Editing logic lives in a reusable `TextEditingBehavior` class. The
control implements `ITextEditHost` to provide text storage, font,
shaping, and event hooks. Same behavior reused by `EditText`, `PasswordBox`,
search boxes, code editors.

```beef
public interface ITextEditHost
{
    String Text { get; set; }
    CachedFont Font { get; }
    float CurrentTime { get; }
    void OnTextChanged();
    void OnSelectionChanged();
    IClipboard Clipboard { get; }
}

public class TextEditingBehavior
{
    public this(ITextEditHost host);

    public int32 Caret;
    public int32 Anchor;            // -1 if no selection
    public InputFilter InputFilter; // optional character validation
    public UndoStack Undo;

    public void HandleKey(KeyEventArgs e);
    public void HandleTextInput(TextInputEventArgs e);
    public void HandleMouseDown(MouseEventArgs e);

    public (int32 start, int32 end) Selection { get; } // normalized
    public bool HasSelection => Anchor >= 0;
}
```

### Anchor + caret model (not start + end)

Two integers. Naturally extends in both directions. Normalize to
(start, end) only when needed.

### UTF-8-aware caret navigation

`GetPrevCharIndex` / `GetNextCharIndex` skip continuation bytes (0x80–0xBF).
Every navigation method respects this from day one — not added later.

### Word boundaries via state machine

Skip-word → skip-whitespace → stop. Prevents landing in whitespace runs.
Used by Ctrl+Left/Right.

### Caret blink via modulo on time

`isVisible = (elapsed % (period * 2)) < period`. No state machine. Reset
"last user input time" to force visible after typing.

### Glyph cache invalidated lazily

Dirty flag set on text change. Re-shaped on render, not on each
keystroke. Batches the shaping work.

### Single-line scroll offset is caret-driven

Recompute each frame to keep caret visible. Don't cache.

### Hit-test fallback when no shaper

If `font.Shaper` is null, estimate caret position from font metrics
(width = 0.6 × fontHeight as monospace fallback). Better than crash.

### Text input filtered at editing layer

Reject control chars (`< 32` except Tab) before they reach the control.
All editors inherit the filter.

### Navigation breaks undo merge chain

Type "abc" → arrow → type "d" produces two undo entries, not "abcd".

### InputFilter

```beef
public enum InputFilterMode { None, Digits, HexDigits, Custom }

public class InputFilter
{
    public InputFilterMode Mode;
    public delegate bool(char32) CustomPredicate;

    public bool Accept(char32 c);
}
```

Validation as a separate component, attached to `TextEditingBehavior`,
not inline in widgets.

### UndoStack

```beef
public class UndoStack
{
    public int32 MaxEntries = 100;     // FIFO drop on overflow
    public float CoalesceWindow = 1.0f; // seconds

    public void PushState(string text, int32 caret, int32 anchor, EditActionType type);
    public bool Undo(out string text, out int32 caret, out int32 anchor);
    public bool Redo(out string text, out int32 caret, out int32 anchor);
    public void ClearRedo();
    public void BreakMergeChain();
}
```

Coalescing heuristic: consecutive `CharInsert` events within 1.0s merge
into one undo entry. Other action types always push. Avoids 100s of
"insert 'a'" undo states.

### PasswordBox = EditText with display override

PasswordBox inherits from EditText, overrides `GetDisplayText()` to mask,
blocks Ctrl+C / Ctrl+X. Same `TextEditingBehavior` underneath.

## 12. Overlays (Popups, Modals, Dialogs, Menus, Tooltips)

### PopupLayer

Single `PopupLayer` per `RootView`, kept as the last child for z-order
(enforced by `RootView.AddView` override).

```beef
public class PopupLayer : ViewGroup
{
    public bool HasModalPopup;
    public View ActivePopup;

    public void ShowPopup(View popup, IPopupOwner owner,
        float x, float y, bool closeOnClickOutside, bool isModal, bool ownsView);
    public void ClosePopup(View popup);
    public void HandleClickOutside(float screenX, float screenY);

    public override View HitTest(Vector2 point); // 3-state behavior below
}
```

### Pass-through hit-test (3 explicit states)

```
if (mEntries.Count == 0)  return null;       // pass through
... hit-test entries reverse-order ...
if (HasModalPopup)        return this;       // block input
                           return null;       // pass through
```

Three explicit cases. Cleaner than WPF's modal event loop.

### `OwnsView` flag

`PopupEntry.OwnsView` — `true` deletes view on close, `false` just
detaches. Submenus use `false` so the menu item still owns them. Lifecycle
flexibility without leaks.

### Modal backdrop deferred

`ModalBackdrop` view added on first modal, removed when last modal closes.
Doesn't exist when not needed.

### `IPopupOwner` notification

```beef
public interface IPopupOwner
{
    void OnPopupClosed(View popup);
}
```

Popup tells owner on close (so ContextMenu can clear `mOpenSubmenu`,
ComboBox can re-focus, etc.). Cleaner than callbacks on the popup.

### PopupPositioner (static helpers)

```beef
public static class PopupPositioner
{
    public static (float x, float y) PositionBestFit(RectangleF anchor, Vector2 popupSize, RectangleF screen);
    public static (float x, float y) PositionBelow(RectangleF anchor, Vector2 popupSize, RectangleF screen);
    public static (float x, float y) PositionAbove(RectangleF anchor, Vector2 popupSize, RectangleF screen);
    public static (float x, float y) PositionSubmenu(RectangleF parent, Vector2 popupSize, RectangleF screen);
}
```

Pure stateless functions. Reusable across menus, tooltips, autocomplete,
floating panels.

### LMB vs RMB click-outside differ

LMB closing a popup *consumes* the click (don't process underneath). RMB
closing *continues* processing so a new context menu can open at the same
spot.

### Render order

`tree → modal backdrop → popups → drag adorner`. Each layer has a
specific visual purpose. Layered by render order, not structural in tree.

### Dialog

Modal dialog with vertical layout: title row, content area, button row.
Static `Dialog.Alert(...)` and `Dialog.Confirm(...)` factories for common
patterns. Dialog merges its drawable padding with explicit padding via
`max` (so theme nine-slice borders aren't undercut by padding=0).

### ContextMenu

Hierarchical menus. `MenuItem` struct owns submenu (cascaded delete).
Submenu opens on hover (no click), closes on leave. `CloseEntireChain()`
walks up `mParentMenu` to root and closes everything. Submenus shown via
`PopupLayer.ShowPopup(ownsView: false)` — menu item retains ownership.

### TooltipManager + TooltipView

**Manager** owns a single reusable `TooltipView`. Tracks current hover
target, time since hover started. Ticked by `UIContext` each frame.
Default: show after 0.5s, auto-hide after 5s. Position via
`PopupPositioner.PositionBestFit` near cursor or anchor.

### IFloatingWindowHost

```beef
public interface IFloatingWindowHost
{
    bool SupportsOSWindows { get; }
    void CreateFloatingWindow(View root, float width, float height,
        float screenX = -1, float screenY = -1,
        delegate void(View) onCloseRequested = null);
    void DestroyFloatingWindow(View root);
}
```

Bridge between docking/floating system and the app's window provider.
Default `Sedulous.Engine.UI` impl creates real engine windows. Apps can
provide a virtual implementation (in-game window).

## 13. Drag and Drop

### State machine

```
Idle → (mouse-down on IDragSource) → Potential
Potential → (distance threshold met) → Active
Potential → (cancel / threshold not met) → Idle
Active → (mouse-up over IDropTarget) → OnDrop → Idle
Active → (mouse-up over invalid target) → cancelled → Idle
```

Mouse capture acquired immediately on `Potential`. Threshold (default
4 px) gates promotion to `Active`. Prevents accidental drags from clicks.

### Skip drag on double-click

Double-click action (e.g., re-dock, edit-mode toggle) may destroy views.
Without this guard, the destroyed view would start a phantom drag.

### Format-based DragData (MIME-like)

```beef
public class DragData
{
    public Dictionary<String, Object> Formats; // "text", "filepath", "uielement", "custom"
    public bool HasFormat(StringView format);
    public Object Get(StringView format);
}
```

Source and target negotiate over format strings. Type-agnostic, extensible.

### IDragSource / IDropTarget interfaces

```beef
public interface IDragSource
{
    DragData CreateDragData();           // null cancels
    View CreateDragVisual(DragData data); // owned by DragDropManager
    void OnDragStarted(DragData data);
    void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled);
}

public interface IDropTarget
{
    DragDropEffects CanAcceptDrop(DragData data, float localX, float localY);
    void OnDragEnter(DragData data, float localX, float localY);
    void OnDragOver(DragData data, float localX, float localY);
    void OnDragLeave(DragData data);
    DragDropEffects OnDrop(DragData data, float localX, float localY);
}

public enum DragDropEffects { None, Copy, Move, Link }
```

Symmetric. Walking the drop-target chain *includes* the drag source —
target rejects via `CanAcceptDrop`. Allows reorder operations where
source = target (tab reordering, list item swap).

### DragAdorner is a data class

Not a `View`. Configurable colors, optional `delegate void(UIDrawContext, RectangleF) CustomRender`, simple field-based. Owned and rendered by
`DragDropManager`.

### Closure ordering

**Adorner closed *before* `OnDrop`.** OnDrop may destroy the floating
window (re-docking), which would free the popup layer the adorner lives
in. Cleanup order matters.

### Cross-window drag

`DragAdorner` remembers which `PopupLayer` it lives in
(`mAdornerPopupLayer`). When the drag crosses windows, the adorner stays
frozen in the originating window's layer. Avoids use-after-free if the
target window's layer is destroyed mid-drag.

## 14. Animation

### Animation base class

```beef
public abstract class Animation
{
    public float Duration;
    public float Delay;
    public EasingFunction Easing;
    public bool AutoReverse;
    public int32 RepeatCount = 1;       // 0 = infinite
    public ElementHandle<View> Target;  // weak — auto-cancels on view destroy
    public AnimationState State;        // Pending / Running / Paused / Completed / Cancelled
    public FillBehavior OnTargetDestroyed; // Stop (default) or Reset

    public virtual bool Update(float deltaTime); // returns true when complete
    protected abstract void Apply(float t);      // t = eased progress 0..1
}
```

Subclasses: `FloatAnimation`, `ColorAnimation`, `Vector2Animation`,
`ThicknessAnimation`, `RectangleAnimation`. Each carries delegate-based
getter+setter:

```beef
new FloatAnimation(
    from: 0, to: 1, duration: 0.3f,
    setter: new (v) => view.Alpha = v
);
```

Delegate-based, not reflection. Compile-time safe. Animatable from outside
the framework without metadata systems.

### Storyboard composition

```beef
public enum StoryboardMode { Sequential, Parallel }

public class Storyboard : Animation
{
    public StoryboardMode Mode;
    public List<Animation> Children;
    public void Add(Animation child, float beginTime = 0);
    public void AddAfter(Animation child, Animation prerequisite);
}
```

Storyboard *is* an `Animation` — composable to arbitrary depth.

### ViewAnimator (factory shortcuts)

```beef
public static class ViewAnimator
{
    public static Animation FadeIn(View view, float duration, EasingFunction easing = null);
    public static Animation FadeOut(View view, float duration, EasingFunction easing = null);
    public static Animation SlideIn(View view, Direction dir, float distance, float duration);
    public static Animation Pulse(View view, float scale, float duration);
    // ... + extension methods for one-liner Start* variants
}

// view.StartFadeOut(0.3f);  // one-liner that creates + adds to manager
```

Two-tier API: factories return for further config; extension methods
start immediately.

### AnimationManager

- Owns animations (deletes on completion or cancellation).
- Pending add/remove queues during update (same deferred-mutation pattern
  as `MutationQueue`, scoped to animation lists). Prevents iterator
  invalidation when handlers add/remove animations.
- `OnElementDeleted(view)` cancels all animations targeting that view.
  Honors `FillBehavior` per-animation.

### Easing as delegates

```beef
public delegate float EasingFunction(float t);

public static class Easings
{
    public static readonly EasingFunction Linear, EaseInQuad, EaseOutCubic,
        EaseInOutCubic, EaseOutBack, EaseInOutElastic, ...;
}
```

App code can supply custom easings without modifying the framework.

## 15. Service Registry

Type-keyed dictionary on `UIContext`. App code registers custom services
without modifying core:

```beef
public class UIContext
{
    public void RegisterService<T>(T instance) where T : class;
    public T GetService<T>() where T : class;
}
```

**Direct fields** for core managers (frequently accessed):
`InputManager`, `FocusManager`, `MutationQueue`, `Theme`, `PopupLayer`.

**Service registry** for optional/swappable: `ModalManager`,
`AnimationManager`, `DragDropManager`, `TooltipManager`, custom app
services.

Services not owned by context — caller retains ownership.

## 16. Element-Bound Events

Events bound to a specific view auto-cleanup when the view dies.

```beef
public class ElementBoundEvent<T>
{
    public void Subscribe(View owner, T handler);
    public void Unsubscribe(View owner, T handler);
    public void Invoke(...);  // skips handlers whose owner is dead/pending
}
```

**Defer handler removal during Invoke.** Removing a handler during the
invoke loop adds to `mToRemove`, applied after iteration. Prevents
iterator corruption on self-unsubscribe.

**Validate handlers on invoke.** Skip handlers whose owner is null,
pending deletion, or detached from context. Cleaner than auto-unsubscribing
on view delete.

## 17. Commands

```beef
public interface ICommand
{
    void Execute(Object parameter = null);
    bool CanExecute(Object parameter = null);
    EventAccessor<delegate void()> CanExecuteChanged { get; }
    void RaiseCanExecuteChanged();
}

public class RelayCommand : ICommand
{
    public this(delegate void() execute, delegate bool() canExecute = null);
}

public class RelayCommand<T> : ICommand
{
    public this(delegate void(T) execute, delegate bool(T) canExecute = null);
}
```

`Button.Command` and `MenuItem.Command` properties. Button auto-disables
when `CanExecute()` returns false. `RaiseCanExecuteChanged` is **manual**
— business logic owns when conditions changed; no automatic watching.

## 18. Custom Controls

A custom control is just a `View` (or `ViewGroup`) subclass:

```beef
public class RadialGauge : View
{
    public float Value;
    public float MinValue = 0, MaxValue = 100;

    protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
    {
        MeasuredSize = .(wSpec.Resolve(64), hSpec.Resolve(64));
    }

    public override void OnDraw(UIDrawContext ctx)
    {
        ctx.DrawDrawable("RadialGauge.Background", Bounds);
        // ...use ctx.VG for custom vector drawing...
    }
}
```

To make it usable in XML, register at startup:

```beef
UIRegistry.RegisterView<RadialGauge>("RadialGauge");
UIRegistry.RegisterProperty<RadialGauge, float>("Value", (w, v) => w.Value = v);
UIRegistry.RegisterProperty<RadialGauge, float>("MinValue", (w, v) => w.MinValue = v);
UIRegistry.RegisterProperty<RadialGauge, float>("MaxValue", (w, v) => w.MaxValue = v);
```

Now this works:
```xml
<RadialGauge Value="{Binding Player.Mana}" MinValue="0" MaxValue="100"/>
```

**Design principle:** custom views are first-class — no distinction between
built-in and user-defined. The registry is just data the XML loader
consults.

**Theme key fallback for custom views:** if the theme doesn't have
`"RadialGauge.Background"`, optionally fall back to `"View.Background"`
(or the nearest base class). Documented convention.

## 19. XML Authoring

Uses `Sedulous.Xml`. Conventions:

- Element name → view type (via `UIRegistry`)
- Attribute name → property name (via registry; reflection fallback)
- Child elements → `Children` of containing `ViewGroup`
- `LayoutParams` attributes (e.g., `layout_weight`, `gravity`) inferred
  from parent's runtime type via `CreateDefaultLayoutParams()`
- `{Binding Path}` attribute syntax → data binding
- `x:Name="resumeBtn"` → setter populates a code-behind reference
- `<Include Source="other.ui.xml"/>` → composition

```xml
<RootView>
  <LinearLayout orientation="Vertical" padding="16" gravity="Center">
    <Label text="Paused" styleId="Heading"/>
    <Button text="Resume" x:Name="resumeBtn" onClick="OnResume" layout_weight="1"/>
    <Button text="Settings" onClick="OnSettings"/>
    <Button text="Quit" onClick="OnQuit"/>
  </LinearLayout>
</RootView>
```

Code-first equivalent produces the same view tree.

**Hot reload:** the XML loader watches the file. On change, rebuild the
view tree. Views with matching `Name` (or `x:Name`) preserve their runtime
state where meaningful (scroll offset, focus, text-box contents).

## 20. DPI Scaling

Single scale factor for the whole UI, default 1.0.

- All view bounds in **logical units** (dp-like).
- At render time, `UIContext.Draw` applies `vg.Scale(uiScale, uiScale)`
  once at the root of the tree walk. Everything downstream renders at the
  correct physical size.
- Fonts: ask `FontService` for the size closest to
  `logicalSize * uiScale` so glyphs are crisp. Layout still uses logical
  metrics for sizing decisions.
- Stroke widths scale naturally via the transform.
- Detected from OS DPI on startup; per-window configurable.

## 21. Debug Drawing

`UIContext` owns a `UIDebugDrawSettings` flags struct:

```beef
public struct UIDebugDrawSettings
{
    public bool ShowBounds;             // outline every view
    public bool ShowPadding;            // colored band for padding
    public bool ShowMargin;             // colored band for margin
    public bool ShowDrawablePadding;    // distinct color from explicit padding
    public bool ShowHitTarget;          // highlight view under cursor
    public bool ShowFocusPath;          // chain from focused view to root
    public bool ShowTabOrder;           // numbered focus arrows
    public bool ShowLayoutInvalidation; // briefly flash views just laid out
    public bool ShowZOrder;             // numbered overlay
    public bool ShowMissingThemeKeys;   // highlight views missing theme keys
    public bool ShowPerfHotspots;       // color by Measure/Arrange/Draw cost
    public bool ShowRecyclerStats;      // overlay ListView/recycler counters
}
```

All overlays drawn via the same `VGContext` after the normal pass. Zero
overhead when off.

**Tree inspector** (Phase 14): floating debug panel with collapsible
hierarchy + properties pane (theme keys, computed bounds, focus state,
dirty flags, registered binding sources, recycler stats). Built using the
framework itself.

**Per-view timing** when `ShowPerfHotspots` on: layout/draw walks wrap
each view's `Measure` / `Arrange` / `Draw` in profiler scopes. Cost colors
views red → green by percentile.

## 22. Resource Integration

UI resource types live in `Sedulous.UI.Resources`:

- **`ThemeResource`** — wraps a loaded `Theme`. Listens for underlying
  file changes for runtime theme reloads.
- **`UILayoutResource`** — wraps a parsed UI XML layout. Holds the view
  tree blueprint (not instantiated views); instantiated via `UIXmlLoader`
  when used. Republishes on file change for hot reload.

`UISubsystem` registers these types with `ResourceSystem` at startup.

# Phased Implementation Plan

## Phase Completion Criteria

A phase is **not complete** until all three conditions hold:

1. **Code merged** — the phase's features land in `Sedulous.UI` (and
   `.Runtime` / `.Toolkit` / `.Gamekit` / `.Resources` / `.Engine.UI` as
   appropriate).
2. **Tests passing** — `Sedulous.UI.Tests` has test coverage for the
   phase's features, and `BeefBuild -project=Sedulous.UI.Tests` runs
   clean. Tests are written alongside the feature, not deferred.
3. **UISandbox updated** — `UISandbox` gains a new demo page / section
   exercising the phase's features. Layout can be refactored to match
   current API; sandbox is treated as a living gallery, not a fixed app.

Each phase section below lists its work items followed by the specific
test coverage expected and the sandbox additions.

## Implementation Status

| Phase | Status | Tests |
|-------|--------|-------|
| **1** Foundation + Runtime + Sandbox | ✅ DONE | 18 |
| **2** Drawables + Widgets + Layouts + Debug | ✅ DONE | 9 |
| **3** Input + Focus | ✅ DONE | 25 |
| **4** Theme System | ✅ DONE | 13 |
| **5** XML UI Loading | ✅ DONE | 20 |
| **6** Resource Integration | ✅ DONE | 6 |
| **7** Engine Integration | DEFERRED | — |
| **8** Scrolling | ✅ DONE | 14 |
| **9** Adapters + Virtualization | ✅ DONE | 18 |
| **11** Overlays + Controls + Legacy Adoption | ✅ DONE | 175 |
| **10** Text Editing | ✅ DONE | 218 |
| **12** Animation + Transitions | ✅ DONE | 241 |
| **13** Drag and Drop | ✅ DONE | 252 |
| **14** Toolkit + Gamekit + Polish | NOT STARTED | — |

**Total tests: 252** across Phases 1–13.

Phase 11 included: overlays (PopupLayer, ContextMenu, Dialog,
TooltipManager), 10 new controls (CheckBox, RadioButton, RadioGroup,
ToggleButton, ToggleSwitch, RepeatButton, ProgressBar, Slider,
TabView, ComboBox), legacy comparison adoption, focus stack,
ImageView ScaleType, scrollable demo layout, theme fixes.

Phase 10 included: Sedulous.UI.Shell bridge library (InputMapping,
UIInputHelper with text input emulation, ShellClipboardAdapter),
TextEditingBehavior + ITextEditHost, EditText (single + multiline),
PasswordBox, UndoStack, InputFilter, IClipboard, focus stack for
popup focus save/restore.

Phase 12 included: Animation base + FloatAnimation/ColorAnimation/
Vector2Animation, Storyboard (Sequential/Parallel), AnimationManager,
Easing convenience wrapper, ViewAnimator factories, DrawChildren
Alpha/RenderTransform support, transform-aware hit-testing,
VGContext DrawTextWrapped/MeasureTextWrapped/FillPolygon.

Phase 13 included: DragDropManager state machine, IDragSource/
IDropTarget, DragData, DragAdorner, DPI wiring from Shell window,
View.ToLocal, UIContext multi-window readiness properties.

See **Deferred Work** section at the end of this document for all
items skipped or deferred from completed phases.

## Phase 1 — First light: foundation + runtime + sandbox

> **Status: ✅ COMPLETE**

**Goal: get the real `UISubsystem` driving the real `UISandbox` rendering
real UI on screen.** VGRenderer is already proven, so there's no reason
to spend a phase headless before seeing pixels. Phase 1 is bigger than
a typical first phase but concludes with a running, demoable sandbox
— every subsequent phase then just adds capability to an already-working
app.

**Code (`Sedulous.UI` — core data model):**
- `View` / `ViewGroup` / `RootView` hierarchy
- `ViewId` (atomic counter), `ElementHandle<T>`, `Registry` on `UIContext`
- `MutationQueue` + `IsPendingDeletion` flag + `UIPhase` tracking
- `MeasureSpec` (mode + size) + `Resolve()`
- `LayoutParams` base (with `MatchParent` / `WrapContent` sentinels)
- `Gravity` bit flags + `GravityHelper.Apply()`
- `Visibility` (Visible/Invisible/Gone) + layout skipping for Gone
- `Thickness`, `Orientation`, `Alignment` value types
- `LinearLayout` (horizontal/vertical, weight distribution, Gravity)
- `FrameLayout` (gravity-positioned overlay stack)
- `ColorView` — simplest concrete widget, fills bounds with a color.
  Uses direct `UIDrawContext.VG.FillRect`. (Drawable system lands in
  Phase 2; this keeps Phase 1 scope tight.)
- `UIDrawContext` — thin wrapper over `VGContext` for now. No
  theme-aware helpers yet.
- Tree-walk render: `UIContext.Draw(vg)` emits into the context.
- DPI scale transform applied once at the render-pass root.
- Reverse-order hit test in `ViewGroup` (no input routing yet — just the
  hit-test primitive; actual event routing lands Phase 3)

**Code (`Sedulous.UI.Runtime` — real subsystem from day one):**
- `UISubsystem` extends `Sedulous.Runtime.Subsystem` (UpdateOrder = 400,
  matching `GUISubsystem`). Owns:
  - `UIContext` (the view tree + registry + mutation queue)
  - `VGContext` (fed by the tree walk)
  - `VGRenderer` (submits the batch to GPU each frame)
  - `FontService` (wired via TTF loader)
- Stubbed input — `Sedulous.Shell` events accepted but not yet routed
  (FocusManager/InputManager land Phase 3). Click/key/move events get
  noted but don't affect the tree.
- Window resize / DPI change propagates to `RootView.ViewportSize` /
  `DpiScale`
- Basic frame loop: drain MutationQueue → Layout if invalidated → Draw
  → Submit

**Code (UISandbox — running app):**
- `Code/Samples/UI/UISandbox/` created, mirrors `VGSandbox` layout
- `Application` subclass that creates `UISubsystem` via
  `Sedulous.UI.Runtime`
- Shows a composed layout: a vertical `LinearLayout` filling the window,
  containing a horizontal `LinearLayout` with weighted `ColorView`
  children, and nested `FrameLayout` demonstrating Gravity
- Proves: registration, layout pipeline, mutation queue, render path,
  subsystem integration, VG batch submission
- Static — no interactivity yet, but visually confirms the framework
  pipeline end-to-end

**Tests (`Sedulous.UI.Tests/Core`, `/Layout`, `/Registry`, `/Mutation`,
`/Runtime`):**
- Layout correctness: LinearLayout weights, FrameLayout gravity
- MeasureSpec semantics (Unspecified / AtMost / Exactly + `Resolve`)
- Visibility three-state behavior (Gone skipped in layout, Invisible
  reserves space)
- Deferred mutation: queue a remove during a synthetic event walk;
  nothing crashes, change applies after drain
- Handle safety: destroy a view mid-frame; subsequent `Resolve` returns
  null
- Phase assertions: calling sync mutation during unsafe phase asserts
- Reverse-order hit test: topmost child wins when overlapping
- `UISubsystem` lifecycle (init, update, shutdown) with a mock context
- End-to-end smoke: UISubsystem produces a non-empty VGBatch from a
  sample tree

## Phase 2 — Drawable system + full widget set + layouts + debug overlays

> **Status: ✅ COMPLETE**

Expand from the bare minimum of Phase 1 into a production-capable widget
set with composable visuals. **No theme yet** — widgets have per-instance
fields for colors/drawables; theme retrofit comes in Phase 4. Since the
sandbox is already running, each new widget and layout is added as a new
demo page.

**Code (`Sedulous.UI`):**
- **Drawable system:**
  - `Drawable` base + state-aware overload
  - Concrete: `ColorDrawable`, `RoundedRectDrawable`, `NineSliceDrawable`
    (with Expand), `ImageDrawable`, `GradientDrawable`, `ShapeDrawable`
  - Composition: `StateListDrawable`, `LayerDrawable`, `InsetDrawable`
  - `DrawablePadding` contribution + max-merge with explicit padding
- `ControlState` enum + priority resolution (used by `StateListDrawable`
  lookup even though full theming doesn't land yet)
- `UIDrawContext` gains theme-aware helpers
  (`FillBackground`, `DrawBorder`, `DrawText`, `DrawImage`) that take a
  `Drawable` argument directly; the theme-key-based overloads land Phase 4.
- Widgets: `Label`, `Button`, `ImageView`, `Panel`, `Spacer`, `Separator`
  — each carries its own `Drawable Background` / `Color Foreground`
  fields (null → hardcoded defaults; null-fallback-to-theme added Phase 4)
- Additional layouts: `GridLayout` (with two-pass Auto/Star), `FlowLayout`
  (wrap with primary/cross axis), `AbsoluteLayout`
- `View.GetBaseline()` for typography-aware `LinearLayout` horizontal mode
- Effective-enabled walk (parent-chain disable propagation)
- **Debug overlays:** `ShowBounds`, `ShowPadding`, `ShowMargin`,
  `ShowDrawablePadding`, `ShowZOrder` — pay for themselves immediately
  while building later widgets

**Tests (`Sedulous.UI.Tests/Drawing`, `/Layout`, `/Core`):**
- `NineSliceDrawable` with and without `Expand` (DrawablePadding correct)
- `StateListDrawable` state priority resolution with fallback
- `LayerDrawable` per-layer insets
- `InsetDrawable.DrawablePadding` reported correctly
- Grid two-pass: Auto + Star sizing
- FlowLayout wraps correctly in both orientations
- `LinearLayout` baseline alignment for horizontal text rows
- `UIDrawContext` correctly pushes/pops clip rects
- Debug overlay toggles: batch empty when all flags false

**UISandbox:**
- "Widgets" page with Label/Button/ImageView/Panel (buttons still
  non-interactive until Phase 3)
- "Drawables" page demonstrating all drawable primitives + composition
  (StateListDrawable cycling through states by pressing a key, etc.)
- "Layouts" page with GridLayout/FlowLayout/AbsoluteLayout side-by-side
- Debug-overlay toggle keys (F1=bounds, F2=padding, F3=margin, F4=drawable-padding, F5=z-order)

## Phase 3 — Input + focus

> **Status: ✅ COMPLETE** — Focus restoration on overlay close deferred to
> Phase 11. TextInputEventArgs deferred to Phase 10.

With the runtime subsystem already established, this phase turns buttons
into buttons, makes hover/focus work, and wires `Sedulous.Shell` events
through to the tree.

**Code (`Sedulous.UI`):**
- `InputManager` with pooled event args (`MouseEventArgs`,
  `MouseWheelEventArgs`, `KeyEventArgs`, `TextInputEventArgs`)
- Hit-testing (top-down through tree, reverse-order in ViewGroup)
- Hover refresh on mouse-down
- Capture (single view) via `FocusManager.SetCapture`
- Mouse wheel bubbles; other mouse events stop at hit
- Click count + distance threshold → `MouseEventArgs.ClickCount`
- `KeyModifiers` per event; no global state
- `IsRepeat` flag on key events
- `e.Handled` cooperative propagation
- `IAcceleratorHandler` top-down search for Alt+key
- `FocusManager`:
  - Three-axis focusability (`IsFocusable`/`IsTabStop`/`IsEffectivelyEnabled`)
  - `IsFocusWithin` (computed via parent chain)
  - HTML-style Tab order (TabIndex>0 sorted, TabIndex==0 tree order)
  - Focus restoration on overlay close
  - Modal trap hook (no modal manager yet — that's Phase 11)
  - Tab vs Ctrl+Tab distinction reserved
- `EffectiveCursor` walks parent chain
- `UIContext.Focused`, `Hovered`, `Capturing` stored as `ViewId`,
  resolved per use
- `Button.OnClick` event, focus ring rendering
- **Debug overlays:** `ShowHitTarget`, `ShowFocusPath`, `ShowTabOrder`

**Code (`Sedulous.UI.Runtime`):**
- `UIInputHelper` — real `Sedulous.Shell` event → `InputManager` wiring
  (was stubbed in Phase 1)
- `InputMapping` — Shell `KeyCode` → UI `KeyCode` translation
- `UISubsystem` feeds pumped events into `InputManager` each frame

**Tests (`Sedulous.UI.Tests/Input`, `/Focus`, `/Runtime`):**
- Hit-test finds topmost overlapping view
- Hover state stable across synthetic mouse events
- Click count logic: double-click requires both time + distance threshold
- Mouse wheel bubbles up through parents until handled
- Tab order: TabIndex>0 sorted first, TabIndex==0 in tree order
- `IsEffectivelyEnabled` walks parent chain (disabled parent propagates)
- `IsFocusWithin` true for ancestors of focused view
- Capture: captured view receives all mouse events regardless of hit
- `ViewId`-based hovered/focused survives view destruction (returns null
  via `Resolve`, no crash)
- Accelerator search hits correct target top-down
- `UIInputHelper`: shell events arrive at the correct view

**UISandbox:**
- Existing Phase 2 pages gain interactivity — buttons actually respond
- "Input" page: focus rings, hover-change demo, capture demo (slider
  thumb), tab-order visualization with DebugDraw overlays active
- "Events" page showing a live log of routed events (capture/target/bubble
  phases, Handled state)

**Tests (`Sedulous.UI.Tests/Input`, `/Focus`):**
- Hit-test finds topmost overlapping view
- Hover state stable across synthetic mouse events
- Click count logic: double-click requires both time + distance threshold
- Mouse wheel bubbles up through parents until handled
- Tab order: TabIndex>0 sorted first, TabIndex==0 in tree order
- `IsEffectivelyEnabled` walks parent chain (disabled parent propagates)
- `IsFocusWithin` true for ancestors of focused view
- Capture: captured view receives all mouse events regardless of hit
- `ViewId`-based hovered/focused survives view destruction (returns null
  via `Resolve`, no crash)
- Accelerator search hits correct target top-down

**UISandbox:**
- "Input" page: focus rings, hover-change demo, capture demo (slider
  thumb), tab-order visualization with DebugDraw overlays active
- "Events" page showing a live log of routed events (capture/target/bubble
  phases, Handled state)

## Phase 4 — Theme system

> **Status: ✅ COMPLETE** — Theme XML parser deferred to Phase 6. Theme
> XML round-trip test deferred with it.

**Code (`Sedulous.UI`):**
- `Theme` with typed flat dictionaries (Color, Dimension, Padding,
  Drawable, String, Font)
- `Palette` struct with `Lighten`/`Darken`/`Desaturate`/`Compute*` helpers
- Per-control nullable property pattern (retrofit: `Color? mBackground`
  returns theme value when null; widgets from Phase 2 updated to use
  this pattern)
- Built-in `DarkTheme` + `LightTheme` factories
- `IThemeExtension` static registry with `Theme.RegisterExtension`
- Theme XML parser in `Sedulous.UI` (uses `Sedulous.Xml`)
- Runtime theme switching (deferred via mutation queue, triggers
  `InvalidateLayout` on next frame)
- Border thickness / padding changes call `InvalidateLayout`
- `UIDrawContext` gains theme-key-based overloads
  (`FillBackground("Button.Background")`)

**Tests (`Sedulous.UI.Tests/Theming`):**
- Palette `ComputeHover` / `ComputePressed` / `ComputeDisabled` produce
  expected values
- `IThemeExtension` applied after base init, can inject new keys
- Nullable override: setting `mBackground = null` falls back to theme;
  non-null overrides
- Theme XML round-trip (parse → re-serialize → parse)
- Theme change triggers layout invalidation on affected views

**UISandbox:**
- "Themes" page: toggle between Dark / Light themes at runtime;
  same widgets re-theme instantly
- All widgets from Phase 2/3 retrofit to go through theme
  (hardcoded defaults removed)

## Phase 5 — XML UI loading + view registry

> **Status: ✅ COMPLETE** — `{Binding Path}` syntax and `<Include Source=...>`
> deferred. Both need infrastructure not yet built (observable bindings,
> file I/O integration).

Declarative UIs, file-I/O-free (parsing only).

**Code (`Sedulous.UI`):**
- `UIRegistry` with view + property registration
- XML → view tree loader in `Sedulous.UI`
- Implicit `LayoutParams` subclass dispatch from parent type
- `{Binding Path}` syntax (one-way only)
- `x:Name` code-behind references
- `<Include Source=...>` composition

**Tests (`Sedulous.UI.Tests/Xml`):**
- Round-trip: code-built tree ≡ tree built from XML string that
  describes it (structural equality)
- `LayoutParams` subclass correctly chosen from parent type
- `x:Name` populates the target field
- `{Binding Path}` resolves simple paths, updates on change
- Unknown element type → clear error with location
- Unknown property → clear error with available properties listed

**UISandbox:**
- "XML Loading" page: sidebar showing XML source, main area showing the
  rendered tree. Edit XML in a scratch file, reload via button (full
  hot reload comes with resource integration in Phase 6).

## Phase 6 — Resource integration

> **Status: ✅ COMPLETE** — Hot-reload file watching deferred to Phase 7
> (needs engine FileWatcher). `<Include Source=...>` in layout XML
> deferred (needs file I/O resolution path).

`Sedulous.UI.Resources` wraps Phase 4 & 5 parsers as engine resources.

**Code (`Sedulous.UI.Resources`):**
- `ThemeResource` + `UILayoutResource`
- Serializers registered with `SerializerProvider`
- Resource change listener hooks for hot reload
- (Engine-side registration deferred to Phase 7)

**Tests (`Sedulous.UI.Tests/Resources`):**
- `ThemeResource` loads + hot-reloads from mock filesystem
- `UILayoutResource` republishes to listeners on file change
- Dependency tracking: layout referencing theme reloads when theme changes

**UISandbox:**
- "Resource Integration" page: loads theme + layout from resource files,
  demonstrates hot reload by editing the theme file (color change visible
  without restart).

## Phase 7 — Engine integration

> **Status: DEFERRED** — Engine integration is only useful once enough UI
> capability exists (scrolling, text editing, overlays) to build real
> game UIs. Phases 8–11 proceed first using the standalone
> `Sedulous.UI.Runtime` + `UISandbox` driver. Phase 7 picks up after.

`Sedulous.UI.Runtime` has been around since Phase 1. This phase adds the
engine-specific layer — scene integration, resource system registration,
and engine-provided window hosting. Thin phase; most of the heavy lifting
is already done.

**Code (`Sedulous.UI.Runtime`):**
- `ShellClipboardAdapter`: full `IClipboard` impl (round-trips Shell
  clipboard). Stubbed in Phase 1, completed here since Phase 10 text
  editing will lean on it heavily.

**Code (`Sedulous.Engine.UI`):**
- Registers `ThemeResource` / `UILayoutResource` types with `ResourceSystem`
- `WorldSpaceUIComponent` + manager (3D-anchored UI, uses Gamekit
  widgets when Phase 14 lands them)
- Default `IFloatingWindowHost` impl using engine windows
- Cursor management (engine cursor swap via `View.EffectiveCursor` chain)
- Optional: `EngineUISubsystem` thin wrapper or composition that adds
  engine-side behavior (scene tick integration, resource hot-reload
  propagation) on top of `Sedulous.UI.Runtime.UISubsystem`

**Tests (`Sedulous.UI.Tests/Runtime`):**
- `ShellClipboardAdapter` round-trip
- Engine-side integration tests stay minimal (deeper integration tested
  in engine layer itself)

**UISandbox:**
- Clipboard works (Ctrl+C / Ctrl+V on prospective text fields)
- No major refactor — sandbox continues working as before; this phase
  mostly benefits engine-side consumers

## Phase 8 — Scrolling

**Code (`Sedulous.UI`):**
- `MomentumHelper` struct (kinetic friction-decay scroll)
- `ScrollBar` standalone view (independently themeable, owned outside
  `mChildren`)
- `ScrollBarPolicy` enum (Never/Auto/Always)
- `ScrollView` with negative-offset layout
- Cascading visibility recompute when both axes are Auto
- `View.ScrollIntoView()` walks up to nearest scrollable ancestor

**Tests (`Sedulous.UI.Tests/Scrolling`):**
- `MomentumHelper` velocity decay curve matches expected exponential
- Snap to zero below `StopThreshold`
- `ScrollView` negative-offset layout: child bounds correct at various
  scroll offsets
- `ScrollBarPolicy.Auto` shows bar when content exceeds viewport, hides
  when not
- Both-axes-auto cascading visibility (enabling H makes V space smaller,
  may trigger V, etc.)
- `ScrollIntoView` computes correct offset for nested scrollable
  ancestors

**UISandbox:**
- "Scrolling" page: long content in `ScrollView` with various policies.
  Mouse wheel, drag on scrollbar, momentum after drag release.

## Phase 9 — Adapters + virtualization

`ListView` + `TreeView` powered by adapters.

**Code (`Sedulous.UI`):**
- `IListAdapter` interface with multi-view-type support
- `ITreeAdapter` interface
- `FlattenedTreeAdapter` (tree → flat virtualizable list)
- `ViewRecycler` (per-view-type pool + diagnostic counters)
- `SelectionModel` (separate from view, with `ShiftIndices` for tree expand)
- `ListView` virtualization:
  - Fixed item height: O(1) visible range
  - Variable height: cached offsets + binary search
  - Recycle on scroll-out
- `TreeView` (uses `FlattenedTreeAdapter` to reuse `ListView` virtualization)
- **Debug overlay:** `ShowRecyclerStats`

**Tests (`Sedulous.UI.Tests/Data`):**
- `ViewRecycler` reuses views (ReusedCount increments, CreatedCount stops)
- Multi-view-type adapter: views returned to correct pool
- `ListView` fixed-height visible range matches expected O(1) formula
- `ListView` variable-height: binary search finds correct range
- `FlattenedTreeAdapter` expand/collapse updates flat list correctly
- `SelectionModel.ShiftIndices` adjusts selection on insertion
- Adapter `OnChanged` / `OnRangeChanged` notifications trigger rebinds

**UISandbox:**
- "Virtualized List" page: 10,000 items with heterogeneous view types
  (e.g., text rows + image rows). Recycler stats overlay visible.
- "Tree View" page: filesystem-like browser using `ITreeAdapter` with
  lazy expansion. Selection survives expand/collapse.

## Phase 10 — Text editing

**Code (`Sedulous.UI`):**
- `TextEditingBehavior` + `ITextEditHost` interface
- `InputFilter` (None/Digits/HexDigits/Custom)
- `UndoStack` with fixed capacity + 1.0s coalescing window for char-insert
- `IClipboard` interface
- UTF-8-aware caret nav
- Word boundary state machine (skip-word → skip-whitespace → stop)
- Anchor + caret selection model (normalize to range when needed)
- Caret blink via modulo on time
- Glyph cache lazy invalidation
- Caret-driven scroll for single-line
- Hit-test fallback when no shaper
- Text input control-char filter (`< 32` except Tab) at editing layer
- Navigation breaks undo merge chain
- `EditText` (single + multi-line)
- `PasswordBox` (display override, blocks Ctrl+C/X)
- Double/triple click → word/line selection
- Context menu lookup walks parent chain
- ContextMenu populated on right-click (Phase 11 brings the actual menu)

**Tests (`Sedulous.UI.Tests/Editing`):**
- UTF-8-aware navigation: Ctrl+Right skips multi-byte sequences correctly
- Word boundary state machine on various inputs
- Anchor+caret model: Shift+arrow extends; arrow collapses
- Undo coalescing: rapid char inserts merge, navigation breaks chain
- `InputFilter` rejects non-matching chars
- `UndoStack` drops oldest on overflow
- Selection normalization regardless of anchor/caret order
- `PasswordBox` blocks Ctrl+C / Ctrl+X

**UISandbox:**
- "Text Editing" page: multi-line `EditText` with undo/redo, word
  selection, copy/paste. Also `PasswordBox`, numeric-only input
  (`InputFilter.Digits`), and UTF-8 stress text (emoji, diacritics).

## Phase 11 — Overlays / popups / dialogs / menus / tooltips

**Code (`Sedulous.UI`):**
- `PopupLayer` with three-state hit-test (empty/normal/modal)
- `PopupEntry` with `OwnsView` flag
- `PopupPositioner` static helpers
  (BestFit / Below / Above / Submenu)
- `ModalBackdrop` deferred (added on first modal, removed on last close)
- `IPopupOwner` notification interface
- LMB vs RMB click-outside differential behavior
- `Dialog` with `Alert` / `Confirm` static factories
- Drawable padding merged via `max` with explicit padding
- `ContextMenu` with `MenuItem` (cascaded delete), submenu hover-open,
  `CloseEntireChain`
- `TooltipManager` (timing/state) + `TooltipView` (rendering)
  - Default 0.5s show-delay, 5s auto-hide
  - Single TooltipView reused
- Render order: tree → backdrop → popups → drag adorner
- Modal focus trap via `ModalManager` registered as service

**Tests (`Sedulous.UI.Tests/Overlay`):**
- `PopupLayer` three-state hit-test (empty → null, normal → child,
  modal → self)
- `PopupEntry.OwnsView` flag: true deletes on close, false detaches
- `PopupPositioner.BestFit` flips above when clipping bottom
- `PopupPositioner.Submenu` flips left when clipping right
- `ModalBackdrop` added on first modal, removed on last close
- `IPopupOwner.OnPopupClosed` called on close
- `ContextMenu` submenu cascade delete (MenuItem owns submenu)
- `TooltipManager` shows after delay, hides after auto-hide

**UISandbox:**
- "Overlays" page: buttons for Alert/Confirm dialogs, context menu on
  right-click with nested submenus (hover-open), tooltips on every
  button, modal test.

## Phase 12 — Animation + transitions

**Code (`Sedulous.UI`):**
- `Animation` base class with virtual `Apply(t)` and `ElementHandle<View>` target
- Concrete: `FloatAnimation`, `ColorAnimation`, `Vector2Animation`,
  `ThicknessAnimation`, `RectangleAnimation`
- Delegate-based getter+setter (compile-time safe, no reflection)
- `Storyboard` with Sequential/Parallel modes (Storyboard *is* an Animation)
- `AnimationManager` with deferred mutation under update lock
  (pending-add / pending-remove)
- `OnElementDeleted(view)` cancels animations targeting that view
- `FillBehavior.Stop` (default) vs `Reset` per animation
- `Easings` static helpers (Linear, EaseIn/Out/InOutQuad/Cubic/Quart,
  Back, Elastic, Bounce, ...)
- `ViewAnimator` static factory shortcuts
  (`FadeIn`, `FadeOut`, `SlideIn`, `Pulse`, ...)
- Extension methods for one-liner `Start*` variants
- Style transitions on state change (hover/press fade-in)
- **Debug overlays:** `ShowLayoutInvalidation`, `ShowPerfHotspots`

**Tests (`Sedulous.UI.Tests/Animation`):**
- Animation progress: t=0 → from, t=1 → to, eased in between
- AutoReverse + RepeatCount semantics
- Storyboard Sequential: children start at correct times, complete in order
- Storyboard Parallel: all children advance together
- `OnElementDeleted` cancels animations targeting that view
- `FillBehavior.Reset` restores original value on cancel
- Pending-add/remove during manager Update doesn't corrupt iteration

**UISandbox:**
- "Animation" page: fade transitions on hover, sequential storyboard
  demo (card flip-in sequence), parallel storyboard (multiple properties
  tweening together), custom easing curves comparison.

## Phase 13 — Drag and drop

**Code (`Sedulous.UI`):**
- `DragData` (format-string keyed dictionary)
- `IDragSource` / `IDropTarget` interfaces (symmetric)
- `DragDropEffects` enum (Copy/Move/Link)
- `DragDropManager` state machine (Idle / Potential / Active)
- Distance threshold for Potential → Active transition
- Capture acquired immediately on Potential
- Skip drag on double-click
- Drop walks parent chain (don't skip drag source)
- `DragAdorner` data class with optional `CustomRender` delegate
- Adorner closure ordering: closed *before* `OnDrop`
- Cross-window drag: adorner stays in originating PopupLayer
- Drag-source lookup walks parent chain

**Tests (`Sedulous.UI.Tests/DragDrop`):**
- State machine: Idle → Potential → Active with threshold
- Drag cancelled if threshold not met within mouse-up window
- Drop walks parent chain including source (for reorder)
- Double-click guards drag start
- Adorner lifecycle: closed before OnDrop fires

**UISandbox:**
- "Drag and Drop" page: swap-reorder list where items drag within the
  same container (tests drag-source-as-drop-target), cross-container
  drag (move from left list to right), tab-drag to rearrange tabs.

## Phase 14 — Toolkit + Gamekit + polish

Now that the core framework is complete, spin up the two supporting
libraries and the final polish items.

**Code (`Sedulous.UI.Toolkit`):**
- `DockManager` (binary split tree + tab groups)
- `DockablePanel`, `FloatingWindow` (uses `IFloatingWindowHost`)
- `PropertyGrid` (delegate getter/setter + type enum + custom editor)
- `DataGrid` (column definitions, sort/resize, row virtualization via
  Phase 9's adapter)
- **UI Tree Inspector:** floating debug panel (collapsible hierarchy,
  properties pane with theme keys / computed bounds / focus state /
  dirty flags / binding sources / recycler stats). Built entirely from
  framework primitives — eats its own dog food.

**Code (`Sedulous.UI.Gamekit`):**
- HUD widgets: `HealthBar`, `ManaBar`, `StaminaBar`
- `RadialGauge`, `ActionBar`, `Minimap`
- `Nameplate`, `DamageNumber` (floating + animated)
- `WorldSpaceAnchor` view (base for world-anchored UI; actual scene
  attachment lives in `Sedulous.Engine.UI`'s `WorldSpaceUIComponent`)

**Code (`Sedulous.UI` + `Sedulous.UI.Runtime`):**
- Gamepad navigation:
  - DPad → focus traversal (uses focus model from Phase 3)
  - A button → activate focused control
- Two-way binding for `EditText` / `Slider` / `CheckBox`
- `View.ContentDescription` accessibility hook (no reader yet; just the
  field + a way to export a tree description)

**Tests:**
- `Sedulous.UI.Tests/Toolkit/` — DockManager split/merge, PropertyGrid
  field enumeration, DataGrid column resize math
- `Sedulous.UI.Tests/Gamekit/` — HealthBar value clamping, RadialGauge
  angle math

**UISandbox (gallery finale):**
- "Toolkit" page: a docked workspace demo with dockable panels, a
  PropertyGrid inspecting the selected view, a DataGrid, and the live
  tree inspector overlay
- "Gamekit" page: HUD showcase with health/mana/stamina bars, action
  bar, animated damage numbers, radial gauge
- "Sample Game UI" page: pause menu, inventory grid, dialog boxes, with
  world-space nameplates floating over demo entities — all wired through
  bindings to mock game state
- Gamepad navigation works across all pages

## Execution Order

All design decisions resolved; ready to start.

**Philosophy: sandbox runs from Phase 1.** `Sedulous.UI.Runtime` and
`UISandbox` are established on day one — the sandbox is a running,
rendering app from the first phase. Every later phase just grows the
framework while the sandbox keeps working. No "big bang" moment where
everything suddenly needs to integrate.

1. **Phase 1** (foundation + runtime + first-light sandbox) — COMPLETE
2. **Phase 2** (drawables + full widget set + layouts + debug overlays) — COMPLETE
3. **Phase 3** (input + focus) — COMPLETE
4. **Phases 4-5** (theme + XML parsing) — COMPLETE
5. **Phase 6** (resource integration) — COMPLETE
6. **Phases 8-9** (scrolling + virtualization) — COMPLETE
7. **Phase 11** (overlays + controls + legacy adoption) — COMPLETE
8. **Phase 10** (text editing + Sedulous.UI.Shell) — COMPLETE
9. **Phase 12** (animation + transitions) — COMPLETE
10. **Phase 13** (drag and drop + DPI wiring) — COMPLETE
11. **Phase 7** (engine integration) — deferred until enough UI
    capability exists to build real game UIs.
12. **Phase 14** (Toolkit + Gamekit + polish) — final libraries, tree
    inspector, sample game UI gallery.

**Phases 1-6 and 8-13 are COMPLETE.** Only Phase 7 (engine integration)
and Phase 14 (Toolkit + Gamekit + polish) remain.

**Remaining work:**
- **Phase 7** (engine integration) — WorldSpaceUIComponent, scene hooks,
  resource system wiring. Deferred until real game UI is being built.
- **Phase 14** (Toolkit + Gamekit + polish) — DockManager, PropertyGrid,
  DataGrid, UI Inspector, HUD widgets, gamepad navigation, two-way
  binding. The final feature-complete phase.

## Files

### Sedulous.UI

```
src/
  View.bf
  ViewGroup.bf
  RootView.bf

  Core/
    UIContext.bf            // root: registry + queue + theme + managers
    UIPhase.bf              // Idle / RoutingInput / LayingOut / Drawing
    UIDrawContext.bf
    Visibility.bf
    Orientation.bf
    Thickness.bf
    Alignment.bf
    UIDebugDrawSettings.bf
    UIDebugOverlay.bf
    UIInspector.bf

  Registry/
    ViewId.bf
    ElementHandle.bf
    Registry.bf

  Mutation/
    MutationQueue.bf
    IsPendingDeletion handled on View

  Layout/
    LayoutParams.bf
    MeasureSpec.bf
    Gravity.bf
    LinearLayout.bf
    GridLayout.bf
    FrameLayout.bf
    FlowLayout.bf
    AbsoluteLayout.bf

  Drawing/
    Drawable.bf
    ColorDrawable.bf
    RoundedRectDrawable.bf
    NineSliceDrawable.bf
    GradientDrawable.bf
    ImageDrawable.bf
    ShapeDrawable.bf
    StateListDrawable.bf
    LayerDrawable.bf
    InsetDrawable.bf

  Theming/
    Theme.bf
    Palette.bf
    ControlState.bf
    IThemeExtension.bf
    DarkTheme.bf
    LightTheme.bf
    ThemeXmlLoader.bf

  Input/
    InputManager.bf
    InputEventArgs.bf       // pooled
    KeyCode.bf
    KeyModifiers.bf
    CursorType.bf
    InputFilter.bf
    FocusManager.bf
    IAcceleratorHandler.bf
    ElementBoundEvent.bf

  Editing/
    TextEditingBehavior.bf
    ITextEditHost.bf
    UndoStack.bf
    IClipboard.bf

  DragDrop/
    DragDropManager.bf
    DragData.bf
    DragAdorner.bf
    DragDropEffects.bf
    IDragSource.bf
    IDropTarget.bf

  Data/
    IListAdapter.bf
    ITreeAdapter.bf
    FlattenedTreeAdapter.bf
    ViewRecycler.bf
    SelectionModel.bf

  Animation/
    Animation.bf
    AnimationManager.bf
    AnimationState.bf
    Storyboard.bf
    ViewAnimator.bf
    FloatAnimation.bf
    ColorAnimation.bf
    Vector2Animation.bf
    ThicknessAnimation.bf
    RectangleAnimation.bf
    Easing.bf
    FillBehavior.bf

  Overlay/
    PopupLayer.bf
    PopupEntry.bf
    PopupPositioner.bf
    PopupWindow.bf
    ModalBackdrop.bf
    ModalManager.bf
    IPopupOwner.bf
    Dialog.bf
    ContextMenu.bf
    MenuItem.bf
    TooltipManager.bf
    TooltipView.bf
    IFloatingWindowHost.bf

  Commands/
    ICommand.bf
    RelayCommand.bf

  Bindings/
    Binding.bf
    BindingResolver.bf

  Xml/
    UIRegistry.bf
    UIXmlLoader.bf

  Controls/
    Label.bf
    Button.bf
    ToggleButton.bf
    CheckBox.bf
    RadioButton.bf
    RadioGroup.bf
    Slider.bf
    ProgressBar.bf
    EditText.bf
    PasswordBox.bf
    ImageView.bf
    Panel.bf
    Spacer.bf
    Separator.bf
    ScrollView.bf
    ScrollBar.bf
    ListView.bf
    TreeView.bf
    ColorView.bf
    MomentumHelper.bf
```

### Sedulous.UI.Resources

```
src/
  ThemeResource.bf
  UILayoutResource.bf
  ThemeSerializer.bf
  UILayoutSerializer.bf
  UIResourceTypeIds.bf
```

### Sedulous.UI.Runtime

Depends on `Sedulous.UI`, `Sedulous.Runtime`, `Sedulous.Shell`,
`Sedulous.VG.Renderer`, `Sedulous.Fonts.TTF`.

```
src/
  UISubsystem.bf           // extends Sedulous.Runtime.Subsystem
  UIInputHelper.bf         // Sedulous.Shell events → UIInputEvent
  ShellClipboardAdapter.bf // IClipboard over Shell
  InputMapping.bf          // shell KeyCode → UI KeyCode
```

### Sedulous.UI.Toolkit

Depends on `Sedulous.UI`.

```
src/
  Docking/
    DockManager.bf
    DockablePanel.bf
    FloatingWindow.bf
    DockSplit.bf
    DockTabGroup.bf
    DockPosition.bf
    DockTarget.bf
  PropertyGrid/
    PropertyGrid.bf
    PropertyItem.bf
    PropertyType.bf
  DataGrid/
    DataGrid.bf
    DataGridColumn.bf
    DataGridTextColumn.bf
    DataGridCheckBoxColumn.bf
  Inspector/
    UIInspector.bf         // debug tree + properties panel
```

### Sedulous.UI.Gamekit

Depends on `Sedulous.UI`.

```
src/
  HUD/
    HealthBar.bf
    ManaBar.bf
    StaminaBar.bf
    ActionBar.bf
    Minimap.bf
  Gauges/
    RadialGauge.bf
  WorldSpace/
    WorldSpaceAnchor.bf    // view base; scene attachment is in Engine.UI
    Nameplate.bf
    DamageNumber.bf
```

### Sedulous.UI.Tests

Depends on `Sedulous.UI`, `Sedulous.UI.Runtime`, `Sedulous.UI.Toolkit`,
`Sedulous.UI.Gamekit`, `Sedulous.UI.Resources`, xUnit-style test harness.

```
src/
  TestHelper.bf
  Core/           // View tree, registry, mutation, phase tracking
  Layout/         // MeasureSpec, LayoutParams, Gravity, panels
  Drawing/        // Drawable hierarchy, DrawablePadding, state resolution
  Theming/        // Palette math, IThemeExtension, theme XML round-trip
  Input/          // Hit-test, hover, capture, click count, bubbling
  Focus/          // Three-axis focusability, tab order, IsFocusWithin
  Xml/            // Registry, XML loader, LayoutParams dispatch, bindings
  Resources/      // Hot reload, dependency tracking
  Runtime/        // UISubsystem lifecycle, shell integration
  Scrolling/      // MomentumHelper, scroll offset, policy
  Data/           // Adapter, recycler, FlattenedTree, SelectionModel
  Editing/        // TextEditingBehavior, UTF-8 nav, undo coalescing
  Overlay/        // PopupLayer, PopupPositioner, modal, tooltip
  Animation/      // Progress, storyboard, manager mutation safety
  DragDrop/       // State machine, threshold, adorner lifecycle
  Toolkit/        // DockManager, PropertyGrid, DataGrid
  Gamekit/        // HealthBar, RadialGauge math
```

### Sedulous.Engine.UI

Depends on `Sedulous.UI.Runtime`, `Sedulous.UI.Gamekit`,
`Sedulous.UI.Resources`, engine layer.

```
src/
  UIResourceRegistration.bf    // registers ThemeResource / UILayoutResource
  Components/
    WorldSpaceUIComponent.bf   // uses Gamekit's WorldSpaceAnchor
    WorldSpaceUIComponentManager.bf
  EngineFloatingWindowHost.bf  // default IFloatingWindowHost impl
```

### Samples/UI/UISandbox

Depends on `Sedulous.Runtime.Client`, `Sedulous.UI`, `Sedulous.UI.Runtime`,
`Sedulous.UI.Toolkit`, `Sedulous.UI.Gamekit`, `Sedulous.UI.Resources`,
`Sedulous.VG.Renderer`.

```
src/
  Program.bf                // Application subclass, hosts UISubsystem
  Pages/
    WidgetsPage.bf          // Phase 2
    DrawablesPage.bf        // Phase 2
    InputPage.bf            // Phase 3
    ThemePage.bf            // Phase 4
    XmlLoadingPage.bf       // Phase 5
    ResourcesPage.bf        // Phase 6
    ScrollingPage.bf        // Phase 8
    VirtualizedListPage.bf  // Phase 9
    TreeViewPage.bf         // Phase 9
    TextEditingPage.bf      // Phase 10
    OverlaysPage.bf         // Phase 11
    AnimationPage.bf        // Phase 12
    DragDropPage.bf         // Phase 13
    ToolkitPage.bf          // Phase 14
    GamekitPage.bf          // Phase 14
    SampleGameUIPage.bf     // Phase 14
```

## Deferred Work

Items skipped or deferred from completed phases, with their original
phase and the reason for deferral. Pick these up when the prerequisite
infrastructure lands or when the feature becomes blocking.

### From Phase 1

| Item | Reason | Where it fits |
|------|--------|---------------|
| `Alignment` value type | Gravity covers H+V alignment + fill. Separate type is redundant. | **Dropped** — not needed |

### From Phase 3

| Item | Reason | Where it fits |
|------|--------|---------------|
| Focus restoration on overlay close | Needs PopupLayer + modal stack | Phase 11 (Overlays) |
| `TextInputEventArgs` | Needs text input pipeline | Phase 10 (Text Editing) |
| Debug overlay `ShowTabOrder` rendering | Flag exists but renderer not implemented | Low priority — pick up when tab order bugs arise |

### From Phase 4

| Item | Reason | Where it fits |
|------|--------|---------------|
| Theme XML round-trip test (parse → serialize → parse) | Needs XML writer for themes; ThemeXmlParser only reads | Future — add `ThemeXmlWriter` when theme editing is needed |

### From Phase 5

| Item | Reason | Where it fits |
|------|--------|---------------|
| `{Binding Path}` XML syntax | Needs `Observable<T>` or binding infrastructure | Could be its own mini-phase or part of Phase 8+ when data-driven UIs become needed |
| `<Include Source=...>` XML composition | Needs file I/O path resolution relative to the including file | Phase 7 (Engine Integration) or whenever file-based layout loading is needed |

### From Phase 6

| Item | Reason | Where it fits |
|------|--------|---------------|
| Hot-reload file watching | Needs engine `FileWatcher` infrastructure | Phase 7 (Engine Integration) |
| `<Include Source=...>` in layout XML | Same as Phase 5 deferral — needs file path resolution | Phase 7 |

### Debug overlays not yet rendering

These flags exist in `UIDebugDrawSettings` but `UIDebugOverlay` does
not implement their rendering yet:

- `ShowZOrder` — numbered overlay showing draw order
- `ShowTabOrder` — numbered arrows showing focus traversal order

Both are low priority. Implement when debugging those specific
behaviors becomes necessary.


## Legacy Comparison: Items Worth Adopting

Detailed comparison of current implementation against BansheeBeef's
legacy Sedulous.UI. Items organized by priority. Pick selectively —
not everything needs to be adopted.

### Critical (load-bearing for correctness)

| # | Item | Area | Status |
|---|------|------|--------|
| C1 | **OnInterceptMouseEvent hook** | ViewGroup | DONE — virtual method on ViewGroup |
| C2 | **Render Transform support** | View | DONE — RenderTransform + RenderTransformOrigin |
| C3 | **Full event bubbling with coordinate recalculation** | InputManager | DONE — audited; BubbleMouseDown recalculates via ToLocal per parent, correct |
| C4 | **ProcessTextInput method** | InputManager | DONE — routes char32 to focused view |
| C5 | **Modal popup awareness in tab navigation** | FocusManager | DONE — GetFocusRoot constrains to modal |
| C6 | **DeletedThisFrame tracking** | MutationQueue | DONE — NotifyDeleted + DeletedThisFrameCount |
| C7 | **Alpha property** | View | DONE — clamped 0-1 on View |

### High Priority (significant functionality gaps)

| # | Item | Area | Status |
|---|------|------|--------|
| H1 | **ListView keyboard navigation** | ListView | DONE — Up/Down/PageUp/PageDown/Home/End with selection |
| H2 | **ListView.ScrollToPosition(int)** | ListView | DONE — scrolls adapter position into view |
| H3 | **Theme-aware rendering helpers** | UIDrawContext | DONE — FillThemedBox + DrawFocusRing on UIDrawContext |
| H4 | **MeasureChild / MeasureChildWithMargins helpers** | ViewGroup | DONE — both helpers on ViewGroup |
| H5 | **MomentumHelper.IsActive threshold** | MomentumHelper | DONE — StopThreshold check |
| H6 | **SelectionModel.ShiftIndices guard** | SelectionModel | DONE — negative index guard |
| H7 | **Tooltip integration in InputManager** | InputManager | DONE — OnMouseDown hides tooltip, TooltipText used |
| H8 | **Cursor management in InputManager** | InputManager | DONE — CurrentCursor property updated from EffectiveCursor |
| H9 | **Event args with timestamps** | Input | DONE — Timestamp on MouseEventArgs + KeyEventArgs |
| H10 | **ScrollView.ScrollToView(child)** | ScrollView | DONE — scrolls child into viewport |

### Medium Priority (API completeness)

| # | Item | Area | Status |
|---|------|------|--------|
| M1 | **ScrollBar.SmallChange / LargeChange** | ScrollBar | DONE — SmallChange + auto LargeChange (90% viewport) |
| M2 | **ScrollBar.Min property** | ScrollBar | DONE — arbitrary scroll range support |
| M3 | **ScrollBar page-click behavior** | ScrollBar | DONE — pages by LargeChange on track click |
| M4 | **ScrollView convenience methods** | ScrollView | DONE — ScrollToTop/Bottom/Left/Right |
| M5 | **ScrollView.SetContent()** | ScrollView | DONE — clears children and sets single content |
| M6 | **SelectionModel.SelectedPositions** | SelectionModel | DONE — returns full HashSet |
| M7 | **Button.Command (ICommand)** | Button | DONE — ICommand + auto-disable via CanExecute |
| M8 | **ScanCode on KeyEventArgs** | Input | DONE — int32 ScanCode field |
| M9 | **Multi-window support architecture** | UIContext | DEFERRED — significant scope; single-root sufficient for now |
| M10 | **AnimationManager in UIContext** | UIContext | DEFERRED — Phase 12 |

### Things We Do Better (keep as-is)

| Item | Why ours is better |
|------|-------------------|
| **Visual children abstraction** | `VisualChildCount`/`GetVisualChild` distinguishes logical from auxiliary views (scrollbars, internal controls). Legacy has no equivalent — every auxiliary view needs manual wiring. |
| **Deferred mutation convenience** | `View.QueueRemove()`/`QueueDestroy()`/`QueueFocus()` directly on View. Legacy requires going through ViewGroup/MutationQueue. |
| **Auto-reparenting** | `AddView` automatically detaches child from previous parent. Legacy requires manual management. |
| **Explicit phase tracking** | `UIPhase` enum makes the frame lifecycle debuggable. Legacy has no equivalent. |
| **Debug overlay granularity** | Settings-driven toggles (ShowBounds, ShowPadding, ShowHitTarget, ShowRecyclerStats, etc.) with zero overhead when off. Legacy shows everything or nothing. |
| **ViewRecycler.GetOrCreate()** | Combines acquire + creation + binding in one call. Legacy requires three separate steps. |
| **Re-entrant MutationQueue** | Our closure-based queue supports actions that enqueue more actions. Legacy processes all at once without re-entrancy. |
| **IsFocusWithin** | Checks if any descendant has focus. Legacy only has `IsFocused` flag. |
