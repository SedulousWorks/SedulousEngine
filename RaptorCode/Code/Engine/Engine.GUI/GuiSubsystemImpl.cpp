// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - implementation unit, what is left of it after the Engine.GUI port's third slice:
// the components' script reflection (`of`, `root()`), the script facades, the panels' mouse, and
// the subsystem's members for its input (the port's E4) and its scripts (E5), with the lines the
// ported members still need of them (listed after ExposeToScript). The resource provider's
// bindings, the components' reflection (their attributes now), the billboard placement, the world
// panel's pixels, the pointer ray, the ray against a panel and the domain are
// Code/Engine/Sedulous.Engine.GUI/src
// (GuiResourceProvider.bf, GuiCanvasComponent.bf, GuiBillboardComponent.bf,
// GuiWorldPanelComponent.bf, GuiWorldMath.bf, GuiDomain.bf), as the subsystem's core is (its
// construction, lifecycle, sheets, fonts, tiers, the game's screen, a tier per run, the overlay
// layer, documents built, the overlays through GuiPassRenderer, the GPU bring-up and an editor's
// preview: GuiSubsystem.bf, GuiOverlayDraw.bf, GuiScreenTier.bf, GuiSceneTier.bf, GuiRenderState.bf,
// GuiScreenPlacement.bf), as are the components live (the canvases' host, a component's tree and
// sheet, the texture roots, the billboards' placement, the scene draw's gate, the render state's
// textures, RenderTextures and TextureCount: GuiComponentSync.bf, GuiCanvasHost.bf,
// GuiTextureRoot.bf, GuiRenderTextures.bf, GuiTextureTarget.bf).

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
import foundation.shell;
import foundation.input;
import engine.input;
import foundation.gui;
import foundation.gui.gamekit;
import foundation.gui.shell;
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

    namespace
    {
        // The mouse as a world panel sees it: at the point the ray crosses it, in its pixels; its
        // buttons, wheel and the rest the real one's.
        class PanelMouse final : public foundation::shell::IMouse
        {
        public:
            PanelMouse(foundation::shell::IMouse* mouse, Float2 at) noexcept : m_mouse(mouse), m_at(at) {}
            [[nodiscard]] f32 X() const override { return m_at.x; }
            [[nodiscard]] f32 Y() const override { return m_at.y; }
            [[nodiscard]] f32 GlobalX() const override { return m_mouse->GlobalX(); }
            [[nodiscard]] f32 GlobalY() const override { return m_mouse->GlobalY(); }
            [[nodiscard]] f32 DeltaX() const override { return m_mouse->DeltaX(); }
            [[nodiscard]] f32 DeltaY() const override { return m_mouse->DeltaY(); }
            [[nodiscard]] f32 ScrollX() const override { return m_mouse->ScrollX(); }
            [[nodiscard]] f32 ScrollY() const override { return m_mouse->ScrollY(); }
            [[nodiscard]] bool IsButtonDown(foundation::shell::MouseButton button) const override { return m_mouse->IsButtonDown(button); }
            [[nodiscard]] bool IsButtonPressed(foundation::shell::MouseButton button) const override { return m_mouse->IsButtonPressed(button); }
            [[nodiscard]] bool IsButtonReleased(foundation::shell::MouseButton button) const override { return m_mouse->IsButtonReleased(button); }
            [[nodiscard]] bool RelativeMode() const override { return m_mouse->RelativeMode(); }
            void SetRelativeMode(bool enabled) override { m_mouse->SetRelativeMode(enabled); }
            [[nodiscard]] bool CursorVisible() const override { return m_mouse->CursorVisible(); }
            void SetCursorVisible(bool visible) override { m_mouse->SetCursorVisible(visible); }
            void SetCursor(foundation::shell::CursorType cursor) override { m_mouse->SetCursor(cursor); }
            void SetGlobalCapture(bool capture) override { m_mouse->SetGlobalCapture(capture); }

        private:
            foundation::shell::IMouse* m_mouse;
            Float2 m_at;
        };
    }

    // ===================================================================================
    // GuiSubsystem
    // ===================================================================================

    void GuiSubsystem::ExposeToScript(foundation::script::IScriptContext& context) { InstallGuiScriptService(context, m_scriptBinding); }

    // ---- the ported members' lines still to port ----
    // Each of these members is in Code/Engine/Sedulous.Engine.GUI/src now (GuiSubsystem.bf,
    // GuiComponentSync.bf), a comment there where the lines below join it ("E4": the input, "E5":
    // the scripts).
    //
    // OnInit (E5), after the overlay layer:
    //     // A script's root is its run's screen tier (the shared one in the player).
    //     m_scriptBinding.resolve = [this]() { return ScreenRootFor(foundation::script::CurrentRun()); };
    //
    // MakeScreenTier and OnSystemsReady (E4), each tier's input:
    //     tier.Bridge = MakeBridge(*tier.Root);
    //
    // OnShutdown (E4, E5), before the tiers go:
    //     m_activeRoot = nullptr;
    //     m_pressRoot = nullptr;
    //     m_scriptBinding.resolve = nullptr; // a script still running finds no root, not a freed one
    //
    // SyncComponents (E4), as each unseen texture root goes, and OnDestroying (E4), as each of the
    // scene's texture roots goes (`root` its root):
    //     if (m_activeRoot == root)
    //         m_activeRoot = nullptr;
    //     if (m_pressRoot == root)
    //         m_pressRoot = nullptr;
    //
    // BeginFrame (E4), after SyncComponents and before the GUI's clock:
    //     PumpInput();
    //
    // TextureRootFor (E4), as a texture root is made:
    //     made->Bridge = MakeBridge(*made->Root);
    //
    // OnDestroying (E4), as the scene's tier goes,
    //     if (m_activeRoot == m_sceneTiers[i].Root.Get())
    //         m_activeRoot = nullptr;
    //     if (m_pressRoot == m_sceneTiers[i].Root.Get())
    //         m_pressRoot = nullptr;
    //
    // EndRunScreens (E4), as the run's tier goes (`root` its root):
    //     if (m_activeRoot == root)
    //         m_activeRoot = nullptr;
    //     if (m_pressRoot == root)
    //         m_pressRoot = nullptr;

    UniquePtr<GuiInputBridge> GuiSubsystem::MakeBridge(SceneRoot& root)
    {
        UniquePtr<GuiInputBridge> bridge = MakeUnique<GuiInputBridge>(m_allocator, root.GetEventDispatcher());
        bridge->SetInputKindTracker(&m_inputKind); // the pointer, the keys or a pad (K2b)
        bridge->SetTextInputTarget(m_textInputTarget);
        return bridge;
    }

    void GuiSubsystem::SetTextInputTarget(foundation::shell::IWindow* window)
    {
        m_textInputTarget = window;
        if (m_screen.Bridge)
            m_screen.Bridge->SetTextInputTarget(window);
        for (const UniquePtr<ScreenTier>& tier : m_runTiers)
            tier->Bridge->SetTextInputTarget(window);
        for (const SceneTier& tier : m_sceneTiers)
            tier.Bridge->SetTextInputTarget(window);
    }

    GuiInputBridge* GuiSubsystem::BridgeOf(const SceneRoot* root) noexcept
    {
        if (ScreenTier* tier = TierOfRoot(root))
            return tier->Bridge.Get();
        for (const SceneTier& tier : m_sceneTiers)
            if (tier.Root.Get() == root)
                return tier.Bridge.Get();
        for (const UniquePtr<TextureRoot>& texture : m_textureRoots)
            if (texture->Root.Get() == root)
                return texture->Bridge.Get();
        return nullptr;
    }

    // The nearest interactive world panel the pointer's ray crosses, through each reachable scene's
    // camera at the shape its GUI last drew (through the view's centre when the mouse is captured:
    // the crosshair is the pointer), and the point in its pixels; none: no root.
    GuiSubsystem::InputTarget GuiSubsystem::PanelUnderPointer(Float2 point, bool centreAim)
    {
        InputTarget found;
        f32 nearest = 0.0f;
        for (const SceneTier& tier : m_sceneTiers)
        {
            auto* panels = tier.Scene->GetSystem<GuiWorldPanelComponentManager>();
            if (panels == nullptr || !InputReaches(tier))
                continue;
            const Float2 viewSize = tier.Root->GetViewportSize();
            if (viewSize.x <= 0.0f || viewSize.y <= 0.0f)
                continue; // not drawn yet: no shape to cast through
            render::ViewCamera camera;
            if (!engine::render::ExtractPrimaryCamera(*tier.Scene, camera, nullptr, viewSize.x / viewSize.y))
                continue;
            Float3 origin;
            Float3 direction;
            GuiPointerRay(camera, centreAim ? Float2{viewSize.x * 0.5f, viewSize.y * 0.5f} : point, viewSize, origin, direction);
            panels->ForEach(
                [&](GuiWorldPanelComponent& c, scene::EntityHandle entity)
                {
                    if (!c.interactive || !c.visible || !c.renderRoot || !tier.Scene->IsEffectivelyActive(entity))
                        return;
                    const GuiPanelHit hit = RayHitGuiPanel(origin, direction, tier.Scene->GetWorldMatrix(entity), c.sizeMeters);
                    if (!hit.Hit || (found.Root != nullptr && hit.Distance >= nearest))
                        return;
                    const Float2 pixels = WorldPanelPixels(c);
                    found = InputTarget{c.renderRoot.Get(), Float2{hit.Uv.x * pixels.x, hit.Uv.y * pixels.y}, true, true};
                    nearest = hit.Distance;
                });
        }
        return found;
    }

    // Whether this frame's input may reach `tier`'s scene: the source's own scene when it is bound
    // to one (an editor Game tab), else every scene or none, as the input subsystem's policy says.
    bool GuiSubsystem::InputReaches(const SceneTier& tier) const noexcept
    {
        if (m_input == nullptr)
            return false;
        if (const void* bound = m_input->BoundSceneKey(); bound != nullptr)
            return static_cast<const void*>(tier.Scene) == bound;
        return m_input->UnboundScenePolicy() == engine::input::UnboundInputScenePolicy::AllScenes;
    }

    GuiSubsystem::InputTarget GuiSubsystem::PickInputRoot(bool pointer, Float2 point, bool centreAim)
    {
        if (!m_screen.Root)
            return {};
        // The shared tier's overlay layer, occupied (a system menu, a loading screen), is modal; a
        // passive one (a watermark, `pointer-events: none`) draws over everything and takes nothing.
        for (usize i = 0; m_overlay && i < m_overlay->ChildCount(); ++i)
            if (m_overlay->GetChildAt(i)->IsDisplayed() && m_overlay->GetChildAt(i)->IsHitTestVisible())
                return InputTarget{m_screen.Root.Get(), ScreenPointerPoint(m_screen, point), m_screen.HasResolution(), false};
        // The screen tier input reaches (the bound run's), its pointer in its own pixels.
        ScreenTier& tier = InputTier();
        const InputTarget screen{tier.Root.Get(), ScreenPointerPoint(tier, point), tier.HasResolution(), false};
        // The GUI under the pointer, the screen tier's over a scene's, then a world panel's.
        if (pointer)
        {
            if (tier.Root->GetEventDispatcher()->IsPointerOver(screen.Point))
                return screen;
            for (const SceneTier& scene : m_sceneTiers)
                if (InputReaches(scene) && scene.Root->GetEventDispatcher()->IsPointerOver(point))
                    return InputTarget{scene.Root.Get(), point, false, false};
            if (const InputTarget panel = PanelUnderPointer(point, centreAim); panel.Root != nullptr)
                return panel;
        }
        // The keys and a pad: the screens a game pushed, else a scene's GUI.
        if (tier.Screens->Count() > 0)
            return screen;
        for (const SceneTier& scene : m_sceneTiers)
            if (InputReaches(scene) && HasContent(scene))
                return InputTarget{scene.Root.Get(), point, false, false};
        return screen;
    }

    void GuiSubsystem::PumpInput()
    {
        m_pointerTaken = false;
        if (m_input == nullptr || !m_screen.Root)
            return;
        foundation::input::IInputSourceProvider& devices = m_input->ActiveSource();
        m_inputKind.Update(devices);
        foundation::shell::IMouse* mouse = devices.Mouse();
        foundation::shell::ITouch* touch = devices.Touch();
        const bool fingers = touch != nullptr && touch->TouchCount() > 0;
        Float2 point{0.0f, 0.0f};
        if (fingers)
        {
            foundation::shell::TouchPoint finger;
            if (touch->GetTouchPoint(0, finger))
                point = Float2{finger.pointerX, finger.pointerY};
        }
        else if (mouse != nullptr)
            point = Float2{mouse->X(), mouse->Y()};
        const bool pointer = fingers || mouse != nullptr;
        const bool held = fingers || (mouse != nullptr && (mouse->IsButtonDown(foundation::shell::MouseButton::Left) ||
                                                           mouse->IsButtonDown(foundation::shell::MouseButton::Right) ||
                                                           mouse->IsButtonDown(foundation::shell::MouseButton::Middle)));

        // One root a frame; a held press stays with the root it began in, so its release lands (on a
        // panel, where the ray crosses it still, else where it last did).
        const bool centreAim = mouse != nullptr && mouse->RelativeMode();
        InputTarget target = PickInputRoot(pointer, point, centreAim);
        if (held && m_pressRoot != nullptr && target.Root != m_pressRoot)
        {
            bool panel = false;
            for (const UniquePtr<TextureRoot>& texture : m_textureRoots)
                panel = panel || texture->Root.Get() == m_pressRoot;
            if (panel)
                target = InputTarget{m_pressRoot, m_panelPoint, true, true};
            else if (ScreenTier* tier = TierOfRoot(m_pressRoot))
                target = InputTarget{m_pressRoot, ScreenPointerPoint(*tier, point), tier->HasResolution(), false};
            else
                target = InputTarget{m_pressRoot, point, false, false};
        }
        if (target.Panel)
            m_panelPoint = target.Point;
        SceneRoot* root = target.Root;
        if (root != m_activeRoot && m_activeRoot != nullptr && pointer)
        {
            // The root input leaves: nothing in it stays hovered.
            (void)m_activeRoot->GetEventDispatcher()->InjectMouseMove(Float2{-1.0e6f, -1.0e6f});
        }
        m_activeRoot = root;
        GuiInputBridge* bridge = BridgeOf(root);
        if (bridge == nullptr)
            return;
        if (held && m_pressRoot == nullptr)
        {
            m_pressRoot = root; // the press begins: where it began says whether the GUI took it
            m_pressTaken = target.Panel || root->GetEventDispatcher()->IsPointerOver(target.Point);
        }
        if (target.Mapped)
        {
            // A panel's pointer is where the ray crosses it, a fitted screen tier's where the render-
            // space pointer falls in its pixels (fingers come as the mouse SDL copies them to).
            PanelMouse mapped(mouse, target.Point);
            bridge->PumpDevices(mouse != nullptr ? &mapped : nullptr, nullptr, devices.Keyboard());
        }
        else
            bridge->PumpDevices(mouse, touch, devices.Keyboard());
        // Keys, text and the pad through their events, in order; the pointer was polled above.
        for (const foundation::shell::InputEvent& event : devices.Events())
            switch (event.kind)
            {
            case foundation::shell::InputEventKind::KeyDown:
            case foundation::shell::InputEventKind::KeyUp:
            case foundation::shell::InputEventKind::TextInput:
            case foundation::shell::InputEventKind::TextEditing:
            case foundation::shell::InputEventKind::GamepadButtonDown:
            case foundation::shell::InputEventKind::GamepadButtonUp:
            case foundation::shell::InputEventKind::GamepadAxis:
                (void)bridge->Dispatch(event);
                break;
            default:
                break;
            }
        bridge->SyncInputKind(); // a pad or keys with no event this frame still count

        // What the action layer is told the GUI took: the pointer over GUI that takes it, or a press
        // that began there while it is held; the keys while text is edited. Added to Engine.UI's
        // claim (its pump runs first in this lane); EndFrame clears them after the frame read them.
        m_pointerTaken = pointer && (held ? m_pressTaken : target.Panel || root->GetEventDispatcher()->IsPointerOver(target.Point));
        const bool keys = root->GetEventDispatcher()->WantsTextInput();
        if (!held)
        {
            m_pressRoot = nullptr;
            m_pressTaken = false;
        }
        const bool pointerTaken = m_pointerTaken;
        m_input->ForEachActionRuntime(
            [pointerTaken, keys](foundation::input::ActionRuntime& runtime)
            {
                foundation::input::ActionRuntime::ConsumptionMask mask = runtime.GetConsumptionMask();
                mask.pointer = mask.pointer || pointerTaken;
                mask.keyboard = mask.keyboard || keys;
                runtime.SetConsumptionMask(mask);
            });
    }

    GuiSubsystem::ScreenTier& GuiSubsystem::InputTier() noexcept
    {
        const void* bound = m_runScreens && m_input != nullptr ? m_input->BoundSceneKey() : nullptr;
        if (bound != nullptr)
            for (const SceneTier& scene : m_sceneTiers)
                if (static_cast<const void*>(scene.Scene) == bound)
                {
                    if (ScreenTier* tier = FindRunTier(scene.Scene->Run()))
                        return *tier;
                    break;
                }
        return m_screen;
    }
}
