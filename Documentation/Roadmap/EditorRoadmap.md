# Sedulous Editor Roadmap

A modular, extensible editor built on the Sedulous engine and Sedulous.UI framework.
Engine modules plug in their editor functionality via `[EditorPlugin]` without the
editor core knowing about them. Reference: BansheeBeef editor implementation.

## Design Principles

| Principle | Description |
|-----------|-------------|
| **Plugin-first** | Every editor feature beyond the shell is a plugin. Built-in panels are plugins too. |
| **Compile-time discovery** | `[EditorPlugin]` attribute + `Type.Types` scan at startup. No manual registration. |
| **Command-based undo** | All edits go through `IEditorCommand`. Merging for drags, groups for multi-step. |
| **Reflection-based defaults** | Components get auto-generated inspectors via field reflection. Custom inspectors override per-type. |
| **Separate editor projects** | Each engine module gets a paired editor project (e.g. `Sedulous.Editor.Physics`). Editor deps stay out of runtime. |

## Key Differences from BansheeBeef Reference

The Banshee editor uses its own `Sedulous.UI` + `Sedulous.UI.Toolkit` - a similar
Android-inspired UI framework with the same control names (Label, Button, Panel,
TreeView, PropertyGrid, DockManager, SplitView, etc.) but a different implementation
from ours. The ideas and patterns carry over; the code does not.

Other differences:

- `DrawContext`/`DrawingRenderer` - we use **VGContext/VGRenderer**
- `Application` (Runtime.Client) - we follow the same pattern, **not** EngineApplication
- Old `Context` with shared JobSystem/ResourceSystem - our JobSystem is a singleton (runs jobs immediately), Context just calls ProcessCompleteJobs in update
- `Sedulous.Engine.Core` (old engine) - we use **Sedulous.Engine.Core** + scene system
- `EntityId` - we use **EntityHandle**
- `SceneManager` - we use **SceneSubsystem** + **ComponentManager<T>** pattern
- Old `Renderer` class - we use **RenderSubsystem** with Pipeline/RenderGraph

The Banshee editor's architecture (plugins, pages, inspector flow, command stack) is
a strong reference. Control patterns are similar but not copy-paste - our UI API
differs in constructors, layout params, and theming. The main adaptation work is in
engine integration: scene management, viewport rendering, and component inspection.

## Project Management

Open a directory to start working. The editor looks for or creates a `.sedproj` file.

**`.sedproj` stores:**
- Editor window layout (dock positions, panel sizes)
- Recently opened scenes
- Last active scene (restored on project open)
- Build configuration
- Per-plugin settings (each plugin gets a named section)

**Startup flow:**
1. Full-window project picker (no editor shell behind it)
2. New Project / Open Project / Recent list
3. On open: restore layout, reopen last active pages
4. Default layout: Page area (center), Console+Assets (bottom)

## Embedded Runtime

The editor runs a **separate engine runtime instance** for live preview, following
the same pattern as the Banshee editor. Editor and runtime have distinct Context
instances with clean separation.

```
EditorApplication
├── EditorContext                      # Editor services (plugins, documents, selection, UI)
│   ├── EditorPluginRegistry
│   ├── EditorPageManager
│   ├── EditorCommandStack
│   ├── AssetSelection
│   └── EditorProject
│
├── RuntimeContext                     # Embedded engine (render, physics, audio, animation)
│   ├── SceneSubsystem
│   ├── RenderSubsystem
│   ├── PhysicsSubsystem
│   ├── AnimationSubsystem
│   ├── AudioSubsystem
│   └── NavigationSubsystem
│
├── Shared
│   ├── ResourceSystem (editor owns, both contexts reference)
│   ├── ShaderSystem
│   └── JobSystem (singleton, no per-context instance needed)
│
└── Editor UI
    ├── UIContext + VGRenderer (editor owns directly)
    ├── DockManager (outer shell)
    ├── MenuBar / StatusBar
    └── Per-page content views
```

**Editor mode (default):**
- Engine ticks rendering only (viewport preview, gizmos)
- Physics/audio paused or tick-on-demand (animation preview scrubbing)
- Editor owns scene mutations (all changes go through EditorCommands)

**Play mode:**
1. Serialize active scene to buffer
2. Engine begins full ticking (physics, audio, animation, gameplay)
3. Inspector becomes read-only, play/pause/stop controls shown
4. Stop -> restore scene from buffer, resume editor mode
5. Undo history preserved across play/stop

## Project Structure

```
Editor/
  Sedulous.Editor.Core/src/           # Interfaces and systems (library)
    EditorContext.bf                   # Central service locator
    Attributes/
      EditorPluginAttribute.bf        # [EditorPlugin] for auto-discovery
      HideInInspectorAttribute.bf     # Skip field in inspector
      RangeAttribute.bf               # Min/max slider
      CategoryAttribute.bf            # Inspector grouping
      TooltipAttribute.bf             # Hover text
    Commands/
      IEditorCommand.bf               # Undoable operation
      EditorCommandStack.bf           # Undo/redo manager
      CommandGroup.bf                 # Multi-step atomic undo
      PropertyChangeCommand.bf        # Generic field value change
      EntityCommands.bf               # Create/delete/reparent entity
    Pages/
      IEditorPage.bf                  # Base for all editor pages
      IEditorPageFactory.bf           # Creates pages per file type
      SceneEditorPage.bf              # Scene editing page
      EditorPageManager.bf            # Open pages, active tab
    Selection/
      AssetSelection.bf               # Global asset browser selection
    Plugins/
      IEditorPlugin.bf                # Top-level plugin interface
      EditorPluginRegistry.bf         # Discovery + lifecycle
    Panels/
      IEditorPanel.bf                 # Dockable panel
      IEditorPanelFactory.bf          # Panel creation factory
    Inspection/
      IComponentInspector.bf          # Custom per-component inspector
      ReflectionInspector.bf          # Default: auto from fields
      InspectorContext.bf             # Services for inspectors
    Assets/
      IAssetImporter.bf               # Source file -> engine asset
      IAssetCreator.bf                # "Create New" asset types
      IAssetThumbnailGenerator.bf     # Asset browser thumbnails
    Gizmos/
      IGizmoRenderer.bf               # 3D viewport gizmo per component
      GizmoContext.bf                 # Drawing helpers
    Scene/
      EditorSceneManager.bf           # Play/pause/stop mode
    Project/
      EditorProject.bf                # .sedproj loading/saving
      RecentProjects.bf               # User-local recent list

  Sedulous.Editor.App/src/            # Editor executable
    EditorApplication.bf              # Standalone app, owns device/window/UI + RuntimeContext
    Pages/
      ScenePageBuilder.bf             # Hierarchy + Viewport + Inspector layout
    Panels/
      ConsolePanel.bf                 # Log output
      AssetBrowserPanel.bf            # File browser
    ViewportView.bf                   # 3D scene viewport (render-to-texture)
    ViewportCameraController.bf       # Fly cam for viewport
    Program.bf                        # Entry point

  Sedulous.Editor.Physics/src/        # Per-module editor plugin
    PhysicsEditorPlugin.bf
    RigidbodyInspector.bf
    ColliderGizmoRenderer.bf
  Sedulous.Editor.Render/src/
    RenderEditorPlugin.bf
    MaterialEditorPage.bf
    LightGizmoRenderer.bf
  Sedulous.Editor.Audio/src/
    AudioEditorPlugin.bf
  Sedulous.Editor.Animation/src/
    AnimationEditorPlugin.bf
    CurveEditor.bf
  ... (one editor project per engine module)
```

## Core Interfaces

### IEditorPlugin

```beef
interface IEditorPlugin : IDisposable
{
    StringView Name { get; }
    void Initialize(EditorContext context);
    void Shutdown();
    void Update(float deltaTime);
}
```

### EditorContext

```beef
class EditorContext
{
    // Engine runtime (from EngineApplication)
    public Context RuntimeContext;

    // Editor services
    public EditorPageManager PageManager;
    public EditorSceneManager SceneEditor;
    public AssetSelection AssetSelection;
    public EditorPluginRegistry PluginRegistry;
    public EditorProject Project;

    // UI (editor shell)
    public DockManager DockManager;
    public MenuBar MenuBar;

    // Registration - plugins call during Initialize()
    public void RegisterPanelFactory(IEditorPanelFactory factory);
    public void RegisterComponentInspector(Type componentType, IComponentInspector inspector);
    public void RegisterPageFactory(IEditorPageFactory factory);
    public void RegisterAssetImporter(IAssetImporter importer);
    public void RegisterAssetCreator(IAssetCreator creator);
    public void RegisterThumbnailGenerator(StringView extension, IAssetThumbnailGenerator gen);
    public void RegisterGizmoRenderer(Type componentType, IGizmoRenderer renderer);
    public void AddMenuItem(StringView menuPath, delegate void() action);
}
```

### IEditorCommand + EditorCommandStack

```beef
interface IEditorCommand : IDisposable
{
    StringView Description { get; }
    void Execute();
    void Undo();
    bool CanMergeWith(IEditorCommand other);
    void MergeWith(IEditorCommand other);
}

class EditorCommandStack
{
    public bool CanUndo { get; }
    public bool CanRedo { get; }
    public void Execute(IEditorCommand command);
    public void Undo();
    public void Redo();
    public void BeginGroup(StringView description);
    public void EndGroup();
}
```

### IEditorPage

Both scenes and assets open as pages in a shared tab bar. Each page has its
own undo stack, dirty state, and content view.

```beef
interface IEditorPage : IDisposable
{
    StringView PageId { get; }
    StringView Title { get; }           // Appends "*" when dirty
    StringView FilePath { get; }
    View ContentView { get; }           // Root view for page content
    bool IsDirty { get; }
    EditorCommandStack CommandStack { get; }

    void Save();
    void SaveAs(StringView path);
    void OnActivated();
    void OnDeactivated();
    void Update(float deltaTime);
}
```

### SceneEditorPage

Scene-specific page. ContentView is an internal layout:
Hierarchy (left) | Viewport (center) | Inspector (right).

```beef
class SceneEditorPage : IEditorPage
{
    public Scene Scene;
    public List<EntityHandle> SelectedEntities;
    public EventAccessor<delegate void(SceneEditorPage)> OnSelectionChanged;

    public void SelectEntity(EntityHandle entity);
    public void ClearSelection();
    public bool IsSelected(EntityHandle entity);
}
```

### Page Layout Architecture

```
DockManager (outer, owned by EditorApplication)
├── Page tab area (center) - active page's ContentView
│   └── SceneEditorPage.ContentView:
│       ├── Hierarchy (left)       ← per-page, TreeView with SceneHierarchyAdapter
│       ├── Viewport (center)      ← per-page, render-to-texture with fly cam
│       └── Inspector (right)      ← per-page, PropertyGrid with reflection/custom inspectors
│   └── MaterialEditorPage.ContentView:
│       └── Material property editor
│
├── Console (bottom)               ← global panel
├── Asset Browser (bottom tab)     ← global panel
└── Plugin panels                  ← global, contributed by plugins
```

### IComponentInspector

```beef
interface IComponentInspector : IDisposable
{
    Type ComponentType { get; }
    void BuildInspector(Component component, PropertyGrid grid, InspectorContext ctx);
    void TeardownInspector();
}
```

Default: `ReflectionInspector` iterates `component.GetType().GetFields()`,
maps field types to PropertyEditor subclasses, wires OnEditBegin/OnEditEnd
to PropertyChangeCommand.

### Asset Pipeline

```beef
interface IAssetImporter
{
    void GetSupportedExtensions(List<String> outExtensions);
    Result<void> Import(StringView sourcePath, StringView outputPath);
}

interface IAssetCreator
{
    StringView DisplayName { get; }     // "Material", "Animation Clip"
    StringView Category { get; }        // "Rendering", "Animation"
    StringView Extension { get; }       // ".mat", ".anim"
    Result<void> Create(StringView path, EditorContext context);
}

interface IAssetThumbnailGenerator
{
    Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 w, int32 h);
}
```

### Gizmos

```beef
interface IGizmoRenderer : IDisposable
{
    Type ComponentType { get; }
    void Draw(Component component, GizmoContext ctx);
    bool DrawWhenUnselected { get; }
}
```

GizmoContext wraps the engine's DebugDraw for wire shapes, or provides
direct access to the render encoder for custom rendering.

## Plugin Discovery

```beef
[AttributeUsage(.Class, .AlwaysIncludeTarget)]
struct EditorPluginAttribute : Attribute
{
    public int32 Priority;
    public this(int32 priority = 0) { Priority = priority; }
}

// EditorPluginRegistry.DiscoverPlugins():
for (let type in Type.Types)
{
    if (type.HasCustomAttribute<EditorPluginAttribute>())
    {
        let plugin = type.CreateObject() as IEditorPlugin;
        if (plugin != null) mPlugins.Add(plugin);
    }
}
// Sort by priority, then Initialize(context) each.
```

## Inspector Flow

1. User clicks entity in Hierarchy -> `SceneEditorPage.SelectEntity(handle)`
2. Inspector observes `OnSelectionChanged`
3. For each component on the entity:
   - Registered `IComponentInspector` -> `BuildInspector(component, grid, ctx)`
   - No custom -> `ReflectionInspector` auto-generates from fields
4. PropertyEditor events -> `PropertyChangeCommand` -> per-page `CommandStack`

## Rendering Architecture Refactor (Prerequisite) - DONE

Decoupled RenderSubsystem from presentation so the same scene rendering code
works in both EngineApplication (game) and EditorApplication (viewport texture).

### ISceneRenderer / IOverlayRenderer interfaces

Two interfaces queried from Context via `GetSubsystemByInterface<T>()` /
`GetSubsystemsByInterface<T>()` (added to Context for this purpose):

```beef
/// Implemented by RenderSubsystem. First one found is used.
interface ISceneRenderer
{
    void RenderScene(ICommandEncoder encoder, ITexture colorTexture,
        ITextureView colorTarget, uint32 w, uint32 h, int32 frameIndex);
    Pipeline Pipeline { get; }
    RenderContext RenderContext { get; }
}

/// Implemented by EngineUISubsystem (delegates to ScreenUIView).
/// All found are run, sorted by OverlayOrder.
interface IOverlayRenderer
{
    int32 OverlayOrder { get; }
    void RenderOverlay(ICommandEncoder encoder, ITextureView target,
        uint32 w, uint32 h, int32 frameIndex);
}
```

**Key design:** RenderSubsystem implements only ISceneRenderer. It does not
handle overlays. EngineUISubsystem implements IOverlayRenderer and delegates
to ScreenUIView. This keeps scene rendering and UI overlay as separate concerns
on separate subsystems - cleaner than having RenderSubsystem own both.

### Texture ownership

The application owns the **final output target** (RGBA16Float color) and passes
it to RenderScene. Internal pipeline textures (bloom chain, shadow atlas,
transient HDR, G-buffer) stay internal. Pipeline no longer creates or owns
the output texture - it receives it as a parameter.

### Application frame loop (implemented)

```beef
// EngineApplication.PresentFrame():
WaitFence(mFrameIndex);
ResetCommandPool(mFrameIndex);
encoder = CreateEncoder();

ClearTarget(encoder, mColorTarget);           // render pass with LoadOp.Clear

mSceneRenderer.RenderScene(encoder,           // extraction + shadows + pipeline
    mColorTarget, mColorTargetView, w, h, mFrameIndex);
// colorTarget is now in ShaderRead state (transitioned by RenderScene)

AcquireSwapchainImage();
BlitToSwapchain(encoder, mColorTargetView);   // fullscreen triangle tonemap blit

for (let overlay in mOverlayRenderers)        // sorted by OverlayOrder
    overlay.RenderOverlay(encoder, swapchainView, swapW, swapH, mFrameIndex);

TransitionToPresent(encoder);
Submit(encoder);
Present();
mFrameIndex = (mFrameIndex + 1) % MAX_FRAMES;
```

### What changed

**RenderSubsystem:**
- Implements ISceneRenderer - `RenderScene(encoder, targets, frameIndex)`
- Lost: swapchain, surface, blit helper, overlay list, command pools, frame fence
- Pipeline receives output target as parameter, no longer owns it
- Pipeline's explicit ClearOutput pass removed (ForwardOpaquePass already uses LoadOp.Clear on the transient HDR; application clears the final output)
- Transition contract: output enters as RenderTarget, exits as ShaderRead

**EngineApplication:**
- Owns: swapchain, output texture, command pools, frame fence, frame index, blit helper
- New PresentFrame() after Context.EndFrame() - handles the full clear -> render -> blit -> overlay -> present pipeline
- Caches ISceneRenderer + IOverlayRenderer queries at startup

**EngineUISubsystem:**
- Implements IOverlayRenderer (delegates to ScreenUIView)
- No longer registers overlay with RenderSubsystem
- Gets SwapChainFormat + FrameCount from application (set before startup)
- Uses ISceneRenderer interface for Pipeline/RenderContext access
- WorldUIPass registered in OnReady() instead of deferred Update hack

**Subsystem lifecycle:**
- Added `OnReady()` - called after all OnInit() completes, before first frame.
  Mirror of OnPrepareShutdown. Enables cross-subsystem wiring without deferred hacks.

**Pipeline:**
- `Render()` takes `(encoder, view, outputTexture, outputTextureView, frameIndex)`
- No longer creates/destroys output texture
- OnResize just updates dimensions and notifies passes
- Clear pass removed; transient HDR cleared by first writer's LoadOp.Clear

**Deleted:** IRenderOverlay.bf (replaced by IOverlayRenderer)

### Editor benefit

The editor calls `ISceneRenderer.RenderScene` with its own viewport texture.
No swapchain on the RuntimeContext. Same RenderSubsystem code, different targets:

```beef
// EditorApplication:
ClearTarget(encoder, mViewportColor);
sceneRenderer.RenderScene(encoder, mViewportColor, mViewportColorView,
    vpW, vpH, frameIndex);
// Display mViewportColorView in viewport panel
// Render editor UI to own swapchain
// Present editor swapchain
```

## Viewport

The editor's 3D viewport displays the output of `ISceneRenderer.RenderScene`
called with a viewport-sized texture. The editor owns the texture, passes it
to the runtime's scene renderer, then displays it in the viewport panel.

**ViewportCameraController** handles fly-cam (WASD + mouse look) within
the viewport view's bounds. Only active when viewport is focused.

**Gizmos** render as an overlay pass after the scene, using DebugDraw or
a dedicated gizmo render pass. In editor mode, gizmos render into the
viewport output (before the editor composites it), so they appear in the
viewport but not in the editor UI.

## Implementation Phases

### Phase 1: Core Framework - DONE
- `EditorContext`, `IEditorPlugin`, `EditorPluginAttribute`, `EditorPluginRegistry`
- `IEditorCommand`, `EditorCommandStack`, `CommandGroup`
- `IEditorPage`, `IEditorPageFactory`, `SceneEditorPage`, `EditorPageManager`
- `AssetSelection`
- `IEditorPanel`, `IEditorPanelFactory`
- `EditorProject` (.sedproj), `RecentProjects`
- `IComponentInspector`, `InspectorContext`, `ReflectionInspector`
- Field attributes: `HideInInspector`, `Range`, `Category`, `Tooltip`
- `PropertyChangeCommand`, `EntityCommands`

### Phase 2: Editor Shell - DONE
- `EditorApplication` extends Runtime.Client.Application (owns UIContext/VGRenderer directly)
- Project picker: New Project / Open Project (OS folder dialog) + recent projects
- Editor shell: MenuBar (File/Edit/View), DockManager, StatusBar
- Page area with placeholder, Console + Assets panels docked at bottom
- LogView with ListView adapter, color-coded level indicators, selection
- EditorLogger with IEditorLogListener + EditorLogBuffer (thread-safe, early log capture)
- RuntimeContext with SceneSubsystem + RenderSubsystem for scene preview
- File > New Scene: creates scene with camera, light, ground plane, cube
- SceneEditorPage with hierarchy | viewport | inspector (ScenePageBuilder)
- SceneHierarchyAdapter: ITreeAdapter with Dictionary nodeId mapping
- ViewportView: render-to-texture via VGRenderer.RegisterExternalTexture
- ViewportCameraController: RMB+drag look, WASD movement, scroll zoom
- IFloatingWindowHost: full OS floating window support
- Cross-window input routing via focused window detection
- Wire: selection -> inspector, command stack -> Edit menu undo/redo

### Phase 3: Entity Inspector

The inspector panel shows the components of the selected entity and allows
editing their properties. This is the primary way to configure entities.

**3a. Reflection-based inspector (default)**
- When an entity is selected, iterate its components via ComponentManagers
- For each component, use `ReflectionInspector` to auto-generate property editors
  from field reflection (`component.GetType().GetFields()`)
- Map field types to PropertyEditor subclasses:
  - `float` -> NumericField, `int` -> NumericField (integer mode)
  - `bool` -> Checkbox
  - `String` -> StringEditor
  - `Color` -> ColorPicker (when available, fallback to 4 floats)
  - `Vector3` -> 3x NumericField row
  - `Quaternion` -> Euler angles (3x NumericField)
  - `Transform` -> Position/Rotation/Scale groups
  - `ResourceRef` -> Path text + browse button
  - `enum` -> ComboBox
- Respect attributes: `[HideInInspector]` skip, `[Range(min,max)]` slider,
  `[Category("name")]` grouping, `[Tooltip("text")]` hover text
- PropertyEditor OnValueChanged -> `PropertyChangeCommand` -> page CommandStack

**3b. Component enumeration**
- Need API to iterate components on an entity across all registered managers
- Options:
  A. Scene stores a component list per entity (adds memory per entity)
  B. Each ComponentManager has `HasComponent(entity)` + `Get(entity)` (iterate all managers)
  C. ComponentManagerBase tracks a per-entity component mask
- Option B is simplest for now - iterate `scene.Modules`, check each manager

**3c. Add/remove components**
- Inspector header: "Add Component" button -> dropdown of all registered component types
- Each component section has a remove button (or context menu)
- Add/remove go through EditorCommands for undo

**3d. Custom inspectors**
- `IComponentInspector` registered per component type (e.g. LightComponentInspector)
- Override `BuildInspector` to create custom UI instead of reflection
- Registered via `EditorContext.RegisterComponentInspector(type, inspector)`

**Dependencies:** PropertyGrid (done), PropertyEditor types (StringEditor done,
NumericField done, need more types), component enumeration API on Scene.

### Phase 4: Asset Browser, Import Pipeline & Registry Management

The asset browser displays registry contents, supports file operations, imports
source assets into baked engine resources, and manages registry mount points.
The import pipeline already exists in `Sedulous.Geometry.Tooling` +
`.Tooling.Resources` (ModelImporter -> ResourceImportResult -> ResourceSerializer)
but is only called from code (EngineSandbox). The editor needs UI and wiring.

**Existing pipeline (complete):**
- `ModelLoaderFactory` -> `GltfLoader` / `FbxLoader` -> `Model`
- `ModelImporter.Import(model, options)` -> `ModelImportResult` (plain data)
- `ResourceImportResult.ConvertFrom(importResult, dedupContext)` -> resource wrappers
- `ResourceSerializer.SaveImportResult(result, outputDir)` -> saves `.mesh`, `.material`, `.texture`, `.skeleton`, `.animation` files
- `ImportDeduplicationContext` -- cross-import texture/material sharing by source path
- `ImageLoaderFactory` -> STB / SDL loaders for standalone texture import
- `ModelImportOptions` -- flags, scale, normals, tangents, recenter, max bones

**Registry system (complete):**
- `ResourceRegistry` -- GUID<->path bidirectional maps, `SaveToFile`/`LoadFromFile`
- `.registry` text format: `guid=relativePath` per line
- `ResourceSystem` -- protocol path resolution (`builtin://`, `project://`), hot-reload via FileWatcher
- Editor already creates `builtin` + `project` registries in `EditorApplication`

**Editor interfaces (defined, needs redesign):**
- `IAssetImporter` -- current: simple `Import(sourcePath, outputPath)`. **Will be redesigned** to support multi-resource preview and import (see Phase 4d)
- `IAssetCreator` -- `DisplayName`, `Category`, `Extension`, `Create(path, context)`
- `IAssetThumbnailGenerator` -- `GenerateThumbnail(path, w, h)`
- `EditorContext` -- `RegisterAssetImporter()`, `RegisterAssetCreator()`, `RegisterThumbnailGenerator()`

**UI toolkit (available):**
- `ListView` -- virtualized, adapter-based, selection, right-click events
- `TreeView` -- hierarchical with `ITreeAdapter`, expand/collapse
- `TabView` -- tabbed container
- `ContextMenu` -- popup menus with submenus
- `ImageView` -- image display with scale modes
- `ToggleButton` -- for view mode switching
- `DragDropManager` / `IDragSource` / `IDropTarget` -- full drag-drop framework
- `IDialogService` -- native file/folder dialogs
- `SelectionModel` -- single/multi selection with events
- **No GridView** -- needs custom implementation for tile view

#### Phase 4a: Asset Browser Panel -- Core UI

**Goal:** Dockable panel with registry tree (left) + content list (right).
Replace the placeholder "Assets" panel in EditorApplication.

**4a-1. Registry Tree (left pane)**

`RegistryTreeAdapter : ITreeAdapter` with one root node per mounted registry.
Each registry shows its filesystem subdirectories as expandable children.
Builtin and project registries always present; additional mounted registries
appear below. Clicking a node sets the content view's current path.

Tree node data:
- Registry name (root level) -- e.g. "builtin", "project", "shared_assets"
- Subdirectory paths (children) -- resolved from registry root on disk

**4a-2. Content View (right pane)**

`AssetContentAdapter : ListAdapterBase` showing items in the selected directory.
Each row shows: icon (by extension), name, and a registry badge if the item
has a GUID in the active registry.

Items come from **both** the filesystem (files in the directory) and the
registry (GUID-mapped entries whose relative path starts with the current
folder prefix). Filesystem items without a registry entry appear unmarked.
Registry entries pointing to missing files appear with a warning indicator.

Initial view mode: list only. Grid/tile view deferred to Phase 4e.

**4a-3. Navigation**

- Click folder in content view -> navigate into it (update path, rebuild adapter)
- Breadcrumb bar above content view showing current path segments (clickable)
- Back button or breadcrumb click to navigate up
- Double-click asset -> open in appropriate editor page (via `IEditorPageFactory`)

**4a-4. Panel Wiring**

- `AssetBrowserPanel : IEditorPanel` -- replaces placeholder in EditorApplication
- `AssetBrowserPanelFactory : IEditorPanelFactory` -- registered with EditorContext
- Panel stores reference to `ResourceSystem` (for registry access) and `EditorContext`

**Files:**

| File | Change |
|------|--------|
| `Editor.Core/src/Panels/AssetBrowserPanel.bf` | NEW -- panel implementation |
| `Editor.App/src/Panels/AssetBrowserBuilder.bf` | NEW -- builds split layout |
| `Editor.App/src/Panels/RegistryTreeAdapter.bf` | NEW -- ITreeAdapter for registries |
| `Editor.App/src/Panels/AssetContentAdapter.bf` | NEW -- ListAdapterBase for content |
| `Editor.App/src/Panels/AssetBrowserPanelFactory.bf` | NEW -- factory |
| `Editor.App/src/EditorApplication.bf` | MODIFY -- replace placeholder with real panel |

#### Phase 4b: Registry Management

**Goal:** Mount, create, and unmount registries from the asset browser.

**4b-1. Registry Toolbar**

Toolbar above the registry tree with buttons:
- **Mount** -- `IDialogService.ShowOpenFileDialog` for `.registry` files -> creates `ResourceRegistry`, loads file, adds to `ResourceSystem`
- **Create** -- `IDialogService.ShowFolderDialog` -> creates empty `.registry` file in selected folder, mounts it with user-provided name
- **Unmount** -- removes selected registry from `ResourceSystem` (disabled for builtin/project)

**4b-2. Registry Persistence**

Mounted registries (beyond builtin/project) stored in `.sedproj` so they
restore on project reopen. Format: list of `{name, rootPath, registryFilePath}`.

**4b-3. Locked Registries**

Builtin and project registries cannot be unmounted. The unmount button is
disabled when they're selected. Their tree nodes may show a lock icon.

**Files:**

| File | Change |
|------|--------|
| `Editor.Core/src/Project/EditorProject.bf` | MODIFY -- persist mounted registries |
| `Editor.App/src/Panels/AssetBrowserBuilder.bf` | MODIFY -- registry toolbar |
| `Editor.App/src/EditorApplication.bf` | MODIFY -- restore mounted registries on load |

#### Phase 4c: Context Menus & File Operations

**Goal:** Right-click menus for items, folders, and empty space.

**4c-1. Item Context Menu**

Right-click on a file/asset in the content view:
- **Rename** -- inline edit (like hierarchy rename)
- **Delete** -- confirmation dialog, removes file + unregisters from registry
- **Copy Path** -- copies protocol path to clipboard (e.g. `project://models/cube.mesh`)
- **Copy GUID** -- copies GUID string to clipboard
- **Find References** -- (stub for now, future: scan scene files for this GUID)
- **Reimport** -- (only for resources with SourcePath, triggers re-import)
- **Show in Explorer** -- opens OS file browser at file location

**4c-2. Folder / Empty Space Context Menu**

Right-click on folder or empty area:
- **Create New ->** submenu dynamically populated from `EditorContext.GetAssetCreators()`
  - Each `IAssetCreator` provides `DisplayName`, `Category`, `Extension`
  - Categories become submenus: "Create New -> Rendering -> Material"
- **Create Folder** -- creates subdirectory, refreshes view
- **Import...** -- opens file dialog filtered by all registered importer extensions
- **Paste** -- (future: clipboard file operations)

**4c-3. Asset Creator Registration**

Built-in creators registered by editor modules:
- `MaterialAssetCreator` -- creates default `.material` file
- `SceneAssetCreator` -- creates empty `.scene` file
- Future modules add their own (audio clips, particle effects, etc.)

Each creator: creates the resource, saves to disk, registers GUID in the
active registry, refreshes the content view.

**Files:**

| File | Change |
|------|--------|
| `Editor.App/src/Panels/AssetBrowserBuilder.bf` | MODIFY -- context menus |
| `Editor.App/src/Assets/MaterialAssetCreator.bf` | NEW -- IAssetCreator impl |
| `Editor.App/src/Assets/SceneAssetCreator.bf` | NEW -- IAssetCreator impl |
| `Editor.App/src/EditorApplication.bf` | MODIFY -- register built-in creators |

#### Phase 4d: Asset Import Pipeline

**Goal:** Import source files into baked engine resources via UI.

**4d-1. Redesigned IAssetImporter Interface**

Replace the current simple `Import(sourcePath, outputPath)` with a richer
interface that supports multi-resource preview and import:

```beef
interface IAssetImporter : IDisposable
{
    /// File extensions this importer handles (e.g. ".gltf", ".glb", ".fbx").
    void GetSupportedExtensions(List<String> outExtensions);

    /// Analyze source file and return list of importable items.
    /// Called before showing the import dialog so user can preview/configure.
    Result<ImportPreview> CreatePreview(StringView sourcePath);

    /// Import selected items from the preview.
    /// outputDir is the target directory, registry is for GUID registration.
    Result<void> Import(ImportPreview preview, StringView outputDir,
        ResourceRegistry registry, ImportDeduplicationContext dedupContext);
}

/// One importable item from a source file.
class ImportPreviewItem
{
    public String Name;                // Suggested filename (editable)
    public String TypeLabel;           // "Static Mesh", "Texture", etc.
    public ResourceType ResourceType;  // For icon selection
    public bool Selected = true;       // Checkbox state
}

/// Preview of what an import will produce.
class ImportPreview
{
    public String SourcePath;
    public List<ImportPreviewItem> Items;
    public ModelImportOptions Options;  // Null for non-model importers
}
```

Simple importers (texture) return a single-item preview. Model importers
return many items. The import dialog works the same for both.

**4d-2. Import Dialog**

When the user drops files or clicks "Import...", show a dialog:
- Source file path (read-only)
- List of resources from `CreatePreview()` (checkboxes to include/exclude)
  - For a `.gltf`: meshes, materials, textures, skeletons, animations
  - For a `.png`: single texture resource
- Each item shows: type icon, suggested name, output path (editable)
- "Import All to Folder..." button to set a common output directory
- Import options panel (scale, normals, tangents -- from `ModelImportOptions`)
- Target registry shown (the registry whose content view triggered the import)
- Deduplication warnings: "Texture 'wood.png' already exists -- skip/reimport/rename"
- **Import** / **Cancel** buttons

**4d-3. Import Execution**

On **Import**:
1. Call `importer.Import(preview, outputDir, registry, dedupContext)`
2. Internally: load source, run pipeline, save checked items, register GUIDs
3. Write `.meta` sidecar file for each imported resource (see 4d-6)
4. Save registry to disk
5. Refresh content view

**4d-4. Importer Implementations**

Registered with `EditorContext.RegisterAssetImporter()`:

- **ModelAssetImporter** -- handles `.gltf`, `.glb`, `.fbx`, `.obj`
  - `CreatePreview`: loads via `ModelLoaderFactory`, runs `ModelImporter.Import`,
    enumerates all produced meshes/materials/textures/skeletons/animations
  - `Import`: converts to resources, saves via `ResourceSerializer`, registers GUIDs
- **TextureAssetImporter** -- handles `.png`, `.jpg`, `.jpeg`, `.tga`, `.bmp`, `.hdr`
  - `CreatePreview`: single item -- the texture resource
  - `Import`: loads via `ImageLoaderFactory`, wraps as `TextureResource`, saves
- **AudioAssetImporter** -- (stub, future: `.wav`, `.ogg` -> `.audioclip`)

**4d-5. Drag-Drop Import**

Content view implements `IDropTarget`. When files are dropped from OS:
1. Check extensions against registered importers
2. If importer found -> call `CreatePreview()` -> show import dialog
3. If no match -> copy file as-is (raw asset, no registry entry)
4. If multiple files -> batch import dialog (one preview per file)

**4d-6. Import Metadata (.meta sidecar files)**

Each imported resource gets a `.meta` sidecar file alongside it
(e.g. `cube.mesh.meta`). Plain text format:

```
source=D:/Models/character.gltf
sourceHash=a1b2c3d4e5f6
importOptions.scale=1.0
importOptions.generateNormals=true
importTimestamp=2026-04-27T15:30:00
```

**Benefits:** per-file locality (travels with asset), easy to inspect,
git-friendly, no lock contention on concurrent imports.

**Used for:** re-import (detect source changes via hash), preserving import
options across re-imports, tracking provenance.

**4d-7. Deduplication**

Before import, build `ImportDeduplicationContext` from existing registry
entries by scanning resources with matching `SourcePath` values. Dialog
shows conflicts with skip/reimport/rename choices per item.

**Files:**

| File | Change |
|------|--------|
| `Editor.Core/src/Assets/IAssetImporter.bf` | MODIFY -- redesigned interface |
| `Editor.Core/src/Assets/ImportPreview.bf` | NEW -- preview items and options |
| `Editor.App/src/Assets/ModelAssetImporter.bf` | NEW -- IAssetImporter for models |
| `Editor.App/src/Assets/TextureAssetImporter.bf` | NEW -- IAssetImporter for textures |
| `Editor.App/src/Assets/ImportDialog.bf` | NEW -- import preview/config UI |
| `Editor.App/src/Assets/ImportMetadata.bf` | NEW -- .meta file read/write |
| `Editor.App/src/Panels/AssetBrowserBuilder.bf` | MODIFY -- IDropTarget, import trigger |
| `Editor.App/src/EditorApplication.bf` | MODIFY -- register built-in importers |

#### Phase 4e: Thumbnails & Grid View

**Goal:** Visual asset browsing with thumbnails and tile layout.

**4e-1. Custom GridContentView**

Purpose-built `GridContentView : ViewGroup` for the asset browser:
- Flow layout: fixed-size cells, wrap on container width, reflow on resize
- Each cell: thumbnail `ImageView` + name `Label` below
- `ViewRecycler` for virtualization (only create/bind visible cells)
- Vertical scrolling with momentum (same physics as `ListView`)
- `SelectionModel` integration: click, shift-click, ctrl-click
- Right-click -> `OnItemRightClicked` event (same pattern as `ListView`)
- Double-click -> `OnItemDoubleClicked` event
- Cell size configurable (small/medium/large via slider or presets)

View mode switcher: `ToggleButton` group in content toolbar (List | Grid).
Both modes use the same `AssetContentAdapter` data, different presentation.

**4e-2. Thumbnail Generators**

Per-type generators registered with `EditorContext.RegisterThumbnailGenerator()`:
- **TextureThumbnailGenerator** -- downsample the texture's pixel data
- **MeshThumbnailGenerator** -- (future: render mesh to small offscreen target)
- **MaterialThumbnailGenerator** -- (future: render sphere with material)
- **Default** -- icon by file extension (gear for .material, cube for .mesh, etc.)

**4e-3. Thumbnail Cache**

Thumbnails cached to disk in project's `.cache/thumbnails/` directory.
Cache key: resource GUID + file modification time. Regenerate on mismatch.

**Files:**

| File | Change |
|------|--------|
| `Editor.App/src/Panels/GridContentView.bf` | NEW -- grid layout view |
| `Editor.App/src/Assets/TextureThumbnailGenerator.bf` | NEW |
| `Editor.App/src/Assets/ThumbnailCache.bf` | NEW -- disk cache |
| `Editor.App/src/Panels/AssetBrowserBuilder.bf` | MODIFY -- view mode toggle |

#### Phase 4f: Drag into Scene & Asset Preview

**Goal:** Drag assets from browser into viewport/hierarchy to create entities.

**4f-1. Drag from Browser**

Content view items implement `IDragSource`. Drag data carries the resource's
protocol path and type. Format: `"asset/resource"`.

**4f-2. Drop Targets**

- **Viewport** -- drop mesh -> create entity at camera look-at point with MeshComponent
- **Hierarchy** -- drop mesh -> create entity as child of drop target
- **Inspector material slot** -- drop material -> assign to slot
- **Inspector texture slot** -- drop texture -> assign to slot

**4f-3. Asset Inspector**

When an asset is selected in the browser (not a scene entity), the inspector
shows asset properties (read-only or editable depending on type). Uses the
same `IComponentInspector` pattern but for resources instead of components.

**Files:**

| File | Change |
|------|--------|
| `Editor.App/src/Panels/AssetDragData.bf` | NEW -- DragData subclass |
| `Editor.App/src/Panels/AssetContentAdapter.bf` | MODIFY -- IDragSource |
| `Editor.App/src/Pages/ScenePageBuilder.bf` | MODIFY -- viewport IDropTarget |
| `Editor.App/src/Pages/SceneHierarchyView.bf` | MODIFY -- accept asset drops |

#### Phase 4 Dependencies

```
4a (Browser Core UI)
  |
  v
4b (Registry Mgmt) --- can parallel with 4c
  |                           |
  v                           v
4c (Context Menus) <----------+
  |
  v
4d (Import Pipeline)
  |
  v
4e (Thumbnails & Grid) --- can parallel with 4f
  |                              |
  v                              v
4f (Drag into Scene) <-----------+
```

Phases 4a-4d are the core functional path. 4e-4f are enhancement/polish.

### Phase 5: Scene Gizmos - PARTIAL

**Done:**
- ✅ EditorCamera (independent of scene entities, uses CameraOverride)
- ✅ Viewport toolbar (Translate/Rotate/Scale toggles, World/Local toggle)
- ✅ IViewportInputHandler chain (gizmo priority before camera)
- ✅ TransformGizmo: translate (arrows), rotate (rings), scale (boxes+lines)
- ✅ Mode-aware hover detection (axis lines for translate/scale, ring proximity for rotate)
- ✅ Drag interaction with undo (SetTransformCommand with old/new transforms)
- ✅ Local/World orientation (gizmo axes follow entity rotation or world)
- ✅ Constant screen-size scaling (gizmo scales with camera distance)

**Remaining:**

**5a. Entity selection picking - DONE**
- ✅ GPU pick pass (PickPass): renders entity indices as RGBA8 colors, async 2-frame readback
- ✅ RHI: Origin3D + TextureOrigin on BufferTextureCopyRegion for sub-texture copy (Vulkan/DX12)
- ✅ MeshRenderData.EntityIndex set during extraction (static + skinned meshes)
- ✅ Pick shaders (pick.vert/frag.hlsl): entity index encoded as color, +1 offset so 0 = background
- ✅ GizmoInputHandler: GPU pick on LMB click, CPU proxy sphere fallback for non-mesh entities
- ✅ Selection syncs to hierarchy view via OnSelectionChanged
- Shift+click multi-select not yet implemented

**5b. Inspector live update during gizmo drag**
- Transform Vector3Editors don't refresh while dragging
- Need either polling mechanism on editors or OnSelectionChanged on drag end
- Currently must click away and back to see updated values

**5c. W/E/R keyboard shortcuts for gizmo mode**
- Toolbar buttons work but no keyboard shortcuts to switch modes
- Should be handled at viewport level (OnKeyDown in ViewportView or handler)

**5d. Snap**
- Hold Ctrl for grid snap (translate), angle snap (rotate), step snap (scale)
- Snap size configurable via toolbar or settings

**5e. Component gizmos**
- `IGizmoRenderer` per component type (registered by editor modules)
- Light: directional arrow, point sphere, spot cone
- Camera: frustum wireframe
- Collider: wireframe shapes (box, sphere, capsule)
- Draw via `GizmoContext` which wraps DebugDraw
- `DrawWhenUnselected` flag for always-visible gizmos (lights, cameras)

**5f. Intermittent undock drag bug**
- Occasionally LMB drag on gizmo triggers dock panel undock instead
- Likely mouse capture timing issue - gizmo capture may fail or release early
- Needs investigation to reproduce reliably

### Phase 6: Play Mode
- `EditorSceneManager` - serialize/restore scene around play
- Play/Pause/Stop controls
- Inspector read-only during play

### Phase 7: Per-Module Plugins
- Physics: ColliderInspector, ColliderGizmo, PhysicsDebugPanel
- Render: MaterialEditorPage, LightGizmo, CameraFrustumGizmo
- Audio: AudioSourceInspector, AudioPreview
- Animation: CurveEditor, TimelinePanel
- Navigation: NavMeshDebugPanel, "Bake NavMesh" menu item

## Editor Modules Architecture

Each engine domain (physics, audio, animation, navigation) gets a paired editor
module project that provides both runtime registration and editor extensions.

**Project structure:**
```
Editor/
  Sedulous.Editor.Core/        -- core editor framework (existing)
  Sedulous.Editor.App/         -- editor application (existing)
  Sedulous.Editor.Render/      -- render component inspectors, gizmos
  Sedulous.Editor.Physics/     -- physics inspectors, collider gizmos
  Sedulous.Editor.Audio/       -- audio inspectors, source gizmos
  Sedulous.Editor.Animation/   -- animation inspectors, skeleton gizmos
  Sedulous.Editor.Navigation/  -- navmesh inspectors, agent gizmos
```

**Registration flow:**
Each editor module implements a registration method that receives both the
RuntimeContext and EditorContext. It registers:
1. The runtime subsystem with RuntimeContext (so scenes get component managers)
2. Component inspectors, gizmo renderers, asset importers with EditorContext

```
EditorApplication.OnInitialize():
  // Always needed
  runtimeContext.RegisterSubsystem(new SceneSubsystem())
  runtimeContext.RegisterSubsystem(new RenderSubsystem())

  // Editor modules register runtime + editor parts
  EditorPhysicsModule.Register(runtimeContext, editorContext)
    -> runtimeContext.RegisterSubsystem(new PhysicsSubsystem())
    -> editorContext.RegisterComponentInspector(typeof(RigidBodyComponent), ...)
    -> editorContext.RegisterGizmoRenderer(typeof(RigidBodyComponent), ...)

  EditorAudioModule.Register(runtimeContext, editorContext)
    -> runtimeContext.RegisterSubsystem(new AudioSubsystem())
    -> editorContext.RegisterComponentInspector(typeof(AudioSourceComponent), ...)

  runtimeContext.Startup()
```

**Benefits:**
- Editor stays modular -- build without physics by not registering the module
- Runtime and editor parts are co-located in one project per domain
- Scenes get all component types from registered modules via ISceneAware
- ComponentTypeRegistry fallback not needed -- subsystems inject managers
- Full round-trip: scenes saved by the editor preserve all component types
- Plugins can add new component types by following the same pattern

**Current state:** Only SceneSubsystem + RenderSubsystem registered. Other
engine subsystems not yet available in the editor. Scenes saved from the
editor will only contain render components (mesh, camera, light). Loading
scenes with physics/audio/animation components will silently skip those
components until their editor modules are registered.

## Prerequisites

- ~~**RenderSubsystem refactor**~~: ISceneRenderer/IOverlayRenderer, swapchain
  ownership moved to EngineApplication - **DONE**
- **Sedulous.UI.Toolkit**: DockManager, SplitView, MenuBar, StatusBar, Toolbar,
  PropertyGrid, TreeView - all complete
- **Sedulous.Engine.UI**: EngineUISubsystem, ScreenUIView - complete
- **Sedulous.Engine.Render**: RenderSubsystem, render pipeline - complete
- **Sedulous.Engine.Core**: ComponentManager, Scene serialization - complete
- **Sedulous.Resources**: ResourceSystem with FileWatcher - complete
