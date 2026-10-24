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
