// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Engine::GUI - implementation unit, what is left of it after the Engine.GUI port's second slice:
// the canvases' host, the components' script reflection (`of`, `root()`), the script facades, the
// panels' mouse, the render state's textures, and the subsystem's members for the components' live
// trees (the port's E3), its input (E4) and its scripts (E5), with the lines the ported members
// still need of them (listed after ExposeToScript). The resource provider's bindings, the
// components' reflection (their attributes now), the billboard placement, the world panel's pixels,
// the pointer ray, the ray against a panel and the domain are Code/Engine/Sedulous.Engine.GUI/src
// (GuiResourceProvider.bf, GuiCanvasComponent.bf, GuiBillboardComponent.bf,
// GuiWorldPanelComponent.bf, GuiWorldMath.bf, GuiDomain.bf), as the subsystem's core is (its
// construction, lifecycle, sheets, fonts, tiers, the game's screen, a tier per run, the overlay
// layer, documents built, the overlays through GuiPassRenderer, the GPU bring-up and an editor's
// preview: GuiSubsystem.bf, GuiOverlayDraw.bf, GuiScreenTier.bf, GuiSceneTier.bf, GuiRenderState.bf,
// GuiScreenPlacement.bf).

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

    namespace
    {
        // A canvas's place in its scene's root, filling it (the `canvas` element to a sheet): its
        // document laid out at the root's size, or at the reference resolution and scaled
        // uniformly to fit, centred on a whole pixel. Paints nothing, so it never takes the
        // pointer from the game: only what its document paints does.
        class CanvasHost final : public UIWidget
        {
        public:
            CanvasHost() { SetTag(StringView(u8"canvas")); }

            void Configure(i32 order, GuiScalerMode scaler, Float2 reference)
            {
                Order = order;
                if (scaler == m_scaler && reference == m_reference)
                    return;
                m_scaler = scaler;
                m_reference = reference;
                RequestLayout();
            }

            void OnLayout() override
            {
                const Float2 size = GetSize();
                Float2 inner = size;
                f32 scale = 1.0f;
                Float2 offset{0.0f, 0.0f};
                if (m_scaler == GuiScalerMode::ReferenceResolution && m_reference.x > 0.0f && m_reference.y > 0.0f && size.x > 0.0f &&
                    size.y > 0.0f)
                {
                    inner = m_reference;
                    scale = Min(size.x / inner.x, size.y / inner.y);
                    offset = Float2{Round((size.x - inner.x * scale) * 0.5f), Round((size.y - inner.y * scale) * 0.5f)};
                }
                for (usize i = 0; i < ChildCount(); ++i)
                {
                    Node* child = GetChildAt(i);
                    child->SetScaleOrigin(Float2{0.0f, 0.0f});
                    child->SetScale(Float2{scale, scale});
                    child->Arrange(Rect{offset.x, offset.y, inner.x, inner.y});
                }
            }

            i32 Order = 0;

        private:
            GuiScalerMode m_scaler = GuiScalerMode::ConstantPixel;
            Float2 m_reference{0.0f, 0.0f};
        };
    }

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

    struct GuiSubsystem::RenderState
    {
        // Its device, the shaders, the renderer and what PrepareOverlay recorded for the screen tier
        // are GuiRenderState.bf (Device below is its Device); what is left is the textures (E3).

        // A texture a canvas or a panel draws into: the sampled texture, and the multisampled
        // colour and stencil its pass resolves from (none: a plain pass straight into it).
        struct Target
        {
            explicit Target(IAllocator&) noexcept {}
            const SceneRoot* Root = nullptr; // whose
            scene::Scene* Scene = nullptr;
            scene::EntityHandle Entity{};
            rhi::Texture* Texture = nullptr;
            rhi::TextureView* View = nullptr;
            foundation::vg::renderer::VGPassTargets Pass;
            bool Multisampled = false;
            u32 Width = 0;
            u32 Height = 0;
            rhi::ResourceState State = rhi::ResourceState::Undefined;
            bool Seen = false;
        };
        Array<UniquePtr<Target>> Targets;

        explicit RenderState(IAllocator& allocator, bool) noexcept : Targets(allocator) {}
        ~RenderState()
        {
            if (Device == nullptr)
                return;
            Device->WaitIdle();
            for (const UniquePtr<Target>& target : Targets)
                Release(*target);
        }
        void Release(Target& target)
        {
            target.Pass.Destroy();
            if (target.View != nullptr)
                Device->DestroyTextureView(target.View);
            if (target.Texture != nullptr)
                Device->DestroyTexture(target.Texture);
            target.View = nullptr;
            target.Texture = nullptr;
        }
        // `root`'s texture at `width` x `height`, made or made again at that size (the GPU waited
        // for: the scene may still sample the old one); null when the device makes none.
        Target* EnsureTarget(const SceneRoot& root, scene::Scene& scene, scene::EntityHandle entity, u32 width, u32 height,
                             IAllocator& allocator)
        {
            Target* found = nullptr;
            for (const UniquePtr<Target>& target : Targets)
                if (target->Root == &root)
                    found = target.Get();
            if (found == nullptr)
            {
                UniquePtr<Target> made = MakeUnique<Target>(allocator, allocator);
                made->Root = &root;
                made->Scene = &scene;
                made->Entity = entity;
                found = made.Get();
                Targets.PushBack(Move(made));
            }
            found->Seen = true;
            if (found->Texture != nullptr && found->Width == width && found->Height == height)
                return found;
            if (found->Texture != nullptr)
            {
                Device->WaitIdle();
                Release(*found);
            }
            if (!Device->CreateTexture(rhi::TextureDesc::RenderTarget(kTextureFormat, width, height, 1, u8"GUI texture"), found->Texture).IsOk())
            {
                found->Texture = nullptr;
                return nullptr;
            }
            rhi::TextureViewDesc viewDesc{};
            viewDesc.format = kTextureFormat;
            if (!Device->CreateTextureView(found->Texture, viewDesc, found->View).IsOk())
            {
                Device->DestroyTexture(found->Texture);
                found->Texture = nullptr;
                found->View = nullptr;
                return nullptr;
            }
            found->Pass.Configure(*Device);
            found->Multisampled = found->Pass.Create(kTextureFormat, width, height);
            found->Width = width;
            found->Height = height;
            found->State = rhi::ResourceState::Undefined;
            return found;
        }

        // sRGB, as the window's: the shaders write linear light, the texture encodes it, the
        // scene samples linear light back.
        static constexpr rhi::TextureFormat kTextureFormat = rhi::TextureFormat::RGBA8UnormSrgb;
    };


    void GuiSubsystem::ExposeToScript(foundation::script::IScriptContext& context) { InstallGuiScriptService(context, m_scriptBinding); }

    // ---- the ported members' lines still to port ----
    // Each of these members is GuiSubsystem.bf or GuiOverlayDraw.bf now, a comment there where
    // the lines below join it ("E3": the components, "E4": the input, "E5": the scripts).
    //
    // SetFonts (E3), after every root is asked to lay out again:
    //     for (const UniquePtr<TextureRoot>& root : m_textureRoots)
    //         root->Root->RequestLayoutTree();
    //
    // OnInit (E5), after the overlay layer:
    //     // A script's root is its run's screen tier (the shared one in the player).
    //     m_scriptBinding.resolve = [this]() { return ScreenRootFor(foundation::script::CurrentRun()); };
    //
    // MakeScreenTier and OnSystemsReady (E4), each tier's input:
    //     tier.Bridge = MakeBridge(*tier.Root);
    //
    // OnShutdown (E3, E4, E5), before the tiers go:
    //     m_activeRoot = nullptr;
    //     m_pressRoot = nullptr;
    //     m_textureRoots.Clear();
    //     m_scriptBinding.resolve = nullptr; // a script still running finds no root, not a freed one
    //
    // BeginFrame (E3, E4), after the provider's poll and before the GUI's clock:
    //     for (const UniquePtr<TextureRoot>& root : m_textureRoots)
    //         root->Seen = false;
    //     for (SceneTier& tier : m_sceneTiers)
    //     {
    //         SyncBillboards(tier);
    //         SyncCanvases(tier);
    //         SyncPanels(tier);
    //     }
    //     // The roots of textures whose canvas or panel went (their textures go as RenderTextures
    //     // next runs).
    //     for (usize i = m_textureRoots.Size(); i-- > 0;)
    //         if (!m_textureRoots[i]->Seen)
    //         {
    //             if (m_activeRoot == m_textureRoots[i]->Root.Get())
    //                 m_activeRoot = nullptr;
    //             if (m_pressRoot == m_textureRoots[i]->Root.Get())
    //                 m_pressRoot = nullptr;
    //             m_textureRoots.RemoveAt(i);
    //         }
    //     PumpInput();
    //
    // OnDestroying (E3, E4): first the scene's canvases' and panels' own roots,
    //     for (usize i = m_textureRoots.Size(); i-- > 0;)
    //         if (m_textureRoots[i]->Scene == &scene)
    //         {
    //             if (m_activeRoot == m_textureRoots[i]->Root.Get())
    //                 m_activeRoot = nullptr;
    //             if (m_pressRoot == m_textureRoots[i]->Root.Get())
    //                 m_pressRoot = nullptr;
    //             m_textureRoots.RemoveAt(i);
    //         }
    // then, as its tier goes,
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
    //
    // Render, the scene tier's (E3), once the view's tier is found and before its layout:
    //     if (tier == nullptr || !HasContent(*tier))
    //         return;
    //     PlaceBillboards(*tier, view);

    // A component's tree built again when its document's product changed (a re-cook, another
    // document): the old one out of wherever it was. True when it was.
    template <typename Component>
    bool GuiSubsystem::RebuildIfChanged(Component& c)
    {
        GuiDocument* document = c.document.Get();
        if (document == c.builtFrom.Get())
            return false;
        if (c.root && c.root->GetParent() != nullptr)
            c.root->GetParent()->RemoveChild(c.root.Get());
        c.root = document != nullptr ? BuildDocument(*document) : RefPtr<Node>{};
        c.sheetFrom = nullptr;
        c.builtFrom = RefPtr<Object>(document);
        return true;
    }

    // A component's own sheet on its tree (in a GUI by now), again when its product changed.
    template <typename Component>
    void GuiSubsystem::ApplySheet(Component& c, StringView name)
    {
        GuiStyleSheet* sheet = c.sheet.Get();
        if (!c.root || sheet == c.sheetFrom.Get())
            return;
        if (sheet != nullptr)
            (void)m_styles.SetSubtreeSheet(*c.root, CSSParser::Parse(sheet->css.AsView(), name));
        else
            m_styles.RemoveSubtreeSheet(*c.root);
        c.sheetFrom = RefPtr<Object>(sheet);
    }

    // The root of its own a texture's content (a render-texture canvas, a world panel) is drawn
    // in: made for the entity the first time, holding `content` alone, kept while seen each frame.
    RefPtr<SceneRoot> GuiSubsystem::TextureRootFor(scene::Scene& scene, scene::EntityHandle entity, Node& content)
    {
        TextureRoot* found = nullptr;
        for (const UniquePtr<TextureRoot>& known : m_textureRoots)
            if (known->Scene == &scene && known->Entity == entity && !known->Seen)
                found = known.Get();
        if (found == nullptr)
        {
            UniquePtr<TextureRoot> made = MakeUnique<TextureRoot>(m_allocator);
            made->Scene = &scene;
            made->Entity = entity;
            made->Root = MakeRef<SceneRoot>(m_allocator, m_context);
            {
                Node::StyleWriteScope defaults(*made->Root);
                made->Root->EditLayoutStyle([](LayoutStyle& s) { s.Kind = Display::Stack; }); // the content fills it
            }
            made->Bridge = MakeBridge(*made->Root);
            found = made.Get();
            m_textureRoots.PushBack(Move(made));
        }
        found->Seen = true;
        if (content.GetParent() != found->Root.Get())
        {
            if (content.GetParent() != nullptr)
                content.GetParent()->RemoveChild(&content);
            while (found->Root->ChildCount() > 0)
                found->Root->RemoveChild(found->Root->GetChildAt(0));
            found->Root->AddChild(&content);
        }
        return found->Root;
    }

    // Each canvas's tree in line with its component: built from its document (again when the
    // document is cooked again), in its host in the scene's root or a root of its own for its
    // texture, its sheet, shown while the canvas and its entity are; the hosts of canvases gone
    // swept; the hosts ordered.
    void GuiSubsystem::SyncCanvases(SceneTier& tier)
    {
        auto* canvases = tier.Scene->GetSystem<GuiCanvasComponentManager>();
        Array<const Node*> seen(m_allocator);
        if (canvases != nullptr)
            canvases->ForEach(
                [&](GuiCanvasComponent& c, scene::EntityHandle entity)
                {
                    const bool wantsTexture = c.renderMode == GuiCanvasRenderMode::RenderTexture;
                    if (!RebuildIfChanged(c) && c.root && wantsTexture != (c.renderRoot.Get() != nullptr))
                    {
                        // Its mode changed: out of where it was, its sheet applied afresh where it goes.
                        if (c.root->GetParent() != nullptr)
                            c.root->GetParent()->RemoveChild(c.root.Get());
                        c.sheetFrom = nullptr;
                    }
                    if (wantsTexture)
                    {
                        c.host = nullptr; // swept below, unseen
                        c.renderRoot = c.root ? TextureRootFor(*tier.Scene, entity, *c.root) : RefPtr<SceneRoot>{};
                    }
                    else
                    {
                        c.renderRoot = nullptr;
                        c.renderTexture = nullptr;
                        c.renderTextureView = nullptr;
                        if (!c.host)
                        {
                            c.host = MakeRef<CanvasHost>(m_allocator);
                            tier.Root->AddChild(c.host.Get());
                            tier.Canvases.PushBack(c.host);
                        }
                        auto* host = static_cast<CanvasHost*>(c.host.Get());
                        host->Configure(c.order, c.scalerMode, c.referenceResolution);
                        seen.PushBack(host);
                        if (c.root && c.root->GetParent() == nullptr)
                            host->AddChild(c.root.Get());
                    }
                    if (!c.root)
                        return;
                    ApplySheet(c, StringView(u8"canvas"));
                    c.root->SetDisplayed(c.visible && tier.Scene->IsEffectivelyActive(entity));
                    c.root->SetInert(!c.interactive);
                });
        // The hosts whose canvas went (despawned, the component removed, drawn into a texture
        // now), then the order: by `order`, stably, after whatever else the root holds.
        Array<CanvasHost*> hosts(m_allocator);
        for (usize i = 0; i < tier.Canvases.Size();)
        {
            CanvasHost* host = static_cast<CanvasHost*>(tier.Canvases[i].Get());
            bool live = false;
            for (const Node* known : seen)
                live = live || known == host;
            if (live)
            {
                hosts.PushBack(host);
                ++i;
                continue;
            }
            tier.Root->RemoveChild(host);
            tier.Canvases.RemoveAt(i);
        }
        // In the root's order, for the sort.
        for (usize i = 1; i < hosts.Size(); ++i)
            for (usize j = i; j > 0 && tier.Root->GetChildIndex(hosts[j]) < tier.Root->GetChildIndex(hosts[j - 1]); --j)
                Swap(hosts[j - 1], hosts[j]);
        bool sorted = true;
        for (usize i = 1; i < hosts.Size(); ++i)
            sorted = sorted && hosts[i - 1]->Order <= hosts[i]->Order;
        if (sorted)
            return;
        for (usize i = 1; i < hosts.Size(); ++i) // stable insertion sort
            for (usize j = i; j > 0 && hosts[j - 1]->Order > hosts[j]->Order; --j)
                Swap(hosts[j - 1], hosts[j]);
        for (CanvasHost* host : hosts)
            tier.Root->SetChildIndex(host, tier.Root->ChildCount() - 1);
    }

    // Each billboard's tree in line with its component, in the scene's billboard layer (rebuilt
    // when its document changes, its sheet, shown while it and its entity are); the trees of
    // billboards gone swept. Where each shows is a view's (PlaceBillboards).
    void GuiSubsystem::SyncBillboards(SceneTier& tier)
    {
        auto* billboards = tier.Scene->GetSystem<GuiBillboardComponentManager>();
        Array<const Node*> seen(m_allocator);
        if (billboards != nullptr)
            billboards->ForEach(
                [&](GuiBillboardComponent& c, scene::EntityHandle entity)
                {
                    (void)RebuildIfChanged(c);
                    if (!c.root)
                        return;
                    if (c.root->GetParent() == nullptr)
                    {
                        c.root->EditLayoutStyle([](LayoutStyle& s) { s.Placement = Position::Absolute; });
                        tier.Billboards->AddChild(c.root.Get());
                    }
                    seen.PushBack(c.root.Get());
                    ApplySheet(c, StringView(u8"billboard"));
                    c.root->SetDisplayed(c.visible && tier.Scene->IsEffectivelyActive(entity));
                });
        for (usize i = tier.Billboards->ChildCount(); i-- > 0;)
        {
            Node* child = tier.Billboards->GetChildAt(i);
            bool live = false;
            for (const Node* known : seen)
                live = live || known == child;
            if (!live)
                tier.Billboards->RemoveChild(child);
        }
    }

    // Each world panel's tree in line with its component, in a root of its own for its texture.
    void GuiSubsystem::SyncPanels(SceneTier& tier)
    {
        auto* panels = tier.Scene->GetSystem<GuiWorldPanelComponentManager>();
        if (panels == nullptr)
            return;
        panels->ForEach(
            [&](GuiWorldPanelComponent& c, scene::EntityHandle entity)
            {
                (void)RebuildIfChanged(c);
                c.renderRoot = c.root ? TextureRootFor(*tier.Scene, entity, *c.root) : RefPtr<SceneRoot>{};
                if (!c.root)
                {
                    c.renderTexture = nullptr;
                    c.renderTextureView = nullptr;
                    return;
                }
                ApplySheet(c, StringView(u8"panel"));
                c.root->SetDisplayed(c.visible && tier.Scene->IsEffectivelyActive(entity));
                c.root->SetInert(!c.interactive);
            });
    }

    // Each shown billboard placed for `view`: hung by its bottom centre on its projected point (its
    // size the last layout's: a new one settles the next frame), scaled toward that point, hidden
    // behind the camera, keeping its layout so nothing else moves.
    void GuiSubsystem::PlaceBillboards(SceneTier& tier, const render::SceneOverlayView& view)
    {
        auto* billboards = tier.Scene->GetSystem<GuiBillboardComponentManager>();
        if (billboards == nullptr)
            return;
        const Float2 viewport{static_cast<f32>(view.viewportWidth), static_cast<f32>(view.viewportHeight)};
        billboards->ForEach(
            [&](GuiBillboardComponent& c, scene::EntityHandle entity)
            {
                if (!c.root || !c.root->IsDisplayed())
                    return;
                const GuiBillboardPlacement placement =
                    PlaceBillboard(c, tier.Scene->GetWorldMatrix(entity), view.viewProjection, view.cameraPosition, viewport);
                c.root->SetVisible(placement.Shown);
                if (!placement.Shown)
                    return;
                const Float2 size = c.root->GetSize();
                const Float2 corner{placement.Anchor.x - size.x * 0.5f, placement.Anchor.y - size.y};
                c.root->EditLayoutStyle(
                    [corner](LayoutStyle& s)
                    {
                        s.Left = LayoutLength::Px(corner.x);
                        s.Top = LayoutLength::Px(corner.y);
                    });
                c.root->SetScaleOrigin(Float2{size.x * 0.5f, size.y});
                c.root->SetScale(Float2{placement.Scale, placement.Scale});
            });
    }

    // Whether a scene's GUI shows anything: a canvas, or a billboard.
    bool GuiSubsystem::HasContent(const SceneTier& tier) noexcept
    {
        return !tier.Canvases.IsEmpty() || (tier.Billboards && tier.Billboards->ChildCount() > 0);
    }

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

    usize GuiSubsystem::TextureCount() const noexcept { return m_render ? m_render->Targets.Size() : 0; }

    namespace
    {
        // A texture's content drawn into it: laid out at its size (inset by `padding` on each side,
        // left clear), offscreen layers first, then its pass, the texture left ready to sample.
        void DrawTexture(GuiPassRenderer& renderer, rhi::CommandEncoder& encoder, auto& target, SceneRoot& root, u32 padding,
                         u32 frameIndex)
        {
            GuiPassView view;
            view.X = static_cast<i32>(padding);
            view.Y = static_cast<i32>(padding);
            view.Width = target.Width - 2 * padding;
            view.Height = target.Height - 2 * padding;
            view.Format = rhi::TextureFormat::RGBA8UnormSrgb;
            if (target.Multisampled)
            {
                const foundation::vg::renderer::VGTargetConfig config = target.Pass.ConfigFor();
                view.SampleCount = config.sampleCount;
                view.DepthStencilFormat = config.depthStencilFormat;
            }
            view.FrameIndex = frameIndex;
            const GuiPassRenderer::Prepared prepared = renderer.Prepare(root, view, &encoder);
            encoder.TransitionTexture(target.Texture, target.State, rhi::ResourceState::RenderTarget);
            const rhi::ClearColor clear{0.0f, 0.0f, 0.0f, 0.0f};
            rhi::RenderPassDesc pass{};
            if (target.Multisampled)
                pass = target.Pass.BeginPass(encoder, target.View, clear, u8"GUI texture");
            else
            {
                rhi::ColorAttachment color{};
                color.view = target.View;
                color.loadOp = rhi::LoadOp::Clear;
                color.storeOp = rhi::StoreOp::Store;
                color.clearValue = clear;
                pass.colorAttachments.Add(color);
            }
            if (rhi::RenderPassEncoder* passEncoder = encoder.BeginRenderPass(pass))
            {
                renderer.Draw(*passEncoder, prepared);
                passEncoder->End();
            }
            encoder.TransitionTexture(target.Texture, rhi::ResourceState::RenderTarget, rhi::ResourceState::ShaderRead);
            target.State = rhi::ResourceState::ShaderRead;
        }
    }

    void GuiSubsystem::RenderTextures(rhi::CommandEncoder& encoder, u32 frameIndex)
    {
        if (!IsRenderReady() || m_texturesSerial == m_frameSerial)
            return;
        m_texturesSerial = m_frameSerial; // several pages of an editor share one GUI: once a frame
        GuiPassRenderer& renderer = *m_render->Renderer;
        (void)renderer.RecordBakes(encoder, frameIndex); // before any pass samples them
        for (const UniquePtr<RenderState::Target>& target : m_render->Targets)
            target->Seen = false;
        for (SceneTier& tier : m_sceneTiers)
        {
            auto* sprites = tier.Scene->GetSystem<engine::render::SpriteComponentManager>();
            auto* decals = tier.Scene->GetSystem<engine::render::DecalComponentManager>();
            // A render-texture canvas's entity's own sprite and decal show its texture (the same
            // override a script would set); one that showed the old one lets it go.
            const auto show = [&](scene::EntityHandle entity, rhi::TextureView* was, rhi::TextureView* now)
            {
                if (auto* sprite = sprites != nullptr ? sprites->Get(entity) : nullptr; sprite != nullptr && (now != nullptr || sprite->texture == was))
                    sprite->texture = now;
                if (auto* decal = decals != nullptr ? decals->Get(entity) : nullptr; decal != nullptr && (now != nullptr || decal->texture == was))
                    decal->texture = now;
            };
            if (auto* canvases = tier.Scene->GetSystem<GuiCanvasComponentManager>())
                canvases->ForEach(
                    [&](GuiCanvasComponent& c, scene::EntityHandle entity)
                    {
                        if (c.renderMode != GuiCanvasRenderMode::RenderTexture || !c.renderRoot)
                            return;
                        rhi::TextureView* was = c.renderTextureView;
                        RenderState::Target* target = m_render->EnsureTarget(*c.renderRoot, *tier.Scene, entity, Max(c.renderTextureWidth, 1u),
                                                                             Max(c.renderTextureHeight, 1u), m_allocator);
                        c.renderTexture = target != nullptr ? target->Texture : nullptr;
                        c.renderTextureView = target != nullptr ? target->View : nullptr;
                        show(entity, was, c.renderTextureView);
                        if (target == nullptr || !c.visible || !tier.Scene->IsEffectivelyActive(entity))
                            return; // the texture kept, not drawn
                        StyleAndLayOut(*c.renderRoot, Float2{static_cast<f32>(target->Width), static_cast<f32>(target->Height)});
                        DrawTexture(renderer, encoder, *target, *c.renderRoot, 0, frameIndex);
                    });
            // A world panel's sprite is driven outright: the quad in its entity's plane, a little
            // larger than the panel for the transparent edge its texture keeps (the quad's own edge
            // falls in clear texels, smoothed by sampling), drawn after the tone mapping so the
            // panel keeps its authored colours, as the screen's GUI does.
            constexpr u32 kEdge = 2;
            if (auto* panels = tier.Scene->GetSystem<GuiWorldPanelComponentManager>())
                panels->ForEach(
                    [&](GuiWorldPanelComponent& c, scene::EntityHandle entity)
                    {
                        if (!c.renderRoot)
                            return;
                        const Float2 pixels = WorldPanelPixels(c);
                        const u32 width = static_cast<u32>(pixels.x) + 2 * kEdge;
                        const u32 height = static_cast<u32>(pixels.y) + 2 * kEdge;
                        RenderState::Target* target = m_render->EnsureTarget(*c.renderRoot, *tier.Scene, entity, width, height, m_allocator);
                        c.renderTexture = target != nullptr ? target->Texture : nullptr;
                        c.renderTextureView = target != nullptr ? target->View : nullptr;
                        const bool shown = c.visible && tier.Scene->IsEffectivelyActive(entity);
                        if (sprites != nullptr)
                        {
                            engine::render::SpriteComponent* sprite = sprites->Get(entity);
                            if (sprite == nullptr)
                                sprite = &sprites->Add(entity);
                            sprite->orientation = engine::render::SpriteOrientation::EntityOriented;
                            sprite->size = Float2{c.sizeMeters.x * static_cast<f32>(width) / pixels.x, c.sizeMeters.y * static_cast<f32>(height) / pixels.y};
                            sprite->texture = c.renderTextureView;
                            sprite->visible = shown && target != nullptr;
                            sprite->postTonemap = true;
                        }
                        if (target == nullptr || !shown)
                            return;
                        StyleAndLayOut(*c.renderRoot, pixels);
                        DrawTexture(renderer, encoder, *target, *c.renderRoot, kEdge, frameIndex);
                    });
        }
        // The textures whose canvas or panel went: a sprite or decal of a scene still here that
        // shows one lets it go, then it goes (the GPU waited for).
        for (usize i = m_render->Targets.Size(); i-- > 0;)
        {
            RenderState::Target& target = *m_render->Targets[i];
            if (target.Seen)
                continue;
            bool sceneHere = false;
            for (const SceneTier& tier : m_sceneTiers)
                sceneHere = sceneHere || tier.Scene == target.Scene;
            if (sceneHere && target.View != nullptr)
            {
                if (auto* sprites = target.Scene->GetSystem<engine::render::SpriteComponentManager>())
                    if (auto* sprite = sprites->Get(target.Entity); sprite != nullptr && sprite->texture == target.View)
                        sprite->texture = nullptr;
                if (auto* decals = target.Scene->GetSystem<engine::render::DecalComponentManager>())
                    if (auto* decal = decals->Get(target.Entity); decal != nullptr && decal->texture == target.View)
                        decal->texture = nullptr;
            }
            m_render->Device->WaitIdle();
            m_render->Release(target);
            m_render->Targets.RemoveAt(i);
        }
    }
}
