// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the button core (E6): toggle, activation on the press, repeat on the GUI's clock, groups by
// a name (per GUI) or a ButtonGroup, the arrows round a group, and the text, icon and indicator parts.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{400.0f, 300.0f});
        root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; }); // each at its own size
        return root;
    }

    template <typename T>
    core::RefPtr<T> Place(SceneRoot& root, core::Float2 at, core::Float2 size = core::Float2{80.0f, 30.0f})
    {
        auto b = Make<T>();
        b->SetPosition(at);
        b->SetSize(size);
        root.AddChild(b.Get());
        return b;
    }

    void Click(EventDispatcher& d, core::Float2 at)
    {
        d.InjectMouseMove(at);
        d.InjectMouseDown(at, MouseButton::Left);
        d.InjectMouseUp(at, MouseButton::Left);
    }
}

TEST_CASE("button: a toggle reports the user's change, not code's")
{
    auto root = MakeRoot();
    auto b = Place<Button>(*root, core::Float2{0.0f, 0.0f});
    core::i32 toggled = 0, changes = 0;
    bool last = false;
    b->SetOnToggled([&](bool on)
    {
        ++toggled;
        last = on;
    });
    b->AddEventListener(EventType::Changed, [&](const Event&) { ++changes; });

    b->SetChecked(true); // not a toggle yet: no state to set
    CHECK_FALSE(b->IsChecked());

    b->SetToggle(true);
    Click(*root->GetEventDispatcher(), core::Float2{10.0f, 10.0f});
    CHECK(b->IsChecked());
    CHECK(toggled == 1);
    CHECK(last);
    CHECK(changes == 1);
    CHECK((b->GetWidgetStates() & WidgetStateChecked) != 0);

    b->SetChecked(false); // code: reported to bindings only
    CHECK_FALSE(b->IsChecked());
    CHECK(toggled == 1);
    CHECK(changes == 1);
}

TEST_CASE("button: acting on the press activates once, with no click on the release")
{
    auto root = MakeRoot();
    auto b = Place<Button>(*root, core::Float2{0.0f, 0.0f});
    b->SetActionOnName(core::String(u8"press"));
    CHECK(b->GetActionOn() == ButtonAction::Press);
    core::i32 clicks = 0, heard = 0;
    b->SetOnClick([&]() { ++clicks; });
    b->AddEventListener(EventType::MouseClick, [&](const Event&) { ++heard; });
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1);
    CHECK(heard == 1); // a listener hears the activation as a click
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1);
    CHECK(heard == 1);

    // The next ordinary press clicks as usual on another button.
    auto other = Place<Button>(*root, core::Float2{100.0f, 0.0f});
    core::i32 otherClicks = 0;
    other->SetOnClick([&]() { ++otherClicks; });
    Click(*d, core::Float2{110.0f, 10.0f});
    CHECK(otherClicks == 1);
}

TEST_CASE("button: a repeat button repeats after its delay while held and over it")
{
    auto root = MakeRoot();
    auto b = Place<Button>(*root, core::Float2{0.0f, 0.0f});
    b->SetRepeat(true);
    b->SetRepeatDelay(0.5f);
    b->SetRepeatInterval(0.1f);
    core::i32 clicks = 0;
    b->SetOnClick([&]() { ++clicks; });
    EventDispatcher* d = root->GetEventDispatcher();
    GUIContext& gui = root->GetContext();

    d->InjectMouseMove(core::Float2{10.0f, 10.0f});
    d->InjectMouseDown(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 1); // the press
    gui.Update(core::Duration::FromSeconds(0.4));
    CHECK(clicks == 1); // within the delay
    gui.Update(core::Duration::FromSeconds(0.15)); // 0.05 past the delay
    CHECK(clicks == 1);
    gui.Update(core::Duration::FromSeconds(0.1)); // 0.15 past: one interval
    CHECK(clicks == 2);

    // Off it, it pauses; back over it, it goes on.
    d->InjectMouseMove(core::Float2{300.0f, 200.0f});
    gui.Update(core::Duration::FromSeconds(0.5));
    CHECK(clicks == 2);
    d->InjectMouseMove(core::Float2{10.0f, 10.0f});
    gui.Update(core::Duration::FromSeconds(0.1));
    CHECK(clicks == 3);

    // Released: no second click from the release, and no more repeats.
    d->InjectMouseUp(core::Float2{10.0f, 10.0f}, MouseButton::Left);
    CHECK(clicks == 3);
    gui.Update(core::Duration::FromSeconds(1.0));
    CHECK(clicks == 3);
}

TEST_CASE("button: radios of one name are a group within their GUI only")
{
    auto root = MakeRoot();
    auto low = Place<RadioButton>(*root, core::Float2{0.0f, 0.0f});
    auto mid = Place<RadioButton>(*root, core::Float2{0.0f, 40.0f});
    auto high = Place<RadioButton>(*root, core::Float2{0.0f, 80.0f});
    RadioButton* const radios[] = {low.Get(), mid.Get(), high.Get()};
    for (RadioButton* r : radios)
        r->SetName(core::String(u8"quality"));
    // Another GUI's radio of the same name is another group.
    auto otherRoot = MakeRoot();
    auto elsewhere = Place<RadioButton>(*otherRoot, core::Float2{0.0f, 0.0f});
    elsewhere->SetName(core::String(u8"quality"));
    elsewhere->SetChecked(true);

    core::Array<ButtonBase*> group;
    mid->CollectGroup(group);
    REQUIRE(group.Size() == 3);
    CHECK(group[0] == low.Get());
    CHECK(group[2] == high.Get());

    EventDispatcher* d = root->GetEventDispatcher();
    Click(*d, core::Float2{10.0f, 50.0f});
    CHECK(mid->IsChecked());
    Click(*d, core::Float2{10.0f, 90.0f});
    CHECK(high->IsChecked());
    CHECK_FALSE(mid->IsChecked());
    CHECK_FALSE(low->IsChecked());
    Click(*d, core::Float2{10.0f, 90.0f}); // a checked radio stays checked
    CHECK(high->IsChecked());
    CHECK(elsewhere->IsChecked());

    low->SetChecked(true); // code too keeps the group exclusive
    CHECK_FALSE(high->IsChecked());
}

TEST_CASE("button: a ButtonGroup makes toggles exclusive, and may allow none")
{
    auto root = MakeRoot();
    auto group = core::MakeRef<ButtonGroup>(core::DefaultAllocator());
    auto a = Place<Button>(*root, core::Float2{0.0f, 0.0f});
    auto b = Place<Button>(*root, core::Float2{100.0f, 0.0f});
    ButtonBase* changedTo = nullptr;
    group->SetOnChanged([&](ButtonBase* button) { changedTo = button; });
    Button* const buttons[] = {a.Get(), b.Get()};
    for (Button* x : buttons)
    {
        x->SetToggle(true);
        x->SetGroup(group);
    }
    CHECK(group->GetButtons().Size() == 2);

    EventDispatcher* d = root->GetEventDispatcher();
    Click(*d, core::Float2{10.0f, 10.0f});
    CHECK(a->IsChecked());
    CHECK(changedTo == a.Get());
    Click(*d, core::Float2{110.0f, 10.0f});
    CHECK(b->IsChecked());
    CHECK_FALSE(a->IsChecked());
    CHECK(group->GetChecked() == b.Get());
    Click(*d, core::Float2{110.0f, 10.0f}); // kept
    CHECK(b->IsChecked());

    group->SetAllowsNone(true);
    Click(*d, core::Float2{110.0f, 10.0f});
    CHECK_FALSE(b->IsChecked());
    CHECK(group->GetChecked() == nullptr);

    // A button that goes leaves its group.
    b->RemoveFromParent();
    b = core::RefPtr<Button>{};
    CHECK(group->GetButtons().Size() == 1);
}

TEST_CASE("button: the arrows move round an exclusive group, checking as they go")
{
    auto root = MakeRoot();
    auto r0 = Place<RadioButton>(*root, core::Float2{0.0f, 0.0f});
    auto r1 = Place<RadioButton>(*root, core::Float2{0.0f, 40.0f});
    auto r2 = Place<RadioButton>(*root, core::Float2{0.0f, 80.0f});
    RadioButton* const radios[] = {r0.Get(), r1.Get(), r2.Get()};
    for (RadioButton* r : radios)
        r->SetName(core::String(u8"g"));
    core::i32 changes = 0;
    r1->AddEventListener(EventType::Changed, [&](const Event&) { ++changes; });
    r1->SetEnabled(false);
    EventDispatcher* d = root->GetEventDispatcher();

    r0->RequestFocus();
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // past the disabled one
    CHECK(r2->IsFocused());
    CHECK(r2->IsChecked());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down)); // round to the first
    CHECK(r0->IsFocused());
    CHECK(r0->IsChecked());
    CHECK_FALSE(r2->IsChecked());

    r1->SetEnabled(true);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(r1->IsChecked());
    CHECK(changes == 1);
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Up));
    CHECK(r0->IsChecked());

    // An ungrouped toggle leaves the arrows to navigation.
    auto lone = Place<CheckBox>(*root, core::Float2{200.0f, 0.0f});
    lone->RequestFocus();
    (void)d->InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    CHECK_FALSE(lone->IsChecked());
}

TEST_CASE("button: in right to left Left moves on through an exclusive group and Right back")
{
    auto root = MakeRoot();
    root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    auto r0 = Place<RadioButton>(*root, core::Float2{0.0f, 0.0f});
    auto r1 = Place<RadioButton>(*root, core::Float2{0.0f, 40.0f});
    r0->SetName(core::String(u8"g"));
    r1->SetName(core::String(u8"g"));
    EventDispatcher* d = root->GetEventDispatcher();
    r0->RequestFocus();
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Left));
    CHECK(r1->IsChecked());
    d->InjectKeyDown(static_cast<core::u32>(KeyCode::Right));
    CHECK(r0->IsChecked());
}

TEST_CASE("button: its text and icon are parts after its indicator, in its text style")
{
    auto b = Make<Button>();
    CHECK(b->GetTextPart() == nullptr);
    CHECK(b->ChildCount() == 0);
    b->SetText(core::StringView(u8"Save"));
    REQUIRE(b->GetTextPart() != nullptr);
    CHECK(b->GetTextPart()->GetTag() == core::StringView(u8"text"));
    CHECK(b->GetText() == core::StringView(u8"Save"));
    CHECK_FALSE(b->GetTextPart()->IsHitTestVisible());

    auto icon = core::MakeRef<ImageDrawable>(core::DefaultAllocator()); // an icon: image content
    b->SetIcon(icon);
    REQUIRE(b->GetIconPart() != nullptr);
    CHECK(b->GetChildAt(0) == b->GetIconPart());
    CHECK(b->GetChildAt(1) == b->GetTextPart());

    b->SetTextColor(core::Color::Green);
    CHECK(b->GetTextPart()->GetTextColor() == core::Color::Green);

    b->SetIcon(core::RefPtr<Drawable>{});
    CHECK(b->GetIconPart() == nullptr);
    CHECK(b->ChildCount() == 1);

    auto check = Make<CheckBox>();
    check->SetText(core::StringView(u8"Music"));
    REQUIRE(check->ChildCount() == 2);
    CHECK(check->GetChildAt(0) == check->GetIndicatorPart());
    CHECK(core::Cast<UIWidget>(check->GetIndicatorPart())->GetTag() == core::StringView(u8"indicator"));
    CHECK(check->GetChildAt(1) == check->GetTextPart());
}

TEST_CASE("button: markup content sits inside it, and its size is its content's")
{
    auto root = MakeRoot();
    auto check = Make<CheckBox>();
    root->AddChild(check.Get());
    (void)root->UpdateLayout();
    CHECK(check->GetSize().x == doctest::Approx(20.0f)); // the indicator alone
    CHECK(check->GetSize().y == doctest::Approx(20.0f));

    auto sw = Make<ToggleSwitch>();
    root->AddChild(sw.Get());
    auto extra = Make<Panel>();
    extra->SetSize(core::Float2{30.0f, 10.0f});
    sw->AddChild(extra.Get());
    (void)root->UpdateLayout();
    CHECK(sw->GetSize().x == doctest::Approx(36.0f + 6.0f + 30.0f)); // the track, the gap, the content
}

TEST_CASE("button: a command's label fills a button with no text of its own")
{
    auto b = Make<Button>();
    b->OnBoundCommandText(core::StringView(u8"Play"), {}, {});
    CHECK(b->GetText() == core::StringView(u8"Play"));
    b->OnBoundCommandText(core::StringView(u8"Pause"), {}, {});
    CHECK(b->GetText() == core::StringView(u8"Pause"));
    b->SetText(core::StringView(u8"Mine"));
    b->OnBoundCommandText(core::StringView(u8"Stop"), {}, {});
    CHECK(b->GetText() == core::StringView(u8"Mine"));
}

TEST_CASE("button: its text part is aligned as the button is: centred on a button, at its start beside an indicator")
{
    auto b = Make<Button>();
    b->SetText(core::StringView(u8"OK"));
    CHECK(b->GetTextPart()->GetTextAlignH() == TextHAlign::Center);
    b->SetTextAlignment(TextHAlign::Right, TextVAlign::Middle);
    CHECK(b->GetTextPart()->GetTextAlignH() == TextHAlign::Right);

    auto check = Make<CheckBox>();
    check->SetText(core::StringView(u8"Music"));
    CHECK(check->GetTextPart()->GetTextAlignH() == TextHAlign::Start);
}
