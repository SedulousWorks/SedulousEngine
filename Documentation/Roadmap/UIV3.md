# Sedulous.GUI - Clean-Slate Design

Clean-slate UI framework for the Sedulous engine, developed as
`Sedulous.GUI*` alongside the existing `Sedulous.UI*` in the engine
repo. Informed by Sedulous.UI's successes and shortcomings. Inspired by
the HTML/CSS mental model while retaining the game-UI-specific strengths
of Sedulous.UI (drawable composition, atlas batching, custom-rendered
composites, single-pass layout).

Since this is a new namespace, it coexists with Sedulous.UI — no fork
needed. Existing consumers (editor, TowerDefense, sandboxes) stay on
Sedulous.UI and migrate at their own pace.

## Why clean-slate instead of evolving v2

The v2 evolution plan (Phases 11-13) identifies several changes that
touch nearly every file in the framework:

- `Property<T>` normalization across all controls ("sweeping breaking
  change" - every control's property surface rewritten)
- `StyleId` removal and `StyleClasses` addition (every control constructor
  + every theme call site)
- `.sss` stylesheet engine layered alongside the existing Beef theme API
- `.sml` markup loader with per-control setter tables bolted on
- Gamepad/directional focus threaded into existing input pipeline

Each of these is individually sound, but together they rewrite the
framework's foundation while working around patterns that exist only
for historical reasons (three property conventions, LayoutParams casting,
string-tagged type identity, two inheritable properties out of 48).

A clean-slate lets us build with the v2 evolution's *conclusions* baked
in from the start, rather than retrofitting them. The result should be a
smaller, more consistent framework that arrives at the same destination
with less total code and zero migration shims.

## What carries forward from v2

Roughly half of v2's code is infrastructure that works well and is
unrelated to the redesign surface. These systems carry over with at most
minor adaptation:

| System | Notes |
|---|---|
| **ViewId** | Handle-based view identity with registry lookup. Sound design. |
| **BoxConstraints** | `(minW, maxW, minH, maxH)` constraint model. Already better than Android's MeasureSpec. |
| **LayoutParams model** | Container-specific typed params. Type-safe, prevents invalid property combinations. |
| **Layout containers** | FlexLayout (CSS Flexbox semantics), GridLayout (auto-flow, spanning, flex tracks), DockLayout, FrameLayout, AbsoluteLayout, FlowLayout. Proven in production. |
| **Drawable hierarchy** | ColorDrawable, RoundedRectDrawable, GradientDrawable, NineSliceDrawable, ImageDrawable, SVGDrawable, AtlasImageDrawable, AtlasNineSliceDrawable, StateListDrawable, LayerDrawable, InsetDrawable, ShapeDrawable. Unique to game UI; nothing equivalent in CSS. |
| **ThemeAtlas** | Packs theme images into single GPU texture for zero binding switches. |
| **MutationQueue** | Deferred tree changes prevent iterator invalidation during frame. |
| **InputManager** | Event routing with coordinate translation per ancestor. Mouse capture, double-click detection, pooled event args. |
| **FocusManager** | Tab/Shift+Tab navigation, modal popup focus stack, ViewId-safe tracking. |
| **DragDropManager** | IDragSource/IDropTarget with threshold activation and adorner. |
| **ShortcutManager** | Global + scoped shortcuts with modifier normalization. |
| **TooltipManager** | Hover-triggered tooltips with placement. |
| **TextEditingBehavior** | Composition-based text editing with undo stack, selection, clipboard, input filters. |
| **Animation system** | FloatAnimation, ColorAnimation, Vector2Animation, Storyboard, ViewAnimator, easing library. |
| **PopupLayer / Overlay** | Modal backdrops, click-outside dismissal, position factory callbacks, Z-order management. |
| **UISubsystem** | Runtime integration: VG rendering pipeline, shell input bridge, DPI sync, cursor sync. |
| **ViewportView** | 3D content in UI with input handler chain. |
| **Event<delegate>** | Memory-safe event system with `~ _.Dispose()`. |
| **ICommand** | CanExecute/Execute pattern for button binding. |
| **ViewRecycler** | Pool-based view recycling for virtualized lists/grids. |
| **SelectionModel** | Single/multi/range selection for data controls. |

## What gets redesigned

| Area | v2 | v3 | Why |
|---|---|---|---|
| **Property system** | Three patterns coexist: public fields, getter + `Set*()`, `Property<T>` (almost unused) | `Property<T>` uniformly for all externally-settable state | Uniform change notification, automatic invalidation, markup binding, style application - all require one consistent pattern |
| **View identity** | `StyleId: String` (overloaded as type tag + user class) | Beef type for element selectors + `StyleClasses: List<String>` for class selectors. `Name: String` as CSS `id` equivalent. | Same conclusion as v2 evolution, but native from day one |
| **Styling engine** | `StyleSheet` with Beef-code theme factories as primary path; `.sss` parser planned as addition | `.sss` as the primary theming format. Programmatic `StyleSheet` API retained as escape hatch for dynamic themes. | Designers iterate without recompilation; compound selectors from day one |
| **Style inheritance** | Only `TextColor` and `FontSize` inherit | Expanded set: `TextColor`, `FontSize`, `FontFamily`, `Cursor`, `TextAlign`, `Opacity` | CSS inherits these; reduces repetitive declarations |
| **Selectors** | Flat (Type + Class + State, no combinators) | Flat for v1, with architecture that doesn't preclude combinators in v2 | Same pragmatic call; but selector data model leaves room |
| **ControlState** | `Normal, Hover, Pressed, Focused, Disabled` | Add `Checked`, `Indeterminate` | Checkable controls use proper state cascade instead of separate `CheckedBackground` properties |
| **Composite control styling** | Flat bundled properties (`ThumbDrawable`, `TrackDrawable`, etc.) | Same for v1; pseudo-element syntax (`Slider::thumb { ... }`) as parser sugar in v2 | Preserves single-View rendering perf; pseudo-elements are syntactic, not architectural |
| **Markup** | None; imperative code only | `.sml` XML markup as first-class citizen from day one, with setter tables and LayoutParamsParser | Not bolted on; controls designed with markup in mind |
| **Gamepad / directional focus** | None; keyboard + mouse only | Spatial focus picker, `OnActivate`/`OnCancel` virtuals, arrow-key rewiring, gamepad polling - all in core | Console-ready from the start |

---

## Core Architecture

### View

The base class for all UI elements. Clean separation of concerns:
identity, tree membership, properties, styling, input, lifecycle.

```
View (base)
├── ViewGroup (container - manages children, padding, hit-test traversal)
│   ├── RootView (top-level viewport, owns PopupLayer)
│   ├── Panel (ViewGroup with background drawable)
│   └── Layout containers (FlexLayout, GridLayout, DockLayout, FrameLayout, AbsoluteLayout, FlowLayout)
└── Leaf controls (Label, Button, EditText, ImageView, Slider, etc.)
```

#### Identity

| Field | Purpose |
|---|---|
| `Id: ViewId` | Auto-allocated unique handle. Used by managers (focus, input, drag). Not user-facing. |
| `Handle: ViewHandle` | Indirection wrapper for safe external references. Cleared on deletion. |
| `Name: String?` | User-assigned name. CSS `id` equivalent. Registered in `UIContext.NameRegistry` when set. Unique within a context. |
| `StyleClasses: List<String>` | User-assigned style classes. CSS class equivalent. Multiple allowed. |

No `StyleId`. Type selectors use the Beef type directly via
`view.GetType().IsSubtypeOf(selectorType)`.

Helpers: `AddClass(name)`, `RemoveClass(name)`, `HasClass(name)`,
`ToggleClass(name)`, `SetClasses(params name[])`.

#### ViewHandle — safe view references

In v2, deleting a view can leave stale entries in the ViewId registry
until the MutationQueue drains at frame end. Code that looks up a
ViewId between deletion and drain gets a reference to freed memory.
Even code holding direct `View` references is vulnerable to
use-after-free if the view is deleted by another path.

v3 introduces `ViewHandle` as an indirection layer:

```beef
public class ViewHandle
{
    public View View;
}
```

Every View creates a `ViewHandle` at construction. The handle is a
stable heap object whose `View` field points back to the owning view.
When the view is deleted, `handle.View` is set to `null` **immediately**
— before the deferred mutation runs, before the frame ends.

**Usage patterns:**

- **Managers** (FocusManager, InputManager, DragDropManager) store
  `ViewHandle` instead of `ViewId` or raw `View` references. Checking
  `handle.View != null` is safe at any point in the frame.
- **ViewId registry** maps `uint32 -> ViewHandle`. `GetViewById()`
  returns `handle.View` (null if deleted).
- **Cross-view references** (NextFocusUp/Down/Left/Right, popup
  owners, drag sources) store `ViewHandle` for safe access.
- **External code** that needs to hold a view reference across frames
  should hold the `ViewHandle`, not the `View` directly.

```beef
/* Safe pattern */
let handle = button.Handle;
/* ... later, possibly after button is deleted ... */
if (handle.View != null)
    handle.View.OnActivate();

/* Registry lookup */
let view = context.GetViewById(id);  /* returns null if deleted */
```

The handle is lightweight (single-field class) and the null-out is
O(1). No generation counters, no weak-ref infrastructure — just
clearing one field.

#### Property<T> as the uniform property model

Every externally-settable property on View and its subclasses is a
`Property<T>`. This is the single biggest architectural difference from
v2, where properties were a mix of fields, getters, and `Set*()` methods.

```beef
public class Property<T> where bool : operator T == T
{
    private T mValue;
    private bool mIsUpdating;

    public Event<delegate void(T)> Changed ~ _.Dispose();

    public T Value
    {
        get => mValue;
        set
        {
            if (mIsUpdating) return;
            if (mValue == value) return;
            mIsUpdating = true;
            mValue = value;
            Changed(mValue);
            mIsUpdating = false;
        }
    }

    public void SetSilent(T value)       /* set without firing Changed */
    public void BindTo(Property<T> target)     /* one-way */
    public void BindTwoWay(Property<T> other)  /* two-way */
}
```

**Invalidation integration:** Property<T> on View hooks into the view's
invalidation system. When a property changes, the view is marked for
the appropriate phase:

- Layout-affecting properties (Width, Height, Padding, Margin, Visibility,
  Text on Label, etc.) mark the view for re-measure + re-layout.
- Visual-only properties (Opacity, TextColor, Background class changes,
  etc.) mark the view for redraw only.

This replaces the manual `Invalidate()` calls scattered across v2
controls.

**Decided: Invalidation granularity.**

Property changes trigger re-measure by default (safe, conservative).
Properties that are known to be visual-only can be tagged `.Visual` at
construction to skip layout and only trigger redraw. This tagging is
done by the control (it knows which of its properties affect layout).
View base marks the obvious ones: `Opacity`, `Cursor`, `TooltipText`.
Controls can override `OnPropertyChanged` for finer-grained control if
needed.

#### View base fields

Properties that exist on every View:

```
/* Identity */
Id: ViewId                          /* auto, immutable */
Name: String?                       /* user-set, optional, unique per context */
StyleClasses: List<String>          /* user-set, CSS classes */

/* Layout */
Visibility: Property<Visibility>    /* Visible, Hidden, Gone */
Opacity: Property<float>            /* 0-1, composes multiplicatively */
Transform: Property<ViewTransform>  /* post-layout translation/scale/rotation */
ClipsContent: Property<bool>        /* clip children to bounds */

/* Sizing (read by LayoutParams, but also queryable) */
MeasuredSize: Vector2               /* output of OnMeasure */
Bounds: RectangleF                  /* output of OnLayout, parent-relative */

/* Input */
IsEnabled: Property<bool>           /* interaction enabled */
IsInteractionEnabled: Property<bool>/* subtree input blocking */
IsHitTestVisible: Property<bool>    /* participates in hit-test */
IsFocusable: Property<bool>         /* can receive keyboard focus */
IsTabStop: Property<bool>           /* participates in Tab navigation */
TabIndex: Property<int32>           /* Tab order (0 = tree order) */
Cursor: Property<CursorType>       /* mouse cursor */

/* Focus (directional - from v2 Phase 13, native here) */
NextFocusUp: ViewId?
NextFocusDown: ViewId?
NextFocusLeft: ViewId?
NextFocusRight: ViewId?
WantsArrowKeys: bool                /* EditText overrides to true */

/* Tooltip */
TooltipText: Property<String?>
TooltipPlacement: Property<TooltipPlacement>

/* Computed (read-only) */
Parent: View?
Context: UIContext?
IsAttached: bool
IsHovered: bool
IsFocused: bool
IsFocusWithin: bool
IsEffectivelyEnabled: bool
EffectiveCursor: CursorType
Root: RootView?
Width: float                        /* convenience: Bounds.Width */
Height: float                       /* convenience: Bounds.Height */
```

#### View lifecycle

Same proven sequence from v2:

1. **Construction** - properties at defaults
2. **Attachment** - `UIContext.AttachView(view)` registers ViewId, propagates Context
3. **Measure** - `OnMeasure(BoxConstraints)` computes `MeasuredSize`
4. **Layout** - `OnLayout(x, y, w, h)` sets `Bounds`, positions children
5. **Draw** - `OnDraw(UIDrawContext)` renders
6. **Detachment** - clears manager references
7. **Destruction** - owned resources freed

Deferred mutations via `QueueRemove()` / `QueueDestroy()` drained at
frame end.

#### ControlState

```beef
enum ControlState
{
    Normal        = 0,
    Hover         = 1,
    Pressed       = 2,
    Focused       = 4,
    Disabled      = 8,
    Checked       = 16,
    Indeterminate = 32,
}
```

Bit flags — Beef enums support this natively. Controls return compound
states: a checked, hovered checkbox returns `.Checked | .Hover`.

`GetControlState()` composes flags rather than picking a single winner:

```beef
public virtual ControlState GetControlState()
{
    var state = ControlState.Normal;
    if (!IsEffectivelyEnabled) state |= .Disabled;
    if (IsHovered)             state |= .Hover;
    if (IsFocused)             state |= .Focused;
    return state;
}

/* CheckBox override */
public override ControlState GetControlState()
{
    var state = base.GetControlState();
    if (IsChecked.Value) state |= .Checked;
    return state;
}
```

`StateListDrawable` lookup: try exact flag combination first, then
fall back to most specific subset (e.g. `Checked | Hover` -> `Checked`
-> `Normal`).

`.sss` syntax maps naturally: `CheckBox:checked:hover { ... }` requires
both flags.

---

### Layout

The layout model carries over from v2 almost unchanged:

- **BoxConstraints** `(minW, maxW, minH, maxH)` passed top-down
- **Two-phase** measure (compute MeasuredSize) + layout (set Bounds)
- **LayoutParams** per child, typed per container
- **SizeSpec** `Fixed(Unit) | Match | Wrap` on LayoutParams
- **Unit** `Dp(float) | Pt(float) | Px(float)` with DPI resolution

Containers: FlexLayout, GridLayout, DockLayout, FrameLayout,
AbsoluteLayout, FlowLayout. All carry forward.

**Markup integration:** Each container declares a static
`LayoutParamsParser` that maps attribute names to LayoutParams fields.
The markup loader asks the parent container for its parser when
processing child attributes. This keeps LayoutParams type-safe while
making markup ergonomic:

```xml
<Flex direction="vertical" spacing="8">
  <Button text="OK" grow="1"/>    <!-- grow routes to FlexLayout.LayoutParams -->
  <Button text="Cancel"/>
</Flex>
```

No changes to the layout algorithm itself.

---

### Styling

#### `.sss` as the primary theming format

The `.sss` stylesheet language is the primary way to define themes.
Controls ship with no hardcoded visual defaults — all visuals come from
the active stylesheet.

```css
@palette dark {
  primary:        #4a8eff;
  background:     #1a1a1f;
  surface:        #24242c;
  text:           #e8e8ee;
  text-dim:       #8a8a9a;
  border:         #3a3a45;
}

@icon checkmark     "icons/checkmark.svg";
@icon chevron-right "icons/chevron-right.svg";

@import "controls/buttons.sss";

View {
  text-color: $text;
  font-size:  13;
}

Button {
  background: rounded-rect($surface, radius=6, border=$border, border-width=1);
  padding:    6 12;
}
Button:hover    { background: rounded-rect(lighten($surface, 8%), radius=6); }
Button:pressed  { background: rounded-rect(darken($surface, 8%), radius=6); }
Button:disabled { text-color: $text-dim; }

Button.primary       { background: rounded-rect($primary, radius=6); text-color: white; }
Button.primary:hover { background: rounded-rect(lighten($primary, 8%), radius=6); }
```

#### Programmatic API retained as escape hatch

The `StyleSheet` / `StyleRule` / `StyleSelector` / `StyleValue` types
remain public. Dynamic themes (e.g., user-customizable accent color at
runtime) can build rules in code. But the built-in themes (dark, light,
rounded-dark) ship as `.sss` embedded resources, not Beef factory
methods.

```beef
/* Dynamic accent color override */
let override = new StyleSheet();
let accentDrawable = Palette.CreateStateRounded(userAccentColor, 6);
override.OwnDrawable(accentDrawable);
override.ForType(typeof(Button)).AddClass("primary")
    .Set(.Background, accentDrawable);
context.PushStyleSheet(override);
```

#### Selectors

Same model as v2 evolution plan, but native from day one:

| Form | Example | Specificity |
|---|---|---|
| Type | `Label` | 1 |
| State | `:hover` | 1 |
| Class | `.hint` | 10 |
| Multi-class | `.primary.destructive` | 20 |
| Type + state | `EditText:focused` | 2 |
| Type + class | `Panel.surface` | 11 |
| Type + class + state | `Button.primary:hover` | 12 |

Subtype matching: `MyFancyButton : Button` matches `Button { ... }`
rules via `IsSubtypeOf`.

**Not in v1:** Descendant/child combinators (`Panel > Button`,
`.sidebar Label`). The selector data model stores an optional parent
selector pointer to support this later without breaking changes.

#### Style inheritance

Properties that inherit through the parent chain (child gets parent's
value if not explicitly set):

| Property | Rationale |
|---|---|
| `TextColor` | v2 already inherits this |
| `FontSize` | v2 already inherits this |
| `FontFamily` | CSS inherits; avoids repeating font on every label |
| `Cursor` | CSS inherits; container sets cursor for all children |
| `TextAlign` | CSS inherits; container sets alignment for text descendants |

**Decided: Opacity is draw-time composition only**, not cascade-inherited.
Parent 0.5 * child 0.5 = 0.25 visual opacity, applied during rendering.
Cascade inheritance would double-apply. Removed from the inheritance
table.

#### Drawable factories

Same registry from v2 evolution plan:

| Factory | Produces |
|---|---|
| `color(rgba)` | `ColorDrawable` |
| `rounded-rect(color, radius?, border?, border-width?)` | `RoundedRectDrawable` |
| `gradient(direction, stop1, stop2, ...)` | `GradientDrawable` |
| `nine-slice(image, slices, tint?)` | `NineSliceDrawable` |
| `image(path, scale-type?, tint?)` | `ImageDrawable` |
| `svg(name, tint?)` | `SVGDrawable` |
| `state-list(normal=..., hover=..., ...)` | `StateListDrawable` |
| `layer(d1, d2, ...)` | `LayerDrawable` |
| `inset(d, top, right, bottom, left)` | `InsetDrawable` |

User-extensible: `DrawableFactoryRegistry.Register("name", factory)`.

#### UITypeRegistry

Maps short string names to Beef types. Built-in controls auto-register.
Shared between the `.sss` parser (element selectors) and `.sml` loader
(element resolution). One source of truth.

```beef
UITypeRegistry.Register("Button", typeof(Button));
UITypeRegistry.Register("FlexLayout", typeof(FlexLayout));
/* ... all built-in controls ... */

/* User registration */
UITypeRegistry.Register("HealthBar", typeof(MyGame.HealthBar));
```

Short aliases allowed: `Flex` -> `FlexLayout`, `Grid` -> `GridLayout`.

---

### Markup (`.sml`)

XML-based declarative layout. First-class citizen from day one — controls
are designed with markup setters in mind.

```xml
<Flex direction="vertical" justify="center" align="stretch"
      padding="16" spacing="8">
  <Label id="title" text="@string:pause-title" font-size="24"
         align="center"/>

  <Button id="resume-btn" class="primary" width="240" height="40"
          on-click="OnResume">
    Resume
  </Button>

  <Spacer height="match" grow="1"/>

  <Label class="hint" text="ESC to resume"/>
</Flex>
```

#### Setter tables

Each control declares a static `MarkupSetters` table mapping attribute
names to property setters. Because all properties are `Property<T>`, the
setters are uniform:

```beef
public class Button : ButtonBase
{
    public static readonly MarkupSetters Setters = .()
    {
        Properties = .(
            .("text",      .String,  (v, val) => ((Button)v).Text.Value = val.AsString),
            .("font-size", .Float,   (v, val) => ((Button)v).FontSize.Value = val.AsFloat),
        ),
        Events = .(
            .("on-click", (v, ctrl, name) => ((Button)v).OnClick.Add(ctrl.ResolveHandler(name))),
        ),
    };
}
```

Base `View` setters (class, id, visibility, opacity, tooltip, cursor,
is-enabled, etc.) are inherited by all controls.

#### LayoutParamsParser

Each container declares a static parser for its LayoutParams. The markup
loader routes child attributes to the parent's parser:

```beef
public class FlexLayout : ViewGroup
{
    public static readonly LayoutParamsParser ParamsParser = .()
    {
        Create = => new FlexLayout.LayoutParams(),
        Properties = .(
            .("width",      .SizeSpec,   (lp, val) => lp.Width = val.AsSizeSpec),
            .("height",     .SizeSpec,   (lp, val) => lp.Height = val.AsSizeSpec),
            .("margin",     .Thickness,  (lp, val) => lp.Margin = val.AsThickness),
            .("grow",       .Float,      (lp, val) => ((FlexLayout.LayoutParams)lp).Grow = val.AsFloat),
            .("shrink",     .Float,      (lp, val) => ((FlexLayout.LayoutParams)lp).Shrink = val.AsFloat),
            .("align-self", .AlignEnum,  (lp, val) => ((FlexLayout.LayoutParams)lp).AlignSelf = val.AsAlign),
        ),
    };
}
```

Attribute routing: the loader checks the parent container's parser first.
If the attribute name matches a layout param, it routes there. Otherwise
it falls through to the child's own setter table.

#### XML parsing

Uses `Sedulous.Xml` (existing library, DOM-based parser). No custom XML
parser needed. The markup loader reads `XmlDocument` / `XmlElement` /
`XmlAttribute` types and walks the tree to construct the view hierarchy.

#### Controller pattern

Markup is loaded with a controller object that owns event handlers and
bindable data:

```beef
let controller = new PauseController();
let root = MarkupLoader.Load("pause.sml", context, controller);
```

Event attributes (`on-click="OnResume"`) resolve against the controller.
The controller implements `IMarkupController`:

```beef
interface IMarkupController
{
    delegate void(View) ResolveHandler(StringView methodName);
}
```

#### Data bindings (one-way, v1)

`text="{Title}"` binds a view property to a controller's `Property<T>`
field. The loader subscribes to `controller.Title.Changed` and updates
the view property. Bindings are live for the view's lifetime and disposed
on view destruction.

#### DataTemplate

```xml
<DataTemplate id="inventory-cell">
  <Frame width="64" height="64">
    <ImageView image="{Icon}" scale-type="fit-center"/>
    <Label text="{Count}" gravity="bottom-right" font-size="10"/>
  </Frame>
</DataTemplate>
```

Registered as a factory function. Adapters retrieve via
`loader.GetTemplate("inventory-cell")`.

#### Include

```xml
<Include source="hud-stats.sml"/>
```

Inlines another `.sml` file at parse time. Resolved relative to the
including file.

---

### Input & Focus

#### Event flow

Three-phase event propagation (HTML/CSS model), replacing v2's
bubble-only model:

1. **Capture:** event travels from root down toward the hit target.
   Each ancestor's capture handler is called in order. If any sets
   `Handled = true`, the event stops — it never reaches the target
   or the bubble phase.
2. **Target:** event fires on the target view.
3. **Bubble:** event travels from target back up to root. Each
   ancestor's bubble handler is called in order. `Handled = true`
   stops further bubbling.

Event args carry an `EventPhase` field (Capture, Target, Bubble) so
handlers know which phase they're in.

```beef
enum EventPhase { Capture, Target, Bubble }
```

**View virtual methods** gain capture counterparts:

```beef
/* Bubble (existing pattern) */
virtual void OnMouseDown(MouseEventArgs e)
virtual void OnKeyDown(KeyEventArgs e)

/* Capture (new) */
virtual void OnMouseDownCapture(MouseEventArgs e)
virtual void OnKeyDownCapture(KeyEventArgs e)
```

**Use cases for capture:**

- **Focus traps:** container intercepts Tab in capture phase, keeps
  focus within its subtree.
- **Disabled groups:** parent blocks all input to children by handling
  events in capture.
- **Event delegation:** parent handles events for many children
  efficiently (list/grid item clicks).
- **Modal blocking:** PopupLayer intercepts events in capture instead
  of relying on hit-test tricks.

**Mouse flow:**
hit-test -> capture (root -> target) -> target -> bubble (target -> root).
Mouse capture (SetCapture) overrides routing entirely — events go
directly to the captured view, no capture/bubble phases.

**Keyboard flow:**
capture (root -> focused view) -> focused view -> bubble (focused view
-> root) -> shortcut manager -> accelerator search.

**Event args:** pooled (MouseEventArgs, KeyEventArgs, TextInputEventArgs,
MouseWheelEventArgs). `Handled` flag stops propagation in any phase.
Coordinate translation applied per ancestor during both capture and
bubble for mouse events.

#### Directional focus (native, not retrofitted)

Built into the core from day one:

**FocusManager additions:**

```beef
enum FocusDirection { Up, Down, Left, Right }
bool MoveFocus(FocusDirection dir)
```

Spatial picker algorithm (Android FocusFinder-style): project focused
view's rect onto direction axis, score candidates by axial distance +
perpendicular penalty. `NextFocus{Dir}` override takes priority.

**Arrow key routing:** `InputManager.ProcessKeyDown` checks
`focusedView.WantsArrowKeys`. If false (default), arrows route to
`MoveFocus`. If true (EditText, NumericField), arrows go to the view's
`OnKeyDown`.

**View virtuals:**

```beef
virtual void OnActivate()   /* Gamepad A / Enter; ButtonBase -> FireClick */
virtual void OnCancel()     /* Gamepad B / Escape; bubbles to parent */
```

#### Gamepad input

`UIInputHelper` polls gamepad alongside mouse + keyboard:

```beef
let gamepad = shellInput.GetGamepad(0);
if (gamepad != null && gamepad.Connected)
    ProcessGamepadInput(gamepad, context, deltaTime);
```

- D-pad edges -> `ProcessFocusMove(direction)`
- Left stick with deadzone + repeat -> `ProcessFocusMove(direction)`
- A button -> `ProcessActivate()` on focused view
- B button -> `ProcessCancel()` on focused view
- `UIConsumedInput` flag set on shell input when UI has focus

---

### Controls

All v2 controls carry forward. The difference is consistent
`Property<T>` usage and markup setter tables from day one.

#### Property convention

Every control follows the same pattern:

```beef
public class Label : View
{
    public Property<String> Text = new .("") ~ delete _;
    public Property<float?> FontSize = new .(null) ~ delete _;
    public Property<Color?> TextColor = new .(null) ~ delete _;
    public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;
    public Property<bool> WordWrap = new .(false) ~ delete _;
    public Property<TextEllipsis> Ellipsis = new .(.None) ~ delete _;

    /* ... */

    public static readonly MarkupSetters Setters = .() { /* ... */ };
}
```

No public fields for settable state. No `Set*()` methods. `Property<T>`
is the one way.

Usage:
```beef
let label = new Label();
label.Text.Value = "Hello";
label.FontSize.Value = 18;
label.TextColor.Value = .(255, 100, 100);

/* Binding */
label.Text.BindTo(controller.Title);

/* Change notification */
label.Text.Changed.Add(new (text) => { Log(text); });
```

#### Composite controls and pseudo-elements

TabView, Slider, ScrollBar, ProgressBar, ToggleSwitch, Expander,
ComboBox, NumericField, CheckBox, RadioButton — all keep the
single-View custom-rendered model. Sub-parts are styled via
pseudo-element selectors using the generic property set:

```css
Slider::track  { background: rounded-rect($border, radius=2); height: 4; }
Slider::fill   { background: rounded-rect($primary, radius=2); }
Slider::thumb  { background: rounded-rect($text, radius=6); width: 12; height: 12; }

Slider:disabled::thumb { background: rounded-rect($text-dim, radius=6); }
```

Controls query sub-part styles via `ResolvePartDrawable("thumb", .Background, partState)`.
Each control computes per-part state internally (e.g., Slider knows if
the thumb is hovered/dragged) and passes it to the resolution method.

StyleProperty is a small generic set (~17 entries): Background,
TextColor, FontSize, Padding, Margin, CornerRadius, BorderColor,
BorderWidth, Width, Height, etc. No component-specific properties.

#### Control state overrides for checkable controls

With `Checked` in `ControlState`, checkable controls participate in the
normal state cascade:

```css
CheckBox:checked::checkmark { background: svg(checkmark, tint=$text); }
ToggleSwitch:checked::track { background: rounded-rect($primary, radius=8); }
ToggleButton:checked        { background: rounded-rect($primary, radius=6); }
```

No separate `CheckedBackground` property needed.

#### Control activate overrides

| Control | `OnActivate()` behavior |
|---|---|
| ButtonBase | `mIsPressed = true; FireClick(); mIsPressed = false` |
| CheckBox | Toggle `IsChecked` |
| RadioButton | Select |
| ToggleSwitch | Toggle |
| ToggleButton | Toggle |
| EditText | Fire `OnSubmit` |
| ComboBox | Open dropdown |
| Slider | No-op (left/right adjust value) |
| Expander | Toggle expanded |

---

### UIContext

Central coordinator. Same role as v2 with additions:

```beef
public class UIContext
{
    /* Registry */
    Dictionary<uint32, ViewHandle> mViewRegistry;  /* ViewId -> ViewHandle */
    Dictionary<String, ViewHandle> mNameRegistry;   /* Name -> ViewHandle, FindByName<T>() */

    /* Roots */
    List<RootView> mRootViews;

    /* Managers (owned) */
    InputManager InputManager;
    FocusManager FocusManager;          /* now with MoveFocus(direction) */
    DragDropManager DragDropManager;
    AnimationManager Animations;
    ShortcutManager Shortcuts;
    TooltipManager Tooltips;

    /* Style */
    StyleSheet StyleSheet;              /* primary, from .sss */
    List<StyleSheet> mStyleOverrides;   /* push/pop for dynamic overrides */

    /* Services */
    IClipboard Clipboard;
    IFontService FontService;
    ILocalizationService Localization;  /* new: @string:key resolution */

    /* Lifecycle */
    MutationQueue mMutationQueue;
    enum Phase { Idle, Layout, Drawing }
}
```

---

## Open decisions

| # | Question | Options | Leaning |
|---|---|---|---|
| 1 | Invalidation granularity | ~~A: per-property metadata; B: conservative~~ | **Resolved:** Default to re-measure; visual-only opt-out via `.Visual` tag. View base marks Opacity, Cursor, TooltipText. |
| 2 | Checked + hover compound state | ~~A: bit flags; B: primary + secondary; C: explicit variants~~ | **Resolved:** Bit flags (Beef enums are flags natively). `GetControlState()` returns compound flags like `.Checked \| .Hover`. StateListDrawable falls back from exact match to subsets. |
| 3 | Opacity in style inheritance | ~~Inherit through cascade vs compose at draw time only~~ | **Resolved:** Draw-time composition only. Not cascade-inherited. |
| 4 | `@palette extends` scope | ~~Palette inheritance~~ | **Resolved:** Yes. `@palette rounded extends dark { ... }` inherits parent tokens and overrides selectively. Needed for theme variants. |
| 5 | Event binding mechanism | ~~Beef `[Reflect]` vs `IMarkupController.ResolveHandler()`~~ | **Resolved:** Deferred. Events wired in code after `MarkupLoader.Load()` via `FindByName<T>()`. Controller pattern added later without breaking changes. |
| 6 | Per-control `MarkupSetters` verbosity | ~~Explicit tables vs `[Reflect]` codegen~~ | **Resolved:** Explicit tables. Codegen as later optimization if needed. |
| 7 | Two-way bindings | ~~v1 or deferred~~ | **Resolved:** Deferred. One-way sufficient for v1. |
| 8 | Hot reload | ~~v1 or deferred~~ | **Resolved:** Core supports clean teardown/reattach natively. `.sss` hot reload is just a stylesheet swap. `.sml` is destroy + rebuild. VFS already provides file watching. No special infrastructure needed — wire it up when themes phase lands. |

---

## Project structure

Developed as `Sedulous.GUI*` projects in the engine repo
(`SedulousEngine`), alongside the existing `Sedulous.UI*`. No fork
needed — the new namespace coexists cleanly.

### Projects

| Project | Purpose |
|---|---|
| `Sedulous.GUI` | Core framework (View, layout, styling, input, controls, overlay, animation) |
| `Sedulous.GUI.Shell` | Shell integration (GUIInputHelper, InputMapping, ShellClipboardAdapter) |
| `Sedulous.GUI.Runtime` | Engine runtime integration (GUISubsystem, VG rendering pipeline) |
| `Sedulous.GUI.Viewport` | ViewportView for 3D content in GUI |
| `Sedulous.GUI.Tests` | Framework tests |
| `GUISandbox` | Integration test app (under Samples/) |

### Source layout (Sedulous.GUI)

```
src/
  Core/           View, ViewGroup, RootView, ViewId, Property, UIContext, MutationQueue
  Layout/         BoxConstraints, SizeSpec, Unit, LayoutParams, Gravity,
                  FlexLayout, GridLayout, DockLayout, FrameLayout, AbsoluteLayout, FlowLayout
  Drawing/        UIDrawContext, ControlState, Drawable hierarchy (12 types), Palette, ThemeAtlas
  Styling/        StyleSheet, StyleRule, StyleSelector, StyleProperty, StyleValue, ThemePalette,
                  ThemeRegistry, IThemeExtension
  Styling/Parser/ StyleSheetLoader, Tokenizer, Parser, Ast, Values,
                  DrawableFactoryRegistry, ColorFunctions, UITypeRegistry
  Styling/Themes/ dark.sss, light.sss, rounded-dark.sss (embedded resources)
  Controls/       All ~31 controls with Property<T> + MarkupSetters
  Overlay/        PopupLayer, PopupEntry, ModalBackdrop, IPopupOwner, ContextMenu, Dialog,
                  TooltipManager, TooltipView
  Input/          InputManager, FocusManager, ShortcutManager, KeyCode, KeyModifiers,
                  MouseButton, event args
  DragDrop/       DragDropManager, DragData, DragAdorner, IDragSource, IDropTarget
  Editing/        TextEditingBehavior, ITextEditHost, UndoStack, InputFilter
  Animation/      Animation, AnimationManager, Easing, ViewAnimator, Storyboard
  Data/           IListAdapter, ViewRecycler, SelectionModel
  Markup/         MarkupLoader, MarkupRegistry, MarkupSetters, LayoutParamsParser,
                  MarkupValue, DataTemplate, ILocalizationService, BindingSubscription
```

---

## Phasing

Infrastructure first, then styling and markup early so controls are
built *with* their theme rules, markup setters, and integration tests
from the start. No monolithic "controls phase" — controls are added
incrementally once the infrastructure is in place.

### Infrastructure phases

| Phase | Scope | Depends on |
|---|---|---|
| **A: Core** | View, ViewGroup, RootView, Property<T>, ViewId, UIContext (with NameRegistry), MutationQueue, ControlState (flags), Visibility, ViewTransform, Thickness, CursorType, Orientation, IClipboard, ICommand | - |
| **B: Layout** | BoxConstraints, SizeSpec, Unit, LayoutParams, Gravity, GravityHelper, all 6 containers (Flex, Grid, Dock, Frame, Absolute, Flow) | A |
| **C: Drawing** | UIDrawContext, Drawable base + all 12 concrete types, Palette, ThemeAtlas | A |
| **D: Styling** | StyleSheet, StyleRule, StyleSelector (type + classes + state flags), StyleProperty, StyleValue, style resolution + inheritance (TextColor, FontSize, FontFamily, Cursor, TextAlign), UITypeRegistry, `.sss` tokenizer + parser + AST, StyleSheetLoader, drawable factory registry + built-in factories, color functions, @palette/@icon/@import directives, palette extends | A, C |
| **E: Markup** | MarkupLoader (using Sedulous.Xml), MarkupRegistry, MarkupSetters, LayoutParamsParser, MarkupValue, value parsers (shared with D), one-way data bindings, DataTemplate, Include, ILocalizationService | A, B, D |
| **F: Input** | InputManager, FocusManager (tab + directional + modal stack), ShortcutManager, DragDropManager, all event args, KeyCode, KeyModifiers, MouseButton, IAcceleratorHandler | A |
| **G: Animation** | Animation base + Float/Color/Vector2 animations, Storyboard, AnimationManager, ViewAnimator, Easing | A |
| **H: Shell** | GUISubsystem (was UISubsystem), GUIInputHelper (mouse + keyboard + gamepad), InputMapping, ShellClipboardAdapter | A, F |

Phases C, F, G are independent of each other and can proceed in
parallel. Phase E depends on D (value parsers, UITypeRegistry) and B
(LayoutParamsParser needs containers).

### Control phases (incremental)

Each control ships as a complete unit: Property<T> fields, MarkupSetters
table, LayoutParamsParser (if container), `.sss` theme entries in
dark.sss/light.sss, unit tests, and GUISandbox demo.

| Phase | Controls | Notes |
|---|---|---|
| **C1: Foundation** | Panel, Label, Spacer, Separator, ImageView, ColorView, DrawableView | Simplest views. Enough to test layout + styling + markup end-to-end. First `.sss` theme file (dark.sss, light.sss). First GUISandbox screen. |
| **C2: Buttons** | ButtonBase, Button, ContentButton, RepeatButton, ToggleButton | OnClick, Command, Pressed state. First interactive controls. |
| **C3: Selection** | CheckBox, RadioButton, RadioGroup, ToggleSwitch, Slider, ProgressBar | Checked state (flag composition). Value controls. |
| **C4: Input** | TextEditingBehavior, ITextEditHost, UndoStack, InputFilter, EditText, PasswordBox, NumericField, EditableLabel | Text editing infrastructure + controls. |
| **C5: Scrolling** | ScrollBar, ScrollView, MomentumHelper | Scrollable containers. |
| **C6: Selection containers** | ComboBox, TabView, Expander | Composite controls with popups / collapsible content. |
| **C7: Overlay** | PopupLayer, PopupEntry, ModalBackdrop, PopupPositioner, ContextMenu, Dialog, TooltipManager, TooltipView, IPopupOwner, ITooltipProvider | Overlay system + overlay controls. |
| **C8: Data** | IListAdapter, ITreeAdapter, FlattenedTreeAdapter, ViewRecycler, SelectionModel, HierarchicalState, ListView, GridView, TreeView | Virtualized data controls + adapter infrastructure. |
| **C9: Viewport** | ViewportView, IViewportInputHandler | 3D content in GUI. |

C1-C3 can proceed quickly (small controls, few dependencies). C4
depends on the text editing infrastructure. C5-C6 are independent of
each other. C7 depends on C5 (scroll in popups). C8 depends on C5
(scroll in lists). C9 is independent.

### Theme files

Built incrementally alongside controls:

| File | Grows during |
|---|---|
| `dark.sss` | C1 onward — each control adds its rules |
| `light.sss` | C1 onward |
| `rounded-dark.sss` | After dark.sss is stable; uses `@palette extends` |

---

## Not in v3 scope

- Toolkit controls (MenuBar, Toolbar, StatusBar, SplitView,
  BreadcrumbBar, ColorPicker, HDRColorPicker, DraggableTreeView,
  VectorFields, PropertyGrid, Docking). Separate phase after core
  framework stabilizes.
- Gamekit (Phase 14): HUD primitives, modal screens, dialogue,
  inventory, radial menus, floating numbers, localization
  implementation, world-space UI.
- CSS descendant/child combinators (v3.1)
- Pseudo-element syntax for composite controls (v3.1)
- Two-way data bindings (v3.1)
- Event binding in markup (v3.1 — wire events in code via FindByName
  for now)
- Hot reload (v3.1 — VFS already supports file watching)
- Touch input
- Accessibility
