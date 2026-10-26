// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - implementation unit, what is left of it after the Engine.GUI port's fourth slice:
// the components' script reflection (`of`, `root()`), the script facades and the subsystem's
// members for its scripts (E5), with the lines the ported members still need of them (listed after
// ExposeToScript). The resource provider's bindings, the components' reflection (their attributes
// now), the billboard placement, the world panel's pixels, the pointer ray, the ray against a panel
// and the domain are Code/Engine/Sedulous.Engine.GUI/src (GuiResourceProvider.bf,
// GuiCanvasComponent.bf, GuiBillboardComponent.bf, GuiWorldPanelComponent.bf, GuiWorldMath.bf,
// GuiDomain.bf), as the subsystem's core is (its
// construction, lifecycle, sheets, fonts, tiers, the game's screen, a tier per run, the overlay
// layer, documents built, the overlays through GuiPassRenderer, the GPU bring-up and an editor's
// preview: GuiSubsystem.bf, GuiOverlayDraw.bf, GuiScreenTier.bf, GuiSceneTier.bf, GuiRenderState.bf,
// GuiScreenPlacement.bf), as are the components live (the canvases' host, a component's tree and
// sheet, the texture roots, the billboards' placement, the scene draw's gate, the render state's
// textures, RenderTextures and TextureCount: GuiComponentSync.bf, GuiCanvasHost.bf,
// GuiTextureRoot.bf, GuiRenderTextures.bf, GuiTextureTarget.bf), as is the input (each root's
// bridge, the pump, the root picked, a world panel's pointer by a ray and the panels' mouse, the
// bound source, what the action layer hears, the text input target: GuiInputPump.bf,
// GuiInputTarget.bf, GuiPanelMouse.bf).

module;
#include "Core/Prelude.h"
#include "Core/Log/Log.h"
#include "Core/Reflection/Reflect.h"
#include "Profiler/Profiler.h"

module engine.gui;

import foundation.core;
import engine.domain;
import foundation.profiler;
import foundation.runtime;
import foundation.scene;
import engine.scene;
import foundation.resource;
import foundation.content;
import foundation.rhi;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.fonts.resource;  // the fonts' resource module (the domain)
import foundation.fonts.harfbuzz;  // the shaper the GUI's fonts get
import foundation.fonts.bidi;      // mixed-direction lines in visual order
import foundation.image;
import foundation.vg;
import foundation.vg.svg;
import foundation.vg.resource;      // VectorImage: an SVG by guid
import foundation.texture.resource; // Texture: an image by guid
import foundation.render.api;
import engine.render; // RenderSubsystem: the overlays' registration
import foundation.gui;
import foundation.gui.gamekit;
import foundation.script;          // ComponentOf: a component's `.of(entity)`
import foundation.script.facades;  // the behaviour prelude's names
import foundation.gui.resources; // GuiDocument, GuiStyleSheet, kGuiResourceModule
import foundation.gui.hosting;   // GuiPassRenderer, VgShaderLibrary
import foundation.vg.renderer;     // VGPassTargets: a texture's multisampled pass

using namespace foundation::core;
using namespace foundation::gui;

namespace engine::gui
{
    // ===================================================================================
    // Components
    // ===================================================================================

    REFLECT_VALUE(GuiCanvasComponent, "rtti::engine::gui")
    {
        builder.Method<&foundation::script::ComponentOf<GuiCanvasComponent>, GuiCanvasComponent>("of");
        builder.Method<&GuiCanvasComponent::rootNode>("root");
    }

    REFLECT_VALUE(GuiBillboardComponent, "rtti::engine::gui")
    {
        builder.Method<&foundation::script::ComponentOf<GuiBillboardComponent>, GuiBillboardComponent>("of");
        builder.Method<&GuiBillboardComponent::rootNode>("root");
    }

    REFLECT_VALUE(GuiWorldPanelComponent, "rtti::engine::gui")
    {
        builder.Method<&foundation::script::ComponentOf<GuiWorldPanelComponent>, GuiWorldPanelComponent>("of");
        builder.Method<&GuiWorldPanelComponent::rootNode>("root");
    }

    void RegisterGuiComponentReflection()
    {
        static const bool once = []()
        {
            RttiRegisterValue_GuiCanvasComponent();
            RttiRegisterValue_GuiBillboardComponent();
            RttiRegisterValue_GuiWorldPanelComponent();
            return true;
        }();
        (void)once;
    }

    namespace
    {
        [[nodiscard]] foundation::core::Variant NodeHandle(const RefPtr<Node>& root)
        {
            return root ? root->HandleAs(Node::StaticType()) : foundation::core::Variant{};
        }
    }
    foundation::core::Variant GuiCanvasComponent::rootNode() const { return NodeHandle(root); }
    foundation::core::Variant GuiBillboardComponent::rootNode() const { return NodeHandle(root); }
    foundation::core::Variant GuiWorldPanelComponent::rootNode() const { return NodeHandle(root); }

    void RegisterGuiScriptFacades()
    {
        static const bool once = []()
        {
            RegisterGuiComponentReflection(); // the components' TypeData, `of` among it, first
            RegisterGuiScriptSurface();  // `gui`, the widgets, the events, the tweens
            RegisterGamekitElements();   // the screen stack, screens, prompts
            foundation::script::RegisterExtraFacadeName(u8"gui"); // the prelude imports the alias
            const TypeInfo* const components[] = {&TypeOf<GuiCanvasComponent>(), &TypeOf<GuiBillboardComponent>(),
                                                  &TypeOf<GuiWorldPanelComponent>()};
            for (const TypeInfo* component : components)
            {
                GlobalTypeRegistry().Register(*component);
                foundation::script::RegisterExtraScriptRootType(component);
                foundation::script::RegisterExtraFacadeName(StringView(reinterpret_cast<const utf8char*>(component->name)));
            }
            return true;
        }();
        (void)once;
    }

    // ===================================================================================
    // GuiSubsystem
    // ===================================================================================

    void GuiSubsystem::ExposeToScript(foundation::script::IScriptContext& context) { InstallGuiScriptService(context, m_scriptBinding); }

    // ---- the ported members' lines still to port ----
    // Each of these members is in Code/Engine/Sedulous.Engine.GUI/src now (GuiSubsystem.bf), a
    // comment there where the lines below join it ("E5": the scripts).
    //
    // OnInit (E5), after the overlay layer:
    //     // A script's root is its run's screen tier (the shared one in the player).
    //     m_scriptBinding.resolve = [this]() { return ScreenRootFor(foundation::script::CurrentRun()); };
    //
    // OnShutdown (E5), before the tiers go:
    //     m_scriptBinding.resolve = nullptr; // a script still running finds no root, not a freed one
}
