# Sedulous.UI - Evolution Plan (v2)

> **STATUS: SHIPPED.** Preserved as the historical **planning record**.
> The work landed in engine master as 8 discrete changes; framing,
> scope, and a few of the details diverged from this plan. For the
> canonical "what shipped" summary, see [UIV3.md](UIV3.md). For the
> roadmap-style COMPLETE entries that fit the existing UI2_PLAN format,
> see the "v2 Evolution" section appended to [UI2_PLAN.md](UI2_PLAN.md).

Next-generation evolution of Sedulous.UI focused on making the framework
ergonomic for **game UIs** and **designer iteration**. Continues the phase
numbering from `UI2_PLAN.md` (which covers Phases 0-10).

## Why this is happening in a fork

Sedulous.UI is in production use across the editor, TowerDefense,
EngineSandbox, AudioSandbox, and ModelViewer. The changes in this plan are
**deliberately breaking**:

- `View.StyleId: String` becomes `View.StyleClasses: List<String>`
- Many control properties migrate from public fields / `Set*()` methods to
  `Property<T>`
- The styling, markup, and focus APIs grow new surface area

A sweeping in-place migration would block every consumer. Instead, the work
happens in the **`SedulousUI` repo** as a standalone fork. Consumers stay
on the stable `SedulousEngine` copy of Sedulous.UI until the fork
stabilizes; migration is then a single, well-defined sweep per consumer.

## Goals

The framework today is solid for editor/tools UI but rough for game UI:

- **Themes are hand-coded in Beef.** Designers can't iterate visuals
  without recompiling. There is no text format for stylesheets even though
  the underlying StyleSheet/StyleRule/StyleSelector model already supports
  a CSS-style cascade.
- **Every screen is code.** No markup loader means every menu, HUD, and
  dialog is a `new FlexLayout(); flex.AddView(...)` tree. Game UIs have
  many screens; iteration is slow.
- **No gamepad path.** Platform SDL3 has full gamepad including DPad and
  buttons, but `UIInputHelper` polls only mouse + keyboard. `FocusManager`
  has Tab/Shift+Tab; no directional focus. UIs cannot ship to console.
- **Game UI primitives are reinvented per app.** TowerDefense has full
  HUD/menu/dialog UIs (`Code/Projects/TowerDefense/src/UI/`) but they're
  app-specific. Common patterns (animated meters, floating damage numbers,
  modal screens, item slots) deserve to be library code. This work is
  scoped as Phase 14 (Gamekit), tracked separately from this plan.

This evolution covers Phases 11-13. Phase 14 (Gamekit) will be planned
once 11-13 land.

---

## Phase 11 - Stylesheet Language (`.sss`)

A CSS-flavored text format for declaring themes. The model behind it
(`StyleSheet`, `StyleRule`, `StyleSelector`, `StyleProperty`, `StyleValue`)
already exists and is used by the cascade resolver. Phase 11 adds the
parser and a small set of supporting features around it.

### Sample

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

Panel {
  background: color($surface);
  padding:    8;
}

Label.hint        { text-color: $text-dim; font-size: 11; }
Label.title       { font-size: 18; }

Button {
  background:   rounded-rect($surface, radius=6, border=$border, border-width=1);
  padding:      6 12;
}
Button:hover    { background: rounded-rect(lighten($surface, 8%), radius=6); }
Button:pressed  { background: rounded-rect(darken($surface, 8%), radius=6); }
Button:disabled { text-color: $text-dim; }

Button.primary       { background: rounded-rect($primary, radius=6); text-color: white; }
Button.primary:hover { background: rounded-rect(lighten($primary, 8%), radius=6); }

EditText {
  background:        rounded-rect($background, radius=4, border=$border, border-width=1);
  padding:           4 6;
  placeholder-color: $text-dim;
  cursor-color:      $primary;
}
EditText:focused { border-color: $primary; }

CheckBox {
  checkmark-icon: svg(checkmark, tint=$text);
  box-size:       16;
}

Slider {
  track-drawable: rounded-rect($border, radius=2);
  fill-drawable:  rounded-rect($primary, radius=2);
  thumb-drawable: rounded-rect($text, radius=6);
  thumb-size:     12;
  track-height:   4;
}

Dialog {
  background: rounded-rect($surface, radius=8, border=$border, border-width=1);
  padding:    16;
}
```

### Design decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 11.1 | File extension | `.sss` | Distinct from CSS so the parser can diverge cleanly |
| 11.2 | View identity model | **Drop `StyleId` entirely.** Type selectors match Beef type via `StyleSelector.ViewType`. Class selectors match against new `StyleClasses: List<String>`. (**breaking**) | Today `StyleId` is overloaded as both control-type tag (set in every constructor: `StyleId = "button"`) and user variant. Splitting into Beef-type + user-class list matches the CSS mental model and removes the string-tag bookkeeping. |
| 11.3 | Descendant/child combinators | Not in v1 | Current `StyleSelector` is flat; combinators require a tree-walk match pass |
| 11.4 | Pseudo-state `:checked` | Add to `ControlState` | Today ToggleButton/CheckBox use separate `CheckedBackground` property |
| 11.5 | Drawable factory syntax | `rounded-rect($bg, radius=6, border=$x)` with keyword args | Readable, scales to per-corner radii |
| 11.6 | State-list syntax | `state-list(normal=..., hover=..., pressed=...)` function | Symmetric with other factories |
| 11.7 | Palette variables | `$name`, resolved at parse from `@palette` block | One block per file; later block wins |
| 11.8 | Palette composition | `@palette my-theme extends dark { ... }` | Lets RoundedDark override drawable shapes without re-declaring colors |
| 11.9 | Comments | `/* */` only | Keeps tokenizer simple; `//` ambiguous with URLs |
| 11.10 | `@import` paths | Relative to importing file | Predictable |
| 11.11 | Theme distribution | Embedded resources for v1 | Existing icons already use embedded; disk-loaded + hot-reload is 11.5 follow-up |
| 11.12 | `inherit` keyword | Not in v1 | Stick with current TextColor/FontSize inheritance set |
| 11.13 | Unknown property | Parse error, not warning | Catches typos at load time |
| 11.14 | Cascade specificity | Keep current model (class=10, type=1, state=1) | Already proven |

### Selectors v1

| Form | Example | Specificity |
|---|---|---|
| Type | `Label` | 1 |
| State | `:hover` | 1 |
| Class | `.hint` | 10 |
| Multi-class | `.primary.destructive` | 20 |
| Type + state | `EditText:focused` | 2 |
| Type + class | `Panel.surface` | 11 |
| Type + class + state | `Button.primary:hover` | 12 |
| Multiple classes + state | `.primary.destructive:hover` | 21 |

Any registered view type works as an element selector — `Button`,
`Label`, `EditText`, `CheckBox`, `Slider`, `Panel`, `Dialog`, custom user
controls, anything in the `UITypeRegistry`. Subclasses match their
parent's selectors via `IsSubtypeOf` (so `MyFancyButton : Button` is
caught by `Button { ... }` rules).

`ControlState` set: `:normal`, `:hover`, `:pressed`, `:focused`, `:disabled`,
`:checked` (new in 11.4).

### Composite controls (TabView, Slider, ScrollBar, etc.)

Some controls have a fixed multi-part visual structure that is drawn as
a single rendered View rather than composed of child Views. Today these
expose styling as bundled named properties on the control's selector:

```css
TabView {
  strip-drawable:          color($surface);
  content-drawable:        color($background);
  active-tab-drawable:     rounded-rect($background, radius=4 4 0 0);
  hover-tab-drawable:      color(lighten($surface, 5%));
  inactive-tab-text-color: $text-dim;
  active-tab-text-color:   $text;
  close-icon:              svg(close, tint=$text-dim);
  accent-color:            $primary;
  header-height:           28;
}

Slider {
  track-drawable: rounded-rect($border, radius=2);
  fill-drawable:  rounded-rect($primary, radius=2);
  thumb-drawable: rounded-rect($text, radius=6);
  thumb-size:     12;
  track-height:   4;
}
```

Each named property is an entry in the `StyleProperty` enum (e.g.
`StripDrawable`, `ActiveTabDrawable`, `TrackDrawable`, `ThumbSize`). The
control reads them at draw time. v1 keeps this model verbatim — no
architectural change to TabView/Slider/etc.

**Two alternatives were considered and rejected for v1:**

1. **Decompose into real child views** (Tab views inside a TabStrip
   inside TabView). Cleaner CSS but costlier — per-tab View allocation,
   layout, hit-test, and the tab-drag / close-on-middle-click /
   placement-aware corner masking logic would have to be redistributed.
   The current single-View custom-rendered model is more compact.

2. **CSS-style pseudo-elements** (`TabView::tab`, `TabView::strip`,
   `TabView::close`). Syntactic sugar that rewrites at parse time to the
   existing flat properties (`TabView::tab background` becomes
   `TabView active-tab-drawable`). Cheap to add — each composite
   declares its pseudo-element name -> flat property mapping. **Deferred
   to v2** as a quality-of-life improvement once the v1 parser is
   stable. The flat-property syntax above ships first.

Composite controls that fit this pattern in the current codebase:
TabView, Slider, ScrollBar, ProgressBar, ToggleSwitch, Expander,
ComboBox (dropdown chrome), NumericField (spin buttons), CheckBox + box
+ checkmark icon, RadioButton + box + mark icon.

Composite controls that already decompose into child views (so v1 just
styles each child by its own type selector): ContextMenu items,
Dialog (title bar + content + button row are layout-driven), TabView
content area (the active tab's content is whatever View was added).

### Drawable factories (built-in registry)

| Factory | Produces | Notes |
|---|---|---|
| `color(rgba)` | `ColorDrawable` | Implicit when a property declared as Drawable receives a color literal |
| `rounded-rect(color, radius?, border?, border-width?)` | `RoundedRectDrawable` | Per-corner via `radius=tl,tr,br,bl` |
| `gradient(direction, stop1, stop2, ...)` | `GradientDrawable` | Direction: top-to-bottom, etc. |
| `nine-slice(image, slices, tint?)` | `NineSliceDrawable` | Slices: `4 4 4 4` |
| `image(path, scale-type?, tint?)` | `ImageDrawable` | |
| `svg(name, tint?)` | `SVGDrawable` | Resolves `name` against `@icon` registry |
| `state-list(normal=..., hover=..., ...)` | `StateListDrawable` | Each value is itself a drawable factory call or color |
| `layer(d1, d2, ...)` | `LayerDrawable` | Stacked draw |
| `inset(d, top, right, bottom, left)` | `InsetDrawable` | |

User-extensible: `DrawableFactoryRegistry.Register("custom-name", fn)`.

### Value types

| Style property type | Stylesheet syntax |
|---|---|
| Color | `#rrggbb`, `#rrggbbaa`, `rgb(r,g,b)`, `rgba(r,g,b,a)`, named (`white`, `black`, `transparent`) |
| Float | `13`, `0.5` (unitless) |
| Thickness | `8` (all sides), `8 12` (vert, horz), `8 12 8 12` (top, right, bottom, left) |
| SizeSpec | Phase 11 doesn't use SizeSpec values; Phase 12 does. Syntax defined there. |
| Drawable | A factory call, or a color literal (auto-wraps as `color()`), or a `$variable` |
| Bool | `true`, `false` |
| Unit (in numeric values) | `13px`, `8dp`, `12pt`; unitless = dp |

### Color functions

| Function | Result |
|---|---|
| `lighten($color, 10%)` | Lighter shade by HSL L |
| `darken($color, 10%)` | Darker shade by HSL L |
| `alpha($color, 0.5)` | Set alpha channel |
| `mix($a, $b, 0.5)` | Linear blend |

### Top-level directives

- `@palette name { ... }` - defines a named palette
- `@palette name extends parent { ... }` - palette inheriting another's variables
- `@icon name "path"` - registers an SVG by name for `svg(name)` references
- `@import "path.sss"` - inlines another stylesheet (resolved relative)
- `@font name "path"` - font registration (deferred to v1.5 if not needed for theme migration)

### View / cascade changes (breaking)

#### `StyleId` is removed; replaced by Beef type + `StyleClasses`

Today `View.StyleId: String` is overloaded as both a control-type
discriminator (every control's constructor sets it: `ButtonBase` →
`"button"`, `CheckBox` → `"checkbox"`, etc.) and a user variant tag
(`settingsPanel.StyleId = "panel"`). Themes match against the string
via the wildcard pattern `sheet.ForType(typeof(View), "button")` —
which means the Beef type selector (`StyleSelector.ViewType`) is
declared but effectively unused.

The new model splits these cleanly along CSS lines:

| CSS concept | New `StyleSelector` field | Set how |
|---|---|---|
| Element selector (`Button { ... }`) | `ViewType: Type` — matches via `view.GetType().IsSubtypeOf(ViewType)` | Implicit: every view has a Beef type |
| Class selector (`.primary { ... }`) | `StyleClasses: List<String>` — selector matches if **all** its classes are on the view | User-set via `view.StyleClasses.Add("primary")` |

Subclasses match their parent's type selector naturally — a
`MyFancyButton : Button` is styled by `Button { ... }` rules via
`IsSubtypeOf`, exactly like CSS.

#### Concrete deltas

- `View.StyleId: String` → **deleted**
- `View.StyleClasses: List<String>` → **added**, with helpers `AddClass(name)`,
  `RemoveClass(name)`, `HasClass(name)`, `SetClasses(params name[])`
- Every control's constructor: remove `StyleId = new String("button")` etc.
  (~15 sites — Button, CheckBox, EditText, ComboBox, TreeView, etc.)
- `StyleSelector.StyleClass: String` → `StyleClasses: List<String>`
- `StyleSelector.Matches(view, state)`: subset-match every class in
  `StyleClasses` against `view.StyleClasses`
- Theme code: `sheet.ForType(typeof(View), "button")` →
  `sheet.ForType(typeof(Button))`
- User-class sites: `panel.StyleId = "panel"` → `panel.StyleClasses.Add("panel")`
  (UISandboxApp.bf:205 + tests)
- Tests asserting `view.StyleId != null` (the "constructor set the tag"
  smoke test): remove — Beef-type matching makes them meaningless

#### Specificity update

Each declared class contributes 10 to the selector's specificity. Type
matches contribute 1. State matches contribute 1. So `Button.primary` =
1 + 10 = 11; `.primary.destructive:hover` = 10 + 10 + 1 = 21.

#### Type-name registry (shared with Phase 12)

The `.sss` parser sees strings like `Button { ... }` and needs to map
them to `typeof(Button)`. Phase 11 introduces a
`UITypeRegistry` keyed by short name → `Type`. Built-in controls
auto-register at static init; user controls register theirs alongside.
**This registry is shared with Phase 12's markup loader**, which needs
the same string→Type lookup for element resolution. One source of
truth.

### Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| 11A | Drop `StyleId`; add `StyleClasses` + Beef-type selectors + `UITypeRegistry` | Build clean. Themes rewritten to `ForType(typeof(Button))`; constructor `StyleId` sets removed; sandbox + tests updated. Visual parity. |
| 11B | Value parsers (Color, Unit, Thickness, SizeSpec, bool, float) | Standalone unit tests; no integration yet |
| 11C | Tokenizer + parser + AST | Round-trips representative `.sss` files to AST; parser error messages cite source positions |
| 11D | Drawable factory registry + built-in factories | Each factory builds a real drawable when called by the loader |
| 11E | `StyleSheetLoader.Load(path, palette?) -> StyleSheet` | Loads a `.sss` file end-to-end, including `@palette`, `@icon`, `@import` |
| 11F | Migrate Dark/Light/RoundedDark/Toolkit themes to `.sss` | UISandbox renders identically; F5 theme cycling works |
| 11G | UI tests + sandbox parity | All existing UI tests pass; UISandbox renders match |

### Files

**New (under `Code/Foundation/Sedulous.UI/src/Styling/Parser/`):**

- `StyleSheetLoader.bf` - entry point
- `Tokenizer.bf`
- `Parser.bf`
- `Ast.bf`
- `Values.bf` - color/unit/thickness/sizespec parsers (reused by Phase 12)
- `DrawableFactoryRegistry.bf`
- `ColorFunctions.bf` - lighten/darken/alpha/mix
- `UITypeRegistry.bf` - string -> Beef Type for `.sss` element selectors
  (shared with Phase 12 markup loader)
- `Themes/dark.sss`, `light.sss`, `rounded-dark.sss` (embedded resources)

**New (under `Code/Foundation/Sedulous.UI.Toolkit/`):**

- `Themes/toolkit.sss` (embedded)

**Modified:**

- `View.bf` - delete `StyleId`; add `StyleClasses: List<String>` with
  `AddClass`/`RemoveClass`/`HasClass`/`SetClasses` helpers
- `StyleSelector.bf` - replace `StyleClass: String` with
  `StyleClasses: List<String>`; subset-match
- `ControlState.bf` - add `Checked`
- Every control under `Controls/` and `Overlay/` - remove the
  `StyleId = new String("...")` constructor line (Button, CheckBox,
  RadioButton, EditText, ComboBox, Dialog, TooltipView, TreeView,
  ListView, GridView, TabView, ProgressBar, Slider, ToggleSwitch,
  ContextMenu, NumericField, Expander, Separator, etc.)
- `DarkTheme.bf`, `LightTheme.bf`, `RoundedDarkTheme.bf`,
  `ToolkitThemeExtension.bf` - thin wrappers over `StyleSheetLoader.Load`;
  intermediate rewrite of `ForType(typeof(View), "x")` to `ForType(typeof(X))`
  before the .sss migration
- All controls that read `CheckedBackground` - migrate to `:checked`
  state pattern
- UISandbox + tests - `view.StyleId = "x"` becomes `view.StyleClasses.Add("x")`;
  remove `StyleId != null` smoke-test assertions

### Not in Phase 11

- `Property<T>` normalization (Phase 12)
- Markup loader (Phase 12)
- Hot-reload (Phase 11.5 follow-up if needed)
- Stylesheet authoring tools / linters
- CSS-style descendant or child combinators

---

## Phase 12 - Markup Language (`.sml`)

XML-based declarative layout. Element names map to View types; attributes
map to per-control properties and per-container `LayoutParams`. Children
elements become children of the parent View.

### Sample

```xml
<Flex direction="vertical" justify="center" align="stretch" padding="16" spacing="8">
  <Label id="title" text="@string:pause-title" font-size="24" align="center"/>

  <Button id="resume-btn" class="primary" width="240" height="40" on-click="OnResume">
    Resume
  </Button>

  <Button id="quit-btn" class="destructive" width="240" height="40" on-click="OnQuit">
    Quit to Main Menu
  </Button>

  <Spacer height="match" grow="1"/>

  <Label class="hint" text="ESC to resume"/>
</Flex>
```

DataTemplate for adapters:

```xml
<DataTemplate id="inventory-cell" type="ItemViewModel">
  <Frame width="64" height="64">
    <ImageView image="{Icon}" scale-type="fit-center"/>
    <Label text="{Count}" gravity="bottom-right" font-size="10"/>
  </Frame>
</DataTemplate>
```

### Design decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 12.1 | File extension | `.sml` | Pairs with `.sss`; reads as "structure" (markup language) |
| 12.2 | Format | XML | Matches Phase 10 roadmap; tooling-friendly; maps cleanly to View tree |
| 12.3 | Namespaces | `<Button>` builtins, `<myapp:Custom>` for user types | Default namespace = `Sedulous.UI`; user namespaces explicit |
| 12.4 | Property setter binding | Explicit `static MarkupSetters` table per control | Beef reflection opt-in and limited; explicit is codegen-able later |
| 12.5 | `Property<T>` normalization | Sweeping change, **breaking** | Markup setters become uniform; reactive bindings trivial |
| 12.6 | `id` attribute | Name registry on `UIContext` separate from `ViewId` | Additive; `ViewId` keeps its runtime role |
| 12.7 | Event handlers | Method name resolved against a controller object passed at load | Matches WPF/UIKit pattern; clean separation |
| 12.8 | Data bindings | `text="{Title}"` - one-way only for v1 | Sufficient for game UI; two-way later via `Property<T>` |
| 12.9 | `<DataTemplate>` for ListView/TreeView/GridView | Yes in v1 | Adapters otherwise still need code; win deflates without it |
| 12.10 | `<Include source="..."/>` | Yes in v1 | Enables reuse of HUD/footer snippets across screens |
| 12.11 | Hot reload | Not in v1 | Watcher pattern is small but needs deletion/reattach story |
| 12.12 | Localization | `text="@string:key"` resolved via `ILocalizationService` on `UIContext` | Indirection in Phase 12; default impl in Phase 14 |

### Setter table pattern

Each markup-targetable control declares a static setter table:

```beef
public static class Button
{
  public static readonly MarkupSetters MarkupSetters = .()
  {
    Properties = .(
      .("text",      MarkupValueKind.String,  (v, val) => (v as Button).Text.Value = val.AsString),
      .("font-size", MarkupValueKind.Float,   (v, val) => (v as Button).FontSize.Value = val.AsFloat),
      .("class",     MarkupValueKind.Classes, (v, val) => (v as Button).StyleClasses.AddRange(val.AsClasses)),
    ),
    Events = .(
      .("on-click",  (v, target, methodName) => (v as Button).OnClick.Add(ResolveHandler(target, methodName))),
    ),
  };
}
```

Verbose per control but explicit, no reflection. ~10-30 lines per control;
a Beef code generator could derive these from `[Reflect]` attributes
later.

### Container layout-params handling

When the parser sees a child element inside a container, it asks the
container for its `LayoutParamsParser`:

```beef
public static class FlexLayout
{
  public static readonly LayoutParamsParser LayoutParamsParser = .()
  {
    Create = => new FlexLayout.LayoutParams(),
    Properties = .(
      .("width",      MarkupValueKind.SizeSpec, (lp, val) => (lp as FlexLayout.LayoutParams).Width = val.AsSizeSpec),
      .("height",     MarkupValueKind.SizeSpec, (lp, val) => (lp as FlexLayout.LayoutParams).Height = val.AsSizeSpec),
      .("margin",     MarkupValueKind.Thickness,(lp, val) => (lp as FlexLayout.LayoutParams).Margin = val.AsThickness),
      .("grow",       MarkupValueKind.Float,    (lp, val) => (lp as FlexLayout.LayoutParams).Grow = val.AsFloat),
      .("shrink",     MarkupValueKind.Float,    (lp, val) => (lp as FlexLayout.LayoutParams).Shrink = val.AsFloat),
      .("align-self", MarkupValueKind.AlignEnum,(lp, val) => (lp as FlexLayout.LayoutParams).AlignSelf = val.AsAlign),
      .("gravity",    MarkupValueKind.Gravity,  (lp, val) => (lp as FlexLayout.LayoutParams).Gravity = val.AsGravity),
    ),
  };
}
```

Layout attributes on a child element route to the parent's
`LayoutParamsParser`; everything else routes to the child's own
`MarkupSetters`.

### Property<T> normalization (breaking)

Markup attribute setters operate on uniform `Property<T>` access. Controls
need to expose stylable/markup-targetable fields as `Property<T>`:

| Control | Old | New |
|---|---|---|
| `Label` | `mText` + `SetText` | `Text: Property<String>` |
| `Label` | `FontSize: float?` (field) | `FontSize: Property<float?>` |
| `Label` | `TextColor: Color?` (field) | `TextColor: Property<Color?>` |
| `Button` | `mText` + `SetText` | `Text: Property<String>` |
| `EditText` | `SetText`, `SetPlaceholder` | `Text: Property<String>`, `Placeholder: Property<String>` |
| `CheckBox` | `IsChecked: bool` | `IsChecked: Property<bool>` |
| ... | ... | ... |

This is a single sweeping commit done **before** the markup loader. Audit
all controls in `Code/Foundation/Sedulous.UI/src/Controls/` and Toolkit.
Mechanical change — every `btn.SetText("foo")` becomes
`btn.Text.Value = "foo"`.

### Name registry

`UIContext` gains `NameRegistry: Dictionary<String, View>`. Markup loader
populates from `id` attributes. Lookup API: `context.FindByName<T>(name)`.
Separate from `ViewId` (auto-allocated integer; remains for runtime
references).

### Event binding

A markup load takes a controller object (any class type). Event
attributes resolve a method name against the controller:

```beef
let controller = new PauseController();
let root = MarkupLoader.Load("pause.sml", context, controller);
// on-click="OnResume" -> finds controller.OnResume method
```

Method resolution is the one place Beef reflection is needed - or we
require the controller to implement `IMarkupController` with a
`ResolveHandler(name: String): Action<View>` method.

### Data bindings (v1: one-way)

`text="{Title}"` binds Label.Text to a controller property named `Title`.
The controller exposes properties as `Property<T>` fields; the markup
loader subscribes to `Title.Changed` and updates `Text.Value`.

Bindings stay live for the lifetime of the View. Loader collects all
binding subscriptions and disposes them when the view is destroyed.

### `<DataTemplate>` for adapters

```xml
<DataTemplate id="inventory-cell" type="ItemViewModel">
  ...
</DataTemplate>
```

`DataTemplate` registers a factory function with the loader's template
registry. Adapters retrieve it via `loader.GetTemplate("inventory-cell")`
and use it to build per-item views with per-item bindings.

### `<Include>`

```xml
<Include source="hud-stats.sml"/>
```

Inlines another `.sml` file at parse time. Resolved relative to the
including file. No template / parameter substitution in v1.

### Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| 12A | `Property<T>` normalization across all controls | All controls compile + existing tests pass; sandbox identical |
| 12B | `UIContext.NameRegistry` + `FindByName<T>` | Manual registration test |
| 12C | `MarkupRegistry`, `MarkupSetters`, `LayoutParamsParser` infrastructure | Type registration round-trips |
| 12D | Per-control setter tables for built-ins | Every Sedulous.UI control has setter table |
| 12E | Tokenizer / XML parser / element resolution | Parses sample `.sml` to View tree (literal attributes only) |
| 12F | Attribute value parsing (uses Phase 11B parsers) | Width/Margin/Color attributes work |
| 12G | Event binding via controller | `on-click` fires registered handler |
| 12H | One-way data bindings (`{Property}`) | Binding updates view when controller's property changes |
| 12I | `<DataTemplate>` + adapter integration | Sandbox ListView uses XML template |
| 12J | `<Include>` | Sandbox composes screens from snippets |
| 12K | `ILocalizationService` indirection (no default impl) | `@string:foo` resolves through service; falls back to key if none |
| 12L | UISandbox: at least one screen converted to `.sml` | Visual + functional parity with code version |

### Files

**New (under `Code/Foundation/Sedulous.UI/src/Markup/`):**

- `MarkupLoader.bf` - entry point
- `MarkupRegistry.bf`
- `MarkupSetters.bf`
- `LayoutParamsParser.bf`
- `MarkupValueKind.bf` - enum of attribute value kinds
- `MarkupValue.bf` - discriminated union over parsed attribute values
- `IMarkupController.bf` (or use Beef reflection if available)
- `DataTemplate.bf`
- `ILocalizationService.bf`
- `BindingSubscription.bf`

**Modified:**

- Every control under `Controls/` - add `Property<T>` for stylable fields,
  add `static MarkupSetters MarkupSetters`
- Every container under `Layout/` - add `static LayoutParamsParser LayoutParamsParser`
- `View.bf` - add `RegisterName` / `Name` (for `id` attribute)
- `UIContext.bf` - add `NameRegistry`, `FindByName<T>`,
  `LocalizationService` slot
- UISandbox - convert one screen to `.sml` as integration test

### Not in Phase 12

- Two-way data bindings
- Expression bindings (`{!IsValid}`)
- Hot reload (12.5 follow-up)
- Localization service implementation (Phase 14)
- Markup-side styling (`style="..."` inline) - use `class=` and `.sss`

---

## Phase 13 - Directional Focus + Gamepad

Wire SDL3 gamepad input into the UI focus system and add directional
focus navigation so consoles ship.

### Background

Survey of the current state:

- **Platform (SDL3) gamepad input is complete.** `IGamepad` interface,
  `GamepadButton` enum including `DPadUp/Down/Left/Right`, axes, polling.
  Lives under `Code/Foundation/Sedulous.Platform/src/Input/` and
  `Code/Foundation/Sedulous.Platform.SDL3/`.
- **UI input bridge is keyboard + mouse only.** `UIInputHelper` (under
  `Code/Foundation/Sedulous.UI.Platform/`) polls `platformInput.Mouse` and
  `platformInput.Keyboard`. Gamepad is not polled.
- **FocusManager is Tab-only.** `FocusNext` / `FocusPrev` walk the focus
  tree in tab-index order. No directional picker.
- **View has focus state.** `IsFocusable`, `IsTabStop`, `TabIndex`,
  `OnFocusGained`, `OnFocusLost`, `IsFocused`.

### Design decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 13.1 | Spatial picker algorithm | Android FocusFinder-style: project rect onto direction-axis, score by axial distance + perpendicular penalty | Proven; handles non-aligned UIs |
| 13.2 | Per-view explicit override | `NextFocusUp/Down/Left/Right: ViewId?` | Cheap escape hatch when picker chooses wrong |
| 13.3 | Arrow keys = focus-move when focused view isn't a text editor | Yes; EditText opts out via `WantsArrowKeys = true` | Console UIs need this |
| 13.4 | Gamepad A | `OnActivate()` virtual on View; default no-op; ButtonBase overrides to fire OnClick | Standard console A-button semantics |
| 13.5 | Gamepad B | `OnCancel()` virtual; bubbles up | Modal/Dialog handles to close |
| 13.6 | Left stick as alternate D-pad | Yes; configurable deadzone + repeat rate | Trivial once D-pad path exists |
| 13.7 | Button layout | Xbox layout hardcoded v1 (A=Activate, B=Cancel) | Rebinding is a Gamekit feature |
| 13.8 | UI traps gamepad input when focused | `UIInputHelper` sets `UIConsumedInput` flag on platform input | Already a placeholder slot |

### Wiring summary

**1. View additions (`View.bf`):**

- `NextFocusUp/Down/Left/Right: ViewId?`
- `WantsArrowKeys: bool` (default false; EditText/NumericField override to true)
- `OnActivate()` virtual - default no-op
- `OnCancel()` virtual - bubbles to parent unless handled

**2. FocusManager additions:**

```beef
public enum FocusDirection { Up, Down, Left, Right }
public bool MoveFocus(FocusDirection dir)
```

Algorithm: enumerate all focusable views; for each, compute whether it
sits in `dir` from the current focused view's center; score = axial
distance + perpendicular distance penalty; honor `NextFocus{Dir}`
override first.

**3. InputManager additions:**

- `ProcessFocusMove(FocusDirection dir)` - calls `FocusManager.MoveFocus`
- `ProcessActivate()` - calls `OnActivate` on focused view, bubbling
- `ProcessCancel()` - calls `OnCancel` on focused view, bubbling

Arrow-key dispatch in `ProcessKeyDown` checks the focused view's
`WantsArrowKeys`. If false (the typical case), arrows route to
`ProcessFocusMove`. If true (EditText), arrows route to the focused
view's `OnKeyDown` as today.

**4. UIInputHelper additions:**

```beef
let gamepad = platformInput.GetGamepad(0);
if (gamepad != null && gamepad.Connected)
  ProcessGamepadInput(gamepad, context, deltaTime);
```

Polls D-pad button-pressed edges; maps to `ProcessFocusMove`. Polls left
stick X/Y; with deadzone + repeat timer, also maps to `ProcessFocusMove`.
Maps A button to `ProcessActivate`, B to `ProcessCancel`.

When a focusable view exists, sets `UIConsumedInput = true` on platform
input so game-side input contexts know to skip those events.

**5. Control activate overrides:**

- `ButtonBase.OnActivate` -> `mIsPressed = true; FireClick(); mIsPressed = false`
- `EditText.OnActivate` -> fire `OnSubmit`
- `CheckBox.OnActivate` -> `IsChecked = !IsChecked`
- `Slider.OnActivate` -> no-op (use left/right for value change)
- `ComboBox.OnActivate` -> open dropdown
- `RadioButton.OnActivate` -> select
- `ToggleSwitch.OnActivate` -> toggle

### Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| 13A | `View.NextFocus*` + `WantsArrowKeys` + `OnActivate`/`OnCancel` | Sandbox unchanged; new fields available |
| 13B | `FocusManager.MoveFocus(direction)` + spatial picker | Unit tests with synthetic view layouts |
| 13C | `InputManager.ProcessFocusMove/Activate/Cancel` + arrow-key rewire | Tab still works; arrow keys now move focus on non-text controls |
| 13D | Control `OnActivate` overrides | Enter on focused Button fires click |
| 13E | `UIInputHelper.ProcessGamepadInput` (D-pad + buttons) | UISandbox navigable with gamepad |
| 13F | Left stick navigation with deadzone + repeat | Stick navigation matches D-pad UX |
| 13G | `UIConsumedInput` platform flag wiring | Game-side input contexts skip events when UI consumes |

### Files

**Modified:**

- `Code/Foundation/Sedulous.UI/src/Core/View.bf`
- `Code/Foundation/Sedulous.UI/src/Input/FocusManager.bf`
- `Code/Foundation/Sedulous.UI/src/Input/InputManager.bf`
- `Code/Foundation/Sedulous.UI.Platform/src/UIInputHelper.bf`
- Per-control `OnActivate` overrides

**New:**

- `Code/Foundation/Sedulous.UI/src/Input/FocusDirection.bf`
- `Code/Foundation/Sedulous.UI/src/Input/SpatialFocusPicker.bf`

### Not in Phase 13

- Button rebinding UI (Gamekit / Phase 14)
- Action map for game controls (Gamekit / Phase 14)
- Touch input (separate phase)
- Per-context input maps (engine-side, not UI)

---

## Cross-cutting decisions

| # | Decision | Choice |
|---|---|---|
| X.1 | Phase order | 11 -> 12 -> 13 |
| X.2 | Phase isolation | Each phase a discrete commit boundary (bisectable) |
| X.3 | Tests | New unit tests per phase under `Sedulous.UI.Tests` |
| X.4 | UISandbox migration | Each phase extends the sandbox to exercise its new feature |
| X.5 | Roadmap maintenance | Mark sub-phases COMPLETE in this doc as they land |
| X.6 | Migration of engine repo consumers | Out of scope; planned separately once fork stabilizes |

## Resolved items

- **11.2 (View identity model).** Originally framed as "rename `StyleId`
  to `StyleClasses`". Revised after auditing actual usage: `StyleId` is
  overloaded (control-type tag set in every constructor + occasional user
  variant). Resolution: drop `StyleId` entirely, use Beef type via
  `StyleSelector.ViewType` for type selectors, add `StyleClasses` for
  user classes. Introduces shared `UITypeRegistry` (string -> Type) used
  by both Phase 11 parser and Phase 12 markup loader.

## Open items

Items I'm least sure about and want to revisit before/during the phases:

- **11.4 (`:checked` pseudo-state).** Adds a `Checked` value to
  `ControlState`. Today checked state is encoded by reading the
  `CheckedBackground` style property instead of `Background`. Switching
  to `:checked` is cleaner but every checkable control needs migration.
  Confirm before 11A.
- **11.8 (palette extends).** Useful for RoundedDark to override drawable
  shapes without re-declaring colors. Implementation: at parse time,
  resolve `extends parent` by cloning parent's variable table, then
  layering child's declarations on top. Variable references are
  flattened at the @palette boundary, not deferred. Confirm scope before
  11E.
- **12.4 (no-reflection setter tables).** Verbose per-control. Could
  investigate Beef `[Reflect]` codegen instead. Verbose-but-explicit is
  the v1 default; investigate codegen if it becomes onerous in 12D.
- **12.7 (event binding via controller method names).** Needs Beef
  reflection or an `IMarkupController` interface. Confirm at 12G.
- **13.3 (arrow-keys = focus-move on non-text controls).** Changes
  current behavior - today arrow keys go to the focused view always.
  Mitigation: `WantsArrowKeys` opt-in for text-edit controls. Confirm at
  13C.
