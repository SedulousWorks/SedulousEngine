# Property Animation Editor Roadmap

Plan for bringing property-animation authoring into the editor. The
runtime side already works end-to-end; this roadmap is purely the
editor UI/UX layer.

## Status snapshot

| Phase | Scope | Status |
|---|---|---|
| 1 | Page scaffolding (preview source, hierarchy, scrub, play/stop, save) | **DONE** |
| 2 | Dopesheet widget + keyframe drag/add/delete | **DONE** |
| 2.5 | Toolbar duration field, looping toggle, keyframe inspector with type-specific value editors | **DONE** |
| 3 | Property picker (add track from registry) | **DONE** (scoped — see below) |
| 4 | Record mode | **DEFERRED** (design documented, not needed for current game) |
| 5+ | Curve editor (CubicSpline tangent authoring on existing `CurveCanvas`) | **DEFERRED** |

End-to-end authoring of property animations works today: open a
`.propanim`, pick a preview `.scene` or `.prefab`, pick a target entity
from the hierarchy, add tracks via the property picker, set keyframes,
edit times/values, scrub, play, save.

---

## Current state

**Runtime — DONE** (`Sedulous.Animation` + `Sedulous.Animation.Resources` + `Sedulous.Engine.Animation`):

- `PropertyAnimationClip`: name, duration, looping flag, plus five
  parallel type-specific track lists (`FloatTracks`, `Vector2Tracks`,
  `Vector3Tracks`, `Vector4Tracks`, `QuaternionTracks`).
- `PropertyAnimationTrack<T>`: `PropertyPath` (e.g. `"Transform.Position"`),
  `Interpolation` (Step | Linear | CubicSpline), `Easing` (preset
  curves), `Keyframes` (sorted-by-time list of `Keyframe<T>`).
- `Keyframe<T>`: `Time`, `Value`, plus `InTangent`/`OutTangent` for
  CubicSpline.
- `PropertyAnimationSampler` handles all sampling math (lerp/slerp +
  Hermite for CubicSpline + easing).
- `PropertyAnimationPlayer` drives playback (stopped / playing / paused,
  current time, speed, looping).
- `PropertyBinderRegistry` maps string property paths to typed setter
  delegates, one per supported value type. Built-in bindings cover
  Transform.Position / Rotation / Scale and component-X/Y/Z scalars.
- `PropertyAnimationComponent` + `PropertyAnimationComponentManager`:
  resolves clip refs, creates a player, ticks during the scene's
  AsyncUpdate phase, evaluates and writes to bound properties.
- `.propanim` file format with full serialization round-trip
  (multi-track, multi-type, easing preservation), and in-place
  hot-reload that preserves outside references to the clip pointer.

**Editor — DONE through Phase 3** (`PropAnimEditorPage` +
`PropAnimPageBuilder` + `TimelineView` + `PropertyPickerDialog`):

- `PropAnimEditorPageFactory` registers `.propanim` and constructs a
  real editor page.
- `PropAnimEditorPage` implements `IEditorPage` and
  `IResourceChangeListener`, holds a preview `Scene` via
  `PreviewSceneHost`, picks a target entity, and exposes scrub /
  play / stop / save. Reacts to hot-reload via `OnClipReloaded`
  (subscribers refresh cached track indices and selection).
- `PropAnimPageBuilder` builds the page layout: toolbar (play/stop +
  current-time readout + duration `NumericField` + loop `CheckBox`),
  left panel (preview source picker, entity hierarchy, keyframe
  inspector), center viewport, bottom timeline region (mini-toolbar
  with Add Track / Add Keyframe / Delete Keyframe + the dopesheet).
- `TimelineView` is the dopesheet widget: ruler with playhead, track
  rows (one per existing track, labeled with kind + property path),
  diamond keyframes, click-to-select, drag-to-retime, Delete key.
  Exposes typed accessors for the selected keyframe's value and time;
  scrubbing fires `OnPlayheadChanged`, mutations fire `OnClipMutated`.
- `PropertyPickerDialog` lists every path registered with the
  `PropertyBinderRegistry`, grouped by value type. Selection appends
  the correct typed track via `clip.AddXxxTrack(path)`.
- The keyframe inspector in the left panel uses the toolkit's
  standalone `Vector2Field` / `Vector3Field` / `Vector4Field` /
  `QuaternionField` (Euler-degrees presentation for quaternions) plus
  a plain `NumericField` for floats. `OnEditBegan` / `OnEditEnded`
  events from those fields drive an "is editing" flag that defers
  inspector rebuilds via `MutationQueue`, so per-keystroke
  `OnValueChanged` → `OnClipMutated` doesn't tear down the field the
  user is typing in.
- Scrub-before-Play works: the page's `CurrentTime` setter hands the
  clip to the player and immediately pauses it so `Evaluate()` has a
  non-null clip to sample.

---

## Design decisions (settled)

- **Preview source is a `.scene` or `.prefab`.** Either is loaded
  into a fresh temp scene; the on-disk file is never modified.
- **Preview is fully in-memory.** Auto-added components, evaluated
  property writes, etc. live in the temp scene and vanish on close.
- **Auto-add missing components on the target entity** when the user
  picks one that doesn't have the component the animation writes to.
  Surfaced in the UI via the "Component auto-added on target"
  indicator in the inspector.
- **Page-scope first; extract widgets later.** `TimelineView` and
  `PropertyPickerDialog` are page-scope today; extract when a second
  consumer appears.
- **Scene/prefab swap doesn't reset animation work.** Tracks stay on
  the clip across preview-source swaps.
- **Preview-target persistence — session-only.** Editor doesn't
  persist the picked preview/target across restarts. No metadata
  baked into the `.propanim` file.
- **Hot-reload preserves outside references.** The resource reloads
  in place; `OnClipReloaded` lets editor state refresh.

---

## Non-goals

- **Curve editor for tangent editing** (CubicSpline custom tangents).
  Linear + Step + easing presets cover almost all game animation.
- **Multi-target tracks.** Runtime supports one component per entity
  with paths relative to that entity. No editor work for multi-target.
- **Constraint / parent-of / look-at rigs.** Just property tracks.
- **Animation blending / state machine** — `.animgraph` territory.
- **Generic reusable timeline widget** — page-scope until a second
  user materializes.

---

## Phase 1 — Page scaffolding [DONE]

Shipped: `PropAnimEditorPage` + `PropAnimPageBuilder` Phase-1 layout
+ `PreviewSceneHost`, scrub slider stub, Play / Stop / Save, entity
hierarchy in the left panel, target picker with auto-component-add,
session-only preview state.

---

## Phase 2 — Dopesheet + keyframe editing [DONE]

Shipped: `TimelineView` widget with ruler + playhead + per-track rows
+ diamond keyframes. Interactions: select track (label-column click),
hit-test keyframe, drag-to-retime, Add/Delete Keyframe buttons,
Delete key. Two-way sync of playhead time with `page.CurrentTime`.
`OnClipMutated` fires `page.MarkDirty()`.

Drag-retime never shrinks `Clip.Duration` — the editor's duration is
user-authored and uses `ExtendDurationIfNeeded(t)` instead of the
runtime's `ComputeDuration()`.

---

## Phase 2.5 — Duration, looping, value editing [DONE]

Shipped after Phase 2 user feedback:

- **Duration `NumericField`** in the toolbar. Sets `clip.Duration`
  directly; replaces the Phase-2 implicit "duration = max keyframe
  time" behavior.
- **Loop `CheckBox`** in the toolbar. Toggles `clip.IsLooping`
  (previously serialized but unauthored).
- **Keyframe inspector** in the left panel, replacing the Phase-1
  track-summary placeholder. When a keyframe is selected, shows track
  path + a time `NumericField` + per-type value editor (single
  `NumericField` for float, the toolkit's `VectorNField` / `QuaternionField`
  for vectors / quaternions). Quaternion editor presents Euler degrees
  internally but emits `Quaternion` on the wire — same convention as
  `PropertyGridDescriptor.QuaternionToEuler`.
- **Edit-transaction handling**. `NumericField` got
  `OnEditBegan` / `OnEditEnded` events on focus gain/loss; vector
  fields aggregate child events with a `MutationQueue`-deferred End
  so cross-axis tabbing doesn't fire a transient End/Begin pair. The
  inspector flips `host.IsEditing` from those events and queues
  rebuilds for after the user leaves the field, so per-keystroke
  `OnClipMutated` doesn't tear down the field the user is typing in.
- **Scrub-before-Play.** Page's `CurrentTime` setter hands the clip
  to the player and immediately pauses it so `Evaluate()` actually
  samples on the first scrub, even when Play has never been pressed.

---

## Phase 3 — Property picker [DONE, scoped]

Shipped: `PropertyPickerDialog` — modal dialog grouped by value type,
listing every path the `PropertyBinderRegistry` knows about
(Transform.Position, Transform.Rotation, Transform.Position.X, etc.).
"Add Track..." button in the timeline mini-toolbar opens it; selection
calls the appropriate `clip.AddXxxTrack(path)`, marks the page dirty,
and refreshes the timeline.

Supporting work: `PropertyBinderRegistry` got `FloatPaths` /
`Vector2Paths` / `Vector3Paths` / `Vector4Paths` / `QuaternionPaths`
enumerators so the dialog can walk the dictionaries.

### Scope delta from original plan

The roadmap originally proposed reflecting on the target entity's
`[Property]` fields and cross-referencing against the binder registry
to filter the list per-entity. That landed differently:

- **Current behavior:** flat list of every registered path. The user
  can pick any path; if it doesn't resolve on the target entity, the
  binder silently no-ops at play time.
- **Why deferred:** the `InspectorCodegen` comptime-generates
  `DescribeProperties` per component, but reaching that data at
  runtime to filter the picker is more plumbing than the value
  warranted. Defer until users actually hit "wrong path" friction.

### Future work for Phase 3 (deferred)

- Filter by target entity's components.
- "Doesn't resolve on this entity — add component for preview?" prompt.
- Allow picking from a runtime binder that doesn't have a matching
  `[Property]` field (generated paths).

---

## Phase 4 — Record mode [DEFERRED]

Big UX win for animator workflows, but not blocking the current game.
Design captured here from the audit done before deferral.

### Goal

While "Record" is toggled on the toolbar, every property change the
user makes on the target entity in an inspector becomes a keyframe at
the current playhead time on the matching track (creating the track
if it doesn't exist).

### Required work

1. **Embed an inspector for the target entity in the PropAnim page.**
   The page currently doesn't show one. Mirror
   `ScenePageBuilder.BuildInspector`: create a `PropertyGrid`,
   rebuild it on `page.OnTargetChanged`, walk the entity's
   `IInspectable` components via `entity.DescribeProperties(desc)`.
2. **Hook each editor's `OnEditEnd`.** The scene editor already does
   this for its own dirty-tracking; copy the pattern. Use `OnEditEnd`
   (not `OnValueChanged`) so a single edit gesture produces one
   keyframe, not one per keystroke.
3. **Property-path mapping.** The inspector knows
   `(component=TransformComponent, property=Position)`. The binder
   keys by `"Transform.Position"`. Need a helper:
   `componentSerializationTypeId.LastSegment.StripSuffix("Component") + "." + propertyName`.
4. **Per-type dispatch.** On `OnEditEnd`, read the editor's typed
   `Value`, dispatch to `clip.AddXxxTrack(path)` (if no track exists
   for that path) + `track.AddKeyframe(playheadTime, value)`. One
   case per `PropTrackKind`. Replace existing keyframe at the same
   time stamp rather than appending a duplicate.
5. **Record-mode toggle** on the toolbar (likely a
   `ToggleButton`/`CheckBox`). Drives an `IsRecording` flag on the
   page.
6. **Visible recording indicator on the viewport.** A red border on
   the viewport `Panel`, or a "REC" overlay, while `IsRecording` is on.

### Open questions

- **`OnEditEnd` vs `OnValueChanged`?** Recommended: `OnEditEnd`
  (transaction-shaped, matches scene-editor convention, avoids ten
  keyframes from typing "1.234"). Could offer `OnValueChanged` as a
  toggle ("real-time record") later.
- **Restrict to registered paths only, or allow unbound paths?**
  Recommended: restrict to paths with a registered binder. Unbound
  paths produce silent runtime no-ops; not useful.
- **Component auto-add on first record?** If the user enables record
  mode on an entity that doesn't have a `LightComponent`, should
  twiddling `Light.Intensity` somehow appear? Probably no — record
  mode records what the inspector exposes; the inspector exposes
  components the entity has.

### Audit notes (Phase 3 sweep)

- `PropertyEditor` already has `OnEditBegan` / `OnEditEnded` (added
  in Phase 2.5). Scene editor uses `OnEditEnd` exclusively.
- `PropertyGridDescriptor.Float / Vec3 / Quat / ...` wires a `Setter`
  delegate that writes directly to `T*`. Setter fires on every
  keystroke (this is intentional for live editing); the
  `OnEditEnd` event brackets the gesture.
- `InspectorCodegen.bf` derives property names from field names
  (`mIntensity` → `"Intensity"`); honors `[Property("DisplayName", "SerializedName")]`
  for overrides.
- Component `SerializationTypeId` is fully-qualified (e.g.
  `"Sedulous.TransformComponent"`). Binder paths are short
  (`"Transform.Position"`). Need a strip helper.

---

## Phase 5+ — Curve editor [DEFERRED]

Deferred until a real authoring need arises.

The toolkit already has a working curve widget at
`Foundation/Sedulous.UI.Toolkit/src/Controls/CurveCanvas.bf`. Its
`Keypoint` carries `TangentIn` / `TangentOut` (lines 103-104) and the
Hermite evaluation uses them (line 240+). The curve renders correctly
end-to-end. What's missing for Phase 5 is the **tangent-handle editing
UI** — file comment at line 93 explicitly notes "Tangent handle
editing is not yet exposed; tangents stay at the values set by code".

Phase 5 work (when it lands):

1. Add draggable tangent handles to each `Keypoint` in `CurveCanvas`
   (the geometry + hit-testing; the math already consumes them).
2. Tangent modes: free / locked / mirrored / flat / broken.
3. Wire `CurveCanvas` into the PropAnim editor as an alternate view
   of a single track — switch between dopesheet row and curve view.
4. Round-trip `PropertyAnimationTrack<T>.Keyframes[i].InTangent` /
   `OutTangent` through the canvas (per-component for vector tracks).

Since `CurveCanvas` is already in the toolkit, scope is "add tangent
editing to the existing widget" rather than "build a curve editor
from scratch". Other consumers (particle effects, gradients) get the
tangent affordances for free once it's there.

---

## Cross-references

- Runtime entry points: `PropertyAnimationClip`,
  `PropertyAnimationComponent`,
  `PropertyAnimationComponentManager`,
  `PropertyAnimationPlayer`,
  `PropertyAnimationSampler`,
  `PropertyBinderRegistry`,
  `PropertyAnimationClipResource`.
- Editor entry points: `PropAnimEditorPageFactory`,
  `PropAnimEditorPage`, `PropAnimPageBuilder`, `TimelineView`,
  `PropertyPickerDialog`, `Sedulous.UI.Toolkit/VectorFields.bf`.
- Patterns to mirror for Phase 4 record mode:
  - `ScenePageBuilder.BuildInspector` (`Editor.App/src/Pages/ScenePageBuilder.bf`)
    for entity-inspector hookup and `OnEditEnd` subscription.
  - `PropertyGridDescriptor` (`Editor.Core/src/Inspection/PropertyGridDescriptor.bf`)
    for the Setter-delegate wiring convention.
- Reference programmatic-clip usage:
  `Samples/EngineSandbox/src/SandboxApp.bf` around line 641
  (`mOrbitAnimRes`).
