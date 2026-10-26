// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - the `engine.gui` module: the engine's GUI on foundation.gui (E5 of
// Specs/gui-lab-evolution-3.md), Engine.UI's counterpart, beside it while both live; what is left
// of it after the Engine.GUI port's fourth slice: the script surface (E8 below, the port's E5),
// with the components' script reflection (`of`, `root()`).
//
// Code/Engine/Sedulous.Engine.GUI/src has the rest. The first slice: the components, their enums
// and managers (AddGuiSceneManagers is GuiScene.bf), the world math, the resource provider and the
// domain. The second, the subsystem's core: GuiSubsystem.bf (the context, the style manager, the
// theme under the game's sheets, the fonts, the screen tier with its stack and overlay layer, the
// scene tier, the game's screen, a screen tier per run, the lifecycle), GuiOverlayDraw.bf (both
// tiers drawn into the engine's overlay passes through GuiPassRenderer, the GPU bring-up, an
// editor's preview), GuiScreenTier.bf, GuiSceneTier.bf, GuiRenderState.bf and
// GuiScreenPlacement.bf. The third, the components live (E7 of the spec): GuiComponentSync.bf (a
// canvas's tree in its scene's root or a texture root of its own, its host and scaler
// (GuiCanvasHost.bf), a component's own sheet, the billboards' layer and their placement as each
// view draws, a world panel's tree, the scene draw's gate), GuiRenderTextures.bf (RenderTextures,
// TextureCount: the textures drawn before the scene, each shown on its entity's sprite or decal,
// a world panel's sprite driven), GuiTextureRoot.bf and GuiTextureTarget.bf, with the render state's
// textures in GuiRenderState.bf. The fourth, the input (E6 of the spec): GuiInputPump.bf (the
// engine's active input source into one root a frame through GUI.Shell's bridge, made per root, the
// overlay layer modal, a press kept by its root, the bound source, a world panel's pointer by a ray,
// a fitted tier's pointer, what the action layer hears, the input kind, the text input target),
// GuiInputTarget.bf and GuiPanelMouse.bf, with each tier's bridge (GuiScreenTier.bf,
// GuiSceneTier.bf, GuiTextureRoot.bf). Where the rest joins it, a comment there names the slice
// ("E5").
//
// The script surface (E8): the GUI's own (the `gui` facade, every widget reflected, the gamekit's
// stack), installed per script context with the screen tier's root (ExposeToScript): `gui::root()`
// is the screen root and `ScreenStack::of(gui::root().find("screens"))` its stack, which pushes a
// document by its guid ("{guid}") through the provider. Each component's `.of(entity)` reaches its
// tree as a node (`root()`). With run screens on, the `gui` root of a run's scripts is its tier's.
// GCC modules hygiene: the renderer and the shaders lived in GuiSubsystemImpl.cpp.

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
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.resources; // the documents and sheets components name

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
    // not named below are Code/Engine/Sedulous.Engine.GUI/src (GuiSubsystem.bf, GuiOverlayDraw.bf,
    // GuiComponentSync.bf, GuiRenderTextures.bf, GuiInputPump.bf): what is left is the scripts (E5).
    class GuiSubsystem final : public foundation::runtime::Subsystem,
                               public scene::ISceneObserver,
                               public render::ISceneOverlay,
                               public render::IScreenOverlay
    {
    public:
        // ---- scripts ----
        /// `context`'s scripts given the screen tier's root (`gui::root()`).
        void ExposeToScript(foundation::script::IScriptContext& context);

    private:
        GuiScriptBinding m_scriptBinding; // what each script context is given
    };
}
