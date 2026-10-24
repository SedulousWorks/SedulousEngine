// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - the `engine.gui` module: the engine's GUI on foundation.gui (E5 of
// Specs/gui-lab-evolution-3.md), Engine.UI's counterpart, beside it while both live.
//
// GuiResourceProvider answers the GUI's resource requests by asset guid ("{guid}" or the bare
// guid), as every other reference in the engine: a document's markup and a sheet's CSS from their
// cooked products, an SVG from a vector image, an image from a texture (a render texture a camera
// draws into among them). The markup, the sheets and the gamekit need no change: they ask by string
// as they do in the sandbox.
//
// GuiSubsystem: one GUIContext and style manager for the application, the GUI's built-in theme
// under the game's sheets (a list, in order, each an @import of its guid), the fonts; a screen tier
// (a root holding the gamekit's screen stack and an overlay layer above it, outside any scene, so
// it survives a scene swap) and a scene tier (a root per scene, drawn wherever the scene renders);
// both drawn into the engine's overlay passes through GUI.Hosting's GuiPassRenderer, above
// Engine.UI's. A sheet or document whose cooked product changes restyles the GUI (hot reload). The
// GUI ticks on unscaled time (menus move while the game is paused), so its work is in BeginFrame.
//
// Input (E6): the engine's active input source (the player's window, an editor Game tab's view)
// into one root a frame, through GUI.Shell's bridge (one per root, each root its own dispatcher): an
// occupied overlay layer is modal; else the root whose GUI is under the pointer (the screen tier
// first); else the screen tier while it holds a screen; else the first scene root with content. A
// press stays with its root until every button is up. Which scenes input may reach follows the input
// subsystem's binding, as Engine.UI's does. The action layer is told what the GUI took (the pointer
// over GUI that takes it, or a press that began there; the keys while text is being edited), added
// to what Engine.UI claims; the GUI tracks the input kind from the same source.
//
// Components (E7): `gui.Canvas` shows a document (with a sheet of its own over the game's) in its
// scene's root, ordered among the scene's canvases, at the target's pixels or scaled from a
// reference resolution to fit; despawned, its tree goes; a re-cooked document rebuilds it.
// `gui.Billboard` shows a document over its entity (a nameplate, a health bar), in a layer under
// the scene's canvases, placed through each view's camera as it draws: hung by its bottom centre on
// the projected point, hidden behind the camera, scaled with distance when asked. A canvas may
// draw into a texture instead (a screen in the world, its entity's sprite or decal showing it), and
// `gui.WorldPanel` shows a document on a quad in its entity's plane, its sprite driven, the pointer
// reaching it by a ray through the scene's camera. Both draw in RenderTextures, which the host calls
// before the scene, after the frame's bakes.
//
// The script surface (E8): the GUI's own (the `gui` facade, every widget reflected, the gamekit's
// stack), installed per script context with the screen tier's root (ExposeToScript): `gui::root()`
// is the screen root and `ScreenStack::of(gui::root().find("screens"))` its stack, which pushes a
// document by its guid ("{guid}") through the provider. Each component's `.of(entity)` reaches its
// tree as a node (`root()`).
//
// The game's screen (E9c): the screen tier lays out at the game's render resolution and draws, at
// the target's own, into the rectangle that size is fitted into, turned when the game's orientation
// is not the target's, as the game's image is (Engine.UI's placement); its pointer arrives in render
// space and is taken to its pixels. With run screens on (the editor), each run (a Game tab's game)
// has a screen tier of its own: drawn for its tab (SetRenderRun), the input of the scene it is
// bound to, the `gui` root of its scripts; the overlay layer stays on the shared tier above it.
// GCC modules hygiene: the renderer, the shaders and the textures live in GuiSubsystemImpl.cpp.

module;
#include "Core/Prelude.h"

export module engine.gui;

import foundation.core;
import engine.domain;
import foundation.runtime;
import foundation.scene;
import engine.scene;
import foundation.resource;
import foundation.rhi;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.resource; // the project's fonts (Font products)
import foundation.image;
import foundation.vg.svg;
import foundation.render.api; // the two overlay roles
import foundation.script;     // the script contexts the surface is installed in
import foundation.shell;      // the text input target
import foundation.input;      // InputKindTracker
import engine.input;          // the active input source, the action runtimes
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.resources; // the documents and sheets components name
import foundation.gui.shell;     // GuiInputBridge

using namespace foundation::core;
using namespace foundation::gui;
namespace rhi = foundation::rhi;

export namespace engine::gui
{
    namespace render = foundation::render;
    namespace scene = foundation::scene;
    namespace resource = foundation::resource;
    namespace image = foundation::image;

    // ---- components ----

    enum class GuiScalerMode : u8
    {
        ConstantPixel = 0,   ///< one GUI pixel a target pixel
        ReferenceResolution, ///< laid out at the reference resolution, scaled uniformly to fit, centred
    };

    enum class GuiCanvasRenderMode : u8
    {
        ScreenOverlay = 0, ///< in its scene's GUI, over the view
        RenderTexture,     ///< into a texture of its own (its entity's sprite or decal shows it)
    };

    /// A document shown in its scene's GUI: a menu, a HUD. Spawned it opens, despawned it closes.
    struct GuiCanvasComponent
    {
        // Authored:
        resource::Ref<GuiDocument> document;
        resource::Ref<GuiStyleSheet> sheet; ///< over the game's sheets, for this canvas alone (optional)
        i32 order = 0;                           ///< among the scene's canvases: higher on top
        bool visible = true;
        bool interactive = true;
        GuiScalerMode scalerMode = GuiScalerMode::ConstantPixel;
        Float2 referenceResolution{1920.0f, 1080.0f};
        GuiCanvasRenderMode renderMode = GuiCanvasRenderMode::ScreenOverlay;
        u32 renderTextureWidth = 512; ///< RenderTexture: the texture's size, in pixels
        u32 renderTextureHeight = 512;

        // Runtime:
        RefPtr<Node> root;       ///< the tree built from the document
        RefPtr<UIWidget> host;   ///< its place in the scene's root (order, scaler)
        RefPtr<Object> builtFrom;     ///< the document product it was built from (held: a new one never takes its address)
        RefPtr<Object> sheetFrom;     ///< the sheet product applied
        RefPtr<SceneRoot> renderRoot;     ///< RenderTexture: its own root, never in a scene's GUI
        rhi::Texture* renderTexture = nullptr; ///< RenderTexture: the texture (the subsystem's), once drawn
        rhi::TextureView* renderTextureView = nullptr;

        /// Its tree as a script's node handle (`root()`); null before it is built.
        [[nodiscard]] foundation::core::Variant rootNode() const;
    };

    inline void Serialize(ISerializer& ar, GuiCanvasComponent& c)
    {
        foundation::core::Serialize(ar, "document", c.document);
        foundation::core::Serialize(ar, "sheet", c.sheet);
        foundation::core::Serialize(ar, "order", c.order);
        foundation::core::Serialize(ar, "visible", c.visible);
        foundation::core::Serialize(ar, "interactive", c.interactive);
        u8 scaler = static_cast<u8>(c.scalerMode);
        foundation::core::Serialize(ar, "scalerMode", scaler);
        c.scalerMode = static_cast<GuiScalerMode>(scaler);
        foundation::core::Serialize(ar, "referenceResolution", c.referenceResolution);
        u8 render = static_cast<u8>(c.renderMode);
        foundation::core::Serialize(ar, "renderMode", render);
        c.renderMode = static_cast<GuiCanvasRenderMode>(render);
        foundation::core::Serialize(ar, "renderTextureWidth", c.renderTextureWidth);
        foundation::core::Serialize(ar, "renderTextureHeight", c.renderTextureHeight);
    }

    inline void ResolveResources(resource::ResourceManager& manager, GuiCanvasComponent& c)
    {
        c.document.Bind(manager);
        c.sheet.Bind(manager);
    }

    class GuiCanvasComponentManager final : public scene::SerializableComponentManager<GuiCanvasComponent>
    {
    public:
        GuiCanvasComponentManager() : SerializableComponentManager<GuiCanvasComponent>(u8"gui.Canvas") {}
    };

    enum class GuiBillboardOrientation : u8
    {
        Screen = 0,  ///< the offset in the entity's own space (it turns with the entity)
        Cylindrical, ///< the offset in world space (a fixed lift above the entity)
    };
    enum class GuiBillboardScale : u8
    {
        Fixed = 0, ///< the same size at any distance
        Distance,  ///< referenceDistance / distance, within minScale and maxScale
    };

    /// A document over its entity, facing the view: a nameplate, a health bar.
    struct GuiBillboardComponent
    {
        // Authored:
        resource::Ref<GuiDocument> document;
        resource::Ref<GuiStyleSheet> sheet; ///< over the game's sheets, for this billboard alone (optional)
        Float3 offset{0.0f, 0.0f, 0.0f};
        GuiBillboardOrientation orientation = GuiBillboardOrientation::Cylindrical;
        GuiBillboardScale scaleMode = GuiBillboardScale::Fixed;
        f32 referenceDistance = 10.0f;
        f32 minScale = 0.3f;
        f32 maxScale = 2.0f;
        bool visible = true;

        // Runtime:
        RefPtr<Node> root;
        RefPtr<Object> builtFrom;
        RefPtr<Object> sheetFrom;

        /// Its tree as a script's node handle (`root()`); null before it is built.
        [[nodiscard]] foundation::core::Variant rootNode() const;
    };

    inline void Serialize(ISerializer& ar, GuiBillboardComponent& c)
    {
        foundation::core::Serialize(ar, "document", c.document);
        foundation::core::Serialize(ar, "sheet", c.sheet);
        foundation::core::Serialize(ar, "offset", c.offset);
        u8 orientation = static_cast<u8>(c.orientation);
        foundation::core::Serialize(ar, "orientation", orientation);
        c.orientation = static_cast<GuiBillboardOrientation>(orientation);
        u8 scale = static_cast<u8>(c.scaleMode);
        foundation::core::Serialize(ar, "scaleMode", scale);
        c.scaleMode = static_cast<GuiBillboardScale>(scale);
        foundation::core::Serialize(ar, "referenceDistance", c.referenceDistance);
        foundation::core::Serialize(ar, "minScale", c.minScale);
        foundation::core::Serialize(ar, "maxScale", c.maxScale);
        foundation::core::Serialize(ar, "visible", c.visible);
    }

    inline void ResolveResources(resource::ResourceManager& manager, GuiBillboardComponent& c)
    {
        c.document.Bind(manager);
        c.sheet.Bind(manager);
    }

    class GuiBillboardComponentManager final : public scene::SerializableComponentManager<GuiBillboardComponent>
    {
    public:
        GuiBillboardComponentManager() : SerializableComponentManager<GuiBillboardComponent>(u8"gui.Billboard") {}
    };

    /// A document on a quad in the world, in its entity's plane (a sign, a terminal): drawn into a
    /// texture at a density of its own, its entity's sprite driven to show it (added when missing),
    /// so it sits in the scene with its depth; the pointer reaches it by a ray when interactive.
    struct GuiWorldPanelComponent
    {
        // Authored:
        resource::Ref<GuiDocument> document;
        resource::Ref<GuiStyleSheet> sheet; ///< over the game's sheets, for this panel alone (optional)
        Float2 sizeMeters{1.6f, 0.9f};           ///< the quad's extent in the world
        f32 pixelsPerMeter = 200.0f;             ///< the texture's density
        bool interactive = true;
        bool visible = true;

        // Runtime:
        RefPtr<Node> root;
        RefPtr<SceneRoot> renderRoot; ///< its own root, never in a scene's GUI
        RefPtr<Object> builtFrom;
        RefPtr<Object> sheetFrom;
        rhi::Texture* renderTexture = nullptr; ///< the subsystem's, once drawn
        rhi::TextureView* renderTextureView = nullptr;

        /// Its tree as a script's node handle (`root()`); null before it is built.
        [[nodiscard]] foundation::core::Variant rootNode() const;
    };

    inline void Serialize(ISerializer& ar, GuiWorldPanelComponent& c)
    {
        foundation::core::Serialize(ar, "document", c.document);
        foundation::core::Serialize(ar, "sheet", c.sheet);
        foundation::core::Serialize(ar, "sizeMeters", c.sizeMeters);
        foundation::core::Serialize(ar, "pixelsPerMeter", c.pixelsPerMeter);
        foundation::core::Serialize(ar, "interactive", c.interactive);
        foundation::core::Serialize(ar, "visible", c.visible);
    }

    inline void ResolveResources(resource::ResourceManager& manager, GuiWorldPanelComponent& c)
    {
        c.document.Bind(manager);
        c.sheet.Bind(manager);
    }

    class GuiWorldPanelComponentManager final : public scene::SerializableComponentManager<GuiWorldPanelComponent>
    {
    public:
        GuiWorldPanelComponentManager() : SerializableComponentManager<GuiWorldPanelComponent>(u8"gui.WorldPanel") {}
    };

    /// A world panel's texture in pixels (its content, at its density, within GPU-friendly limits).
    [[nodiscard]] Float2 WorldPanelPixels(const GuiWorldPanelComponent& panel) noexcept;

    /// The world ray under `pointer` (pixels) on a view of `viewSize` through `camera` (unjittered),
    /// from the near plane, between the engine's NDC depths. (Engine.UI keeps the same math for its
    /// panels while it lives.)
    void GuiPointerRay(const render::ViewCamera& camera, Float2 pointer, Float2 viewSize, Float3& origin, Float3& direction) noexcept;

    struct GuiPanelHit
    {
        bool Hit = false;
        f32 Distance = 0.0f; ///< along the ray
        Float2 Uv{0.0f, 0.0f}; ///< 0 to 1 across the panel, v down as a GUI's pixels
    };
    /// The ray against a panel of `sizeMeters` in the plane of `panelWorld` (its right and up span
    /// it; either face is hit).
    [[nodiscard]] GuiPanelHit RayHitGuiPanel(Float3 origin, Float3 direction, const Float4x4& panelWorld, Float2 sizeMeters) noexcept;

    /// Where a billboard shows in a view: the point it hangs from (its bottom centre), in the
    /// view's pixels, and its scale; not shown when the point is behind the camera.
    struct GuiBillboardPlacement
    {
        bool Shown = false;
        Float2 Anchor{0.0f, 0.0f};
        f32 Scale = 1.0f;
    };
    /// `billboard` on an entity at `entityWorld`, seen through `viewProjection` (unjittered) from
    /// `cameraPosition` in a view of `viewport` pixels.
    [[nodiscard]] GuiBillboardPlacement PlaceBillboard(const GuiBillboardComponent& billboard, const Float4x4& entityWorld,
                                                       const Float4x4& viewProjection, Float3 cameraPosition, Float2 viewport) noexcept;

    /// The components' reflection (the inspector, the scene format). Idempotent.
    void RegisterGuiComponentReflection();
    /// The GUI's script surface: the GUI's (`gui`, the widgets, the gamekit's) and each component's
    /// `.of(entity)`, with their names in the behaviour prelude. Idempotent; before a script
    /// manager binds the registry.
    void RegisterGuiScriptFacades();

    /// The GUI's managers for a scene: the subsystem's scenes and headless scene consumers alike
    /// (Engine.Composition).
    inline void AddGuiSceneManagers(scene::Scene& scene)
    {
        scene.AddSystem<GuiCanvasComponentManager>();
        scene.AddSystem<GuiBillboardComponentManager>();
        scene.AddSystem<GuiWorldPanelComponentManager>();
    }

    /// Where a screen tier draws on its target (Engine.UI's ScreenPlacement): not fitted, the plain
    /// draw at the target's own size over all of it; fitted, the root lays out at `DrawSize` over
    /// its display scale `DpiScale` and draws into `Rect` of the target through `Transform`, which
    /// turns the root's pixels onto the rectangle's (identity unless the orientation turns it).
    struct GuiScreenPlacement
    {
        bool Fitted = false;
        ContentRotation Turn = ContentRotation::None;
        Rectangle Rect{0.0f, 0.0f, 0.0f, 0.0f};
        Float2 DrawSize{0.0f, 0.0f};
        f32 DpiScale = 1.0f;
        Float4x4 Transform = Float4x4::Identity();
    };

    /// The GUI's resources by asset guid, through the application's resource manager.
    class GuiResourceProvider final : public IResourceProvider
    {
    public:
        /// Told when an image key starts or stops standing for a texture (`view` null: it stops):
        /// the renderers that draw the GUI.
        using TextureSink = Function<void(const image::ImageData* key, rhi::TextureView* view)>;

        explicit GuiResourceProvider(IAllocator& allocator);
        ~GuiResourceProvider() override;
        GuiResourceProvider(const GuiResourceProvider&) = delete;
        GuiResourceProvider& operator=(const GuiResourceProvider&) = delete;

        /// Where the guids resolve; null (between projects) resolves nothing. Another manager lets
        /// go of what was bound: an image key stays valid for what holds it and stops showing.
        /// Borrowed.
        void SetResourceManager(resource::ResourceManager* resources);
        [[nodiscard]] resource::ResourceManager* GetResourceManager() const noexcept;
        /// The renderers' sink; told at once of every key that stands for a texture now.
        void SetTextureSink(TextureSink sink);

        /// A texture's image: one key per texture, its natural size the texture's.
        [[nodiscard]] const image::ImageData* LoadImage(StringView path) override;
        /// A document's markup or a sheet's CSS.
        [[nodiscard]] bool LoadText(StringView path, String& out) override;
        /// A vector image's picture, parsed once per product.
        [[nodiscard]] const foundation::vg::svg::SVGDocument* LoadSvg(StringView path) override;

        /// Brings what was read in line with the current products (a re-cook, a failed load): true
        /// when a document or sheet read before has changed since the last poll.
        bool Poll();

        /// The guid `path` names ("{guid}" or bare); false when it names none.
        [[nodiscard]] static bool ParseGuid(StringView path, Guid& out) noexcept;

    private:
        struct State;
        UniquePtr<State> m_state;
    };

    class GuiSubsystem final : public foundation::runtime::Subsystem,
                               public scene::ISceneObserver,
                               public render::ISceneOverlay,
                               public render::IScreenOverlay
    {
    public:
        /// `dataFileSystem` is the application's data mount (borrowed for the subsystem's life):
        /// the VG shaders and the built-in font come from it.
        GuiSubsystem(IAllocator& allocator, foundation::vfs::IFileSystem& dataFileSystem);
        ~GuiSubsystem() override;

        /// After Engine.UI's (-650), so a game's GUI sees the same frame; all work in BeginFrame.
        [[nodiscard]] i32 UpdateOrder() const noexcept override { return -640; }

        [[nodiscard]] GUIContext& Context() noexcept { return *m_context; }
        [[nodiscard]] const RefPtr<GUIContext>& ContextRef() const noexcept { return m_context; }
        /// The style manager every root is styled through: the built-in theme, the game's sheets.
        [[nodiscard]] StyleManager& Styles() noexcept { return m_styles; }
        [[nodiscard]] GuiResourceProvider& Resources() noexcept { return *m_resources; }
        /// The fonts the GUI's text draws with.
        [[nodiscard]] foundation::fonts::IFontService* Fonts() const noexcept;

        /// The project's fonts, which it shares with Engine.UI (defaultUiFontId, uiFontIds): the
        /// default and the others, each a family a label picks by `font-family`. Without a default
        /// the built-in font serves (the others wait for one). The products are held.
        void SetFonts(const foundation::fonts::Font* defaultFont, Span<const foundation::fonts::Font* const> others);

        /// Where asset guids resolve (the application's resource manager); null resolves nothing.
        void SetResourceManager(resource::ResourceManager* resources);
        /// The game's sheets, over the built-in theme, each over the ones before it (a game's own
        /// over a shared one). Re-read when one's cooked product changes.
        void SetStyleSheets(Span<const Guid> sheets);
        [[nodiscard]] Span<const Guid> StyleSheets() const noexcept { return Span<const Guid>(m_sheets.Data(), m_sheets.Size()); }
        /// How many times the game's sheets were applied (set, or a cooked product changed).
        [[nodiscard]] u64 SheetGeneration() const noexcept { return m_sheetGeneration; }

        /// The screen tier, outside any scene: its root, the gamekit's screen stack in it, and the
        /// overlay layer above the stack (a loading screen, a system menu).
        [[nodiscard]] SceneRoot* ScreenRoot() noexcept { return m_screen.Root.Get(); }
        [[nodiscard]] ScreenStack* Screens() noexcept { return m_screen.Screens.Get(); }

        // ---- the game's screen ----
        /// The screen tier at the game's render resolution, fitted into its target by `fit`, its
        /// text crisp at the target's resolution; nought on either axis: the target's own size.
        void SetScreenResolution(u32 width, u32 height, FitMode fit);
        [[nodiscard]] bool HasScreenResolution() const noexcept { return m_screen.HasResolution(); }
        /// The game's orientation: on a target of the other shape the screen tier lays out at the
        /// game's shape and draws turned a quarter. Any: never turned.
        void SetScreenOrientation(ScreenOrientation orientation) noexcept { m_screen.Orientation = orientation; }
        /// Where a tier at `resolution` (none: 0 x 0), fitted by `fit` and held to `orientation`,
        /// draws on a `target`-sized target.
        [[nodiscard]] static GuiScreenPlacement PlaceScreen(Float2 resolution, FitMode fit, ScreenOrientation orientation, Float2 target) noexcept;

        // ---- a screen tier per run (the editor's Game tabs) ----
        /// On: each run its own screen tier (the editor sets it once). Off (the player's): one.
        void SetRunScreens(bool enabled) noexcept { m_runScreens = enabled; }
        [[nodiscard]] bool RunScreens() const noexcept { return m_runScreens; }
        /// `run`'s screen stack and root, made on first use; the shared tier's with run screens off
        /// or no run.
        [[nodiscard]] ScreenStack* ScreensFor(const void* run);
        [[nodiscard]] SceneRoot* ScreenRootFor(const void* run);
        void SetScreenResolution(const void* run, u32 width, u32 height, FitMode fit);
        void SetScreenOrientation(const void* run, ScreenOrientation orientation);
        /// The run whose screen tier the next screen overlay draws under the shared one's overlays
        /// (null: none), set by a host around its overlays for that run's view.
        void SetRenderRun(const void* run) noexcept { m_renderRun = run; }
        /// The run ended: its screen tier and every screen on it go.
        void EndRunScreens(const void* run);
        [[nodiscard]] usize RunScreenCount() const noexcept { return m_runTiers.Size(); }
        [[nodiscard]] Node* OverlayLayer() noexcept { return m_overlay.Get(); }
        /// `document` built and shown on the overlay layer, above every screen (a loading screen, a
        /// system menu), modal while it shows, unless it takes no pointer (`pointer-events: none`
        /// on its root: a watermark); the tree, to take off again, or null when it does not build.
        RefPtr<Node> PushOverlay(const GuiDocument& document);
        /// A tree made in code shown on the overlay layer.
        void PushOverlay(Node& overlay);
        void RemoveOverlay(Node& overlay);
        [[nodiscard]] usize OverlayCount() const noexcept { return m_overlay ? m_overlay->ChildCount() : 0; }
        /// The scene tier's root for `scene`; null when the scene is unknown.
        [[nodiscard]] SceneRoot* SceneRootFor(const scene::Scene& scene) noexcept;

        // ---- lifecycle ----
        void OnInit() override;
        void OnReady() override;
        void OnShutdown() override;
        void BeginFrame(f32 deltaTime) override;
        /// The action layer's pointer and keyboard claims cleared after the frame read them: the
        /// next frame's BeginFrame lane republishes them (Engine.UI's, then the GUI's added).
        void EndFrame() override;

        // ---- scripts ----
        /// `context`'s scripts given the screen tier's root (`gui::root()`).
        void ExposeToScript(foundation::script::IScriptContext& context);

        // ---- input ----
        /// The window whose platform text input (IME) follows the GUI's focus (the player's main
        /// window); null leaves it alone (an editor, whose own bridge owns it).
        void SetTextInputTarget(foundation::shell::IWindow* window);
        /// The root this frame's input went to; null before any input.
        [[nodiscard]] SceneRoot* ActiveInputRoot() const noexcept { return m_activeRoot; }
        /// Whether the GUI took the pointer this frame (what the action layer was told).
        [[nodiscard]] bool PointerOverGui() const noexcept { return m_pointerTaken; }
        /// The input kind, from the active source each frame (the pointer, the keys, a pad).
        [[nodiscard]] foundation::input::InputKindTracker& GetInputKindTracker() noexcept { return m_inputKind; }

        // ---- the scene tier ----
        void OnSystemsReady(scene::Scene& scene) override;
        void OnDestroying(scene::Scene& scene) override;

        // ---- the overlay roles ----
        /// Above Engine.UI's (0) while both draw.
        [[nodiscard]] i32 OverlayOrder() const noexcept override { return 10; }
        /// The scene tier: the view's scene root, laid out at the view's viewport and drawn there.
        void Render(rhi::RenderPassEncoder& encoder, const render::SceneOverlayView& view) override;
        /// The screen tier, before the pass: the frame's bakes, then the screen root recorded with
        /// its offscreen layers on the host's encoder.
        void PrepareOverlay(rhi::CommandEncoder& encoder, const render::ScreenOverlayView& view) override;
        /// The screen tier: what PrepareOverlay recorded for this view, else recorded now.
        void Render(rhi::RenderPassEncoder& encoder, const render::ScreenOverlayView& view) override;

        // ---- an editor's preview ----
        /// `markup` built for an editor's page in the GUI's own context (the game's fonts, theme and
        /// sheets), in a root of its own that is never in a tier and takes no input; `css`, when
        /// given, a sheet over it alone (a sheet's page). What the loader dropped goes to
        /// `diagnostics`. Null when the markup does not build.
        [[nodiscard]] RefPtr<SceneRoot> CreatePreview(StringView markup, StringView css = {},
                                                           Array<GuiDiagnostic>* diagnostics = nullptr);
        /// `root` laid out at `width` x `height` and drawn into `target` (in RenderTarget state, and
        /// left so) in a pass of its own on `encoder`, over what is there.
        void RenderPreview(SceneRoot& root, rhi::CommandEncoder& encoder, rhi::TextureView* target, rhi::TextureFormat format,
                           u32 width, u32 height, u32 frameIndex);

        /// The GPU side, by whoever owns graphics (the application's startup): the VG shaders from
        /// the data mount, the renderer. Idempotent; without it the overlays draw nothing.
        void EnsureRenderReady(rhi::Device& device, i32 frameCount);
        /// The textures: the frame's bakes, then every render-texture canvas and world panel drawn
        /// into its texture, made or resized as it asks and left ready to sample; their entities'
        /// sprites (and a canvas's decal) shown them. By the host on its encoder before the scene
        /// draws, so the scene samples this frame's. Once a frame: a second call does nothing.
        void RenderTextures(rhi::CommandEncoder& encoder, u32 frameIndex);
        /// How many textures canvases and panels draw into now.
        [[nodiscard]] usize TextureCount() const noexcept;
        [[nodiscard]] bool IsRenderReady() const noexcept;

    private:
        struct RenderState; // the renderer and the shaders (impl unit)
        struct SceneTier
        {
            scene::Scene* Scene = nullptr;
            RefPtr<SceneRoot> Root;
            UniquePtr<GuiInputBridge> Bridge;
            Array<RefPtr<UIWidget>> Canvases; ///< its canvases' hosts, in the root
            RefPtr<UIWidget> Billboards;      ///< the layer under them its billboards are in
        };

        void ApplySheets();
        void ApplyUserAgentSheet();
        void PumpInput();
        void SyncCanvases(SceneTier& tier);
        void SyncBillboards(SceneTier& tier);
        void PlaceBillboards(SceneTier& tier, const render::SceneOverlayView& view);
        [[nodiscard]] static bool HasContent(const SceneTier& tier) noexcept;
        void SyncPanels(SceneTier& tier);
        // A document's tree (null when it does not build), and a component's tree in line with its
        // document and sheet: rebuilt when the document's product changes.
        [[nodiscard]] RefPtr<Node> BuildDocument(const GuiDocument& document);
        template <typename Component>
        bool RebuildIfChanged(Component& c);
        template <typename Component>
        void ApplySheet(Component& c, StringView name);
        // A root of its own for a texture (a render-texture canvas, a world panel), with its input.
        struct TextureRoot
        {
            scene::Scene* Scene = nullptr;
            scene::EntityHandle Entity{};
            RefPtr<SceneRoot> Root;
            UniquePtr<GuiInputBridge> Bridge;
            bool Seen = false;
        };
        RefPtr<SceneRoot> TextureRootFor(scene::Scene& scene, scene::EntityHandle entity, Node& content);
        // Where the pointer goes this frame: a root, and the point in it (a panel's in its pixels).
        struct InputTarget
        {
            SceneRoot* Root = nullptr;
            Float2 Point{0.0f, 0.0f}; ///< in the root's pixels
            bool Mapped = false;      ///< the point is not the pointer's own (a panel's, a fitted tier's)
            bool Panel = false;
        };
        // A screen tier: a root holding a screen stack (the shared one the overlay layer above it
        // too), its input, and the game's screen it lays out for.
        struct ScreenTier
        {
            const void* Run = nullptr; ///< null: the shared tier
            RefPtr<SceneRoot> Root;
            RefPtr<ScreenStack> Screens;
            UniquePtr<GuiInputBridge> Bridge;
            Float2 Resolution{0.0f, 0.0f};
            FitMode Fit = FitMode::Letterbox;
            ScreenOrientation Orientation = ScreenOrientation::Any;
            Float2 TargetSize{0.0f, 0.0f}; ///< the target it last drew into
            ContentRotation Turn = ContentRotation::None;
            [[nodiscard]] bool HasResolution() const noexcept { return Resolution.x > 0.0f && Resolution.y > 0.0f; }
        };
        void MakeScreenTier(ScreenTier& tier);
        static void ApplyResolution(ScreenTier& tier, u32 width, u32 height, FitMode fit);
        [[nodiscard]] ScreenTier* FindRunTier(const void* run) noexcept;
        [[nodiscard]] ScreenTier* TierOfRoot(const SceneRoot* root) noexcept;
        // The tier input reaches: the run of the scene the input is bound to, when it has a tier.
        [[nodiscard]] ScreenTier& InputTier() noexcept;
        // A render-space point in the tier's root pixels (the crop's offset off, at its scale).
        [[nodiscard]] static Float2 ScreenPointerPoint(const ScreenTier& tier, Float2 point) noexcept;
        [[nodiscard]] InputTarget PanelUnderPointer(Float2 point, bool centreAim);
        [[nodiscard]] InputTarget PickInputRoot(bool pointer, Float2 point, bool centreAim);
        [[nodiscard]] bool InputReaches(const SceneTier& tier) const noexcept;
        [[nodiscard]] GuiInputBridge* BridgeOf(const SceneRoot* root) noexcept;
        [[nodiscard]] UniquePtr<GuiInputBridge> MakeBridge(SceneRoot& root);
        void StyleAndLayOut(SceneRoot& root, Float2 size);
        [[nodiscard]] bool ReadDataFile(StringView path, Array<u8>& out) const;

        TaggedAllocator m_allocator;
        foundation::vfs::IFileSystem* m_dataFileSystem; // borrowed
        RefPtr<GUIContext> m_context;
        StyleManager m_styles;
        UniquePtr<GuiResourceProvider> m_resources;
        UniquePtr<foundation::fonts::IFontService> m_fonts;        // the built-in font
        UniquePtr<foundation::fonts::IFontService> m_projectFonts; // the project's, when it names a default
        RefPtr<foundation::fonts::Font> m_defaultFont;
        Array<RefPtr<foundation::fonts::Font>> m_otherFonts;
        Array<Guid> m_sheets;
        u64 m_sheetGeneration = 0;
        ScreenTier m_screen;                     // the shared tier
        Array<UniquePtr<ScreenTier>> m_runTiers; // a tier per run, with run screens on
        bool m_runScreens = false;
        const void* m_renderRun = nullptr;
        RefPtr<UIWidget> m_overlay;
        GuiScriptBinding m_scriptBinding; // what each script context is given
        Array<SceneTier> m_sceneTiers;
        Array<UniquePtr<TextureRoot>> m_textureRoots;
        u64 m_frameSerial = 0;
        u64 m_texturesSerial = ~0ull; // the frame RenderTextures last ran in
        Float2 m_panelPoint{0.0f, 0.0f}; // where a held press on a panel last was, in its pixels
        UniquePtr<RenderState> m_render;
        render::ISceneRenderer* m_sceneRenderer = nullptr; // the overlays' registration
        render::IScreenRenderer* m_screenRenderer = nullptr;
        engine::input::InputSubsystem* m_input = nullptr;
        foundation::input::InputKindTracker m_inputKind;
        foundation::shell::IWindow* m_textInputTarget = nullptr;
        SceneRoot* m_activeRoot = nullptr; // the root input went to last
        SceneRoot* m_pressRoot = nullptr;  // the root a held press began in
        bool m_pressTaken = false;              // that press began over GUI that takes the pointer
        bool m_pointerTaken = false;
    };

    /// The GUI's domain (engine-composition.md): its resource modules (documents and sheets, the
    /// vector images, the fonts) beside the UI domain's while both live.
    [[nodiscard]] const engine::DomainModule& GuiDomain() noexcept;
}
