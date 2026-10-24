// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - directional navigation (G7 of Specs/vg-and-gui-lab.md): the geometric picker over grids
// and irregular layouts, focus scopes (pass, wrap, contain, focus memory, default focus), widgets
// that use the arrows and give them back at their ends, and activation by Return.
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

    // A focusable widget at (x, y), 40 x 20, id `id`.
    core::RefPtr<Button> Cell(Node& parent, const char8_t* id, float x, float y, float w = 40.0f, float h = 20.0f)
    {
        auto b = Make<Button>();
        b->SetId(SV(id));
        b->SetPosition(core::Float2{x, y});
        b->SetSize(core::Float2{w, h});
        parent.AddChild(b.Get());
        return b;
    }

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        EventDispatcher& d = *root->GetEventDispatcher();
        Bed() { root->SetSize(core::Float2{400.0f, 400.0f}); }
        [[nodiscard]] core::StringView Focused() const
        {
            const UIWidget* w = core::Cast<UIWidget>(d.GetFocusNode());
            return w != nullptr ? w->GetId() : SV(u8"");
        }
        void Key(KeyCode key) { d.InjectKeyDown(static_cast<core::u32>(key)); }
    };
}

TEST_CASE("navigation: focusing a page lands on its entry, and Tab stays in a dialog")
{
    Bed bed;
    auto page = Make<UIWidget>();
    page->SetNavScope(NavScope::Pass);
    page->SetDefaultFocusId(SV(u8"second"));
    bed.root->AddChild(page.Get());
    auto first = Cell(*page.Get(), u8"first", 10.0f, 10.0f);
    auto second = Cell(*page.Get(), u8"second", 10.0f, 40.0f);
    CHECK(page->FocusElement());
    CHECK(bed.Focused() == SV(u8"second")); // its default
    bed.d.SetFocusNode(first.Get());
    auto elsewhere = Cell(*bed.root.Get(), u8"elsewhere", 200.0f, 10.0f);
    bed.d.SetFocusNode(elsewhere.Get());
    CHECK(page->FocusElement());
    CHECK(bed.Focused() == SV(u8"first")); // what was last focused there

    page->SetNavScope(NavScope::Contain);
    bed.d.SetFocusNode(second.Get());
    bed.Key(KeyCode::Tab); // wraps inside the dialog, never reaching `elsewhere`
    CHECK(bed.Focused() == SV(u8"first"));
    bed.Key(KeyCode::Tab);
    CHECK(bed.Focused() == SV(u8"second"));
}
