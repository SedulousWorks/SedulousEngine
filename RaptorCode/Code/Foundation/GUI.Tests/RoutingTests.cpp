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

TEST_CASE("routing: a press goes down through capture, reaches its target, and comes back up")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    auto inner = Box(*card.Get(), 10, 10, 100, 100, u8"inner");
    Trace trace;
    trace.Watch(*card.Get(), EventType::MouseDown);
    trace.Watch(*inner.Get(), EventType::MouseDown);
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(trace.Is({u8"card capture", u8"inner target", u8"inner target", u8"card bubble"}));
    d->InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left);

    // A parent handling the press in capture keeps it from its child (a list taking a drag).
    trace.calls.Clear();
    (void)card->AddEventListener(EventType::MouseDown, [](const Event& e) { e.Handled = true; }, true);
    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(trace.Is({u8"card capture"}));
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

TEST_CASE("routing: a handler removing the nodes above it does not break the walk")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    auto inner = Box(*card.Get(), 10, 10, 100, 100, u8"inner");
    int cardSaw = 0;
    (void)card->AddEventListener(EventType::MouseDown, [&](const Event&) { ++cardSaw; });
    (void)inner->AddEventListener(EventType::MouseDown, [&](const Event&) { root->RemoveChild(card.Get()); });
    root->GetEventDispatcher()->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(card->GetParent() == nullptr);
    CHECK(cardSaw == 0); // it left the tree before the press came back up
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

TEST_CASE("routing: every node under the pointer is hovered, and told as it joins or leaves")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    auto a = Box(*card.Get(), 10, 10, 50, 50, u8"a");
    auto b = Box(*card.Get(), 100, 10, 50, 50, u8"b");
    int cardEnters = 0, cardLeaves = 0, aLeaves = 0, bEnters = 0;
    (void)card->AddEventListener(EventType::MouseEnter, [&](const Event&) { ++cardEnters; });
    (void)card->AddEventListener(EventType::MouseLeave, [&](const Event&) { ++cardLeaves; });
    (void)a->AddEventListener(EventType::MouseLeave, [&](const Event&) { ++aLeaves; });
    (void)b->AddEventListener(EventType::MouseEnter, [&](const Event&) { ++bEnters; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(core::Float2{20.0f, 20.0f});
    CHECK(a->IsHovered());
    CHECK(card->IsHovered()); // :hover holds for the card while a is under the pointer
    CHECK(cardEnters == 1);
    d->InjectMouseMove(core::Float2{110.0f, 20.0f}); // a to b, inside the card
    CHECK_FALSE(a->IsHovered());
    CHECK(b->IsHovered());
    CHECK(aLeaves == 1);
    CHECK(bEnters == 1);
    CHECK(cardEnters == 1); // never left
    CHECK(cardLeaves == 0);
    d->InjectMouseMove(core::Float2{300.0f, 300.0f});
    CHECK_FALSE(card->IsHovered());
    CHECK(cardLeaves == 1);
    CHECK(d->GetOverNode() == root.Get());
}

TEST_CASE("routing: the pressed node and the nodes holding it are pressed until the release")
{
    auto root = MakeRoot();
    auto card = Box(*root.Get(), 0, 0, 200, 200, u8"card");
    auto a = Box(*card.Get(), 10, 10, 50, 50, u8"a");
    auto other = Box(*root.Get(), 250, 0, 50, 50, u8"other");
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(a->IsPressed());
    CHECK(card->IsPressed());
    CHECK_FALSE(other->IsPressed());
    d->InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK_FALSE(a->IsPressed());
    CHECK_FALSE(card->IsPressed());
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

TEST_CASE("routing: pointer capture holds the moves and the release, and is lost when it ends")
{
    auto root = MakeRoot();
    auto knob = Box(*root.Get(), 0, 0, 50, 50, u8"knob");
    auto other = Box(*root.Get(), 200, 0, 50, 50, u8"other");
    int knobMoves = 0, otherMoves = 0, lost = 0;
    (void)knob->AddEventListener(EventType::MouseMove, [&](const Event&) { ++knobMoves; });
    (void)other->AddEventListener(EventType::MouseMove, [&](const Event&) { ++otherMoves; });
    (void)knob->AddEventListener(EventType::PointerCaptureLost, [&](const Event&) { ++lost; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->CapturePointer(*knob.Get());
    d->InjectMouseMove(core::Float2{210.0f, 10.0f}); // over the other node
    CHECK(knobMoves == 1);
    CHECK(otherMoves == 0);
    CHECK(other->IsHovered()); // hover still follows the pointer
    d->InjectMouseUp(core::Float2{210.0f, 10.0f}, MouseButton::Left);
    CHECK(lost == 1); // the press ended it
    CHECK(d->GetPointerCapture() == nullptr);

    d->CapturePointer(*knob.Get());
    d->CapturePointer(*other.Get()); // taken by another
    CHECK(lost == 2);
    int otherLost = 0;
    (void)other->AddEventListener(EventType::PointerCaptureLost, [&](const Event&) { ++otherLost; });
    d->CapturePointer(*knob.Get()); // taken back
    CHECK(otherLost == 1);
    root->RemoveChild(knob.Get()); // leaving the tree
    CHECK(lost == 3);
    CHECK(d->GetPointerCapture() == nullptr);
}

TEST_CASE("routing: presses near in time and place count up; a pause or a move starts again")
{
    auto root = MakeRoot();
    auto box = Box(*root.Get(), 0, 0, 100, 100, u8"box");
    core::Array<core::u32> counts;
    (void)box->AddEventListener(EventType::MouseDown, [&](const Event& e) {
        counts.PushBack(static_cast<const MouseEvent&>(e).ClickCount);
    });
    EventDispatcher* d = root->GetEventDispatcher();
    auto press = [d](f32 x) {
        d->InjectMouseDown(core::Float2{x, 10.0f}, MouseButton::Left);
        d->InjectMouseUp(core::Float2{x, 10.0f}, MouseButton::Left);
    };
    press(10.0f);
    press(12.0f);
    press(11.0f);
    d->Tick(1.0f); // a pause
    press(11.0f);
    press(60.0f); // far away
    REQUIRE(counts.Size() == 5u);
    CHECK(counts[0] == 1u);
    CHECK(counts[1] == 2u);
    CHECK(counts[2] == 3u);
    CHECK(counts[3] == 1u);
    CHECK(counts[4] == 1u);
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

TEST_CASE("routing: the first finger drives the pointer; moves follow it and a second finger is ignored")
{
    auto root = MakeRoot();
    auto a = Box(*root.Get(), 0, 0, 50, 50, u8"a");
    auto b = Box(*root.Get(), 100, 0, 50, 50, u8"b");
    int downs = 0, moves = 0;
    (void)root->AddEventListener(EventType::MouseDown, [&](const Event&) { ++downs; });
    (void)a->AddEventListener(EventType::MouseMove, [&](const Event&) { ++moves; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectTouchDown(1u, core::Float2{10.0f, 10.0f});
    CHECK_FALSE(d->InjectTouchDown(2u, core::Float2{110.0f, 10.0f})); // a second finger
    CHECK_FALSE(d->InjectTouchMove(2u, core::Float2{120.0f, 10.0f}));
    CHECK(downs == 1);
    d->InjectTouchMove(1u, core::Float2{110.0f, 10.0f}); // the press holds the moves for a
    CHECK(moves == 1);
    CHECK(b->IsHovered()); // and hover follows the finger
    CHECK_FALSE(d->InjectTouchUp(2u, core::Float2{120.0f, 10.0f}));
    CHECK(d->IsTouchActive());
    d->InjectTouchUp(1u, core::Float2{110.0f, 10.0f});
    CHECK_FALSE(d->IsTouchActive());
}

TEST_CASE("routing: every finger down is followed, where it went down and where it is, until it lifts")
{
    auto root = MakeRoot();
    EventDispatcher* d = root->GetEventDispatcher();
    CHECK(d->GetFingers().Size() == 0u);
    d->InjectTouchDown(1u, core::Float2{10.0f, 10.0f});
    (void)d->InjectTouchDown(2u, core::Float2{110.0f, 10.0f});
    (void)d->InjectTouchMove(2u, core::Float2{120.0f, 30.0f});
    REQUIRE(d->GetFingers().Size() == 2u);
    CHECK(d->GetFingers()[1].Id == 2u);
    CHECK(d->GetFingers()[1].Start.x == doctest::Approx(110.0f));
    CHECK(d->GetFingers()[1].Now.x == doctest::Approx(120.0f));
    CHECK(d->GetFingers()[1].Now.y == doctest::Approx(30.0f));
    // The first lifting leaves the second followed, and the pointer free.
    d->InjectTouchUp(1u, core::Float2{10.0f, 10.0f});
    REQUIRE(d->GetFingers().Size() == 1u);
    CHECK(d->GetFingers()[0].Id == 2u);
    CHECK_FALSE(d->IsTouchActive());
    (void)d->InjectTouchUp(2u, core::Float2{120.0f, 30.0f});
    CHECK(d->GetFingers().Size() == 0u);
}

TEST_CASE("routing: taps count as a double tap over a wider distance than clicks")
{
    auto root = MakeRoot();
    auto box = Box(*root.Get(), 0, 0, 200, 200, u8"box");
    core::Array<core::u32> counts;
    (void)box->AddEventListener(EventType::MouseDown, [&](const Event& e) {
        counts.PushBack(static_cast<const MouseEvent&>(e).ClickCount);
    });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectTouchDown(1u, core::Float2{50.0f, 50.0f});
    d->InjectTouchUp(1u, core::Float2{50.0f, 50.0f});
    d->InjectTouchDown(2u, core::Float2{68.0f, 50.0f}); // 18 apart: a finger's wobble
    d->InjectTouchUp(2u, core::Float2{68.0f, 50.0f});
    d->Tick(1.0f);
    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    d->InjectMouseDown(core::Float2{68.0f, 50.0f}, MouseButton::Left); // too far for a mouse
    REQUIRE(counts.Size() == 4u);
    CHECK(counts[1] == 2u);
    CHECK(counts[3] == 1u);
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
