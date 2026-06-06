# Session context: UI v2 evolution planning

You're continuing a planning session for the next-generation evolution of
Sedulous.UI. **No code has been written.** The deliverable so far is one
plan document. The natural next step is reviewing the remaining open
decisions before starting Phase 11 implementation.

## TL;DR

- **What:** Add a CSS-flavored stylesheet language (`.sss`), an XML
  markup language (`.sml`), and gamepad/directional focus to Sedulous.UI.
  Phases 11-13. Phase 14 (Gamekit) deliberately deferred.
- **Where:** All work happens in this fork repo
  (`C:\DEV\SedulousWorks\Repos\SedulousUI`), NOT in the engine repo
  (`C:\DEV\SedulousWorks\Repos\SedulousEngine`). Fork exists so existing
  consumers (editor, sandboxes, TowerDefense) keep working while v2
  evolves.
- **Plan doc:** `Documentation/Roadmap/UI_EVOLUTION.md` — read this
  before doing anything. It has the full decision matrix, sample
  syntaxes, sub-phases, file lists, open items.
- **Status:** Plan is mostly settled. Five items still open (listed
  below). Once those are resolved, start Phase 11A.

## Repo layout

- **Fork (this repo):** `C:\DEV\SedulousWorks\Repos\SedulousUI`
  - Standalone — full Sedulous foundation copied in (Core, RHI, Shell,
    Fonts, Images, VFS, VG, etc.) plus the UI projects:
    `Sedulous.UI`, `Sedulous.UI.Runtime`, `Sedulous.UI.Shell`,
    `Sedulous.UI.Tests`, `Sedulous.UI.Toolkit`, `Sedulous.UI.Viewport`
  - Sample: `Code/Samples/UI/UISandbox` — visual integration test
  - Roadmap: `Documentation/Roadmap/`
    - `UI_EVOLUTION.md` — the v2 plan (this session's work)
    - `UI2_PLAN.md` — Phases 0-10 (already COMPLETE — infrastructure,
      containers, themes, controls, text input, data controls, overlays,
      toolkit, runtime integration, app migration)
    - `UI2_DESIGN.md` — historical comparison vs the deprecated
      Sedulous.GUI

- **Engine repo (consumers, do NOT touch):**
  `C:\DEV\SedulousWorks\Repos\SedulousEngine`
  - Editor, EngineSandbox, AudioSandbox, ModelViewer, TowerDefense all
    depend on the engine repo's copy of Sedulous.UI. These consumers
    migrate to v2 only after the fork stabilizes — out of scope for the
    current plan.

## What was decided (and why it took several passes)

Original plan had `View.StyleId: String` → `View.StyleClasses: List<String>`.
Looked clean. The user asked "is StyleId really replaceable by StyleClasses?"
and an audit revealed `StyleId` is overloaded:

1. **Control-type tag (the dominant use):** every control constructor sets
   it — `Button` → `"button"`, `CheckBox` → `"checkbox"`, `EditText` →
   `"edittext"`, etc. ~15 sites under `Code/Foundation/Sedulous.UI/src/Controls/`
   and `Overlay/`.
2. **User variant (occasional):** generic `View` styled as a panel
   (`UISandboxApp.bf:205`), test fixtures setting `"primary"`, etc.

Themes lean on this string via `sheet.ForType(typeof(View), "button")` —
the `typeof(View)` being a wildcard. So the Beef type selector
(`StyleSelector.ViewType`) is declared but effectively unused even
though `IsSubtypeOf` matching is implemented and works.

**Revised plan (now in UI_EVOLUTION.md):**

- Drop `StyleId` entirely.
- Use Beef type via `StyleSelector.ViewType` for element selectors
  (`Button { ... }`). Subclasses match parents naturally.
- Add `View.StyleClasses: List<String>` for user classes
  (`.primary { ... }`).
- Themes change from `sheet.ForType(typeof(View), "button")` to
  `sheet.ForType(typeof(Button))`.
- Introduce `UITypeRegistry` (string -> Beef Type) for the `.sss`
  parser. **Shared with Phase 12's markup loader** — one source of
  truth for "what's the type for the string `Button`".

Similar discussion landed for **composite controls** (TabView, Slider,
ScrollBar, ProgressBar, etc.). User asked "how would tabs fit into
this?". The control is custom-rendered (no per-tab View instances), so
v1 keeps the existing flat bundled-property model:

```css
TabView {
  strip-drawable:          color($surface);
  active-tab-drawable:     rounded-rect($background, radius=4 4 0 0);
  inactive-tab-text-color: $text-dim;
  ...
}
```

CSS-style pseudo-elements (`TabView::tab`, `TabView::strip`) were
considered and **deferred to v2** as parser-side syntactic sugar.
Decomposing into real child Views was rejected — would lose the
single-View custom-rendered model's perf and locality.

## Open items (the user wants to resolve these before Phase 11A)

| # | Item | Status |
|---|---|---|
| 11.4 | `:checked` pseudo-state on `ControlState` (replaces `CheckedBackground` separate property pattern) | Needs go/no-go before 11A |
| 11.8 | `@palette my-theme extends parent { ... }` palette composition | Confirm scope before 11E |
| 12.4 | Per-control `MarkupSetters` table vs investigating Beef `[Reflect]` codegen | Confirm at 12D |
| 12.7 | Event binding: controller method names via reflection vs `IMarkupController` interface | Confirm at 12G |
| 13.3 | Arrow keys = focus move when focused view isn't a text editor (today they always go to focused view) | Confirm at 13C |

11.2 (the View identity model) is **resolved** — see the "Resolved
items" block at the bottom of UI_EVOLUTION.md.

## Phase order and shape (recap)

| Phase | Scope | Status |
|---|---|---|
| 11 | Stylesheet language `.sss`: parser, palette/icon/import directives, drawable factories, `StyleClasses` migration, theme migration. Sub-phases 11A-11G in plan doc. | Plan finalized except 5 open items |
| 12 | Markup language `.sml`: XML, setter tables, `Property<T>` normalization (sweeping breaking change), name registry, controller-based events, one-way bindings, DataTemplate, Include. Sub-phases 12A-12L. | Plan finalized except 12.4, 12.7 |
| 13 | Directional focus + gamepad: spatial picker, `OnActivate`/`OnCancel` virtuals, arrow-key rewire, SDL3 gamepad polling in `UIInputHelper`. Sub-phases 13A-13G. | Plan finalized except 13.3 |
| 14 | Sedulous.UI.Gamekit (HUD primitives, modal screens, dialogue, inventory, radial menus, world-space nameplates/floating numbers, localization). | **Not planned yet.** User chose to defer planning until 11-13 land. |

Each phase merges before the next starts. Sub-phases inside a phase
are discrete commits for bisectability.

## Survey findings worth keeping in mind

These came out of the initial audit and inform the plan; not all are
captured verbatim in UI_EVOLUTION.md.

- **Styling:** `StyleSheet` (RefCounted), `StyleRule`, `StyleSelector`
  (specificity: class=10, type=1, state=1), `StyleProperty` enum
  (~40 entries — drawables, colors, floats, thicknesses, bool), `StyleValue`
  (discriminated union). Only `TextColor` + `FontSize` inherit through
  parent chain. Drawables owned via `StyleSheet.OwnDrawable()`.
- **View / Layout:** `View` has auto-`ViewId Id`, `StyleId` (going away),
  `LayoutParams` (container-specific subclasses). `Property<T>` exists
  with `Changed` event but only used sporadically. `AddView` takes
  optional `LayoutParams`. `SizeSpec.Fixed(.Dp(n)) | .Match | .Wrap`.
  Properties set via mix of public fields, properties, and `Set*()`
  methods — uneven, which matters for Phase 12 markup attribute mapping.
- **Focus / Input:** Shell SDL3 has full gamepad incl. DPad — `IGamepad`,
  `GamepadButton.DPadUp/Down/Left/Right`. Engine.Input has gamepad
  bindings. **Zero of it reaches UI today.** `UIInputHelper.bf:76-94`
  polls mouse + keyboard only. `FocusManager` has Tab/Shift+Tab; no
  spatial picker.
- **Game UI patterns:** TowerDefense has the full set (HUDManager,
  TowerInfoPanel, MainMenuUI, PauseUI, GameOverUI) in
  `Code/Projects/TowerDefense/src/UI/` (in the engine repo). World-space
  UI (`UIComponent` + `WorldUIPass`) is production-ready including
  billboard modes + raycast input. Missing primitives for Gamekit:
  AnimatedMeter, FloatingText/DamageNumber, ItemSlot/Hotbar, RadialMenu,
  Cooldown overlay, Compass/Waypoint, Typewriter Label, Nameplate
  scaffold. `ViewAnimator` covers fade/translate/scale/rotate.

## How to work with this user

These are durable preferences captured in auto-memory; reapply on resume:

- **Discuss before changing.** When the user says "let's discuss" or
  asks a question, default to discussion. Don't dive into edits. They
  caught me jumping the gun once in this session.
- **Architectural changes: present root cause + options.** The user
  debugs methodically and wants to make the call. Don't pre-decide.
- **Thorough survey first** for cross-cutting "we don't have enough X"
  asks — audit the whole subsystem before scoping or editing.
- **Breaking changes are OK** if the result is a better framework.
  Explicitly green-lit for this UI v2 evolution.
- **Preserve comments** during refactors. Code comments AND
  doc/roadmap background. Annotate status; don't strip context.
- **Page layout (editor concern):** lay out each editor page
  individually following the scene-editor convention. No shared layout
  abstraction. (Carries over here if any editor screens get touched.)
- **Git workflow:** commit messages scoped to exactly what's staged;
  keep independent fixes in separate commits.
- **No emojis** in files or chat unless explicitly requested.

## Beef language quirks that have bitten in this codebase

- **Reserved identifiers** (`extension`, `ref`, etc.) need `@` prefix
  when used as parameter / variable names. Codebase already uses
  `@extension`, `@ref` etc.
- **String/StringView on attributes** used to crash the compiler; fixed
  for `String`. Don't use `= default` on attribute fields.
- **Reflection is opt-in** via `[Reflect]` attribute — design Phase 12's
  markup setter tables to NOT require reflection by default.
- **BeefBuild test targeting:** `BeefBuild -project=X -test`. Use the
  on-path `BeefBuild.exe`, not `C:\DEV\Beef\...`. (Not strictly relevant
  here yet — no tests written this session.)

## Files referenced in the plan but not yet created

These exist in the plan doc only:

**Phase 11 new files (under `Code/Foundation/Sedulous.UI/src/Styling/Parser/`):**
`StyleSheetLoader.bf`, `Tokenizer.bf`, `Parser.bf`, `Ast.bf`,
`Values.bf`, `DrawableFactoryRegistry.bf`, `ColorFunctions.bf`,
`UITypeRegistry.bf`. Plus embedded `Themes/dark.sss`, `light.sss`,
`rounded-dark.sss`. Toolkit gets `Themes/toolkit.sss`.

**Phase 11 modified files:** `View.bf`, `StyleSelector.bf`,
`ControlState.bf`, every control's constructor under `Controls/` and
`Overlay/`, all theme `.bf` files, UISandbox + tests.

Phase 12 and 13 file lists are in the plan doc.

## Resuming on the new system: first actions

1. **Read `Documentation/Roadmap/UI_EVOLUTION.md`** end to end. It's the
   canonical plan; this file is just orientation.
2. **Skim `Documentation/Roadmap/UI2_PLAN.md`** through Phase 10 to know
   what's already shipped (don't replan what exists).
3. **Resolve the 5 open items** with the user (11.4, 11.8, 12.4, 12.7,
   13.3). They're listed in the "Open items" section at the bottom of
   UI_EVOLUTION.md with revisit guidance.
4. **Then create Phase 11A tasks** and start. 11A is the
   `StyleId` -> `StyleClasses` + Beef-type selectors + `UITypeRegistry`
   migration. Concrete steps in UI_EVOLUTION.md under "View / cascade
   changes (breaking) -> Concrete deltas".
