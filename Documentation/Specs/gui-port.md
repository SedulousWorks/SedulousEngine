# Porting Raptor's GUI

> Status: APPROVED (user rulings 2026-10-23, below)
> Source: `RaptorCode/` (bc86ece2), copied from Raptor `vg` 4fe177db2 on master 287ddc135

## What

Raptor's `foundation.gui` is a retained-mode GUI, designed area by area from a survey of eepp,
RmlUi, Godot and browsers. It is built on VG for drawing, Fonts for text and Core's reflection
for scripts. Around it sit eleven satellite libraries, the engine's GUI (Engine.GUI), its cook
(GUI.Pipeline), the editor's pages for its assets (Editor.GUI), a sandbox sample and the script
integration tests. That is about 130k lines of C++ and tests in 33 projects. It comes to
Sedulous as `Foundation/Sedulous.GUI.*` and its engine, pipeline and editor siblings.

Sedulous.UI stays. Raptor keeps foundation.ui (its port of Sedulous.UI) beside foundation.gui
until the games, samples and editor have moved onto the new GUI. Sedulous does the same, so
nothing that uses Sedulous.UI changes during the port.

## Method: port and strike

The C++ is committed in `RaptorCode/` (see its README). Each port commit:

- adds the Beef code with its tests;
- deletes from `RaptorCode/`, in the same commit, exactly the C++ it ported, so a review sees the
  C++ removed beside the Beef added and can check it for correctness and completeness;
- leaves what it did not port where it is. A file ported in part keeps the rest; the Beef may say
  "still in RaptorCode/...".

What remains in `RaptorCode/` is what is left to port. At the end, anything left is either still
to do or left out on purpose, with the reason written in `RaptorCode/README.md`.

- **A test is ported with the code it tests.** A Raptor test that needs a later slice waits for it
  in the ledger. Every port gets a mutation check (restored from a backup copy, never with
  `git checkout`), ASan through `Tools/asan-test.py`, and a run after removing the test project's
  build directory.
- **The hunks** (`RaptorCode/Hunks/<path>.diff`, the GUI's changes to files outside its projects)
  are struck hunk by hunk as each one lands in its Sedulous file. **A CMakeLists.txt** is struck
  when its project's BeefProj.toml lands, which is the moment its dependency list has been carried
  over.
- **Commits**: one per slice (user ruling): each commit is a slice that compiles with its tests
  passing. The subject is `GUI: ...` (or the satellite's area, `GUI.Docking: ...`), the body says
  why and ends with "Struck from RaptorCode (Raptor vg 4fe177db2)." No trailers.
- **Raptor moving on.** The user has parked Raptor's GUI work, so the ledger should hold still. If
  Raptor changes a file not yet ported, copy that file into the ledger again. A change to a file
  already ported is ported as a normal sync commit.
- **The build lane.** Ask gameengine-80 for it before every build, as for every other build.

## Projects

| Raptor | Sedulous | Namespace |
|---|---|---|
| `Foundation/GUI` (`foundation.gui`) | `Foundation/Sedulous.GUI` | `Sedulous.GUI` |
| `Foundation/GUI.<Name>` | `Foundation/Sedulous.GUI.<Name>` | Raptor's: `Sedulous.GUI` for the satellites in `foundation::gui`, `Sedulous.GUI.VFS` and `Sedulous.GUI.Inspector` for `gui::vfs` and `gui::inspector` |
| `Engine/Engine.GUI` | `Engine/Sedulous.Engine.GUI` | `Sedulous.Engine.GUI` |
| `Pipeline/GUI.Pipeline` | `Pipeline/Sedulous.GUI.Pipeline` | `Sedulous.GUI.Pipeline` |
| `Editor/Editor.GUI` | `Editor/Sedulous.Editor.GUI` | `Sedulous.Editor.GUI` |
| `Samples/GUISandbox` | `Samples/Samples.GUISandbox` | `Samples.GUISandbox` |
| `Integration/Integration.GuiScript` | `Integration/Sedulous.Integration.GuiScript` | |

Each gets its sibling `.Tests` project, as the Raptor projects do. `GUI.Fuzz.Tests` becomes
`Sedulous.GUI.Fuzz.Tests`: its fuzz targets run as ordinary tests over the seed and crash files.
Raptor's optional libFuzzer build is left out.

No `Sedulous.GUI` name exists yet. About 80 type names are shared with Sedulous.UI (`Button`,
`Label`, `Thickness`, `MarkupLoader`, ...). They live in different namespaces, so only a file
that uses both libraries (the player, DefaultApp, the editor) has to qualify them.

## Order

Projects go in dependency order. Inside a project, a slice may use only what is already ported.

1. **Sedulous.GUI.Resources**: the cooked `.xml` document and `.css` sheet, stored as validated
   text. It has no GUI dependency, so it can go first or at any time.
2. **Sedulous.GUI, the core** (48k lines, 28k of tests), in 19 slices. Each slice imports only
   from slices before it:

   | # | Slice | Lines | First tests that need no later slice |
   |---|---|---|---|
   | S1 | Geometry and primitives: Rect, Thickness, Transform2D, Transformable, Diagnostic, ParseUtil, MutationQueue, FrameStats, DebugOverlay, Clipboard, Theme, RangeValue | 1152 | Rect, Transform2D, Transformable, Compositor |
   | S2 | Reactive data: Reactive, Commands, DataModel | 725 | Reactive |
   | S3 | Style values: LayoutStyle, CSSValues, StyleValue, Easing, Motion, StyleProperties, StyleInterpolation | 3715 | Calc, Easing |
   | S4 | Events and actions: ModelIndex, Event, Action, ActionManager, Actions, Keymap, MediaQuery, PopupPlacement | 2331 | |
   | S5 | Models: Variant, Model, StringListModel, ListModel, TableModel, TreeModel, SortingProxyModel | 1480 | Model |
   | S6 | Drawing and resources: ResourceProvider, PictureBaker, DrawContext, Drawable, ImageDrawable, SvgDrawable, NodeBox | 1310 | ImageDrawable |
   | S7 | Text and editing models: TextSegmentation, TextRuns, TextLayout, Text, UndoStack, InputFilter, TextEditModel, TextEditingKeys | 3739 | BidiText, Editing, TextEditModel, TextRuns, Text |
   | S8 | Node and layout: Node, ElementTypes, LayoutImpl, ActionManagerImpl | 4890 | Node, NodeDraw |
   | S9 | Widget base: UINode, UIWidget, Navigation, Accessibility (its interface) | 1256 | NamedEvent |
   | S10 | Selectors and sheets: StyleSelector, StyleRule, StyleSheet, CSSParser, StyleCheck | 2656 | CSSParser, StyleSheet |
   | S11 | Dispatcher and root: EventDispatcher, SceneRoot, GuiScript, GUIClusterImpl, DebugOverlayImpl | 4342 | Damage, Service, Widget, DebugOverlay |
   | S12 | Style engine: StyleApplier, StyleAnimation, Tween, StyleManager, TweenImpl | 3926 | Action, BoxStyle, CssCascade, Culling, Effects, Enter, Keyframes, MediaQuery, StyleCore |
   | S13 | Simple widgets: Label, Image, Panel, Separator, Splitter, ScrollView, Tooltip, Disclosure, RangeWidget, Slider, ProgressBar, ScrollBar, DragPreview, ListBox | 2643 | 19 test files (fonts, overflow, scroll, slider, tween, ...) |
   | S14 | Buttons: ButtonBase, Button, CheckBox, Radio, ToggleSwitch, Expander | 1138 | 14 (routing, scene root, navigation, layout engine, ...) |
   | S15 | Popups, windows, tabs: Menu, MenuBar, ComboBox, Window, MessageBox, TabBar, TabView, Toast | 4492 | 7 |
   | S16 | Text widgets: TextEditBase, TextField, TextArea, NumberField, EditableLabel, ColorPicker | 2448 | 9 |
   | S17 | Markup: MarkupLoader | 395 | 17 (markup, elements, translation, menus, tabs, ...) |
   | S18 | Item views and accessibility: ItemView, ListView, TableView, TreeView, AccessibilityImpl | 3638 | 11 |
   | S19 | What is left of GUIReflectionImpl and GUIModule | 1737 | |

   Raptor's subfolders depend on each other in a loop (Node uses style values, the style engine
   uses Node). The C++ breaks the loop by moving method bodies into `.cpp` files that see the whole
   module. A Beef project compiles all its files together, so it has no such loop to break. A body
   that needs a later slice (Node's routing needs SceneRoot, its tweens need Tween) is ported with
   that slice, as an `extension Node` in a file beside it, mirroring the `.cpp` it came from. Until
   then the method is not there, and nothing that calls it is ported yet.

   `GUIReflectionImpl.cpp` holds every class's reflection block. **Each block is ported with its
   class**, not saved for S19, so a widget arrives whole. S19 is what remains: the registration
   functions, the `gui` script facade and the module's list of everything.
3. **Satellites that need only the core**: GUI.Shell (the input bridge), GUI.Code (the code
   editor), GUI.Gamekit, GUI.Toolkit, GUI.Inspector, GUI.VFS.
4. **GUI.Hosting** (needs GUI.Shell) and **GUI.Testing** (needs GUI.Inspector).
5. **GUI.Docking** and **GUI.Viewport** (they need Hosting), and **GUI.Fuzz.Tests** (needs Testing).
6. **Sedulous.Engine.GUI** with the engine hunks (composition, DefaultApp, player, project
   settings), and **Sedulous.GUI.Pipeline** with the registration hunk.
7. **Sedulous.Editor.GUI** with the editor hunks, **Integration.GuiScript**, and
   **Samples.GUISandbox** with its image tests. The WebScene hunk lands here as well.

## Translating the C++

These follow what the Xml and VG ports already did. Beef's way wins over the C++ idiom.

- **Allocators.** `MemoryAllocator()`, `IAllocator&` parameters and allocator-taking containers go:
  Beef allocates with `new`. `Foundation::Policy` is a CMake target only (no source imports it),
  so it is not ported.
- **Ownership.** The node tree is reference counted (`RefPtr<Node>`, 684 uses). Nodes become
  corlib `RefCounted`, as Sedulous.UI's `View` already is, with the parent holding a reference to
  each child and the child a plain back pointer. `UniquePtr` becomes an owned field (`~ delete _`)
  or an owned list. `ElementRef` keeps its weak slot and generation table. It is the GUI's own
  weak reference, and the script handles are built on it.
- **Callbacks.** `core::Function<>` becomes a Beef delegate. The receiver owns a delegate it is
  handed and deletes it when the listener goes, as `InputKindTracker.AddListener` does. Listener
  ids stay `uint32`.
- **Strings and containers.** `String`/`StringView`/`u8"..."` become `String`/`StringView`/`"..."`;
  `Array` becomes `List`, `HashMap` becomes `Dictionary`, `Span` stays `Span`, and `Optional<T>`
  becomes `T?` or a `Result`.
- **Variants.** Raptor has two. `core::Variant` (data model, drag payloads) becomes corlib's
  `System.Variant`, unless a slice shows it cannot carry what the C++ does. `gui::Variant`, the
  model cell value (empty, bool, int, float, string), is the GUI's own and is ported as a small
  struct.
- **Casts.** `core::Cast<T>` becomes `as`. `RTTI_OBJECT` is not needed: every Beef class knows
  its type.
- **Data.** The tests reach fonts and images through `FindDataRoot` and `DataPath`, which
  Sedulous.VFS already has. The four fonts they use are already in `Data/Assets/fonts`. The
  ledger's `Data/` (the sandbox and showcase pages, the reference images, the fuzz input) moves
  to the same place in `Data/` with the first port that reads it. Two places use a CMake define
  for a path (GUI.Code's language samples, the showcase script test); they use `FindDataRoot`
  instead.

## Reflection: one record per property

The GUI rests on reflection. A widget property is written down once, with its script name, its
CSS name and flags (`translatable`, `twoWay`, `access`), and that one record serves:

- the CSS applier, which sets any property a sheet names. A fixed table of about 113 properties
  is handled by hand; everything else is found through reflection. The applier tracks per node
  whether the sheet or code set each value, so it can put the node's own value back;
- the markup loader, which builds an element by its tag and sets its attributes;
- bindings (`{{name}}`, two-way), which find a property by either name;
- the script surface: every widget, its properties and its methods.

In Raptor these are runtime records (`REFLECT_MEMBERS` builders, 66 types and about 183
properties in the core, plus the satellites' own). Sedulous.UI has nothing like this: its CSS,
markup and scripts each keep their own hand-written table.

**Ruled (user): generate the record at compile time.** A widget's property carries a `[GuiProperty]`
attribute: `[GuiProperty(Css = "page")]`, `[GuiProperty(Translatable = true)]`. A comptime type
attribute on the widget emits a static table of its properties, each with its names, its flags,
its value type, and typed get and set thunks. The table chains to the base class's table, so a
lookup walks up the hierarchy the way Raptor's walks `type->base`. The markup creator is a thunk
in the same table. This is how `[Serializable]` already emits its bodies, and the script walker
already reads a property as its `get__X`/`set__X` accessors at compile time (Beef has no
property info at run time).

What that buys: no run time reflection (Beef's is opt in, costs binary size, and is listed in
`Documentation/RuntimeReflection.md` use by use), typed access with no boxing, and a build that
fails on a CSS name that does not parse to the property's type. What it costs: a generator to
write first, in S1 to S3, and tested on its own before the widgets depend on it.

The value conversion Raptor does at run time with `ConvertVariant` (a string from a sheet or an
attribute to the property's type) becomes a thunk generated per value type, built on the style
value parsers.

The toolkit's reflected property source reads more of a member than its name (Raptor's property
attributes, enumerators, containers and value structs, all from Core's run time reflection). The
same generator carries it: Core's `[DisplayName]`, `[Description]`, `[Range]` and `[VisibleWhen]`
beside `[GuiProperty]`, and the GUI's own flags on it (`BitFlags`, `NoAlpha`, `HdrColor`); an
enum's cases, walked at compile time; a value struct (one whose public fields carry
`[GuiProperty]`) as its fields, each a typed get and set over a pointer to a copy the source
writes back through the property's setter; and a `List<T>` as typed count, element and change
thunks, with `[GuiList]` giving its most (Raptor's BoundedArray) and, for a list of objects, the
`[GuiReflect]` types an add makes (Raptor enumerates a base's derived types; here they are named).

## Scripts

- **AngelScript only.** Sedulous has no Luau. Each Integration.GuiScript story runs once in
  AngelScript and once in Luau; the Luau half of each is struck as left out on purpose.
- **The surface** comes from the existing comptime walker. Widget members exposed to scripts are
  marked `[Scriptable]`; the walker will need to learn a new kind of handle (a GUI node, weak,
  through the element table), the `X.of(node)` cast that every widget type has, and the `gui`
  facade as a script service.
- **The names (user ruling): Sedulous's PascalCase.** Raptor's script names are camelCase (`text`,
  `add`, `on`, `of`). The GUI's script surface uses the Beef names as Sedulous's other surfaces do,
  so the scripts Raptor ships as data (the showcase menu, the sandbox pages, the script tests) are
  rewritten to them as they port.
- **A stale handle.** In Raptor, using a handle to a destroyed node is a script error ("the object
  is gone"). Sedulous's UI handles read as null instead. The GUI port follows Raptor, since its
  tests check for the error.

## Type names

Each type keeps the name Raptor gives it, `GUIContext` and `GUIModule` beside `GuiHost` and
`GuiSubsystem` (user ruling), so the two engines can be searched side by side.

## Reference images

Sedulous renders its own reference images (user ruling): the sandbox's image tests compare
against PNGs Sedulous drew, kept in `Data/Tests/GUI/Images`. Raptor's PNGs, moved there from the
ledger, are what each one is first checked against by eye and by difference, to verify the port
draws what Raptor draws; then Sedulous's image replaces it.

## Left out

- `Foundation::Policy`, the allocator parameters, the `CMakeLists.txt` files (each struck when its
  BeefProj.toml lands), the libFuzzer build, and the Luau halves of the script tests.
- The specs and plans stay in Raptor, which is where the design record is kept:
  `Specs/vg-and-gui-lab.md`, `gui-lab-evolution{,-2,-3}.md`, `Systems/gui-port.md`.

## Rulings (user, 2026-10-23)

1. Reflection: generated at compile time.
2. Script names: Sedulous's PascalCase; Raptor's scripts are rewritten as they port.
3. Type names: as Raptor spells each one.
4. Reference images: Sedulous renders its own, verified against Raptor's.
5. Commits: one per slice, each compiling with its tests passing.
