// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the keyboard's breadth (E12 of Specs/gui-lab-evolution-2.md): tab-index, focus groups,
// Tab captured by a widget, a menu's keys through the keymap, the next key captured, mnemonics and
// type-ahead from text input; a focused widget hidden gives the focus up.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
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
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::Array<core::RefPtr<Button>> buttons;
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        Button& Add(const char8_t* id, Node* parent = nullptr)
        {
            core::RefPtr<Button> b = Make<Button>();
            b->SetId(SV(id));
            b->SetSize(core::Float2{40.0f, 20.0f});
            (parent != nullptr ? parent : static_cast<Node*>(root.Get()))->AddChild(b.Get());
            buttons.PushBack(b);
            return *b;
        }
        static core::StringView IdOf(Node* n)
        {
            const UIWidget* w = core::Cast<UIWidget>(n);
            return w != nullptr ? w->GetId() : core::StringView{};
        }
        core::String Focused() { return core::String(IdOf(D().GetFocusNode())); }
        void Tab(bool back = false) { D().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), back ? KeyModShift : 0u); }
    };
}

TEST_CASE("keyboard: tab-index orders Tab: positive first, lowest first, then tree order; negative is skipped")
{
    Bed bed;
    bed.Add(u8"a").SetTabIndex(2);
    bed.Add(u8"b");
    bed.Add(u8"c").SetTabIndex(1);
    bed.Add(u8"d").SetTabIndex(-1);
    bed.Add(u8"e");
    const core::Array<Node*> stops = bed.D().TabStops();
    REQUIRE(stops.Size() == 4u);
    CHECK(Bed::IdOf(stops[0]) == SV(u8"c"));
    CHECK(Bed::IdOf(stops[1]) == SV(u8"a"));
    CHECK(Bed::IdOf(stops[2]) == SV(u8"b"));
    CHECK(Bed::IdOf(stops[3]) == SV(u8"e"));
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"c"));
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"a"));
    bed.Tab(true);
    CHECK(bed.Focused() == SV(u8"c"));
    // Skipped by Tab, but still focusable another way; Tab from there goes on in the order.
    bed.D().SetFocusNode(bed.buttons[3].Get());
    CHECK(bed.Focused() == SV(u8"d"));
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"c")); // not among the stops: Tab starts over
}

TEST_CASE("keyboard: tab-index comes from a sheet and from markup")
{
    Bed bed;
    Button& a = bed.Add(u8"a");
    Button& b = bed.Add(u8"b");
    StyleManager styles;
    styles.SetStyleSheet(CSSParser::Parse(SV(u8"#a { tab-index: -1; } #b { tab-index: 3; }")));
    styles.ApplyTree(*bed.root.Get());
    CHECK(a.GetTabIndex() == -1);
    CHECK(b.GetTabIndex() == 3);

    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<Node> tree = loader.LoadFromString(SV(u8"<Panel><Button id=\"x\" tab-index=\"5\"/></Panel>"));
    REQUIRE(tree);
    REQUIRE(tree->ChildCount() == 1u);
    CHECK(tree->GetChildAt(0)->GetTabIndex() == 5);
}

TEST_CASE("keyboard: a focus group is one Tab stop: its checked member first, then the one focused last; arrows wrap inside")
{
    Bed bed;
    bed.Add(u8"x").SetPosition(core::Float2{0.0f, 0.0f});
    core::RefPtr<Panel> group = Make<Panel>();
    group->SetFocusGroup(true);
    group->SetPosition(core::Float2{0.0f, 40.0f});
    group->SetSize(core::Float2{200.0f, 20.0f});
    bed.root->AddChild(group.Get());
    core::RefPtr<RadioButton> radios[3];
    for (int i = 0; i < 3; ++i)
    {
        radios[i] = Make<RadioButton>();
        radios[i]->SetId(core::StringView(i == 0 ? u8"r0" : i == 1 ? u8"r1" : u8"r2"));
        radios[i]->SetPosition(core::Float2{60.0f * static_cast<float>(i), 0.0f});
        radios[i]->SetSize(core::Float2{50.0f, 20.0f});
        group->AddChild(radios[i].Get());
    }
    radios[1]->SetChecked(true);
    bed.Add(u8"y").SetPosition(core::Float2{0.0f, 80.0f});

    CHECK(bed.D().TabStops().Size() == 3u);
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"x"));
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"r1")); // the checked one
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right), 0);
    CHECK(bed.Focused() == SV(u8"r2"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Right), 0);
    CHECK(bed.Focused() == SV(u8"r0")); // wrapped inside the group
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"y")); // out of the group in one step
    bed.Tab(true);
    CHECK(bed.Focused() == SV(u8"r0")); // back to the one focused there last
}

TEST_CASE("keyboard: a tab strip is a focus group: one stop, the selected tab")
{
    Bed bed;
    bed.Add(u8"before");
    core::RefPtr<TabBar> bar = Make<TabBar>();
    bed.root->AddChild(bar.Get());
    (void)bar->InsertTab(0, SV(u8"One"));
    (void)bar->InsertTab(1, SV(u8"Two"));
    (void)bar->InsertTab(2, SV(u8"Three"));
    bar->SetSelectedIndex(2);
    const core::Array<Node*> stops = bed.D().TabStops();
    REQUIRE(stops.Size() == 2u);
    CHECK(stops[1]->IsCurrentInGroup()); // the selected tab
}

TEST_CASE("keyboard: a widget that captures Tab takes Tab and Shift+Tab as keys; Ctrl+Tab moves focus from it")
{
    Bed bed;
    bed.Add(u8"a");
    core::RefPtr<TextArea> editor = Make<TextArea>();
    editor->SetId(SV(u8"editor"));
    editor->SetSize(core::Float2{200.0f, 80.0f});
    editor->SetTabCaptures(true);
    bed.root->AddChild(editor.Get());
    bed.Add(u8"b");
    bed.D().SetFocusNode(editor.Get());
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"editor"));
    CHECK(editor->GetText() == SV(u8"\t")); // it typed a tab
    bed.Tab(true);
    CHECK(bed.Focused() == SV(u8"editor")); // its key, though it does nothing with it
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModCtrl);
    CHECK(bed.Focused() == SV(u8"b"));
    bed.D().SetFocusNode(editor.Get());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab), KeyModCtrl | KeyModShift);
    CHECK(bed.Focused() == SV(u8"a"));
    // Without it, Tab moves on as ever.
    editor->SetTabCaptures(false);
    bed.D().SetFocusNode(editor.Get());
    bed.Tab();
    CHECK(bed.Focused() == SV(u8"b"));
    CHECK(editor->GetText() == SV(u8"\t"));
}

TEST_CASE("keyboard: a menu's moves are bindings in the menu key context, rebound like any key")
{
    Bed bed;
    bed.root->SetSize(core::Float2{600.0f, 400.0f});
    core::RefPtr<MenuBar> bar = Make<MenuBar>();
    bed.root->AddChild(bar.Get());
    Menu* file = bar->AddMenu(SV(u8"File"));
    file->AddItem(SV(u8"Open"), [] {});
    file->AddItem(SV(u8"Save"), [] {});
    Menu* edit = bar->AddMenu(SV(u8"Edit"));
    edit->AddItem(SV(u8"Undo"), [] {});
    bed.root->UpdateLayout();
    Keymap& keys = bed.root->GetContext().GetKeymap();
    const char8_t* const wasd[][2] = {{u8"w", u8"menu.up"}, {u8"s", u8"menu.down"}, {u8"a", u8"menu.left"}, {u8"d", u8"menu.right"}};
    for (const auto& b : wasd)
        REQUIRE(keys.Bind(SV(b[0]), SV(b[1]), SV(kMenuKeyContext)));

    const auto item = [&]() -> core::StringView
    {
        const MenuItem* it = core::Cast<MenuItem>(bed.D().GetFocusNode());
        return it != nullptr ? it->GetText() : core::StringView{};
    };
    bar->ButtonAt(0)->RequestFocus();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::S), 0); // opens File
    CHECK(file->IsOpen());
    CHECK(item() == SV(u8"Open"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::S), 0);
    CHECK(item() == SV(u8"Save"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::D), 0); // along the bar
    CHECK(edit->IsOpen());
    CHECK(item() == SV(u8"Undo"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::A), 0);
    CHECK(file->IsOpen());
}

TEST_CASE("keyboard: a binding whose command nothing on the focus path handles lets the key go on")
{
    Bed bed;
    bed.Add(u8"a").SetPosition(core::Float2{0.0f, 0.0f});
    bed.Add(u8"b").SetPosition(core::Float2{0.0f, 40.0f});
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"down"), SV(u8"nobody.handles")));
    bed.D().SetFocusNode(bed.buttons[0].Get());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down), 0);
    CHECK(bed.Focused() == SV(u8"b")); // navigation had it
}

TEST_CASE("keyboard: a focused widget hidden gives up the focus: Return does not press it, the scope's commands run")
{
    Bed bed;
    core::RefPtr<Panel> screen = Make<Panel>();
    bed.root->AddChild(screen.Get());
    Button& back = bed.Add(u8"back", screen.Get());
    int pressed = 0;
    back.SetOnClick([&pressed]() { ++pressed; });
    int ran = 0;
    (void)bed.root->GetContext().DefineCommand(SV(u8"test.back"));
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"escape"), SV(u8"test.back")));
    (void)bed.root->OnCommand(SV(u8"test.back"), [&ran](CommandEvent&) { ++ran; });
    back.RequestFocus();
    REQUIRE(bed.Focused() == SV(u8"back"));

    screen->SetDisplayed(false); // the screen hides with its button focused
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(pressed == 0);
    CHECK(bed.D().GetFocusNode() == nullptr);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(ran == 1);

    // Hidden by `visibility` too, and found out by the tick as well as by a key.
    screen->SetDisplayed(true);
    back.RequestFocus();
    REQUIRE(bed.Focused() == SV(u8"back"));
    back.SetVisible(false);
    bed.D().Tick(0.016f);
    CHECK(bed.D().GetFocusNode() == nullptr);
}

TEST_CASE("keyboard: CaptureNextKey takes the next key before bindings and widgets, with its modifiers, and drops its text")
{
    Bed bed;
    core::RefPtr<TextField> field = Make<TextField>();
    field->SetSize(core::Float2{200.0f, 24.0f});
    bed.root->AddChild(field.Get());
    bed.D().SetFocusNode(field.Get());
    int quits = 0;
    (void)bed.root->OnCommand(SV(u8"quit"), [&](CommandEvent&) { ++quits; });
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"ctrl-q"), SV(u8"quit")));

    core::Array<Keystroke> taken;
    int cancels = 0;
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); }, [&] { ++cancels; });
    CHECK(bed.D().IsCapturingKey());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::LeftCtrl), KeyModCtrl); // waits: maybe Ctrl+something
    CHECK(taken.IsEmpty());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Q), KeyModCtrl);
    REQUIRE(taken.Size() == 1u);
    CHECK(taken[0] == ParseKeystroke(SV(u8"ctrl-q")).Value());
    CHECK(quits == 0); // the binding never saw it
    CHECK_FALSE(bed.D().IsCapturingKey());

    // A plain key's text is dropped; the field gets nothing.
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); });
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::W), 0);
    bed.D().InjectText(SV(u8"w"));
    CHECK(taken.Size() == 2u);
    CHECK(field->GetText().IsEmpty());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::E), 0); // capture over: as ever
    bed.D().InjectText(SV(u8"e"));
    CHECK(field->GetText() == SV(u8"e"));

    // A modifier alone, taken as it is released.
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); });
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::LeftShift), KeyModShift);
    bed.D().InjectKeyUp(static_cast<core::u32>(KeyCode::LeftShift), 0);
    REQUIRE(taken.Size() == 3u);
    CHECK(taken[2] == ParseKeystroke(SV(u8"leftshift")).Value());

    // A pad button.
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); });
    bed.D().InjectPadButton(PadButton::North);
    REQUIRE(taken.Size() == 4u);
    CHECK(taken[3] == ParseKeystroke(SV(u8"pad-north")).Value());
    CHECK(cancels == 0);
}

TEST_CASE("keyboard: Escape cancels a capture, unless the caller takes it")
{
    Bed bed;
    core::Array<Keystroke> taken;
    int cancels = 0;
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); }, [&] { ++cancels; });
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape), 0);
    CHECK(cancels == 1);
    CHECK(taken.IsEmpty());
    CHECK_FALSE(bed.D().IsCapturingKey());
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); }, [&] { ++cancels; }, true);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape), 0);
    REQUIRE(taken.Size() == 1u);
    CHECK(taken[0].Code == static_cast<core::u32>(KeyCode::Escape));
    CHECK(cancels == 1);
    // A second capture replaces a waiting one, which is cancelled.
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); }, [&] { ++cancels; });
    bed.D().CaptureNextKey([&](const Keystroke& k) { taken.PushBack(k); });
    CHECK(cancels == 2);
}

TEST_CASE("keyboard: an & marks an access key; && is an ampersand")
{
    Mnemonic m = ParseMnemonic(SV(u8"&File"));
    CHECK(m.Shown == SV(u8"File"));
    CHECK(m.Key == U'f');
    CHECK(m.Start == 0u);
    CHECK(m.End == 1u);
    m = ParseMnemonic(SV(u8"E&xit"));
    CHECK(m.Shown == SV(u8"Exit"));
    CHECK(m.Key == U'x');
    CHECK(m.Start == 1u);
    m = ParseMnemonic(SV(u8"Save && Quit"));
    CHECK(m.Shown == SV(u8"Save & Quit"));
    CHECK(m.Key == 0);
}

TEST_CASE("keyboard: Alt and a button's access key focus and press it; its letter is underlined while Alt is held")
{
    Bed bed;
    Button& other = bed.Add(u8"other");
    Button& apply = bed.Add(u8"apply");
    apply.SetText(SV(u8"&Apply"));
    other.SetText(SV(u8"Other"));
    int clicks = 0;
    apply.SetOnClick([&] { ++clicks; });
    CHECK(apply.GetText() == SV(u8"Apply"));
    CHECK(apply.GetMnemonic() == U'a');
    bed.D().SetFocusNode(&other);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::A), KeyModAlt);
    CHECK(clicks == 1);
    CHECK(bed.Focused() == SV(u8"apply"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Q), KeyModAlt); // nothing marked Q
    CHECK(clicks == 1);

    REQUIRE(apply.GetTextPart() != nullptr);
    CHECK_FALSE(bed.D().AreMnemonicsShown());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::LeftAlt), KeyModAlt);
    CHECK(bed.D().AreMnemonicsShown());
    bed.D().InjectKeyUp(static_cast<core::u32>(KeyCode::LeftAlt), 0);
    CHECK_FALSE(bed.D().AreMnemonicsShown());
    bed.D().SetMnemonicsAlwaysShown(true);
    CHECK(bed.D().AreMnemonicsShown());
}

TEST_CASE("keyboard: Alt and a key open a menu bar's menu, and run an item of the open menu")
{
    Bed bed;
    bed.root->SetSize(core::Float2{600.0f, 400.0f});
    core::RefPtr<MenuBar> bar = Make<MenuBar>();
    bed.root->AddChild(bar.Get());
    int opened = 0;
    Menu* file = bar->AddMenu(SV(u8"&File"));
    file->AddItem(SV(u8"&Open"), [&] { ++opened; });
    file->AddItem(SV(u8"E&xit"), [] {});
    (void)bar->AddMenu(SV(u8"&Edit"));
    bed.root->UpdateLayout();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F), KeyModAlt);
    CHECK(file->IsOpen());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::O), KeyModAlt);
    CHECK(opened == 1);
    CHECK_FALSE(file->IsOpen());
}

TEST_CASE("keyboard: type-ahead reads typed text, so it follows the layout and an IME: a Cyrillic list types ahead")
{
    Bed bed;
    core::RefPtr<ComboBox> combo = Make<ComboBox>();
    combo->SetSize(core::Float2{140.0f, 26.0f});
    combo->SetItemsText(core::String(SV(u8"Яблоко|Груша|Арбуз")));
    combo->SetSelectedIndex(0);
    bed.root->AddChild(combo.Get());
    combo->RequestFocus();
    CHECK(bed.D().WantsTextInput()); // it asks for typed text
    // A Russian layout's key types a Cyrillic letter; its key code is a Latin letter's.
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::U), 0);
    bed.D().InjectText(SV(u8"г"));
    CHECK(combo->GetSelectedIndex() == 1);
    // A binding of a bare letter does not take it from under the type-ahead.
    int ran = 0;
    (void)bed.root->OnCommand(SV(u8"jump"), [&](CommandEvent&) { ++ran; });
    REQUIRE(bed.root->GetContext().GetKeymap().Bind(SV(u8"f"), SV(u8"jump")));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::F), 0);
    bed.D().InjectText(SV(u8"а"));
    CHECK(ran == 0);
    CHECK(combo->GetSelectedIndex() == 2);
}

TEST_CASE("keyboard: type-ahead matches letters in either case in Latin, Greek and Cyrillic")
{
    CHECK(StartsWithIgnoringCase(SV(u8"Banana"), SV(u8"ba")));
    CHECK(StartsWithIgnoringCase(SV(u8"Éclair"), SV(u8"é")));       // É, é
    CHECK(StartsWithIgnoringCase(SV(u8"Łódź"), SV(u8"ł"))); // Ł, ł
    CHECK(StartsWithIgnoringCase(SV(u8"Δέλτα"), SV(u8"δ"))); // Δ, δ
    CHECK(StartsWithIgnoringCase(SV(u8"Груша"), SV(u8"гр"))); // Гр, гр
    CHECK(StartsWithIgnoringCase(SV(u8"Ёлка"), SV(u8"ё"))); // Ё, ё
    CHECK_FALSE(StartsWithIgnoringCase(SV(u8"Apple"), SV(u8"b")));
    CHECK_FALSE(StartsWithIgnoringCase(SV(u8"A"), SV(u8"ab")));
}
