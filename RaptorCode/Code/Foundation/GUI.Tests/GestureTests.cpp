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

TEST_CASE("gestures: touch-action from a sheet, a list of its keywords, narrowed by every ancestor")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto outer = Make<UIWidget>();
    outer->AddClass(SV(u8"outer"));
    auto inner = Make<UIWidget>();
    inner->AddClass(SV(u8"inner"));
    auto plain = Make<UIWidget>();
    root->AddChild(outer.Get());
    outer->AddChild(inner.Get());
    outer->AddChild(plain.Get());
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".outer { touch-action: pan-y pinch-zoom; } .inner { touch-action: pan-x pan-y; }")));
    styles.ApplyTree(*root.Get());
    CHECK(outer->GetTouchActions() == (kTouchPanY | kTouchPinchZoom));
    CHECK(inner->GetTouchActions() == (kTouchPanX | kTouchPanY));
    CHECK(inner->EffectiveTouchActions() == kTouchPanY); // the outer keeps pan-x, the inner pinch-zoom
    CHECK(plain->GetTouchActions() == kTouchAuto);       // not inherited
    CHECK(plain->EffectiveTouchActions() == (kTouchPanY | kTouchPinchZoom));

    styles.SetStyleSheet(CSSParser::Parse(SV(u8".outer { touch-action: none; } .inner { touch-action: pan-x sideways; }")));
    styles.ApplyTree(*root.Get());
    CHECK(outer->GetTouchActions() == 0);
    CHECK(inner->GetTouchActions() == kTouchAuto); // a word it does not know: the declaration dropped
    styles.SetStyleSheet(CSSParser::Parse(SV(u8".outer { touch-action: manipulation; }")));
    styles.ApplyTree(*root.Get());
    CHECK(outer->GetTouchActions() == kTouchAuto);
}

TEST_CASE("gestures: two fingers over a node that keeps pinch-zoom pinch, turn and pan it as one")
{
    Bed bed(kTouchPanX | kTouchPanY); // pinch-zoom left out: two fingers are the node's
    EventDispatcher& d = bed.d();
    d.InjectTouchDown(1u, core::Float2{150.0f, 200.0f});
    CHECK(d.InjectTouchDown(2u, core::Float2{250.0f, 200.0f}));
    CHECK(d.IsGesturing());
    REQUIRE(bed.seen.Size() >= 2u);
    CHECK(bed.Saw(u8"pointercancel")); // the first finger's press: a gesture, not a tap
    CHECK(bed.seen.Back() == core::String(u8"gesturestart"));

    // Spread from 100 apart to 200: twice the scale, about the same middle.
    d.InjectTouchMove(1u, core::Float2{100.0f, 200.0f});
    d.InjectTouchMove(2u, core::Float2{300.0f, 200.0f});
    CHECK(bed.last.Scale == doctest::Approx(2.0f));
    CHECK(bed.last.Translation.x == doctest::Approx(0.0f));
    // The deltas multiply up to the total.
    f32 product = 1.0f;
    for (const GestureEvent& e : bed.changes)
        product *= e.ScaleDelta;
    CHECK(product == doctest::Approx(2.0f));

    // Turned a quarter, clockwise (y runs down): the second finger below the middle.
    d.InjectTouchMove(1u, core::Float2{200.0f, 100.0f});
    d.InjectTouchMove(2u, core::Float2{200.0f, 300.0f});
    CHECK(bed.last.Rotation == doctest::Approx(core::kPi * 0.5f).epsilon(0.01));
    CHECK(bed.last.Scale == doctest::Approx(2.0f));

    d.InjectTouchUp(2u, core::Float2{200.0f, 300.0f});
    CHECK_FALSE(d.IsGesturing());
    CHECK(bed.seen.Back() == core::String(u8"gestureend"));
    CHECK(bed.last.Rotation == doctest::Approx(core::kPi * 0.5f).epsilon(0.01));
    d.InjectTouchUp(1u, core::Float2{200.0f, 100.0f});
    CHECK_FALSE(bed.Saw(u8"click"));
}

TEST_CASE("gestures: a two-finger pan's translation is in the GUI's units, at any scale and any turn of the node")
{
    Bed bed(0);
    bed.root->SetDisplayScale(2.0f); // device pixels twice the root's units
    (void)bed.root->UpdateLayout();
    EventDispatcher& d = bed.d();
    d.InjectTouchDown(1u, core::Float2{300.0f, 300.0f});
    d.InjectTouchDown(2u, core::Float2{400.0f, 300.0f});
    d.InjectTouchMove(1u, core::Float2{340.0f, 260.0f});
    d.InjectTouchMove(2u, core::Float2{440.0f, 260.0f});
    CHECK(bed.last.Translation.x == doctest::Approx(20.0f)); // 40 device pixels: 20 units
    CHECK(bed.last.Translation.y == doctest::Approx(-20.0f));
    CHECK(bed.last.Scale == doctest::Approx(1.0f));
    d.InjectTouchUp(2u, core::Float2{440.0f, 260.0f});
    d.InjectTouchUp(1u, core::Float2{340.0f, 260.0f});

    // Turned a quarter by its last gesture, as a viewer turns its picture: a move across is still across.
    bed.pad->SetRotationOrigin(core::Float2{150.0f, 150.0f}); // about its middle: still under the fingers
    bed.pad->SetRotation(core::kPi * 0.5f);
    (void)bed.root->UpdateLayout();
    d.InjectTouchDown(1u, core::Float2{300.0f, 300.0f});
    d.InjectTouchDown(2u, core::Float2{400.0f, 300.0f});
    REQUIRE(d.IsGesturing());
    d.InjectTouchMove(1u, core::Float2{340.0f, 300.0f});
    d.InjectTouchMove(2u, core::Float2{440.0f, 300.0f});
    CHECK(bed.last.Translation.x == doctest::Approx(20.0f));
    CHECK(bed.last.Translation.y == doctest::Approx(0.0f).epsilon(0.001));
}

TEST_CASE("gestures: over a node that leaves pinch-zoom to the GUI, a second finger does nothing")
{
    Bed bed(kTouchAuto);
    EventDispatcher& d = bed.d();
    d.InjectTouchDown(1u, core::Float2{150.0f, 200.0f});
    CHECK_FALSE(d.InjectTouchDown(2u, core::Float2{250.0f, 200.0f}));
    CHECK_FALSE(d.IsGesturing());
    (void)d.InjectTouchUp(2u, core::Float2{250.0f, 200.0f});
    d.InjectTouchUp(1u, core::Float2{150.0f, 200.0f});
    CHECK(bed.Saw(u8"click")); // the first finger still taps
    CHECK_FALSE(bed.Saw(u8"gesturestart"));
}

TEST_CASE("gestures: one cancelled, or whose node leaves the tree, ends as cancelled")
{
    {
        Bed bed(0);
        EventDispatcher& d = bed.d();
        d.InjectTouchDown(1u, core::Float2{150.0f, 200.0f});
        d.InjectTouchDown(2u, core::Float2{250.0f, 200.0f});
        d.CancelGesture(); // the platform took a finger back
        CHECK_FALSE(d.IsGesturing());
        CHECK(bed.seen.Back() == core::String(u8"gesturecancel"));
    }
    {
        Bed bed(0);
        EventDispatcher& d = bed.d();
        d.InjectTouchDown(1u, core::Float2{150.0f, 200.0f});
        d.InjectTouchDown(2u, core::Float2{250.0f, 200.0f});
        bed.pad->RemoveFromParent();
        const usize before = bed.seen.Size();
        d.InjectTouchMove(1u, core::Float2{140.0f, 200.0f});
        CHECK_FALSE(d.IsGesturing());
        CHECK(bed.seen.Size() == before); // gone: it hears nothing more
    }
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
