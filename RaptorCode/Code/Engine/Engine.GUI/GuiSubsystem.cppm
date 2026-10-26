// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - the `engine.gui` module: the engine's GUI on foundation.gui (E5 of
// Specs/gui-lab-evolution-3.md), Engine.UI's counterpart, beside it while both live; what is left
// of it after the Engine.GUI port's second slice: the subsystem's input (E6 below, the port's E4),
// the components' live trees (E7 below, the port's E3) and the script surface (E8 below, the port's
// E5), with the components' script reflection (`of`, `root()`).
//
// Code/Engine/Sedulous.Engine.GUI/src has the rest. The first slice: the components, their enums
// and managers (AddGuiSceneManagers is GuiScene.bf), the world math, the resource provider and the
// domain. The second, the subsystem's core: GuiSubsystem.bf (the context, the style manager, the
// theme under the game's sheets, the fonts, the screen tier with its stack and overlay layer, the
// scene tier, the game's screen, a screen tier per run, the lifecycle), GuiOverlayDraw.bf (both
// tiers drawn into the engine's overlay passes through GuiPassRenderer, the GPU bring-up, an
// editor's preview), GuiScreenTier.bf, GuiSceneTier.bf, GuiRenderState.bf and
// GuiScreenPlacement.bf. Where the rest joins it, a comment there names the slice ("E3", "E4",
// "E5").
//
// Input (E6): the engine's active input source (the player's window, an editor Game tab's view)
// into one root a frame, through GUI.Shell's bridge (one per root, each root its own dispatcher): an
// occupied overlay layer is modal; else the root whose GUI is under the pointer (the screen tier
// first); else the screen tier while it holds a screen; else the first scene root with content. A
// press stays with its root until every button is up. Which scenes input may reach follows the input
// subsystem's binding, as Engine.UI's does. The action layer is told what the GUI took (the pointer
// over GUI that takes it, or a press that began there; the keys while text is being edited), added
// to what Engine.UI claims; the GUI tracks the input kind from the same source. A fitted screen
// tier's pointer arrives in render space and is taken to its pixels (ScreenPointerPoint, ported).
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
// tree as a node (`root()`). With run screens on, the `gui` root of a run's scripts is its tier's.
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

    /// The components' script reflection (`of`, `root`). Idempotent.
    void RegisterGuiComponentReflection();
    /// The GUI's script surface: the GUI's (`gui`, the widgets, the gamekit's) and each component's
    /// `.of(entity)`, with their names in the behaviour prelude. Idempotent; before a script
    /// manager binds the registry.
    void RegisterGuiScriptFacades();

    // GuiScreenPlacement is Code/Engine/Sedulous.Engine.GUI/src/GuiScreenPlacement.bf.

    // The class head (Subsystem, ISceneObserver, ISceneOverlay, IScreenOverlay) and every member
    // not named below are Code/Engine/Sedulous.Engine.GUI/src (GuiSubsystem.bf, GuiOverlayDraw.bf):
    // what is left is the scripts (E5), the input (E4) and the components' live trees (E3).
    class GuiSubsystem final : public foundation::runtime::Subsystem,
                               public scene::ISceneObserver,
                               public render::ISceneOverlay,
                               public render::IScreenOverlay
    {
    public:
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

        /// The textures: the frame's bakes, then every render-texture canvas and world panel drawn
        /// into its texture, made or resized as it asks and left ready to sample; their entities'
        /// sprites (and a canvas's decal) shown them. By the host on its encoder before the scene
        /// draws, so the scene samples this frame's. Once a frame: a second call does nothing.
        void RenderTextures(rhi::CommandEncoder& encoder, u32 frameIndex);
        /// How many textures canvases and panels draw into now.
        [[nodiscard]] usize TextureCount() const noexcept;

    private:
        // The render state's textures (the impl unit); its device, shaders, renderer and the screen's
        // prepared draws are GuiRenderState.bf.
        struct RenderState;
        // The scene tier's (GuiSceneTier.bf: its scene, root and billboard layer): what is left of it.
        struct SceneTier
        {
            UniquePtr<GuiInputBridge> Bridge;
            Array<RefPtr<UIWidget>> Canvases; ///< its canvases' hosts, in the root
        };

        void PumpInput();
        void SyncCanvases(SceneTier& tier);
        void SyncBillboards(SceneTier& tier);
        void PlaceBillboards(SceneTier& tier, const render::SceneOverlayView& view);
        [[nodiscard]] static bool HasContent(const SceneTier& tier) noexcept;
        void SyncPanels(SceneTier& tier);
        // A component's tree in line with its document and sheet: rebuilt when the document's
        // product changes (BuildDocument, a document's tree, is GuiSubsystem.bf).
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
        // The screen tier's (GuiScreenTier.bf): what is left of it.
        struct ScreenTier
        {
            UniquePtr<GuiInputBridge> Bridge;
        };
        // The tier input reaches: the run of the scene the input is bound to, when it has a tier.
        [[nodiscard]] ScreenTier& InputTier() noexcept;
        [[nodiscard]] InputTarget PanelUnderPointer(Float2 point, bool centreAim);
        [[nodiscard]] InputTarget PickInputRoot(bool pointer, Float2 point, bool centreAim);
        [[nodiscard]] bool InputReaches(const SceneTier& tier) const noexcept;
        [[nodiscard]] GuiInputBridge* BridgeOf(const SceneRoot* root) noexcept;
        [[nodiscard]] UniquePtr<GuiInputBridge> MakeBridge(SceneRoot& root);

        TaggedAllocator m_allocator; // none in Beef: its objects are new'd
        GuiScriptBinding m_scriptBinding; // what each script context is given
        Array<UniquePtr<TextureRoot>> m_textureRoots;
        u64 m_texturesSerial = ~0ull; // the frame RenderTextures last ran in (m_frameSerial is mFrameSerial)
        Float2 m_panelPoint{0.0f, 0.0f}; // where a held press on a panel last was, in its pixels
        foundation::input::InputKindTracker m_inputKind;
        foundation::shell::IWindow* m_textInputTarget = nullptr;
        SceneRoot* m_activeRoot = nullptr; // the root input went to last
        SceneRoot* m_pressRoot = nullptr;  // the root a held press began in
        bool m_pressTaken = false;              // that press began over GUI that takes the pointer
        bool m_pointerTaken = false;
    };
}
