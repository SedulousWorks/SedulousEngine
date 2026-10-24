// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - multi-touch (E17c of Specs/gui-lab-evolution-2.md): touch-action names what a finger may do
// that the GUI does itself, as CSS's does, each ancestor narrowing it; two fingers over a node that
// leaves pinch-zoom out make one gesture from the second's landing (scale, rotation and translation,
// totals and deltas), cancelling the first finger's press; a one-finger move along an axis a node
// keeps does not pan, and goes on as the pointer.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::u8;
using core::usize;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> pad = Make<UIWidget>();
        core::Array<core::String> seen;
        core::Array<GestureEvent> changes;
        GestureEvent last{EventType::GestureEnd, nullptr};
        explicit Bed(u8 touchActions)
        {
            root->SetSize(core::Float2{400.0f, 400.0f});
            pad->SetPosition(core::Float2{50.0f, 50.0f});
            pad->SetSize(core::Float2{300.0f, 300.0f});
            pad->SetTouchActions(touchActions);
            root->AddChild(pad.Get());
            const EventType types[] = {EventType::GestureStart, EventType::GestureChange, EventType::GestureEnd,
                                       EventType::GestureCancel, EventType::PointerCancel, EventType::MouseClick};
            for (const EventType type : types)
                (void)pad->AddEventListener(type, [this](const Event& e)
                                            {
                                                seen.PushBack(core::String(EventTypeName(e.Type)));
                                                if (e.Type == EventType::GestureChange)
                                                    changes.PushBack(static_cast<const GestureEvent&>(e));
                                                if (e.Type == EventType::GestureEnd || e.Type == EventType::GestureCancel ||
                                                    e.Type == EventType::GestureChange)
                                                    last = static_cast<const GestureEvent&>(e);
                                            });
            (void)root->UpdateLayout();
        }
        EventDispatcher& d() { return *root->GetEventDispatcher(); }
        bool Saw(const char8_t* name) const
        {
            for (const core::String& s : seen)
                if (s.AsView() == SV(name))
                    return true;
            return false;
        }
    };
}

TEST_CASE("gestures: a finger moving along an axis its node keeps does not pan, and goes on as the pointer")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    auto view = Make<Panel>();
    view->SetSize(core::Float2{200.0f, 200.0f});
    view->EditLayoutStyle([](LayoutStyle& s) { s.OverflowY = Overflow::Scroll; });
    root->AddChild(view.Get());
    auto slider = Make<UIWidget>(); // a horizontal drag of its own: pans up and down only
    slider->SetSize(core::Float2{200.0f, 600.0f});
    slider->SetTouchActions(kTouchPanY);
    view->AddChild(slider.Get());
    (void)root->UpdateLayout();
    int moves = 0;
    (void)slider->AddEventListener(EventType::MouseMove, [&](const Event&) { ++moves; });
    EventDispatcher& d = *root->GetEventDispatcher();

    d.InjectTouchDown(1u, core::Float2{50.0f, 100.0f});
    d.InjectTouchMove(1u, core::Float2{80.0f, 102.0f}); // across, which it keeps
    CHECK_FALSE(d.IsPanning());
    CHECK(moves >= 1); // the node's own drag
    d.InjectTouchUp(1u, core::Float2{80.0f, 102.0f});

    d.InjectTouchDown(1u, core::Float2{50.0f, 150.0f});
    d.InjectTouchMove(1u, core::Float2{50.0f, 100.0f}); // up and down, which it leaves to the GUI
    CHECK(d.IsPanning());
    CHECK(view->GetScrollOffset().y > 0.0f);
    d.InjectTouchUp(1u, core::Float2{50.0f, 100.0f});
}
