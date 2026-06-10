# Sedulous.UI - Per-View Style Overrides

**Status:** Not started. Design only.

Adds two escape hatches to the styling system that v2 didn't ship:

- **Inline styles** - per-property overrides on a single `View`, the
  CSS `style="..."` analogue. Code-only for now (no markup attribute).
- **Local stylesheets** - a scoped `StyleSheet` reference on any
  `View`; the sheet applies to that view and its descendants, falling
  through to the next ancestor's local sheet or the context sheet.

These two tiers compose. Either can be used alone.

## Motivation

Today the only override path is a small set of typed fields on a few
controls (e.g. `ButtonBase.Background`, `Panel.Background`). They
cover one property each, only on specific controls, and need a new
field per property/control combination. There's no general way to:

- Set a single Label's font-size to 24 without subclassing or
  declaring a stylesheet class for it.
- Theme a Dialog and its subtree differently from the rest of the UI
  (e.g. a "compact" preview panel, an embedded mini-app, a tutorial
  overlay) without mutating the context-wide `StyleSheet`.

Both gaps are addressed here without touching the cascade or selector
model.

## Design

### Tier 1 - Inline styles

A view carries an optional sparse map of `StyleProperty -> StyleValue`
overrides. Any value present beats every rule-based match (inline is
specificity infinity, the same way CSS `style="..."` beats any
selector).

**API:**

```beef
view.SetInlineStyle(.TextColor, .Red);
view.SetInlineStyle(.FontSize, 24f);
view.SetInlineStyle(.Background, roundedDrawable);

view.GetInlineStyle(.TextColor);    // returns StyleValue (.None if unset)
view.HasInlineStyle(.TextColor);    // bool

view.ClearInlineStyle(.FontSize);
view.ClearInlineStyles();
```

Pseudo-element equivalents for composite controls:

```beef
view.SetInlinePartStyle("thumb", .Background, drawable);
view.ClearInlinePartStyle("thumb", .Background);
```

**Storage:** `View.InlineStyles: Dictionary<StyleProperty, StyleValue>`,
lazily allocated. `null` when no overrides set (the common case - one
pointer of overhead per view). Pseudo-element overrides live in a
secondary structure keyed by `(part, property)`, only allocated if
used.

**Ownership:** drawables stored as inline values need explicit
ownership semantics so they're not leaked. Mirror the `StyleSheet`
pattern:

```beef
view.OwnInlineDrawable(drawable);  // view deletes on destruction
```

Setting a non-owned drawable as an inline value is fine - the view
just holds the reference and doesn't delete. Callers manage the
drawable's lifetime themselves in that case (same contract as
`StyleSheet.AddRule(...).Set(prop, drawable)` without
`OwnDrawable(...)`).

**Resolution priority:** highest. Inline values are checked first and
returned if present. This means inline styles ignore selector
specificity entirely - they're the "I really mean this" hatch.

**State interaction:** inline values apply across all `ControlState`
values. If you want per-state overrides on one view, that's the
local-stylesheet path (Tier 2), not inline.

### Tier 2 - Local stylesheets

Any view can hold an optional `LocalStyleSheet` reference. When
resolving a property for a view, the cascade walks the ancestor chain
and consults the nearest ancestor's `LocalStyleSheet` first, falling
through to the context `StyleSheet` only if no local sheet in the
chain produced a match for the property.

**API:**

```beef
view.LocalStyleSheet = altSheet;   // RefCounted, view AddRefs
view.LocalStyleSheet = null;        // releases, falls back to context sheet
```

`LocalStyleSheet` is the same `StyleSheet` type used for context
sheets. Constructed the same way - imperatively, via `.sss` loading,
or both.

**Resolution algorithm:**

```
Resolve(view, prop):
    1. if view.InlineStyles contains prop:
           return view.InlineStyles[prop]

    2. walk ancestor chain (view, view.Parent, ..., RootView):
           if ancestor.LocalStyleSheet != null:
               result = ancestor.LocalStyleSheet.Resolve(view, prop)
               if result != .None:
                   return result

    3. result = context.StyleSheet.Resolve(view, prop)
       if result != .None:
           return result

    4. if StyleInheritance.IsInheritable(prop) and view.Parent != null:
           return Resolve(view.Parent, prop)

    5. return .None
```

**"Not found" semantics (per chosen option `a`):** at step 2, if an
ancestor's `LocalStyleSheet` exists but doesn't define `prop` for this
view, we **skip to the next ancestor** rather than stopping. Each
local sheet contributes only the properties it actually defines;
unmatched properties fall through. This matches CSS scoped-stylesheet
behavior and lets a Dialog's `LocalStyleSheet` override only what it
wants.

**Selector matching note:** the `view` passed to
`LocalStyleSheet.Resolve` is the original view being styled, not the
ancestor that owns the sheet. Selectors match the styled view's type,
classes, and state. The ancestor is just where we found the sheet to
consult.

**Inheritable property recursion (step 4):** when an inheritable
property (today: `TextColor`, `FontSize`) doesn't resolve on the
target view, we recurse from the parent through the entire algorithm
- including step 2's ancestor-chain walk. This means a `TextColor`
declared in a Dialog's `LocalStyleSheet` is correctly inherited by
descendant Labels that don't have their own `TextColor` rule.

**Pseudo-element resolution:** the same algorithm with one twist -
local sheets and inline-part overrides are consulted via
`ResolvePartStyle(view, part, prop)`. The ancestor-chain walk
unchanged; each sheet's `ResolvePart` is called instead of `Resolve`.

**Lifecycle:** `LocalStyleSheet` is `RefCounted`. The view `AddRefs`
on assignment, `Release`s on reassignment and on destruction.
Multiple views can share the same `LocalStyleSheet` instance safely.

### Migration of existing typed override fields

A small set of controls today carry a typed field for one property
(e.g. `ButtonBase.Background`, `Panel.Background`). These become thin
wrappers over `InlineStyles`:

```beef
public Drawable Background
{
    get => GetInlineStyle(.Background).AsDrawable;
    set => SetInlineStyle(.Background, .DrawableRef(value));
}
```

Existing call sites (`btn.Background = mySheet.OwnColor(.Red)`)
continue to work unchanged. The old per-control fields are unified
under the inline-style mechanism, and any other property can now be
overridden the same way.

Ownership transitions: `OwnInlineDrawable` becomes the new home for
"this view owns this drawable I just assigned." Callers that
previously assigned a stylesheet-owned drawable (`btn.Background =
sheet.OwnColor(...)`) stay correct - the sheet still owns it, the
view's `Background` is just a non-owned reference. Callers that
constructed a drawable inline (`new ColorDrawable(.Red)` without
sheet ownership) should call `view.OwnInlineDrawable(d)` after the
assignment.

## Sub-phases

| # | Sub-phase | Verifiable result |
|---|---|---|
| A | Inline styles (Tier 1) - data + API on `View`, no resolution wiring yet | Build clean. Unit tests for set/get/clear/has. |
| B | Inline-style resolution priority in `StyleSheet.Resolve` and pseudo-element resolvers | Inline overrides beat rule-based matches in tests. |
| C | `OwnInlineDrawable` + destruction cleanup | Tests: drawable freed when view destroyed; non-owned not freed. |
| D | Migrate typed `Background` fields on ButtonBase, Panel, etc. to wrap `InlineStyles` | Existing tests pass; no regressions in sandbox. |
| E | `LocalStyleSheet` on `View` - ref-counted property, lifecycle | Set/clear AddRef/Release tested. |
| F | Resolution algorithm: ancestor-chain walk + context fallback + inheritable recursion | Unit tests for the cases in the algorithm; tests cover (a) fall-through "not found", scoped overrides, inheritance through a local sheet. |
| G | Pseudo-element variant: `ResolvePartStyle` consults local sheets in the chain | Tests for `Slider::thumb` overridden via a `LocalStyleSheet` on an ancestor. |
| H | Sandbox demo - one screen using each feature | Visual confirmation; doc snippet. |

## Files to add / modify

**New (under `Code/Foundation/Sedulous.UI/src/Styling/`):**

- `InlineStyles.bf` - the per-view sparse override store + ownership
  list. Could live inside `View.bf` instead if the surface is small.

**Modified:**

- `View.bf` - add `InlineStyles` (lazy), `LocalStyleSheet`,
  `OwnInlineDrawable`, `Set/Get/Clear/HasInlineStyle` and pseudo-element
  variants. Wire cleanup in destructor.
- `StyleSheet.bf` - `Resolve(view, prop)` checks `view.InlineStyles`
  first, then walks ancestor chain for local sheets, then resolves
  against the context sheet. Same change for `ResolvePart` / partner
  resolvers.
- `ButtonBase.bf`, `Panel.bf`, any other control with a typed
  per-property override field - migrate to the `InlineStyles`-backed
  property pattern.
- `View.bf` resolver helpers (`ResolveStyleColor`, etc.) - already
  forward to `StyleSheet.Resolve`; no change needed there. They pick
  up the new behavior automatically.

## Tests

Add under `Code/Foundation/Sedulous.UI.Tests/src/`:

- `InlineStyleTests.bf`:
  - Set/Get/Clear/Has per property
  - Inline beats type selector
  - Inline beats class + state selector
  - Inline beats `:checked` and pseudo-element rule
  - Drawable ownership: owned drawable freed on view destruction;
    non-owned not freed
  - Clearing all styles releases dictionary

- `LocalStyleSheetTests.bf`:
  - Ancestor's local sheet wins over context sheet
  - Closer ancestor's local sheet wins over farther one
  - Local sheet "not found" falls through to next ancestor, then
    context (the (a) semantics)
  - Inheritable property declared in a local sheet on an ancestor
    correctly cascades into descendants
  - Pseudo-element resolved through a local sheet
  - RefCount: set/clear pairs; reassignment releases old sheet;
    destruction releases sheet

- Existing `StyleSheetTests` regression: confirm nothing breaks when
  no inline / local overrides are in play.

## Not in scope

- **Markup attribute for inline styles** (`<Button style="...">`).
  Code-only for v1 per scope. Adding it later is a small parser
  extension; the underlying API stays the same.
- **CSS descendant/child combinators.** Out of scope same as v2.
- **Inline style animation.** Setting an inline style is a one-shot
  write; animating it requires the existing `Animation` /
  `ViewAnimator` path, which already operates on view properties
  rather than the style cascade.
- **Local stylesheet hot-reload.** A `LocalStyleSheet` can be replaced
  at runtime (the ref-counted reference makes this cheap), but
  file-watcher integration for `.sss`-backed local sheets is a
  separate concern.
- **Multiple local sheets per view.** Only one `LocalStyleSheet` slot
  per view; if you need to layer two, compose them into one sheet at
  load time. Multi-slot layering could be added later if needed.
