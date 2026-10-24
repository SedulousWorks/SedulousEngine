// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - the bed the drop and keyboard tests share: a DockSpace in a root, five panels
// registered, four docked (scene and inspector tabbed in the central stack, the hierarchy beside it
// on the left, the console under it), and the moves a user makes on it.
#pragma once

#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.docking;

namespace dockbed
{
    using namespace foundation::gui;
    namespace core = foundation::core;
    using core::i32;
    using core::usize;

    inline core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // Scene and inspector tabbed in the central stack, the hierarchy beside it on the left (a
    // quarter), the console under the central stack.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        DockController controller{core::DefaultAllocator()};
        core::RefPtr<DockSpace> space = core::MakeRef<DockSpace>(core::DefaultAllocator());

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            space->EditLayoutStyle([](LayoutStyle& s) {
                s.Width = LayoutLength::Px(800.0f);
                s.Height = LayoutLength::Px(600.0f);
            });
            root->AddChild(space.Get());
            const char8_t* const ids[] = {u8"scene", u8"inspector", u8"hierarchy", u8"console", u8"log"};
            for (const char8_t* id : ids)
            {
                DockPanelDescription description;
                description.Id = core::String(id);
                description.Factory = []() { return core::RefPtr<Node>(core::MakeRef<Panel>(core::DefaultAllocator())); };
                REQUIRE(controller.Register(core::Move(description)));
            }
            space->Show(controller, controller.GetLayout().MainSurface());
            const DockNodeId central = controller.GetLayout().CentralStack();
            REQUIRE(controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"scene"), central); }).Ok());
            REQUIRE(controller.Edit([&](DockLayout& l) { return l.InsertTab(SV(u8"inspector"), central); }).Ok());
            REQUIRE(controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(u8"hierarchy"), central, DockSide::Start, 0.25f); }).Ok());
            REQUIRE(controller.Edit([&](DockLayout& l) { return l.InsertBeside(SV(u8"console"), central, DockSide::Bottom, 0.3f); }).Ok());
            Lay();
        }
        void Lay()
        {
            root->UpdateLayout();
            // The tabs a size of their own: with no font their text measures nothing.
            const char8_t* const ids[] = {u8"scene", u8"inspector", u8"hierarchy", u8"console"};
            for (const char8_t* id : ids)
                if (Tab* tab = TabOf(id))
                    tab->EditLayoutStyle([](LayoutStyle& s) {
                        s.Width = LayoutLength::Px(80.0f);
                        s.Height = LayoutLength::Px(24.0f);
                    });
            root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        DockNodeId StackOf(const char8_t* panel) const { return controller.GetLayout().StackOf(SV(panel)); }
        TabView* ViewOf(const char8_t* panel) const { return Cast<TabView>(space->WidgetOf(StackOf(panel))); }
        Tab* TabOf(const char8_t* panel) const
        {
            TabView* view = ViewOf(panel);
            TabPage* page = space->PageOf(SV(panel));
            if (view == nullptr || page == nullptr)
                return nullptr;
            for (i32 i = 0; i < view->GetPageCount(); ++i)
                if (view->GetPage(i) == page)
                    return view->GetBar()->GetTab(i);
            return nullptr;
        }
        static core::Float2 Centre(const Rect& r) { return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f}; }
        static Rect Bounds(const Node& n) { return n.GetScreenBounds(); }
        // A tab torn out of its strip (pulled down into its stack).
        void Tear(const char8_t* panel)
        {
            Tab* tab = TabOf(panel);
            REQUIRE(tab != nullptr);
            const core::Float2 at = Centre(Bounds(*tab));
            D().InjectMouseDown(at, MouseButton::Left);
            D().InjectMouseMove(core::Float2{at.x, at.y + 50.0f});
            D().InjectMouseMove(core::Float2{at.x, at.y + 60.0f});
            REQUIRE(D().IsDragging());
        }
        void Over(core::Float2 at) { D().InjectMouseMove(at); }
        void Release(core::Float2 at) { D().InjectMouseUp(at, MouseButton::Left); }
        bool Preview(Rect& out) const { return space->GetPreviewBounds(out); }
    };
}

