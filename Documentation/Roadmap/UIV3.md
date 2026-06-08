# Sedulous UI - Evolution Summary

Evolution of the Sedulous UI framework. Originally developed as
`Sedulous.GUI*` alongside `Sedulous.UI*`, then ported back to
`Sedulous.UI` after stabilization.

## Completed Changes

All 8 planned changes have been implemented, tested, and ported back.

### 1. ControlState as bit flags

Changed `ControlState` from a flat enum to bit flags for compound
states (e.g., `Checked | Hover`). `StateListDrawable` uses flag-based
lookup with fallback. Checkable controls return `.Checked` from
`GetControlState()`.

### 2. StyleClasses (multi-class support)

Replaced single `StyleId: String` with `StyleClasses: List<String>`.
Theme rules use type-based selectors (`ForType(typeof(Slider))`) instead
of string matching. Controls no longer set a StyleId in constructors.
Specificity: class=10, type=1, state=1, pseudo=1.

### 3. Capture-phase events

Added HTML/CSS three-phase event propagation: Capture (root to target),
Target, Bubble (target to root). `EventPhase` enum on all event args.
View gains capture virtuals (`OnMouseDownCapture`, `OnKeyDownCapture`,
etc.). Mouse capture bypasses phases entirely.

### 4. Directional focus + gamepad

`View` gains `NextFocusUp/Down/Left/Right`, `WantsArrowKeys`,
`OnActivate()`, `OnCancel()`. `FocusManager.MoveFocus(FocusDirection)`
with spatial picker (axial + perpendicular scoring). Arrow keys dispatch
to focused view first, fall back to directional navigation. Gamepad
polling in `UIInputHelper` (D-pad, A/B buttons, left stick with deadzone
and repeat).

### 5. .sss stylesheet parser

CSS-flavored text format for declaring themes. Tokenizer, parser,
`StyleSheetLoader`, drawable factory registry (color, rounded-rect,
gradient, state-list, state-colors, state-rounded, layer, inset, svg,
image, nine-slice), color functions (lighten, darken, alpha, mix),
`@palette` with extends, `@icon`, `@image`, `@import` directives.
Breeze theme authored in .sss.

### 6. .sml markup loader

XML-based declarative layout using `Sedulous.Xml`. `MarkupRegistry`
(factory + setter pattern), `MarkupLoader` walks DOM, supports all
built-in controls and layouts. Special attributes: id, class, visibility,
is-enabled, opacity, padding, cursor, tooltip. Events wired in code via
`FindByName<T>()` after load.

### 7. Property\<T> normalization

Markup-settable properties use `Property<T>` with `IPropertyOwner`
auto-invalidation. Code-only properties remain as plain fields.
`Property<T>` has `SetOwner()`, `InvalidationKind` (.Layout/.Visual),
`Changed` event, `SetSilent()`, `BindTo()`/`BindTwoWay()`.

### 8. Pseudo-element styling

Replaced ~35 flat `StyleProperty` entries with pseudo-element selectors.
`StyleProperty` enum reduced from ~48 to 17 entries. 10 controls
migrated (Slider, ProgressBar, ScrollBar, ToggleSwitch, CheckBox,
RadioButton, TabView, Expander, NumericField, ComboBox) with ~25
pseudo-element parts. TreeView, ContextMenu also migrated. All 5 theme
files updated. `.sss` supports `::pseudo` and `::pseudo:state` syntax.

## Deferred

### ViewHandle

Safe reference indirection layer. Not needed — v2 already handles
use-after-free via `ViewId` + `MutationQueue`.

## Not in scope

- CSS descendant/child combinators
- Touch input
- Accessibility
- Gamekit (HUD primitives, modal screens, dialogue, inventory,
  radial menus, floating numbers, localization, world-space UI)
