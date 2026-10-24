// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - input routing (E1 of Specs/gui-lab-evolution.md): an input event goes down from the root
// (capture), reaches its target, and comes back up (bubble), each node's own handler running in
// the bubble phase and a handled event ending the route after its node; the hover and press paths
// (every node under the pointer is hovered, every node holding the pressed one is pressed);
// pointer capture and its loss; a click on the nearest node holding the press and the release;
// click counts; and what the Inject calls tell a host.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{400.0f, 400.0f});
        return root;
    }
    core::RefPtr<UIWidget> Box(Node& parent, f32 x, f32 y, f32 w, f32 h, const char8_t* id)
    {
        auto box = Make<UIWidget>();
        box->SetPosition(core::Float2{x, y});
        box->SetSize(core::Float2{w, h});
        box->SetId(SV(id));
        parent.AddChild(box.Get());
        return box;
    }
    core::String Name(const Node* node)
    {
        const UIWidget* widget = Cast<UIWidget>(node);
        return widget != nullptr ? core::String(widget->GetId()) : core::String(u8"root");
    }
    core::String PhaseName(EventPhase phase)
    {
        return core::String(phase == EventPhase::Capture ? u8"capture" : phase == EventPhase::Target ? u8"target" : u8"bubble");
    }
    // Records "<node> <phase>" for every listener call on the listed nodes, capture and bubble.
    struct Trace
    {
        core::Array<core::String> calls;
        void Watch(Node& node, EventType type)
        {
            for (int pass = 0; pass < 2; ++pass)
                (void)node.AddEventListener(
                    type,
                    [this, &node](const Event& e)
                    {
                        core::String line = Name(&node);
                        line += SV(u8" ");
                        line += PhaseName(e.Phase);
                        calls.PushBack(line);
                    },
                    pass == 0); // capture, then bubble
        }
        template <usize N>
        [[nodiscard]] bool Is(const char8_t* const (&expected)[N]) const
        {
            if (calls.Size() != N)
                return false;
            for (usize i = 0; i < N; ++i)
                if (calls[i].AsView() != SV(expected[i]))
                    return false;
            return true;
        }
    };
}

TEST_CASE("routing: a handled event ends after its node; the node's own listeners still run")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    auto button = Make<Button>();
    button->SetSize(core::Float2{80.0f, 30.0f});
    card->AddChild(button.Get());
    int buttonClicks = 0, cardClicks = 0;
    button->SetOnClick([&] { ++buttonClicks; });
    (void)button->AddEventListener(EventType::MouseClick, [&](const Event&) { ++buttonClicks; });
    (void)card->AddEventListener(EventType::MouseClick, [&](const Event&) { ++cardClicks; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(buttonClicks == 2); // its handler and its listener
    CHECK(cardClicks == 0);   // the button took the click
    d->InjectMouseDown(core::Float2{150.0f, 150.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{150.0f, 150.0f}, MouseButton::Left);
    CHECK(cardClicks == 1);
}

TEST_CASE("routing: keys bubble from the focus; a scroller scrolls only when it is focused")
{
    auto root = MakeRoot();
    auto page = Box(*root.Get(), 0, 0, 300, 300, u8"page");
    auto field = Box(*page.Get(), 10, 10, 100, 30, u8"field");
    field->SetTabFocusable(true);
    int pageKeys = 0;
    (void)page->AddEventListener(EventType::KeyDown, [&](const Event&) { ++pageKeys; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->SetFocusNode(field.Get());
    CHECK_FALSE(d->InjectKeyDown(static_cast<core::u32>(KeyCode::F5))); // nobody used it
    CHECK(pageKeys == 1);

    auto scroller = Make<ScrollView>();
    scroller->SetSize(core::Float2{100.0f, 100.0f});
    root->AddChild(scroller.Get());
    (void)Box(*scroller.Get(), 0, 0, 10, 400, u8"tall"); // what it scrolls over
    auto inside = Box(*scroller.Get(), 0, 0, 50, 20, u8"inside");
    root->UpdateLayout();
    inside->SetTabFocusable(true);
    d->SetFocusNode(inside.Get());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::PageDown));
    CHECK(scroller->GetScrollOffset().y == doctest::Approx(0.0f)); // the key was the widget's to leave
    d->SetFocusNode(scroller.Get());
    CHECK(d->InjectKeyDown(static_cast<core::u32>(KeyCode::PageDown)));
    CHECK(scroller->GetScrollOffset().y > 0.0f);
}

TEST_CASE("routing: the wheel goes up from the pointer; a scroller at its end leaves it to the one around it")
{
    auto root = MakeRoot();
    auto outer = Make<ScrollView>();
    outer->SetSize(core::Float2{200.0f, 200.0f});
    root->AddChild(outer.Get());
    (void)Box(*outer.Get(), 150, 0, 10, 800, u8"outer-tall");
    auto inner = Make<ScrollView>();
    inner->SetSize(core::Float2{100.0f, 100.0f});
    outer->AddChild(inner.Get());
    (void)Box(*inner.Get(), 0, 0, 10, 150, u8"inner-tall");
    root->UpdateLayout();
    EventDispatcher* d = root->GetEventDispatcher();
    CHECK(d->InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -10.0f}));
    CHECK(inner->GetScrollOffset().y > 0.0f);
    CHECK(outer->GetScrollOffset().y == doctest::Approx(0.0f));
    for (int i = 0; i < 20; ++i) // to the inner one's end, and on
        d->InjectMouseWheel(core::Float2{50.0f, 50.0f}, core::Float2{0.0f, -10.0f});
    CHECK(inner->GetScrollOffset().y == doctest::Approx(inner->GetScrollRange().y));
    CHECK(outer->GetScrollOffset().y > 0.0f);
}

TEST_CASE("routing: a click goes to the nearest node holding both the press and the release")
{
    auto root = MakeRoot();
    auto row = Box(*root.Get(), 0, 0, 300, 50, u8"row");
    auto a = Box(*row.Get(), 0, 0, 50, 50, u8"a");
    auto b = Box(*row.Get(), 100, 0, 50, 50, u8"b");
    core::Array<core::String> clicked;
    Node* const watched[] = {row.Get(), a.Get(), b.Get()};
    for (Node* node : watched)
        (void)node->AddEventListener(EventType::MouseClick, [&clicked, node](const Event& e) {
            if (e.Phase == EventPhase::Target)
                clicked.PushBack(Name(node));
        });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left); // on a
    d->InjectMouseUp(core::Float2{110.0f, 10.0f}, MouseButton::Left);  // released on b
    REQUIRE(clicked.Size() == 1u);
    CHECK(clicked[0] == core::String(u8"row"));

    // A button holding a label: a click on the label is the button's.
    auto button = Make<Button>();
    button->SetPosition(core::Float2{0.0f, 100.0f});
    button->SetSize(core::Float2{100.0f, 40.0f});
    root->AddChild(button.Get());
    auto caption = Make<Label>();
    caption->SetSize(core::Float2{60.0f, 20.0f});
    button->AddChild(caption.Get());
    int presses = 0;
    button->SetOnClick([&] { ++presses; });
    d->InjectMouseDown(core::Float2{10.0f, 105.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 105.0f}, MouseButton::Left);
    CHECK(presses == 1);
}

TEST_CASE("routing: the Inject calls tell a host whether the GUI used the input")
{
    auto root = MakeRoot();
    auto layer = Box(*root.Get(), 0, 0, 400, 400, u8"layer"); // a full-window layout container
    auto button = Make<Button>();
    button->SetPosition(core::Float2{10.0f, 10.0f});
    button->SetSize(core::Float2{80.0f, 30.0f});
    button->SetTabFocusable(true);
    layer->AddChild(button.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    CHECK(d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left));
    CHECK(d->InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left));
    CHECK_FALSE(d->InjectMouseDown(core::Float2{300.0f, 300.0f}, MouseButton::Left)); // the game's
    CHECK_FALSE(d->InjectMouseUp(core::Float2{300.0f, 300.0f}, MouseButton::Left));
    CHECK(d->IsPointerOver(core::Float2{20.0f, 20.0f}));
    CHECK_FALSE(d->IsPointerOver(core::Float2{300.0f, 300.0f}));
    NodeBox backdrop;
    backdrop.BackgroundColor = core::Color{0.0f, 0.0f, 0.0f, 0.5f};
    layer->SetBox(backdrop, false); // a backdrop that paints
    CHECK(d->IsPointerOver(core::Float2{300.0f, 300.0f}));

    d->SetFocusNode(button.Get());
    CHECK(d->InjectKeyDown(static_cast<core::u32>(KeyCode::Return))); // activated
    CHECK_FALSE(d->InjectKeyDown(static_cast<core::u32>(KeyCode::F7)));
}

TEST_CASE("routing: pointer-events and cursor come from a sheet; the cursor is the nearest set one")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    card->AddClass(SV(u8"card"));
    auto glass = Box(*root.Get(), 0, 0, 200, 200, u8"glass"); // over the card
    glass->AddClass(SV(u8"glass"));
    auto inner = Box(*card.Get(), 10, 10, 50, 50, u8"inner");
    StyleManager styles(CSSParser::Parse(SV(u8".glass { pointer-events: none; } .card { cursor: pointer; }")));
    styles.ApplyTree(*root.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(core::Float2{20.0f, 20.0f});
    CHECK(d->GetOverNode() == inner.Get()); // through the glass
    CHECK(d->GetCursor() == Cursor::Pointer); // the card's, inherited by the inner box
    inner->SetCursor(Cursor::Text);
    CHECK(d->GetCursor() == Cursor::Text);
    d->InjectMouseMove(core::Float2{300.0f, 300.0f});
    CHECK(d->GetCursor() == Cursor::Default);

    // While a press holds the pointer, the pressed node's look stays (a drag keeps its cursor).
    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    d->InjectMouseMove(core::Float2{300.0f, 300.0f});
    CHECK(d->GetCursor() == Cursor::Text);
    d->InjectMouseUp(core::Float2{300.0f, 300.0f}, MouseButton::Left);
    CHECK(d->GetCursor() == Cursor::Default);
}

TEST_CASE("routing: a tap is a press, a release and a click marked as touch, with no hover left behind")
{
    auto root = MakeRoot();
    auto button = Make<Button>();
    button->SetPosition(core::Float2{10.0f, 10.0f});
    button->SetSize(core::Float2{80.0f, 30.0f});
    root->AddChild(button.Get());
    core::Array<core::String> seen;
    const EventType kinds[] = {EventType::MouseDown, EventType::MouseUp, EventType::MouseClick};
    for (EventType type : kinds)
        (void)button->AddEventListener(type, [&seen](const Event& e) {
            const MouseEvent& m = static_cast<const MouseEvent&>(e);
            if (m.Pointer == PointerType::Touch && m.PointerId == 7u)
                seen.PushBack(core::String(e.Type == EventType::MouseDown ? u8"down" : e.Type == EventType::MouseUp ? u8"up" : u8"click"));
        });
    EventDispatcher* d = root->GetEventDispatcher();
    CHECK(d->InjectTouchDown(7u, core::Float2{20.0f, 20.0f}));
    CHECK(button->IsHovered()); // while the finger is down
    CHECK(button->IsPressed());
    CHECK(d->InjectTouchUp(7u, core::Float2{20.0f, 20.0f}));
    REQUIRE(seen.Size() == 3u);
    CHECK(seen[0] == core::String(u8"down"));
    CHECK(seen[1] == core::String(u8"up"));
    CHECK(seen[2] == core::String(u8"click"));
    CHECK_FALSE(button->IsHovered()); // the finger lifted: nothing under it
    CHECK(d->GetOverNode() == nullptr);
}

TEST_CASE("routing: CancelPointer ends a press with no click, and a slider drops its drag")
{
    auto root = MakeRoot();
    auto button = Make<Button>();
    button->SetSize(core::Float2{80.0f, 30.0f});
    root->AddChild(button.Get());
    int clicks = 0, cancels = 0;
    button->SetOnClick([&] { ++clicks; });
    (void)button->AddEventListener(EventType::PointerCancel, [&](const Event&) { ++cancels; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectTouchDown(1u, core::Float2{10.0f, 10.0f});
    d->CancelPointer(); // a scroller began panning under the finger
    CHECK(cancels == 1);
    CHECK_FALSE(button->IsPressed());
    d->InjectTouchUp(1u, core::Float2{10.0f, 10.0f});
    CHECK(clicks == 0);

    auto slider = Make<Slider>();
    slider->SetPosition(core::Float2{0.0f, 100.0f});
    slider->SetSize(core::Float2{200.0f, 20.0f});
    root->AddChild(slider.Get());
    d->InjectMouseDown(core::Float2{100.0f, 110.0f}, MouseButton::Left);
    const f32 before = slider->GetValue();
    d->CancelPointer();
    d->InjectMouseMove(core::Float2{190.0f, 110.0f});
    CHECK(slider->GetValue() == doctest::Approx(before)); // the drag ended with the press
    d->InjectMouseUp(core::Float2{190.0f, 110.0f}, MouseButton::Left);
}
