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

### Phase 3: Gizmos & Polish
- `IGizmoRenderer`, `GizmoContext` (interfaces done, rendering not wired)
- Transform gizmo (translate/rotate/scale)
- Selection picking (raycast in viewport)
- Cross-window drag routing (move OS windows during dock panel drag)

### Phase 4: Asset Pipeline
- `IAssetImporter`, `IAssetThumbnailGenerator`
- Asset browser with file watching + hot reload
- `IAssetCreator` for "Create New" menus

### Phase 5: Play Mode
- `EditorSceneManager` - serialize/restore scene around play
- Play/Pause/Stop controls
- Inspector read-only during play

### Phase 6: Per-Module Plugins
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
