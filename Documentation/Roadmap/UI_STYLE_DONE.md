# Sedulous.UI - Per-View Style Overrides

**Status:** Shipped 2026-06-10. Tier 1 (inline styles) + Tier 2
(local stylesheets) + the orchestrator-style resolution algorithm
all live. The plan also wound up driving a `Drawable : RefCounted`
refactor (sub-phases D.1-D.5) that the original design didn't
anticipate.

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

### Tier 1 - Inline styles *(shipped)*

A view carries an optional internal `StyleSheet`. Any value set on it
beats every rule-based match from the context sheet (inline is
specificity infinity, the same way CSS `style="..."` beats any
selector).

**Public API:**

```beef
panel.SetStyle(.Background, new ColorDrawable(.Red));  // consumes ref
panel.SetStyle(.TextColor, .Red);
panel.SetStyle(.FontSize, 24f);

view.GetInlineStyle(.TextColor);  // returns StyleValue (.None if unset)
view.HasInlineStyle(.TextColor);  // bool
view.ClearInlineStyle(.FontSize);
view.ClearInlineStyles();
```

Typed `SetStyle` overloads mirror `StyleRule.Set` (Color / float /
Thickness / bool / Drawable). The Drawable overload exposes a
`consumeRef: bool = true` flag - default consumes the caller's
ref (the typical one-liner pattern); pass `consumeRef: false` when
the caller wants to keep its own ref on a shared drawable.

Pseudo-element equivalents for composite controls:

```beef
slider.SetPartStyle("thumb", .Background, new ColorDrawable(.Blue));
view.GetInlinePartStyle("thumb", .Background);
view.ClearInlinePartStyle("thumb", .Background);
```

**Storage:** `View.mInlineSheet : StyleSheet` (lazy, RefCounted). A view
with no inline overrides pays one pointer of overhead. The inline
sheet hosts:

- One rule with an empty `StyleSelector` for element-level overrides
  (matches the owning view unconditionally).
- One rule per pseudo-element name, with `Selector.SetPseudoElement(part)`.

All refcount management for `DrawableRef` values reuses `StyleRule.Set`
/ `StyleRule.Remove` from the styling subsystem - the View doesn't
duplicate it. Overwriting a rule's `DrawableRef` releases the previous
drawable; clearing the rule does the same; the sheet's destruction
releases everything it owns. View destructor is one line:
`mInlineSheet?.ReleaseRef()`.

**Drawable : RefCounted:** the inline-style work required uniform
ownership across rule/sheet/view boundaries. Sub-phase D.1 made
`Drawable` inherit `RefCounted`. Child-holding subclasses
(`InsetDrawable`, `LayerDrawable`, `StateListDrawable`) consume the
caller's ref in their constructors / `Add` / `Set` methods and Release
on destruction. `StyleSheet.OwnDrawable(d, consumeRef = true)` and
`StyleRule.Set(prop, d, consumeRef = false)` both expose the
`consumeRef` flag - defaults match each method's typical call pattern
(rule call sites overwhelmingly do `Set(prop, sheet.OwnColor(...))`;
view call sites overwhelmingly do `SetStyle(prop, new ...)`).

**Resolution priority:** highest. `StyleSheet.Resolve` and `ResolvePart`
both consult `view.InlineSheet` first (with `walkInheritance: false`
to keep inline values from leaking across ancestor boundaries) before
walking their own rules. Re-entry guard via `inlineSheet !== this`
prevents infinite recursion when called on the inline sheet itself.

**State interaction:** inline values apply across all `ControlState`
values - the inline sheet's element rule has an empty selector with
no state constraint. If you want per-state overrides on one view,
that's the local-stylesheet path (Tier 2), not inline.

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

### Migration of existing typed override fields *(shipped)*

`ButtonBase.Background`, `Panel.Background`, and
`ToggleButton.CheckedBackground` were removed entirely. Drawing code
collapsed: `Panel.OnDraw` and `ButtonBase.DrawButtonBackground` now
read via `ResolveStyleDrawable(.Background)` only (inline overrides +
theme rules both flow through the same resolver). `ToggleButton.OnDraw`
restructured similarly with `.CheckedBackground` checked first.

~50 call sites across editor pages, sandbox, and TowerDefense were
migrated from `panel.Background = new ColorDrawable(...)` to
`panel.SetStyle(.Background, new ColorDrawable(...))` via bulk sed.
`HUDManager.UpdateSpeedButtons` dropped its manual
`?.ReleaseRef()`-then-reassign dance - `SetStyle`'s overwrite-release
handles the refcount internally.

## Sub-phases

| # | Sub-phase | Status | Result |
|---|---|---|---|
| A | Inline-style data + API on `View` (no resolution wiring) | ✅ shipped | Lazy Dictionary + List storage with set/get/clear/has. Replaced in D.3 - kept the public API. |
| B | Inline-style resolution priority in `StyleSheet.Resolve` / `ResolvePart` | ✅ shipped | Inline overrides beat every rule match. |
| C | `OwnInlineDrawable` + view-owned drawable cleanup | ✅ shipped, then removed | Initially added to manage drawable lifetimes; subsumed by D.1 refcount and removed in D.3. |
| D | Migrate typed `Background` / `CheckedBackground` fields to the inline-style API | ✅ shipped (expanded to D.1-D.5) | Required a `Drawable : RefCounted` refactor that wasn't in the original plan. |
| &nbsp;&nbsp;D.1 | `Drawable : RefCounted` + child-owning subclasses + test scope-site migration | ✅ shipped | 717/717 UI tests green. |
| &nbsp;&nbsp;D.2 | `StyleRule` + `StyleSheet` refcount wiring; `consumeRef` flag on both | ✅ shipped | `Set` AddRefs by default; `OwnDrawable` consumes by default. |
| &nbsp;&nbsp;D.3 | `View.SetStyle` overloads + inline-style storage migrated to internal `StyleSheet` | ✅ shipped | Dictionary replaced with `mInlineSheet`. All refcount mgmt reuses `StyleRule.Set` / `Remove`. |
| &nbsp;&nbsp;D.4 | Drop typed `Background` / `CheckedBackground` fields; migrate ~50 call sites | ✅ shipped | Workspace clean. |
| &nbsp;&nbsp;D.5 | Doc updates + build/test sanity | ✅ shipped | This file. Interactive sandbox/editor visual verification deferred to the user. |
| E | `LocalStyleSheet` on `View` - ref-counted property, lifecycle | ✅ shipped | Mirrors `UIContext.StyleSheet`: no-op identical assign, AddRef new + Release old, destructor releases. |
| F | Resolution algorithm: ancestor-chain walk + context fallback + inheritable recursion | ✅ shipped | `View.ResolveStyle` is the orchestrator; `StyleSheet.Resolve` shrank to per-sheet primitive. |
| G | Pseudo-element variant: `ResolvePartStyle` consults local sheets in the chain | ✅ shipped | Same orchestrator pattern; no inheritance recursion for pseudo-elements. |
| H | Sandbox demo - one screen using each feature | ✅ shipped | UISandbox "Pause (.sml)" tab: inline styles on title + resume/quit buttons, plus a `LocalStyleSheet` on the pause root that scopes Label/Button defaults to the subtree. |

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
