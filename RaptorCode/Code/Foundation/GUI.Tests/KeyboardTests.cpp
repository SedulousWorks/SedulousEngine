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
