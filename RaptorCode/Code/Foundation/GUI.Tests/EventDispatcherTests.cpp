// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - EventDispatcher tests: hover enter/leave, click, focus (click + program-
// matic), key/text routing to the focus node, and interaction-ref cleanup. Input is
// injected as abstract events (the shell bridge's job), hit-tested via the tree's OverFind.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    core::RefPtr<SceneRoot> MakeScene(core::Float2 size)
    {
        auto s = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        s->SetSize(size);
        return s;
    }
    core::RefPtr<Node> MakePanel(core::Float2 pos, core::Float2 size)
    {
        auto n = core::MakeRef<Node>(core::DefaultAllocator());
        n->SetSize(size);
        n->SetPosition(pos);
        return n;
    }
}

TEST_CASE("dispatch: hover enter/leave tracks the node under the cursor")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto child = MakePanel(core::Float2{10.0f, 10.0f}, core::Float2{50.0f, 50.0f});
    root->AddChild(child.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int enter = 0, leave = 0;
    child->AddEventListener(EventType::MouseEnter, [&](const Event&) { ++enter; });
    child->AddEventListener(EventType::MouseLeave, [&](const Event&) { ++leave; });

    d->InjectMouseMove(core::Float2{20.0f, 20.0f}); // over child
    CHECK(d->GetOverNode() == child.Get());
    CHECK(enter == 1);
    CHECK(leave == 0);

    d->InjectMouseMove(core::Float2{120.0f, 120.0f}); // off child, over root
    CHECK(d->GetOverNode() == root.Get());
    CHECK(leave == 1);
}

TEST_CASE("dispatch: press+release on the same node is a click and focuses it")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto child = MakePanel(core::Float2{10.0f, 10.0f}, core::Float2{50.0f, 50.0f});
    child->SetTabFocusable(true); // a widget that takes focus
    root->AddChild(child.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int clicks = 0;
    child->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });

    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(clicks == 1);
    CHECK(d->GetFocusNode() == child.Get());
    CHECK(child->IsFocused());

    // A click on what does not take focus (a backdrop) clears it, still delivering the click; one
    // on a child of a focusable widget focuses that widget.
    auto backdrop = MakePanel(core::Float2{100.0f, 100.0f}, core::Float2{50.0f, 50.0f});
    root->AddChild(backdrop.Get());
    int backdropClicks = 0;
    backdrop->AddEventListener(EventType::MouseClick, [&](const Event&) { ++backdropClicks; });
    d->InjectMouseDown(core::Float2{120.0f, 120.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{120.0f, 120.0f}, MouseButton::Left);
    CHECK(backdropClicks == 1);
    CHECK(d->GetFocusNode() == nullptr);
    auto inner = MakePanel(core::Float2{5.0f, 5.0f}, core::Float2{10.0f, 10.0f});
    child->AddChild(inner.Get());
    d->InjectMouseDown(core::Float2{20.0f, 20.0f}, MouseButton::Left);
    CHECK(d->GetFocusNode() == child.Get());
}

TEST_CASE("dispatch: a press in a node that keeps the focus leaves it where it is")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto field = MakePanel(core::Float2{10.0f, 10.0f}, core::Float2{50.0f, 50.0f});
    field->SetTabFocusable(true);
    root->AddChild(field.Get());
    auto list = MakePanel(core::Float2{100.0f, 100.0f}, core::Float2{80.0f, 80.0f});
    list->SetKeepsFocus(true); // a completion list
    root->AddChild(list.Get());
    auto row = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{80.0f, 20.0f});
    list->AddChild(row.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    field->RequestFocus();
    REQUIRE(d->GetFocusNode() == field.Get());
    int clicks = 0;
    row->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    d->InjectMouseDown(core::Float2{110.0f, 105.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{110.0f, 105.0f}, MouseButton::Left);
    CHECK(clicks == 1);
    CHECK(d->GetFocusNode() == field.Get()); // kept
    // A focusable widget inside it still takes the focus.
    auto button = MakePanel(core::Float2{0.0f, 40.0f}, core::Float2{80.0f, 20.0f});
    button->SetTabFocusable(true);
    list->AddChild(button.Get());
    d->InjectMouseDown(core::Float2{110.0f, 145.0f}, MouseButton::Left);
    CHECK(d->GetFocusNode() == button.Get());
}

TEST_CASE("dispatch: mouse event payload is accessible via static_cast")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    core::Float2 seen{-1.0f, -1.0f};
    root->AddEventListener(EventType::MouseMove, [&](const Event& e)
                           { seen = static_cast<const MouseEvent&>(e).Position; });

    d->InjectMouseMove(core::Float2{33.0f, 44.0f});
    CHECK(seen.x == doctest::Approx(33.0f));
    CHECK(seen.y == doctest::Approx(44.0f));
}

TEST_CASE("dispatch: key and text route to the focus node")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto child = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 50.0f});
    root->AddChild(child.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int keys = 0, texts = 0;
    core::StringView lastText;
    child->AddEventListener(EventType::KeyDown, [&](const Event&) { ++keys; });
    child->AddEventListener(EventType::TextInput,
                            [&](const Event& e)
                            {
                                ++texts;
                                lastText = static_cast<const TextInputEvent&>(e).Text;
                            });

    d->InjectKeyDown(65); // no focus yet -> dropped
    CHECK(keys == 0);

    d->SetFocusNode(child.Get());
    d->InjectKeyDown(65);
    d->InjectText(core::StringView(u8"hi"));
    CHECK(keys == 1);
    CHECK(texts == 1);
    CHECK(lastText == core::StringView(u8"hi"));
}

TEST_CASE("dispatch: programmatic focus gains and releases")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto a = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 50.0f});
    auto b = MakePanel(core::Float2{60.0f, 0.0f}, core::Float2{50.0f, 50.0f});
    root->AddChild(a.Get());
    root->AddChild(b.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    a->RequestFocus();
    CHECK(d->GetFocusNode() == a.Get());
    CHECK(a->IsFocused());

    b->RequestFocus(); // moves focus: a loses, b gains
    CHECK(d->GetFocusNode() == b.Get());
    CHECK_FALSE(a->IsFocused());
    CHECK(b->IsFocused());

    b->ReleaseFocus();
    CHECK(d->GetFocusNode() == nullptr);
    CHECK_FALSE(b->IsFocused());
}

TEST_CASE("dispatch: a subtree leaving the tree takes the hover, press and focus refs into it")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto panel = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    auto child = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 50.0f});
    auto other = MakePanel(core::Float2{100.0f, 100.0f}, core::Float2{50.0f, 50.0f});
    panel->AddChild(child.Get());
    root->AddChild(panel.Get());
    root->AddChild(other.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseMove(core::Float2{10.0f, 10.0f});
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->SetFocusNode(child.Get());
    REQUIRE(d->GetOverNode() == child.Get());
    REQUIRE(d->GetFocusNode() == child.Get());

    root->RemoveChild(panel.Get()); // the child goes with its parent
    CHECK(d->GetOverNode() == root.Get()); // what is still under the pointer
    CHECK_FALSE(child->IsHovered());
    CHECK(d->GetFocusNode() == nullptr);
    CHECK_FALSE(child->IsFocused()); // told it lost focus while it still lived
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left); // no press to finish
    d->InjectMouseMove(core::Float2{120.0f, 120.0f});
    CHECK(d->GetOverNode() == other.Get());

    // A node leaving elsewhere leaves the refs alone.
    d->SetFocusNode(other.Get());
    root->AddChild(panel.Get());
    root->RemoveChild(panel.Get());
    CHECK(d->GetOverNode() == other.Get());
    CHECK(d->GetFocusNode() == other.Get());
}

TEST_CASE("dispatch: a popup leaving the tree, or with its owner, is dropped and told why")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto opener = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    auto popup = MakePanel(core::Float2{0.0f, 20.0f}, core::Float2{50.0f, 80.0f});
    root->AddChild(opener.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    PopupCloseReason why = PopupCloseReason::Code;
    int closes = 0;
    const auto open = [&]
    {
        PopupOptions options;
        options.OnClosed = [&](PopupCloseReason reason) { ++closes; why = reason; };
        d->OpenPopup(*opener, *popup, core::Move(options));
    };
    open();
    CHECK(popup->GetParent() == opener.Get()); // the opener's child while open
    CHECK(popup->IsInTopLayer());
    popup->RemoveFromParent();
    CHECK(d->PopupCount() == 0u);
    CHECK(closes == 1);
    CHECK(why == PopupCloseReason::OwnerRemoved);
    CHECK_FALSE(popup->IsInTopLayer());

    open();
    root->RemoveChild(opener.Get());
    CHECK(d->PopupCount() == 0u);
    CHECK(closes == 2);
    CHECK(why == PopupCloseReason::OwnerRemoved);
}

TEST_CASE("dispatch: a disabled widget, or one inside a disabled panel, takes no pointer input")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto backdrop = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{200.0f, 200.0f});
    auto panel = MakePanel(core::Float2{100.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    auto button = core::MakeRef<Button>(core::DefaultAllocator());
    auto inner = core::MakeRef<Button>(core::DefaultAllocator());
    button->SetSize(core::Float2{50.0f, 20.0f});
    inner->SetSize(core::Float2{50.0f, 20.0f});
    root->AddChild(backdrop.Get());
    root->AddChild(button.Get());
    root->AddChild(panel.Get());
    panel->AddChild(inner.Get());
    int clicks = 0, innerClicks = 0, behind = 0, enters = 0;
    button->SetOnClick([&] { ++clicks; });
    inner->SetOnClick([&] { ++innerClicks; });
    (void)backdrop->AddEventListener(EventType::MouseDown, [&](const Event&) { ++behind; });
    (void)button->AddEventListener(EventType::MouseEnter, [&](const Event&) { ++enters; });
    EventDispatcher* d = root->GetEventDispatcher();
    auto click = [d](core::Float2 at)
    {
        d->InjectMouseMove(at);
        d->InjectMouseDown(at, MouseButton::Left);
        d->InjectMouseUp(at, MouseButton::Left);
    };

    button->SetEnabled(false);
    click(core::Float2{10.0f, 10.0f});
    CHECK(clicks == 0);
    CHECK(behind == 0);        // it still covers what lies behind it
    CHECK(enters == 1);        // and is still hovered (a tooltip says why it is disabled)
    CHECK(d->GetFocusNode() == nullptr);
    button->SetEnabled(true);
    click(core::Float2{10.0f, 10.0f});
    CHECK(clicks == 1);

    panel->SetEnabled(false);
    CHECK_FALSE(inner->IsTreeEnabled());
    click(core::Float2{110.0f, 10.0f});
    CHECK(innerClicks == 0);
    d->SetFocusNode(inner.Get());
    CHECK_FALSE(d->Activate()); // nor by the keyboard
    CHECK(innerClicks == 0);
}

TEST_CASE("dispatch: Tab navigation cycles through tab-focusable nodes in order")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto a = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    auto skip = MakePanel(core::Float2{0.0f, 20.0f}, core::Float2{50.0f, 20.0f}); // NOT focusable
    auto b = MakePanel(core::Float2{0.0f, 40.0f}, core::Float2{50.0f, 20.0f});
    auto c = MakePanel(core::Float2{0.0f, 60.0f}, core::Float2{50.0f, 20.0f});
    a->SetTabFocusable(true);
    b->SetTabFocusable(true);
    c->SetTabFocusable(true);
    root->AddChild(a.Get());
    root->AddChild(skip.Get());
    root->AddChild(b.Get());
    root->AddChild(c.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Nothing focused -> Tab lands on the first stop.
    CHECK(d->FocusNext());
    CHECK(d->GetFocusNode() == a.Get());
    // Tab skips the non-focusable node.
    CHECK(d->FocusNext());
    CHECK(d->GetFocusNode() == b.Get());
    CHECK(d->FocusNext());
    CHECK(d->GetFocusNode() == c.Get());
    // Wraps back to the first.
    CHECK(d->FocusNext());
    CHECK(d->GetFocusNode() == a.Get());
    // Shift+Tab goes backwards (wraps to the last).
    CHECK(d->FocusPrevious());
    CHECK(d->GetFocusNode() == c.Get());
}

TEST_CASE("dispatch: the Tab key drives focus traversal (Shift+Tab reverses)")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto a = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    auto b = MakePanel(core::Float2{0.0f, 40.0f}, core::Float2{50.0f, 20.0f});
    a->SetTabFocusable(true);
    b->SetTabFocusable(true);
    root->AddChild(a.Get());
    root->AddChild(b.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Tab));
    CHECK(d->GetFocusNode() == a.Get());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Tab));
    CHECK(d->GetFocusNode() == b.Get());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModShift);
    CHECK(d->GetFocusNode() == a.Get());
}

TEST_CASE("dispatch: Tab is consumed (not routed) but other keys still reach the focus node")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto a = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{50.0f, 20.0f});
    a->SetTabFocusable(true);
    root->AddChild(a.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int tabKeys = 0, otherKeys = 0;
    a->AddEventListener(EventType::KeyDown,
                        [&](const Event& e)
                        {
                            if (static_cast<const KeyEvent&>(e).KeyCode ==
                                static_cast<core::u32>(KeyCode::Tab))
                                ++tabKeys;
                            else
                                ++otherKeys;
                        });

    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Tab)); // focuses a, consumed
    CHECK(d->GetFocusNode() == a.Get());
    CHECK(tabKeys == 0);                                     // the widget never saw the Tab
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Home)); // a real key routes through
    CHECK(otherKeys == 1);
}

TEST_CASE("dispatch: only the left button synthesizes a click (right/middle do not activate)")
{
    auto root = MakeScene(core::Float2{200.0f, 200.0f});
    auto child = MakePanel(core::Float2{0.0f, 0.0f}, core::Float2{100.0f, 100.0f});
    root->AddChild(child.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int clicks = 0, downs = 0;
    child->AddEventListener(EventType::MouseClick, [&](const Event&) { ++clicks; });
    child->AddEventListener(EventType::MouseDown, [&](const Event&) { ++downs; });

    // Right-click: down+up are delivered, but no click (no activation).
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Right);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Right);
    CHECK(downs == 1);
    CHECK(clicks == 0);

    // Left-click activates.
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1);
}

TEST_CASE("dispatcher: a move carries the modifiers held during it")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{100.0f, 100.0f});
    core::u32 seen = 0;
    (void)root->AddEventListener(EventType::MouseMove, [&](const Event& e) { seen = static_cast<const MouseEvent&>(e).Modifiers; });
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(core::Float2{10.0f, 10.0f}, KeyModShift);
    CHECK(seen == static_cast<core::u32>(KeyModShift));
    d->InjectMouseMove(core::Float2{12.0f, 10.0f});
    CHECK(seen == 0u);
}
